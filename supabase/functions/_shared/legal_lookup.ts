// legal_lookup.ts — Phase 2 strategic upgrade #2: tool-augmented mid-reasoning.
// -----------------------------------------------------------------------------
// Backs the `legal_lookup` Claude tool. The executor calls this BEFORE
// asserting any statute paragraph content, so the model quotes the actual
// current text from our corpus instead of hallucinating from memory.
//
// Eval Phase 1 caught HOL §114 (Suomen hallintolaki): the model invented a
// "30 day window" when reality is "5 years" (KHO-only). Live lookup of the
// actual paragraph text prevents this whole class of failure.
//
// Architecture:
//   v1 (this file) — pgvector RAG against `law_chunks` (aka legal_rag_corpus).
//                    Top-5 cosine matches, threshold ≥0.75, 4KB total cap.
//   v2 (TODO stubs) — live API fallback when corpus is stale (>60 days):
//                       FI → Finlex Open Data API
//                       EE → Riigi Teataja JSON API
//                       EU → EUR-Lex SPARQL endpoint
//                     See `stubLiveFallback` below. v1 always returns null.
//
// Pure-ish: takes injected dependencies (embed fn, RPC client) for testability.
// Only top-level side-effect is an optional env read (LEGAL_LOOKUP_LIVE_API_ENABLED).
// -----------------------------------------------------------------------------

// ── Constants ────────────────────────────────────────────────────────────────

/** Top-K corpus chunks returned by a single lookup. Tighter than RAG's
 *  default 8 to keep the tool_result payload under 4KB. */
export const LEGAL_LOOKUP_MATCH_COUNT = 5;

/** Cosine-similarity floor. RAG default is 0.60; we want precision over
 *  recall here since the model latches onto whatever we hand back. */
export const LEGAL_LOOKUP_SIMILARITY_THRESHOLD = 0.75;

/** Days after corpus_refreshed_at before flagging stale. Tighter than
 *  citation_grounder's 90-day threshold — this drives a live-API fallback,
 *  not a post-hoc warning. */
export const LEGAL_LOOKUP_STALE_THRESHOLD_DAYS = 60;

/** JSON-serialised response cap. ≈1000 tokens — leaves headroom in the
 *  executor system-prompt budget. */
export const LEGAL_LOOKUP_MAX_RESPONSE_BYTES = 4096;

/** Per-chunk snippet cap. 5 × 700 ≈ 3.5KB before metadata. */
export const LEGAL_LOOKUP_SNIPPET_MAX_CHARS = 700;

/** Accepted jurisdictions. Matches law_chunks.jurisdiction CHECK. */
export const LEGAL_LOOKUP_JURISDICTIONS = ["fi", "ee", "eu", "de", "ru"] as const;
export type LegalLookupJurisdiction = typeof LEGAL_LOOKUP_JURISDICTIONS[number];

const JURISDICTION_TO_RPC: Record<LegalLookupJurisdiction, string> = {
  fi: "FI", ee: "EE", eu: "EU", de: "DE", ru: "RU",
};

/** Native language hint for the law_search RPC. The RPC's `lang like 'eu_%'`
 *  branch widens scope to EU directives regardless. */
const JURISDICTION_TO_LANG: Record<LegalLookupJurisdiction, string> = {
  fi: "fi", ee: "et", eu: "en", de: "en", ru: "ru",
};

// ── Public types ────────────────────────────────────────────────────────────

/** One returned chunk in the tool response. */
export interface LegalLookupChunk {
  /** Human-readable reference, e.g. "HOL §114", "TLS §88". */
  statute: string;
  /** Lowercase act slug. */
  act_slug: string;
  /** Paragraph identifier (verbatim). */
  paragraph: string;
  /** Verbatim body, truncated at LEGAL_LOOKUP_SNIPPET_MAX_CHARS. */
  text: string;
  /** Cosine similarity in [0, 1]. */
  similarity: number;
  /** Days since corpus_refreshed_at. Null = unknown (treated stale). */
  freshness_days: number | null;
  source_url: string | null;
}

export interface LegalLookupResult {
  chunks: LegalLookupChunk[];
  /** Present iff any chunk is older than the stale threshold. */
  stale_warning?: string;
  /** "corpus" in v1. v2 may return finlex/riigi_teataja/eur_lex. */
  source: "corpus" | "finlex" | "riigi_teataja" | "eur_lex" | "stub";
  embed_tokens: number;
}

// ── Dependency injection seam ───────────────────────────────────────────────

