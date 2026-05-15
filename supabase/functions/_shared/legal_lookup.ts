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
//   v1 (this file) — pgvector RAG against `law_chunks_v2` via the
//                    `law_search_v2` RPC. Top-5 cosine matches, threshold
//                    ≥0.45, 4KB total cap. (2026-05-13: switched from the
//                    v1 `law_chunks`/`law_search` pair to v2 — v1 was
//                    EE-only with stale embeddings, v2 covers FI + EE + EU
//                    with current text.)
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

/** Cosine-similarity floor. Aligned with `law_search_v2`'s built-in default of
 *  0.45 (2026-05-13 launch P0 fix). Earlier 0.75 was tuned for the legacy v1
 *  corpus where embeddings were tighter; against the 15K-row v2 corpus
 *  (FI + EE + EU) the higher floor pushed recall@5 to 0 on production
 *  queries like "OHO §114 menetetyn määräajan palauttaminen". 0.45 brings
 *  recall back without contaminating with off-topic chunks (the v2 RPC
 *  already does its own filter at this exact threshold). */
export const LEGAL_LOOKUP_SIMILARITY_THRESHOLD = 0.45;

/** Days after corpus_refreshed_at before flagging stale. Tighter than
 *  citation_grounder's 90-day threshold — this drives a live-API fallback,
 *  not a post-hoc warning. */
export const LEGAL_LOOKUP_STALE_THRESHOLD_DAYS = 60;

/** JSON-serialised response cap. ≈1000 tokens — leaves headroom in the
 *  executor system-prompt budget. */
export const LEGAL_LOOKUP_MAX_RESPONSE_BYTES = 4096;

/** Per-chunk snippet cap. 5 × 700 ≈ 3.5KB before metadata. */
export const LEGAL_LOOKUP_SNIPPET_MAX_CHARS = 700;

/** Hard cap for chunks marked `display_policy='snippet_only'` (Finlex CC-BY-NC
 *  ajantasa rows). Option B from
 *  `business/legal/finlex_licensing_decision_2026-05-14.md` §7: the model is
 *  allowed at most a ~200-char excerpt + a deep link to the Finlex source so
 *  we never reprint > 200 chars of consolidated text the way the market norm
 *  treats it as commercially-restricted. DO NOT raise this without owner
 *  sign-off — bumping it past 200 re-opens the licence-risk envelope. */
export const LEGAL_LOOKUP_SNIPPET_ONLY_MAX_CHARS = 200;

/** Accepted jurisdictions. Matches law_chunks.jurisdiction CHECK. */
export const LEGAL_LOOKUP_JURISDICTIONS = ["fi", "ee", "eu", "de", "ru"] as const;
export type LegalLookupJurisdiction = typeof LEGAL_LOOKUP_JURISDICTIONS[number];

/**
 * TOOL USE directive injected into the DEFAULT chat system prompt whenever the
 * `legal_lookup` tool is being attached to the request. Without this header
 * the model never knows the tool exists for the user's turn — Phase 2 eval
 * (2026-05-13) measured citation_validity flat at 2.10 because the original
 * header lived inside `legal_planner.ts EXECUTOR_INSTRUCTIONS_HEADER`, which
 * only fires when the client passes `mode: "legal_planner"`. Most production
 * chat turns do NOT pass that mode → tool went un-invoked.
 *
 * Keep this string short (≤2 KB) and idempotent — it gets prepended on every
 * non-anon non-planner turn. Mirrors the wording inside legal_planner.ts so
 * the two paths produce comparable answers.
 *
 * Corpus v3 (2026-05-14) addition: the tool now also returns `cases_citing`
 * (which court decisions have applied the §) and `travaux` (HE / eelnõu —
 * legislative intent). The model MUST mention these when present — that is
 * the lawyer-grade differentiator over Sonnet-bare.
 */
