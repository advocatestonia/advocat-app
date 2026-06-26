// _shared/doc_chunker.ts
// -----------------------------------------------------------------------------
// Pure chunking + embedding helpers for Feature #4 (semantic search over the
// user's own documents). No I/O except the explicit OpenAI fetch in
// `embedDocChunks` — the chunker itself is pure and unit-tested.
//
// Why a separate chunker from chunk_splitter.ts:
//   chunk_splitter.ts targets ONE chunk per legal § and only splits the rare
//   oversize §. For free-text user documents (contracts, letters, PDFs) we
//   want MANY small, OVERLAPPING windows so a phrase like "the deposit" lands
//   inside a focused chunk regardless of where it falls. Small overlapping
//   windows give much better recall for ad-hoc "where was X mentioned" search.
//
// Tunables:
//   TARGET_CHARS   ≈ 1000 chars (~250–400 tokens) — a focused passage.
//   OVERLAP_CHARS  ≈ 150 chars  — carries context across boundaries so a hit
//                                 spanning a window edge is still found.
//   MAX_CHARS      = 8000 chars — hard ceiling per chunk (well under OpenAI's
//                                 8191-token item cap even for dense FI/EE text
//                                 at ~2.4 chars/token).
// -----------------------------------------------------------------------------

import { scrubText } from "./llm_egress/scrub_body.ts";

export const TARGET_CHARS = 1000;
export const OVERLAP_CHARS = 150;
export const MAX_CHARS = 8000;

/** OpenAI item cap is 2048 inputs; we batch conservatively at 96. */
export const EMBED_BATCH_SIZE = 96;

export const OPENAI_EMBED_URL = "https://api.openai.com/v1/embeddings";
export const OPENAI_MODEL = "text-embedding-3-small";
export const EMBED_DIM = 1536;

export interface DocChunk {
  chunkIndex: number;
  text: string;
  charStart: number;
  charEnd: number;
}

/**
 * Normalise whitespace without destroying paragraph structure: collapse runs
 * of spaces/tabs, trim trailing spaces per line, but keep newlines so the
 * paragraph splitter still works.
 */