/** Mirrors law-search/embed.ts contract — returns null on failure. */
export type EmbedQueryFn = (
  query: string,
) => Promise<{ embedding: number[]; tokens: number } | null>;

export type LawSearchRpcFn = (params: {
  query_embedding: number[];
  query_lang: string;
  query_jurisdiction: string;
  match_count: number;
  similarity_threshold: number;
}) => Promise<LawSearchRpcRow[] | null>;

export interface LawSearchRpcRow {
  id: string;
  act_slug: string;
  act_name?: string | null;
  paragraph: string;
  title?: string | null;
  body: string;
  source_url?: string | null;
  jurisdiction?: string | null;
  similarity: number;
  /** Optional — current production RPC does NOT surface this. */
  corpus_refreshed_at?: string | null;
}

/** Batched freshness lookup. Used when the RPC row lacks corpus_refreshed_at. */
export type FetchFreshnessFn = (
  chunkIds: string[],
) => Promise<Map<string, string | null>>;

export interface LegalLookupOptions {
  similarityThreshold?: number;
  matchCount?: number;
  staleThresholdDays?: number;
  /** Exact statute hint, e.g. "HOL §114". Prepended to the embedding query
   *  as a high-signal anchor. */
  specificStatute?: string | null;
  /** Try live API on stale results. Defaults to env LEGAL_LOOKUP_LIVE_API_ENABLED. */
  liveApiEnabled?: boolean;
  now?: () => Date;
}

/** Thrown on misuse (unknown jurisdiction). Network / RPC failures degrade
 *  gracefully to `{ chunks: [], source: 'stub' }` and never throw. */
export class LegalLookupConfigError extends Error {
  constructor(msg: string) {
    super(msg);
    this.name = "LegalLookupConfigError";
  }
}

// ── Public entry point ──────────────────────────────────────────────────────

/**
 * Look up current statute text. Executor calls this BEFORE asserting any
 * paragraph content.
 *
 * Pipeline: validate → embed → RPC → freshness join → stale check (+ live
 * fallback if enabled) → snippet truncate → 4KB cap.
 *
 * Graceful degradation:
 *   - Empty query → { chunks: [], source: 'stub' }
 *   - Embed / RPC failure → { chunks: [], source: 'stub' }
 *   - Unknown jurisdiction → throws LegalLookupConfigError
 */
