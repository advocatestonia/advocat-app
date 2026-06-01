// check-vehicle/__tests__/check_vehicle_test.ts
// -----------------------------------------------------------------------------
// Boundary-guard regression for the vehicle-lookup inputs.
//
//   * normalizeCountry — 2-letter codes upcased, EN/native names mapped, unknown
//     and empty fall back to "EE" (so a bad country never crashes the handler).
//   * isPlateValid — gates the plate before it is interpolated into the LKF POST
//     body. Asserts length bounds (3–12) and that only Latin/Cyrillic letters,
//     digits, hyphen and space pass; control chars, CRLF and injection-y payloads
//     are rejected so nothing hostile reaches the upstream form.
//
// Run:
//   deno test --allow-read \
//     supabase/functions/check-vehicle/__tests__/check_vehicle_test.ts
// -----------------------------------------------------------------------------

import { assert, assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { isPlateValid, normalizeCountry } from "../validate.ts";

Deno.test("NC-01 — 2-letter codes are upper-cased", () => {
  assertEquals(normalizeCountry("ee"), "EE");
  assertEquals(normalizeCountry("fi"), "FI");
  assertEquals(normalizeCountry("DE"), "DE");
});

Deno.test("NC-02 — EN / native names are mapped", () => {
  assertEquals(normalizeCountry("Estonia"), "EE");
  assertEquals(normalizeCountry("suomi"), "FI");
  assertEquals(normalizeCountry("Deutschland"), "DE");
  assertEquals(normalizeCountry("  Sverige  "), "SE");
});

Deno.test("NC-03 — empty / unknown falls back to EE", () => {
  assertEquals(normalizeCountry(null), "EE");
  assertEquals(normalizeCountry(undefined), "EE");
  assertEquals(normalizeCountry(""), "EE");
  assertEquals(normalizeCountry("Narnia"), "EE");
});

Deno.test("PV-01 — well-formed plates accepted (EE/FI/Cyrillic)", () => {
  for (const ok of ["123ABC", "ABC-123", "AB 1234", "АВ123", "1234567890AB"]) {
    assert(isPlateValid(ok), `expected ${ok} valid`);
  }
});

Deno.test("PV-02 — length bounds enforced (3–12)", () => {
  assert(!isPlateValid("AB")); // 2 chars
  assert(!isPlateValid("")); // empty
  assert(!isPlateValid("ABCDEFGHIJKLM")); // 13 chars
});

Deno.test("PV-03 — control chars / CRLF / injection payloads rejected", () => {
  for (
    const bad of [
      "123\nABC",
      "123\r\nSet-Cookie: x",
      "12<script>",
      "12&p_key=evil",
      "12;DROP",
      "12/../34",
      "плейт😀",
      "12\t34",
    ]
  ) {
    assert(!isPlateValid(bad), `expected ${JSON.stringify(bad)} rejected`);
  }
});
