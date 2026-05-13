// finlex_akn_parser.ts
// -----------------------------------------------------------------------------
// Pure parsing logic extracted from scripts/scrape_finlex.ts so the Akoma
// Ntoso → structured-section pipeline is unit-testable without hitting
// Finlex.
//
// The script (scrape_finlex.ts) runs top-level fetch + write statements on
// import, which makes it unsuitable for `deno test`. This module is
// side-effect-free: it exports the parser primitives, the consumer wires
// them to network I/O.
//
// Phase 2 Pkg 1 — Finland corpus, 2026-05-11.
// -----------------------------------------------------------------------------

export interface ParsedSection {
  /** Chapter number from the enclosing <chapter> (e.g. "7" for "7 luku")
   *  or null when the act has no chapter structure. */
  chapterNum: string | null;
  /** Section number from <num> (e.g. "3" for "3 §"). */
  sectionNum: string;
  /** Heading text from <heading>, when present. */
  title: string | null;
  /** Concatenated body text: every <p> inside <content>, joined by blank
   *  lines, followed by any <subsection> contents. */
  body: string;
  /** Each <subsection> as a separate entry so the structure can be
   *  re-emitted in the corpus JSON (matches the FI shell convention). */
  subsections: Array<{ id: string; text: string }>;
}

/** Decode common XML entities (&amp; &lt; &gt; &quot; &apos; &#NNN; &#xHH;).
 *  Pure — no DOM, no allocations beyond the result string. */
export function decodeEntities(s: string): string {
  return s
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'")
    .replace(/&#(\d+);/g, (_m, n) => String.fromCharCode(parseInt(n, 10)))
    .replace(/&#x([0-9a-fA-F]+);/g, (_m, n) => String.fromCharCode(parseInt(n, 16)));
}

/** Strip all XML tags from a fragment, collapse whitespace, decode entities. */
export function stripTags(s: string): string {
  return decodeEntities(s.replace(/<[^>]*>/g, " "))
    .replace(/\s+/g, " ")
    .trim();
}

/** Extract the integer at the start of a "num" string like "7 luku" → "7"
 *  or "3 §" → "3". Returns null when no leading digit is present. */
export function leadingInt(s: string): string | null {
  const m = s.match(/^\s*(\d+)/);
  return m ? m[1] : null;
}

/** Parse the inner XML of one <section>...</section> element. Returns a
 *  [ParsedSection] or null when the element lacks the minimum required
 *  fields (a <num> with a leading digit and a non-empty body). */
export function parseSectionInner(
  inner: string,
  chapterNum: string | null,
): ParsedSection | null {
  // Extract <num> — required; without it we can't form an ID.
  const numMatch = inner.match(/<num>([\s\S]*?)<\/num>/);
  if (!numMatch) return null;
  const sectionNum = leadingInt(stripTags(numMatch[1]));
  if (!sectionNum) return null;

  // Optional <heading>
  const headingMatch = inner.match(/<heading>([\s\S]*?)<\/heading>/);
  const title = headingMatch ? stripTags(headingMatch[1]) : null;

  // <content> blocks — collect all <p> text inside.
  const bodyParts: string[] = [];
  const contentRe = /<content>([\s\S]*?)<\/content>/g;
  let cMatch: RegExpExecArray | null;
  while ((cMatch = contentRe.exec(inner)) !== null) {
    const contentInner = cMatch[1];
    const pRe = /<p\b[^>]*>([\s\S]*?)<\/p>/g;
    let pMatch: RegExpExecArray | null;
    while ((pMatch = pRe.exec(contentInner)) !== null) {
      const txt = stripTags(pMatch[1]);
      if (txt) bodyParts.push(txt);
    }
  }

  // <subsection num="1">...</subsection> at section level. Subsection
  // text is appended to the section body so the embedding gets the full
  // legal weight; the structured `subsections` array is also returned so
  // the corpus JSON can re-emit the structure.
  const subsections: Array<{ id: string; text: string }> = [];
  const subRe = /<subsection\b([^>]*)>([\s\S]*?)<\/subsection>/g;
  let sMatch: RegExpExecArray | null;
  while ((sMatch = subRe.exec(inner)) !== null) {
    const attrs = sMatch[1];
    const sInner = sMatch[2];
    const numAttr = attrs.match(/\bnum\s*=\s*"([^"]+)"/);
    const id = numAttr ? `(${numAttr[1]})` : `(?)`;
    const text = stripTags(sInner);
    if (text) {
      subsections.push({ id, text });
      bodyParts.push(text);
    }
  }

  const body = bodyParts.join("\n\n").trim();
  if (!body) return null;

  return { chapterNum, sectionNum, title, body, subsections };
}

/** Walk an Akoma Ntoso XML fragment and yield every <section>, paired with
 *  its enclosing chapter number when present. Older statutes that lack
 *  <chapter> wrappers are handled by a second pass that catches outer
 *  <section> elements with chapterNum=null.
 *
 *  Robust to:
 *    • Variant <chapter> attributes (the eId= attribute is ignored).
 *    • Sections without <heading>.
 *    • Sections without <subsection>.
 *    • Multi-paragraph <content> blocks (each <p> contributes one line).
 *
 *  Skips:
 *    • Sections without a <num> (can't form an ID).
 *    • Sections with empty body (no <p> text and no <subsection>).
 *
 *  Skipped sections do NOT throw — the caller can log + continue. */
export function findSections(xml: string): ParsedSection[] {
  const out: ParsedSection[] = [];

  // Step 1: locate every <chapter ...>...</chapter> span.
  const chapterRe = /<chapter\b[^>]*>([\s\S]*?)<\/chapter>/g;
  const seenSectionSpans = new Set<string>();

  let chMatch: RegExpExecArray | null;
  while ((chMatch = chapterRe.exec(xml)) !== null) {
    const chapterBody = chMatch[1];
    const chapterNumMatch = chapterBody.match(/<num>([\s\S]*?)<\/num>/);
    const chapterNumRaw = chapterNumMatch ? stripTags(chapterNumMatch[1]) : "";
    const chapterNum = leadingInt(chapterNumRaw);

    const sectionRe = /<section\b[^>]*>([\s\S]*?)<\/section>/g;
    let secMatch: RegExpExecArray | null;
    while ((secMatch = sectionRe.exec(chapterBody)) !== null) {
      const inner = secMatch[1];
      seenSectionSpans.add(secMatch[0]);
      const parsed = parseSectionInner(inner, chapterNum);
      if (parsed) out.push(parsed);
    }
  }

  // Step 2: outer (chapter-less) sections.
  const sectionRe2 = /<section\b[^>]*>([\s\S]*?)<\/section>/g;
  let outerMatch: RegExpExecArray | null;
  while ((outerMatch = sectionRe2.exec(xml)) !== null) {
    if (seenSectionSpans.has(outerMatch[0])) continue;
    const parsed = parseSectionInner(outerMatch[1], null);
    if (parsed) out.push(parsed);
  }

  return out;
}

/** Build the compound paragraph id used by `law_chunks.paragraph`:
 *    chapterNum = "7", sectionNum = "3" → "7-3"
 *    chapterNum = null, sectionNum = "26" → "26"
 *  Matches the Finnish corpus convention pinned in the design doc §6
 *  and the BARE_FINNISH_CITATION_PATTERN regex in citation_enforcement.ts. */
export function buildParagraphId(
  chapterNum: string | null,
  sectionNum: string,
): string {
  return chapterNum ? `${chapterNum}-${sectionNum}` : sectionNum;
}