export async function legalLookup(
  query: string,
  jurisdiction: string,
  deps: {
    embed: EmbedQueryFn;
    lawSearch: LawSearchRpcFn;
    fetchFreshness?: FetchFreshnessFn;
    liveFallback?: LiveFallbackFn;
  },
  options: LegalLookupOptions = {},
): Promise<LegalLookupResult> {
  const trimmed = (query ?? "").trim();
  if (!trimmed) {
    return { chunks: [], source: "stub", embed_tokens: 0 };
  }

  const jur = jurisdiction.toLowerCase() as LegalLookupJurisdiction;
  if (!LEGAL_LOOKUP_JURISDICTIONS.includes(jur)) {
    throw new LegalLookupConfigError(
      `Unsupported jurisdiction '${jurisdiction}' (expected one of ${
        LEGAL_LOOKUP_JURISDICTIONS.join(", ")
      })`,
    );
  }

  const matchCount = options.matchCount ?? LEGAL_LOOKUP_MATCH_COUNT;
  const threshold = options.similarityThreshold ??
    LEGAL_LOOKUP_SIMILARITY_THRESHOLD;
  const staleDays = options.staleThresholdDays ??
    LEGAL_LOOKUP_STALE_THRESHOLD_DAYS;
  const now = options.now ?? (() => new Date());

  // When the caller knows the exact statute id, prepend it — embeddings
  // pick up "HOL §114" as a strong anchor even though the corpus stores
  // just "§114" without the act prefix.
  const embedInput = options.specificStatute
    ? `${options.specificStatute} ${trimmed}`
    : trimmed;

  // ── Embed ────────────────────────────────────────────────────────────────
  let embedResult: Awaited<ReturnType<EmbedQueryFn>>;
  try {
    embedResult = await deps.embed(embedInput);
  } catch (err) {
    console.warn(`legalLookup: embed threw ${String(err)}`);
    return { chunks: [], source: "stub", embed_tokens: 0 };
  }
  if (!embedResult) {
    return { chunks: [], source: "stub", embed_tokens: 0 };
  }

  // ── RPC ──────────────────────────────────────────────────────────────────
  let rows: LawSearchRpcRow[] | null;
  try {
    rows = await deps.lawSearch({
      query_embedding: embedResult.embedding,
      query_lang: JURISDICTION_TO_LANG[jur],
      query_jurisdiction: JURISDICTION_TO_RPC[jur],
      match_count: matchCount,
      similarity_threshold: threshold,
    });
  } catch (err) {
    console.warn(`legalLookup: RPC threw ${String(err)}`);
    return { chunks: [], source: "stub", embed_tokens: embedResult.tokens };
  }
  if (!rows || rows.length === 0) {
    return { chunks: [], source: "stub", embed_tokens: embedResult.tokens };
  }

  // ── Freshness join ───────────────────────────────────────────────────────
  // Prefer RPC's own corpus_refreshed_at when present; fall back to a
  // batched id lookup. Missing timestamp → freshness_days=null (treated stale).
  const freshness = new Map<string, string | null>();
  const needsFreshness: string[] = [];
  for (const r of rows) {
    if (typeof r.corpus_refreshed_at === "string") {
      freshness.set(r.id, r.corpus_refreshed_at);
    } else {
      needsFreshness.push(r.id);
    }
  }
  if (needsFreshness.length > 0 && deps.fetchFreshness) {
    try {
      const extra = await deps.fetchFreshness(needsFreshness);
      for (const [k, v] of extra) freshness.set(k, v);
    } catch (err) {
      console.warn(`legalLookup: freshness lookup threw ${String(err)}`);
    }
  }

  // ── Build chunks ─────────────────────────────────────────────────────────
  const nowMs = now().getTime();
  const builtChunks: LegalLookupChunk[] = rows.map((r) => ({
    statute: formatStatute(r.act_slug, r.paragraph),
    act_slug: r.act_slug.toLowerCase(),
    paragraph: r.paragraph,
    text: truncateSnippet(r.body),
    similarity: typeof r.similarity === "number" ? r.similarity : 0,
    freshness_days: computeFreshnessDays(freshness.get(r.id) ?? null, nowMs),
    source_url: r.source_url ?? null,
  }));

  // ── Stale detection + optional live fallback ─────────────────────────────
  const anyStale = builtChunks.some((c) =>
    c.freshness_days === null || c.freshness_days > staleDays
  );

  const liveEnabled = options.liveApiEnabled ?? resolveLiveApiEnabled();
  if (anyStale && liveEnabled && deps.liveFallback) {
    try {
      const live = await deps.liveFallback({
        query: trimmed,
        jurisdiction: jur,
        specificStatute: options.specificStatute ?? null,
      });
      if (live && live.chunks.length > 0) {
        return capResponse({
          chunks: live.chunks,
          source: live.source,
          embed_tokens: embedResult.tokens,
        });
      }
    } catch (err) {
      console.warn(`legalLookup: live fallback threw ${String(err)}`);
      // fall through to corpus result with stale_warning
    }
  }

  const result: LegalLookupResult = {
    chunks: builtChunks,
    source: "corpus",
    embed_tokens: embedResult.tokens,
  };
  if (anyStale) {
    result.stale_warning = buildStaleWarning(builtChunks, staleDays);
  }

  return capResponse(result);
}

// ── Live API fallback (v2 stub) ─────────────────────────────────────────────

export type LiveFallbackFn = (req: {
  query: string;
  jurisdiction: LegalLookupJurisdiction;
  specificStatute: string | null;
}) => Promise<
  { chunks: LegalLookupChunk[]; source: LegalLookupResult["source"] } | null
>;

/** Stub dispatcher. v1 always returns null — corpus is the only path.
 *  v2 implementations fill the TODOs without rewriting call sites. */
export const stubLiveFallback: LiveFallbackFn = async (req) => {
  switch (req.jurisdiction) {
    case "fi":
      // TODO: implement live Finlex API
      //   GET https://opendata.finlex.fi/finlex/avoindata/v1/...
      //   parse JSON → LegalLookupChunk[]; return { chunks, source: 'finlex' }
      return null;
    case "ee":
      // TODO: implement live Riigi Teataja JSON API
      //   GET https://www.riigiteataja.ee/api/...
      //   return { chunks, source: 'riigi_teataja' }
      return null;
    case "eu":
      // TODO: implement live EUR-Lex SPARQL endpoint
      //   POST https://publications.europa.eu/webapi/rdf/sparql
      //   return { chunks, source: 'eur_lex' }
      return null;
    case "de":
    case "ru":
      // No live API in scope. Stay on corpus.
      return null;
    default:
      return null;
  }
};

// ── Helpers ─────────────────────────────────────────────────────────────────