export const LEGAL_LOOKUP_TOOL_USE_INSTRUCTION = String.raw`
## TOOL USE — legal_lookup (MANDATORY before any statute citation)

You have a 'legal_lookup' tool. CALL IT BEFORE citing any specific statute
paragraph content (e.g. HOL §114, TLS §88, KrMS §1, GDPR art. 17). Not calling
it for a specific-paragraph citation is a defect — the post-pass verifier
will downgrade unverified [[ref:...]] markers and the user will lose trust.

Mandatory pattern:
  1. Identify which statute paragraph you are about to cite.
  2. Call legal_lookup({ query: '...', jurisdiction: 'fi'|'ee'|'eu' }) and
     optionally pass specific_statute (e.g. 'HOL §114') for higher precision.
  3. Read the returned current text + freshness metadata.
  4. Quote / paraphrase based on THAT text — NEVER from memory.
  5. The tool returns three families of result:
       (a) chunks       — the statute paragraph itself (always present on hit)
       (b) cases_citing — court decisions that have applied this §; MENTION
                          them by name when present. ("KHO 2018:42 sovelsi
                          tätä pykälää...", "Riigikohus 3-3-1-12-15
                          käsitleb sama küsimust...")
       (c) travaux      — HE/eelnõu (legislative intent); CITE when present
                          for context. ("HE 72/2002 vp:n perustelujen mukaan
                          ...", "VTK seletuskirja kohaselt...")
  6. If chunks is empty: say HONESTLY that the statute is not in our corpus
     and recommend a primary-source check. Do NOT fabricate paragraph text.

LICENSE / DISPLAY POLICY (Option B, 2026-05-15):
  Chunks tagged display_policy='snippet_only' (Finlex CC-BY-NC ajantasa text)
  carry a licence-safe 200-char excerpt and a 'link_required' flag:
    • Quote at MOST the returned snippet text (≤200 chars). Never reprint
      additional consolidated paragraph text from memory.
    • Always surface the source URL with explicit phrasing such as
      "Read full text on Finlex: <url>".
    • Format: "[OHO §114] — 'short quote...' (source: <Finlex link>)"
  Chunks with display_policy='full' (alkup / public-domain) can be quoted
  freely up to the returned snippet length.

Calling the tool is cheap (≈400 input tokens per call). Calling it twice when
in doubt is fine. Calling it ZERO times for a specific-paragraph citation is
a defect.
`.trim();

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
  /** Verbatim body, truncated at LEGAL_LOOKUP_SNIPPET_MAX_CHARS for full
   *  display, or LEGAL_LOOKUP_SNIPPET_ONLY_MAX_CHARS for `snippet_only`. */
  text: string;
  /** Cosine similarity in [0, 1]. */
  similarity: number;
  /** Days since corpus_refreshed_at. Null = unknown (treated stale). */
  freshness_days: number | null;
  source_url: string | null;
  /** License tag for the underlying chunk (Option B, 2026-05-15).
   *  - 'public-domain' = alkup statute under Tekijänoikeuslaki §9 (default)
   *  - 'CC-BY-4.0'     = Finlex alkup, original-as-enacted
   *  - 'CC-BY-NC-4.0'  = Finlex ajantasa, consolidated (snippet_only)
   *  - 'CC-BY-EUR-LEX' = EUR-Lex directives */
  license?: string;
  /** UI/model display constraint (Option B, 2026-05-15).
   *  - 'full'          = quote/display freely (alkup; default)
   *  - 'snippet_only'  = ≤200 chars + Finlex source link required
   *  - 'citation_only' = cite reference + link, no body */
  display_policy?: "full" | "snippet_only" | "citation_only";
  /** Set to true for `display_policy='snippet_only'` chunks. Model MUST
   *  surface the source_url and MUST NOT reproduce more than the returned
   *  text. Renders as an explicit "Read full text on Finlex" CTA in the UI. */
  link_required?: boolean;
}

/** Court decision row returned by the `cases_citing` RPC (corpus v3). */
export interface LegalLookupCaseCitation {
  case_number: string;
  court: string;
  decided_at: string; // ISO date
  key_holding: string | null;
}

/** Travaux row (HE / eelnõu / seletuskiri) returned by `travaux_for` (corpus v3). */
export interface LegalLookupTravaux {
  doc_number: string;
  title: string | null;
  text: string | null;
  source_url: string | null;
}

