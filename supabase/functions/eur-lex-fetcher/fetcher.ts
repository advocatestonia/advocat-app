// eur-lex-fetcher/fetcher.ts
// -----------------------------------------------------------------------------
// HTTP layer for EUR-Lex: fetch a CELEX document as HTML in a target
// language and return the body + source URL.
//
// EUR-Lex public REST surface:
//   https://eur-lex.europa.eu/legal-content/<LANG>/TXT/HTML/?uri=CELEX:<CELEX>
//
// Languages we use: EN, FI, ET (Estonia + Finland + English for citation
// reference). The URL pattern is identical across languages — only the
// `<LANG>` path segment changes. CELEX IDs are stable identifiers (the
// "32004L0038" form for directives, "32016R0679" for regulations).
//
// Rate-limit posture: EUR-Lex is a courtesy service; we keep it at 1 RPS
// with a small jitter. The worker loop in index.ts enforces inter-job
// pacing; this module just does the single fetch with timeout + retry.
// -----------------------------------------------------------------------------

// As of 2026-05, eur-lex.europa.eu serves all /legal-content/* HTML behind an
// AWS WAF JavaScript challenge (HTTP 202 + AwsWafIntegration body). Server-side
// fetches can't solve the JS puzzle. We route through publications.europa.eu
// (CELLAR backend) which serves the same canonical XHTML directly:
//   https://publications.europa.eu/resource/celex/<CELEX>
//   Accept: application/xhtml+xml
//   Accept-Language: eng | fin | est  (3-letter ISO 639-2)
// The XHTML uses the same `<p class="oj-ti-art">Article N</p>` markers, so the
// chunker works unchanged.
const PUBLICATIONS_BASE = "https://publications.europa.eu/resource/celex";
const DEFAULT_TIMEOUT_MS = 30_000;
const USER_AGENT =
  "AdvocatBot/1.0 (+https://advocat.ee; corpus-ingest; contact: aiplacest@gmail.com)";

export type EurLexLang = "EN" | "FI" | "ET";

// 2-letter UI lang → 3-letter ISO 639-2 lang code expected by publications.europa.eu
const LANG_TO_ISO3: Record<EurLexLang, string> = {
  EN: "eng",
  FI: "fin",
  ET: "est",
};

export interface EurLexFetchResult {
  /** Raw HTML body of the document. */
  html: string;
  /** The exact source URL we fetched — stored on each chunk for citation. */
  sourceUrl: string;
  /** HTTP status returned (always 200 if the call resolves; non-200 throws). */
  status: number;
}

export class EurLexFetchError extends Error {
  readonly status: number;
  readonly celex: string;
  readonly lang: EurLexLang;
  constructor(message: string, opts: { status: number; celex: string; lang: EurLexLang }) {
    super(message);
    this.name = "EurLexFetchError";
    this.status = opts.status;
    this.celex = opts.celex;
    this.lang = opts.lang;
  }
}

/**
 * Build the consolidated-HTML URL for a CELEX in the requested language.
 *
 * For consolidated acts (e.g. Directive 2004/38/EC after 2011 amendments),
 * EUR-Lex returns the consolidated text via the same URL — the consolidation
 * date is encoded in CELEX when you want a specific version. For Phase 1
 * we use the base CELEX which EUR-Lex resolves to the current consolidated
 * text. A future ingest can pass dated CELEX ("02004L0038-20210801") to
 * pin a specific redaktsioon for `redaktsioon_valid_from/to`.
 */
export function buildEurLexUrl(celex: string, _lang: EurLexLang): string {
  // Language is selected via Accept-Language header (see fetchEurLex), not the URL.
  return `${PUBLICATIONS_BASE}/${celex}`;
}

/**
 * Fetch a CELEX as HTML. Throws EurLexFetchError on non-2xx so the worker
 * can record `last_error` and decide between retry vs. mark-failed.
 *
 * Retry policy: we do NOT retry inside this function. The worker loop in
 * index.ts owns retry semantics — it sees the failure, increments the
 * `attempts` column, and re-queues if attempts < 3. This keeps fetcher.ts
 * pure-ish and testable.
 */
export async function fetchEurLex(
  celex: string,
  lang: EurLexLang,
  opts: { timeoutMs?: number; signal?: AbortSignal } = {},
): Promise<EurLexFetchResult> {
  if (!/^[0-9]{5}[A-Z][0-9]{4}(?:-[0-9]{8})?$/.test(celex)) {
    throw new EurLexFetchError(`Invalid CELEX format: ${celex}`, {
      status: 0,
      celex,
      lang,
    });
  }
  const url = buildEurLexUrl(celex, lang);
  const timeoutMs = opts.timeoutMs ?? DEFAULT_TIMEOUT_MS;
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort("timeout"), timeoutMs);
  if (opts.signal) {
    if (opts.signal.aborted) ctrl.abort();
    else opts.signal.addEventListener("abort", () => ctrl.abort(), { once: true });
  }

  try {
    const iso3 = LANG_TO_ISO3[lang];
    const resp = await fetch(url, {
      method: "GET",
      headers: {
        "User-Agent": USER_AGENT,
        // publications.europa.eu requires xhtml in Accept to return the
        // CONVEX-rendered document (not RDF metadata).
        "Accept": "application/xhtml+xml",
        // Language negotiation happens here, NOT in the URL.
        "Accept-Language": iso3,
      },
      signal: ctrl.signal,
      redirect: "follow",
    });

    if (!resp.ok) {
      // 404 means the CELEX has no version in this language — common for
      // older directives that pre-date Estonian/Finnish translations. The
      // worker treats this as a soft-skip (mark this language done, move on).
      throw new EurLexFetchError(
        `EUR-Lex ${resp.status} for CELEX ${celex} lang ${lang}`,
        { status: resp.status, celex, lang },
      );
    }

    const html = await resp.text();
    // EUR-Lex returns a "document not available in this language" stub
    // with HTTP 200 in some cases. We detect the stub by length + a
    // sentinel phrase that appears across all 24 languages.
    if (html.length < 4_000 || /not available in (the requested|this) language/i.test(html)) {
      throw new EurLexFetchError(
        `EUR-Lex returned stub (no ${lang} translation) for ${celex}`,
        { status: 204, celex, lang },
      );
    }

    return { html, sourceUrl: url, status: resp.status };
  } finally {
    clearTimeout(timer);
  }
}
