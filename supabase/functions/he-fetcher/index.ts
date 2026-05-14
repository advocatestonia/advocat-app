// he-fetcher — Travaux préparatoires ingestion worker (FI HE + EE eelnõud).
// -----------------------------------------------------------------------------
// Phase 2 corpus-v3 / Travaux killer feature, per Legal Architect:
//   "FI judges cite HE in reasoning — having the HE 217/1995 vp text linked
//    to HOL §114 is what turns Advocat from a citation engine into an
//    interpretation engine."
//
// Modes (selected via ?mode=...):
//
//   ?mode=seed     Populate ingest_jobs with the curated 30-doc catalogue.
//                  Idempotent (UNIQUE (source, source_id, target_table)
//                  in the schema prevents duplicates). Returns counts.
//
//   ?mode=work     Pull one or more travaux jobs off the queue via
//                  dispatch_ingest_job(), fetch, parse via Sonnet, embed,
//                  upsert into `travaux`, mark `done`. Default mode.
//                  Honours ?batch=N (default 1, max 10).
//
//   ?mode=status   Return queue + travaux counts. No side effects.
//
// Auth: service-role only (matches gold-scrubber / agent-intentions-cron).
//
// Idempotency:
//   The `travaux` table does NOT have a UNIQUE constraint on
//   (doc_kind, doc_number, section_ref). Adding one would require a
//   migration outside this PR's scope. We therefore implement
//   idempotency app-side: before inserting a doc's chunks, we DELETE any
//   prior rows with the same (doc_kind, doc_number). This means a re-run
//   replaces the previous extraction rather than producing duplicates.
//   Safe because each doc's chunks are self-contained.
//
// All DB writes use raw fetch against the PostgREST API (matches the
// gold-scrubber / agent-intentions-cron pattern in this codebase). That
// avoids the heavy supabase-js typing and keeps the cold-start lean.
//
// Cost guardrails:
//   - HE_FETCHER_MAX_INPUT_CHARS (350K) — Sonnet sees at most ~85K tok
//   - HE_FETCHER_MAX_TOKENS (8K out) — caps the output side
//   - Hard cap on chunks-per-doc (CHUNKS_PER_DOC_CAP = 80) prevents a
//     pathological prompt from inserting thousands of rows
//   - Embedding cost: 30 docs × ~80 chunks × ~500 tok ≈ 1.2M tok at $0.02/M
//     = $0.024. Negligible vs Sonnet.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { corsHeaders, jsonError, jsonOk } from "../_shared/auth.ts";
import {
  ExtractedTravauxChunk,
  HE_FETCHER_MAX_INPUT_CHARS,
  HE_FETCHER_MAX_TOKENS,
  HE_FETCHER_MODEL,
  HE_FETCHER_SYSTEM_PROMPT,
  HE_FETCHER_TIMEOUT_MS,
  parseTravauxOutput,
} from "./extractor_prompt.ts";
import { fetchSource } from "./fetch_source.ts";
import { ALL_SEEDS, TravauxSeed } from "./seed.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
  "";
const CRON_SECRET = Deno.env.get("CRON_SECRET") ?? "";
const CLAUDE_API_KEY = Deno.env.get("CLAUDE_API_KEY") ?? "";
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";

const ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages";
const OPENAI_EMBEDDINGS_URL = "https://api.openai.com/v1/embeddings";
const EMBEDDING_MODEL = "text-embedding-3-small";
const EMBEDDING_DIM = 1536;

const DEFAULT_BATCH = 1;
const MAX_BATCH = 10;
/** Hard ceiling on rows inserted per document — guard against a runaway prompt. */
const CHUNKS_PER_DOC_CAP = 80;
/** Embed-call timeout — generous because we batch sequentially. */
const EMBED_TIMEOUT_MS = 10_000;

// -----------------------------------------------------------------------------
// Types
// -----------------------------------------------------------------------------
interface IngestJob {
  id: string;
  source: string;
  source_id: string;
  target_table: string;
  payload: Record<string, unknown> | null;
}

interface WorkOutcome {
  job_id: string;
  source_id: string;
  doc_number: string;
  status: "done" | "failed";
  inserted_chunks?: number;
  error?: string;
}

