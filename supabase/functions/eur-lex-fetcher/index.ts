// eur-lex-fetcher — Phase 1 corpus build (2026-05-14)
// -----------------------------------------------------------------------------
// Cron-driven (or manually invoked) worker that drains `ingest_jobs` rows
// WHERE source='eur-lex' and writes chunks into `law_chunks_v2`.
//
// Mirror of the deadline-radar-tick pattern:
//   * x-cron-secret header gate (operationally callable only by pg_cron)
//   * service-role Supabase client (RLS bypass needed for INSERT into
//     law_chunks_v2 and UPDATE on ingest_jobs)
//   * bounded work per invocation (MAX_JOBS_PER_INVOCATION) so the
//     150s edge-function wall clock is never the bottleneck — the worker
//     drains as much as it can, then exits cleanly. The next cron tick
//     picks up where this one left off (FOR UPDATE SKIP LOCKED makes
//     this safe even with overlap).
//
// Per-job payload contract (set by the seed migration):
//   {
//     "celex":   "32004L0038",            // CELEX ID (required)
//     "act_slug":"eu-dir-2004-38",        // slug for law_chunks_v2.act_slug
//     "act_full_name":"Directive 2004/38/EC ...",
//     "act_number":"2004/38/EC",
//     "languages":["EN","FI","ET"]        // optional — defaults to all three
//   }
//
// Idempotency: the UNIQUE (source, source_id, target_table) constraint on
// ingest_jobs already gives us "one job per (CELEX, language) tuple"; we
// encode language into the source_id as `${celex}:${lang}` (lowercase
// language to match URL convention) so the seed can enqueue one row per
// (directive, language) and the worker handles each independently.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { chunkEurLexHtml, type EurLexChunk } from "./chunker.ts";
import { EurLexFetchError, fetchEurLex, type EurLexLang } from "./fetcher.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";
const CRON_SECRET = Deno.env.get("CRON_SECRET");

const WORKER_ID_PREFIX = "eur-lex-fetcher";
const LEASE_SECONDS = 180;
const MAX_JOBS_PER_INVOCATION = 12;          // 12 × (fetch + chunk + embed) ≈ 90s
const MIN_INTER_FETCH_MS = 1_100;            // ~1 RPS to EUR-Lex
const OPENAI_EMBED_URL = "https://api.openai.com/v1/embeddings";
const EMBED_MODEL = "text-embedding-3-small";
const EMBED_BATCH = 16;                      // OpenAI accepts up to 2048; 16 is a safe latency floor

interface JobPayload {
  celex?: string;
  act_slug?: string;
  act_full_name?: string;
  act_number?: string;
  languages?: string[];
}

interface DispatchedJob {
  id: string;
  source: string;
  source_id: string;
  target_table: string | null;
  payload: JobPayload | null;
}

// =============================================================================
// HTTP entry
// =============================================================================
//
// Only boot the HTTP listener when this module is the entry point. Tests
// import this file for `checkCronSecret` + `hashShort` and would otherwise
// fail with NotCapable (no --allow-net in test runs) because `serve` starts
// listening at top level.
const IS_MAIN = import.meta.main;

const httpHandler = async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204 });
  }
  if (req.method !== "POST") {
    return jsonResp({ error: "Method not allowed" }, 405);
  }

  const gate = checkCronSecret(req.headers.get("x-cron-secret"), CRON_SECRET);
  if (gate.kind === "deny") return jsonResp(gate.body, gate.status);

  if (!OPENAI_API_KEY) {
    return jsonResp({ error: "OPENAI_API_KEY not configured" }, 500);
  }

  const workerId = `${WORKER_ID_PREFIX}-${crypto.randomUUID().slice(0, 8)}`;
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  const results = {
    worker_id: workerId,
    processed: 0,
    done: 0,
    failed: 0,
    skipped_no_translation: 0,
    chunks_inserted: 0,
    errors: [] as Array<{ job_id: string; error: string }>,
  };

  for (let i = 0; i < MAX_JOBS_PER_INVOCATION; i++) {
    const job = await dispatchOne(supabase, workerId);
    if (!job) break;
    results.processed += 1;

    try {
      const inserted = await processJob(supabase, job);
      results.chunks_inserted += inserted;
      await markDone(supabase, job.id);
      results.done += 1;
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      // Soft-skip when EUR-Lex has no translation in this language.
      if (err instanceof EurLexFetchError && (err.status === 204 || err.status === 404)) {
        await markDone(supabase, job.id, `no-translation: ${msg}`);
        results.skipped_no_translation += 1;
      } else {
        await markFailed(supabase, job.id, msg);
        results.failed += 1;
        results.errors.push({ job_id: job.id, error: msg.slice(0, 240) });
      }
    }

    // ~1 RPS pacing to EUR-Lex (only sleep between jobs, not after the
    // final one we're about to break out of).
    if (i + 1 < MAX_JOBS_PER_INVOCATION) {
      await sleep(MIN_INTER_FETCH_MS);
    }
  }

  return jsonResp(results, 200);
};

