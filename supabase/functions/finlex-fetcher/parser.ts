// Pure helpers for the finlex-fetcher edge function — extracted into a
// separate module so the Deno test suite can import them directly without
// reflecting source text through `new Function()`. Everything in this file
// is dependency-free and side-effect-free; it is safe to import from any
// context (tests, edge runtime, future Node-based backfill scripts).

export interface ActMeta {
  act_slug: string;       // "fi-hol"
  act_abbrev: string;     // "HOL"
  act_full_name: string;  // "Hallintolaki"
  act_number: string;     // "434/2003"
  lang: string;           // "fi"
  source_url: string;     // canonical Finlex URI for this act
}

export interface Section {
  num: string;          // "114" (without § suffix)
  chapter?: string;     // "8" if known
  heading: string;      // "Menetetyn määräajan palauttaminen"
  text: string;         // full paragraph text (joined subsections)
}

// ── Citation utilities — FI convention `HOL 114 §` ─────────────────────────
//
// Two forms exist in Finnish legal usage:
//   1. Chapter-less acts (HOL, TyösopimusL, …):    `HOL 114 §`
//   2. Chapter-structured acts (RL, OK, UlkL, …):  `RL 21:1 §` (= ch 21, § 1)
//
// Both end with § (§ AFTER number is the BINDING rule). We emit the
// chapter:section form whenever the section actually has a chapter, so
// downstream citation matchers don't have to special-case RL.

/** Canonical FI citation for one section. */
export function sectionLabel(
  abbrev: string,
  sectionNum: string,
  chapter?: string,
): string {
  const N = sectionNum.trim();
  if (chapter && chapter.length > 0) {
    return `${abbrev} ${chapter}:${N} §`;
  }
  return `${abbrev} ${N} §`;
}

/**
 * Alias variants for fuzzy lookup. For chapter-less acts: 6 variants. For
 * chapter-structured acts: same 6 variants on the chapter:section form plus
 * 3 extra variants that omit the chapter (users frequently cite just the
 * section number when context is clear).
 *
 * pattern_kind values come from the statute_aliases check constraint:
 *   - 'exact'              — verbatim match (the common case)
 *   - 'regex'              — regex pattern (unused here; reserved for ops)
 *   - 'common_misspelling' — known incorrect forms users still type
 *
 * Covers user typos and stylistic splits we have observed in our own DB
 * (memory: HAO_KHO_restoration_jurisdiction lesson shows users write both
 * "HOL § 114" and "§ 114 HOL" even though only the first is correct FI
 * convention — the reversed form is `common_misspelling`).
 */
export function aliasVariants(
  meta: ActMeta,
  sectionNum: string,
  chapter?: string,
): { alias: string; pattern_kind: string }[] {
  const N = sectionNum.trim();
  const A = meta.act_abbrev;
  const F = meta.act_full_name;
  const fullN = chapter && chapter.length > 0 ? `${chapter}:${N}` : N;

  const out: { alias: string; pattern_kind: string }[] = [
    { alias: `${A} ${fullN} §`, pattern_kind: "exact" },                  // canonical
    { alias: `${F} ${fullN} §`, pattern_kind: "exact" },                  // full name
    { alias: `${A} §${fullN}`, pattern_kind: "exact" },                   // compact
    { alias: `${F.toLowerCase()} ${fullN} §`, pattern_kind: "exact" },    // full lowercase
    { alias: `${A.toLowerCase()} ${fullN} §`, pattern_kind: "exact" },    // abbrev lowercase
    { alias: `§ ${fullN} ${A}`, pattern_kind: "common_misspelling" },     // reversed (FI users still write this)
  ];

  // Chapter-bearing extras: section-only forms so "RL 1 §" still routes to
  // the right row when the user forgets the chapter prefix. These are NOT
  // canonical — strictly speaking they're ambiguous — but we treat them as
  // `common_misspelling` so the lookup ranker can downrank them when an
  // explicit chapter is present in the query.
  if (chapter && chapter.length > 0) {
    out.push(
      { alias: `${A} ${N} §`, pattern_kind: "common_misspelling" },
      { alias: `${F} ${N} §`, pattern_kind: "common_misspelling" },
      { alias: `${A.toLowerCase()} ${N} §`, pattern_kind: "common_misspelling" },
    );
  }

  return out;
}

