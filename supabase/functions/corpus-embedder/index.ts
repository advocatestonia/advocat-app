// corpus-embedder Edge Function
// -----------------------------------------------------------------------------
// Idempotent worker that finds rows in (law_chunks_v2, case_chunks, travaux)
// with `embedding IS NULL` and populates them via OpenAI's
// text-embedding-3-small model (1536-dim).
//
// Built for the Corpus v3 ingest pipeline (consilium 2026-05-14):
//   scrapers populate text → corpus-embedder fills embeddings → law_search_v2
//   becomes usable.
//
// Wire format:
//   POST or GET /functions/v1/corpus-embedder
//   Optional JSON body:
//     {
//       "table":       "law_chunks_v2" | "case_chunks" | "travaux" | "all",
//                      // default "all" — process all three round-robin
//       "batch_size":  1..100,        // default 100 (OpenAI batch cap)
//       "max_batches": 1..20,         // default 5 per invocation (Edge Fn
//                                     //   wall-clock cap is ~150s)
//       "run_validators": boolean     // default true — see VALIDATORS below
//     }
//
//   200 OK
//   {
//     "processed":  number,    // chunks embedded this invocation
//     "remaining":  number,    // chunks still needing embedding (any table)
//     "by_table":   { law_chunks_v2: {processed, remaining},
//                     case_chunks:   {...},
//                     travaux:       {...} },
//     "cost_usd":   number,    // estimate of OpenAI burn this invocation
//     "tokens":     number,    // total prompt_tokens billed
//     "elapsed_ms": number,
//     "validators": { ... } | null
//   }
//
// Idempotency: WHERE embedding IS NULL guarantees we never re-embed.
//
// Auth: service-role only. Deployed with `--no-verify-jwt` and gated by a
// shared secret (CORPUS_EMBEDDER_SECRET) so it can be called by curl/cron
// without needing a user JWT. If the secret isn't set in env, we fail closed.
//
// Cost guard: OpenAI text-embedding-3-small costs $0.02 / 1M tokens.
// Typical 1KB chunk = ~250 tokens → ~$0.000005/chunk. 13K chunks ≈ $0.07.
// Cap is documented at $100, actual will be << $1.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";
const CORPUS_EMBEDDER_SECRET = Deno.env.get("CORPUS_EMBEDDER_SECRET") ?? "";

const OPENAI_EMBED_URL = "https://api.openai.com/v1/embeddings";
const OPENAI_MODEL = "text-embedding-3-small";
const EMBED_DIM = 1536;

// text-embedding-3-small price: $0.02 / 1M tokens (2026-05 pricing).
const PRICE_PER_TOKEN_USD = 0.02 / 1_000_000;

// OpenAI inputs cap: 8191 tokens per item, 300K tokens total per request.
// We chunk text aggressively in scrapers (~1KB / ~250 tok per chunk), so
// 100 inputs/request ≈ 25K tokens — well under any limit.
const DEFAULT_BATCH_SIZE = 100;
const MAX_BATCH_SIZE = 100;
// Wall-clock cap on the function is ~150s. Each batch is ~1-2s, so 5 batches
// is a safe default. Caller can bump up via `max_batches`.
const DEFAULT_MAX_BATCHES = 5;
const MAX_MAX_BATCHES = 20;

// Hard cap on input text length to avoid pathological scrapers blowing the
// 8191-token per-item OpenAI limit. Empirically Estonian/Finnish legal text
// runs ~2.4 chars/token (compound words, UTF-8), NOT the 4 chars/token rule
// for English. 18_000 chars × 2.4 ≈ 7_500 tokens — safe under 8191 with
// headroom for tokenizer drift. The chunk_splitter helper splits oversize
// rows at the scraper layer; this is just a defence-in-depth truncation so
// a forgotten rescraper can't burn dollars on 429-loops.
const MAX_TEXT_CHARS = 18_000;

