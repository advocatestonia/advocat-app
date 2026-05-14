// he-fetcher — Deno tests for the pure pieces (parser, normaliser, helpers,
// seed catalogue invariants). Run with:
//   deno test --allow-read --allow-env \
//     supabase/functions/he-fetcher/__tests__/he_fetcher_test.ts
//
// HTTP / Sonnet / OpenAI calls are NOT covered here — they need network
// + secrets. A future integration test should exercise ?mode=seed and
// ?mode=status against a staging Supabase project.
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertFalse,
  assertNotEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  type ExtractedTravauxChunk,
  HE_FETCHER_MAX_INPUT_CHARS,
  HE_FETCHER_MAX_TOKENS,
  HE_FETCHER_MODEL,
  HE_FETCHER_SYSTEM_PROMPT,
  HE_FETCHER_TIMEOUT_MS,
  normaliseSectionRef,
  parseTravauxOutput,
} from "../extractor_prompt.ts";
import { ALL_SEEDS, EE_EELNOU_SEEDS, FI_HE_SEEDS } from "../seed.ts";
import { htmlToText } from "../fetch_source.ts";
import { clampInt, parseCountRange, seedFromPayload } from "../index.ts";

// =============================================================================
// 1. Model + budget pins
// =============================================================================
Deno.test("HEF-T01 — model is Sonnet (consilium requirement, not Haiku)", () => {
  assert(HE_FETCHER_MODEL.includes("sonnet"));
});

Deno.test("HEF-T02 — timeout is within 10s..120s", () => {
  assert(HE_FETCHER_TIMEOUT_MS >= 10_000);
  assert(HE_FETCHER_TIMEOUT_MS <= 120_000);
});

Deno.test("HEF-T03 — max tokens leaves headroom but bounds cost", () => {
  // 8K is enough for ~30 §§ × 1.5K each, well under the $5 budget.
  assert(HE_FETCHER_MAX_TOKENS >= 4_000);
  assert(HE_FETCHER_MAX_TOKENS <= 16_000);
});

Deno.test("HEF-T04 — system prompt mentions JSON array format", () => {
  assert(
    HE_FETCHER_SYSTEM_PROMPT.toLowerCase().includes("json array"),
    "system prompt must instruct strict JSON output",
  );
  assert(
    HE_FETCHER_SYSTEM_PROMPT.includes("section_ref"),
    "system prompt must name the section_ref field",
  );
});

Deno.test("HEF-T05 — input cap keeps prompt below Sonnet context", () => {
  // 350K chars ≈ 87K tokens, well under Sonnet's 200K context.
  assert(HE_FETCHER_MAX_INPUT_CHARS >= 100_000);
  assert(HE_FETCHER_MAX_INPUT_CHARS <= 500_000);
});

// =============================================================================
// 2. parseTravauxOutput — defensive parsing
// =============================================================================
Deno.test("HEF-P01 — parses canonical Sonnet output", () => {
  const raw = `[
    { "section_ref": "114", "text": "${"x".repeat(60)}" },
    { "section_ref": "114.1", "text": "${"y".repeat(60)}" }
  ]`;
  const out = parseTravauxOutput(raw);
  assertEquals(out.length, 2);
  assertEquals(out[0].section_ref, "114");
  assertEquals(out[1].section_ref, "114.1");
});

Deno.test("HEF-P02 — strips ```json fences Sonnet sometimes emits", () => {
  const raw = '```json\n[{"section_ref":"114","text":"' + "x".repeat(60) +
    '"}]\n```';
  const out = parseTravauxOutput(raw);
  assertEquals(out.length, 1);
  assertEquals(out[0].section_ref, "114");
});

Deno.test("HEF-P03 — drops chunks shorter than 50 chars", () => {
  const raw = `[
    { "section_ref": "114", "text": "too short" },
    { "section_ref": "115", "text": "${"y".repeat(100)}" }
  ]`;
  const out = parseTravauxOutput(raw);
  assertEquals(out.length, 1);
  assertEquals(out[0].section_ref, "115");
});

Deno.test("HEF-P04 — null section_ref preserved", () => {
  const raw = `[{ "section_ref": null, "text": "${"z".repeat(60)}" }]`;
  const out = parseTravauxOutput(raw);
  assertEquals(out.length, 1);
  assertEquals(out[0].section_ref, null);
});

Deno.test("HEF-P05 — malformed JSON returns []", () => {
  assertEquals(parseTravauxOutput("not json").length, 0);
  assertEquals(parseTravauxOutput("").length, 0);
  assertEquals(parseTravauxOutput("{not an array}").length, 0);
});

Deno.test("HEF-P06 — non-array top-level returns []", () => {
  assertEquals(
    parseTravauxOutput('{"section_ref":"114","text":"abc"}').length,
    0,
  );
});

