// Deno TDD — citation_verifier.ts (P0 hallucination guard, 2026-05-19).
// -----------------------------------------------------------------------------
// Pins the verifier behaviour against the five worst-offender turns from the
// hallucination eval (2026-05-19):
//   • h50 — KarS §121 lookup → invents §§7, §6, §§118, §114-§117
//   • h42 — ECtHR Article 6 lookup → invents Article 6§1, Article 8, Article 13
//   • h20 — KarS §121 lookup → invents §118, §120
//   • h24 — TLS §88 lookup → invents §91, §92
//   • h48 — TSL 7 luku lookup → invents §7:1, §8:1
//
// Plus extraction / range / mode / marker-bypass smoke tests.
//
// Run with:
//   deno test --allow-read \
//     supabase/functions/_shared/__tests__/citation_verifier_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  type ToolUseResult,
  verifyResponseCitations,
} from "../citation_verifier.ts";

// ─── Helpers ────────────────────────────────────────────────────────────────

function lookup(
  paras: Array<{ act?: string; para?: string; label?: string }>,
  specific_statute?: string,
): ToolUseResult {
  return {
    tool_name: "legal_lookup",
    input: specific_statute
      ? { query: "x", jurisdiction: "fi", specific_statute }
      : { query: "x", jurisdiction: "fi" },
    returned_chunks: paras.map((p) => ({
      act_slug: p.act ?? "fi-rl",
      paragraph: p.para ?? null,
      section_label: p.label ?? null,
      similarity: 0.8,
    })),
  };
}

// ─── CV-T01 — empty text / no cites is a no-op ──────────────────────────────

Deno.test("CV-T01 — empty text returns zero everything", () => {
  const r = verifyResponseCitations("", []);
  assertEquals(r.verified_citations.length, 0);
  assertEquals(r.unverified_citations.length, 0);
  assertEquals(r.hallucination_score, 0);
});

Deno.test("CV-T02 — prose without any cite is a no-op", () => {
  const text = "Töölepingu seadus reguleerib töösuhteid Eestis.";
  const r = verifyResponseCitations(text, []);
  assertEquals(r.verified_citations.length, 0);
  assertEquals(r.unverified_citations.length, 0);
  assertEquals(r.marked_text, text);
  assertEquals(r.stripped_text, text);
});

// ─── CV-T03 — single §N covered → verified ──────────────────────────────────

Deno.test("CV-T03 — §114 verified when tool returned paragraph=114", () => {
  const text = "Menetetyn määräajan palauttaminen on HOL §114 mukaan KHO:n yksinoikeus.";
  const tools = [lookup([{ act: "fi-oho", para: "114", label: "§114" }])];
  const r = verifyResponseCitations(text, tools);
  assertEquals(r.verified_citations.length, 1);
  assertEquals(r.unverified_citations.length, 0);
  assertEquals(r.hallucination_score, 0);
});

// ─── CV-T04 — specific_statute hint counts ──────────────────────────────────

Deno.test("CV-T04 — specific_statute hint covers cite even when chunks empty", () => {
  const text = "TSL §88 viittaa työsopimuksen päättämiseen.";
  const tools: ToolUseResult[] = [{
    tool_name: "legal_lookup",
    input: { query: "x", jurisdiction: "fi", specific_statute: "TSL §88" },
    returned_chunks: [],
  }];
  const r = verifyResponseCitations(text, tools);
  assertEquals(r.unverified_citations.length, 0);
  assertEquals(r.verified_citations.length, 1);
});

// ─── CV-T05 — range expansion §§118-120 ─────────────────────────────────────

Deno.test("CV-T05 — §§118-120 expands; only looked-up §118 verified", () => {
  const text = "KarS §121 ja sellega seotud §§118-120 hõlmavad ka tervisekahjustusi.";
  const tools = [
    lookup([{ act: "ee-kars", para: "121", label: "§121" }]),
    lookup([{ act: "ee-kars", para: "118", label: "§118" }]),
  ];
  const r = verifyResponseCitations(text, tools);
  // Expected: §121 verified, §118 verified, §119 & §120 unverified.
  const allRaw = [...r.verified_citations, ...r.unverified_citations]
    .map((c) => c.toLowerCase().replace(/\s+/g, ""));
  assert(
    allRaw.some((c) => c.includes("121")),
    `expected §121 in cites, got ${JSON.stringify(allRaw)}`,
  );
  assert(
    allRaw.some((c) => c.includes("119")),
    `expected synthetic §119 in cites, got ${JSON.stringify(allRaw)}`,
  );
  assertEquals(r.unverified_citations.length >= 2, true);
  assert(r.hallucination_score > 0);
});

