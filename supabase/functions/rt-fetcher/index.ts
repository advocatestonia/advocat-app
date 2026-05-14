// rt-fetcher Edge Function
// -----------------------------------------------------------------------------
// Phase 2 Pkg 1 — Ingest Estonian primary law (Riigi Teataja) into
// `public.law_chunks_v2`. Companion to finlex-fetcher (FI corpus) and
// eur-lex-fetcher (EU directives). Same target tables, same downstream
// consumers (legal-lookup, statutory-anchors, citation grounder).
//
// Wire format (operator-only — no public surface, deploy --no-verify-jwt):
//   POST /functions/v1/rt-fetcher
//   x-cron-secret: <CRON_SECRET>   OR   Authorization: Bearer <CRON_SECRET>
//   { "worker_id": string,           -- 1-32 chars, lease key
//     "max_jobs"?: number,           -- default 5, max 10 per invocation
//   }
//
//   200 OK
//   { "worker_id": string,
//     "processed": [
//       { "source_id": string, "target_table": "law_chunks_v2",
//         "status": "chunking"|"failed",
//         "chunks": number, "error"?: string }
//     ],
//     "took_ms": number }
//
// Why this design (and why the previous spec was wrong):
//   The original task spec referenced a hypothetical Riigi Teataja REST/JSON
//   API. There is NO such API. RT publishes per-act XML at a stable URL and
//   the discovery mechanism is HTML scraping the act-by-abbreviation
//   redirect. A previous agent caught the fake URL — we work with what RT
//   actually publishes:
//
//     Per-act XML : https://www.riigiteataja.ee/akt/{global_id}.xml
//     Discovery   : https://www.riigiteataja.ee/akt/{abbreviation}
//                   (returns the current redaktsioon page with a link to
//                    `.xml` containing the canonical global_id).
//
// Schema knowledge (verified 2026-05-14 against project okgnkucgwsytsondrjye):
//   ingest_jobs   : (source, source_id, target_table) UNIQUE; CHECK source
//                   IN (…, 'rt', …). payload JSONB; status default 'queued'.
//   law_chunks_v2 : jurisdiction/act_slug/act_full_name/text/lang/source_url
//                   are NOT NULL. No row-level uniqueness on (act_slug,
//                   section) — we delete-then-insert per (act_slug, lang).
//
// EE Citation format: `TsÜS § 86` (§ BEFORE the number). BINDING.
//
// Rate limiting:
//   • 2 req/sec/worker against riigiteataja.ee (sleep between calls).
//     Lower than finlex (1 req/s) because RT is on Cloudflare CDN and
//     handles burst traffic gracefully; their abuse-detection trips at
//     ~5 req/s sustained per IP.
//   • max_jobs<=10 per invocation hard cap so we always finish inside
//     Supabase's 60s wall-clock.
//   • Caller fires 3-4 parallel invocations with distinct worker_ids.
//
// User-Agent: We send `AdvocatBot/1.0 (+https://advocat.ee; contact:
// ops@advocat.ee)`. RT does not require it but is friendlier when we
// identify ourselves (Webmedia operations team monitors abuse logs).
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  ActMeta,
  aliasVariants,
  parseMetadata,
  parseStatuteXml,
  sectionLabel,
} from "./parser.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const CRON_SECRET = Deno.env.get("CRON_SECRET") ?? "";

const RT_BASE = "https://www.riigiteataja.ee";
const USER_AGENT = "AdvocatBot/1.0 (+https://advocat.ee; contact: ops@advocat.ee)";

const DEFAULT_MAX_JOBS = 5;
const HARD_MAX_JOBS = 10;
const LEASE_SECONDS = 120;
const FETCH_TIMEOUT_MS = 20_000;        // RT XML files can be 1MB+ (KarS ~1.1MB)
const REQ_INTERVAL_MS = 550;            // 2 req/sec/worker, +50ms safety margin

// In-process cache so a single worker invocation doesn't redundantly resolve
// the same abbreviation twice (defensive; today each abbreviation appears
// once per job batch, but future operations might re-queue).
const discoveryCache = new Map<string, string>();

// ────────────────────────────────────────────────────────────────────────────
// Public response helpers
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
// Riigi Teataja HTTP client + discovery
// ────────────────────────────────────────────────────────────────────────────

async function rtFetch(url: string, accept = "text/html,application/xml"): Promise<Response> {
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), FETCH_TIMEOUT_MS);
  try {
    return await fetch(url, {
      headers: {
        "User-Agent": USER_AGENT,
        "Accept": accept,
        "Accept-Language": "et,en;q=0.5",
      },
      signal: ctrl.signal,
    });
  } finally {
    clearTimeout(timer);
  }
}