if (IS_MAIN) {
  serve(httpHandler);
}

// Export for integration tests that want to exercise the handler directly
// without booting an HTTP listener.
export { httpHandler };

// =============================================================================
// Worker steps
// =============================================================================

async function dispatchOne(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  workerId: string,
): Promise<DispatchedJob | null> {
  const { data, error } = await supabase.rpc("dispatch_ingest_job", {
    p_worker_id: workerId,
    p_lease_seconds: LEASE_SECONDS,
  });
  if (error) {
    console.warn(`eur-lex-fetcher: dispatch_ingest_job error: ${error.message}`);
    return null;
  }
  if (!data || data.length === 0) return null;
  const row = data[0];
  if (row.source !== "eur-lex") {
    // We pulled a non-eur-lex job by accident (single shared queue).
    // Release the lease immediately so the right worker can pick it up.
    // Setting locked_until = now() expires the lease at the next dispatch.
    await supabase
      .from("ingest_jobs")
      .update({ status: "queued", locked_until: new Date().toISOString() })
      .eq("id", row.id);
    return null;
  }
  return row as DispatchedJob;
}

async function processJob(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  job: DispatchedJob,
): Promise<number> {
  const payload = job.payload ?? {};
  const celex = payload.celex;
  const actSlug = payload.act_slug;
  const actFullName = payload.act_full_name ?? actSlug ?? celex ?? "Unknown EU act";
  const actNumber = payload.act_number ?? null;

  if (!celex || !actSlug) {
    throw new Error(`eur-lex job ${job.id} missing celex or act_slug`);
  }

  // Convention: source_id = "<CELEX>:<lang>" (lowercase lang). One job per language.
  const m = job.source_id.match(/^([A-Z0-9]+):([a-z]{2})$/);
  if (!m) {
    throw new Error(
      `eur-lex source_id "${job.source_id}" does not match "<CELEX>:<lang>"`,
    );
  }
  const langLower = m[2];
  const langUpper = langLower.toUpperCase() as EurLexLang;
  if (!["EN", "FI", "ET"].includes(langUpper)) {
    throw new Error(`eur-lex unsupported language: ${langUpper}`);
  }
  const chunkLang = langLower as "en" | "fi" | "et";

  // 1. Fetch
  const { html, sourceUrl } = await fetchEurLex(celex, langUpper);

  // 2. Chunk
  const chunks = chunkEurLexHtml(html, chunkLang);
  if (chunks.length === 0) {
    throw new Error(`No chunks extracted from ${celex} (${langUpper}) — chunker miss`);
  }

  // 3. Embed in batches
  await markChunking(supabase, job.id);
  const texts = chunks.map((c) => c.text);
  const embeddings = await embedAll(texts);
  if (embeddings.length !== chunks.length) {
    throw new Error(
      `Embedding count ${embeddings.length} != chunk count ${chunks.length}`,
    );
  }

  // 4. Insert into law_chunks_v2
  await markEmbedding(supabase, job.id);
  const rows = chunks.map((c, idx) => ({
    jurisdiction: "eu",
    act_slug: actSlug,
    act_full_name: actFullName,
    act_number: actNumber,
    chapter: null,
    section: c.section,
    subsection: c.subsection,
    section_label: c.section_label,
    text: c.text,
    lang: chunkLang === "en" ? "en" : chunkLang,        // law_chunks_v2.lang: fi/sv/et/en
    redaktsioon_valid_from: null,                       // base CELEX → current consolidated, no pin
    redaktsioon_valid_to: null,
    version_hash: hashShort(c.text),
    embedding: embeddings[idx],
    source_url: sourceUrl,
  }));

  // Idempotency: delete existing chunks for (act_slug, lang) before insert.
  // Cheaper and safer than ON CONFLICT — the (act_slug, section, lang)
  // tuple is not a unique key today, and adding one would require a
  // migration we don't want to ship under this task's narrow scope.
  const { error: delErr } = await supabase
    .from("law_chunks_v2")
    .delete()
    .eq("act_slug", actSlug)
    .eq("lang", chunkLang);
  if (delErr) {
    throw new Error(`law_chunks_v2 delete failed: ${delErr.message}`);
  }

  // Bulk insert. Supabase JS handles batches transparently up to ~1k rows.
  const { error: insErr } = await supabase.from("law_chunks_v2").insert(rows);
  if (insErr) {
    throw new Error(`law_chunks_v2 insert failed: ${insErr.message}`);
  }

  return rows.length;
}