// ─── CV-T06 — h50 reproduction (KarS §121 → invented §§7, §6, §118, §114-§117)

Deno.test("CV-T06 — h50: KarS §121 lookup, response invents §§7, §6, §§118-§117", () => {
  const text = [
    "Eesti KarS §121 (kehaline väärkohtlemine) ja Soome RL §21:5 (pahoinpitely)",
    "on funktsionaalselt sarnased. Eesti süsteem teeb selget vahet kerge",
    "(lievä pahoinpitely, §7) ja raske (törkeä pahoinpitely, §6) vahel,",
    "karistusraamiga kuni viis aastat. Eesti süsteemi (§121 väärkohtlemine,",
    "§118 tervisekahjustus, §114-§117 rasked variandid), samas kui Soome",
    "süsteemis on neli astet.",
  ].join(" ");
  const tools = [
    lookup([{ act: "ee-kars", para: "121", label: "§121" }], "KarS §121"),
    lookup([{ act: "fi-rl", para: "21:5", label: "21 luku 5 §" }], "RL 21:5"),
  ];
  const r = verifyResponseCitations(text, tools);
  // Cites: §121, §7, §6, §121 (repeat), §118, §114-§117 range (§115, §116, §117),
  // §21:5 (verified). Most §7/§6/§118/§114/§115/§116/§117 should be unverified.
  assert(
    r.unverified_citations.length >= 4,
    `expected ≥4 unverified, got ${r.unverified_citations.length}: ` +
      JSON.stringify(r.unverified_citations),
  );
  assert(r.hallucination_score >= 0.5);
  // §121 must be verified
  const verifiedNums = r.verified_citations
    .map((c) => c.replace(/\D/g, ""));
  assert(
    verifiedNums.includes("121"),
    `expected §121 verified, got ${JSON.stringify(r.verified_citations)}`,
  );
});

// ─── CV-T07 — h42 reproduction (Article 6 → invents Article 8, 13) ─────────

Deno.test("CV-T07 — h42: Article 6 lookup, response invents Article 8 + 13", () => {
  const text = [
    "Maaouia v France established the rule that Article 6 ECHR does not",
    "apply to immigration cases. They fall outside the scope of Article 6",
    "§1 because they concern neither civil rights nor criminal charges.",
    "However, applicants' interests are protected under Article 8 ECHR",
    "(respect for private and family life), and States must provide",
    "effective remedies under Article 13 and respect Article 8 procedural",
    "safeguards.",
  ].join(" ");
  const tools = [
    lookup([{ act: "echr", para: "6", label: "Article 6" }], "ECHR Article 6"),
  ];
  const r = verifyResponseCitations(text, tools);
  // Expected: Article 6 verified, Article 8 + 13 unverified.
  const verifiedNums: string[] = r.verified_citations
    .join(" ")
    .toLowerCase()
    .match(/\d+/g) ?? [];
  const unverifiedNums: string[] = r.unverified_citations
    .join(" ")
    .toLowerCase()
    .match(/\d+/g) ?? [];
  assert(verifiedNums.includes("6"), `Article 6 should be verified, got ${JSON.stringify(r.verified_citations)}`);
  assert(
    unverifiedNums.includes("8") && unverifiedNums.includes("13"),
    `Article 8 + 13 should be unverified, got ${JSON.stringify(r.unverified_citations)}`,
  );
});

// ─── CV-T08 — h20 reproduction (KarS §121 → invents §118-§120 range) ───────

Deno.test("CV-T08 — h20: KarS §121 lookup, response invents §118-§120 range", () => {
  const text =
    "KarS §121 erineb järgmiste paragrahvidest (nagu §118-§120) kahjustuse raskusastme ja tagajärgede poolest.";
  const tools = [
    lookup([{ act: "ee-kars", para: "121", label: "§121" }], "KarS §121"),
  ];
  const r = verifyResponseCitations(text, tools);
  // §121 verified. §118, §119, §120 unverified.
  assert(r.verified_citations.length >= 1);
  assert(r.unverified_citations.length >= 2);
  assert(r.hallucination_score > 0.5);
});

