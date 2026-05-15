// finlex-fetcher Edge Function
// -----------------------------------------------------------------------------
// Phase 2 Pkg 1 — Ingest Finnish primary law (Finlex Open Data) into
// `public.law_chunks_v2` and `public.case_chunks`. Companion to the EE corpus
// ingester (scripts/ingest_law_corpus.ts) — same target tables, same
// citation format (`HOL 114 §`), same downstream consumers (legal-lookup,
// statutory-anchors, citation grounder).
//
// Wire format (operator-only — no public surface):
//   POST /functions/v1/finlex-fetcher
//   Authorization: Bearer <CRON_SECRET>
//   { "worker_id":   string,           -- 1-32 chars, used to lease rows
//     "max_jobs"?:   number,           -- default 5, max 10 per invocation
//     "kind"?:       "statute" | "case" | "any"   -- default "any"
//   }
//
//   200 OK
//   { "worker_id": string,
//     "processed": [
//       { "source_id": string, "target_table": string,
//         "status": "chunked"|"failed"|"blocked",
//         "chunks": number, "error"?: string }
//     ],
//     "took_ms": number }
//
// Auth: shared `CRON_SECRET`. This function is NOT for end users — it is
// invoked by an Edge-Functions cron (configured separately) or by an operator
// running the rate-limited backfill. We deploy with --no-verify-jwt because
// the cron driver does not pass user JWTs.
//
// Schema knowledge (verified 2026-05-14 against project okgnkucgwsytsondrjye):
//   ingest_jobs   : (source, source_id, target_table) UNIQUE; payload JSONB;
//                   status default 'queued'; locked_until + worker_id leasing.
//   law_chunks_v2 : jurisdiction/act_slug/act_full_name/text/lang/source_url
//                   are NOT NULL; section/section_label/etc are nullable.
//                   No row-level uniqueness on (act_slug, section) — we
//                   delete-then-insert per (act_slug, lang) for idempotency.
//   case_chunks   : court/case_number/decided_at/text NOT NULL. No unique
//                   index; same delete-then-insert idempotency strategy.
//
// Citation format: `section_label` MUST be `{ACT_ABBREV} {N} §` (FI: § AFTER
// number). e.g. "HOL 114 §". statute_aliases gets 6+ variants per § to
// support fuzzy operator search (covered by lookup_statute RPC + chat).
//
// Rate limiting (Finlex abuse-detection is real, owner has been bitten
// before):
//   • 1 req/sec/worker against opendata.finlex.fi (sleep between each call).
//   • max_jobs<=10 per invocation hard cap so a single edge-function run
//     completes inside Supabase's 60s wall clock.
//   • Caller is expected to fire 3 parallel invocations with distinct
//     worker_id values — that's where 3-way parallelism comes from.
//
// KKO/KHO case ingestion is currently disabled — see CASE_FETCH_BLOCKED
// below. The 80 case jobs are still seeded so the ingestion pipeline is
// visible and reportable; they remain in status='queued' until a follow-up
// agent wires the www.finlex.fi HTML route through Playwright (the RSC
// payload is the bottleneck — see finlex-fetcher/CASES.md).
//
// User-Agent: Finlex Open Data requires User-Agent (their OpenAPI marks it
// required). We send `AdvocatBot/1.0 (+https://advocat.ee; contact: ops@advocat.ee)`.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  ActMeta,
  aliasVariants,
  parseStatuteXml,
  sectionLabel,
} from "./parser.ts";
import { splitAllOversize } from "../_shared/chunk_splitter.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const CRON_SECRET = Deno.env.get("CRON_SECRET") ?? "";

const FINLEX_BASE = "https://opendata.finlex.fi/finlex/avoindata/v1";
const USER_AGENT = "AdvocatBot/1.0 (+https://advocat.ee; contact: ops@advocat.ee)";

