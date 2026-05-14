// Deno tests for citation-extractor — Pkg 2 v1.
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-read --allow-env --allow-net \
//     supabase/functions/citation-extractor/__tests__/citation_extractor_test.ts
//
// Pure-function tests for regex extraction.  Resolver / DB writes are covered
// by a contract test (cron-driven, hits the deployed fn).
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertFalse,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import { extractCitations, type ExtractedCitation } from "../index.ts";

// =============================================================================
// 1. FI patterns
// =============================================================================

Deno.test("CIT-T01 — FI extracts HOL 114 §", () => {
  const cites = extractCitations("Hakemus perustuu HOL 114 § mukaan.");
  const fi = cites.filter((c) => c.kind === "fi");
  assert(fi.length >= 1, "expected ≥1 FI hit");
  const hol = fi.find((c) => c.alias === "HOL 114 §");
  assert(hol, `expected canonical alias HOL 114 §, got ${JSON.stringify(fi)}`);
  assertEquals(hol!.section, "114");
});

Deno.test("CIT-T02 — FI extracts RL 21:1 § with chapter:section", () => {
  const cites = extractCitations("Rikoslain RL 21:1 § soveltuu.");
  const rl = cites.find((c) => c.kind === "fi" && c.alias === "RL 21:1 §");
  assert(rl, "expected RL 21:1 §");
  assertEquals(rl!.section, "1");
});

Deno.test("CIT-T03 — FI extracts OHO 13:114 §", () => {
  const cites = extractCitations(
    "OHO 13:114 § mukaan menetetty määräaika voidaan palauttaa.",
  );
  const oho = cites.find((c) => c.kind === "fi" && c.alias === "OHO 13:114 §");
  assert(oho, "expected OHO 13:114 §");
  assertEquals(oho!.section, "114");
});

Deno.test("CIT-T04 — FI extracts full-name 'Hallintolaki N §'", () => {
  const cites = extractCitations("Hallintolaki 60 § säätää tiedoksiannosta.");
  const hl = cites.find((c) =>
    c.kind === "fi" && c.alias === "Hallintolaki 60 §"
  );
  assert(hl, "expected Hallintolaki 60 §");
  assertEquals(hl!.section, "60");
});

Deno.test("CIT-T05 — FI rejects bare numerals + neg list", () => {
  // "Kohta 12 §" — `kohta` is in FI_NEG_LIST and should be rejected.
  const cites = extractCitations("Kohta 12 § ja s 5 § eivät ole pykäliä.");
  // Filter to alias forms that start with neg-list words.
  const bogus = cites.filter((c) =>
    c.kind === "fi" && /^(Kohta|kohta|S|s)\s/.test(c.alias)
  );
  assertEquals(bogus.length, 0, `neg-list leaked: ${JSON.stringify(bogus)}`);
});

// =============================================================================
// 2. EE patterns
// =============================================================================

Deno.test("CIT-T06 — EE extracts TsÜS § 86", () => {
  const cites = extractCitations("TsÜS § 86 alusel.");
  const tsu = cites.find((c) => c.kind === "ee" && c.alias === "TsÜS § 86");
  assert(tsu, "expected TsÜS § 86");
  assertEquals(tsu!.section, "86");
});

Deno.test("CIT-T07 — EE extracts PankrS § 109 lg 1", () => {
  const cites = extractCitations(
    "Maakohus leidis, et PankrS § 109 lg-s 1 eeldused on täidetud.",
  );
  // We only need to capture the act + section; lg/subsection is out of scope.
  const pk = cites.find((c) => c.kind === "ee" && c.alias === "PankrS § 109");
  assert(pk, `expected PankrS § 109, got ${JSON.stringify(cites)}`);
  assertEquals(pk!.section, "109");
});

Deno.test("CIT-T08 — EE rejects neg-list lone tokens", () => {
  const cites = extractCitations("lg § 5 ei ole pykälä.");
  const bogus = cites.filter((c) => c.kind === "ee" && /^lg\s/i.test(c.alias));
  assertEquals(bogus.length, 0, `EE neg-list leaked: ${JSON.stringify(bogus)}`);
});