type TableName = "law_chunks_v2" | "case_chunks" | "travaux";
const ALL_TABLES: TableName[] = ["law_chunks_v2", "case_chunks", "travaux"];

interface ChunkRow {
  id: string;
  text: string;
}

interface BatchOutcome {
  processed: number;
  tokens: number;
  err?: string;
}

interface TableOutcome {
  processed: number;
  remaining: number;
}

interface ValidatorResult {
  name: string;
  passed: boolean;
  detail?: unknown;
}

// ---------- response helpers ----------

const RESP_HEADERS = {
  "Content-Type": "application/json",
  // No CORS — this is a backend-to-backend cron endpoint, not browser-facing.
};

function jsonError(msg: string, status: number, extra: Record<string, unknown> = {}): Response {
  return new Response(JSON.stringify({ error: msg, ...extra }), {
    status,
    headers: RESP_HEADERS,
  });
}

function jsonOk(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: RESP_HEADERS });
}

/** Constant-time string comparison (prevents a timing oracle on the secret). */
function timingSafeEqualStr(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let r = 0;
  for (let i = 0; i < a.length; i++) {
    r |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return r === 0;
}

// ---------- OpenAI batch embed ----------

/**
 * Batch-embed up to MAX_BATCH_SIZE texts via OpenAI.
 * Returns { embeddings (parallel to input), tokens } or throws on error.
 */
async function embedBatch(
  texts: string[],
): Promise<{ embeddings: number[][]; tokens: number }> {
  if (!OPENAI_API_KEY) {
    throw new Error("OPENAI_API_KEY not set");
  }
  if (texts.length === 0) {
    return { embeddings: [], tokens: 0 };
  }
  // Truncate any pathologically large texts.
  const inputs = texts.map((t) =>
    t.length > MAX_TEXT_CHARS ? t.slice(0, MAX_TEXT_CHARS) : t
  );

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort("timeout"), 60_000);

  let resp: Response;
  try {
    resp = await fetch(OPENAI_EMBED_URL, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${OPENAI_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: OPENAI_MODEL,
        input: inputs,
        encoding_format: "float",
      }),
      signal: controller.signal,
    });
  } finally {
    clearTimeout(timer);
  }

  if (!resp.ok) {
    const detail = await resp.text().catch(() => "");
    throw new Error(`OpenAI ${resp.status}: ${detail.slice(0, 240)}`);
  }
  const data = await resp.json() as {
    data?: Array<{ embedding?: number[]; index?: number }>;
    usage?: { total_tokens?: number; prompt_tokens?: number };
  };
  const items = data?.data ?? [];
  if (items.length !== texts.length) {
    throw new Error(
      `OpenAI returned ${items.length} embeddings for ${texts.length} inputs`,
    );
  }
  // Sort by index just in case OpenAI ever returns out-of-order; doc says
  // they preserve order, but the field exists, so be defensive.
  const sorted = items.slice().sort(
    (a, b) => (a.index ?? 0) - (b.index ?? 0),
  );
  const embeddings: number[][] = [];
  for (let i = 0; i < sorted.length; i++) {
    const e = sorted[i]?.embedding;
    if (!Array.isArray(e) || e.length !== EMBED_DIM) {
      throw new Error(
        `OpenAI item ${i} has bad embedding (len=${
          Array.isArray(e) ? e.length : "n/a"
        })`,
      );
    }
    embeddings.push(e);
  }
  const tokens = data?.usage?.total_tokens ?? data?.usage?.prompt_tokens ?? 0;
  return { embeddings, tokens };
}

// ---------- Postgres helpers ----------

// deno-lint-ignore no-explicit-any
type SBClient = ReturnType<typeof createClient<any>>;

/**
 * Fetch up to `limit` rows with NULL embedding for the given table.
 * Uses a deterministic ORDER BY id so concurrent invocations are unlikely
 * to fight over the same rows (and the UPDATE is idempotent anyway).
 */