// =============================================================================
// HTTP entry point
// =============================================================================
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST" && req.method !== "GET") {
    return jsonError("method not allowed", 405);
  }

  // ── Auth: service-role JWT OR CRON_SECRET ─────────────────────────────────
  // Two equivalent paths:
  //   - Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>  (legacy worker path)
  //   - x-cron-secret: <CRON_SECRET>                       (operator/cron path)
  const auth = req.headers.get("authorization") ?? "";
  const cronHdr = req.headers.get("x-cron-secret") ?? "";
  const okServiceRole = !!SUPABASE_SERVICE_ROLE_KEY &&
    auth === `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`;
  const okCron = !!CRON_SECRET && cronHdr === CRON_SECRET;
  if (!okServiceRole && !okCron) {
    return jsonError("service-role or x-cron-secret required", 401);
  }

  const url = new URL(req.url);
  const mode = (url.searchParams.get("mode") ?? "work").toLowerCase();
  const workerId = url.searchParams.get("worker_id") ??
    `he-fetcher-${crypto.randomUUID().slice(0, 8)}`;

  if (mode === "seed") {
    return await handleSeed();
  }
  if (mode === "status") {
    return await handleStatus();
  }
  if (mode === "work") {
    const batch = clampInt(
      url.searchParams.get("batch"),
      1,
      MAX_BATCH,
      DEFAULT_BATCH,
    );
    if (!CLAUDE_API_KEY) {
      return jsonError("CLAUDE_API_KEY not configured", 503);
    }
    if (!OPENAI_API_KEY) {
      return jsonError("OPENAI_API_KEY not configured", 503);
    }
    return await handleWork(workerId, batch);
  }
  return jsonError(`unknown mode: ${mode}`, 400);
});

// =============================================================================
// PostgREST helpers (service-role)
// =============================================================================
function pgHeaders(extra: Record<string, string> = {}): Record<string, string> {
  return {
    "Content-Type": "application/json",
    apikey: SUPABASE_SERVICE_ROLE_KEY,
    Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
    ...extra,
  };
}

async function pgPost(
  path: string,
  body: unknown,
  prefer = "return=minimal",
): Promise<Response> {
  return await fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    method: "POST",
    headers: pgHeaders({ Prefer: prefer }),
    body: JSON.stringify(body),
  });
}

async function pgPatch(path: string, body: unknown): Promise<Response> {
  return await fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    method: "PATCH",
    headers: pgHeaders({ Prefer: "return=minimal" }),
    body: JSON.stringify(body),
  });
}

async function pgDelete(path: string): Promise<Response> {
  return await fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    method: "DELETE",
    headers: pgHeaders({ Prefer: "return=minimal" }),
  });
}

async function pgRpc(name: string, args: unknown): Promise<Response> {
  return await fetch(`${SUPABASE_URL}/rest/v1/rpc/${name}`, {
    method: "POST",
    headers: pgHeaders(),
    body: JSON.stringify(args),
  });
}

// =============================================================================
// Mode: SEED — populate ingest_jobs with the curated catalogue
// =============================================================================
async function handleSeed(): Promise<Response> {
  // Build one batch payload — PostgREST honours `on_conflict=...` for upsert
  // via the Prefer header `resolution=ignore-duplicates`.
  const rows = ALL_SEEDS.map((seed) => ({
    source: seed.doc_kind === "HE" ? "he" : "eelnõu",
    source_id: seed.source_id,
    target_table: "travaux",
    status: "queued",
    priority: 5,
    payload: {
      url: seed.url,
      doc_kind: seed.doc_kind,
      doc_number: seed.doc_number,
      title: seed.title,
      year: seed.year,
      jurisdiction: seed.jurisdiction,
      related_act_slug: seed.related_act_slug,
    },
  }));

  const res = await fetch(
    `${SUPABASE_URL}/rest/v1/ingest_jobs?on_conflict=source,source_id,target_table`,
    {
      method: "POST",
      headers: pgHeaders({
        Prefer: "resolution=ignore-duplicates,return=minimal",
      }),
      body: JSON.stringify(rows),
    },
  );
  if (!res.ok) {
    const err = await res.text();
    return jsonError(`seed failed: ${err.slice(0, 300)}`, res.status);
  }
  return jsonOk({
    mode: "seed",
    catalogue_size: ALL_SEEDS.length,
    ensured: ALL_SEEDS.length,
  });
}

// =============================================================================
// Mode: STATUS — counts + sanity checks
// =============================================================================
async function handleStatus(): Promise<Response> {
  // travaux count (head + Prefer: count=exact)
  const travauxRes = await fetch(
    `${SUPABASE_URL}/rest/v1/travaux?select=id`,
    { method: "HEAD", headers: pgHeaders({ Prefer: "count=exact" }) },
  );
  const travauxCount = parseCountRange(
    travauxRes.headers.get("content-range"),
  );

  // ingest_jobs grouped by status (travaux target only)
  const queueRes = await fetch(
    `${SUPABASE_URL}/rest/v1/ingest_jobs?select=status&target_table=eq.travaux`,
    { method: "GET", headers: pgHeaders() },
  );
  const queueRows = queueRes.ok
    ? await queueRes.json() as Array<{ status: string }>
    : [];
  const tally: Record<string, number> = {};
  for (const r of queueRows) {
    tally[r.status] = (tally[r.status] ?? 0) + 1;
  }

  return jsonOk({
    mode: "status",
    travaux_rows: travauxCount,
    travaux_queue: tally,
    catalogue_size: ALL_SEEDS.length,
  });
}

