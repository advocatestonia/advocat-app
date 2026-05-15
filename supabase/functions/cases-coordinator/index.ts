// cases-coordinator Edge Function
// -----------------------------------------------------------------------------
// Bridges `public.ingest_jobs` (case rows) → Railway cases-fetcher service →
// `public.case_chunks` (one row per paragraph).
//
// Wire-compatible with the existing finlex-fetcher / eur-lex-fetcher pattern:
//   POST /functions/v1/cases-coordinator
//   x-cron-secret: <CRON_SECRET>   (or Authorization: Bearer <CRON_SECRET>)
//   { "worker_id":  string,           -- 1-32 chars
//     "max_jobs"?:  number,           -- default 5, hard cap 10
//     "source"?:    "kko"|"kho"|"riigikohus"|"any" -- default "any"
//   }
//
//   200 OK
//   { "worker_id": string,
//     "processed": [
//       { "source_id": string, "case_number": string,
//         "status": "done"|"failed",
//         "chunks": number, "error"?: string }
//     ],
//     "took_ms": number }
//
// Auth: shared CRON_SECRET. NOT a public endpoint — invoked by pg_cron or by
// operator-driven backfill. We deploy with --no-verify-jwt.
//
// Why this lives separately from finlex-fetcher (sister fn):
//   - finlex-fetcher already had the 80 case jobs marked 'failed' with a
//     "Finlex AKN-LD3" last_error explaining the blocker.
//   - Cases need a headless browser (services/cases-fetcher on Railway).
//   - Source variety: KKO + KHO + Riigikohus + (future) HKK, HoO. Better to
//     keep the fetcher orchestrator separate from the statute orchestrator.
//
// Job payload contract (matches what finlex-fetcher seeded):
//   For source='finlex' (KKO/KHO seeded with court='KKO'|'KHO'):
//     { "court": "KKO"|"KHO", "case_year": N, "case_number": N, "lang":"fi", "ecli": "..." }
//   For source='kko' / 'kho' (future seeds, explicit source):
//     { "year": N, "number": N, "lang":"fi" }
//   For source='riigikohus':
//     { "case_number": "3-2-1-145-16", "lang":"et" }
//
// Idempotency: we DELETE FROM case_chunks WHERE court=X AND case_number=Y
// before re-inserting. The (source, source_id, target_table) UNIQUE on
// ingest_jobs already guarantees one job-row per case.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const CRON_SECRET = Deno.env.get("CRON_SECRET") ?? "";
const CASES_FETCHER_URL = Deno.env.get("CASES_FETCHER_URL") ?? "";
const CASES_FETCHER_SECRET = Deno.env.get("CASES_FETCHER_SECRET") ?? "";

const DEFAULT_MAX_JOBS = 5;
const HARD_MAX_JOBS = 10;
const LEASE_SECONDS = 180;
const FETCHER_TIMEOUT_MS = 75_000; // server.js scraper timeout (60s) + headroom

// ────────────────────────────────────────────────────────────────────────────
// HTTP helpers
// ────────────────────────────────────────────────────────────────────────────
function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
function err(msg: string, status: number, extra: Record<string, unknown> = {}) {
  return json({ error: msg, ...extra }, status);
}

// ────────────────────────────────────────────────────────────────────────────
// Types
// ────────────────────────────────────────────────────────────────────────────
type FinalStatus = "done" | "failed";

interface JobRow {
  id: string;
  source: string;
  source_id: string;
  target_table: string | null;
  status: string | null;
  attempts: number | null;
  payload: Record<string, unknown> | null;
}

interface ProcessResult {
  source_id: string;
  case_number: string;
  status: FinalStatus;
  chunks: number;
  error?: string;
}

interface FetcherParagraph {
  paragraph_no: string | null;
  text: string;
  text_type: "facts" | "ratio" | "obiter" | "dispositive" | string;
  section?: string | null;
}

interface FetcherResponse {
  ok: boolean;
  source: string;
  url: string;
  case_number: string;
  decided_at: string | null;
  title: string;
  keywords: string[];
  paragraphs: FetcherParagraph[];
  raw_text: string;
  court_chamber?: string | null;
  error?: string;
  took_ms?: number;
}

