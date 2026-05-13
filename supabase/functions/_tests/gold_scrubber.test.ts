// gold_scrubber.test.ts — Sofia Gold Corpus Phase A.
// ----------------------------------------------------------------------------
// Run with:
//   deno test --allow-net --allow-read --allow-env \
//     supabase/functions/_tests/gold_scrubber.test.ts
//
// Coverage:
//   - regexScrub redacts emails, Estonian/Finnish phones, isikukood,
//     HETU, R/H-prefixed case numbers, and Estonian/Finnish surnames.
//   - regexScrub PRESERVES KHO/RKHKo public-record citations.
//   - regexScrub returns a replacement-counts map for telemetry.
//   - twoStageScrub falls back to regex-only when no anthropic key.
// ----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  regexScrub,
  twoStageScrub,
} from "../_shared/pii_scrubber.ts";

// ─── regex pass ─────────────────────────────────────────────────────────────

Deno.test("regexScrub — empty input is a no-op", () => {
  const r = regexScrub("");
  assertEquals(r.text, "");
  assertEquals(r.replacements, {});
});

Deno.test("regexScrub — redacts Finnish phone number", () => {
  const r = regexScrub("Soita +358 50 123 4567 tai jätä viesti");
  assertStringIncludes(r.text, "[PHONE]");
  assert(!/\d{4}/.test(r.text.replace(/\[PHONE\]/g, "")),
    "no 4-digit run after redaction");
  assert((r.replacements["[PHONE]"] ?? 0) >= 1);
});

Deno.test("regexScrub — redacts Estonian phone number", () => {
  const r = regexScrub("Helista +372 5555 1234 või kirjuta");
  assertStringIncludes(r.text, "[PHONE]");
});

Deno.test("regexScrub — redacts email addresses", () => {
  const r = regexScrub("Minu email maria.makinen@example.com");
  assertStringIncludes(r.text, "[EMAIL]");
  assert(!r.text.includes("@example.com"));
  assertEquals(r.replacements["[EMAIL]"], 1);
});

Deno.test("regexScrub — redacts Estonian ID code (isikukood)", () => {
  const r = regexScrub("Minu isikukood on 39001011234, tänan");
  assertStringIncludes(r.text, "[ID_EE]");
  assert(!r.text.includes("39001011234"));
  assertEquals(r.replacements["[ID_EE]"], 1);
});

Deno.test("regexScrub — redacts Finnish HETU", () => {
  const r = regexScrub("HETU 010180-123A puuttuu hakemuksesta");
  assertStringIncludes(r.text, "[HETU_FI]");
  assert(!r.text.includes("010180-123A"));
});

Deno.test("regexScrub — redacts R-prefixed case number", () => {
  const r = regexScrub("Käräjäoikeus, asia R-24/00123 alkaa huomenna");
  assertStringIncludes(r.text, "[CASE_NO]");
  assert(!r.text.includes("R-24/00123"));
});

Deno.test("regexScrub — redacts Estonian surname suffix", () => {
  const r = regexScrub("Vastaaja Jaanus Saarmäki kiisti syytteen");
  // Either "Saarmäki" matched as one or both suffix names matched.
  assertStringIncludes(r.text, "[NAME]");
  assertEquals(r.text.includes("Saarmäki"), false);
});

Deno.test("regexScrub — PRESERVES KHO public-record citation", () => {
  // KHO 2024:25 is a public legal reference and must survive.
  const r = regexScrub("Korkein hallinto-oikeus KHO 2024:25 vahvisti, että ...");
  assertStringIncludes(r.text, "KHO 2024:25");
});

Deno.test("regexScrub — PRESERVES RKHKo public-record citation", () => {
  const r = regexScrub("Riigikohus RKHKo 3-3-1-99-2024 kohta 5 sätestab ...");
  assertStringIncludes(r.text, "RKHKo");
  // The exact case-id format (3-3-1-99-2024) does not match [RH]-NN/NNNN,
  // and is therefore preserved.
  assertStringIncludes(r.text, "3-3-1-99-2024");
});

Deno.test("regexScrub — combined fixture (multi-PII paragraph)", () => {
  const input =
    "Vastaaja Maria Mäkinen, +358 50 555 7777, maria@example.com, " +
    "HETU 010180-123A, asia R-24/00123. Viittaan KHO 2024:25 perusteluihin.";
  const r = regexScrub(input);
  assertStringIncludes(r.text, "[PHONE]");
  assertStringIncludes(r.text, "[EMAIL]");
  assertStringIncludes(r.text, "[HETU_FI]");
  assertStringIncludes(r.text, "[CASE_NO]");
  assertStringIncludes(r.text, "[NAME]");
  // Public citation preserved.
  assertStringIncludes(r.text, "KHO 2024:25");
  // Original PII strings gone.
  assert(!r.text.includes("maria@example.com"));
  assert(!r.text.includes("010180-123A"));
  assert(!r.text.includes("R-24/00123"));
});

// ─── twoStageScrub fallback ─────────────────────────────────────────────────

Deno.test("twoStageScrub — no anthropic key falls back to regex-only", async () => {
  const r = await twoStageScrub({
    text: "Email maria@example.com, tel +358 50 123 4567",
    anthropicApiKey: undefined,
  });
  assertStringIncludes(r.text, "[EMAIL]");
  assertStringIncludes(r.text, "[PHONE]");
});

Deno.test("twoStageScrub — surfaces regex replacement counts", async () => {
  const r = await twoStageScrub({
    text: "Two emails: a@b.co and c@d.ee",
    anthropicApiKey: undefined,
  });
  assertEquals(r.replacements["[EMAIL]"], 2);
});