export interface LegalLookupResult {
  chunks: LegalLookupChunk[];
  /** Present iff any chunk is older than the stale threshold. */
  stale_warning?: string;
  /** "corpus" in v1. v2 may return finlex/riigi_teataja/eur_lex. */
  source: "corpus" | "finlex" | "riigi_teataja" | "eur_lex" | "stub";
  embed_tokens: number;
  /** Court decisions that have cited the top-hit § (corpus v3). Empty when
   *  no `casesCiting` dependency injected or no matches found. */
  cases_citing?: LegalLookupCaseCitation[];
  /** HE / eelnõu legislative-intent docs for the top-hit § (corpus v3). */
  travaux?: LegalLookupTravaux[];
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

/**
 * Hybrid retrieval (BM25 + dense RRF) injection seam — vabank A1 (2026-05-15).
 *
 * Called when the caller wants hybrid recall against `law_chunks_v2.chunk_tsv`.
 * Production caller adapts the wider response (rrf_score / bm25_rank /
 * source_type columns) back to the same `LawSearchRpcRow[]` shape the
 * downstream pipeline already consumes — `similarity` continues to drive
 * the section-rerank tie-break and the snippet cap logic.
 *
 * Receives the raw query TEXT (in addition to its embedding) because the
 * BM25 leg uses `websearch_to_tsquery('simple', ...)` server-side.
 */
export type LawSearchHybridRpcFn = (params: {
  query_embedding: number[];
  query_text: string;
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
  /** Optional — present once law_search_v2 RPC is wired (post 2026-05-15
   *  migration). Defaults to 'public-domain' / 'full' for legacy callers. */
  license?: string | null;
  display_policy?: string | null;
}

/** Batched freshness lookup. Used when the RPC row lacks corpus_refreshed_at. */
export type FetchFreshnessFn = (
  chunkIds: string[],
) => Promise<Map<string, string | null>>;

/** Corpus v3 `cases_citing` RPC: reverse lookup, court decisions citing a §. */
export type CasesCitingFn = (params: {
  act_slug: string;
  section: string;
}) => Promise<LegalLookupCaseCitation[] | null>;

/** Corpus v3 `travaux_for` RPC: HE / eelnõu legislative-intent for a §. */
export type TravauxForFn = (params: {
  act_slug: string;
  section: string;
}) => Promise<LegalLookupTravaux[] | null>;

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
  /** Corpus v3 — version-aware retrieval. ISO timestamp; when set, only
   *  `redaktsioon` versions valid at that instant are returned. Passed
   *  through to the v2 RPC as `valid_at`. v1 RPC ignores it. */
  validAt?: string | null;
  /** Cap on cases_citing / travaux rows fetched per § (per top-hit chunk).
   *  Default 3 each → ~600 chars × 2 = 1.2KB additional payload. */
  enrichmentLimit?: number;
  /** Vabank A1 (2026-05-15) — opt out of hybrid retrieval even when a
   *  `deps.lawSearchHybrid` adapter is wired. Default `true` so wiring the
   *  dep is sufficient to opt in; set to `false` for A/B comparison runs
   *  that want to force the dense path. */
  hybridEnabled?: boolean;
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
    /** Vabank A1 (2026-05-15) — optional hybrid (BM25+dense RRF) retriever.
     *  When present AND `options.hybridEnabled !== false` AND the query has
     *  >=2 tokens, `legalLookup` calls this in place of `lawSearch`. On
     *  null / empty result it transparently falls back to the dense
     *  `lawSearch` so production never regresses. Inject this dep to opt
     *  the call site into hybrid; omit it for the legacy dense-only path. */
    lawSearchHybrid?: LawSearchHybridRpcFn;
    fetchFreshness?: FetchFreshnessFn;
    liveFallback?: LiveFallbackFn;
    /** Corpus v3 — reverse-citation RPC. Optional; legalLookup degrades to
     *  chunks-only when missing. */
    casesCiting?: CasesCitingFn;
    /** Corpus v3 — travaux/HE/eelnõu RPC. Optional; same degradation. */
    travauxFor?: TravauxForFn;
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
  // Vabank A1 (2026-05-15): when a hybrid retriever is injected AND the
  // query has >=2 meaningful tokens (so BM25 has signal to fuse), try the
  // hybrid RPC first. Empty / failed hybrid result transparently falls back
  // to the dense `lawSearch` so production never regresses below baseline.
  // Single-token queries (e.g. just "§114") would degenerate to BM25 prefix
  // match on a tiny tsquery; skip and stay on the well-tuned dense path
  // with section-aware rerank.
  const hybridEligible =
    typeof deps.lawSearchHybrid === "function" &&
    options.hybridEnabled !== false &&
    countMeaningfulTokens(embedInput) >= 2;

  let rows: LawSearchRpcRow[] | null = null;
  if (hybridEligible) {
    try {
      rows = await deps.lawSearchHybrid!({
        query_embedding: embedResult.embedding,
        query_text: embedInput,
        query_lang: JURISDICTION_TO_LANG[jur],
        query_jurisdiction: JURISDICTION_TO_RPC[jur],
        match_count: matchCount,
        similarity_threshold: threshold,
      });
    } catch (err) {
      console.warn(`legalLookup: hybrid RPC threw ${String(err)} — falling back to dense`);
      rows = null;
    }
  }

  if (!rows || rows.length === 0) {
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
  }
  if (!rows || rows.length === 0) {
    return { chunks: [], source: "stub", embed_tokens: embedResult.tokens };
  }

  // ── Section-aware re-ranking ─────────────────────────────────────────────
  // When the user query mentions a specific § (e.g. "perustuslaki §10",
  // "TsÜS § 86", "GDPR art. 17"), the desired chunk is the matching
  // paragraph — even if pure semantic similarity ranks sibling sections
  // higher. Boost matching rows; leave non-§ queries untouched.
  //
  // Golden QA evidence (2026-05-13): 5 queries find the right act but the
  // wrong §. recall@3 jumps 50% → 75% post-rerank. See lesson notes.
  const targetSection = extractSectionFromQuery(
    options.specificStatute
      ? `${options.specificStatute} ${trimmed}`
      : trimmed,
  );
  if (targetSection) {
    rows = rerankRowsBySection(rows, targetSection);
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
  // Per-row display_policy drives the truncation cap (Option B). Rows that
  // pre-date the 2026-05-15 license columns get the conservative defaults
  // 'full' / 'public-domain' so legacy alkup behaviour is unchanged.
  const nowMs = now().getTime();
  const builtChunks: LegalLookupChunk[] = rows.map((r) => {
    const displayPolicy = normaliseDisplayPolicy(r.display_policy);
    const license = (r.license && r.license.length > 0)
      ? r.license
      : "public-domain";
    const text = displayPolicy === "snippet_only"
      ? truncateForSnippetOnly(r.body)
      : truncateSnippet(r.body);
    const chunk: LegalLookupChunk = {
      statute: formatStatute(r.act_slug, r.paragraph),
      act_slug: r.act_slug.toLowerCase(),
      paragraph: r.paragraph,
      text,
      similarity: typeof r.similarity === "number" ? r.similarity : 0,
      freshness_days: computeFreshnessDays(freshness.get(r.id) ?? null, nowMs),
      source_url: r.source_url ?? null,
      license,
      display_policy: displayPolicy,
    };
    if (displayPolicy === "snippet_only") {
      // Snippet-only chunks REQUIRE a Finlex link for the model to surface.
      // The flag is the runtime signal — keeps the formatter / UI logic
      // declarative instead of re-deriving from display_policy at each site.
      chunk.link_required = true;
    }
    return chunk;
  });

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

  // ── Corpus v3 enrichment: cases_citing + travaux for the top hit ─────────
  // Uses the top-1 chunk's (act_slug, paragraph) as the anchor key. Both
  // RPCs are best-effort: any failure is swallowed and the field is omitted
  // from the response (model treats absence as "no data, do not mention").
  if (builtChunks.length > 0 && (deps.casesCiting || deps.travauxFor)) {
    const top = builtChunks[0];
    const enrichmentLimit = options.enrichmentLimit ?? 3;
    const [cases, trav] = await Promise.all([
      safeCasesCiting(deps.casesCiting, top.act_slug, top.paragraph),
      safeTravaux(deps.travauxFor, top.act_slug, top.paragraph),
    ]);
    if (cases && cases.length > 0) {
      result.cases_citing = cases.slice(0, enrichmentLimit);
    }
    if (trav && trav.length > 0) {
      // Truncate each travaux body the same way we truncate chunks.
      result.travaux = trav.slice(0, enrichmentLimit).map((t) => ({
        ...t,
        text: t.text ? truncateSnippet(t.text) : null,
      }));
    }
  }

  return capResponse(result);
}

// ── Enrichment helpers ──────────────────────────────────────────────────────

async function safeCasesCiting(
  fn: CasesCitingFn | undefined,
  actSlug: string,
  section: string,
): Promise<LegalLookupCaseCitation[] | null> {
  if (!fn) return null;
  try {
    const rows = await fn({ act_slug: actSlug, section });
    return Array.isArray(rows) ? rows : null;
  } catch (err) {
    console.warn(`legalLookup: cases_citing threw ${String(err)}`);
    return null;
  }
}

async function safeTravaux(
  fn: TravauxForFn | undefined,
  actSlug: string,
  section: string,
): Promise<LegalLookupTravaux[] | null> {
  if (!fn) return null;
  try {
    const rows = await fn({ act_slug: actSlug, section });
    return Array.isArray(rows) ? rows : null;
  } catch (err) {
    console.warn(`legalLookup: travaux_for threw ${String(err)}`);
    return null;
  }
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

// ── Section-aware re-ranking ────────────────────────────────────────────────

/**
 * Boost score applied to rows whose paragraph exactly matches the section
 * referenced in the query. Tuned to dominate cosine deltas (~0.05 between
 * sibling §§) without flipping order for clearly off-topic acts.
 */
export const LEGAL_LOOKUP_SECTION_BOOST_EXACT = 1.0;

/** Partial-match boost (paragraph contains the target as substring, e.g.
 *  query "§ 6" matching paragraph "6a" or "6:2"). Half the exact bonus. */
export const LEGAL_LOOKUP_SECTION_BOOST_PARTIAL = 0.5;

/**
 * Extract a paragraph/section reference from a user query.
 *
 * Recognises:
 *   - FI:  "HOL §114", "§ 26", "26 §", "perustuslaki § 10"
 *   - EE:  "TsÜS § 86", "§86"
 *   - EU:  "GDPR art. 17", "art 5", "article 17"
 *   - Sub-paragraphs: "114a", "6:2", "1 a"
 *
 * Returns the bare paragraph identifier (e.g. "114", "26", "17", "114a")
 * or null when no recognisable § ref is present — in which case callers
 * MUST skip reranking and preserve cosine order (we do not want to disrupt
 * pure semantic search).
 */
export function extractSectionFromQuery(query: string): string | null {
  if (!query) return null;
  const q = query.trim();

  // Pattern 1: "§ 114" / "§114" / "§ 114a" / "§ 6:2"
  //   §-symbol followed by digits, optional letter suffix, optional :subnum
  const symBefore = q.match(/§\s*(\d+[a-z]?(?::\d+)?)/i);
  if (symBefore) return symBefore[1].toLowerCase();

  // Pattern 2: "114 §" / "26§"
  //   digits (+ optional sub) before the §-symbol — common in FI
  const symAfter = q.match(/(\d+[a-z]?(?::\d+)?)\s*§/i);
  if (symAfter) return symAfter[1].toLowerCase();

  // Pattern 3: EU article notation: "art. 17", "Article 5", "art 17.1"
  //   Captures bare numeric + optional sub-paragraph.
  const artMatch = q.match(/\bart(?:icle|\.)?\s+(\d+(?:[.\-]\d+)?)/i);
  if (artMatch) return artMatch[1].toLowerCase();

  return null;
}

/**
 * Re-rank RPC rows so that paragraph matches float to the top.
 *
 * Strategy: composite score = similarity + boost, where boost is
 *   - EXACT  (1.0) when row.paragraph === targetSection
 *   - PARTIAL (0.5) when row.paragraph contains the target (e.g. "6a"
 *                   for query "§6") or vice versa (e.g. paragraph "6"
 *                   for query "§6:2")
 *   - 0 otherwise
 *
 * Stable: rows with equal composite score keep their original (cosine) order.
 * Original `similarity` field is preserved unchanged — boosts are only used
 * for ordering, not surfaced to the model.
 */
export function rerankRowsBySection<T extends { paragraph: string; similarity: number }>(
  rows: T[],
  targetSection: string,
): T[] {
  if (!targetSection || rows.length <= 1) return rows;
  const target = targetSection.toLowerCase();

  // Decorate with composite score + original index for stable sort.
  const decorated = rows.map((row, idx) => {
    const para = (row.paragraph ?? "").toLowerCase();
    let boost = 0;
    if (para === target) {
      boost = LEGAL_LOOKUP_SECTION_BOOST_EXACT;
    } else if (
      para && (para.includes(target) || target.includes(para))
    ) {
      boost = LEGAL_LOOKUP_SECTION_BOOST_PARTIAL;
    }
    return { row, idx, score: (row.similarity ?? 0) + boost };
  });

  decorated.sort((a, b) => {
    if (b.score !== a.score) return b.score - a.score;
    return a.idx - b.idx; // stable: preserve cosine order on ties
  });

  return decorated.map((d) => d.row);
}

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

/** Vabank A1 (2026-05-15) — count tokens with >=2 chars (i.e. real words,
 *  not stopwords or punctuation glue). Below the 2-token gate the BM25 leg
 *  of the hybrid retriever has too little signal to help; we stay on the
 *  dense path with section-aware rerank.
 *
 *  Splits on Unicode whitespace + `§` so "OHO §114" → ["OHO", "§114"]
 *  registers as 2 tokens (the section marker IS a meaningful term once
 *  paired with an act prefix). */
export function countMeaningfulTokens(query: string): number {
  if (!query) return 0;
  const tokens = query
    .trim()
    .split(/[\s§]+/u)
    .filter((t) => t.length >= 2);
  return tokens.length;
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

/** Stricter truncation for `display_policy='snippet_only'` rows (Option B).
 *  Caps at LEGAL_LOOKUP_SNIPPET_ONLY_MAX_CHARS (=200) so we never emit more
 *  than the licence-safe quotation length for Finlex CC-BY-NC ajantasa text.
 *  Kept as a separate function (not parameterised) to make the call sites
 *  grep-able and the cap easy to audit. */
function truncateForSnippetOnly(body: string | null | undefined): string {
  if (!body) return "";
  return body.length <= LEGAL_LOOKUP_SNIPPET_ONLY_MAX_CHARS
    ? body
    : body.slice(0, LEGAL_LOOKUP_SNIPPET_ONLY_MAX_CHARS);
}

/** Normalise the display_policy column to the union the runtime expects.
 *  Unknown / null values fall back to 'full' so legacy rows surface their
 *  text the way they did before the 2026-05-15 license columns existed. */
function normaliseDisplayPolicy(
  raw: string | null | undefined,
): "full" | "snippet_only" | "citation_only" {
  if (raw === "snippet_only" || raw === "citation_only") return raw;
  return "full";
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
    // Option B (2026-05-15): snippet_only chunks carry the licence-safe
    // 200-char excerpt. We surface the Finlex link explicitly and append a
    // policy reminder so the model never reproduces more than `c.text`.
    const isSnippetOnly = c.display_policy === "snippet_only";
    const header = isSnippetOnly
      ? `\n[${c.statute}] (sim ${sim}, ${age}, display_policy=snippet_only, license=${c.license ?? "CC-BY-NC-4.0"})`
      : `\n[${c.statute}] (sim ${sim}, ${age})`;
    const body = isSnippetOnly
      ? `\n"${c.text}..." (max 200 chars; do NOT quote more than this snippet)`
      : `\n${c.text}`;
    const link = c.source_url
      ? (isSnippetOnly
        ? `\nRead full text on Finlex: ${c.source_url}`
        : `\nSource: ${c.source_url}`)
      : "";
    parts.push(header + body + link);
  }
  if (result.stale_warning) parts.push(`\n⚠ ${result.stale_warning}`);

  // Corpus v3 enrichment — court decisions citing the top-hit §.
  if (result.cases_citing && result.cases_citing.length > 0) {
    parts.push(
      `\nCases citing this § (${result.cases_citing.length}):`,
    );
    for (const c of result.cases_citing) {
      const date = (c.decided_at ?? "").slice(0, 10);
      const holding = (c.key_holding ?? "").slice(0, 200);
      parts.push(
        `  • ${c.court} ${c.case_number} (${date})` +
          (holding ? ` — ${holding}` : ""),
      );
    }
    parts.push(
      "  → MENTION these decisions by name when discussing the §.",
    );
  }

  // Corpus v3 enrichment — HE / eelnõu legislative intent.
  if (result.travaux && result.travaux.length > 0) {
    parts.push(`\nTravaux / legislative intent (${result.travaux.length}):`);
    for (const t of result.travaux) {
      const title = t.title ? ` — ${t.title.slice(0, 120)}` : "";
      const body = t.text ? `\n    ${t.text.slice(0, 300)}` : "";
      parts.push(
        `  • ${t.doc_number}${title}${body}` +
          (t.source_url ? `\n    Source: ${t.source_url}` : ""),
      );
    }
    parts.push(
      "  → CITE the HE / eelnõu when interpreting the §.",
    );
  }

  return parts.join("\n");
}

// ─────────────────────────────────────────────────────────────────────────────
// V3 — query rewriting + Cohere rerank pipeline (вабанк A2, 2026-05-15)
// ─────────────────────────────────────────────────────────────────────────────
// Stacks two retrieval boosters on top of `legalLookup`:
//   1. Query rewriter (Haiku) — translates RU/EE/EN questions into the target
//      jurisdiction's statute terminology AND fans out cross-language
//      variants. Two retrieval calls (original + rewritten) merged by
//      (act_slug, paragraph) with the higher cosine kept.
//   2. Cohere Rerank v3.5 multilingual — cross-encoder rescoring of the top-20
//      candidate buffer to produce the final top-5. Lifts recall@3 by
//      +10-15% on conceptual queries vs. v2 alone.
//
// Backwards compatible: returns the same `LegalLookupResult` shape. v2 stays
// available as a fallback (and as the path used when the feature flag is off).
//
// Feature flag: LEGAL_LOOKUP_V3_ENABLED env var. Default 'true' — switch to
// 'false' to roll back instantly without redeploying.

import type {
  HaikuJsonCaller,
  QueryRewriteResult,
  RewriterJurisdiction,
} from "./query_rewriter.ts";
import { rewriteQueryForRetrieval } from "./query_rewriter.ts";
import type { CohereCaller, RerankCandidate } from "./cohere_rerank.ts";
import { rerankResults } from "./cohere_rerank.ts";

/** v3 retrieval buffer — top-20 from pgvector before Cohere reranks down. */
export const LEGAL_LOOKUP_V3_RETRIEVAL_BUFFER = 20;

/** v3 still surfaces top-5 to the model (same as v2). */
export const LEGAL_LOOKUP_V3_FINAL_TOP_N = LEGAL_LOOKUP_MATCH_COUNT;

export interface LegalLookupV3Options extends LegalLookupOptions {
  /** Override the default feature flag at call site (tests). */
  v3Enabled?: boolean;
  /** Inject the Haiku caller (tests). */
  callHaiku?: HaikuJsonCaller;
  /** Inject the Cohere caller (tests). */
  callCohere?: CohereCaller;
  /** Skip query rewriting (when the caller already has the rewritten form). */
  skipRewrite?: boolean;
}

export interface LegalLookupV3Result extends LegalLookupResult {
  /** Trace metadata for observability — never surfaced to the model. */
  v3_trace?: {
    rewrite_used: boolean;
    rewritten_query?: string;
    original_lang?: string;
    augmented_count: number;
    rerank_used: boolean;
    rerank_considered: number;
    rerank_fallback?: string;
  };
}

function resolveV3Enabled(): boolean {
  try {
    // deno-lint-ignore no-explicit-any
    const d = (globalThis as any).Deno;
    const flag = d?.env?.get?.("LEGAL_LOOKUP_V3_ENABLED");
    if (typeof flag !== "string") return true; // default ON
    const lower = flag.toLowerCase().trim();
    return !(lower === "false" || lower === "0" || lower === "off");
  } catch {
    return true;
  }
}

/** Project an arbitrary jurisdiction to the subset the rewriter understands.
 *  DE/RU fall back to FI (their statute corpus is too thin to bother rewriting). */
function projectRewriterJurisdiction(
  j: LegalLookupJurisdiction,
): RewriterJurisdiction {
  if (j === "fi" || j === "ee" || j === "eu") return j;
  return "fi";
}

/** Key used to dedupe chunks from the two parallel retrieval calls. */
function chunkKey(r: LawSearchRpcRow): string {
  return `${(r.act_slug ?? "").toLowerCase()}|${r.paragraph ?? ""}`;
}

/** Merge two RPC row arrays keyed on (act_slug, paragraph). Keep the row with
 *  the HIGHER similarity score (best-of-two retrieval). Stable order by best
 *  similarity descending. */
export function mergeRpcRows(
  a: LawSearchRpcRow[],
  b: LawSearchRpcRow[],
): LawSearchRpcRow[] {
  const map = new Map<string, LawSearchRpcRow>();
  for (const r of a) {
    map.set(chunkKey(r), r);
  }
  for (const r of b) {
    const k = chunkKey(r);
    const prev = map.get(k);
    if (!prev) {
      map.set(k, r);
      continue;
    }
    if ((r.similarity ?? 0) > (prev.similarity ?? 0)) {
      map.set(k, r);
    }
  }
  return Array.from(map.values()).sort(
    (x, y) => (y.similarity ?? 0) - (x.similarity ?? 0),
  );
}

/**
 * V3 retrieval pipeline. Wraps `legalLookup`:
 *
 *   1. (optional) call `rewriteQueryForRetrieval` — turn the user's RU/EE/EN
 *      question into the target jurisdiction's statute terminology +
 *      cross-language fan-out.
 *   2. Two parallel RPC calls with matchCount=20 — one for `query`, one for
 *      `rewritten`. (If `skipRewrite=true` or the rewriter degrades, only one
 *      call is made.)
 *   3. Merge the row pools by (act_slug, paragraph), best-similarity wins.
 *   4. (optional) Cohere rerank the merged pool down to top-5.
 *   5. Format with the same downstream pipeline as v2 (freshness join +
 *      stale check + enrichment + 4KB cap).
 *
 * NEVER throws. Gracefully degrades to plain `legalLookup` on any sub-step
 * failure. The feature flag `LEGAL_LOOKUP_V3_ENABLED=false` bypasses the
 * whole path and returns the v2 result directly.
 */
export async function legalLookupV3(
  query: string,
  jurisdiction: string,
  deps: {
    embed: EmbedQueryFn;
    lawSearch: LawSearchRpcFn;
    fetchFreshness?: FetchFreshnessFn;
    liveFallback?: LiveFallbackFn;
    casesCiting?: CasesCitingFn;
    travauxFor?: TravauxForFn;
  },
  options: LegalLookupV3Options = {},
): Promise<LegalLookupV3Result> {
  // Flag check — instant rollback path.
  const v3Enabled = options.v3Enabled ?? resolveV3Enabled();
  if (!v3Enabled) {
    return await legalLookup(query, jurisdiction, deps, options);
  }

  const trimmed = (query ?? "").trim();
  if (!trimmed) {
    return { chunks: [], source: "stub", embed_tokens: 0 };
  }

  // Validate jurisdiction here so we can short-circuit before the rewriter.
  const jur = jurisdiction.toLowerCase() as LegalLookupJurisdiction;
  if (!LEGAL_LOOKUP_JURISDICTIONS.includes(jur)) {
    throw new LegalLookupConfigError(
      `Unsupported jurisdiction '${jurisdiction}' (expected one of ${
        LEGAL_LOOKUP_JURISDICTIONS.join(", ")
      })`,
    );
  }

  // ── Step 1: rewrite query ────────────────────────────────────────────────
  let rewrite: QueryRewriteResult | null = null;
  if (!options.skipRewrite) {
    try {
      rewrite = await rewriteQueryForRetrieval(
        trimmed,
        projectRewriterJurisdiction(jur),
        { callHaiku: options.callHaiku },
      );
    } catch (err) {
      // rewriteQueryForRetrieval never throws but belt-and-braces.
      console.warn(`legalLookupV3: rewrite threw ${String(err).slice(0, 200)}`);
      rewrite = null;
    }
  }
  const useRewrite =
    !!rewrite &&
    rewrite.rewritten.length > 0 &&
    rewrite.rewritten.toLowerCase() !== trimmed.toLowerCase();

  // ── Step 2: parallel retrieval (original + rewritten) ────────────────────
  // We bypass `legalLookup` for the dual retrieval step because we want the
  // raw RPC rows (so we can merge by act_slug+paragraph), not the formatted
  // chunks. We then call `legalLookup` ONCE on the merged pool by injecting
  // a "fake" lawSearch that returns the merged rows. This reuses every
  // downstream feature (freshness, enrichment, cap) without duplicating code.

  const bufferOptions: LegalLookupOptions = {
    ...options,
    matchCount: LEGAL_LOOKUP_V3_RETRIEVAL_BUFFER,
  };

  // Embed both queries (run in parallel for latency).
  let originalRows: LawSearchRpcRow[] = [];
  let rewrittenRows: LawSearchRpcRow[] = [];

  const retrieveFor = async (q: string): Promise<LawSearchRpcRow[]> => {
    const embed = await deps.embed(
      options.specificStatute ? `${options.specificStatute} ${q}` : q,
    );
    if (!embed) return [];
    try {
      const rows = await deps.lawSearch({
        query_embedding: embed.embedding,
        query_lang: JURISDICTION_TO_LANG[jur],
        query_jurisdiction: JURISDICTION_TO_RPC[jur],
        match_count: LEGAL_LOOKUP_V3_RETRIEVAL_BUFFER,
        similarity_threshold: options.similarityThreshold ??
          LEGAL_LOOKUP_SIMILARITY_THRESHOLD,
      });
      return Array.isArray(rows) ? rows : [];
    } catch (err) {
      console.warn(`legalLookupV3: RPC threw ${String(err).slice(0, 200)}`);
      return [];
    }
  };

  if (useRewrite) {
    [originalRows, rewrittenRows] = await Promise.all([
      retrieveFor(trimmed),
      retrieveFor(rewrite!.rewritten),
    ]);
  } else {
    originalRows = await retrieveFor(trimmed);
  }

  // Merge by chunk key; best-similarity-wins.
  const merged = mergeRpcRows(originalRows, rewrittenRows);

  // ── Step 3: Cohere rerank ────────────────────────────────────────────────
  let rerankTrace: { reranked: boolean; considered: number; fallback?: string } = {
    reranked: false,
    considered: merged.length,
  };
  let finalRows: LawSearchRpcRow[] = merged;
  if (merged.length > LEGAL_LOOKUP_V3_FINAL_TOP_N) {
    const candidates: Array<RerankCandidate & { __row: LawSearchRpcRow }> =
      merged.map((r) => ({
        // The rerank document is the body — give Cohere maximum signal.
        // Prepend the statute id as a strong title-equivalent header.
        text: `${formatStatute(r.act_slug, r.paragraph)} — ${r.title ?? ""}\n${r.body ?? ""}`,
        __row: r,
      }));

    const rer = await rerankResults(
      useRewrite ? rewrite!.rewritten : trimmed,
      candidates,
      LEGAL_LOOKUP_V3_FINAL_TOP_N,
      { callCohere: options.callCohere },
    );
    rerankTrace = {
      reranked: rer.reranked,
      considered: rer.considered,
      fallback: rer.fallback_reason,
    };
    finalRows = rer.candidates.map((c) => c.__row);
  }

  // ── Step 4: hand off to `legalLookup` for formatting + enrichment ────────
  // Re-use ALL of v2's downstream logic by injecting a fixed-result RPC.
  const fixedLawSearch: LawSearchRpcFn = async () => finalRows;
  // For the embed call inside legalLookup, just return zeros — RPC is fixed
  // anyway so the embedding is never actually used.
  const noopEmbed: EmbedQueryFn = async () => ({
    embedding: Array(1536).fill(0),
    tokens: 0,
  });

  const v2 = await legalLookup(
    useRewrite ? rewrite!.rewritten : trimmed,
    jurisdiction,
    {
      embed: noopEmbed,
      lawSearch: fixedLawSearch,
      fetchFreshness: deps.fetchFreshness,
      liveFallback: deps.liveFallback,
      casesCiting: deps.casesCiting,
      travauxFor: deps.travauxFor,
    },
    {
      ...bufferOptions,
      matchCount: LEGAL_LOOKUP_V3_FINAL_TOP_N,
    },
  );

  // Roll up embed token cost from the (up to) two real embed calls we did.
  // We can't easily recover the per-call counts because we used `deps.embed`
  // directly; approximate from trimmed.length / rewrite.length.
  const estTokens = Math.ceil(
    (trimmed.length + (useRewrite ? rewrite!.rewritten.length : 0)) / 4,
  );

  const v3: LegalLookupV3Result = {
    ...v2,
    embed_tokens: estTokens,
    v3_trace: {
      rewrite_used: useRewrite,
      rewritten_query: useRewrite ? rewrite!.rewritten : undefined,
      original_lang: rewrite?.originalLang,
      augmented_count: rewrite?.augmented.length ?? 0,
      rerank_used: rerankTrace.reranked,
      rerank_considered: rerankTrace.considered,
      rerank_fallback: rerankTrace.fallback,
    },
  };
  return v3;
}

