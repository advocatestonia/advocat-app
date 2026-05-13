// contract_review_prompts.test.ts — pins the composable Contract Review
// prompt modules. TypeScript port of
// `test/services/contract_review_prompts_test.dart`.
// -----------------------------------------------------------------------------
// Run:
//   deno test --allow-all supabase/functions/_tests/contract_review_prompts.test.ts
//
// Each module is tested in isolation; the orchestrator is tested at the
// bottom. These tests are the contract between the prompt layer and the
// Typst rendering worker — break them and the PDF stops rendering, so
// changes here require a deliberate version bump in the prompt module.
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  buildContractAnalysisCore,
  buildContractReviewPrompt,
  buildContractReviewSystemPrompt,
  buildEmailDraftAddendum,
  buildJurisdictionContext,
  buildRiskTaxonomy,
  kContractReviewDisclaimers,
  kContractReviewPromptVersionDefault,
  pickContractReviewVersion,
} from "../_shared/contract_review_prompts.ts";

// =============================================================================
// pickContractReviewVersion
// =============================================================================

Deno.test("pickContractReviewVersion — defaults to v1.0 when env var unset", () => {
  // envOverride: '' simulates an unset / empty env var.
  assertEquals(
    pickContractReviewVersion(""),
    kContractReviewPromptVersionDefault,
  );
});

Deno.test("pickContractReviewVersion — accepts a known version override", () => {
  assertEquals(pickContractReviewVersion("v1.0"), "v1.0");
});

Deno.test("pickContractReviewVersion — falls back to default for unknown version", () => {
  assertEquals(
    pickContractReviewVersion("v9.9-experimental"),
    kContractReviewPromptVersionDefault,
  );
});

// =============================================================================
// buildJurisdictionContext
// =============================================================================

Deno.test("buildJurisdictionContext — returns non-empty fragment for known jurisdictions", () => {
  const out = buildJurisdictionContext(["DE"]);
  assert(out.length > 0, "output must be non-empty");
  assert(out.length > 100, "output must be substantive");
});

Deno.test("buildJurisdictionContext — includes BGB toolkit for German contracts", () => {
  const out = buildJurisdictionContext(["DE"]);
  assertStringIncludes(out, "BGB");
  assertStringIncludes(out, "HGB");
  assertStringIncludes(out, "AGB-Kontrolle");
  assertStringIncludes(out, "§ 84");
  assertStringIncludes(out, "§ 377");
});

Deno.test("buildJurisdictionContext — includes BGB toolkit for AT and CH too", () => {
  assertStringIncludes(buildJurisdictionContext(["AT"]), "BGB");
  assertStringIncludes(buildJurisdictionContext(["CH"]), "BGB");
});

Deno.test("buildJurisdictionContext — includes UCC toolkit for US contracts", () => {
  const out = buildJurisdictionContext(["US"]);
  assertStringIncludes(out, "UCC");
  assertStringIncludes(out, "§ 2-207");
  // "common-law" (hyphenated) is the canonical spelling.
  assertStringIncludes(out, "common-law");
});

Deno.test("buildJurisdictionContext — includes UK common-law toolkit", () => {
  const out = buildJurisdictionContext(["UK"]);
  assertStringIncludes(out, "Sale of Goods Act 1979");
  assertStringIncludes(out, "Hadley v. Baxendale");
});

Deno.test("buildJurisdictionContext — includes GDPR + CISG when EU is declared", () => {
  const out = buildJurisdictionContext(["EU"]);
  assertStringIncludes(out, "GDPR");
  assertStringIncludes(out, "Brussels I");
  assertStringIncludes(out, "CISG");
});

Deno.test("buildJurisdictionContext — stacks multiple families when several jurisdictions supplied", () => {
  const out = buildJurisdictionContext(["DE", "EU"]);
  assertStringIncludes(out, "BGB");
  assertStringIncludes(out, "GDPR");
});

Deno.test("buildJurisdictionContext — falls back to generic when no jurisdictions supplied", () => {
  const out = buildJurisdictionContext([]);
  assertStringIncludes(out, "Generic toolkit");
});

Deno.test("buildJurisdictionContext — falls back to generic on unknown tag", () => {
  const out = buildJurisdictionContext(["ZZ"]);
  assertStringIncludes(out, "Generic toolkit");
});