function sleep(ms: number): Promise<void> {
  return new Promise((r) => setTimeout(r, ms));
}

/**
 * Normalise a Riigi Teataja date string (kehtivuseAlgus/Lopp) to a Postgres
 * timestamptz-compatible ISO string, or null if the input is missing /
 * unparseable. RT uses "2025-01-01" or "2025-01-01+03:00" — JavaScript's
 * Date constructor accepts the first but rejects the second (offset without
 * a time component is invalid per RFC 3339). We canonicalise by stripping
 * any trailing TZ offset and treating the bare YYYY-MM-DD as a wall date
 * at UTC midnight — adequate for our redaktsioon_valid_from/to range index.
 */
function toIsoOrNull(value: string | undefined): string | null {
  if (!value) return null;
  // Trim any RT-style trailing TZ offset that doesn't follow a time part.
  const trimmed = value.trim().replace(/^(\d{4}-\d{2}-\d{2})[+\-]\d{2}:\d{2}$/, "$1");
  const d = new Date(trimmed);
  if (isNaN(d.getTime())) return null;
  return d.toISOString();
}

/**
 * Resolve an EE statute abbreviation (e.g. "TsÜS", "KarS") to its current
 * canonical global_id (e.g. "131122024048").
 *
 * RT serves `/akt/{abbrev}` as a 200 page (NOT a 302 redirect) whose HTML
 * contains the canonical global_id in several places. We extract from the
 * `.xml` download link which is the most stable shape:
 *   <li><a href="https://www.riigiteataja.ee/akt/131122024048.xml">XML failina</a></li>
 *
 * This is HTML scraping by necessity — RT publishes NO machine-readable
 * directory or JSON API. The XSD schema (tyviseadus_1) hasn't changed
 * since 2010, and the HTML link structure has been stable since the 2018
 * rewrite. If RT ever changes this, our parser tests catch it and we'd
 * fall back to the URL pattern `akt/[0-9]{8,}\.xml` (already what we match).
 */
export async function resolveActSlugToGlobalId(
  abbreviation: string,
): Promise<{ globalId: string; xmlUrl: string }> {
  const cacheKey = abbreviation;
  const cached = discoveryCache.get(cacheKey);
  if (cached) {
    return { globalId: cached, xmlUrl: `${RT_BASE}/akt/${cached}.xml` };
  }

  // RT's URL accepts non-Latin abbreviations (TsÜS, VÕS, ÄS) directly;
  // encodeURIComponent encodes ÜÕÄ correctly.
  const url = `${RT_BASE}/akt/${encodeURIComponent(abbreviation)}`;
  const resp = await rtFetch(url, "text/html");
  if (!resp.ok) {
    throw new Error(
      `RT discovery for "${abbreviation}": HTTP ${resp.status} ${url}`,
    );
  }
  const html = await resp.text();
  // Extract the first global_id we see in the body — every internal RT
  // reference to "this act" uses the same id.
  const m = /akt\/(\d{8,})\.xml/.exec(html);
  if (!m) {
    throw new Error(
      `RT discovery for "${abbreviation}": no global_id found in HTML body (${html.length} chars)`,
    );
  }
  const globalId = m[1];
  discoveryCache.set(cacheKey, globalId);
  return { globalId, xmlUrl: `${RT_BASE}/akt/${globalId}.xml` };
}

// ────────────────────────────────────────────────────────────────────────────
// Job processing
// ────────────────────────────────────────────────────────────────────────────

interface StatutePayload {
  act_slug: string;   // "ee-tsus"
  act_name: string;   // "Tsiviilseadustiku üldosa seadus"
  act_abbrev?: string;// override; otherwise derived from source_id
  lang: string;       // "et"
}

interface JobRow {
  id: string;
  source: string;
  source_id: string;
  target_table: string | null;
  status: string | null;
  attempts: number | null;
  payload: Record<string, unknown> | null;
}

// Status state machine (matches public.ingest_jobs_status_check):
//   queued → fetching → chunking → embedding → done
//                                            └→ failed
// The fetcher's terminal state is 'chunking' on success: chunks are in
// law_chunks_v2 but their `embedding` column is still NULL until corpus-
// embedder runs.
type FinalStatus = "chunking" | "failed";

interface ProcessResult {
  source_id: string;
  target_table: string;
  status: FinalStatus;
  chunks: number;
  error?: string;
}

/** Derive the canonical abbreviation for EE citations from source_id/slug. */
function abbrevFromJob(payload: StatutePayload, sourceId: string): string {
  // source_id is the RT abbreviation (TsÜS, KarS, …) — exactly what we
  // need for the citation. The payload can override (rare).
  if (payload.act_abbrev) return payload.act_abbrev;
  return sourceId;
}

