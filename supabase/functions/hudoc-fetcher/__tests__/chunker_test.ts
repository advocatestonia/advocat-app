// Deno tests for hudoc-fetcher/chunker.ts
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-read \
//     supabase/functions/hudoc-fetcher/__tests__/chunker_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  chunkHudocHtml,
  detectSection,
  htmlToText,
  mergeMicroChunks,
} from "../chunker.ts";

// =============================================================================
// htmlToText (mirror of EUR-Lex but tested separately because the two
// edge functions deploy independently)
// =============================================================================

Deno.test("HU-T01 — htmlToText strips tags and decodes entities", () => {
  const t = htmlToText("<p>Hello&nbsp;world&amp;more</p>");
  assert(t.includes("Hello world&more"));
});

Deno.test("HU-T02 — htmlToText decodes numeric character refs (HUDOC quirk)", () => {
  // HUDOC's docx-to-html conversion emits `&#xa0;` and similar instead
  // of named entities. If we don't decode them, embeddings see literal
  // "&#xa0;" tokens and quality degrades.
  const t = htmlToText("<p>83.&#xa0;&#xa0;The Court observed&#8230;</p>");
  assert(t.includes("83. The Court observed"));
  assert(!t.includes("&#x"));
  assert(!t.includes("&#8230"));
});

// =============================================================================
// detectSection — heading recognition
// =============================================================================

Deno.test("HU-T10 — detectSection 'THE FACTS' → facts", () => {
  assertEquals(detectSection("THE FACTS"), "facts");
});

Deno.test("HU-T11 — detectSection 'I. THE CIRCUMSTANCES OF THE CASE' → facts", () => {
  assertEquals(detectSection("I. THE CIRCUMSTANCES OF THE CASE"), "facts");
  assertEquals(detectSection("I. CIRCUMSTANCES OF THE CASE"), "facts");
});

Deno.test("HU-T12 — detectSection 'THE LAW' → ratio", () => {
  assertEquals(detectSection("THE LAW"), "ratio");
});

Deno.test("HU-T13 — detectSection 'FOR THESE REASONS, THE COURT...' → dispositive", () => {
  assertEquals(
    detectSection("FOR THESE REASONS, THE COURT, UNANIMOUSLY,"),
    "dispositive",
  );
  assertEquals(detectSection("FOR THESE REASONS THE COURT"), "dispositive");
});

Deno.test("HU-T14 — detectSection unknown heading → null", () => {
  assertEquals(detectSection("Random paragraph 5. about facts"), null);
  assertEquals(detectSection("II. ADMISSIBILITY"), null);
});

// =============================================================================
// chunkHudocHtml — end-to-end on synthetic HTML
// =============================================================================

const FAKE_JUDGMENT = `
<html><body>
<p>CASE OF BOUYID v. BELGIUM</p>
<p>(Application no. 23380/09)</p>
<p>JUDGMENT</p>
<p>STRASBOURG</p>
<p>28 September 2015</p>

<p>THE FACTS</p>
<p>I. THE CIRCUMSTANCES OF THE CASE</p>
<p>10. The applicants are two brothers, Mr Saïd Bouyid and Mr Mohamed Bouyid, who are Belgian nationals.</p>
<p>11. The first applicant alleges that on 8 December 2003, when he was 17, a police officer slapped him in the face during questioning.</p>
<p>12. The second applicant alleges similar treatment on 23 February 2004.</p>

<p>THE LAW</p>
<p>I. ALLEGED VIOLATION OF ARTICLE 3 OF THE CONVENTION</p>
<p>81. The applicants complained that they had been slapped by police officers and that the ensuing investigation had not been effective. They relied on Article 3 of the Convention.</p>
<p>82. The Court reiterates that Article 3 enshrines one of the most fundamental values of democratic societies.</p>
<p>83. In respect of a person who is deprived of liberty, or, more generally, is confronted with law-enforcement officers, any recourse to physical force which has not been made strictly necessary by the person's own conduct diminishes human dignity and is in principle an infringement of the right set forth in Article 3.</p>
<p>112. The Court therefore finds that there has been a violation of Article 3 of the Convention under its substantive and procedural limbs.</p>

<p>FOR THESE REASONS, THE COURT</p>
<p>1. Joins to the merits, unanimously, the Government's preliminary objection of non-exhaustion and dismisses it;</p>
<p>2. Holds, by fourteen votes to three, that there has been a violation of Article 3 of the Convention.</p>
</body></html>
`;

