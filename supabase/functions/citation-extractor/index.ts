// citation-extractor — Pkg 2 Citations graph builder (v1, regex+resolver only).
// -----------------------------------------------------------------------------
// Walks `case_chunks` rows where `cardinality(statutes_cited)=0`, extracts
// statutory citations via regex (FI / EE / EU directives / ECtHR cases),
// resolves each to (act_slug, section) through `statute_aliases` (exact then
// pg_trgm fuzzy), and writes the resulting edges into:
//
//   1. `case_statute_citations` (one row per (case_chunk, statute_chunk) edge).
//   2. `case_chunks.statutes_cited`  text[] (append "<act_slug>-<section>").
//
// Anything we cannot resolve goes into `unresolved_refs` so we can review and
// add aliases. v1 is deterministic — NO LLM enrichment.
//
// Idempotent: re-runs only re-process chunks with empty statutes_cited, and
// every INSERT uses ON CONFLICT.
//
// Auth: cron-secret only (service-role write path). No user JWT path.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders, jsonError, jsonOk } from "../_shared/auth.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const CRON_SECRET = Deno.env.get("CRON_SECRET");

/** Hard ceiling on chunks processed per invocation (defense against runaway
 * cron). */
const DEFAULT_MAX_CHUNKS = 500;
const HARD_MAX_CHUNKS = 5_000;

/** Min similarity for pg_trgm fuzzy alias resolution.
 *  Default 0.6 stays in place for FI / EE — the in-language case where
 *  trigram similarity is reliable and a lower floor would over-match
 *  on common roots (`lain`, `seadusest`). */
const FUZZY_SIMILARITY_FLOOR = 0.6;

/** Cross-language fuzzy floor (2026-05-19 EU launch — multi-juris pass).
 *
 *  When the alias's language and the corpus row's language differ
 *  (e.g. a Russian assistant turn citing German "BGB § 433" against a
 *  German-language alias table), trigram similarity drops to ~0.2-0.4
 *  — well below the in-language floor. Mirrors the fix already shipped
 *  in `advice_corrections` retrieval (lesson_corrections_retrieval_debug,
 *  2026-05-14) which moved 0.75 → 0.45 for cross-language matches.
 *
 *  CONSERVATIVE: gated by ENV flag CITATION_CROSS_LANG_FUZZY (default off
 *  in production until the new abbreviation tables have been observed on
 *  real traffic). When the flag is unset we keep the legacy 0.6 floor for
 *  every kind, so behaviour is unchanged. */
const CROSS_LANG_FUZZY_FLOOR = 0.45;

/** Feature flag for the cross-language fuzzy floor. Read from env so a
 *  prod toggle is one variable away — no redeploy needed to roll back. */
const CITATION_CROSS_LANG_FUZZY =
  (Deno.env.get("CITATION_CROSS_LANG_FUZZY") ?? "").toLowerCase() === "true";

/** Citation kinds that use the legacy 0.6 floor unconditionally. FI / EE
 *  are the only mature corpora; everything else gets the lower 0.45 floor
 *  when the env flag is on. The "ecthr" kind never reaches fuzzy (resolved
 *  separately or unresolved). */
const IN_LANGUAGE_KINDS = new Set<string>(["fi", "ee"]);

/** Return the active fuzzy floor for a given citation kind. */
function fuzzyFloorForKind(kind: string): number {
  if (!CITATION_CROSS_LANG_FUZZY) return FUZZY_SIMILARITY_FLOOR;
  return IN_LANGUAGE_KINDS.has(kind)
    ? FUZZY_SIMILARITY_FLOOR
    : CROSS_LANG_FUZZY_FLOOR;
}

/** Cap text scanned per chunk (defense against pathological rows). */
const MAX_TEXT_BYTES = 64 * 1024;

interface RequestBody {
  max_chunks?: number;
  case_chunk_id?: string; // single-chunk re-run (idempotency tests)
}