async function processStatuteJob(
  supabase: SupabaseClient,
  job: JobRow,
  _workerId: string,
): Promise<ProcessResult> {
  const payload = (job.payload ?? {}) as unknown as StatutePayload;
  if (!payload.act_slug || !payload.act_name) {
    throw new Error("payload missing act_slug/act_name");
  }

  // Step 1 — Discovery: resolve abbreviation → global_id + XML URL.
  await sleep(REQ_INTERVAL_MS);
  const { globalId, xmlUrl } = await resolveActSlugToGlobalId(job.source_id);

  // Step 2 — Fetch XML.
  await sleep(REQ_INTERVAL_MS);
  const resp = await rtFetch(xmlUrl, "application/xml");
  if (!resp.ok) {
    throw new Error(`fetch ${xmlUrl}: HTTP ${resp.status}`);
  }
  const xml = await resp.text();
  if (xml.length < 1000) {
    throw new Error(`fetch ${xmlUrl}: body too small (${xml.length} bytes)`);
  }
  if (!xml.includes("<oigusakt")) {
    throw new Error(`fetch ${xmlUrl}: not a tyviseadus XML (no <oigusakt> root)`);
  }

  const md = parseMetadata(xml);
  const lyhend = md.lyhend?.trim();
  // Treat the payload abbreviation as authoritative for citation (since
  // that's what users will type), but fall back to the XML's <lyhend>
  // if the payload didn't supply one explicitly.
  const abbrev = abbrevFromJob(payload, job.source_id);
  // Sanity: warn (not error) when the XML's lyhend disagrees — keeps us
  // visible in logs but doesn't block ingest.
  if (lyhend && lyhend !== abbrev) {
    console.warn(
      `rt-fetcher: source_id=${job.source_id} payload.abbrev=${abbrev} ` +
      `but XML <lyhend>=${lyhend} — using payload value`,
    );
  }

  const meta: ActMeta = {
    act_slug: payload.act_slug,
    act_abbrev: abbrev,
    act_full_name: payload.act_name,
    lang: payload.lang || "et",
    source_url: xmlUrl,
    global_id: globalId,
  };

  const sections = parseStatuteXml(xml);
  if (sections.length === 0) {
    throw new Error(`parser yielded 0 sections from ${xmlUrl}`);
  }

  // Step 3 — Idempotent insert: delete existing rows for (act_slug, lang)
  // first, matching the strategy finlex-fetcher uses.
  const { error: delErr } = await supabase
    .from("law_chunks_v2")
    .delete()
    .eq("act_slug", meta.act_slug)
    .eq("lang", meta.lang)
    .eq("jurisdiction", "ee");
  if (delErr) throw new Error(`delete law_chunks_v2: ${delErr.message}`);

  const { error: aliasDelErr } = await supabase
    .from("statute_aliases")
    .delete()
    .eq("act_slug", meta.act_slug);
  if (aliasDelErr) {
    throw new Error(`delete statute_aliases: ${aliasDelErr.message}`);
  }

  // kehtivuseAlgus/Lopp from metaandmed → redaktsioon_valid_from/to.
  // RT date formats observed in the wild:
  //   "2025-01-01"            (date only, treat as UTC midnight)
  //   "2025-01-01+03:00"      (date + EET offset — invalid JS Date input)
  //   "2025-01-01T00:00:00Z"  (rare; full ISO)
  // We normalise to UTC ISO so the timestamptz column accepts it cleanly.
  const validFrom = toIsoOrNull(md.kehtivuseAlgus);
  const validTo = toIsoOrNull(md.kehtivuseLopp);

  const chunkRows = sections.map((s) => ({
    jurisdiction: "ee",
    act_slug: meta.act_slug,
    act_full_name: meta.act_full_name,
    act_number: null, // RT has no FI-style act_number — global_id lives in version_hash
    chapter: s.chapter ?? null,
    section: s.num,
    section_label: sectionLabel(meta.act_abbrev, s.num, s.chapter),
    text: s.heading ? `${s.heading}\n\n${s.text}` : s.text,
    lang: meta.lang,
    source_url: meta.source_url,
    // version_hash records the RT global_id so we can detect when RT
    // publishes a new redaktsioon and we need to re-ingest.
    version_hash: globalId,
    redaktsioon_valid_from: validFrom,
    redaktsioon_valid_to: validTo,
  }));

  for (let i = 0; i < chunkRows.length; i += 500) {
    const slice = chunkRows.slice(i, i + 500);
    const { error: insErr } = await supabase
      .from("law_chunks_v2")
      .insert(slice);
    if (insErr) throw new Error(`insert law_chunks_v2 [${i}..]: ${insErr.message}`);
  }

  // Aliases — one rowset per section, 6 variants each, plus 3 act-level.
  const aliasRows: Array<{
    alias: string;
    act_slug: string;
    section: string;
    pattern_kind: string;
  }> = [];
  for (const s of sections) {
    for (const v of aliasVariants(meta, s.num, s.chapter)) {
      aliasRows.push({
        alias: v.alias,
        act_slug: meta.act_slug,
        section: s.num,
        pattern_kind: v.pattern_kind,
      });
    }
  }
  // Act-level aliases (no section) so "TsÜS" alone routes.
  for (const a of [
    meta.act_abbrev,
    meta.act_full_name,
    meta.act_full_name.toLowerCase(),
  ]) {
    aliasRows.push({
      alias: a,
      act_slug: meta.act_slug,
      section: "",
      pattern_kind: "exact",
    });
  }

  // Dedupe (same logic as finlex-fetcher — the functional unique index
  // uses COALESCE(section, '') so we have to guard against accidental
  // duplicates before insert).
  const dedup = new Map<string, typeof aliasRows[0]>();
  for (const r of aliasRows) {
    const key = `${r.alias}|${r.act_slug}|${r.section}`;
    if (!dedup.has(key)) dedup.set(key, r);
  }
  const aliasRowsDeduped = [...dedup.values()];

  for (let i = 0; i < aliasRowsDeduped.length; i += 500) {
    const slice = aliasRowsDeduped.slice(i, i + 500);
    const { error: aErr } = await supabase
      .from("statute_aliases")
      .insert(slice);
    if (aErr) throw new Error(`insert statute_aliases [${i}..]: ${aErr.message}`);
  }

  return {
    source_id: job.source_id,
    target_table: "law_chunks_v2",
    status: "chunking",
    chunks: chunkRows.length,
  };
}