Deno.test("buildJurisdictionContext — is case-insensitive for jurisdiction tags", () => {
  const lower = buildJurisdictionContext(["de"]);
  const upper = buildJurisdictionContext(["DE"]);
  assertEquals(lower, upper);
});

Deno.test("buildJurisdictionContext — output is well below the 30 KB module budget", () => {
  // Worst case: all families stacked.
  const out = buildJurisdictionContext(["DE", "US", "UK", "EU"]);
  assert(out.length < 30 * 1024, `jurisdiction fragment too large: ${out.length}`);
});

// =============================================================================
// buildRiskTaxonomy
// =============================================================================

Deno.test("buildRiskTaxonomy — returns non-empty base taxonomy without industry", () => {
  const out = buildRiskTaxonomy();
  assert(out.length > 0);
  assertStringIncludes(out, "CRITICAL");
  assertStringIncludes(out, "HIGH");
  assertStringIncludes(out, "MEDIUM");
  assertStringIncludes(out, "INFO");
  assertStringIncludes(out, "GOOD");
});

Deno.test("buildRiskTaxonomy — lists all five categories", () => {
  const out = buildRiskTaxonomy();
  assertStringIncludes(out, "Commercial");
  assertStringIncludes(out, "Legal");
  assertStringIncludes(out, "Warranty");
  assertStringIncludes(out, "IP & data");
  assertStringIncludes(out, "Operational");
});

Deno.test("buildRiskTaxonomy — adds dealer module when industry=dealer", () => {
  const out = buildRiskTaxonomy({ industry: "dealer" });
  assertStringIncludes(out, "dealer");
  assertStringIncludes(out, "Ausgleichsanspruch");
});

Deno.test("buildRiskTaxonomy — adds SaaS module when industry=saas", () => {
  const out = buildRiskTaxonomy({ industry: "saas" });
  assertStringIncludes(out, "SaaS");
  assertStringIncludes(out, "SLA");
  assertStringIncludes(out, "Sub-processors");
});

Deno.test("buildRiskTaxonomy — adds NDA module when industry=nda", () => {
  const out = buildRiskTaxonomy({ industry: "nda" });
  assertStringIncludes(out, "NDA");
  // Case-insensitive match: source is "Residual-knowledge".
  assertStringIncludes(out.toLowerCase(), "residual");
});

Deno.test("buildRiskTaxonomy — adds employment module when industry=employment", () => {
  const out = buildRiskTaxonomy({ industry: "employment" });
  assertStringIncludes(out, "Probation");
  assertStringIncludes(out, "Non-compete");
});

Deno.test("buildRiskTaxonomy — adds M&A module when industry=m&a", () => {
  const out = buildRiskTaxonomy({ industry: "m&a" });
  assertStringIncludes(out, "Reps & warranties");
  assertStringIncludes(out, "MAC");
});

Deno.test("buildRiskTaxonomy — adds real-estate module when industry=real_estate", () => {
  const out = buildRiskTaxonomy({ industry: "real_estate" });
  assertStringIncludes(out, "Rent indexation");
});

Deno.test("buildRiskTaxonomy — unknown industry tag is a no-op (does not throw)", () => {
  // Just confirm no throw and base taxonomy still present.
  const out = buildRiskTaxonomy({ industry: "space-mining" });
  assertStringIncludes(out, "CRITICAL");
});

Deno.test("buildRiskTaxonomy — output is under the 30 KB module budget", () => {
  const out = buildRiskTaxonomy({ industry: "m&a" });
  assert(out.length < 30 * 1024, `risk taxonomy too large: ${out.length}`);
});

// =============================================================================
// buildContractAnalysisCore
// =============================================================================

Deno.test("buildContractAnalysisCore — returns non-empty fragment", () => {
  const out = buildContractAnalysisCore("en");
  assert(out.length > 0);
  assert(out.length > 500);
});

Deno.test('buildContractAnalysisCore — forbids the verb "sign"', () => {
  const out = buildContractAnalysisCore("en");
  // The prompt explicitly enumerates forbidden verbs.
  assertStringIncludes(out, '"sign"');
  assertStringIncludes(out, "NEVER");
});