/** Parse PostgREST `Content-Range: 0-9/42` → 42. Returns 0 on miss. */
export function parseCountRange(header: string | null): number {
  if (!header) return 0;
  const m = /\/(\d+)$/.exec(header);
  if (!m) return 0;
  const n = parseInt(m[1], 10);
  return Number.isFinite(n) ? n : 0;
}

// =============================================================================
// Mode: WORK — dispatch up to `batch` jobs and process them
// =============================================================================
async function handleWork(
  workerId: string,
  batch: number,
): Promise<Response> {
  const outcomes: WorkOutcome[] = [];

  for (let i = 0; i < batch; i++) {
    // Pull next job.
    const dispatchRes = await pgRpc("dispatch_ingest_job", {
      p_worker_id: workerId,
      p_lease_seconds: 600,
    });
    if (!dispatchRes.ok) {
      console.warn(
        `he-fetcher: dispatch failed ${dispatchRes.status}: ${
          (await dispatchRes.text()).slice(0, 200)
        }`,
      );
      break;
    }
    const jobs = await dispatchRes.json() as IngestJob[];
    const job = jobs[0];
    if (!job) break; // queue empty

    // We only handle travaux ingest.
    if (job.target_table !== "travaux") {
      await releaseJob(job.id, "non-travaux job — released");
      continue;
    }

    const payload = (job.payload ?? {}) as Record<string, unknown>;
    const seed = seedFromPayload(job, payload);
    if (!seed) {
      await failJob(job.id, "missing payload fields");
      outcomes.push({
        job_id: job.id,
        source_id: job.source_id,
        doc_number: "?",
        status: "failed",
        error: "missing payload fields",
      });
      continue;
    }

    try {
      const inserted = await processOneDoc(seed);
      await markDone(job.id);
      outcomes.push({
        job_id: job.id,
        source_id: job.source_id,
        doc_number: seed.doc_number,
        status: "done",
        inserted_chunks: inserted,
      });
    } catch (e) {
      const msg = (e instanceof Error ? e.message : String(e)).slice(0, 240);
      console.error(`he-fetcher job ${job.id} failed: ${msg}`);
      await failJob(job.id, msg);
      outcomes.push({
        job_id: job.id,
        source_id: job.source_id,
        doc_number: seed.doc_number,
        status: "failed",
        error: msg,
      });
    }
  }

  return jsonOk({ mode: "work", worker: workerId, processed: outcomes });
}

// -----------------------------------------------------------------------------
// processOneDoc — fetch → Sonnet → embed → upsert
// -----------------------------------------------------------------------------
export async function processOneDoc(seed: TravauxSeed): Promise<number> {
  // 1. Resolve the seed URL to either:
  //    (a) a PDF URL that Anthropic can fetch directly (preferred path), or
  //    (b) HTML-derived plain text we send inline.
  const fetched = await fetchSource(seed.url);

  // 2. Sonnet extraction.
  let sonnetRaw: string | null;
  if (fetched.contentType === "pdf") {
    // We HEAD-fetched the PDF only to confirm it exists; hand the URL to
    // Anthropic and let them ingest it server-side.
    sonnetRaw = await callSonnetWithPdfUrl(fetched.resolvedUrl, seed);
  } else {
    if (!fetched.text || fetched.text.length < 200) {
      throw new Error(`html source too short: ${fetched.text.length} chars`);
    }
    const text = fetched.text.length > HE_FETCHER_MAX_INPUT_CHARS
      ? fetched.text.slice(0, HE_FETCHER_MAX_INPUT_CHARS)
      : fetched.text;
    sonnetRaw = await callSonnetWithText(text, seed);
  }
  if (!sonnetRaw) throw new Error("sonnet returned null");
  const chunks = parseTravauxOutput(sonnetRaw);
  if (chunks.length === 0) throw new Error("sonnet returned 0 chunks");
  const capped = chunks.slice(0, CHUNKS_PER_DOC_CAP);

  // 4. Embed each chunk's text.
  const embedded: Array<ExtractedTravauxChunk & { embedding: number[] }> = [];
  for (const c of capped) {
    const emb = await embedText(c.text);
    if (emb) embedded.push({ ...c, embedding: emb });
  }
  if (embedded.length === 0) throw new Error("all embeddings failed");

  // 5. Idempotency: clear prior rows for this (doc_kind, doc_number).
  const delRes = await pgDelete(
    `travaux?doc_kind=eq.${encodeURIComponent(seed.doc_kind)}` +
      `&doc_number=eq.${encodeURIComponent(seed.doc_number)}`,
  );
  if (!delRes.ok) {
    // Not fatal — log loudly.
    console.warn(
      `he-fetcher: prior-rows DELETE failed ${delRes.status}: ${
        (await delRes.text()).slice(0, 200)
      }`,
    );
  }

  // 6. Bulk insert.
  const rows = embedded.map((c) => ({
    doc_kind: seed.doc_kind,
    doc_number: seed.doc_number,
    title: seed.title,
    jurisdiction: seed.jurisdiction,
    related_act_slug: seed.related_act_slug,
    section_ref: c.section_ref,
    text: c.text,
    embedding: c.embedding,
    source_url: seed.url,
    year: seed.year,
  }));
  const insRes = await pgPost("travaux", rows);
  if (!insRes.ok) {
    throw new Error(
      `insert failed ${insRes.status}: ${(await insRes.text()).slice(0, 200)}`,
    );
  }
  return rows.length;
}