async function fetchUnembeddedRows(
  sb: SBClient,
  table: TableName,
  limit: number,
): Promise<ChunkRow[]> {
  // .select() with .is('embedding', null) — supabase-js translates to
  // `embedding=is.null` which Postgres handles via the IS NULL operator.
  const { data, error } = await sb
    .from(table)
    .select("id, text")
    .is("embedding", null)
    .order("id", { ascending: true })
    .limit(limit);
  if (error) throw new Error(`select ${table}: ${error.message}`);
  // Filter out empty/whitespace-only text rows — they can't be embedded.
  return (data ?? [])
    .filter((r): r is ChunkRow =>
      typeof r?.id === "string" &&
      typeof r?.text === "string" &&
      r.text.trim().length > 0
    );
}

/**
 * Re-embed augmented mode (Day2-B vabank 2026-05-17).
 * --------------------------------------------------------------
 * Page through ALL rows in `law_chunks_v2` (not just NULL-embedding rows),
 * reading from `chunk_text_augmented` instead of `text`, and overwriting
 * the existing `embedding`. Uses a marker table `embed_reaug_progress` to
 * resume across invocations (we can only process ~2k rows per 150s slot).
 *
 * Idempotency: the progress marker stores the LAST id processed; the next
 * invocation resumes from `id > marker`. If we crash mid-batch, the worst
 * case is re-embedding a few rows — that's still correct, just wasted $.
 *
 * Backup safety: `embedding_v1_backup` already snapshotted before the
 * first invocation (migration 20260517100000). We never touch
 * embedding_v1_backup here, so rollback stays available.
 */
const REAUG_MARKER_KEY = "law_chunks_v2_reembed_augmented_2026_05_17";

async function fetchReaugBatch(
  sb: SBClient,
  limit: number,
  lastId: string | null,
): Promise<Array<{ id: string; text: string }>> {
  // Cast UUID strings work with .gt — supabase-js handles type coercion.
  // We use chunk_text_augmented when present, else fall back to text so
  // any row that somehow has NULL augmented (shouldn't happen post-migration)
  // still gets re-embedded.
  let q = sb
    .from("law_chunks_v2")
    .select("id, chunk_text_augmented, text")
    .order("id", { ascending: true })
    .limit(limit);
  if (lastId) q = q.gt("id", lastId);
  const { data, error } = await q;
  if (error) throw new Error(`select law_chunks_v2 (reaug): ${error.message}`);
  return (data ?? [])
    .map((r) => ({
      id: r.id as string,
      // Prefer augmented; fall back to text. Both should be non-empty.
      text: ((r.chunk_text_augmented ?? r.text ?? "") as string).trim(),
    }))
    .filter((r) => r.id && r.text.length > 0);
}

async function readReaugMarker(sb: SBClient): Promise<string | null> {
  // Use the `kv_store` table if it exists; otherwise no marker (start fresh).
  // We fall through silently if the table is missing — caller will start at
  // the beginning, which is harmless (idempotent re-embed).
  try {
    const { data, error } = await sb
      .from("kv_store")
      .select("value")
      .eq("key", REAUG_MARKER_KEY)
      .maybeSingle();
    if (error) return null;
    return (data?.value as string) ?? null;
  } catch {
    return null;
  }
}

async function writeReaugMarker(
  sb: SBClient,
  id: string,
): Promise<void> {
  try {
    await sb
      .from("kv_store")
      .upsert({ key: REAUG_MARKER_KEY, value: id }, { onConflict: "key" });
  } catch {
    // Marker is best-effort; failure means next invocation starts fresh,
    // which is wasted work but not wrong.
  }
}

/**
 * Process one batch of re-augment re-embed. Returns the highest-id row
 * processed (for the marker) and the count.
 */