Deno.test("buildContractAnalysisCore — lists allowed verbs", () => {
  const out = buildContractAnalysisCore("en");
  assertStringIncludes(out, "flag");
  assertStringIncludes(out, "suggest");
  assertStringIncludes(out, "propose alternative wording");
});

Deno.test("buildContractAnalysisCore — always mentions Advocat AI as the byline (never personal name)", () => {
  const out = buildContractAnalysisCore("en");
  assertStringIncludes(out, "Advocat AI");
  assertStringIncludes(out, "Asianajajaliitto");
  assertStringIncludes(out, "Advokatuur");
});

Deno.test("buildContractAnalysisCore — emits the strict JSON schema for the Typst worker", () => {
  const out = buildContractAnalysisCore("en");
  assertStringIncludes(out, '"cover"');
  assertStringIncludes(out, '"summary"');
  assertStringIncludes(out, '"translation"');
  assertStringIncludes(out, '"checklist"');
  assertStringIncludes(out, '"email_to_counterparty"');
  assertStringIncludes(out, "CRITICAL|HIGH|MEDIUM|INFO|GOOD");
});

Deno.test("buildContractAnalysisCore — includes the localised disclaimer footer for the output language", () => {
  const etOut = buildContractAnalysisCore("et");
  assertStringIncludes(etOut, "Informatiivne analüüs");
  assertStringIncludes(etOut, "Advocat OÜ ei vastuta otsuste eest");

  const ruOut = buildContractAnalysisCore("ru");
  assertStringIncludes(ruOut, "Информационный анализ");

  const deOut = buildContractAnalysisCore("de");
  assertStringIncludes(deOut, "Informative Analyse");
});

Deno.test("buildContractAnalysisCore — falls back to English disclaimer for unknown language", () => {
  const out = buildContractAnalysisCore("xx");
  assertStringIncludes(out, "Informational analysis only");
});

Deno.test("buildContractAnalysisCore — all 17 advertised languages resolve a disclaimer", () => {
  const langs: string[] = [
    "en",
    "ru",
    "et",
    "fi",
    "de",
    "sv",
    "fr",
    "es",
    "it",
    "pl",
    "ar",
    "tr",
    "uk",
    "lv",
    "lt",
    "ro",
    "fa",
  ];
  for (const l of langs) {
    assert(
      Object.prototype.hasOwnProperty.call(kContractReviewDisclaimers, l),
      `missing disclaimer for ${l}`,
    );
    const out = buildContractAnalysisCore(l);
    assertStringIncludes(
      out,
      kContractReviewDisclaimers[l],
      `${l} disclaimer not embedded`,
    );
  }
});

Deno.test('buildContractAnalysisCore — NEVER uses the string "B2B" in any output language', () => {
  const langs: string[] = ["en", "ru", "et", "fi", "de"];
  for (const l of langs) {
    const out = buildContractAnalysisCore(l);
    assert(!out.includes("B2B"), `"B2B" leaked into core prompt for ${l}`);
  }
});

Deno.test("buildContractAnalysisCore — output is under the 30 KB module budget", () => {
  const out = buildContractAnalysisCore("en");
  assert(out.length < 30 * 1024, `core prompt too large: ${out.length}`);
});

// =============================================================================
// buildEmailDraftAddendum
// =============================================================================

Deno.test("buildEmailDraftAddendum — returns non-empty fragment", () => {
  const out = buildEmailDraftAddendum("de");
  assert(out.length > 0);
});

Deno.test("buildEmailDraftAddendum — instructs to use original language not output language", () => {
  const out = buildEmailDraftAddendum("de");
  assertStringIncludes(out, "ORIGINAL");
  assertStringIncludes(out, "de");
  // Anti-regression: the addendum must not bind to the user's reading
  // language. It is exclusively about the contract's own language.
  assertStringIncludes(out, "Do NOT translate");
});

Deno.test("buildEmailDraftAddendum — requires 3-5 clause-specific numbered questions", () => {
  const out = buildEmailDraftAddendum("en");
  assertStringIncludes(out, "3 to 5");
  assertStringIncludes(out, "numbered");
  assertStringIncludes(out, "clause");
});

Deno.test("buildEmailDraftAddendum — forbids loaded language in the email", () => {
  const out = buildEmailDraftAddendum("en");
  assertStringIncludes(out, "unfair");
  assertStringIncludes(out, "never");
});

