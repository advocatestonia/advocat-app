// hudoc-fetcher/chunker.ts
// -----------------------------------------------------------------------------
// Paragraph-level chunker for ECtHR judgments served by HUDOC.
//
// HUDOC ships judgments as HTML with paragraph numbers in the canonical
// `<n>.` form ("1.", "2.", ...) at the start of paragraphs in THE LAW and
// THE FACTS sections. We chunk on paragraph boundaries so an in-text
// citation like `[[ref:Bouyid_v_Belgium:para-83]]` becomes resolvable.
//
// Headings we care about and what they classify chunks as:
//   "THE FACTS"            → facts
//   "THE LAW"              → ratio (the substantive reasoning)
//   "FOR THESE REASONS"    → dispositive  (the operative part)
//   anything else / pre    → obiter (default — we don't claim to know)
//
// We do NOT attempt to extract holdings or legal topics here; those come
// from a later enrichment pass. This module only:
//   * strips HTML to text
//   * detects section boundaries
//   * splits on `N.` paragraph heads
//   * tags each paragraph with its text_type
// -----------------------------------------------------------------------------

export interface HudocChunk {
  /** Paragraph number, e.g. "83" or null for pre-paragraph header text. */
  paragraph_no: string | null;
  /** Body text, plain, trimmed. */
  text: string;
  /** Classification of where in the judgment this chunk sits. */
  text_type: "facts" | "ratio" | "obiter" | "dispositive";
}

const SECTION_HEADERS = [
  { rx: /^THE FACTS\b/i, type: "facts" as const },
  { rx: /^I\.\s+(THE )?CIRCUMSTANCES OF THE CASE\b/i, type: "facts" as const },
  { rx: /^THE LAW\b/i, type: "ratio" as const },
  { rx: /^FOR THESE REASONS,?\s+THE COURT/i, type: "dispositive" as const },
];

/** Same HTML strip used by EUR-Lex, but kept local so the two functions
 *  can deploy independently without sharing a module that would need its
 *  own import alias under Deno. */
export function htmlToText(html: string): string {
  return html
    .replace(/<(script|style)[^>]*>[\s\S]*?<\/\1>/gi, " ")
    .replace(/<br\s*\/?>/gi, "\n")
    .replace(/<\/(p|div|h[1-6]|li|tr)>/gi, "\n")
    .replace(/<[^>]+>/g, " ")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&apos;/g, "'")
    // Numeric character refs — HUDOC's DOCX-to-HTML output emits
    // `&#xa0;` (non-breaking space) and similar instead of named entities.
    .replace(/&#x([0-9a-fA-F]+);/g, (_, h) => String.fromCodePoint(parseInt(h, 16)))
    .replace(/&#(\d+);/g, (_, d) => String.fromCodePoint(parseInt(d, 10)))
    .replace(/[ \t\u00a0]+/g, " ")
    .replace(/\n[ \t]+/g, "\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

// Paragraph head — same shape as EUR-Lex `N.` but ECtHR allows up to 4 digits.
const PARA_HEAD = /^(\d{1,4})\.\s+(\S)/;

/**
 * Detect a section header on a given line. Returns the new section type,
 * or null if the line is not a recognised header.
 */
export function detectSection(
  line: string,
): "facts" | "ratio" | "obiter" | "dispositive" | null {
  const trimmed = line.trim();
  for (const h of SECTION_HEADERS) {
    if (h.rx.test(trimmed)) return h.type;
  }
  return null;
}

/**
 * Chunk an ECtHR judgment HTML body into paragraph-keyed chunks.
 *
 * Default text_type is "obiter" because before "THE FACTS" we may have
 * procedural preamble (parties, composition, dates) that doesn't fit any
 * of our four buckets cleanly. "obiter" is the catch-all per the
 * case_chunks.text_type CHECK constraint, so we don't drop the text.
 *
 * Per-paragraph chunks are emitted in document order so the consumer
 * can keep paragraph numbers monotonic per (case_number, text_type).
 */
export function chunkHudocHtml(html: string): HudocChunk[] {
  const text = htmlToText(html);
  const lines = text.split("\n");

  const chunks: HudocChunk[] = [];
  let currentType: HudocChunk["text_type"] = "obiter";
  let buf: { para: string | null; text: string[] } = { para: null, text: [] };

  const flush = () => {
    if (buf.text.length === 0) return;
    const joined = buf.text.join("\n").trim();
    if (joined.length > 0) {
      chunks.push({
        paragraph_no: buf.para,
        text: joined,
        text_type: currentType,
      });
    }
    buf = { para: null, text: [] };
  };

  for (const rawLine of lines) {
    const line = rawLine.trim();
    if (!line) continue;

    // Section transition?
    const newSection = detectSection(line);
    if (newSection) {
      flush();
      currentType = newSection;
      // Don't emit the heading itself as a chunk — it adds no value
      // and would clutter the embedding pool.
      continue;
    }

    // Paragraph head?
    const m = line.match(PARA_HEAD);
    if (m) {
      flush();
      buf = { para: m[1], text: [line] };
    } else {
      buf.text.push(line);
    }
  }
  flush();

  return chunks;
}

/** Combine adjacent micro-chunks (no paragraph number, <40 chars) into the
 *  previous chunk. ECtHR judgments occasionally have orphan lines (a
 *  citation reference on its own line, a footnote marker) that would
 *  otherwise produce semantically empty embedding rows. */
export function mergeMicroChunks(chunks: HudocChunk[]): HudocChunk[] {
  const out: HudocChunk[] = [];
  for (const c of chunks) {
    const last = out[out.length - 1];
    if (
      last &&
      c.paragraph_no === null &&
      c.text.length < 40 &&
      last.text_type === c.text_type
    ) {
      last.text = `${last.text}\n${c.text}`;
      continue;
    }
    out.push({ ...c });
  }
  return out;
}