// =============================================================================
// 3. normaliseSectionRef
// =============================================================================
Deno.test("HEF-N01 — strips § sign", () => {
  assertEquals(normaliseSectionRef("114 §"), "114");
  assertEquals(normaliseSectionRef("§ 114"), "114");
});

Deno.test("HEF-N02 — strips 'vp' suffix from HE refs", () => {
  assertEquals(normaliseSectionRef("114 vp"), "114");
});

Deno.test("HEF-N03 — preserves subsection notation", () => {
  assertEquals(normaliseSectionRef("114.1"), "114.1");
  assertEquals(normaliseSectionRef("12 a"), "12 a");
});

Deno.test("HEF-N04 — empty / whitespace returns null", () => {
  assertEquals(normaliseSectionRef(""), null);
  assertEquals(normaliseSectionRef("   "), null);
  assertEquals(normaliseSectionRef("§"), null);
});

Deno.test("HEF-N05 — caps absurd lengths at 40 chars", () => {
  const result = normaliseSectionRef("a".repeat(200));
  assert(result !== null);
  assert(result!.length <= 40);
});

// =============================================================================
// 4. Seed catalogue invariants
// =============================================================================
Deno.test("HEF-S01 — exactly 15 FI HE seeds (consilium spec)", () => {
  assertEquals(FI_HE_SEEDS.length, 15);
});

Deno.test("HEF-S02 — exactly 15 EE eelnõu seeds (consilium spec)", () => {
  assertEquals(EE_EELNOU_SEEDS.length, 15);
});

Deno.test("HEF-S03 — combined catalogue is 30 docs", () => {
  assertEquals(ALL_SEEDS.length, 30);
});

Deno.test("HEF-S04 — all source_ids unique (PK constraint relies on this)", () => {
  const seen = new Set<string>();
  for (const s of ALL_SEEDS) {
    assertFalse(seen.has(s.source_id), `duplicate source_id: ${s.source_id}`);
    seen.add(s.source_id);
  }
});

Deno.test("HEF-S05 — every FI seed has doc_kind=HE and jurisdiction=fi", () => {
  for (const s of FI_HE_SEEDS) {
    assertEquals(s.doc_kind, "HE");
    assertEquals(s.jurisdiction, "fi");
    assert(s.url.includes("eduskunta.fi"), `FI seed url: ${s.url}`);
  }
});

Deno.test("HEF-S06 — every EE seed is eelnõu/seletuskiri and jurisdiction=ee", () => {
  for (const s of EE_EELNOU_SEEDS) {
    assert(
      s.doc_kind === "eelnõu" || s.doc_kind === "seletuskiri",
      `unexpected doc_kind: ${s.doc_kind}`,
    );
    assertEquals(s.jurisdiction, "ee");
    assert(s.url.includes("riigikogu.ee"), `EE seed url: ${s.url}`);
  }
});

Deno.test("HEF-S07 — HOL §114 covered by HE 217/1995 vp (Sulga case)", () => {
  // The Legal Architect's spot-check is exactly this row.
  const holSeed = FI_HE_SEEDS.find((s) =>
    s.related_act_slug === "fi-hol" && s.doc_number.includes("217/1995")
  );
  assert(
    holSeed,
    "HOL must have a seed for HE 217/1995 vp — required for KHO §114 spot-check",
  );
  assertEquals(holSeed!.year, 1995);
});

Deno.test("HEF-S08 — act_slug values look like 'jurisdiction-statute'", () => {
  // Loose sanity check — catches typos like 'fi_hol' vs 'fi-hol'.
  for (const s of ALL_SEEDS) {
    const m = /^[a-z]{2}-[a-z0-9-]+$/.test(s.related_act_slug);
    assert(m, `bad act_slug: ${s.related_act_slug} (${s.source_id})`);
  }
});

Deno.test("HEF-S09 — year is plausible (1970..2030)", () => {
  // Vahingonkorvauslaki's original HE is from 1973 — widest realistic floor.
  for (const s of ALL_SEEDS) {
    assert(s.year >= 1970 && s.year <= 2030, `bad year: ${s.year}`);
  }
});

// =============================================================================
// 5. seedFromPayload — defensive payload reconstruction
// =============================================================================
Deno.test("HEF-PL01 — happy path reconstructs seed", () => {
  const seed = seedFromPayload(
    {
      id: "j1",
      source: "he",
      source_id: "fi-he-217-1995",
      target_table: "travaux",
      payload: null,
    },
    {
      url: "https://x",
      doc_kind: "HE",
      doc_number: "HE 217/1995 vp",
      title: "Hallintolainkäyttö",
      year: 1995,
      jurisdiction: "fi",
      related_act_slug: "fi-hol",
    },
  );
  assert(seed);
  assertEquals(seed!.doc_number, "HE 217/1995 vp");
});