/** Render "act_slug:paragraph" as a human-readable statute reference.
 *  EE/FI acts → "TLS §88", "HOL §114". EU directives → "Directive 32019L1152 art-5". */
export function formatStatute(actSlug: string, paragraph: string): string {
  const slug = actSlug.trim();
  if (!slug) return `§${paragraph}`;
  const isCelex = /^\d{4,5}[A-Z]\d{4}$/i.test(slug);
  if (isCelex) return `Directive ${slug.toUpperCase()} ${paragraph}`;
  return `${slug.toUpperCase()} §${paragraph}`;
}

/** Days since corpus_refreshed_at. Null when missing/unparseable (treated
 *  stale by callers — mirrors citation_grounder.isStale conservatism). */
export function computeFreshnessDays(
  refreshedAtIso: string | null | undefined,
  nowMs: number,
): number | null {
  if (!refreshedAtIso) return null;
  const parsed = new Date(refreshedAtIso);
  if (isNaN(parsed.getTime())) return null;
  const days = (nowMs - parsed.getTime()) / (1000 * 60 * 60 * 24);
  return Math.max(0, Math.floor(days));
}

function truncateSnippet(body: string | null | undefined): string {
  if (!body) return "";
  return body.length <= LEGAL_LOOKUP_SNIPPET_MAX_CHARS
    ? body
    : body.slice(0, LEGAL_LOOKUP_SNIPPET_MAX_CHARS);
}

function buildStaleWarning(
  chunks: ReadonlyArray<LegalLookupChunk>,
  thresholdDays: number,
): string {
  const oldest = chunks.reduce<number | null>((acc, c) => {
    if (c.freshness_days === null) return acc;
    if (acc === null) return c.freshness_days;
    return Math.max(acc, c.freshness_days);
  }, null);
  const desc = oldest === null
    ? "unknown refresh date"
    : `${oldest} days since last refresh`;
  return `Corpus may be stale (${desc}, threshold ${thresholdDays} days). ` +
    `Cross-check with primary source URL before quoting verbatim.`;
}

/** Drop lowest-similarity chunks one-by-one until the JSON-serialised
 *  payload fits LEGAL_LOOKUP_MAX_RESPONSE_BYTES. Last resort: empty chunks. */
function capResponse(result: LegalLookupResult): LegalLookupResult {
  let serialised = JSON.stringify(result);
  if (serialised.length <= LEGAL_LOOKUP_MAX_RESPONSE_BYTES) return result;

  const sortedAsc = [...result.chunks].sort(
    (a, b) => a.similarity - b.similarity,
  );
  while (
    sortedAsc.length > 0 &&
    serialised.length > LEGAL_LOOKUP_MAX_RESPONSE_BYTES
  ) {
    sortedAsc.shift();
    const next: LegalLookupResult = { ...result, chunks: [...sortedAsc] };
    serialised = JSON.stringify(next);
    if (serialised.length <= LEGAL_LOOKUP_MAX_RESPONSE_BYTES) return next;
  }
  return { ...result, chunks: [] };
}

function resolveLiveApiEnabled(): boolean {
  try {
    // deno-lint-ignore no-explicit-any
    const d = (globalThis as any).Deno;
    const flag = d?.env?.get?.("LEGAL_LOOKUP_LIVE_API_ENABLED");
    if (typeof flag !== "string") return false;
    const lower = flag.toLowerCase().trim();
    return lower === "true" || lower === "1" || lower === "on";
  } catch {
    return false;
  }
}

/** Pretty-print a result as the tool_result content payload. The model
 *  reads this as the tool's "return value". */
export function formatLookupResultForModel(result: LegalLookupResult): string {
  if (result.chunks.length === 0) {
    return (
      "No matching statute paragraphs found in the corpus above the " +
      "similarity threshold. Either the statute is not in our bundled " +
      "corpus or the query needs rephrasing. Do NOT fabricate paragraph " +
      "text — say you don't have current text and recommend a primary " +
      "source check."
    );
  }
  const parts: string[] = [
    `Found ${result.chunks.length} chunk(s) from ${result.source}:`,
  ];
  for (const c of result.chunks) {
    const sim = c.similarity.toFixed(2);
    const age = c.freshness_days === null
      ? "unknown age"
      : `${c.freshness_days}d old`;
    parts.push(
      `\n[${c.statute}] (sim ${sim}, ${age})\n${c.text}` +
        (c.source_url ? `\nSource: ${c.source_url}` : ""),
    );
  }
  if (result.stale_warning) parts.push(`\n⚠ ${result.stale_warning}`);
  return parts.join("\n");
}
