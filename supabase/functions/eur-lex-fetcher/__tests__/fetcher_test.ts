// Deno tests for eur-lex-fetcher/fetcher.ts
// -----------------------------------------------------------------------------
// Pure-function tests for URL construction + CELEX validation. The actual
// HTTP fetch is not exercised here — it requires network and would couple
// the test suite to EUR-Lex availability. Use a manual smoke run for that.
// -----------------------------------------------------------------------------

import {
  assertEquals,
  assertRejects,
  assertStrictEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import { buildEurLexUrl, EurLexFetchError, fetchEurLex } from "../fetcher.ts";

// =============================================================================
// 1. URL construction
// =============================================================================

Deno.test("EL-F01 — buildEurLexUrl for directive (32004L0038), EN", () => {
  const url = buildEurLexUrl("32004L0038", "EN");
  assertEquals(
    url,
    "https://publications.europa.eu/resource/celex/32004L0038",
  );
});

Deno.test("EL-F02 — buildEurLexUrl is language-independent (lang goes in Accept-Language header)", () => {
  // 2026-05 migration: switched off eur-lex.europa.eu (WAF-blocked) to
  // publications.europa.eu/CELLAR, where language is negotiated via the
  // Accept-Language header (eng/fin/est), not the URL.
  const en = buildEurLexUrl("32016R0679", "EN");
  const fi = buildEurLexUrl("32016R0679", "FI");
  const et = buildEurLexUrl("32016R0679", "ET");
  assertEquals(en, "https://publications.europa.eu/resource/celex/32016R0679");
  assertEquals(fi, en);
  assertEquals(et, en);
});

// =============================================================================
// 2. CELEX format validation
// =============================================================================

Deno.test("EL-F10 — fetchEurLex rejects invalid CELEX format", async () => {
  await assertRejects(
    () => fetchEurLex("not-a-celex", "EN"),
    EurLexFetchError,
    "Invalid CELEX format",
  );
});

Deno.test("EL-F11 — fetchEurLex accepts dated-consolidation CELEX", () => {
  // Dated CELEX form: "02004L0038-20210801" — won't actually fetch in test,
  // but should pass the regex gate (we mock the fetch by aborting).
  const ctrl = new AbortController();
  ctrl.abort("test"); // pre-aborted — fetch will throw, but NOT for format reasons
  return fetchEurLex("02004L0038-20210801", "EN", { signal: ctrl.signal })
    .then(() => {
      throw new Error("should have rejected on abort, not resolved");
    })
    .catch((e) => {
      // The error name should NOT be EurLexFetchError("Invalid CELEX format")
      const msg = String(e);
      assertStrictEquals(msg.includes("Invalid CELEX format"), false);
    });
});

Deno.test("EL-F12 — fetchEurLex rejects all-lowercase CELEX", async () => {
  await assertRejects(() => fetchEurLex("32004l0038", "EN"), EurLexFetchError);
});

Deno.test("EL-F13 — fetchEurLex rejects too-short CELEX", async () => {
  await assertRejects(() => fetchEurLex("3200", "EN"), EurLexFetchError);
});