// =============================================================================
// Embeddings
// =============================================================================

async function embedAll(texts: string[]): Promise<number[][]> {
  const out: number[][] = [];
  for (let i = 0; i < texts.length; i += EMBED_BATCH) {
    const slice = texts.slice(i, i + EMBED_BATCH);
    const vectors = await embedBatch(slice);
    out.push(...vectors);
  }
  return out;
}

async function embedBatch(inputs: string[]): Promise<number[][]> {
  const resp = await fetch(OPENAI_EMBED_URL, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${OPENAI_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: EMBED_MODEL,
      input: inputs,
      encoding_format: "float",
    }),
  });
  if (!resp.ok) {
    const detail = await resp.text().catch(() => "");
    throw new Error(`OpenAI embeddings ${resp.status}: ${detail.slice(0, 240)}`);
  }
  const json = await resp.json() as {
    data?: Array<{ embedding?: number[] }>;
  };
  const out = (json.data ?? []).map((d) => d.embedding ?? []);
  if (out.some((v) => v.length !== 1536)) {
    throw new Error(`OpenAI returned wrong-dimension embedding (expected 1536)`);
  }
  return out;
}

// =============================================================================
// Job state transitions
// =============================================================================

// deno-lint-ignore no-explicit-any
async function markChunking(supabase: any, jobId: string) {
  await supabase
    .from("ingest_jobs")
    .update({ status: "chunking", updated_at: new Date().toISOString() })
    .eq("id", jobId);
}

// deno-lint-ignore no-explicit-any
async function markEmbedding(supabase: any, jobId: string) {
  await supabase
    .from("ingest_jobs")
    .update({ status: "embedding", updated_at: new Date().toISOString() })
    .eq("id", jobId);
}

// deno-lint-ignore no-explicit-any
async function markDone(supabase: any, jobId: string, note?: string) {
  await supabase
    .from("ingest_jobs")
    .update({
      status: "done",
      last_error: note ?? null,
      locked_until: null,
      worker_id: null,
      updated_at: new Date().toISOString(),
    })
    .eq("id", jobId);
}

// deno-lint-ignore no-explicit-any
async function markFailed(supabase: any, jobId: string, msg: string) {
  await supabase
    .from("ingest_jobs")
    .update({
      status: "failed",
      last_error: msg.slice(0, 2_000),
      locked_until: null,
      worker_id: null,
      updated_at: new Date().toISOString(),
    })
    .eq("id", jobId);
}

// =============================================================================
// Helpers
// =============================================================================

export type GateResult =
  | { kind: "allow" }
  | { kind: "deny"; status: number; body: { error: string } };

export function checkCronSecret(
  header: string | null,
  envSecret: string | undefined,
): GateResult {
  if (!envSecret) {
    return { kind: "deny", status: 500, body: { error: "Cron secret not configured" } };
  }
  if (!header) {
    return { kind: "deny", status: 401, body: { error: "Missing cron secret" } };
  }
  if (header !== envSecret) {
    return { kind: "deny", status: 401, body: { error: "Invalid cron secret" } };
  }
  return { kind: "allow" };
}

function jsonResp(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function sleep(ms: number): Promise<void> {
  return new Promise((r) => setTimeout(r, ms));
}

/** djb2 → 12 hex chars. Stable across runs for the same input — good
 *  enough for `version_hash` change-detection without crypto cost. */
export function hashShort(s: string): string {
  let h = 5381;
  for (let i = 0; i < s.length; i++) {
    h = ((h * 33) ^ s.charCodeAt(i)) >>> 0;
  }
  return h.toString(16).padStart(8, "0").slice(0, 12);
}