const DEFAULT_MAX_JOBS = 5;
const HARD_MAX_JOBS = 10;
const LEASE_SECONDS = 120; // 2× the 60s wall clock so we never strand a job
const FETCH_TIMEOUT_MS = 15_000;
const REQ_INTERVAL_MS = 1100; // 1 req/sec/worker, +100ms safety margin

const CASE_FETCH_BLOCKED = true;
const CASE_FETCH_BLOCKED_REASON =
  "Finlex AKN-LD3 judgment endpoints return 404 for every documentType " +
  "variant (supreme-court, precedent, kko, …) as of 2026-05-14. The bulk " +
  "download host data.finlex.fi is also dead. www.finlex.fi case pages " +
  "render judgment body lazily via Next.js RSC payload, requiring a " +
  "headless-browser fetcher. See finlex-fetcher/CASES.md for the unblock " +
  "plan. Job retained in queued status for re-dispatch.";

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

// Citation utilities + AKN-LD3 parser live in ./parser.ts so the test suite
// can import them as pure ESM without source-text reflection. See parser.ts
// for the canonical `HOL 114 §` citation format and the six-variant alias
// expansion that powers fuzzy lookup.

// ────────────────────────────────────────────────────────────────────────────
// Finlex HTTP client
// ────────────────────────────────────────────────────────────────────────────

async function finlexFetch(url: string, accept = "application/xml"): Promise<Response> {
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), FETCH_TIMEOUT_MS);
  try {
    return await fetch(url, {
      headers: {
        "User-Agent": USER_AGENT,
        "Accept": accept,
      },
      signal: ctrl.signal,
    });
  } finally {
    clearTimeout(timer);
  }
}

/**
 * For a given act (year, number), discover the original-text (alkup) URI.
 *
 * Licence compliance — CRITICAL: We ingest **statute** (CC BY 4.0, original
 * promulgated text) and NOT **statute-consolidated** (CC BY-NC 4.0, which
 * forbids commercial use). See app/advocat_project/docs/legal/corpus_licences.md
 * §2.2 for the legal analysis.
 *
 * Tradeoff: the original text does not include amendments — so for older
 * acts (RL 1889, OK 1734, AvioliittoL 1929) the alkup version is the
 * 19th-century baseline. We accept this gap because (a) the existing EE
 * + FI shells take the same approach, (b) building amendment-merging
 * via Akoma Ntoso `<textualMod>` is a separate Phase 3 effort, and
 * (c) the alkup text is still legally useful as the structural skeleton.
 *
 * URL discovery: Finlex uses TWO URI shapes:
 *   - Modern acts (post-launch revamp): /act/statute/{year}/{num}/fin@
 *     e.g. /act/statute/2003/434/fin@  (HOL)
 *   - Older / re-cataloged acts (multiple amendment files): /act/statute/{year}/{num}-{fileIdx}/fin@
 *     e.g. /act/statute/1889/39-001/fin@  (RL — main file is -001)
 *
 * Strategy: try the modern shape directly (HEAD), fall back to listing-based
 * discovery if the direct path 404s. The list endpoint returns 5–10 items per
 * page and 2003 alone has ~1000 statutes, so pagination is expensive — but
 * the fallback is rare in practice because most Phase-1 priority acts use
 * the modern shape.
 */
