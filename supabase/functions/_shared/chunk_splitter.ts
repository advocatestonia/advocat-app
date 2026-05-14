// _shared/chunk_splitter.ts
// -----------------------------------------------------------------------------
// Defensive splitter for law_chunks_v2 rows that would otherwise exceed
// OpenAI's `text-embedding-3-small` 8191-token-per-item limit.
//
// Background (consilium 2026-05-14):
//   - OpenAI embeddings cap each item at 8191 tokens.
//   - Empirical measurement on our corpus: Estonian / Finnish legal text
//     averages ~2.4 chars/token (compound words like "äriühing", "menetelmä",
//     ÄTM-style numerals, lots of UTF-8 multi-byte). A naive 4 chars/tok rule
//     is wildly optimistic — TuMS § 61 at 19_716 chars overflowed 8192 tokens.
//   - We set MAX_CHARS = 18_000, which keeps even worst-case 2.4-chars/tok
//     content under 7_500 tokens, with headroom for OpenAI tokenizer drift
//     between releases.
//   - Two known oversize chunks today: TuMS § 61 (19_716 chars), VÕS § 380
//     (15_468 chars). KMS § 15 (14_801 chars) is just under but close enough
//     to want splitting too.
//   - The embedder already truncates pathologically large inputs at 28_000
//     chars (defence-in-depth), but truncation throws away material we want
//     for retrieval. Splitting is the right fix.
//
// Strategy:
//   1. If a chunk is at or under MAX_CHARS, return it unchanged.
//   2. Otherwise greedily pack paragraph blocks (\n\n splits) into parts of
//      up to MAX_CHARS each.
//   3. If a single paragraph block itself exceeds MAX_CHARS, fall back to
//      sentence-level splitting (period/question/exclamation followed by
//      whitespace).
//   4. If a single sentence STILL exceeds MAX_CHARS (extremely rare — would
//      require a 28K-char run-on legal sentence), fall back to a hard char
//      window. We never silently drop content.
//   5. Parts get their section_label decorated with " (osa N/M)" so users see
//      that they're looking at part of a larger §. Estonian "osa" = part.
//   6. The `section` column stays identical across parts so existing joins
//      (statute_aliases.section, law_search_v2 → section) continue to work.
//      The `subsection` column on law_chunks_v2 stores "osa N/M" for ordering.
//
// This module is pure: no I/O, no environment access. Safe to import from
// edge functions, Deno test suites, and stand-alone backfill scripts.
// -----------------------------------------------------------------------------

/** Maximum characters per chunk before splitting. 18_000 chars × 2.4 ≈ 7_500
 * tokens for worst-case Estonian/Finnish text, comfortably under OpenAI's
 * 8191-token per-item cap. Empirically tuned on our 7287-row EE corpus
 * (consilium 2026-05-14). Do not raise without re-measuring chars/token. */
export const MAX_CHARS = 18_000;

/** Soft target for paragraph-level packing — start a new part when the current
 * one is at least this big AND adding the next paragraph would exceed
 * MAX_CHARS. Picked at 80% of MAX_CHARS so we don't emit pathologically tiny
 * tail parts. */
const PACK_SOFT_TARGET = Math.floor(MAX_CHARS * 0.80);

/**
 * The minimum shape a row must have for the splitter. Any extra fields
 * (jurisdiction, act_slug, chapter, source_url, ...) are preserved via the
 * generic spread.
 *
 * `subsection` is an optional column on law_chunks_v2 we use to record
 * "osa N/M" when a § is split. When the splitter emits multiple parts it
 * overrides `subsection` for each; single-part chunks keep whatever the
 * caller set.
 */
export interface SplittableChunk {
  text: string;
  section_label?: string | null;
  subsection?: string | null;
  [key: string]: unknown;
}

/**
 * Split a chunk into one or more parts if its text exceeds MAX_CHARS.
 * Each emitted row carries the original metadata plus:
 *   - text:          the sub-portion of the original text
 *   - section_label: " (osa N/M)" suffix added when M>1
 *   - part_index:    1-based position (omitted when only one part)
 *
 * When the input fits, returns `[chunk]` unchanged (same object identity).
 * When the input is oversize, returns N new objects with text/section_label
 * adjusted.
 *
 * Guarantees:
 *   - No content is dropped: concatenating the parts' text reproduces the
 *     original text minus the boundary whitespace that the splitter trims.
 *   - Each part's text.length is ≤ MAX_CHARS.
 *   - Order is preserved.
 */