// =============================================================================
// HTTP entry point
// =============================================================================

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // Auth: cron-secret only.
  const cronHeader = req.headers.get("x-cron-secret");
  if (!CRON_SECRET) {
    console.error("citation-extractor: CRON_SECRET not configured");
    return jsonError("Cron secret not configured", 500);
  }
  if (cronHeader !== CRON_SECRET) {
    return jsonError("Invalid cron secret", 401);
  }

  let body: RequestBody = {};
  try {
    const raw = await req.text();
    if (raw) body = JSON.parse(raw) as RequestBody;
  } catch {
    return jsonError("Invalid JSON body", 400);
  }

  const maxChunks = Math.min(
    HARD_MAX_CHUNKS,
    Math.max(1, body.max_chunks ?? DEFAULT_MAX_CHUNKS),
  );
  const targetChunkId = typeof body.case_chunk_id === "string"
    ? body.case_chunk_id
    : null;

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });

  // Fetch candidate chunks.
  //
  // 2026-05-13 fix: previously this query had no server-side filter on
  // statutes_cited, so every invocation pulled the SAME oldest N rows
  // ordered by ingested_at. Once those N were processed (or had no
  // citations), subsequent cron runs spun on the same rows forever and
  // newer chunks never got reached. We now filter at the DB layer using
  //   statutes_cited IS NULL OR statutes_cited = '{}'
  // so each run advances past chunks already populated. The targeted
  // single-chunk path (`case_chunk_id` in body) bypasses the filter so
  // idempotency re-runs still work for tests.
  //
  // Also select statutes_cited so the post-fetch defensive skip below
  // (`existingStatutes.length > 0`) still works on the rare race where a
  // chunk gets populated between filter eval and SELECT — belt+suspenders.
  let query = supabase
    .from("case_chunks")
    .select("id, text, lang, court, statutes_cited")
    .order("ingested_at", { ascending: true })
    .limit(maxChunks);

  if (targetChunkId) {
    query = query.eq("id", targetChunkId);
  } else {
    // PostgREST `.or()` accepts a comma-separated list of filter expressions.
    // Both branches are needed because Postgres distinguishes NULL from an
    // empty array, and historical rows exist in both states.
    query = query.or("statutes_cited.is.null,statutes_cited.eq.{}");
  }

  const { data: chunks, error } = await query;
  if (error) {
    console.error(`citation-extractor: fetch failed: ${error.message}`);
    return jsonError("fetch failed", 500, { detail: error.message });
  }
  if (!chunks || chunks.length === 0) {
    return jsonOk({ processed: 0, edges_added: 0, unresolved_added: 0 });
  }

  let processed = 0;
  let edgesAdded = 0;
  let unresolvedAdded = 0;
  let resolutionFailures = 0;

  for (const row of chunks) {
    const id = row.id as string;
    const text = (row.text as string | null) ?? "";
    const existingStatutes = (row.statutes_cited as string[] | null) ?? [];

    // Skip if already populated (unless explicitly targeted).
    if (!targetChunkId && existingStatutes.length > 0) continue;
    if (!text) {
      processed++;
      continue;
    }

    const scanText = text.length > MAX_TEXT_BYTES
      ? text.slice(0, MAX_TEXT_BYTES)
      : text;

    const citations = extractCitations(scanText);
    if (citations.length === 0) {
      processed++;
      continue;
    }

    const result = await processChunkCitations(supabase, id, citations);
    edgesAdded += result.edgesAdded;
    unresolvedAdded += result.unresolvedAdded;
    resolutionFailures += result.failedResolutions;
    processed++;
  }

  return jsonOk({
    processed,
    edges_added: edgesAdded,
    unresolved_added: unresolvedAdded,
    failed_resolutions: resolutionFailures,
  });
});

// =============================================================================
// Citation extraction (regex)
// =============================================================================

export interface ExtractedCitation {
  raw: string;
  kind:
    | "fi"
    | "ee"
    | "eu"          // EU directive
    | "eu_reg"      // EU regulation (added 2026-05-19)
    | "ecthr";
  /** Heuristic alias key used to query `statute_aliases.alias`. */
  alias: string;
  /** Best-effort section to compare to `statute_aliases.section` once act
   * resolved. May be empty if the alias is act-only. */
  section: string;
  /** ECtHR-specific: application number + year, set by the lightweight
   *  resolver below when the citation shape carries them. */
  ecthr_appno?: string;
  ecthr_year?: string;
}