async function findOriginalActUri(
  year: string,
  actNumber: string,
): Promise<{ uri: string } | null> {
  // 1. Direct shape
  const directUri = `${FINLEX_BASE}/akn/fi/act/statute/${year}/${actNumber}/fin@`;
  const direct = await finlexFetch(directUri);
  if (direct.ok) {
    const text = await direct.text();
    // Empty match envelope (`<AknXmlList><Results/></AknXmlList>`) is a 200
    // miss. Real act bodies start with `<akomaNtoso`.
    if (text.length > 1000 && text.startsWith("<akomaNtoso")) {
      return { uri: directUri };
    }
  }

  // 2. Suffixed shape (-001 / -000) — walk the listing.
  // The list endpoint returns oldest-first within a year; modern 2024+ acts
  // appear on early pages, older re-cataloged acts often on later pages.
  // We cap pagination at 200 pages (~2000 entries / year) — every year we
  // care about has <1100 fin@ entries.
  let page = 1;
  while (page <= 200) {
    const url = new URL(`${FINLEX_BASE}/akn/fi/act/statute/list`);
    url.searchParams.set("startYear", year);
    url.searchParams.set("endYear", year);
    url.searchParams.set("limit", "10");
    url.searchParams.set("page", String(page));
    const resp = await finlexFetch(url.toString(), "application/json");
    if (!resp.ok) {
      throw new Error(`Finlex list ${url}: HTTP ${resp.status}`);
    }
    const rows: Array<{ akn_uri: string; status?: string }> = await resp.json();
    if (!Array.isArray(rows) || rows.length === 0) break;

    for (const row of rows) {
      // Accept either `{num}/fin@` (modern) or `{num}-{fileIdx}/fin@` (older).
      const m = row.akn_uri.match(
        /\/act\/statute\/(\d{4})\/(\d+)(?:-(\d{3}))?\/(fin)@$/,
      );
      if (!m) continue;
      const [, yYear, yActNum, fileIdx, lang] = m;
      if (yYear !== year || yActNum !== actNumber || lang !== "fin") continue;
      if (!fileIdx || fileIdx === "001" || fileIdx === "000") {
        return { uri: row.akn_uri };
      }
    }

    if (rows.length < 10) break;
    page++;
    await sleep(REQ_INTERVAL_MS);
  }

  return null;
}

/**
 * For a given act (year, number), discover the LATEST consolidated/ajantasa
 * URI under /akn/fi/act/statute-consolidated/{year}/{num}/fin@.
 *
 * Licence posture (Option B, 2026-05-15): consolidated text is Finlex
 * CC-BY-NC-4.0. We tag every chunk inserted from this URI with
 * license='CC-BY-NC-4.0' and display_policy='snippet_only' so legal_lookup
 * caps user-facing quotes at 200 chars + Finlex link. See
 * `business/legal/finlex_licensing_decision_2026-05-14.md`.
 *
 * URL discovery strategy mirrors `findOriginalActUri` (alkup) with two key
 * differences:
 *   1. Direct shape `{year}/{num}/fin@` works for some acts (OHO 808/2019
 *      returns a 220 KB XML body). HOL 434/2003 — and most older acts that
 *      have been amended multiple times — return 404 on that shape; their
 *      canonical URI carries an `@YYYYNNNN` expressionId suffix selecting
 *      the latest redaktsioon.
 *   2. The listing endpoint is /statute-consolidated/list and emits URIs
 *      like `2003/434/fin@20250541`. When multiple expression versions are
 *      present we pick the lexically GREATEST (=latest @-date) because
 *      Finlex sorts redaktsioonit chronologically and dates are zero-padded.
 *
 * Returns null when the act is not present in the consolidated index (some
 * very old acts have alkup but no consolidated entry).
 */
