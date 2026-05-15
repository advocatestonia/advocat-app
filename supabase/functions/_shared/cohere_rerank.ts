// cohere_rerank.ts — вабанк A2 (2026-05-15)
// -----------------------------------------------------------------------------
// Wraps Cohere's Rerank v3.5 multilingual endpoint. We retrieve a top-20
// candidate pool from pgvector (cheap, ~recall@20 ≈ 90%), then ask Cohere to
// re-score them. Cohere has a real cross-encoder under the hood (vs. bi-encoder
// embeddings) so it captures interactions our pgvector pass cannot, giving
// +10-15% on recall@3 for conceptual queries (eval baseline in deploy report).
//
// Cost: $1 per 1000 reranks at 100 docs / req (we send ~20). The free tier
// covers 100 calls/мес. At 10K legal queries/мес that's ~$10/мес.
//
// Graceful degradation: if the API key is missing, the endpoint 4xxs, or the
// network times out, we return the ORIGINAL candidates in their original
// order. Callers can rely on `rerankResults` never throwing.
// -----------------------------------------------------------------------------

// ─── Public types ───────────────────────────────────────────────────────────

/** Generic candidate. We require a `text` field for the rerank document; any
 *  other fields ride along unchanged. */
export interface RerankCandidate {
  text: string;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  [key: string]: unknown;
}

export interface RerankResult<T extends RerankCandidate = RerankCandidate> {
  /** Re-ordered candidates, top-N most relevant first. */
  candidates: T[];
  /** Whether the Cohere call actually ran. False ⇒ fallback to input order. */
  reranked: boolean;
  /** Number of input candidates considered. */
  considered: number;
  /** Reason the fallback fired (empty when reranked=true). Useful for
   *  observability in the calling edge fn. */
  fallback_reason?: "no_api_key" | "http_error" | "parse_error" | "timeout" |
    "empty_input";
}

// ─── Constants ──────────────────────────────────────────────────────────────

export const COHERE_RERANK_URL = "https://api.cohere.com/v2/rerank";
/** Cohere's current GA multilingual reranker (supports 100+ languages
 *  including FI/EE/RU). v3 is deprecated in favour of v3.5. */
export const COHERE_RERANK_MODEL = "rerank-v3.5";
/** Hard upper bound on the candidate pool we send to Cohere. The model
 *  itself accepts up to 1000 but per-call cost scales with N; 50 is more
 *  than enough to cover any reasonable retrieval buffer. */
export const COHERE_RERANK_MAX_DOCS = 50;
/** Per-document character cap before sending. Cohere bills by tokens; we
 *  truncate to keep payload sane. 2000 chars ≈ 500 tokens. */
export const COHERE_RERANK_MAX_DOC_CHARS = 2000;
/** Request timeout. The Cohere p95 is under 800ms; cut at 5s. */
export const COHERE_RERANK_TIMEOUT_MS = 5000;

// ─── Env resolver ───────────────────────────────────────────────────────────

function resolveCohereApiKey(): string | null {
  try {
    // deno-lint-ignore no-explicit-any
    const d = (globalThis as any).Deno;
    const k = d?.env?.get?.("COHERE_API_KEY");
    return typeof k === "string" && k.length > 0 ? k : null;
  } catch {
    return null;
  }
}

// ─── Injectable caller ──────────────────────────────────────────────────────

/** Raw API response shape we care about. The v2 endpoint returns
 *  `{ results: [{ index, relevance_score }], id, meta }`. */
export interface CohereRerankApiResponse {
  results: Array<{ index: number; relevance_score: number }>;
}

/** Injectable for tests: hits the network with the assembled body and
 *  returns the parsed response. Throw on non-2xx / parse failure. */
export type CohereCaller = (body: {
  model: string;
  query: string;
  documents: string[];
  top_n: number;
}) => Promise<CohereRerankApiResponse>;