// =============================================================================
// 3. EU directives
// =============================================================================

Deno.test("CIT-T09 — EU extracts Direktiivi 2004/38/EY", () => {
  const cites = extractCitations(
    "Asia kuuluu Direktiivi 2004/38/EY soveltamisalaan.",
  );
  const eu = cites.find((c) => c.kind === "eu");
  assert(eu, "expected EU hit");
  assertEquals(eu!.alias, "eu-dir-2004-38");
});

Deno.test("CIT-T10 — EU extracts Directive 2008/115/EC (English)", () => {
  const cites = extractCitations("Pursuant to Directive 2008/115/EC ...");
  const eu = cites.find((c) => c.kind === "eu");
  assert(eu, "expected EU hit for Directive 2008/115/EC");
  assertEquals(eu!.alias, "eu-dir-2008-115");
});

// =============================================================================
// 4. ECtHR
// =============================================================================

Deno.test("CIT-T11 — ECtHR extracts Maslov v Austria", () => {
  const cites = extractCitations(
    "EIT toi esiin perusteet Maslov v Austria -ratkaisussa.",
  );
  const ec = cites.find((c) => c.kind === "ecthr");
  assert(ec, "expected ECtHR hit");
  assert(ec!.alias.includes("Maslov") && ec!.alias.includes("Austria"));
});

Deno.test("CIT-T12 — ECtHR with dot also matches", () => {
  const cites = extractCitations("Otsus Salah Sheekh v. Netherlands hindas...");
  const ec = cites.find((c) =>
    c.kind === "ecthr" && c.alias.includes("Netherlands")
  );
  assert(ec, "expected ECtHR hit with dot");
});

// =============================================================================
// 5. De-duplication + ordering
// =============================================================================

Deno.test("CIT-T13 — repeated citations are de-duped within a chunk", () => {
  const text = "HOL 114 § ... ja edelleen HOL 114 § sekä HOL 114 § ...";
  const cites = extractCitations(text);
  const holHits = cites.filter((c) => c.alias === "HOL 114 §");
  assertEquals(holHits.length, 1, "should dedupe identical citations");
});

Deno.test("CIT-T14 — empty / whitespace-only input returns no hits", () => {
  assertEquals(extractCitations("").length, 0);
  assertEquals(extractCitations("   \n\t  ").length, 0);
  assertEquals(
    extractCitations("Asia ei sisällä mitään säädösviittauksia.").length,
    0,
  );
});

// =============================================================================
// 6. Mixed FI + EE + EU in one paragraph (real-world shape)
// =============================================================================

Deno.test("CIT-T15 — mixed FI/EE/EU citations all extracted", () => {
  const text = [
    "Maakohus leidis, et PankrS § 109 alusel ja TsÜS § 86 valguses.",
    "Suomen oikeudessa HOL 114 § + OHO 13:114 § soveltuvat.",
    "Direktiivi 2004/38/EY artikla 28 antaa lisäsuojan.",
  ].join(" ");
  const cites = extractCitations(text);
  // We expect at least: PankrS, TsÜS, HOL 114, OHO 13:114, EU dir.
  const aliases = new Set(cites.map((c) => c.alias));
  assert(aliases.has("PankrS § 109"), "PankrS missing");
  assert(aliases.has("TsÜS § 86"), "TsÜS missing");
  assert(aliases.has("HOL 114 §"), "HOL missing");
  assert(aliases.has("OHO 13:114 §"), "OHO missing");
  assert(aliases.has("eu-dir-2004-38"), "EU missing");
});

// =============================================================================
// 7. Type-shape sanity
// =============================================================================

Deno.test("CIT-T16 — every output row has required fields", () => {
  const cites = extractCitations(
    "HOL 114 §, TsÜS § 86, Direktiivi 2004/38/EY, Maslov v Austria.",
  );
  for (const c of cites) {
    assert(typeof c.raw === "string" && c.raw.length > 0);
    assert(["fi", "ee", "eu", "ecthr"].includes(c.kind));
    assert(typeof c.alias === "string" && c.alias.length > 0);
    assert(typeof c.section === "string");
  }
});