async function findConsolidatedActUri(
  year: string,
  actNumber: string,
): Promise<{ uri: string } | null> {
  // 1. Direct shape — fast path for un-amended acts.
  const directUri =
    `${FINLEX_BASE}/akn/fi/act/statute-consolidated/${year}/${actNumber}/fin@`;
  const direct = await finlexFetch(directUri);
  if (direct.ok) {
    const text = await direct.text();
    if (text.length > 1000 && text.startsWith("<akomaNtoso")) {
      return { uri: directUri };
    }
  }

  // 2. Listing-based discovery. The endpoint returns `{num}/fin@{expressionId}`
  // entries for amended acts. We collect every match and pick the latest
  // expression by lexicographic max (Finlex pads expressionIds, so string
  // ordering matches chronological ordering for the same act_number).
  let latestUri: string | null = null;
  let latestExpressionId: string | null = null;
  let page = 1;
  while (page <= 200) {
    const url = new URL(
      `${FINLEX_BASE}/akn/fi/act/statute-consolidated/list`,
    );
    url.searchParams.set("startYear", year);
    url.searchParams.set("endYear", year);
    url.searchParams.set("limit", "10");
    url.searchParams.set("page", String(page));
    const resp = await finlexFetch(url.toString(), "application/json");
    if (!resp.ok) {
      throw new Error(
        `Finlex consolidated list ${url}: HTTP ${resp.status}`,
      );
    }
    const rows: Array<{ akn_uri: string; status?: string }> = await resp
      .json();
    if (!Array.isArray(rows) || rows.length === 0) break;

    for (const row of rows) {
      // statute-consolidated URIs have NO `-NNN` file index, only an
      // optional `@YYYYNNNN` expressionId after `fin@`.
      const m = row.akn_uri.match(
        /\/act\/statute-consolidated\/(\d{4})\/(\d+)\/fin@(\d*)$/,
      );
      if (!m) continue;
      const [, yYear, yActNum, expressionId] = m;
      if (yYear !== year || yActNum !== actNumber) continue;
      // Empty expression → the "head" URI (rare in this endpoint); take it
      // if no dated version found yet.
      if (!expressionId) {
        if (!latestUri) latestUri = row.akn_uri;
      } else if (
        !latestExpressionId || expressionId > latestExpressionId
      ) {
        latestExpressionId = expressionId;
        latestUri = row.akn_uri;
      }
    }

    if (rows.length < 10) break;
    page++;
    await sleep(REQ_INTERVAL_MS);
  }

  return latestUri ? { uri: latestUri } : null;
}

function sleep(ms: number): Promise<void> {
  return new Promise((r) => setTimeout(r, ms));
}

// ────────────────────────────────────────────────────────────────────────────
// Job processing
// ────────────────────────────────────────────────────────────────────────────

interface StatutePayload {
  act_slug: string;     // "fi-hol"
  act_name: string;     // "Hallintolaki"
  act_number: string;   // "434/2003"
  act_abbrev?: string;  // override; otherwise derived from slug
  lang: string;         // "fi"
  /**
   * Which Finlex redaktsioon to ingest (Option B, 2026-05-15).
   *
   *   'alkup'    — original-as-enacted, /act/statute/.../fin@.
   *                License: CC-BY-4.0 / public-domain text under §9.
   *                Display: full (no truncation beyond 700-char snippet).
   *
   *   'ajantasa' — consolidated current text,
   *                /act/statute-consolidated/.../fin@.
   *                License: CC-BY-NC-4.0 (Finlex compilation right).
   *                Display: snippet_only (≤200 chars + Finlex link required).
   *
   * Defaults to 'alkup' so the existing seed_jobs.sql payloads (which omit
   * the field) keep their current behaviour. Per
   * business/legal/finlex_licensing_decision_2026-05-14.md the 'ajantasa'
   * path is gated by display_policy='snippet_only' in legal_lookup; raising
   * it without that gate re-opens the licence-risk envelope.
   */
  redaktsioon?: "alkup" | "ajantasa";
}