// ────────────────────────────────────────────────────────────────────────────
// Decide fetcher payload from ingest_jobs.payload shape
// ────────────────────────────────────────────────────────────────────────────
// Returns { source, body } or null if the job can't be translated.
function buildFetcherCall(job: JobRow):
  | { source: "kko" | "kho" | "riigikohus"; body: Record<string, unknown>; court: "KKO" | "KHO" | "Riigikohus" }
  | { error: string }
{
  const p = (job.payload ?? {}) as Record<string, unknown>;

  // Riigikohus by explicit source or by case_number pattern
  if (job.source === "riigikohus" || (typeof p.case_number === "string" && /\d-\d-\d|\d-\d{2}-\d{3,}/.test(p.case_number))) {
    const caseNum = String(p.case_number ?? "");
    if (!caseNum) return { error: "riigikohus job missing case_number in payload" };
    return {
      source: "riigikohus",
      court: "Riigikohus",
      body: { source: "riigikohus", case_number: caseNum, lang: p.lang ?? "et" },
    };
  }

  // KKO / KHO — payload can be either:
  //   {court:'KKO', case_year:N, case_number:N}  (finlex seeded)
  //   {year:N, number:N}                          (newer seed format)
  const court = (typeof p.court === "string" ? p.court : "").toUpperCase();
  let year: number | null = null;
  let number: number | null = null;
  if (typeof p.case_year === "number") year = p.case_year;
  else if (typeof p.year === "number") year = p.year;
  if (typeof p.case_number === "number") number = p.case_number;
  else if (typeof p.number === "number") number = p.number;

  if (!year || !number) {
    return { error: `cannot derive year/number from payload: ${JSON.stringify(p).slice(0, 200)}` };
  }

  if (court === "KKO" || job.source === "kko") {
    return {
      source: "kko",
      court: "KKO",
      body: { source: "kko", year, number, lang: p.lang ?? "fi" },
    };
  }
  if (court === "KHO" || job.source === "kho") {
    return {
      source: "kho",
      court: "KHO",
      body: { source: "kho", year, number, lang: p.lang ?? "fi" },
    };
  }
  return { error: `unknown court for job (source=${job.source}, court=${court})` };
}