async function leaseNextJob(
  supabase: SupabaseClient,
  workerId: string,
): Promise<JobRow | null> {
  const { data: candidates, error: selErr } = await supabase
    .from("ingest_jobs")
    .select("id, source, source_id, target_table, status, attempts, payload")
    .eq("source", "rt")
    .eq("target_table", "law_chunks_v2")
    .in("status", ["queued"])
    .order("priority", { ascending: true })
    .order("created_at", { ascending: true })
    .limit(1);
  if (selErr) throw new Error(`select ingest_jobs: ${selErr.message}`);
  if (!candidates || candidates.length === 0) return null;
  const cand = candidates[0] as JobRow;

  const leaseUntil = new Date(Date.now() + LEASE_SECONDS * 1000).toISOString();
  const { data: leased, error: upErr } = await supabase
    .from("ingest_jobs")
    .update({
      status: "fetching",
      worker_id: workerId,
      locked_until: leaseUntil,
      attempts: (cand.attempts ?? 0) + 1,
      updated_at: new Date().toISOString(),
    })
    .eq("id", cand.id)
    .eq("status", "queued") // lost-update guard against parallel workers
    .select("id, source, source_id, target_table, status, attempts, payload");
  if (upErr) throw new Error(`lease ingest_jobs: ${upErr.message}`);
  if (!leased || leased.length === 0) return null; // race lost
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

  if (!CRON_SECRET) {
    return err("Cron secret not configured", 500);
  }
  const headerSecret = req.headers.get("x-cron-secret") ?? "";
  const authHdr = req.headers.get("authorization") ?? "";
  const bearer = authHdr.replace(/^bearer\s+/i, "").trim();
  if (headerSecret !== CRON_SECRET && bearer !== CRON_SECRET) {
    return err("Unauthorized", 401);
  }

  let body: { worker_id?: string; max_jobs?: number };
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

  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    return err("Server misconfigured (no SUPABASE_SERVICE_ROLE_KEY)", 500);
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const started = Date.now();
  const processed: ProcessResult[] = [];

  for (let i = 0; i < maxJobs; i++) {
    let job: JobRow | null = null;
    try {
      job = await leaseNextJob(supabase, workerId);
    } catch (e) {
      console.error("leaseNextJob threw", e);
      processed.push({
        source_id: "(lease error)",
        target_table: "(unknown)",
        status: "failed",
        chunks: 0,
        error: String(e),
      });
      break;
    }
    if (!job) break;

    let result: ProcessResult;
    try {
      if (job.target_table === "law_chunks_v2") {
        result = await processStatuteJob(supabase, job, workerId);
      } else {
        result = {
          source_id: job.source_id,
          target_table: job.target_table ?? "(null)",
          status: "failed",
          chunks: 0,
          error: `unsupported target_table: ${job.target_table}`,
        };
      }
    } catch (e) {
      result = {
        source_id: job.source_id,
        target_table: job.target_table ?? "(unknown)",
        status: "failed",
        chunks: 0,
        error: String(e instanceof Error ? e.message : e),
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
