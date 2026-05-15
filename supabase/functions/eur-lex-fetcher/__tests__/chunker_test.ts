// Deno tests for eur-lex-fetcher/chunker.ts
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-read \
//     supabase/functions/eur-lex-fetcher/__tests__/chunker_test.ts
//
// Pure-function tests for the article-level chunker. The HTTP layer
// (fetcher.ts) is exercised in isolation by fetcher_test.ts.
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  buildLabel,
  chunkEurLexHtml,
  htmlToText,
  matchArticleHead,
  splitArticleIntoParagraphs,
} from "../chunker.ts";

// =============================================================================
// 1. htmlToText
// =============================================================================

Deno.test("EL-T01 — htmlToText strips tags and decodes entities", () => {
  const html = "<p>Hello&nbsp;<b>world</b> &amp; goodbye</p>";
  const text = htmlToText(html);
  assert(text.includes("Hello world"));
  assert(text.includes("& goodbye"));
  assert(!text.includes("<"));
});

Deno.test("EL-T02 — htmlToText drops <script>/<style> blocks wholesale", () => {
  const html = "<p>before</p><script>alert('x')</script><style>p{}</style><p>after</p>";
  const text = htmlToText(html);
  assert(text.includes("before"));
  assert(text.includes("after"));
  assert(!text.includes("alert"));
  assert(!text.includes("p{}"));
});

Deno.test("EL-T03 — htmlToText preserves paragraph boundaries via newlines", () => {
  const html = "<p>line one</p><p>line two</p>";
  const text = htmlToText(html);
  const lines = text.split("\n").map((l) => l.trim()).filter(Boolean);
  assertEquals(lines.length, 2);
  assertEquals(lines[0], "line one");
  assertEquals(lines[1], "line two");
});

// =============================================================================
// 2. matchArticleHead — multilingual
// =============================================================================

Deno.test("EL-T10 — matchArticleHead recognises 'Article 7' (EN)", () => {
  assertEquals(matchArticleHead("Article 7", "en"), "7");
  assertEquals(matchArticleHead("  Article 12  ", "en"), "12");
});

Deno.test("EL-T11 — matchArticleHead recognises 'Article 7a' (suffix)", () => {
  assertEquals(matchArticleHead("Article 7a", "en"), "7a");
});

Deno.test("EL-T12 — matchArticleHead recognises '7 artikla' (FI primary form)", () => {
  assertEquals(matchArticleHead("7 artikla", "fi"), "7");
  assertEquals(matchArticleHead("12 artikla", "fi"), "12");
});

Deno.test("EL-T13 — matchArticleHead recognises 'Artikla 7' (FI fallback form)", () => {
  assertEquals(matchArticleHead("Artikla 7", "fi"), "7");
});

Deno.test("EL-T14 — matchArticleHead recognises 'Artikkel 7' (ET)", () => {
  assertEquals(matchArticleHead("Artikkel 7", "et"), "7");
  assertEquals(matchArticleHead("Artikkel 12a", "et"), "12a");
});

Deno.test("EL-T15 — matchArticleHead rejects non-heading lines", () => {
  assertEquals(matchArticleHead("This is article 7 of the constitution", "en"), null);
  assertEquals(matchArticleHead("Annex II", "en"), null);
  assertEquals(matchArticleHead("Recital 23", "en"), null);
});

Deno.test("EL-T16 — matchArticleHead is case-insensitive on the keyword", () => {
  assertEquals(matchArticleHead("ARTICLE 5", "en"), "5");
  assertEquals(matchArticleHead("artikkel 5", "et"), "5");
});

// =============================================================================
// 3. buildLabel
// =============================================================================

Deno.test("EL-T20 — buildLabel produces correct citation in each language", () => {
  assertEquals(buildLabel("7", "en"), "Article 7");
  assertEquals(buildLabel("7", "fi"), "7 artikla");
  assertEquals(buildLabel("7", "et"), "Artikkel 7");
});

// =============================================================================
// 4. splitArticleIntoParagraphs
// =============================================================================

Deno.test("EL-T30 — splitArticleIntoParagraphs splits on numbered heads", () => {
  const body = `Right of residence for up to three months.
1. Union citizens shall have the right of residence...
2. Paragraph 1 shall also apply to family members...
3. By way of derogation from paragraphs 1 and 2...`;
  const paras = splitArticleIntoParagraphs(body);
  // First chunk is the heading line (no paragraph number).
  assertEquals(paras.length, 4);
  assertEquals(paras[1].subsection, "1");
  assertEquals(paras[2].subsection, "2");
  assertEquals(paras[3].subsection, "3");
});