// ────────────────────────────────────────────────────────────────────────────
// Call the Railway fetcher
// ────────────────────────────────────────────────────────────────────────────
async function callFetcher(body: Record<string, unknown>): Promise<FetcherResponse | { error: string }> {
  if (!CASES_FETCHER_URL || !CASES_FETCHER_SECRET) {
    return { error: "CASES_FETCHER_URL / CASES_FETCHER_SECRET not configured" };
  }
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), FETCHER_TIMEOUT_MS);
  try {
    const resp = await fetch(`${CASES_FETCHER_URL.replace(/\/$/, "")}/scrape`, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${CASES_FETCHER_SECRET}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
      signal: ctrl.signal,
    });
    if (!resp.ok) {
      const txt = await resp.text().catch(() => "");
      return { error: `fetcher HTTP ${resp.status}: ${txt.slice(0, 300)}` };
    }
    const data = (await resp.json()) as FetcherResponse;
    return data;
  } catch (e) {
    return { error: `fetcher fetch failed: ${e instanceof Error ? e.message : String(e)}` };
  } finally {
    clearTimeout(timer);
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Insert paragraphs into case_chunks (delete-then-insert per case)
// ────────────────────────────────────────────────────────────────────────────
async function persistCase(
  supabase: SupabaseClient,
  court: "KKO" | "KHO" | "Riigikohus",
  fetched: FetcherResponse,
  payloadLang: string,
): Promise<{ chunks: number; error?: string }> {
  if (!fetched.case_number || !fetched.decided_at) {
    return { chunks: 0, error: `fetcher missing case_number/decided_at (case=${fetched.case_number}, date=${fetched.decided_at})` };
  }
  if (!fetched.paragraphs?.length) {
    return { chunks: 0, error: "fetcher returned 0 paragraphs" };
  }

  // Map jurisdiction code by court
  const jurisdiction = court === "Riigikohus" ? "ee" : "fi";

  // Idempotency: wipe existing rows for this case before re-inserting
  const { error: delErr } = await supabase
    .from("case_chunks")
    .delete()
    .eq("court", court)
    .eq("case_number", fetched.case_number);
  if (delErr) return { chunks: 0, error: `delete case_chunks: ${delErr.message}` };

  // Filter out paragraphs that are too short (likely UI chrome, copyright
  // footers, breadcrumb text). 20 chars minimum keeps short dispositive
  // statements ("Kassationskaebust ei rahuldata.") while dropping garbage.
  const rows = fetched.paragraphs
    .filter((p) => typeof p.text === "string" && p.text.length >= 20)
    .map((p) => ({
      jurisdiction,
      court,
      case_number: fetched.case_number,
      decided_at: fetched.decided_at,
      paragraph_no: p.paragraph_no ?? null,
      text: p.text,
      text_type: ["facts", "ratio", "obiter", "dispositive"].includes(p.text_type)
        ? p.text_type
        : null,
      lang: payloadLang || (jurisdiction === "ee" ? "et" : "fi"),
      source_url: fetched.url || null,
      legal_topics: fetched.keywords?.length ? fetched.keywords : null,
    }));

  if (rows.length === 0) {
    return { chunks: 0, error: "all paragraphs filtered out (too short)" };
  }

  // Batch insert — case_chunks has no row-level unique index, plain insert is safe.
  for (let i = 0; i < rows.length; i += 500) {
    const slice = rows.slice(i, i + 500);
    const { error: insErr } = await supabase
      .from("case_chunks")
      .insert(slice);
    if (insErr) return { chunks: i, error: `insert case_chunks [${i}..]: ${insErr.message}` };
  }

  return { chunks: rows.length };
}

// ────────────────────────────────────────────────────────────────────────────
// Lease a job
// ────────────────────────────────────────────────────────────────────────────
async function leaseNextJob(
  supabase: SupabaseClient,
  workerId: string,
  sourceFilter: "kko" | "kho" | "riigikohus" | "any",
): Promise<JobRow | null> {
  // Look for case_chunks jobs in 'queued' OR previously-'failed' rows where
  // the failure was the FinlexAKN blocker we now resolve.
  let q = supabase
    .from("ingest_jobs")
    .select("id, source, source_id, target_table, status, attempts, payload, last_error")
    .eq("target_table", "case_chunks")
    .in("status", ["queued", "failed"])
    .order("priority", { ascending: true })
    .order("created_at", { ascending: true })
    .limit(1);

  // Source filter — for the finlex seeded rows source is 'finlex'.
  // The /any/ branch accepts everything; explicit kko/kho/riigikohus filters
  // either by source column OR by payload.court for legacy rows.
  if (sourceFilter === "riigikohus") {
    q = q.eq("source", "riigikohus");
  } else if (sourceFilter === "kko") {
    // Either source='kko' OR (source='finlex' AND payload->>court='KKO')
    q = q.or("source.eq.kko,and(source.eq.finlex,payload->>court.eq.KKO)");
  } else if (sourceFilter === "kho") {
    q = q.or("source.eq.kho,and(source.eq.finlex,payload->>court.eq.KHO)");
  } else {
    // any — restrict to known case sources
    q = q.in("source", ["finlex", "kko", "kho", "riigikohus"]);
  }

  // For failed rows, only re-attempt the FinlexAKN blocker class.
  // We do this by a server-side filter: failed AND last_error starts with
  // "Finlex AKN-LD3". This keeps genuinely bad rows (404s, parse errors)
  // out of the work pool.
  const { data: candidates, error: selErr } = await q;
  if (selErr) throw new Error(`select ingest_jobs: ${selErr.message}`);
  if (!candidates || candidates.length === 0) return null;

  const cand = candidates[0] as JobRow & { last_error?: string | null };
  if (cand.status === "failed") {
    const le = (cand.last_error ?? "").trim();
    if (!le.startsWith("Finlex AKN-LD3")) {
      // Skip this row by selecting the next batch — return null and let
      // the caller move on (one cycle wasted but never re-runs broken work).
      return null;
    }
  }

  // Lease: status → fetching with worker_id
  const leaseUntil = new Date(Date.now() + LEASE_SECONDS * 1000).toISOString();
  const { data: leased, error: upErr } = await supabase
    .from("ingest_jobs")
    .update({
      status: "fetching",
      worker_id: workerId,
      locked_until: leaseUntil,
      attempts: (cand.attempts ?? 0) + 1,
      last_error: null,
      updated_at: new Date().toISOString(),
    })
    .eq("id", cand.id)
    .in("status", ["queued", "failed"])
    .select("id, source, source_id, target_table, status, attempts, payload");
  if (upErr) throw new Error(`lease ingest_jobs: ${upErr.message}`);
  if (!leased || leased.length === 0) return null;
  return leased[0] as JobRow;
}

async function finalizeJob(
  supabase: SupabaseClient,
  job: JobRow,
  result: ProcessResult,
): Promise<void> {
  const update: Record<string, unknown> = {
    updated_at: new Date().toISOString(),
    worker_id: null,
    locked_until: null,
    status: result.status,
    last_error: result.status === "failed" ? (result.error ?? "unknown failure") : null,
  };
  const { error } = await supabase
    .from("ingest_jobs")
    .update(update)
    .eq("id", job.id);
  if (error) {
    console.error("finalize ingest_jobs failed", error.message, job.id);
  }
}

// ────────────────────────────────────────────────────────────────────────────
// HTTP entry
// ────────────────────────────────────────────────────────────────────────────
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204 });
  }
  if (req.method !== "POST") {
    return err("Method not allowed", 405);
  }

  if (!CRON_SECRET) return err("Cron secret not configured", 500);
  const headerSecret = req.headers.get("x-cron-secret") ?? "";
  const bearer = (req.headers.get("authorization") ?? "").replace(/^bearer\s+/i, "").trim();
  if (headerSecret !== CRON_SECRET && bearer !== CRON_SECRET) {
    return err("Unauthorized", 401);
  }

  let body: { worker_id?: string; max_jobs?: number; source?: string };
  try {
    body = await req.json();
  } catch {
    return err("Invalid JSON body", 400);
  }

  const workerId = (typeof body.worker_id === "string" ? body.worker_id : "").trim();
  if (!workerId || workerId.length > 32) {
    return err("worker_id required (1-32 chars)", 400);
  }
  const maxJobs = Math.min(
    HARD_MAX_JOBS,
    Math.max(1, typeof body.max_jobs === "number" ? body.max_jobs : DEFAULT_MAX_JOBS),
  );
  const sourceFilter = (
    body.source === "kko" || body.source === "kho" || body.source === "riigikohus"
      ? body.source
      : "any"
  ) as "kko" | "kho" | "riigikohus" | "any";

  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    return err("Server misconfigured (no SUPABASE_SERVICE_ROLE_KEY)", 500);
  }
  if (!CASES_FETCHER_URL || !CASES_FETCHER_SECRET) {
    return err("Server misconfigured (no CASES_FETCHER_URL / _SECRET)", 500);
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const started = Date.now();
  const processed: ProcessResult[] = [];

  for (let i = 0; i < maxJobs; i++) {
    let job: JobRow | null = null;
    try {
      job = await leaseNextJob(supabase, workerId, sourceFilter);
    } catch (e) {
      console.error("leaseNextJob threw", e);
      processed.push({
        source_id: "(lease error)",
        case_number: "",
        status: "failed",
        chunks: 0,
        error: String(e),
      });
      break;
    }
    if (!job) break;

    let result: ProcessResult;
    try {
      const decision = buildFetcherCall(job);
      if ("error" in decision) {
        result = { source_id: job.source_id, case_number: "", status: "failed", chunks: 0, error: decision.error };
      } else {
        const lang =
          typeof job.payload?.lang === "string"
            ? job.payload.lang as string
            : decision.court === "Riigikohus"
            ? "et"
            : "fi";

        const fetcherResp = await callFetcher(decision.body);
        if ("error" in fetcherResp) {
          result = { source_id: job.source_id, case_number: "", status: "failed", chunks: 0, error: fetcherResp.error };
        } else if (!fetcherResp.ok) {
          result = {
            source_id: job.source_id,
            case_number: fetcherResp.case_number ?? "",
            status: "failed",
            chunks: 0,
            error: fetcherResp.error ?? "fetcher reported ok=false",
          };
        } else {
          const persist = await persistCase(supabase, decision.court, fetcherResp, lang);
          if (persist.error) {
            result = {
              source_id: job.source_id,
              case_number: fetcherResp.case_number,
              status: "failed",
              chunks: persist.chunks,
              error: persist.error,
            };
          } else {
            result = {
              source_id: job.source_id,
              case_number: fetcherResp.case_number,
              status: "done",
              chunks: persist.chunks,
            };
          }
        }
      }
    } catch (e) {
      result = {
        source_id: job.source_id,
        case_number: "",
        status: "failed",
        chunks: 0,
        error: e instanceof Error ? e.message : String(e),
      };
    }
    await finalizeJob(supabase, job, result);
    processed.push(result);
  }

  return json({
    worker_id: workerId,
    processed,
    took_ms: Date.now() - started,
  });
});