async function processReaugBatch(
  sb: SBClient,
  batchSize: number,
  lastId: string | null,
): Promise<{ processed: number; tokens: number; newLastId: string | null; err?: string }> {
  const rows = await fetchReaugBatch(sb, batchSize, lastId);
  if (rows.length === 0) {
    return { processed: 0, tokens: 0, newLastId: lastId };
  }

  let embeddings: number[][];
  let tokens: number;
  try {
    const res = await embedBatch(rows.map((r) => r.text));
    embeddings = res.embeddings;
    tokens = res.tokens;
  } catch (err) {
    return { processed: 0, tokens: 0, newLastId: lastId, err: String(err) };
  }

  // UPDATE in parallel. Use Promise.allSettled so one bad row doesn't kill
  // the batch.
  const updates = rows.map((r, i) =>
    updateEmbedding(sb, "law_chunks_v2", r.id, embeddings[i])
  );
  const settled = await Promise.allSettled(updates);
  let processed = 0;
  const failures: string[] = [];
  let highestSuccessId: string | null = lastId;
  for (let i = 0; i < settled.length; i++) {
    const s = settled[i];
    if (s.status === "fulfilled") {
      processed++;
      // Rows arrive ordered by id ASC, so the last fulfilled is highest.
      highestSuccessId = rows[i].id;
    } else {
      failures.push(`${rows[i].id}: ${String(s.reason)}`);
    }
  }
  return {
    processed,
    tokens,
    newLastId: highestSuccessId,
    err: failures.length ? failures.slice(0, 3).join(" | ") : undefined,
  };
}

/**
 * Count rows with NULL embedding for a table (for "remaining" reporting).
 */
async function countRemaining(
  sb: SBClient,
  table: TableName,
): Promise<number> {
  const { count, error } = await sb
    .from(table)
    .select("id", { count: "exact", head: true })
    .is("embedding", null);
  if (error) throw new Error(`count ${table}: ${error.message}`);
  return count ?? 0;
}

/**
 * UPDATE one row's embedding column. pgvector accepts the string form
 * "[v1,v2,...]" via supabase-js because it goes through the PostgREST
 * type-coercion path.
 */
async function updateEmbedding(
  sb: SBClient,
  table: TableName,
  id: string,
  embedding: number[],
): Promise<void> {
  // Format as pgvector literal. Using fixed-precision floats keeps the
  // payload small (full IEEE-754 repr would be 23 chars/dim → 35KB/row).
  // 7 significant digits is plenty for cosine sim (~1e-6 noise floor).
  const vecStr = "[" + embedding.map((x) => x.toFixed(7)).join(",") + "]";
  const { error } = await sb
    .from(table)
    .update({ embedding: vecStr })
    .eq("id", id);
  if (error) throw new Error(`update ${table} ${id}: ${error.message}`);
}

// ---------- batch driver ----------

/**
 * Process one batch from one table. Fetches up to batchSize unembedded rows,
 * embeds them all in one OpenAI call, then UPDATEs each row in parallel
 * (small N, safe).
 */
async function processBatch(
  sb: SBClient,
  table: TableName,
  batchSize: number,
): Promise<BatchOutcome> {
  const rows = await fetchUnembeddedRows(sb, table, batchSize);
  if (rows.length === 0) return { processed: 0, tokens: 0 };

  let embeddings: number[][];
  let tokens: number;
  try {
    const res = await embedBatch(rows.map((r) => r.text));
    embeddings = res.embeddings;
    tokens = res.tokens;
  } catch (err) {
    return { processed: 0, tokens: 0, err: String(err) };
  }

  // UPDATE in parallel. With supabase-js this is just a network roundtrip
  // per row; we cap concurrency implicitly by the batch size (100).
  const updates = rows.map((r, i) => updateEmbedding(sb, table, r.id, embeddings[i]));
  const settled = await Promise.allSettled(updates);
  let processed = 0;
  const failures: string[] = [];
  for (let i = 0; i < settled.length; i++) {
    const s = settled[i];
    if (s.status === "fulfilled") processed++;
    else failures.push(`${rows[i].id}: ${String(s.reason)}`);
  }
  return {
    processed,
    tokens,
    err: failures.length ? failures.slice(0, 3).join(" | ") : undefined,
  };
}

