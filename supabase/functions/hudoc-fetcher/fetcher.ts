// hudoc-fetcher/fetcher.ts
// -----------------------------------------------------------------------------
// HTTP layer for ECtHR HUDOC. The public UI is a JS SPA — under the hood
// it calls a Solr-backed query endpoint and a separate DOCX→HTML conversion
// endpoint. Both are stable but only loosely documented.
//
//   1. GET /app/query/results
//      Query DSL is custom (NOT standard Lucene): fields use `=` not `:`,
//      AND/OR/NOT must be UPPERCASE, and EVERY query must be scoped by
//      `contentsitename=ECHR` and exclude press-release / old-commission
//      doctypes — otherwise it 404s. The shape of a working query is:
//        contentsitename=ECHR
//          AND (NOT (doctype=PR OR doctype=HFCOMOLD OR doctype=HECOMOLD))
//          AND ((documentcollectionid2="GRANDCHAMBER"
//                OR documentcollectionid2="CHAMBER"))
//          AND (((appno="23380/09")))
//      → returns a list of rows including the canonical `itemid`
//        (always of the form `001-NNNNNN`).
//
//   2. GET /app/conversion/docx/html/body?library=ECHR&id=001-NNNNNN
//      → returns the judgment body as HTML (the DOCX-to-HTML conversion
//        the SPA renders). Note: the older `/docx2html/html/body` path
//        is dead — use `/docx/html/body`.
//
// This module owns the (1)+(2) chain. The worker in index.ts orchestrates
// retries and rate limiting (HUDOC 429s aggressively above ~1 RPS).
// -----------------------------------------------------------------------------

const HUDOC_SEARCH_URL = "https://hudoc.echr.coe.int/app/query/results";
const HUDOC_DOC_BASE = "https://hudoc.echr.coe.int/app/conversion/docx/html/body";
const USER_AGENT =
  "AdvocatBot/1.0 (+https://advocat.ee; corpus-ingest; contact: aiplacest@gmail.com)";
const DEFAULT_TIMEOUT_MS = 30_000;

export interface HudocSearchHit {
  itemid: string;           // e.g. "001-157670"
  appno: string;            // e.g. "23380/09"
  docname: string;          // e.g. "CASE OF BOUYID v. BELGIUM"
  /** ISO judgment date. Populated from either `kpdate` (current HUDOC
   *  field name) or `judgement_date` (legacy) — see normaliseHit. */
  judgement_date: string | null;
  importance: number | null;
  /** "GRANDCHAMBER" / "CHAMBER" / "ADMISSIBILITY" / etc. */
  doctypebranch: string | null;
  /** Two-letter language code from HUDOC, when present. */
  languageisocode: string | null;
  /** Country / respondent state. */
  respondent: string | null;
}

export interface HudocFetchResult {
  itemid: string;
  html: string;
  sourceUrl: string;
}

export class HudocFetchError extends Error {
  readonly status: number;
  readonly hint: string;
  constructor(message: string, opts: { status: number; hint?: string }) {
    super(message);
    this.name = "HudocFetchError";
    this.status = opts.status;
    this.hint = opts.hint ?? "";
  }
}

/**
 * Search HUDOC for cases by application number. Returns the top hit (or
 * null if no match). For cases with multiple judgments (admissibility +
 * merits + just satisfaction) the caller can pick by date — for Phase 1
 * we take the canonical English merits judgment (highest importance,
 * GRANDCHAMBER preferred over CHAMBER, English over translations).
 *
 * The query DSL here is HUDOC-specific, NOT Lucene:
 *   - fields use `=` (not `:`) and string values are double-quoted
 *   - AND/OR/NOT must be UPPERCASE
 *   - every query must be scoped by `contentsitename=ECHR` and exclude
 *     press releases / old-commission doctypes, otherwise the endpoint
 *     returns a 404 HTML page instead of JSON
 */
