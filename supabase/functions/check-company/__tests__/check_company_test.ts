// check-company/__tests__/check_company_test.ts
// -----------------------------------------------------------------------------
// SSRF-invariant regression for the only server-side scrape input.
//
// check-company server-fetches exactly one upstream-influenced URL:
//   https://ariregister.rik.ee/est/company/${safeRegCode}
// where safeRegCode comes ONLY from isSafeRegistryCode(). The upstream-supplied
// `url` field is never server-fetched (surfaced to the client as check_url, a
// browser link). These tests lock the gate: only 4–12 ASCII digits may flow
// into that path; anything else (traversal, host-injection, letters, empty,
// non-string) is rejected, so no off-host or path-escaping fetch is possible.
//
// Run:
//   deno test --allow-read \
//     supabase/functions/check-company/__tests__/check_company_test.ts
// -----------------------------------------------------------------------------

import { assert } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { isSafeRegistryCode } from "../ssrf.ts";

Deno.test("SSRF-01 — well-formed registry codes (4–12 digits) pass", () => {
  for (const ok of ["1234", "12345678", "123456789012", "31222517"]) {
    assert(isSafeRegistryCode(ok), `expected ${ok} to be safe`);
  }
});

Deno.test("SSRF-02 — too short / too long rejected", () => {
  assert(!isSafeRegistryCode("123")); // 3 digits
  assert(!isSafeRegistryCode("1234567890123")); // 13 digits
  assert(!isSafeRegistryCode("")); // empty
});

Deno.test("SSRF-03 — path traversal / host injection rejected", () => {
  for (
    const bad of [
      "../../etc/passwd",
      "12345/../../../admin",
      "12345?x=1",
      "12345#frag",
      "12345/extra",
      "//evil.com",
      "https://evil.com/12345",
      "12345 ",
      " 12345",
      "12345\n",
    ]
  ) {
    assert(!isSafeRegistryCode(bad), `expected ${JSON.stringify(bad)} rejected`);
  }
});

Deno.test("SSRF-04 — letters / unicode digits / mixed rejected", () => {
  for (const bad of ["12a45", "abcd", "12345€", "١٢٣٤", "12 34"]) {
    assert(!isSafeRegistryCode(bad), `expected ${JSON.stringify(bad)} rejected`);
  }
});

Deno.test("SSRF-05 — non-string inputs rejected (no throw)", () => {
  for (const bad of [null, undefined, 12345, {}, [], true, NaN]) {
    assert(!isSafeRegistryCode(bad as unknown));
  }
});