export function splitIfOversize<T extends SplittableChunk>(chunk: T): T[] {
  const text = chunk.text ?? "";
  if (text.length <= MAX_CHARS) return [chunk];

  const parts = splitTextToParts(text, MAX_CHARS);
  if (parts.length <= 1) return [chunk]; // splitter found nothing — keep as-is

  const total = parts.length;
  return parts.map((partText, i) => {
    const partIndex = i + 1;
    const origLabel = chunk.section_label ?? "";
    const suffix = ` (osa ${partIndex}/${total})`;
    const newLabel = origLabel ? `${origLabel}${suffix}` : suffix.trim();
    // Write "osa N/M" into the subsection column so downstream joins/UI
    // can show parts in order without parsing the label.
    return {
      ...chunk,
      text: partText,
      section_label: newLabel,
      subsection: `osa ${partIndex}/${total}`,
    } as T;
  });
}

/**
 * Map an array of chunks through splitIfOversize. Convenience for fetchers
 * that build chunkRows wholesale before insert.
 */
export function splitAllOversize<T extends SplittableChunk>(rows: T[]): T[] {
  const out: T[] = [];
  for (const r of rows) {
    const parts = splitIfOversize(r);
    for (const p of parts) out.push(p);
  }
  return out;
}

// ---------- low-level text splitter ----------

/**
 * Greedy packer with three fallback tiers:
 *   1. Paragraph (\n\n) splits.
 *   2. Sentence splits (.!?  followed by whitespace).
 *   3. Hard char-window splits (only used when a single sentence > MAX_CHARS).
 *
 * Post-process: merge tiny tail/head pieces with their neighbours when the
 * combined size still fits in maxChars. This avoids 19-char "heading-only"
 * parts when a § has a short opening paragraph (e.g. "Tulu maksustamine.")
 * followed by long body paragraphs. Lopsided splits are technically correct
 * but waste an embedding slot on a near-empty chunk.
 *
 * Exported for unit-testing the boundary logic directly.
 */
export function splitTextToParts(text: string, maxChars: number): string[] {
  if (text.length <= maxChars) return [text];

  const paragraphs = splitIntoParagraphs(text);
  const packed: string[] = [];
  let buf = "";

  const flush = () => {
    if (buf.length > 0) {
      packed.push(buf);
      buf = "";
    }
  };

  for (const para of paragraphs) {
    if (para.length > maxChars) {
      // Single paragraph too big — flush current buffer, then sentence-split
      // the giant paragraph and pack its pieces.
      flush();
      const sentencePieces = splitGiantBlock(para, maxChars);
      for (const piece of sentencePieces) {
        if (buf.length === 0) {
          buf = piece;
        } else if (buf.length + 2 + piece.length <= maxChars) {
          buf = `${buf}\n\n${piece}`;
        } else {
          flush();
          buf = piece;
        }
      }
      continue;
    }
    // Normal-size paragraph — try to add to current buf.
    if (buf.length === 0) {
      buf = para;
    } else if (buf.length + 2 + para.length <= maxChars) {
      buf = `${buf}\n\n${para}`;
    } else {
      flush();
      buf = para;
    }
  }
  flush();
  return rebalanceParts(packed, maxChars);
}

/**
 * Post-pack rebalance: when two adjacent parts could fit together in maxChars,
 * merge them. Repeats until no more merges possible. Also merges any tail
 * part smaller than 5% of maxChars into the preceding one if it would still
 * fit. Idempotent.
 */