// ── AKN-LD3 XML parsing ────────────────────────────────────────────────────

/**
 * Strip XML tags and decode the small set of entities Finlex emits.
 * We intentionally do NOT pull in a full XML parser — the AKN-LD3 documents
 * are predictable enough that a tag-strip + text-collapse pipeline gives
 * usable Finnish legal text for embedding/citation.
 */
export function stripAndDecode(xml: string): string {
  return xml
    .replace(/<[^>]+>/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'")
    .replace(/&#(\d+);/g, (_, n) => String.fromCharCode(Number(n)))
    .replace(/\s+/g, " ")
    .trim();
}

/**
 * Walk an AKN-LD3 consolidated statute XML and yield one Section per
 * <section> element. Chapter context is tracked so the chapter field is
 * populated where the act is structured into chapters.
 *
 * Regex-based — adequate for Finlex's deterministic structure and avoids
 * dragging in deno-dom for one job. If Finlex ever changes their XML
 * schema, the parser tests in __tests__/finlex_fetcher_test.ts catch it.
 */
export function parseStatuteXml(xml: string): Section[] {
  const sections: Section[] = [];

  const chapterRe = /<chapter\b[^>]*>([\s\S]*?)<\/chapter>/g;
  const sectionRe = /<section\b[^>]*>([\s\S]*?)<\/section>/g;
  const numRe = /<num>([^<]+)<\/num>/;
  const headingRe = /<heading\b[^>]*>([\s\S]*?)<\/heading>/;

  /** Pull text out of a section block, ignoring num/heading. */
  function bodyText(sectionBlock: string): string {
    let s = sectionBlock;
    s = s.replace(/<num>[^<]*<\/num>/g, " ");
    s = s.replace(/<heading\b[^>]*>[\s\S]*?<\/heading>/g, " ");
    return stripAndDecode(s);
  }

  /** Parse a single <section> block into a Section. */
  function buildSection(block: string, chapterNum?: string): Section | null {
    const numM = numRe.exec(block);
    if (!numM) return null;
    const numRaw = numM[1].replace(/[§\s]/g, "").trim();
    if (!numRaw) return null;
    const sectionNumMatch = numM[1].match(/(\d+)\s*([a-zA-Z]?)/);
    const sectionNum = sectionNumMatch
      ? sectionNumMatch[2]
        ? `${sectionNumMatch[1]} ${sectionNumMatch[2].toLowerCase()}`
        : sectionNumMatch[1]
      : numRaw;
    const headingM = headingRe.exec(block);
    const heading = headingM ? stripAndDecode(headingM[1]) : "";
    const text = bodyText(block);
    if (!text || text.length < 5) return null;
    return {
      num: sectionNum,
      chapter: chapterNum,
      heading,
      text,
    };
  }

  const consumedRanges: Array<[number, number]> = [];

  let cm: RegExpExecArray | null;
  while ((cm = chapterRe.exec(xml)) !== null) {
    const inner = cm[1];
    const chapNumM = /<num>([^<]+)<\/num>/.exec(inner);
    const chapDigitsM = chapNumM ? chapNumM[1].match(/\d+/) : null;
    const chapterNum = chapDigitsM ? chapDigitsM[0] : undefined;
    const innerOffset = cm.index + cm[0].indexOf(inner);
    consumedRanges.push([innerOffset, innerOffset + inner.length]);

    let sm: RegExpExecArray | null;
    const localRe = /<section\b[^>]*>([\s\S]*?)<\/section>/g;
    while ((sm = localRe.exec(inner)) !== null) {
      const s = buildSection(sm[1], chapterNum);
      if (s) sections.push(s);
    }
  }

  // Catch any top-level <section> outside chapters (HOL has no chapters).
  let topSm: RegExpExecArray | null;
  while ((topSm = sectionRe.exec(xml)) !== null) {
    const start = topSm.index;
    const isInsideChapter = consumedRanges.some(
      ([lo, hi]) => start >= lo && start <= hi,
    );
    if (isInsideChapter) continue;
    const s = buildSection(topSm[1]);
    if (s) sections.push(s);
  }

  return sections;
}