interface CasePayload {
  court: string;        // "KKO" | "KHO"
  year: number;         // 2024
  case_number: number;  // 82  →  KKO:2024:82
  lang?: string;        // "fi" default
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
// We DO NOT transition to 'embedding' or 'done' here — the embedder (corpus-
// embedder #59) picks up rows in status='chunking' and finishes them. The
// fetcher's terminal state is 'chunking' on success: chunks are in the
// table but their `embedding` column is still NULL until the embedder runs.
//
// For blocked work (case_chunks pending headless-browser fetcher) we set
// status='failed' with a sticky `last_error` so the row is visible to ops
// dashboards but not re-attempted on every cycle.
type FinalStatus = "chunking" | "failed";

interface ProcessResult {
  source_id: string;
  target_table: string;
  status: FinalStatus;
  chunks: number;
  error?: string;
}

/** Derive the canonical abbreviation we use for FI citations from the slug. */
function abbrevFromSlug(slug: string, override?: string): string {
  if (override) return override.toUpperCase();
  // slug is "fi-hol" → "HOL"; "fi-rl" → "RL"; etc.
  const tail = slug.replace(/^fi-/, "");
  return tail.toUpperCase();
}

async function processStatuteJob(
  supabase: SupabaseClient,
  job: JobRow,
  workerId: string,
): Promise<ProcessResult> {
  const payload = (job.payload ?? {}) as unknown as StatutePayload;
  if (!payload.act_slug || !payload.act_name || !payload.act_number) {
    throw new Error("payload missing act_slug/act_name/act_number");
  }

  // source_id format: "YYYY/NNN" (alkup) or "YYYY/NNN:ajantasa" (Option B,
  // 2026-05-15). Ajantasa rows use a distinct source_id so the UNIQUE index
  // on (source, source_id, target_table) does not collide with the matching
  // alkup row. We strip the suffix here — the discriminator that selects
  // alkup vs ajantasa endpoint lives in `payload.redaktsioon`, not in the
  // job key. Either format parses to the same (year, actNumber) pair.
  const sm = job.source_id.match(/^(\d{4})\/(\d+)(?::ajantasa)?$/);
  if (!sm) {
    throw new Error(
      `bad source_id (expected YYYY/N or YYYY/N:ajantasa): ${job.source_id}`,
    );
  }
  const [, year, actNumber] = sm;

  // ── Redaktsioon selection (Option B, 2026-05-15) ──────────────────────
  // 'alkup'    : default; CC-BY-4.0 / public-domain text, display_policy full.
  // 'ajantasa' : opt-in; CC-BY-NC-4.0, display_policy snippet_only.
  // Anything else falls back to 'alkup' rather than throwing — old payloads
  // (omit the field) remain valid.
  const redaktsioon: "alkup" | "ajantasa" =
    payload.redaktsioon === "ajantasa" ? "ajantasa" : "alkup";

  await sleep(REQ_INTERVAL_MS);
  const discovered = redaktsioon === "ajantasa"
    ? await findConsolidatedActUri(year, actNumber)
    : await findOriginalActUri(year, actNumber);
  if (!discovered) {
    const which = redaktsioon === "ajantasa"
      ? "statute-consolidated (CC-BY-NC-4.0)"
      : "statute (alkup, CC-BY 4.0)";
    throw new Error(
      `no ${which} found for ${year}/${actNumber} (lang=fin)`,
    );
  }
  const meta: ActMeta = {
    act_slug: payload.act_slug,
    act_abbrev: abbrevFromSlug(payload.act_slug, payload.act_abbrev),
    act_full_name: payload.act_name,
    act_number: payload.act_number,
    lang: payload.lang || "fi",
    source_url: discovered.uri,
  };

  // License + display_policy tags for this pass. Mirrors the column defaults
  // in law_chunks_v2: alkup rows can rely on the DB defaults, but we set
  // them explicitly so the ingest is self-documenting and re-runs are
  // idempotent if the defaults ever change.
  const chunkLicense = redaktsioon === "ajantasa"
    ? "CC-BY-NC-4.0"
    : "public-domain";
  const chunkDisplayPolicy = redaktsioon === "ajantasa"
    ? "snippet_only"
    : "full";

  await sleep(REQ_INTERVAL_MS);
  const resp = await finlexFetch(discovered.uri);
  if (!resp.ok) {
    throw new Error(`fetch ${discovered.uri}: HTTP ${resp.status}`);
  }
  const xml = await resp.text();
  if (xml.length < 1000) {
    throw new Error(
      `fetch ${discovered.uri}: body too small (${xml.length} bytes)`,
    );
  }
  const sections = parseStatuteXml(xml);
  if (sections.length === 0) {
    throw new Error(`parser yielded 0 sections from ${discovered.uri}`);
  }

  // ── Idempotent insert: delete existing rows for this (act_slug, lang) first.
  // Both alkup and ajantasa share the same (act_slug, lang) key; running an
  // ajantasa pass therefore REPLACES the alkup corpus for that act. This is
  // intentional — ajantasa is the superset (alkup baseline + amendments +
  // post-enactment sections like OHO §114), and the legal_lookup display
  // policy is what enforces the snippet cap downstream.
  const { error: delErr } = await supabase
    .from("law_chunks_v2")
    .delete()
    .eq("act_slug", meta.act_slug)
    .eq("lang", meta.lang)
    .eq("jurisdiction", "fi");
  if (delErr) throw new Error(`delete law_chunks_v2: ${delErr.message}`);

  const { error: aliasDelErr } = await supabase
    .from("statute_aliases")
    .delete()
    .eq("act_slug", meta.act_slug);
  if (aliasDelErr) {
    throw new Error(`delete statute_aliases: ${aliasDelErr.message}`);
  }

  // Build chunk + alias batches. `subsection` defaults to null; the splitter
  // overrides it to "osa N/M" when a § is too dense for OpenAI's 8192-token
  // embedding cap.
  const rawChunkRows = sections.map((s) => ({
    jurisdiction: "fi",
    act_slug: meta.act_slug,
    act_full_name: meta.act_full_name,
    act_number: meta.act_number,
    chapter: s.chapter ?? null,
    section: s.num,
    subsection: null as string | null,
    section_label: sectionLabel(meta.act_abbrev, s.num, s.chapter),
    text: s.heading ? `${s.heading}\n\n${s.text}` : s.text,
    lang: meta.lang,
    source_url: meta.source_url,
    license: chunkLicense,
    display_policy: chunkDisplayPolicy,
    // version_hash records the source redaktsioon — alkup keeps the original
    // "alkup-{actNumber}" tag; ajantasa rows are stamped "ajantasa-{actNumber}"
    // so a follow-up reconciliation pass can tell them apart from alkup runs.
    version_hash: `${redaktsioon}-${meta.act_number}`,
    redaktsioon_valid_from: null,
    redaktsioon_valid_to: null,
  }));
  // Split any § that exceeds the embedding-safe MAX_CHARS into "osa N/M"
  // parts so the corpus-embedder can process every chunk in one shot.
  const chunkRows = splitAllOversize(rawChunkRows);

  // Batch insert in 500-row chunks (PG keeps complaining over ~1000 cols total).
  for (let i = 0; i < chunkRows.length; i += 500) {
    const slice = chunkRows.slice(i, i + 500);
    const { error: insErr } = await supabase
      .from("law_chunks_v2")
      .insert(slice);
    if (insErr) throw new Error(`insert law_chunks_v2 [${i}..]: ${insErr.message}`);
  }

  // Aliases — one alias rowset per section, 6 variants each.
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
  // Also a few act-level aliases (no section) so "HOL" alone routes.
  // section="" because the unique index uses COALESCE(section,'') — empty
  // string and NULL collide, but explicit '' is what existing code paths
  // in the EE corpus use.
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

  // We just deleted all aliases for this act_slug above, so a plain insert
  // is safe. We cannot use upsert(onConflict: "alias,act_slug,section")
  // because the unique index is functional (uses COALESCE(section, ''))
  // and PostgREST onConflict only supports plain column lists.
  //
  // Dedupe in-memory to avoid the rare case where two different sections
  // happen to produce the same alias (e.g. "§ 1 RL" generated from chapter
  // 1:section 1 AND from a section-only alias for RL 1). The functional
  // unique index would still reject; in-memory dedupe makes us idempotent.
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

async function processCaseJob(
  _supabase: SupabaseClient,
  job: JobRow,
  _workerId: string,
): Promise<ProcessResult> {
  // See CASE_FETCH_BLOCKED_REASON. The schema's check constraint only
  // allows {queued, fetching, chunking, embedding, done, failed} — there
  // is no 'blocked' state, so case jobs land in 'failed' with a sticky
  // last_error explaining why. A follow-up agent that wires the headless-
  // browser fetcher can re-queue them with:
  //   UPDATE ingest_jobs SET status='queued', last_error=NULL
  //     WHERE source='finlex' AND target_table='case_chunks' AND last_error LIKE 'Finlex AKN-LD3%';
  return {
    source_id: job.source_id,
    target_table: job.target_table ?? "case_chunks",
    status: "failed",
    chunks: 0,
    error: CASE_FETCH_BLOCKED_REASON,
  };
}

/**
 * Pop one job, lock it for this worker, run it, write final status. Returns
 * null when no more eligible jobs exist.
 *
 * We use a 2-step lease (UPDATE + SELECT) instead of FOR UPDATE SKIP LOCKED
 * RPC to keep the function self-contained — under load the optimistic
 * `eq("status","queued")` filter is sufficient because the unique
 * (source,source_id,target_table) constraint makes duplicate processing
 * harmless (delete-then-insert per act_slug).
 */
async function leaseNextJob(
  supabase: SupabaseClient,
  workerId: string,
  kindFilter: "statute" | "case" | "any",
): Promise<JobRow | null> {
  // First find a candidate
  let q = supabase
    .from("ingest_jobs")
    .select("id, source, source_id, target_table, status, attempts, payload")
    .eq("source", "finlex")
    .in("status", ["queued"])
    .order("priority", { ascending: true })
    .order("created_at", { ascending: true })
    .limit(1);

  if (kindFilter === "statute") {
    q = q.eq("target_table", "law_chunks_v2");
  } else if (kindFilter === "case") {
    q = q.eq("target_table", "case_chunks");
  }

  const { data: candidates, error: selErr } = await q;
  if (selErr) throw new Error(`select ingest_jobs: ${selErr.message}`);
  if (!candidates || candidates.length === 0) return null;
  const cand = candidates[0] as JobRow;

  // Attempt to lease it: transition queued → fetching with worker_id.
  // 'fetching' is the lease state; we move to 'chunking' on success.
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
  if (!leased || leased.length === 0) {
    // Another worker beat us to it — caller will retry the loop.
    return null;
  }
  return leased[0] as JobRow;
}

async function finalizeJob(
  supabase: SupabaseClient,
  job: JobRow,
  result: ProcessResult,
): Promise<void> {
  // Terminal states the fetcher writes:
  //   - 'chunking'  — chunks inserted, awaiting embedder
  //   - 'failed'    — anything broke OR case work is blocked pending
  //                   headless-browser fetcher (sticky `last_error`)
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
    // Last-ditch: log and let monitoring catch the orphaned lease (the
    // 2-minute lease expiry will free it).
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

  // Cron-secret auth — bypasses Supabase JWT verification (deploy with
  // --no-verify-jwt). Two accepted shapes (sister fetchers use x-cron-secret,
  // the task spec used Authorization: Bearer — we accept both for cron
  // driver flexibility):
  //   1. x-cron-secret: <CRON_SECRET>     (preferred; matches eur-lex-fetcher)
  //   2. Authorization: Bearer <CRON_SECRET>
  if (!CRON_SECRET) {
    return err("Cron secret not configured", 500);
  }
  const headerSecret = req.headers.get("x-cron-secret") ?? "";
  const authHdr = req.headers.get("authorization") ?? "";
  const bearer = authHdr.replace(/^bearer\s+/i, "").trim();
  if (headerSecret !== CRON_SECRET && bearer !== CRON_SECRET) {
    return err("Unauthorized", 401);
  }

  // Parse body
  let body: { worker_id?: string; max_jobs?: number; kind?: string };
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
  const kind = body.kind === "statute" || body.kind === "case" ? body.kind : "any";

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
      job = await leaseNextJob(supabase, workerId, kind as "statute" | "case" | "any");
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
      } else if (job.target_table === "case_chunks") {
        if (CASE_FETCH_BLOCKED) {
          result = await processCaseJob(supabase, job, workerId);
        } else {
          // Future: real case fetcher goes here
          result = {
            source_id: job.source_id,
            target_table: "case_chunks",
            status: "failed",
            chunks: 0,
            error: "case fetcher not implemented",
          };
        }
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