Deno.test("EL-T31 — splitArticleIntoParagraphs returns 1 chunk when no paragraph numbers", () => {
  const body = `Single-paragraph article — no numbered subsections here.`;
  const paras = splitArticleIntoParagraphs(body);
  assertEquals(paras.length, 1);
  assertEquals(paras[0].subsection, null);
});

Deno.test("EL-T32 — splitArticleIntoParagraphs does not split on '7.' inside sentence", () => {
  // Period followed by no space, or by lowercase letter → not a heading.
  const body = `See Article 7.1 for details and Article 7.2 below.`;
  const paras = splitArticleIntoParagraphs(body);
  assertEquals(paras.length, 1);
});

// =============================================================================
// 5. chunkEurLexHtml — end-to-end on synthetic HTML
// =============================================================================

const FAKE_DIR_EN = `
<html><body>
<p>Some preamble text. The European Parliament and the Council...</p>
<p>Whereas...</p>
<h3>Article 1</h3>
<p>1. This Directive lays down the conditions governing the exercise...</p>
<p>2. It also lays down the limits...</p>
<h3>Article 2</h3>
<p>For the purposes of this Directive, "Union citizen" means any person...</p>
<h3>Article 3</h3>
<p>1. This Directive shall apply to all Union citizens...</p>
<p>2. Without prejudice to any right to free movement...</p>
<p>3. The host Member State shall, in accordance...</p>
</body></html>
`;

Deno.test("EL-T40 — chunkEurLexHtml produces ≥3 article chunks (EN)", () => {
  const chunks = chunkEurLexHtml(FAKE_DIR_EN, "en");
  const articleChunks = chunks.filter((c) => c.section.startsWith("art-"));
  // 3 articles → ≥3 chunks (paragraph splits may produce more)
  assert(articleChunks.length >= 3, `expected ≥3 articles, got ${articleChunks.length}`);
});

Deno.test("EL-T41 — chunkEurLexHtml emits article labels in the requested language", () => {
  const en = chunkEurLexHtml(FAKE_DIR_EN, "en");
  const labels = new Set(en.filter((c) => c.section.startsWith("art-")).map((c) => c.section_label));
  assert(labels.has("Article 1"));
  assert(labels.has("Article 2"));
  assert(labels.has("Article 3"));
});

Deno.test("EL-T42 — chunkEurLexHtml splits Article 1 into 2 paragraph chunks", () => {
  const chunks = chunkEurLexHtml(FAKE_DIR_EN, "en");
  const art1 = chunks.filter((c) => c.section.startsWith("art-1"));
  // Article 1 has "1." and "2." subparagraphs
  assert(art1.length >= 2, `expected ≥2 paragraphs in Article 1, got ${art1.length}`);
  const subsections = art1.map((c) => c.subsection).filter(Boolean);
  assert(subsections.includes("1"));
  assert(subsections.includes("2"));
});

Deno.test("EL-T43 — chunkEurLexHtml emits Article 2 as single chunk (no numbered paragraphs)", () => {
  const chunks = chunkEurLexHtml(FAKE_DIR_EN, "en");
  const art2 = chunks.filter((c) => c.section.startsWith("art-2"));
  // Article 2 body has no "1." / "2." → one chunk
  assertEquals(art2.length, 1);
  assertEquals(art2[0].subsection, null);
});

Deno.test("EL-T44 — chunkEurLexHtml preserves preamble when ≥80 chars", () => {
  const chunks = chunkEurLexHtml(FAKE_DIR_EN, "en");
  const preamble = chunks.filter((c) => c.section === "preamble");
  assertEquals(preamble.length, 1);
  assert(preamble[0].text.includes("European Parliament"));
});

Deno.test("EL-T45 — chunkEurLexHtml works in Finnish with FI headings", () => {
  const fakeFi = FAKE_DIR_EN
    .replace(/Article 1/g, "1 artikla")
    .replace(/Article 2/g, "2 artikla")
    .replace(/Article 3/g, "3 artikla");
  const chunks = chunkEurLexHtml(fakeFi, "fi");
  const articleChunks = chunks.filter((c) => c.section.startsWith("art-"));
  assert(articleChunks.length >= 3);
  const labels = new Set(articleChunks.map((c) => c.section_label));
  assert(labels.has("1 artikla"));
});

Deno.test("EL-T46 — chunkEurLexHtml works in Estonian with ET headings", () => {
  const fakeEt = FAKE_DIR_EN
    .replace(/Article 1/g, "Artikkel 1")
    .replace(/Article 2/g, "Artikkel 2")
    .replace(/Article 3/g, "Artikkel 3");
  const chunks = chunkEurLexHtml(fakeEt, "et");
  const articleChunks = chunks.filter((c) => c.section.startsWith("art-"));
  assert(articleChunks.length >= 3);
  const labels = new Set(articleChunks.map((c) => c.section_label));
  assert(labels.has("Artikkel 1"));
});
