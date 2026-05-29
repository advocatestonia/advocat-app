// hudoc-fetcher — Phase 1 corpus build (2026-05-14)
// -----------------------------------------------------------------------------
// Worker that drains `ingest_jobs` rows WHERE source='hudoc' and writes
// chunks into `case_chunks`.
//
// Per-job payload contract (set by the seed migration):
//   {
//     "appno":      "23380/09",                    // ECtHR application number (required)
//     "case_name":  "Bouyid v Belgium",            // human-readable (required)
//     "court":      "ECtHR",                       // case_chunks.court enum
//     "jurisdiction":"echr",                       // case_chunks.jurisdiction
//     "decided_at": "2015-09-28",                  // ISO date (required for the column)
//     "legal_topics":["art-3","mistreatment"],    // optional array tags
//     "lang":       "en"                           // judgment language; default 'en'
//   }
//
// source_id = appno (with the "/" replaced by "_" because URL+queue
// hygiene). One job per ECtHR case — the worker fetches the merits
// judgment and chunks it.
//
// Rate-limit posture: HUDOC issues HTTP 429 aggressively. We stick to
// ~1 RPS and accept that draining the full Phase 1 list (15 ECtHR + 5
// CJEU + bonus) takes ~3 cron ticks.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  chunkHudocHtml,
  mergeMicroChunks,
  type HudocChunk,
} from "./chunker.ts";
import {
  fetchHudocDoc,
  HudocFetchError,
  searchByAppno,
} from "./fetcher.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";
const CRON_SECRET = Deno.env.get("CRON_SECRET");

const WORKER_ID_PREFIX = "hudoc-fetcher";
const LEASE_SECONDS = 180;
const MAX_JOBS_PER_INVOCATION = 8;
const MIN_INTER_FETCH_MS = 1_100;
const OPENAI_EMBED_URL = "https://api.openai.com/v1/embeddings";
const EMBED_MODEL = "text-embedding-3-small";
const EMBED_BATCH = 16;

const ALLOWED_COURTS = new Set([
  "KKO", "KHO", "Riigikohus", "HAO", "HoO", "HKK",
  "RKHK", "RKTK", "RKKK", "CJEU", "ECtHR",
]);
const ALLOWED_JURISDICTIONS = new Set(["fi", "ee", "eu", "echr"]);

interface JobPayload {
  appno?: string;
  case_name?: string;
  court?: string;
  jurisdiction?: string;
  decided_at?: string;
  legal_topics?: string[];
  lang?: string;
  /** Optional pre-resolved HUDOC itemid; bypasses the search step. */
  itemid?: string;
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
// import this file for the auth gate helpers and would otherwise fail
// with NotCapable (no --allow-net in test runs).
const IS_MAIN = import.meta.main;

const httpHandler = async (req: Request) => {
  if (req.method === "OPTIONS") return new Response(null, { status: 204 });
  if (req.method !== "POST") return jsonResp({ error: "Method not allowed" }, 405);

  const gate = checkCronSecret(req.headers.get("x-cron-secret"), CRON_SECRET);
  if (gate.kind === "deny") return jsonResp(gate.body, gate.status);

  if (!OPENAI_API_KEY) {
    return jsonResp({ error: "OPENAI_API_KEY not configured" }, 500);
  }

  const workerId = `${WORKER_ID_PREFIX}-${crypto.randomUUID().slice(0, 8)}`;
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const results = {
    worker_id: workerId,
    processed: 0,
    done: 0,
    failed: 0,
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
      await markFailed(supabase, job.id, msg);
      results.failed += 1;
      results.errors.push({ job_id: job.id, error: msg.slice(0, 240) });
    }

    if (i + 1 < MAX_JOBS_PER_INVOCATION) {
      await sleep(MIN_INTER_FETCH_MS);
    }
  }

  return jsonResp(results, 200);
};