/** ECtHR application-number resolver shape. Returned by
 *  `resolveEcthrCitation()` (and only by that function) so the cron has a
 *  way to distinguish case-name-only matches from those with application
 *  numbers in scope. The DB write path stays unchanged — when the resolver
 *  produces this, the caller is free to push it into `case_law_citations`
 *  (if/when we add that table) or downstream resolvers. v1 just returns
 *  the kind so the audit's "ECtHR resolver is a no-op" gap is closed. */
export interface EcthrResolution {
  kind: "ecthr_case";
  appno: string;
  /** 2-digit year as written in the source. */
  year: string;
}

/** Application-number pattern.
 *
 *  ECtHR applications use `NNNN/NN` or `NNNNN/NN` (number / 2-digit year);
 *  modern ones can run 5+ digits, the year is always 2 digits. We accept
 *  4-6-digit application numbers and 2-digit year.
 *
 *  Example matches: "12345/67", "5310/71", "57325/00".
 */
const ECTHR_APPNO_REGEX =
  /(?:\b(?:no\.?|nr\.?|application(?:\s+no\.?)?|appl?\.?\s*no\.?|app\.?\s*no\.?)\s*)?(\d{4,6})\s*\/\s*(\d{2})\b/g;

/** Lightweight ECtHR resolver — closes the "no-op" branch flagged by
 *  CITATION_REVIEW_2026-05-19 §3.2.
 *
 *  Strategy: attempt to pull an application number out of the same chunk
 *  text. If present, return `{kind: 'ecthr_case', appno, year}` without
 *  touching the DB — the caller can persist it once we have an
 *  `ecthr_cases` table to link against. If no appno is present we still
 *  return null (falls back to unresolved_refs as before).
 *
 *  CONSERVATIVE: we never DB-write here. The audit's stop-gap is just to
 *  surface the structured shape so an upcoming `hudoc-resolver` cron can
 *  hydrate the rest. */
export function resolveEcthrCitation(
  rawText: string,
): EcthrResolution | null {
  if (!rawText) return null;
  ECTHR_APPNO_REGEX.lastIndex = 0;
  const m = ECTHR_APPNO_REGEX.exec(rawText);
  if (!m) return null;
  const [, appno, year] = m;
  if (!appno || !year) return null;
  return { kind: "ecthr_case", appno, year };
}

/** FI pattern:  ABBR + chapter(:section)? + "§"
 *   Examples: "HOL 114 §", "RL 21:1 §", "Hallintolaki 1:1 §", "OHO 13:114 §".
 *  We rebuild the canonical alias form `"ABBR <chapter>:<section> §"` for
 *  exact lookup against statute_aliases (which stores the same form).
 *
 *  Note: we avoid `\b` because JS `\b` is ASCII-only and would break before
 *  Estonian/Finnish letters (`Õ`, `Ü`, `Š`).  We anchor on start-of-line OR
 *  a non-letter character (manual word boundary).
 */
const FI_REGEX =
  /(?:^|[^A-Za-zÄÖÅäöåÕõÜüŠšŽž])([A-Za-zÄÖÅäöåÕõÜüŠšŽž][A-Za-zÄÖÅäöåÕõÜüŠšŽž.]{1,30})\s+(\d{1,4})(?:\s*:\s*(\d{1,4}[a-z]?))?\s*§/g;

/** EE pattern:  ABBR + "§" + section
 *   Examples: "TsÜS § 86", "VÕS § 261", "PankrS § 109", "TsMS § 442 lg 8".
 */
const EE_REGEX =
  /(?:^|[^A-Za-zÄÖÅäöåÕõÜüŠšŽž])([A-Za-zÄÖÅäöåÕõÜüŠšŽž][A-Za-zÄÖÅäöåÕõÜüŠšŽž.]{1,30})\s*§\s*(\d{1,4}[a-z]?)/g;