Deno.test("HU-T20 — chunkHudocHtml emits ≥6 chunks for fake Bouyid judgment", () => {
  const chunks = chunkHudocHtml(FAKE_JUDGMENT);
  assert(chunks.length >= 6, `expected ≥6 chunks, got ${chunks.length}`);
});

Deno.test("HU-T21 — chunkHudocHtml classifies §10-12 as facts", () => {
  const chunks = chunkHudocHtml(FAKE_JUDGMENT);
  const factParas = chunks.filter((c) =>
    c.text_type === "facts" && c.paragraph_no !== null
  );
  const nums = new Set(factParas.map((c) => c.paragraph_no));
  assert(nums.has("10"));
  assert(nums.has("11"));
  assert(nums.has("12"));
});

Deno.test("HU-T22 — chunkHudocHtml classifies §81-83 as ratio", () => {
  const chunks = chunkHudocHtml(FAKE_JUDGMENT);
  const ratio = chunks.filter((c) => c.text_type === "ratio");
  const nums = new Set(ratio.map((c) => c.paragraph_no));
  assert(nums.has("81"));
  assert(nums.has("82"));
  assert(nums.has("83"));
  assert(nums.has("112"));
});

Deno.test("HU-T23 — chunkHudocHtml classifies operative part as dispositive", () => {
  const chunks = chunkHudocHtml(FAKE_JUDGMENT);
  const disp = chunks.filter((c) => c.text_type === "dispositive");
  assert(disp.length >= 1, `expected ≥1 dispositive chunk, got ${disp.length}`);
});

Deno.test("HU-T24 — chunkHudocHtml does NOT emit section heading lines as chunks", () => {
  const chunks = chunkHudocHtml(FAKE_JUDGMENT);
  const headerEcho = chunks.find((c) =>
    c.text.trim() === "THE LAW" || c.text.trim() === "THE FACTS"
  );
  assertEquals(headerEcho, undefined);
});

Deno.test("HU-T25 — chunkHudocHtml preserves paragraph numbers as strings", () => {
  const chunks = chunkHudocHtml(FAKE_JUDGMENT);
  const para83 = chunks.find((c) => c.paragraph_no === "83");
  assert(para83);
  assert(para83.text.includes("strictly necessary"));
});

// =============================================================================
// mergeMicroChunks
// =============================================================================

Deno.test("HU-T30 — mergeMicroChunks folds tiny orphan lines into the previous chunk", () => {
  const input = [
    { paragraph_no: "1", text: "Long paragraph one with enough text to count.", text_type: "ratio" as const },
    { paragraph_no: null, text: "ibid.", text_type: "ratio" as const },
    { paragraph_no: "2", text: "Long paragraph two with enough text to count.", text_type: "ratio" as const },
  ];
  const out = mergeMicroChunks(input);
  assertEquals(out.length, 2);
  assert(out[0].text.includes("ibid"));
});

Deno.test("HU-T31 — mergeMicroChunks does not merge across section boundaries", () => {
  const input = [
    { paragraph_no: "1", text: "Big facts chunk one here.", text_type: "facts" as const },
    { paragraph_no: null, text: "foo.", text_type: "ratio" as const },     // different type
  ];
  const out = mergeMicroChunks(input);
  assertEquals(out.length, 2);
});

Deno.test("HU-T32 — mergeMicroChunks preserves real-length orphan chunks", () => {
  const input = [
    { paragraph_no: "1", text: "Short.", text_type: "ratio" as const },
    {
      paragraph_no: null,
      text:
        "This is a long orphan chunk with more than forty characters of content.",
      text_type: "ratio" as const,
    },
  ];
  const out = mergeMicroChunks(input);
  assertEquals(out.length, 2);
});