export function defaultCohereCaller(apiKey: string): CohereCaller {
  return async (body) => {
    const ctrl = new AbortController();
    const t = setTimeout(() => ctrl.abort(), COHERE_RERANK_TIMEOUT_MS);
    try {
      const res = await fetch(COHERE_RERANK_URL, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${apiKey}`,
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: JSON.stringify(body),
        signal: ctrl.signal,
      });
      if (!res.ok) {
        const errText = await res.text();
        throw new Error(
          `cohere_rerank ${res.status}: ${errText.slice(0, 200)}`,
        );
      }
      const parsed = await res.json() as CohereRerankApiResponse;
      if (!parsed || !Array.isArray(parsed.results)) {
        throw new Error("cohere_rerank: missing results[] in response");
      }
      return parsed;
    } finally {
      clearTimeout(t);
    }
  };
}

// ─── Public entry point ─────────────────────────────────────────────────────

/**
 * Re-rank a candidate list by Cohere relevance against `query`. Top-N are
 * returned; remaining candidates are dropped. Original objects are preserved
 * (we re-order references, not deep-clone).
 *
 * NEVER throws. On any failure we return the first `topN` candidates in
 * their original input order and set `reranked: false` with a `fallback_reason`.
 *
 * @param query       The search query (already rewritten by query_rewriter).
 * @param candidates  Candidate pool from pgvector retrieval (≤50 used).
 * @param topN        How many to return after rerank.
 * @param deps        Injectable Cohere caller for tests.
 */
export async function rerankResults<T extends RerankCandidate>(
  query: string,
  candidates: T[],
  topN: number,
  deps: { callCohere?: CohereCaller } = {},
): Promise<RerankResult<T>> {
  const safeTopN = Math.max(1, topN | 0);
  if (!Array.isArray(candidates) || candidates.length === 0) {
    return { candidates: [], reranked: false, considered: 0, fallback_reason: "empty_input" };
  }

  // Cap the pool size.
  const pool = candidates.slice(0, COHERE_RERANK_MAX_DOCS);
  const considered = pool.length;

  // Resolve caller.
  let caller = deps.callCohere;
  if (!caller) {
    const apiKey = resolveCohereApiKey();
    if (!apiKey) {
      return {
        candidates: pool.slice(0, safeTopN),
        reranked: false,
        considered,
        fallback_reason: "no_api_key",
      };
    }
    caller = defaultCohereCaller(apiKey);
  }

  // Build documents — truncate each to keep payload bounded.
  const documents = pool.map((c) => {
    const t = typeof c.text === "string" ? c.text : "";
    return t.length > COHERE_RERANK_MAX_DOC_CHARS
      ? t.slice(0, COHERE_RERANK_MAX_DOC_CHARS)
      : t;
  });

  // Cohere requires non-empty docs. If any are empty, replace with single
  // space so the index alignment stays intact.
  for (let i = 0; i < documents.length; i++) {
    if (!documents[i] || documents[i].length === 0) {
      documents[i] = " ";
    }
  }

  let api: CohereRerankApiResponse;
  try {
    api = await caller({
      model: COHERE_RERANK_MODEL,
      query: query.slice(0, 4000), // hard ceiling — Cohere docs say ≤10K
      documents,
      top_n: Math.min(safeTopN, pool.length),
    });
  } catch (err) {
    const msg = String(err);
    const reason: RerankResult["fallback_reason"] = msg.includes("aborted")
      ? "timeout"
      : msg.includes("cohere_rerank") && msg.includes("results")
      ? "parse_error"
      : "http_error";
    console.warn(`cohere_rerank: fallback (${reason}): ${msg.slice(0, 200)}`);
    return {
      candidates: pool.slice(0, safeTopN),
      reranked: false,
      considered,
      fallback_reason: reason,
    };
  }

  // Map Cohere's index → reordered candidates.
  const ordered: T[] = [];
  const seen = new Set<number>();
  for (const r of api.results) {
    const idx = r.index;
    if (typeof idx !== "number" || idx < 0 || idx >= pool.length) continue;
    if (seen.has(idx)) continue;
    seen.add(idx);
    ordered.push(pool[idx]);
    if (ordered.length >= safeTopN) break;
  }

  // Defensive: if Cohere returned no usable indices, fall back.
  if (ordered.length === 0) {
    return {
      candidates: pool.slice(0, safeTopN),
      reranked: false,
      considered,
      fallback_reason: "parse_error",
    };
  }

  return { candidates: ordered, reranked: true, considered };
}