Deno.test("buildEmailDraftAddendum — leaves the signature line as a placeholder", () => {
  const out = buildEmailDraftAddendum("en");
  assertStringIncludes(out, "[Name]");
});

Deno.test("buildEmailDraftAddendum — output is under the 30 KB module budget", () => {
  const out = buildEmailDraftAddendum("de");
  assert(out.length < 30 * 1024, `email addendum too large: ${out.length}`);
});

// =============================================================================
// buildContractReviewPrompt orchestrator
// =============================================================================

Deno.test("buildContractReviewPrompt — assembles all modules into one prompt", () => {
  const out = buildContractReviewPrompt({
    jurisdictions: ["DE", "EU"],
    outputLanguage: "ru",
    originalLanguage: "de",
    industry: "dealer",
  });
  // Header
  assertStringIncludes(out, "FEATURE: Contract Review");
  assertStringIncludes(
    out,
    `CONTRACT_REVIEW_PROMPT_VERSION: ${kContractReviewPromptVersionDefault}`,
  );
  // Jurisdictions
  assertStringIncludes(out, "BGB");
  assertStringIncludes(out, "GDPR");
  // Risk taxonomy
  assertStringIncludes(out, "CRITICAL");
  assertStringIncludes(out, "Ausgleichsanspruch");
  // Core
  assertStringIncludes(out, "Advocat AI");
  // Email addendum
  assertStringIncludes(out, "ORIGINAL");
});

Deno.test("buildContractReviewPrompt — embeds the user-language disclaimer in the assembled prompt", () => {
  const ru = buildContractReviewPrompt({
    jurisdictions: ["DE"],
    outputLanguage: "ru",
    originalLanguage: "de",
  });
  assertStringIncludes(ru, "Информационный анализ");
});

Deno.test("buildContractReviewPrompt — respects the version override", () => {
  const out = buildContractReviewPrompt({
    jurisdictions: ["EU"],
    outputLanguage: "en",
    originalLanguage: "en",
    version: "v1.0",
  });
  assertStringIncludes(out, "CONTRACT_REVIEW_PROMPT_VERSION: v1.0");
});

Deno.test('buildContractReviewPrompt — never leaks the string "B2B" anywhere in the assembled output', () => {
  const out = buildContractReviewPrompt({
    jurisdictions: ["DE", "EU"],
    outputLanguage: "ru",
    originalLanguage: "de",
    industry: "dealer",
  });
  assert(
    !out.includes("B2B"),
    '"B2B" must be an internal-only term; never user-facing',
  );
});

Deno.test("buildContractReviewPrompt — total assembled prompt stays under 120 KB shared budget", () => {
  const out = buildContractReviewPrompt({
    jurisdictions: ["DE", "US", "UK", "EU"],
    outputLanguage: "ru",
    originalLanguage: "de",
    industry: "m&a",
  });
  assert(
    out.length < 120 * 1024,
    `composite prompt too large (${out.length}); 120 KB cap`,
  );
});

// =============================================================================
// buildContractReviewSystemPrompt — alias compatibility with handler.ts
// =============================================================================

Deno.test("buildContractReviewSystemPrompt — alias produces identical output to buildContractReviewPrompt", () => {
  const a = buildContractReviewPrompt({
    jurisdictions: ["DE"],
    outputLanguage: "en",
    originalLanguage: "en",
    industry: "saas",
    version: "v1.0",
  });
  const b = buildContractReviewSystemPrompt({
    jurisdictions: ["DE"],
    outputLanguage: "en",
    originalLanguage: "en",
    industry: "saas",
    version: "v1.0",
  });
  assertEquals(a, b);
});

Deno.test("buildContractReviewSystemPrompt — legacy jurisdictionHint string upcasts to jurisdictions[]", () => {
  // handler.ts calls with `jurisdictionHint: "de"` (single hint). The
  // orchestrator must honour that without losing the BGB toolkit.
  const out = buildContractReviewSystemPrompt({
    outputLanguage: "en",
    jurisdictionHint: "de",
    industryHint: "saas",
  });
  assertStringIncludes(out, "BGB");
  assertStringIncludes(out, "SaaS");
});