// ---------- validators ----------

/**
 * Citation format check for FI: section_label should be `XXX 114 §`
 * (Finnish convention: act_abbrev + number + section sign).
 * Accept any of:  "HOL 114 §", "Hallintolaki 114 §", "ULKL 11 luku 1 §"
 * Reject:         "§ 114 HOL", "HOL § 114"
 */
function validateFiCitationFormat(labels: string[]): ValidatorResult {
  const okPattern = /\d+\s*§/; // "number §" anywhere → good
  const badPattern = /§\s*\d/; // "§ number" → wrong (EE format)
  const bad: string[] = [];
  for (const l of labels) {
    if (!l) continue;
    if (badPattern.test(l) && !okPattern.test(l)) bad.push(l);
  }
  return {
    name: "citation_format_fi",
    passed: bad.length === 0,
    detail: bad.length ? { sample_bad: bad.slice(0, 5), count: bad.length } : { checked: labels.length },
  };
}

/**
 * Citation format check for EE: section_label should be `XXX § 114`
 * (Estonian convention: act_abbrev + section sign + number).
 */
function validateEeCitationFormat(labels: string[]): ValidatorResult {
  const okPattern = /§\s*\d/; // "§ number" → good
  const badPattern = /\d\s*§/; // "number §" → wrong (FI format)
  const bad: string[] = [];
  for (const l of labels) {
    if (!l) continue;
    if (badPattern.test(l) && !okPattern.test(l)) bad.push(l);
  }
  return {
    name: "citation_format_ee",
    passed: bad.length === 0,
    detail: bad.length ? { sample_bad: bad.slice(0, 5), count: bad.length } : { checked: labels.length },
  };
}

/**
 * Sanity query: embed a known Finnish legal phrase and check the top hit
 * is in the expected act (HOL § 114 — restoration of lapsed deadline).
 * Only run when there are >= 10 embedded FI rows — pointless before that.
 */
async function validateSanityQuery(
  sb: SBClient,
): Promise<ValidatorResult> {
  // Cheap pre-check.
  const { count } = await sb
    .from("law_chunks_v2")
    .select("id", { count: "exact", head: true })
    .eq("jurisdiction", "fi")
    .not("embedding", "is", null);
  if ((count ?? 0) < 10) {
    return {
      name: "sanity_query_fi_hol114",
      passed: true,
      detail: { skipped: "too few FI embeddings", embedded: count ?? 0 },
    };
  }

  const query = "menetetyn määräajan palauttaminen";
  let queryEmbedding: number[];
  try {
    const { embeddings } = await embedBatch([query]);
    queryEmbedding = embeddings[0];
  } catch (err) {
    return {
      name: "sanity_query_fi_hol114",
      passed: false,
      detail: { error: String(err) },
    };
  }

  // Call the law_search_v2 RPC — same path the chat layer uses.
  const vecStr = "[" + queryEmbedding.map((x) => x.toFixed(7)).join(",") + "]";
  const { data, error } = await sb.rpc("law_search_v2", {
    query_embedding: vecStr,
    jurisdiction_filter: "fi",
    match_threshold: 0.30,
    match_count: 3,
  });
  if (error) {
    return {
      name: "sanity_query_fi_hol114",
      passed: false,
      detail: { rpc_error: error.message },
    };
  }
  const top3 = (data as Array<{ act_slug: string; section_label: string; similarity: number }>) ?? [];
  const hit = top3.some((r) =>
    (r.act_slug ?? "").toLowerCase().includes("hol") ||
    (r.act_slug ?? "").toLowerCase().includes("hallintolaki") ||
    (r.section_label ?? "").includes("114")
  );
  return {
    name: "sanity_query_fi_hol114",
    passed: hit,
    detail: {
      query,
      top_3: top3.map((r) => ({
        act_slug: r.act_slug,
        section_label: r.section_label,
        similarity: r.similarity,
      })),
    },
  };
}