function normalise(input: string): string {
  return input
    .replace(/\r\n?/g, "\n")
    .replace(/[ \t]+/g, " ")
    .replace(/ *\n */g, "\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

/**
 * Split a document's plain text into overlapping chunks.
 *
 * Algorithm:
 *   1. Normalise whitespace.
 *   2. Walk the text in windows of ~TARGET_CHARS. For each window, try to end
 *      it at a natural boundary (paragraph break, sentence end, then space)
 *      searched backwards from the target cut so we don't slice mid-word.
 *   3. Start the next window OVERLAP_CHARS before the previous cut so context
 *      is carried across the boundary.
 *
 * Guarantees:
 *   - Every char of meaningful text is covered by at least one chunk.
 *   - No chunk exceeds MAX_CHARS.
 *   - Empty / whitespace-only input → [].
 *   - charStart/charEnd are offsets into the NORMALISED text (returned so the
 *     UI can highlight; absolute fidelity to the raw byte offsets is not a
 *     goal — they are advisory).
 */
export function chunkDocument(rawText: string): DocChunk[] {
  const text = normalise(rawText ?? "");
  if (text.length === 0) return [];

  const chunks: DocChunk[] = [];
  let cursor = 0;
  let chunkIndex = 0;

  while (cursor < text.length) {
    const hardEnd = Math.min(cursor + MAX_CHARS, text.length);
    const targetEnd = Math.min(cursor + TARGET_CHARS, text.length);

    let cut: number;
    if (targetEnd >= text.length) {
      cut = text.length;
    } else {
      cut = findBoundary(text, cursor, targetEnd, hardEnd);
    }

    const slice = text.slice(cursor, cut).trim();
    if (slice.length > 0) {
      // Recompute trimmed offsets so highlight is tight.
      const lead =
        text.slice(cursor, cut).length -
        text.slice(cursor, cut).trimStart().length;
      const start = cursor + lead;
      chunks.push({
        chunkIndex: chunkIndex++,
        text: slice,
        charStart: start,
        charEnd: start + slice.length,
      });
    }

    if (cut >= text.length) break;

    // Advance with overlap, but always make forward progress.
    const next = Math.max(cut - OVERLAP_CHARS, cursor + 1);
    cursor = next;
  }

  return chunks;
}

/**
 * Find a natural cut point at or before `targetEnd`, but never before
 * `from + 1` and never after `hardEnd`. Preference order:
 *   paragraph break (\n\n) > sentence end (. ! ? followed by space/newline) >
 *   single newline > space > targetEnd (hard cut).
 */
function findBoundary(
  text: string,
  from: number,
  targetEnd: number,
  hardEnd: number
): number {
  const window = text.slice(from, Math.min(targetEnd + OVERLAP_CHARS, hardEnd));

  // Search within [minViable, end-of-window] for a boundary closest to target.
  const minViable = Math.floor((targetEnd - from) * 0.5); // don't make tiny chunks

  const para = lastBoundary(window, minViable, /\n\n/g);
  if (para >= 0) return from + para;

  const sentence = lastBoundary(window, minViable, /[.!?](?=\s|$)/g);
  if (sentence >= 0) return from + sentence + 1; // include the punctuation

  const newline = window.lastIndexOf("\n", targetEnd - from);
  if (newline >= minViable) return from + newline + 1;

  const space = window.lastIndexOf(" ", targetEnd - from);
  if (space >= minViable) return from + space + 1;

  // No boundary found — hard cut at target.
  return Math.min(targetEnd, hardEnd);
}

/** Index (relative to `s`) of the boundary closest to but not before `min`,
 * and not past `s.length`. Returns -1 if none. We scan all matches and pick
 * the LAST one that still leaves the chunk reasonably sized. */
function lastBoundary(s: string, min: number, re: RegExp): number {
  let best = -1;
  let m: RegExpExecArray | null;
  re.lastIndex = 0;
  while ((m = re.exec(s)) !== null) {
    const idx = m.index;
    if (idx >= min) {
      best = idx;
    }
    if (m.index === re.lastIndex) re.lastIndex++; // avoid zero-width loop
  }
  return best;
}

// ── Embedding ────────────────────────────────────────────────────────────────

export interface EmbedResult {
  embeddings: number[][];
  tokens: number;
}

/**
 * Embed an array of texts via OpenAI text-embedding-3-small. Mirrors the
 * corpus-embedder contract (1536-dim, ordered, validated). Throws on any
 * shape mismatch so the caller never writes a malformed vector.
 *
 * `fetchImpl` is injectable for tests.
 */
export async function embedTexts(
  texts: string[],
  apiKey: string,
  fetchImpl: typeof fetch = fetch
): Promise<EmbedResult> {
  if (!apiKey) throw new Error("OPENAI_API_KEY not set");
  if (texts.length === 0) return { embeddings: [], tokens: 0 };
  if (texts.length > 2048) {
    throw new Error(
      `too many inputs (${texts.length}); cap is 2048 per request`
    );
  }

  // GDPR / Data Fortress: this is the ONE embedding egress to OpenAI (a US
  // sub-processor). Both the index path (doc-indexer) and the query path
  // (doc-semantic-search) flow through here, so scrubbing in this single place
  // keeps index and query in the SAME scrub-space (no recall loss) while
  // ensuring no raw isikukood/HETU/IBAN/name/Art.9 text from a user's PRIVATE
  // documents ever reaches OpenAI. full:true is correct — embeddings don't
  // need name fidelity. The stored user_doc_chunks.text column keeps the RAW
  // text (under RLS) for UI highlighting; only this outbound copy is scrubbed.
  const inputs = texts.map((t) => {
    const capped = t.length > MAX_CHARS ? t.slice(0, MAX_CHARS) : t;
    return scrubText(capped, { full: true });
  });

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 60_000);
  let resp: Response;
  try {
    resp = await fetchImpl(OPENAI_EMBED_URL, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: OPENAI_MODEL,
        input: inputs,
        encoding_format: "float",
      }),
      signal: controller.signal,
    });
  } finally {
    clearTimeout(timer);
  }

  if (!resp.ok) {
    const detail = await resp.text().catch(() => "");
    throw new Error(`OpenAI ${resp.status}: ${detail.slice(0, 240)}`);
  }

  const data = (await resp.json()) as {
    data?: Array<{ embedding?: number[]; index?: number }>;
    usage?: { total_tokens?: number; prompt_tokens?: number };
  };
  const items = data?.data ?? [];
  if (items.length !== texts.length) {
    throw new Error(
      `OpenAI returned ${items.length} embeddings for ${texts.length} inputs`
    );
  }
  const sorted = items.slice().sort((a, b) => (a.index ?? 0) - (b.index ?? 0));
  const embeddings: number[][] = [];
  for (let i = 0; i < sorted.length; i++) {
    const e = sorted[i]?.embedding;
    if (!Array.isArray(e) || e.length !== EMBED_DIM) {
      throw new Error(
        `OpenAI item ${i} has bad embedding (len=${
          Array.isArray(e) ? e.length : "n/a"
        })`
      );
    }
    embeddings.push(e);
  }
  const tokens = data?.usage?.total_tokens ?? data?.usage?.prompt_tokens ?? 0;
  return { embeddings, tokens };
}

/** Estimate OpenAI cost (USD) for an embed call given prompt tokens. */
export function embedCostUsd(tokens: number): number {
  // text-embedding-3-small: $0.02 / 1M tokens.
  return (tokens / 1_000_000) * 0.02;
}