Deno.test("HEF-PL02 — missing url returns null", () => {
  const seed = seedFromPayload(
    {
      id: "j1",
      source: "he",
      source_id: "x",
      target_table: "travaux",
      payload: null,
    },
    {
      doc_kind: "HE",
      doc_number: "HE 1/1995",
      jurisdiction: "fi",
      related_act_slug: "fi-hol",
    },
  );
  assertEquals(seed, null);
});

Deno.test("HEF-PL03 — invalid jurisdiction returns null", () => {
  const seed = seedFromPayload(
    {
      id: "j1",
      source: "he",
      source_id: "x",
      target_table: "travaux",
      payload: null,
    },
    {
      url: "https://x",
      doc_kind: "HE",
      doc_number: "x",
      jurisdiction: "us",
      related_act_slug: "fi-hol",
    },
  );
  assertEquals(seed, null);
});

Deno.test("HEF-PL04 — invalid doc_kind returns null", () => {
  const seed = seedFromPayload(
    {
      id: "j1",
      source: "he",
      source_id: "x",
      target_table: "travaux",
      payload: null,
    },
    {
      url: "https://x",
      doc_kind: "bogus",
      doc_number: "x",
      jurisdiction: "fi",
      related_act_slug: "fi-hol",
    },
  );
  assertEquals(seed, null);
});

// =============================================================================
// 6. clampInt
// =============================================================================
Deno.test("HEF-C01 — clampInt — null uses fallback", () => {
  assertEquals(clampInt(null, 1, 10, 3), 3);
});

Deno.test("HEF-C02 — clampInt — out-of-range clamps", () => {
  assertEquals(clampInt("0", 1, 10, 3), 1);
  assertEquals(clampInt("999", 1, 10, 3), 10);
});

Deno.test("HEF-C03 — clampInt — non-numeric falls back", () => {
  assertEquals(clampInt("xyz", 1, 10, 3), 3);
});

Deno.test("HEF-C04 — clampInt — happy path", () => {
  assertEquals(clampInt("5", 1, 10, 3), 5);
});

Deno.test("HEF-C05 — parseCountRange — canonical PostgREST shape", () => {
  assertEquals(parseCountRange("0-9/42"), 42);
  assertEquals(parseCountRange("*/0"), 0);
});

Deno.test("HEF-C06 — parseCountRange — null / malformed → 0", () => {
  assertEquals(parseCountRange(null), 0);
  assertEquals(parseCountRange("garbage"), 0);
  assertEquals(parseCountRange("0-9/"), 0);
});

// =============================================================================
// 7. htmlToText — Riigikogu eelnõu page sanity
// =============================================================================
Deno.test("HEF-H01 — strips script + style", () => {
  const html = "<p>kept</p><script>alert(1)</script><style>p{}</style>";
  const txt = htmlToText(html);
  assert(txt.includes("kept"));
  assertFalse(txt.includes("alert"));
  assertFalse(txt.includes("p{"));
});

Deno.test("HEF-H02 — decodes common entities", () => {
  const html = "<p>&nbsp;§&nbsp;114 &amp; §115</p>";
  const txt = htmlToText(html);
  assert(txt.includes("§ 114"));
  assert(txt.includes("&"));
});

Deno.test("HEF-H03 — preserves Estonian diacritics", () => {
  const html =
    "<p>§ 11. Eelnõu sisu ja võrdlev analüüs põhiseaduse alusel.</p>";
  const txt = htmlToText(html);
  assert(txt.includes("Eelnõu"));
  assert(txt.includes("võrdlev"));
  assert(txt.includes("analüüs"));
  assert(txt.includes("põhiseaduse"));
});

Deno.test("HEF-H04 — preserves Finnish diacritics", () => {
  const html =
    "<div>HE 217/1995 vp koskee menetetyn määräajan palauttamista hallintoasioissa.</div>";
  const txt = htmlToText(html);
  assert(txt.includes("määräajan"));
  assert(txt.includes("palauttamista"));
  assert(txt.includes("hallintoasioissa"));
});

Deno.test("HEF-H05 — block tags become newlines", () => {
  const html = "<p>a</p><p>b</p><p>c</p>";
  const txt = htmlToText(html);
  assert(txt.split(/\n/).filter((l) => l.trim().length > 0).length === 3);
});

// =============================================================================
// 8. ExtractedTravauxChunk type smoke (compile-time, but assert at runtime)
// =============================================================================
Deno.test("HEF-X01 — ExtractedTravauxChunk shape", () => {
  const chunk: ExtractedTravauxChunk = {
    section_ref: "114",
    text: "x".repeat(200),
  };
  assertEquals(typeof chunk.section_ref, "string");
  assertEquals(typeof chunk.text, "string");
  // Round-trip through parser → still recognisable as ExtractedTravauxChunk.
  const json = JSON.stringify([chunk]);
  const parsed = parseTravauxOutput(json);
  assertEquals(parsed.length, 1);
  assertEquals(parsed[0].section_ref, "114");
  assertNotEquals(parsed[0].text.length, 0);
});
