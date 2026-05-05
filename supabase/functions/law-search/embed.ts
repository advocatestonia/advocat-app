// law-search/embed.ts
// -----------------------------------------------------------------------------
// Thin wrapper around OpenAI's embeddings endpoint. Pulled out of index.ts so
// the runtime path is testable in isolation (and so a future swap to a local
// embedding model is a one-file change).
//
// Model: text-embedding-3-small — 1536 dimensions, the size the
// `law_chunks.embedding` vector column was provisioned for. Do NOT swap to
// `text-embedding-3-large` without a schema migration: the column type is
// `vector(1536)` and pgvector will reject 3072-d vectors at insert time.
// -----------------------------------------------------------------------------

const OPENAI_EMBED_URL = "https://api.openai.com/v1/embeddings";
const OPENAI_MODEL = "text-embedding-3-small";

export class EmbeddingError extends Error {
  readonly detail?: unknown;
  constructor(message: string, detail?: unknown) {
    super(message);
    this.name = "EmbeddingError";
    this.detail = detail;
  }
}

export interface EmbedResult {
  embedding: number[];
  /** Total tokens consumed (prompt only — embeddings have no completion). */
  tokens: number;
}

/**
 * Embed a single text via OpenAI. The chat layer's RAG budget assumes a 5s
 * hard timeout — beyond that we fall back to no-RAG to keep the chat turn
 * responsive.
 *
 * Returns null on any failure (timeout, network, non-200, malformed body) so
 * the caller can collapse to `{chunks: []}` per the P0-3 graceful-degradation
 * contract. Throws ONLY on misconfiguration (missing API key) — that is a
 * server-side bug, not a degraded-mode condition.
 */
export async function embedQuery(
  query: string,
  opts: { apiKey: string; timeoutMs?: number; signal?: AbortSignal } = {
    apiKey: "",
  },
): Promise<EmbedResult | null> {
  if (!opts.apiKey) {
    throw new EmbeddingError("OPENAI_API_KEY not set");
  }
  if (!query || !query.trim()) {
    return null;
  }

  const timeoutMs = opts.timeoutMs ?? 5000;
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort("timeout"), timeoutMs);

  // If the caller passed an outer signal (test harness), tie it in.
  if (opts.signal) {
    if (opts.signal.aborted) controller.abort();
    else opts.signal.addEventListener("abort", () => controller.abort(), { once: true });
  }

  try {
    const resp = await fetch(OPENAI_EMBED_URL, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${opts.apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: OPENAI_MODEL,
        input: query,
        encoding_format: "float",
      }),
      signal: controller.signal,
    });

    if (!resp.ok) {
      const detail = await resp.text().catch(() => "");
      console.warn(`embedQuery: OpenAI ${resp.status} — ${detail.slice(0, 240)}`);
      return null;
    }

    const data = await resp.json() as {
      data?: Array<{ embedding?: number[] }>;
      usage?: { total_tokens?: number; prompt_tokens?: number };
    };
    const embedding = data?.data?.[0]?.embedding;
    if (!Array.isArray(embedding) || embedding.length !== 1536) {
      console.warn(
        `embedQuery: malformed response (embedding length=${
          Array.isArray(embedding) ? embedding.length : "n/a"
        })`,
      );
      return null;
    }
    const tokens = data?.usage?.total_tokens ?? data?.usage?.prompt_tokens ?? 0;
    return { embedding, tokens };
  } catch (err) {
    // Timeout, network, abort — all collapse to the same graceful no-op.
    console.warn(`embedQuery: ${String(err)}`);
    return null;
  } finally {
    clearTimeout(timer);
  }
}