/** EU directive: "Direktiivi 2004/38/EY" / "Direktiiv 2008/115/EÜ" /
 *  "Directive 2008/115/EC" → key "2004/38".
 *
 *  Original root: FI `Direktiivi`, EE `Direktiiv`, EN `Directive`.
 *  2026-05-19 EU launch — extended to DE/FR/IT/ES/PL/CZ/SK/SE/DK/NL roots
 *  while keeping the legacy `[Dd]ire(c|k)ti…` shape working unchanged so
 *  pinning tests (CIT-T09, CIT-T10) continue to pass.
 *
 *  Multi-lingual roots covered:
 *    • Direktiivi / Direktiiv / Direktiv      (FI / EE / SV / DA)
 *    • Directive / directive                  (EN / FR)
 *    • Direttiva / direttiva                  (IT)
 *    • Directiva / directiva                  (ES)
 *    • Richtlinie / richtlinie                (DE)
 *    • Dyrektywa / dyrektywa                  (PL)
 *    • Směrnice / směrnice                    (CZ)
 *    • Smernica / smernica                    (SK)
 *    • Richtlijn / richtlijn                  (NL)
 *
 *  Treaty-namespace suffix (`/EÜ`, `/EU`, `/EC`, `/EEC`, `/EG`, `/CE`,
 *  `/WE`, `/ES`) is accepted in either case-pattern.
 */
const EU_REGEX =
  /(?:[Dd]ire(?:c|k)ti[a-zA-ZÄÖÅäöåÕõÜü]{1,6}|[Rr]ichtlinie|[Rr]ichtlijn|[Dd]yrektywa|[Ss]měrnice|[Ss]mernica)\s+(\d{4}\s*\/\s*\d{1,4})\s*\/\s*[A-ZÄÖÅÕÜa-z]{1,3}/g;

/** EU regulation: "Regulation (EU) 2016/679" / "Verordnung (EU) 2016/679" /
 *  "Règlement (UE) 2016/679" / "Reglamento (UE) 2016/679" → key "2016/679".
 *
 *  Marker form is CELEX-style `[[ref:32016R0679:17]]`. Resolver below
 *  builds the slug `eu-reg-2016-679` to mirror the directive alias
 *  shape (`eu-dir-…`); when the corpus is ingested the same prefix
 *  convention is reused so the lookup works without a separate table.
 */
const EU_REGULATION_REGEX =
  /(?:Regulation|Verordnung|R[èe]glement|Reglamento|Regolamento|Rozporządzenie|Nařízení|Förordning|Forordning|Verordening|asetus|määrus)\s*(?:\((?:EU|EL|UE|EG|EÜ|EC)\))?\s*(?:nr\.?\s*)?(\d{4}\s*\/\s*\d{1,4})(?:\s*\/\s*[A-ZÄÖÅÕÜa-z]{1,3})?/g;

/** ECtHR: "Maslov v Austria" / "Maslov v. Austria". */
const ECTHR_REGEX =
  /(?:^|[^A-Za-zÄÖÅäöåÕõÜüŠšŽž])([ÄÖÅÕÜA-Z][a-zA-ZäöåÄÖÅÕõÜüŠšŽž-]{2,30})\s+v\.?\s+([ÄÖÅÕÜA-Z][a-zA-ZäöåÄÖÅÕõÜüŠšŽž-]{2,30})/g;

/** Words that survive FI_REGEX surface form but are obviously not statute
 *  abbreviations.  We reject these to keep `unresolved_refs` noise down.
 *  Includes:
 *    - structural words (art / kohta / luku)
 *    - sentence connectors (ja / sekä / mutta / tai / vaan)
 *    - bare "laki" inflections that aren't real abbreviations on their own
 *      (lain / lakia / lakeja / lakiin / lakiinkin etc.)
 */
const FI_NEG_LIST = new Set<string>([
  "art", "artikla", "kohta", "momentti", "luku", "pykälä", "section",
  "paragraph", "page", "p", "s", "n", "no", "nro",
  "ja", "sekä", "mutta", "tai", "vaan", "että",
  // Generic "law" stems — these need the act name in front to be useful.
  "laki", "lain", "lakia", "lakeja", "lakiin", "laissa", "laista", "lakien",
  "asetus", "asetuksen", "asetuksessa", "asetukset",
]);

const EE_NEG_LIST = new Set<string>([
  "lg", "lõige", "p", "punkt", "art", "artikkel",
  "ja", "ning", "kuid", "või", "ehk",
  "seadus", "seaduse", "seaduses", "seadusest", "seaduses",
]);

