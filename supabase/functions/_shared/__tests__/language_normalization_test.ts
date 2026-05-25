// language_normalization_test.ts — P0 fix 2026-05-25.
// -----------------------------------------------------------------------------
// Coverage for the language-fallback fix on consilium_lawyer_bridge.ts +
// consilium_roles/types.ts. The previous behaviour defaulted every
// unknown-locale user to Russian; the bug surfaced as Finnish / Polish /
// Arabic / etc. users receiving Russian consilium synthesis regardless of
// their UI locale.
//
// Run with:
//   deno test --allow-env --no-check \
//     supabase/functions/_shared/__tests__/language_normalization_test.ts
//
// Coverage matrix:
//   • All 17 SUPPORTED_LANGUAGES are accepted as-is (no coercion to "ru")
//   • BCP47 region/script subtags stripped: "fi-FI" → "fi", "zh_Hant" → "en"
//   • Unknown languages fall back to "en" (NOT "ru")
//   • null / undefined / empty / whitespace fall back to "en"
//   • Case-insensitive: "FI" → "fi", "  RU  " → "ru"
//   • Specifically asserts the bridge's resolveLang path no longer returns "ru"
//     for unknown / undefined input
//   • pickName falls back to en before ru
//   • buildReplyDirective covers all 17 locales without "ru" leak
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertNotEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  DEFAULT_LANGUAGE,
  type LocalisedName,
  normalizeLanguage,
  pickName,
  SUPPORTED_LANGUAGES,
  type SupportedLanguage,
} from "../consilium_roles/types.ts";
import {
  buildLawyerCtx,
  buildReplyDirective,
} from "../lawyer_agents/index.ts";
import { selectRolesFromLawyerDept } from "../consilium_lawyer_bridge.ts";

// ─── Default fallback ────────────────────────────────────────────────────────

Deno.test("DEFAULT_LANGUAGE is 'en' — NEVER 'ru'", () => {
  assertEquals(DEFAULT_LANGUAGE, "en");
  assertNotEquals(DEFAULT_LANGUAGE as string, "ru");
});

Deno.test("SUPPORTED_LANGUAGES contains all 17 UI locales from lib/l10n", () => {
  // Must match lib/l10n/app_*.arb suffixes exactly.
  const expected = [
    "ar", "de", "en", "es", "et", "fa", "fi", "fr", "it",
    "lt", "lv", "pl", "ro", "ru", "sv", "tr", "uk",
  ];
  assertEquals([...SUPPORTED_LANGUAGES].sort(), expected.sort());
  assertEquals(SUPPORTED_LANGUAGES.length, 17);
});

// ─── normalizeLanguage — happy path ──────────────────────────────────────────

Deno.test("normalizeLanguage — accepts every SupportedLanguage as-is", () => {
  for (const lang of SUPPORTED_LANGUAGES) {
    assertEquals(normalizeLanguage(lang), lang, `lang=${lang}`);
  }
});

Deno.test("normalizeLanguage — case-insensitive", () => {
  assertEquals(normalizeLanguage("FI"), "fi");
  assertEquals(normalizeLanguage("EN"), "en");
  assertEquals(normalizeLanguage("RU"), "ru");
  assertEquals(normalizeLanguage("Et"), "et");
  assertEquals(normalizeLanguage("aR"), "ar");
});

Deno.test("normalizeLanguage — trims whitespace", () => {
  assertEquals(normalizeLanguage("  fi  "), "fi");
  assertEquals(normalizeLanguage("\tru\n"), "ru");
  assertEquals(normalizeLanguage(" EN "), "en");
});

Deno.test("normalizeLanguage — strips BCP47 region subtag (hyphen)", () => {
  assertEquals(normalizeLanguage("fi-FI"), "fi");
  assertEquals(normalizeLanguage("ru-RU"), "ru");
  assertEquals(normalizeLanguage("en-US"), "en");
  assertEquals(normalizeLanguage("en-GB"), "en");
  assertEquals(normalizeLanguage("pt-BR"), "en"); // pt not supported → en
  assertEquals(normalizeLanguage("uk-UA"), "uk");
  assertEquals(normalizeLanguage("ar-SA"), "ar");
});

Deno.test("normalizeLanguage — strips BCP47 region subtag (underscore)", () => {
  assertEquals(normalizeLanguage("fi_FI"), "fi");
  assertEquals(normalizeLanguage("ru_RU"), "ru");
  assertEquals(normalizeLanguage("zh_Hant"), "en"); // zh not supported
  assertEquals(normalizeLanguage("pl_PL"), "pl");
});

Deno.test("normalizeLanguage — strips script + region (multi-segment)", () => {
  // zh-Hant-HK has 3 segments; we keep the primary tag.
  assertEquals(normalizeLanguage("zh-Hant-HK"), "en"); // zh not supported
  assertEquals(normalizeLanguage("fi-Latn-FI"), "fi");
});

// ─── normalizeLanguage — falls back to "en", not "ru" ────────────────────────

