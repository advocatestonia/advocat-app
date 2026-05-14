// Tests for _shared/chunk_splitter.ts
//
// Run with:
//   deno test --allow-none supabase/functions/_shared/__tests__/chunk_splitter_test.ts

import { assertEquals, assert } from "https://deno.land/std@0.177.0/testing/asserts.ts";
import {
  MAX_CHARS,
  splitIfOversize,
  splitAllOversize,
  splitTextToParts,
} from "../chunk_splitter.ts";

Deno.test("splitIfOversize: undersized chunk returned unchanged", () => {
  const chunk = {
    text: "Lühike § tekst.",
    section_label: "TsÜS § 1",
    jurisdiction: "ee",
    act_slug: "ee-tsus",
  };
  const result = splitIfOversize(chunk);
  assertEquals(result.length, 1);
  // Same object identity — we never copy when no split is needed.
  assertEquals(result[0], chunk);
});

Deno.test("splitIfOversize: at-limit chunk returned unchanged", () => {
  const chunk = {
    text: "a".repeat(MAX_CHARS),
    section_label: "TsÜS § 2",
  };
  const result = splitIfOversize(chunk);
  assertEquals(result.length, 1);
  assertEquals(result[0].text.length, MAX_CHARS);
});

Deno.test("splitIfOversize: oversized paragraph-rich chunk gets split", () => {
  // 3 paragraphs of ~12_000 chars each → must split into >= 2 parts (each
  // paragraph fits but two together don't).
  const para = "Pikk lõik. ".repeat(1090); // ~12_000 chars
  const text = [para, para, para].join("\n\n");
  assert(text.length > MAX_CHARS);

  const chunk = {
    text,
    section_label: "TuMS § 61",
    jurisdiction: "ee",
    act_slug: "ee-tums",
    section: "61",
  };
  const parts = splitIfOversize(chunk);
  assert(parts.length >= 2, `expected >= 2 parts, got ${parts.length}`);

  // All parts under MAX_CHARS.
  for (const p of parts) {
    assert(p.text.length <= MAX_CHARS, `part ${p.section_label} length ${p.text.length} > ${MAX_CHARS}`);
  }

  // section_label decorated with osa N/M.
  for (let i = 0; i < parts.length; i++) {
    assertEquals(parts[i].section_label, `TuMS § 61 (osa ${i + 1}/${parts.length})`);
  }

  // Metadata preserved on each part.
  for (const p of parts) {
    assertEquals(p.jurisdiction, "ee");
    assertEquals(p.act_slug, "ee-tums");
    assertEquals(p.section, "61");
  }

  // Subsection is set per part.
  // (We don't enforce the exact format here; just that it's set.)
});

Deno.test("splitTextToParts: giant single paragraph falls back to sentence split", () => {
  // One paragraph, no \n\n breaks, 30K chars of well-formed sentences.
  const sentences: string[] = [];
  for (let i = 0; i < 600; i++) {
    sentences.push(`See on ${i}. lause Eesti keeles, mille pikkus on umbes viiskümmend märki.`);
  }
  const text = sentences.join(" "); // single paragraph
  assert(text.length > MAX_CHARS);

  const parts = splitTextToParts(text, MAX_CHARS);
  assert(parts.length >= 2);
  for (const p of parts) {
    assert(p.length <= MAX_CHARS, `part length ${p.length} > ${MAX_CHARS}`);
  }
  // No content loss: concatenated parts contain all sentences.
  const recombined = parts.join(" ");
  for (let i = 0; i < 600; i += 50) {
    assert(recombined.includes(`${i}. lause`), `lost sentence ${i}`);
  }
});

Deno.test("splitTextToParts: degenerate single mega-sentence falls back to hard window", () => {
  // 35K chars with no sentence boundaries.
  const text = "ä".repeat(35_000);
  const parts = splitTextToParts(text, MAX_CHARS);
  assert(parts.length >= 2);
  for (const p of parts) {
    assert(p.length <= MAX_CHARS);
  }
  // No content loss.
  assertEquals(parts.join("").length, 35_000);
});

Deno.test("splitTextToParts: no-op for empty / tiny text", () => {
  assertEquals(splitTextToParts("", MAX_CHARS), [""]);
  assertEquals(splitTextToParts("hi", MAX_CHARS), ["hi"]);
});

Deno.test("splitAllOversize: mixed batch handled row-by-row", () => {
  const big = "a".repeat(MAX_CHARS + 5_000);
  const small = "small";
  const rows = [
    { text: small, section_label: "A § 1" },
    { text: big, section_label: "B § 2" },
    { text: small, section_label: "C § 3" },
  ];
  const out = splitAllOversize(rows);
  // small + (>=2 parts of big) + small  → at least 4 rows
  assert(out.length >= 4);
  assertEquals(out[0].section_label, "A § 1");
  assert(out[out.length - 1].section_label === "C § 3");
});

Deno.test("splitIfOversize: subsection field populated for split parts", () => {
  // Build paragraph-rich text so paragraph split works.
  const para = "Pikk lõik. ".repeat(2000);
  const text = [para, para, para].join("\n\n");
  const chunk = { text, section_label: "X § 1", subsection: null };
  const parts = splitIfOversize(chunk);
  assert(parts.length >= 2);
  for (let i = 0; i < parts.length; i++) {
    assertEquals(
      (parts[i] as unknown as { subsection?: string | null }).subsection,
      `osa ${i + 1}/${parts.length}`,
    );
  }
});