async function runValidators(sb: SBClient): Promise<ValidatorResult[]> {
  const results: ValidatorResult[] = [];

  // Pull sample of FI section_labels.
  const { data: fiLabels } = await sb
    .from("law_chunks_v2")
    .select("section_label")
    .eq("jurisdiction", "fi")
    .not("section_label", "is", null)
    .limit(20);
  results.push(
    validateFiCitationFormat((fiLabels ?? []).map((r) => r.section_label as string)),
  );

  // Pull sample of EE section_labels.
  const { data: eeLabels } = await sb
    .from("law_chunks_v2")
    .select("section_label")
    .eq("jurisdiction", "ee")
    .not("section_label", "is", null)
    .limit(20);
  results.push(
    validateEeCitationFormat((eeLabels ?? []).map((r) => r.section_label as string)),
  );

  // Sanity semantic query.
  results.push(await validateSanityQuery(sb));

  return results;
}

// ---------- main handler ----------

interface RequestBody {
  table?: string;
  batch_size?: number;
  max_batches?: number;
  run_validators?: boolean;
  secret?: string;
  /** Mode selector. Defaults to "fill" (process NULL embeddings).
   *  "re-embed-augmented" re-embeds ALL law_chunks_v2 rows reading from
   *  chunk_text_augmented; used for Day2-B §-precision push (2026-05-17). */
  mode?: "fill" | "re-embed-augmented";
  /** Optional resume marker for re-embed-augmented mode. If omitted, reads
   *  marker from kv_store. Allows external orchestrator to override. */
  resume_after_id?: string;
  /** Force re-start of re-embed-augmented from beginning (ignores marker). */
  reset_marker?: boolean;
}