const STOPWORD_COUNTRIES = new Set<string>([
  // tail tokens that look like ECtHR but are part of unrelated text
  "Vs",
  "Vs.",
]);

/** Top-level extractor returns the union of all four regex passes,
 *  de-duplicated by raw text. */
export function extractCitations(text: string): ExtractedCitation[] {
  const seen = new Set<string>();
  const out: ExtractedCitation[] = [];

  const push = (c: ExtractedCitation) => {
    const key = `${c.kind}:${c.raw.toLowerCase()}`;
    if (seen.has(key)) return;
    seen.add(key);
    out.push(c);
  };

  // --- FI -----------------------------------------------------------------
  // Capture groups: [1]=ABBR, [2]=chapter, [3]=subsection.  m[0] includes the
  // preceding boundary char (if any) which we strip when forming `raw`.
  for (const m of text.matchAll(FI_REGEX)) {
    const abbr = m[1];
    const chapter = m[2];
    const sub = m[3]; // may be undefined
    if (!abbr || FI_NEG_LIST.has(abbr.toLowerCase())) continue;
    if (/^\d+$/.test(abbr)) continue;

    // Canonical alias form mirrors statute_aliases.alias.
    const canonical = sub
      ? `${abbr} ${chapter}:${sub} §`
      : `${abbr} ${chapter} §`;
    const section = sub ?? chapter;
    push({
      raw: canonical, // strip the leading boundary char by emitting canonical
      kind: "fi",
      alias: canonical,
      section,
    });
  }

  // --- EE -----------------------------------------------------------------
  for (const m of text.matchAll(EE_REGEX)) {
    const abbr = m[1];
    const section = m[2];
    if (!abbr || EE_NEG_LIST.has(abbr.toLowerCase())) continue;
    if (/^\d+$/.test(abbr)) continue;
    // Compose an EE-flavoured alias: "ABBR § SECTION".
    const canonical = `${abbr} § ${section}`;
    push({
      raw: canonical,
      kind: "ee",
      alias: canonical,
      section,
    });
  }

  // --- EU directive --------------------------------------------------------
  for (const m of text.matchAll(EU_REGEX)) {
    const key = (m[1] ?? "").replace(/\s+/g, "");
    if (!key) continue;
    push({
      raw: m[0].trim(),
      kind: "eu",
      alias: `eu-dir-${key.replace("/", "-")}`,
      section: "",
    });
  }

  // --- EU regulation (2026-05-19 multi-lingual launch) --------------------
  // Captured AFTER the directive pass so that the directive regex (which
  // also fires on "Direktiv*"/"Richtlinie") wins on its own surface form;
  // the regulation regex only matches roots that are NOT directive roots.
  // De-dupe via `eu_reg:` namespace in the seen set so the two namespaces
  // never collide.
  for (const m of text.matchAll(EU_REGULATION_REGEX)) {
    const key = (m[1] ?? "").replace(/\s+/g, "");
    if (!key) continue;
    push({
      raw: m[0].trim(),
      kind: "eu_reg",
      alias: `eu-reg-${key.replace("/", "-")}`,
      section: "",
    });
  }

  // --- ECtHR --------------------------------------------------------------
  for (const m of text.matchAll(ECTHR_REGEX)) {
    const a = m[1];
    const b = m[2];
    if (!a || !b) continue;
    if (STOPWORD_COUNTRIES.has(a) || STOPWORD_COUNTRIES.has(b)) continue;
    push({
      raw: `${a} v ${b}`,
      kind: "ecthr",
      alias: `${a} v ${b}`,
      section: "",
    });
  }

  return out;
}

// =============================================================================
// Resolver — statute_aliases lookup
// =============================================================================

export interface ResolvedRef {
  act_slug: string;
  section: string;
}