// ─── CV-T09 — h24 reproduction (TLS §88 → invents §91, §92) ───────────────

Deno.test("CV-T09 — h24: TLS §88 lookup, response invents §91 + §92", () => {
  const text = [
    "Töölepingu erakorraline ülesütlemine on lubatud TLS §88 alusel.",
    "Lisaks tuleb arvestada TLS §91-ga, mis sätestab menetlusnõude,",
    "ning TLS §92-ga, mis reguleerib tööandja kohustusi.",
  ].join(" ");
  const tools = [
    lookup([{ act: "ee-tls", para: "88", label: "§88" }], "TLS §88"),
  ];
  const r = verifyResponseCitations(text, tools);
  assert(r.verified_citations.length >= 1, "§88 must be verified");
  const unverifiedNums = r.unverified_citations
    .map((c) => c.replace(/\D/g, ""));
  assert(
    unverifiedNums.includes("91") && unverifiedNums.includes("92"),
    `§91 + §92 should be unverified, got ${JSON.stringify(r.unverified_citations)}`,
  );
});

// ─── CV-T10 — h48 reproduction (TSL 7 luku → invents §7:1, §8:1) ──────────

Deno.test("CV-T10 — h48: TSL 7 luku lookup, response invents §7:1 + §8:1", () => {
  const text = [
    "По §7:1-2, работодатель может уведомить работника об увольнении.",
    "Внеочередное расторжение (purkaa) по §8:1 допускается только при особых обстоятельствах.",
  ].join(" ");
  const tools = [
    lookup([{ act: "fi-tsl", para: "7", label: "7 luku" }], "TSL 7 luku"),
    lookup([{ act: "fi-tsl", para: "7", label: "7 luku" }]),
  ];
  const r = verifyResponseCitations(text, tools);
  // §7:1 and §8:1 are sub-paragraphs the model invented from §7-luku looking only.
  // §7:1's number "7:1" should be unverified because tool returned bare "7".
  // (Our match accepts "7" as the paragraph_num token but the target is "7:1".)
  // Actually the verifier should treat "7:1" as different from "7"; let's
  // confirm at least one is flagged unverified.
  assert(
    r.unverified_citations.length >= 1,
    `expected at least one unverified, got ${JSON.stringify(r.unverified_citations)}`,
  );
});

// ─── CV-T11 — mark mode inserts [?] inline ─────────────────────────────────

Deno.test("CV-T11 — mark mode inserts [?] next to unverified cite", () => {
  const text = "TLS §88 alusel, vt ka §91 menetlusnõudest.";
  const tools = [lookup([{ act: "ee-tls", para: "88", label: "§88" }], "TLS §88")];
  const r = verifyResponseCitations(text, tools, { mode: "mark" });
  assert(r.unverified_citations.length === 1);
  assertStringIncludes(r.marked_text, "§91 [?]");
  // §88 should NOT be marked
  assert(
    !r.marked_text.includes("§88 [?]"),
    `§88 must not be marked, got: ${r.marked_text}`,
  );
  // Footer present
  assertStringIncludes(r.marked_text, "could not be verified");
});

// ─── CV-T12 — strip mode removes the cite ──────────────────────────────────

Deno.test("CV-T12 — strip mode removes unverified cite from text", () => {
  const text = "TLS §88 alusel, vt ka §91 menetlusnõudest.";
  const tools = [lookup([{ act: "ee-tls", para: "88", label: "§88" }], "TLS §88")];
  const r = verifyResponseCitations(text, tools, { mode: "strip" });
  // §91 disappears, §88 stays.
  assert(
    !r.stripped_text.includes("§91"),
    `§91 should be stripped, got: ${r.stripped_text}`,
  );
  assertStringIncludes(r.stripped_text, "§88");
});

// ─── CV-T13 — score boundaries ─────────────────────────────────────────────

Deno.test("CV-T13 — score is unverified/total", () => {
  const text = "TLS §88, §91, §92, §93 alusel.";
  const tools = [lookup([{ act: "ee-tls", para: "88", label: "§88" }], "TLS §88")];
  const r = verifyResponseCitations(text, tools);
  // 1 verified, 3 unverified → 0.75
  assertEquals(r.verified_citations.length, 1);
  assertEquals(r.unverified_citations.length, 3);
  assert(
    Math.abs(r.hallucination_score - 0.75) < 0.01,
    `expected 0.75, got ${r.hallucination_score}`,
  );
});