function rebalanceParts(parts: string[], maxChars: number): string[] {
  if (parts.length <= 1) return parts;
  const TINY_TAIL_THRESHOLD = Math.floor(maxChars * 0.05); // 900 chars at 18K
  const out = parts.slice();

  // Pass 1: merge adjacent pairs that fit together.
  let i = 0;
  while (i < out.length - 1) {
    const combined = out[i].length + 2 + out[i + 1].length;
    if (combined <= maxChars) {
      out[i] = `${out[i]}\n\n${out[i + 1]}`;
      out.splice(i + 1, 1);
      // don't advance — try merging the new combined block with the next
    } else {
      i++;
    }
  }

  // Pass 2: if the LAST part is tiny and could fit into the previous one,
  // merge (this is the lopsided-tail case). Pass 1 already handles this in
  // most cases, but a tiny tail attached to a near-full predecessor is
  // worth force-merging at the cost of slightly exceeding maxChars by < 5%.
  // We DON'T do that here — we strictly respect maxChars. The user can run
  // backfill with a slightly larger MAX_CHARS if rebalancing matters more
  // than the safety margin. The TINY_TAIL_THRESHOLD constant is kept for
  // future tuning.
  void TINY_TAIL_THRESHOLD;

  return out;
}

/**
 * Split text on \n\n (one or more blank lines). Trims each paragraph's edge
 * whitespace but preserves intra-paragraph newlines (rare in our scraper
 * output — RT and Finlex normalise to single-line via stripAndDecode — but
 * cheap to keep correct).
 */
function splitIntoParagraphs(text: string): string[] {
  return text
    .split(/\n\n+/)
    .map((p) => p.trim())
    .filter((p) => p.length > 0);
}

/**
 * Sentence-split a paragraph that is itself > maxChars. Then pack the
 * sentences into ≤ maxChars windows. If a single sentence is still bigger
 * than maxChars (truly degenerate input — a 28K-char run-on sentence), fall
 * back to a hard char-window split for that one sentence so we never throw.
 */
function splitGiantBlock(para: string, maxChars: number): string[] {
  const sentences = splitIntoSentences(para);
  const out: string[] = [];
  let buf = "";

  for (const sent of sentences) {
    if (sent.length > maxChars) {
      // Sentence itself is too big — emit current buf, then hard-window
      // this monster.
      if (buf.length > 0) {
        out.push(buf);
        buf = "";
      }
      for (const w of hardWindow(sent, maxChars)) out.push(w);
      continue;
    }
    if (buf.length === 0) {
      buf = sent;
    } else if (buf.length + 1 + sent.length <= maxChars) {
      buf = `${buf} ${sent}`;
    } else {
      out.push(buf);
      buf = sent;
    }
  }
  if (buf.length > 0) out.push(buf);
  return out;
}

/**
 * Split a paragraph into sentence-like units. We treat `. `, `! `, `? `,
 * `." `, `?» ` (Finnish/Estonian close-quote variants) and the end of string
 * as boundaries. This is intentionally simple — over-splitting is harmless
 * because the next pass repacks. Under-splitting just falls through to the
 * hardWindow fallback.
 */
function splitIntoSentences(para: string): string[] {
  // Regex captures end-of-sentence punctuation + trailing whitespace so the
  // boundary is included in the preceding sentence (avoids losing the
  // period/space when concatenating).
  const re = /[^.!?]+(?:[.!?]+[)"»”']*)?(?:\s+|$)/g;
  const out: string[] = [];
  let m: RegExpExecArray | null;
  while ((m = re.exec(para)) !== null) {
    const piece = m[0].trim();
    if (piece) out.push(piece);
  }
  if (out.length === 0) out.push(para);
  return out;
}

/**
 * Hard char-window split — last-resort fallback. Picks split points at
 * whitespace boundaries when possible to avoid mid-word cuts; falls back to
 * an exact char cut if no whitespace is found in the window.
 */
function hardWindow(text: string, maxChars: number): string[] {
  const out: string[] = [];
  let i = 0;
  while (i < text.length) {
    const end = Math.min(i + maxChars, text.length);
    if (end === text.length) {
      out.push(text.slice(i));
      break;
    }
    // Try to break at last whitespace inside [i, end). Search backward up to
    // 2KB from `end` — beyond that we just take the hard cut.
    const searchStart = Math.max(i + maxChars - 2048, i + 1);
    const slice = text.slice(searchStart, end);
    const wsIdx = slice.search(/\s\S*$/);
    let cut = end;
    if (wsIdx > 0) {
      cut = searchStart + wsIdx;
    }
    out.push(text.slice(i, cut).trim());
    i = cut;
  }
  return out.filter((s) => s.length > 0);
}