// =============================================================================
// Anthropic call — single-shot Sonnet extraction
// =============================================================================
function buildDocHeader(seed: TravauxSeed): string {
  return [
    `Document: ${seed.doc_kind} ${seed.doc_number}`,
    `Title: ${seed.title}`,
    `Year: ${seed.year}`,
    `Jurisdiction: ${seed.jurisdiction.toUpperCase()}`,
    `Statute this document explains: ${seed.related_act_slug}`,
    "",
    "Read the attached document and emit JSON per the system prompt.",
  ].join("\n");
}

async function callSonnetWithText(
  text: string,
  seed: TravauxSeed,
): Promise<string | null> {
  const userPayload = [
    buildDocHeader(seed),
    "",
    "---- BEGIN DOCUMENT TEXT ----",
    text,
    "---- END DOCUMENT TEXT ----",
  ].join("\n");
  return await callAnthropic({
    model: HE_FETCHER_MODEL,
    max_tokens: HE_FETCHER_MAX_TOKENS,
    system: HE_FETCHER_SYSTEM_PROMPT,
    messages: [{ role: "user", content: userPayload }],
  });
}

async function callSonnetWithPdfUrl(
  pdfUrl: string,
  seed: TravauxSeed,
): Promise<string | null> {
  // Claude PDF URL source: Anthropic fetches the PDF directly. This avoids
  // base64-encoding multi-MB PDFs inside the Edge Function (Supabase memory
  // budget is 256 MB and base64 expansion + JSON envelope can OOM).
  return await callAnthropic({
    model: HE_FETCHER_MODEL,
    max_tokens: HE_FETCHER_MAX_TOKENS,
    system: HE_FETCHER_SYSTEM_PROMPT,
    messages: [{
      role: "user",
      content: [
        {
          type: "document",
          source: { type: "url", url: pdfUrl },
        },
        { type: "text", text: buildDocHeader(seed) },
      ],
    }],
  });
}