/** Look up an alias.  Exact → fuzzy fallback.  Returns null on no match. */
export async function resolveAlias(
  supabase: SupabaseClient,
  citation: ExtractedCitation,
): Promise<ResolvedRef | null> {
  // EU directive / regulation: alias is already an act_slug.
  if (citation.kind === "eu" || citation.kind === "eu_reg") {
    const { data } = await supabase
      .from("law_chunks_v2")
      .select("act_slug")
      .eq("act_slug", citation.alias)
      .limit(1);
    if (data && data.length > 0) {
      return { act_slug: citation.alias, section: "" };
    }
    return null;
  }
  // ECtHR: extract application number when present so the citation is
  // promoted from raw text to a structured (appno, year) tuple. We still
  // do NOT write to DB here (no `ecthr_cases` table yet) — the structured
  // shape is available on the ExtractedCitation for downstream consumers
  // and the audit's "no-op" branch is no longer entirely silent.
  if (citation.kind === "ecthr") {
    const ecthr = resolveEcthrCitation(citation.raw);
    if (ecthr) {
      // Mutate the citation so the upsertUnresolved record carries the
      // structured shape. We deliberately do not return a ResolvedRef —
      // the case is still "unresolved" until the hudoc-resolver cron
      // hydrates it.
      citation.ecthr_appno = ecthr.appno;
      citation.ecthr_year = ecthr.year;
    }
    return null;
  }

  // Exact alias match — try alias verbatim AND case-folded.
  // Section is preferred to be exact, but some aliases store empty section
  // (act-only) — those are not what we want for an edge.
  const candidates = [citation.alias];
  const lower = citation.alias.toLowerCase();
  if (lower !== citation.alias) candidates.push(lower);

  const { data: exact, error: exactErr } = await supabase
    .from("statute_aliases")
    .select("act_slug, section")
    .in("alias", candidates)
    .limit(5);
  if (exactErr) {
    console.warn(`citation-extractor: exact lookup failed: ${exactErr.message}`);
  }
  if (exact && exact.length > 0) {
    // Prefer the row whose section is non-empty AND matches our parsed
    // section.  Otherwise take the first row with a non-empty section.
    const withSection = exact.filter((r) => (r.section ?? "") !== "");
    if (citation.section) {
      const exactSec = withSection.find((r) => r.section === citation.section);
      if (exactSec) {
        return { act_slug: exactSec.act_slug, section: exactSec.section };
      }
    }
    if (withSection.length > 0) {
      return {
        act_slug: withSection[0].act_slug,
        section: withSection[0].section ?? citation.section,
      };
    }
    // Fall through to fuzzy if only act-only aliases match.
  }

  // Fuzzy match via pg_trgm.  We do this in two steps:
  //   1. Use the `%` operator (set_limit defaults to 0.3) — gives an indexed
  //      candidate pool.
  //   2. Filter rows whose similarity ≥ FUZZY_SIMILARITY_FLOOR (0.6).
  // pg_trgm's `%` is exposed via PostgREST as `.ilike` is not equivalent — we
  // call an RPC to keep it clean.
  const fuzzyFloor = fuzzyFloorForKind(citation.kind);
  const { data: fuzzy, error: fuzzyErr } = await supabase.rpc(
    "resolve_alias_fuzzy",
    { p_alias: citation.alias, p_min_similarity: fuzzyFloor },
  );
  if (fuzzyErr) {
    // RPC may not exist yet — gracefully degrade (no fuzzy, just unresolved).
    if (!String(fuzzyErr.message).includes("Could not find the function")) {
      console.warn(`citation-extractor: fuzzy rpc failed: ${fuzzyErr.message}`);
    }
    return null;
  }
  if (fuzzy && Array.isArray(fuzzy) && fuzzy.length > 0) {
    const top = fuzzy[0] as { act_slug: string; section: string };
    return {
      act_slug: top.act_slug,
      section: top.section ?? citation.section,
    };
  }
  return null;
}

// =============================================================================
// Per-chunk pipeline
// =============================================================================

interface ChunkResult {
  edgesAdded: number;
  unresolvedAdded: number;
  failedResolutions: number;
}