if (IS_MAIN) {
  serve(httpHandler);
}

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
    console.warn(`hudoc-fetcher: dispatch error: ${error.message}`);
    return null;
  }
  if (!data || data.length === 0) return null;
  const row = data[0];
  if (row.source !== "hudoc") {
    // Release; this row belongs to another worker.
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
  const p = job.payload ?? {};
  const appno = p.appno;
  const caseName = p.case_name;
  const court = p.court ?? "ECtHR";
  const jurisdiction = p.jurisdiction ?? "echr";
  const decidedAt = p.decided_at;
  const legalTopics = Array.isArray(p.legal_topics) ? p.legal_topics : [];
  const lang = p.lang ?? "en";

  if (!appno || !caseName || !decidedAt) {
    throw new Error(
      `hudoc job ${job.id} missing required payload (appno/case_name/decided_at)`,
    );
  }
  if (!ALLOWED_COURTS.has(court)) {
    throw new Error(`hudoc job ${job.id} invalid court "${court}"`);
  }
  if (!ALLOWED_JURISDICTIONS.has(jurisdiction)) {
    throw new Error(`hudoc job ${job.id} invalid jurisdiction "${jurisdiction}"`);
  }

  // 1. Resolve itemid (skip if payload pre-resolved it).
  let itemid = p.itemid;
  if (!itemid) {
    const hit = await searchByAppno(appno);
    if (!hit) {
      throw new Error(`HUDOC: no merits judgment found for appno ${appno}`);
    }
    itemid = hit.itemid;
  }

  // 2. Fetch doc HTML.
  const doc = await fetchHudocDoc(itemid);

  // 3. Chunk + merge micro-chunks.
  await markChunking(supabase, job.id);
  const rawChunks = chunkHudocHtml(doc.html);
  const chunks = mergeMicroChunks(rawChunks);
  if (chunks.length === 0) {
    throw new Error(`No chunks extracted from HUDOC ${itemid} — chunker miss`);
  }

  // 4. Embed.
  await markEmbedding(supabase, job.id);
  const texts = chunks.map((c) => c.text);
  const embeddings = await embedAll(texts);

  // 5. Idempotent insert into case_chunks. Citation key for ECtHR is
  //    (case_number = appno, jurisdiction = echr). We delete prior rows
  //    for the same case before insert — keeps the corpus monotonically
  //    re-ingestable without ON CONFLICT migrations.
  const { error: delErr } = await supabase
    .from("case_chunks")
    .delete()
    .eq("case_number", appno)
    .eq("court", court);
  if (delErr) {
    throw new Error(`case_chunks delete failed: ${delErr.message}`);
  }

  const rows = chunks.map((c, idx) => ({
    jurisdiction,
    court,
    case_number: appno,
    decided_at: decidedAt,
    parties_redacted: caseName,
    paragraph_no: c.paragraph_no,
    text: c.text,
    text_type: c.text_type,
    legal_topics: legalTopics,
    statutes_cited: [],            // populated by a later enrichment pass
    key_holding: null,
    outcome: null,
    lang,
    embedding: embeddings[idx],
    source_url: doc.sourceUrl,
  }));

  // Insert in batches of 100 to stay under the 8s default statement
  // timeout. A single 486-row insert with 1536-dim vectors hit timeouts
  // on the largest ECtHR judgments (Big Brother Watch v UK).
  const INSERT_BATCH = 100;
  for (let i = 0; i < rows.length; i += INSERT_BATCH) {
    const slice = rows.slice(i, i + INSERT_BATCH);
    const { error: insErr } = await supabase.from("case_chunks").insert(slice);
    if (insErr) {
      throw new Error(
        `case_chunks insert failed (batch ${i}-${i + slice.length}): ${insErr.message}`,
      );
    }
  }

  return rows.length;
}

// =============================================================================
// Embeddings — same shape as eur-lex-fetcher; kept in-file to keep each
// edge fn deployable independently without a shared module.
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
// Shared helpers
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