async function callAnthropic(body: Record<string, unknown>): Promise<string | null> {
  const ctl = new AbortController();
  const timer = setTimeout(
    () => ctl.abort("sonnet_timeout"),
    HE_FETCHER_TIMEOUT_MS,
  );
  try {
    const res = await fetch(ANTHROPIC_API_URL, {
      method: "POST",
      headers: {
        "x-api-key": CLAUDE_API_KEY,
        "anthropic-version": "2023-06-01",
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
      signal: ctl.signal,
    });
    clearTimeout(timer);
    if (!res.ok) {
      const errText = (await res.text()).slice(0, 500);
      console.warn(`he-fetcher: sonnet ${res.status} — ${errText}`);
      // Surface the error to the caller instead of just null so failJob() can
      // record a useful last_error.
      throw new Error(`anthropic ${res.status}: ${errText.slice(0, 240)}`);
    }
    const json = await res.json() as {
      content?: Array<{ type?: string; text?: string }>;
      stop_reason?: string;
    };
    const block = json.content?.find((b) => b?.type === "text");
    if (typeof block?.text !== "string") {
      console.warn(
        `he-fetcher: sonnet returned no text block — stop_reason=${
          json.stop_reason ?? "?"
        } content=${JSON.stringify(json.content ?? []).slice(0, 200)}`,
      );
      return null;
    }
    return block.text;
  } catch (e) {
    clearTimeout(timer);
    const msg = String(e).slice(0, 240);
    console.warn(`he-fetcher: sonnet call threw: ${msg}`);
    throw e;
  }
}

// =============================================================================
// OpenAI embedding
// =============================================================================
async function embedText(input: string): Promise<number[] | null> {
  const ctl = new AbortController();
  const timer = setTimeout(() => ctl.abort("embed_timeout"), EMBED_TIMEOUT_MS);
  try {
    const res = await fetch(OPENAI_EMBEDDINGS_URL, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${OPENAI_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: EMBEDDING_MODEL,
        // text-embedding-3-small's per-request limit is 8192 tokens. Our
        // chunks are bounded at 3000 chars (~750 tok) so we're safe.
        input,
        encoding_format: "float",
      }),
      signal: ctl.signal,
    });
    clearTimeout(timer);
    if (!res.ok) {
      console.warn(
        `he-fetcher: embed ${res.status} — ${(await res.text()).slice(0, 240)}`,
      );
      return null;
    }
    const json = await res.json() as {
      data?: Array<{ embedding?: number[] }>;
    };
    const emb = json.data?.[0]?.embedding;
    if (!Array.isArray(emb) || emb.length !== EMBEDDING_DIM) return null;
    return emb;
  } catch (e) {
    clearTimeout(timer);
    console.warn(`he-fetcher: embed call threw: ${String(e).slice(0, 240)}`);
    return null;
  }
}

// =============================================================================
// Queue state mutations
// =============================================================================
async function markDone(jobId: string): Promise<void> {
  const res = await pgPatch(`ingest_jobs?id=eq.${jobId}`, {
    status: "done",
    last_error: null,
    locked_until: null,
    updated_at: new Date().toISOString(),
  });
  if (!res.ok) {
    console.warn(
      `he-fetcher: mark done failed ${res.status}: ${
        (await res.text()).slice(0, 200)
      }`,
    );
  }
}

async function failJob(jobId: string, reason: string): Promise<void> {
  const res = await pgPatch(`ingest_jobs?id=eq.${jobId}`, {
    status: "failed",
    last_error: reason.slice(0, 500),
    locked_until: null,
    updated_at: new Date().toISOString(),
  });
  if (!res.ok) {
    console.warn(
      `he-fetcher: mark failed failed ${res.status}: ${
        (await res.text()).slice(0, 200)
      }`,
    );
  }
}

async function releaseJob(jobId: string, reason: string): Promise<void> {
  const res = await pgPatch(`ingest_jobs?id=eq.${jobId}`, {
    status: "queued",
    last_error: reason.slice(0, 500),
    locked_until: null,
    updated_at: new Date().toISOString(),
  });
  if (!res.ok) {
    console.warn(
      `he-fetcher: release failed ${res.status}: ${
        (await res.text()).slice(0, 200)
      }`,
    );
  }
}

// =============================================================================
// Helpers
// =============================================================================
export function seedFromPayload(
  job: IngestJob,
  payload: Record<string, unknown>,
): TravauxSeed | null {
  const url = typeof payload.url === "string" ? payload.url : null;
  const doc_kind = payload.doc_kind;
  const doc_number = typeof payload.doc_number === "string"
    ? payload.doc_number
    : null;
  const title = typeof payload.title === "string" ? payload.title : "";
  const year = typeof payload.year === "number" ? payload.year : 0;
  const jurisdiction = payload.jurisdiction === "fi" ||
      payload.jurisdiction === "ee"
    ? payload.jurisdiction
    : null;
  const related_act_slug = typeof payload.related_act_slug === "string"
    ? payload.related_act_slug
    : null;
  if (!url || !doc_number || !jurisdiction || !related_act_slug) return null;
  if (
    doc_kind !== "HE" && doc_kind !== "eelnõu" &&
    doc_kind !== "seletuskiri" && doc_kind !== "VN"
  ) return null;
  return {
    source_id: job.source_id,
    doc_kind,
    doc_number,
    title,
    year,
    jurisdiction,
    related_act_slug,
    url,
  };
}

export function clampInt(
  raw: string | null,
  lo: number,
  hi: number,
  fallback: number,
): number {
  if (!raw) return fallback;
  const n = Number.parseInt(raw, 10);
  if (!Number.isFinite(n)) return fallback;
  return Math.max(lo, Math.min(hi, n));
}

// =============================================================================
// Re-exports for tests
// =============================================================================
export { handleSeed, handleStatus, handleWork };