export async function searchByAppno(
  appno: string,
  opts: { timeoutMs?: number; signal?: AbortSignal } = {},
): Promise<HudocSearchHit | null> {
  const query =
    `contentsitename=ECHR` +
    ` AND (NOT (doctype=PR OR doctype=HFCOMOLD OR doctype=HECOMOLD))` +
    ` AND ((documentcollectionid2="GRANDCHAMBER" OR documentcollectionid2="CHAMBER"))` +
    ` AND (((appno="${appno}")))`;
  const params = new URLSearchParams({
    query,
    select:
      "itemid,docname,appno,importance,kpdate,doctypebranch,respondent,languageisocode,documentcollectionid2",
    sort: "kpdate Descending",
    start: "0",
    length: "30",
  });
  const url = `${HUDOC_SEARCH_URL}?${params.toString()}`;
  const ctrl = abortController(opts);

  try {
    const resp = await fetch(url, {
      headers: {
        "User-Agent": USER_AGENT,
        "Accept": "application/json, text/json",
      },
      signal: ctrl.signal,
    });
    if (!resp.ok) {
      throw new HudocFetchError(`HUDOC search ${resp.status} for appno ${appno}`, {
        status: resp.status,
      });
    }
    // HUDOC may serve 200 with an HTML error page if the query DSL is
    // malformed — parse defensively.
    const ctype = resp.headers.get("content-type") ?? "";
    const text = await resp.text();
    let json: unknown;
    try {
      json = JSON.parse(text);
    } catch {
      throw new HudocFetchError(
        `HUDOC search non-JSON response (content-type=${ctype})`,
        { status: resp.status, hint: text.slice(0, 200) },
      );
    }
    // Result shape: { results: [{ columns: { itemid, ... } }] }
    // Some endpoint versions return: { resultlist: [...] }
    // We normalise both.
    const rawList = (json as { results?: unknown[]; resultlist?: unknown[] }).results
      ?? (json as { resultlist?: unknown[] }).resultlist
      ?? [];
    if (!Array.isArray(rawList) || rawList.length === 0) return null;

    const allHits: HudocSearchHit[] = rawList
      .map((r: unknown) => normaliseHit(r))
      .filter((h): h is HudocSearchHit => h !== null);
    if (allHits.length === 0) return null;

    // Filter: English canonical only. Translation rows have either a
    // non-ENG languageisocode or a docname suffix like
    // "- [Albanian Translation] ..."; both are noise for our corpus.
    const isCanonicalEng = (h: HudocSearchHit) =>
      h.languageisocode === "ENG" && !/\[[A-Za-z ]+ Translation\]/i.test(h.docname);

    let candidates = allHits.filter(isCanonicalEng);
    if (candidates.length === 0) {
      // Fall back to all ENG, then all hits — better to ingest a summary
      // than to fail outright.
      candidates = allHits.filter((h) => h.languageisocode === "ENG");
      if (candidates.length === 0) candidates = allHits;
    }

    // Sort: importance ascending (1 = key case), then GC over Chamber,
    // then newest first. Within ENG canonical hits this reliably yields
    // the merits judgment.
    candidates.sort((a, b) => {
      const impA = a.importance ?? 99;
      const impB = b.importance ?? 99;
      if (impA !== impB) return impA - impB;
      const gcA = /GRANDCHAMBER/i.test(a.doctypebranch ?? "") ? 0 : 1;
      const gcB = /GRANDCHAMBER/i.test(b.doctypebranch ?? "") ? 0 : 1;
      if (gcA !== gcB) return gcA - gcB;
      return (b.judgement_date ?? "").localeCompare(a.judgement_date ?? "");
    });
    return candidates[0];
  } finally {
    ctrl.clear();
  }
}

/**
 * Fetch the full judgment body HTML for a given itemid. The HUDOC HTML
 * endpoint serves the rendered DOCX-to-HTML conversion — the same content
 * a browser would see at the public URL but without the SPA shell.
 */
export async function fetchHudocDoc(
  itemid: string,
  opts: { timeoutMs?: number; signal?: AbortSignal } = {},
): Promise<HudocFetchResult> {
  if (!/^001-\d{4,7}$/.test(itemid)) {
    throw new HudocFetchError(`Invalid HUDOC itemid format: ${itemid}`, {
      status: 0,
    });
  }
  const url = `${HUDOC_DOC_BASE}?library=ECHR&id=${itemid}`;
  const ctrl = abortController(opts);
  try {
    const resp = await fetch(url, {
      headers: {
        "User-Agent": USER_AGENT,
        "Accept": "text/html",
      },
      signal: ctrl.signal,
    });
    if (!resp.ok) {
      throw new HudocFetchError(`HUDOC doc ${resp.status} for ${itemid}`, {
        status: resp.status,
      });
    }
    const html = await resp.text();
    if (html.length < 2_000) {
      throw new HudocFetchError(`HUDOC doc body too short (${html.length} bytes)`, {
        status: 204,
        hint: html.slice(0, 200),
      });
    }
    return {
      itemid,
      html,
      // The user-facing URL for citation purposes (clickable in app).
      sourceUrl: `https://hudoc.echr.coe.int/eng?i=${itemid}`,
    };
  } finally {
    ctrl.clear();
  }
}

// =============================================================================
// Helpers
// =============================================================================

function abortController(
  opts: { timeoutMs?: number; signal?: AbortSignal },
): { signal: AbortSignal; clear: () => void } {
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort("timeout"), opts.timeoutMs ?? DEFAULT_TIMEOUT_MS);
  if (opts.signal) {
    if (opts.signal.aborted) ctrl.abort();
    else opts.signal.addEventListener("abort", () => ctrl.abort(), { once: true });
  }
  return { signal: ctrl.signal, clear: () => clearTimeout(timer) };
}

/** Normalise a HUDOC search row into our typed shape.
 *
 *  HUDOC returns rows in two slightly different shapes depending on the
 *  endpoint version:
 *    { columns: { itemid, docname, ... } }   (newer)
 *    { itemid, docname, ... }                 (older — `select` flat)
 *  We support both. */
export function normaliseHit(raw: unknown): HudocSearchHit | null {
  if (!raw || typeof raw !== "object") return null;
  // deno-lint-ignore no-explicit-any
  const r = raw as any;
  const c = r.columns ?? r;
  const itemid: unknown = c.itemid;
  if (typeof itemid !== "string" || !itemid) return null;
  // HUDOC's current Solr index uses `kpdate` (ISO datetime); older docs
  // and our seed/test fixtures use the legacy `judgement_date`. Accept both.
  const rawDate = c.kpdate ?? c.judgement_date ?? null;
  return {
    itemid,
    appno: String(c.appno ?? "").trim(),
    docname: String(c.docname ?? "").trim(),
    judgement_date: rawDate ? String(rawDate) : null,
    importance: typeof c.importance === "number"
      ? c.importance
      : (c.importance ? Number(c.importance) : null),
    doctypebranch: c.doctypebranch ? String(c.doctypebranch) : null,
    languageisocode: c.languageisocode ? String(c.languageisocode) : null,
    respondent: c.respondent ? String(c.respondent) : null,
  };
}