serve(async (req: Request) => {
  const started = Date.now();

  if (req.method !== "POST" && req.method !== "GET") {
    return jsonError("method not allowed", 405);
  }

  // Config sanity.
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    return jsonError("SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY not set", 500);
  }
  if (!OPENAI_API_KEY) {
    return jsonError("OPENAI_API_KEY not set", 500);
  }

  // Auth: shared-secret header OR query param. The function is deployed
  // with --no-verify-jwt so the platform won't reject us, but we still
  // need to keep randoms out.
  // If CORPUS_EMBEDDER_SECRET is unset, refuse — fail closed.
  if (!CORPUS_EMBEDDER_SECRET) {
    return jsonError("CORPUS_EMBEDDER_SECRET not configured", 500);
  }
  const url = new URL(req.url);
  let body: RequestBody = {};
  if (req.method === "POST") {
    try {
      const text = await req.text();
      body = text ? JSON.parse(text) : {};
    } catch {
      return jsonError("invalid JSON body", 400);
    }
  }
  const providedSecret = req.headers.get("x-corpus-secret")
    ?? url.searchParams.get("secret")
    ?? body.secret
    ?? "";
  if (!timingSafeEqualStr(providedSecret, CORPUS_EMBEDDER_SECRET)) {
    return jsonError("unauthorized", 401);
  }

  // Parse params.
  const tableParam = (body.table ?? url.searchParams.get("table") ?? "all").toString();
  const tables: TableName[] = tableParam === "all"
    ? ALL_TABLES
    : ALL_TABLES.includes(tableParam as TableName)
      ? [tableParam as TableName]
      : [];
  if (tables.length === 0) {
    return jsonError(`invalid table: ${tableParam}`, 400);
  }

  const batchSize = Math.max(
    1,
    Math.min(
      MAX_BATCH_SIZE,
      Number(body.batch_size ?? url.searchParams.get("batch_size") ?? DEFAULT_BATCH_SIZE),
    ),
  );
  const maxBatches = Math.max(
    1,
    Math.min(
      MAX_MAX_BATCHES,
      Number(body.max_batches ?? url.searchParams.get("max_batches") ?? DEFAULT_MAX_BATCHES),
    ),
  );
  const runValidators = body.run_validators
    ?? (url.searchParams.get("run_validators") !== "false");

  // Service-role client.
  const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // ---- Mode switch: re-embed-augmented ----
  const mode = (body.mode ?? "fill") as "fill" | "re-embed-augmented";
  if (mode === "re-embed-augmented") {
    let cursor: string | null = body.reset_marker === true
      ? null
      : (body.resume_after_id ?? await readReaugMarker(sb));
    let processed = 0;
    let tokens = 0;
    let batchesDone = 0;
    const errs: string[] = [];

    for (let pass = 0; pass < maxBatches; pass++) {
      const out = await processReaugBatch(sb, batchSize, cursor);
      batchesDone++;
      if (out.err) errs.push(out.err);
      if (out.processed === 0) break; // exhausted
      processed += out.processed;
      tokens += out.tokens;
      cursor = out.newLastId;
      // Persist marker every batch so a crash doesn't lose progress.
      if (cursor) await writeReaugMarker(sb, cursor);
    }

    // Compute remaining: total rows with id > cursor.
    let remaining = 0;
    try {
      let q = sb
        .from("law_chunks_v2")
        .select("id", { count: "exact", head: true });
      if (cursor) q = q.gt("id", cursor);
      const { count } = await q;
      remaining = count ?? 0;
    } catch {
      remaining = -1;
    }

    return jsonOk({
      mode: "re-embed-augmented",
      processed,
      remaining,
      cursor,
      cost_usd: +(tokens * PRICE_PER_TOKEN_USD).toFixed(6),
      tokens,
      batches_used: batchesDone,
      elapsed_ms: Date.now() - started,
      errors: errs.length ? errs : undefined,
    });
  }

  // Round-robin: take one batch from each table per pass until we've used
  // our batch budget OR no table has any work left.
  const byTable: Record<TableName, TableOutcome> = {
    law_chunks_v2: { processed: 0, remaining: 0 },
    case_chunks:   { processed: 0, remaining: 0 },
    travaux:       { processed: 0, remaining: 0 },
  };
  const errors: string[] = [];
  let totalTokens = 0;
  let totalProcessed = 0;
  let batchesUsed = 0;

  outer: for (let pass = 0; pass < maxBatches; pass++) {
    let anyWork = false;
    for (const t of tables) {
      if (batchesUsed >= maxBatches) break outer;
      const out = await processBatch(sb, t, batchSize);
      batchesUsed++;
      if (out.err) errors.push(`${t}: ${out.err}`);
      if (out.processed > 0) {
        anyWork = true;
        byTable[t].processed += out.processed;
        totalTokens += out.tokens;
        totalProcessed += out.processed;
      }
    }
    if (!anyWork) break; // nothing left in any selected table
  }

  // Remaining counts (post-work).
  for (const t of ALL_TABLES) {
    try {
      byTable[t].remaining = await countRemaining(sb, t);
    } catch (err) {
      errors.push(`count ${t}: ${String(err)}`);
    }
  }
  const totalRemaining = ALL_TABLES.reduce((s, t) => s + byTable[t].remaining, 0);

  // Validators (cheap; skip if zero progress AND nothing embedded yet).
  let validators: ValidatorResult[] | null = null;
  if (runValidators) {
    try {
      validators = await runValidators_(sb);
    } catch (err) {
      errors.push(`validators: ${String(err)}`);
      validators = [];
    }
  }

  return jsonOk({
    processed:   totalProcessed,
    remaining:   totalRemaining,
    by_table:    byTable,
    cost_usd:    +(totalTokens * PRICE_PER_TOKEN_USD).toFixed(6),
    tokens:      totalTokens,
    elapsed_ms:  Date.now() - started,
    batches_used: batchesUsed,
    errors:      errors.length ? errors : undefined,
    validators,
  });
});

// Renamed to avoid shadowing the imported function inside the handler.
async function runValidators_(sb: SBClient): Promise<ValidatorResult[]> {
  return runValidators(sb);
}