Deno.test("normalizeLanguage — null / undefined → 'en'", () => {
  assertEquals(normalizeLanguage(null), "en");
  assertEquals(normalizeLanguage(undefined), "en");
});

Deno.test("normalizeLanguage — empty / whitespace-only → 'en'", () => {
  assertEquals(normalizeLanguage(""), "en");
  assertEquals(normalizeLanguage("   "), "en");
  assertEquals(normalizeLanguage("\t\n"), "en");
});

Deno.test("normalizeLanguage — unknown language tag → 'en' (NOT 'ru')", () => {
  // The whole point of the P0 fix: unknown locales must NOT coerce to Russian.
  for (const unknown of ["zh", "ja", "ko", "pt", "nl", "hi", "th", "xx", "qqq"]) {
    const out = normalizeLanguage(unknown);
    assertEquals(out, "en", `unknown="${unknown}" → ${out}`);
    assertNotEquals(out as string, "ru", `unknown="${unknown}" must NOT → ru`);
  }
});

Deno.test("normalizeLanguage — non-string input → 'en'", () => {
  // deno-lint-ignore no-explicit-any
  assertEquals(normalizeLanguage(123 as any), "en");
  // deno-lint-ignore no-explicit-any
  assertEquals(normalizeLanguage({} as any), "en");
  // deno-lint-ignore no-explicit-any
  assertEquals(normalizeLanguage([] as any), "en");
  // deno-lint-ignore no-explicit-any
  assertEquals(normalizeLanguage(true as any), "en");
});

// ─── pickName — falls back en → ru ───────────────────────────────────────────

Deno.test("pickName — exact match wins", () => {
  const name: LocalisedName = {
    en: "Counsel",
    ru: "Адвокат",
    fi: "Asianajaja",
    et: "Vandeadvokaat",
  };
  assertEquals(pickName(name, "fi"), "Asianajaja");
  assertEquals(pickName(name, "et"), "Vandeadvokaat");
  assertEquals(pickName(name, "en"), "Counsel");
  assertEquals(pickName(name, "ru"), "Адвокат");
});

Deno.test("pickName — falls back to en before ru for unknown locale", () => {
  const name: LocalisedName = { en: "Counsel", ru: "Адвокат" };
  // Polish has no native entry → must hit `en`, not `ru`.
  assertEquals(pickName(name, "pl"), "Counsel");
  assertEquals(pickName(name, "ar"), "Counsel");
  assertEquals(pickName(name, "fa"), "Counsel");
  assertEquals(pickName(name, "uk"), "Counsel");
});

Deno.test("pickName — falls back to ru only when en is missing", () => {
  // Legacy role with only ru — must still produce something.
  const name: LocalisedName = { ru: "Только русский" };
  assertEquals(pickName(name, "pl"), "Только русский");
  assertEquals(pickName(name, undefined), "Только русский");
});

Deno.test("pickName — undefined / null lang → en before ru", () => {
  const name: LocalisedName = { en: "Counsel", ru: "Адвокат" };
  assertEquals(pickName(name, undefined), "Counsel");
  assertEquals(pickName(name, null as unknown as undefined), "Counsel");
  assertEquals(pickName(name, ""), "Counsel");
});

// ─── buildReplyDirective — every locale non-empty, no RU leak ─────────────────

Deno.test("buildReplyDirective — every SupportedLanguage produces a non-empty directive", () => {
  for (const lang of SUPPORTED_LANGUAGES) {
    const out = buildReplyDirective(lang);
    assert(typeof out === "string", `lang=${lang} non-string`);
    assert(out.length > 0, `lang=${lang} empty directive`);
  }
});

Deno.test("buildReplyDirective — defaults to English for unknown locales (NOT Russian)", () => {
  const en = buildReplyDirective("en");
  // Unknown / undefined → must equal the English directive.
  assertEquals(buildReplyDirective(undefined), en);
  assertEquals(buildReplyDirective(null), en);
  assertEquals(buildReplyDirective(""), en);
  assertEquals(buildReplyDirective("xx"), en);
  assertEquals(buildReplyDirective("zh-CN"), en);
  assertEquals(buildReplyDirective("ja"), en);
});

Deno.test("buildReplyDirective — flavour overrides for matching locale", () => {
  const base = buildReplyDirective("fi");
  const override = buildReplyDirective("fi", { fi: "FLAVOUR" });
  assertEquals(override, "FLAVOUR");
  assertNotEquals(override, base);
});

Deno.test("buildReplyDirective — flavour ignored for non-matching locale", () => {
  // When user is Polish but lawyer only flavours fi/et/ru, Polish gets the
  // BASE Polish directive (which exists), NOT the Russian flavour.
  const out = buildReplyDirective("pl", {
    fi: "FI override",
    et: "ET override",
    ru: "RU override — must NOT leak",
  });
  assertNotEquals(out, "RU override — must NOT leak");
  assertNotEquals(out, "FI override");
  assertNotEquals(out, "ET override");
  // Polish gets the base Polish directive.
  assert(out.toLowerCase().includes("polsku"), `out=${out}`);
});