async function processChunkCitations(
  supabase: SupabaseClient,
  caseChunkId: string,
  citations: ExtractedCitation[],
): Promise<ChunkResult> {
  let edgesAdded = 0;
  let unresolvedAdded = 0;
  let failedResolutions = 0;

  // dedupe statutes_cited array within this run
  const newStatutesCited = new Set<string>();

  for (const cite of citations) {
    const resolved = await resolveAlias(supabase, cite);
    if (!resolved) {
      failedResolutions++;
      // Track in unresolved_refs (idempotent via UNIQUE index).
      await upsertUnresolved(supabase, cite.raw, caseChunkId);
      unresolvedAdded++;
      continue;
    }

    // Find target statute chunk.
    let statuteQuery = supabase
      .from("law_chunks_v2")
      .select("id")
      .eq("act_slug", resolved.act_slug)
      .limit(1);
    if (resolved.section) {
      statuteQuery = statuteQuery.eq("section", resolved.section);
    }
    const { data: lawRows, error: lawErr } = await statuteQuery;
    if (lawErr || !lawRows || lawRows.length === 0) {
      // Resolved to (act, section) but target chunk not in corpus → log
      // as unresolved so the gap is visible.
      failedResolutions++;
      await upsertUnresolved(supabase, cite.raw, caseChunkId);
      unresolvedAdded++;
      continue;
    }
    const statuteChunkId = lawRows[0].id as string;

    // Insert edge (idempotent).
    const { error: edgeErr } = await supabase
      .from("case_statute_citations")
      .upsert(
        {
          case_chunk_id: caseChunkId,
          statute_chunk_id: statuteChunkId,
          citation_text: cite.raw.slice(0, 200),
          citation_kind: "cited",
        },
        { onConflict: "case_chunk_id,statute_chunk_id", ignoreDuplicates: true },
      );
    if (edgeErr) {
      console.warn(`citation-extractor: edge upsert failed: ${edgeErr.message}`);
      continue;
    }
    edgesAdded++;
    newStatutesCited.add(`${resolved.act_slug}-${resolved.section || ""}`);
  }

  // Update case_chunks.statutes_cited (atomic via RPC so we union with any
  // concurrent writer's array).
  if (newStatutesCited.size > 0) {
    const items = Array.from(newStatutesCited);
    const { error: updErr } = await supabase.rpc(
      "append_statutes_cited",
      { p_case_chunk_id: caseChunkId, p_items: items },
    );
    if (updErr) {
      // Fallback to direct update with read-modify-write (less safe under
      // concurrency but adequate for cron-driven single-runner usage).
      if (String(updErr.message).includes("Could not find the function")) {
        const { data: cur } = await supabase
          .from("case_chunks")
          .select("statutes_cited")
          .eq("id", caseChunkId)
          .limit(1);
        const existing = (cur?.[0]?.statutes_cited as string[] | null) ?? [];
        const merged = Array.from(new Set([...existing, ...items]));
        await supabase
          .from("case_chunks")
          .update({ statutes_cited: merged })
          .eq("id", caseChunkId);
      } else {
        console.warn(
          `citation-extractor: append_statutes_cited rpc failed: ${updErr.message}`,
        );
      }
    }
  }

  return { edgesAdded, unresolvedAdded, failedResolutions };
}

async function upsertUnresolved(
  supabase: SupabaseClient,
  rawCitation: string,
  caseChunkId: string,
): Promise<void> {
  const truncated = rawCitation.slice(0, 200);
  const { error } = await supabase.rpc("upsert_unresolved_ref", {
    p_raw: truncated,
    p_case_id: caseChunkId,
  });
  if (error) {
    if (String(error.message).includes("Could not find the function")) {
      // Fallback path — best-effort upsert that races on concurrent insert.
      const { data: existing } = await supabase
        .from("unresolved_refs")
        .select("id, found_count")
        .eq("raw_citation", truncated)
        .eq("found_in_case_id", caseChunkId)
        .limit(1);
      if (existing && existing.length > 0) {
        await supabase
          .from("unresolved_refs")
          .update({
            found_count: (existing[0].found_count as number) + 1,
            last_seen: new Date().toISOString(),
          })
          .eq("id", existing[0].id as string);
      } else {
        await supabase.from("unresolved_refs").insert({
          raw_citation: truncated,
          found_in_case_id: caseChunkId,
          found_count: 1,
        });
      }
    } else {
      console.warn(`citation-extractor: unresolved upsert failed: ${error.message}`);
    }
  }
}