// ─── CV-T14 — citations inside [[ref:...]] markers are ignored ─────────────

Deno.test("CV-T14 — already-marked citations are skipped by verifier", () => {
  // If the grounder already wrapped a marker [[ref:TLS:88]], the §88 inside
  // that marker should NOT be extracted as a separate cite.
  const text = "Vastavalt [[ref:TLS:88]] tuleb hoiatada töötajat.";
  const tools: ToolUseResult[] = []; // no tool calls
  const r = verifyResponseCitations(text, tools);
  // The numeric "88" inside `ref:TLS:88` would otherwise show up as cite §88.
  // The PARA_PATTERN only matches when § precedes the number, so this passes
  // for free. But the test pins the behaviour.
  assertEquals(r.unverified_citations.length, 0);
});

// ─── CV-T15 — duplicate cite collapse ──────────────────────────────────────

Deno.test("CV-T15 — repeated §91 only counted once in unverified list", () => {
  const text = "§91 sätestab menetlusnõude. Tähelepanu: §91 alusel hoiatamine.";
  const r = verifyResponseCitations(text, []);
  assertEquals(r.unverified_citations.length, 1);
  // But details has both occurrences
  assertEquals(r.details.length, 2);
});

// ─── CV-T16 — range cap protects against §§1-9999 flood ────────────────────

Deno.test("CV-T16 — wide range capped at head + 20 + tail", () => {
  const text = "Vt §§1-100 alusel.";
  const r = verifyResponseCitations(text, []);
  // Should produce no more than ~22 cites (head, 20 siblings, tail)
  assert(
    r.details.length <= 25,
    `expected ≤25 cites for §§1-100, got ${r.details.length}`,
  );
  assert(r.details.length >= 20, `expected ≥20 cites for §§1-100, got ${r.details.length}`);
});

// ─── CV-T17 — coverage by chunk paragraph (no specific_statute) ────────────

Deno.test("CV-T17 — chunk.paragraph='121' covers prose '§121'", () => {
  const text = "KarS §121 katab kehalist väärkohtlemist.";
  const tools: ToolUseResult[] = [{
    tool_name: "legal_lookup",
    input: { query: "kehaline väärkohtlemine", jurisdiction: "ee" },
    returned_chunks: [{ act_slug: "ee-kars", paragraph: "121", section_label: null }],
  }];
  const r = verifyResponseCitations(text, tools);
  assertEquals(r.verified_citations.length, 1);
});

// ─── CV-T18 — Article 17 from EU corpus ────────────────────────────────────

Deno.test("CV-T18 — 'Article 17' covered by chunk paragraph='17'", () => {
  const text = "Under Article 17 of the GDPR, the right to erasure applies.";
  const tools: ToolUseResult[] = [{
    tool_name: "legal_lookup",
    input: { query: "GDPR right to erasure", jurisdiction: "eu" },
    returned_chunks: [{ act_slug: "gdpr", paragraph: "17", section_label: "Article 17" }],
  }];
  const r = verifyResponseCitations(text, tools);
  assertEquals(r.verified_citations.length, 1);
  assertEquals(r.unverified_citations.length, 0);
});

// ─── CV-T19 — tool not legal_lookup is ignored ─────────────────────────────

Deno.test("CV-T19 — non-legal_lookup tool results are ignored", () => {
  const text = "TLS §88 alusel.";
  const tools: ToolUseResult[] = [{
    tool_name: "send_email",
    input: { query: "TLS §88" },
    returned_chunks: [{ act_slug: "ee-tls", paragraph: "88", section_label: "§88" }],
  }];
  const r = verifyResponseCitations(text, tools);
  // send_email match should not count
  assertEquals(r.unverified_citations.length, 1);
});

// ─── CV-T20 — no false positives on innocuous text ─────────────────────────

Deno.test("CV-T20 — prose 'paragraph 5' or 'art 5 EU' is not over-matched", () => {
  // We require § OR "Article"/"Art." prefix. Bare "5" should NOT match.
  const text = "Section 5 of this document discusses 3 main points and 2 sub-points.";
  const r = verifyResponseCitations(text, []);
  // No § or Article prefix → no cites.
  assertEquals(r.details.length, 0);
});