// ─── buildLawyerCtx — normalises language ────────────────────────────────────

Deno.test("buildLawyerCtx — normalises raw locale tags", () => {
  const ctx1 = buildLawyerCtx("test query", "fi-FI");
  assertEquals(ctx1.language, "fi");
  const ctx2 = buildLawyerCtx("test query", "  RU  ");
  assertEquals(ctx2.language, "ru");
  const ctx3 = buildLawyerCtx("test query", "xx");
  assertEquals(ctx3.language, "en");
  const ctx4 = buildLawyerCtx("test query", "PL");
  assertEquals(ctx4.language, "pl");
});

Deno.test("buildLawyerCtx — preserves base.language when set", () => {
  // Explicit base.language wins over the fallback parameter.
  const ctx = buildLawyerCtx("test", "ru", { language: "fi" });
  assertEquals(ctx.language, "fi");
});

// ─── Bridge: resolveLang — unknown / undefined → never 'ru' ──────────────────

Deno.test("selectRolesFromLawyerDept — UNDEFINED classification does NOT route to 'ru'", () => {
  // When the caller passes no classification, the bridge used to coerce
  // language to "ru" inside resolveLang. The lawyer agents' systemPrompts
  // would then emit Russian directives. We verify the systemPrompt body of
  // each selected role does NOT contain the Russian-only directive markers.
  const result = selectRolesFromLawyerDept(
    "KHO valituslupa hakemus — what should I do?",
    undefined,
  );
  assert(result !== null, "expected non-null bridge result");
  assert(result.roles.length >= 3, "expected ≥3 roles");
  // Every role's compiled focus body should include an English reply
  // directive — not the legacy "Отвечай по-русски" default.
  for (const role of result.roles) {
    const body = role.focus;
    // Heuristic: an English-defaulted body should NOT be hard-pinned to RU.
    // We allow Russian text inside the body (e.g. lawyer personas are
    // bilingual) but the explicit "respond in" directive should not say
    // "по-русски" when no language was specified.
    // The buildReplyDirective("en") string is:
    //   "Reply in English; statute citations in source language."
    // So at least one segment of the body should match that.
    assert(
      body.includes("Reply in English") || body.includes("Vastaa") || body.includes("Vasta"),
      `role "${role.name}" appears to have no English/native directive; ` +
        `default may have leaked back to ru. Body head: ${body.slice(0, 400)}`,
    );
  }
});

Deno.test("selectRolesFromLawyerDept — Polish UI locale routes Polish directive", () => {
  // Polish user — must NOT receive Russian by default.
  const result = selectRolesFromLawyerDept(
    "deportacja z Finlandii — co robić?",
    { language: "pl" as SupportedLanguage, jurisdiction: "FI" },
  );
  assert(result !== null);
  assert(result.roles.length >= 3);
  // At least one role's body must carry the Polish reply directive
  // (BASE_REPLY_DIRECTIVES.pl = "Odpowiadaj po polsku; …").
  const anyPolish = result.roles.some((r) =>
    r.focus.toLowerCase().includes("polsku")
  );
  assert(
    anyPolish,
    "No role carried a Polish reply directive — buildReplyDirective leaked",
  );
  // And NO role should carry the Russian "Отвечай по-русски" directive — but
  // because senior_asianajaja preserves ru as a flavour (only fires when lang
  // is normalised to ru), the Russian directive must NOT appear for a pl user.
  const anyRussianDirective = result.roles.some((r) =>
    r.focus.includes("Отвечай по-русски")
  );
  assert(
    !anyRussianDirective,
    "A role leaked the Russian directive for a Polish user — P0 regression",
  );
});

Deno.test("selectRolesFromLawyerDept — Finnish locale produces Finnish directive (regression)", () => {
  const result = selectRolesFromLawyerDept(
    "KHO valituslupa, käännyttäminen, Sulga-case",
    { language: "fi", jurisdiction: "FI" },
  );
  assert(result !== null);
  // Senior asianajaja (FI general counsel) should emit "Vastaa suomeksi."
  const anyFinnish = result.roles.some((r) =>
    r.focus.includes("Vastaa suomeksi")
  );
  assert(anyFinnish, "Finnish user did not get Finnish directive");
});

Deno.test("selectRolesFromLawyerDept — region-subtag locale is normalised before routing", () => {
  // Owner test: caller passes "fi-FI" through the chain — must reach the
  // bridge as "fi" so Finnish directives fire.
  const result = selectRolesFromLawyerDept(
    "valituslupa KHO",
    // deno-lint-ignore no-explicit-any
    { language: "fi-FI" as any, jurisdiction: "FI" },
  );
  assert(result !== null);
  const anyFinnish = result.roles.some((r) =>
    r.focus.includes("Vastaa suomeksi")
  );
  assert(anyFinnish, "fi-FI was not normalised to fi inside the bridge");
});
