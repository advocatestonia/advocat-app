// gold-scrubber/__tests__/gold_scrubber_test.ts
// -----------------------------------------------------------------------------
// Regression for the batch-size clamp. gold-scrubber is service-role-only and
// its PostgREST URLs interpolate only trusted ids (row.id from our own DB) — the
// one external knob is ?batch=, which clampInt bounds to [1,500] (default 100)
// so a hostile/garbage value can't fetch an unbounded queue slice or fan out a
// huge number of billed Haiku scrub calls. These tests lock that cap.
//
// Run:
//   deno test --allow-read \
//     supabase/functions/gold-scrubber/__tests__/gold_scrubber_test.ts
// -----------------------------------------------------------------------------

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { clampInt } from "../clamp.ts";

Deno.test("CLAMP-01 — null / empty → fallback", () => {
  assertEquals(clampInt(null, 1, 500, 100), 100);
  assertEquals(clampInt("", 1, 500, 100), 100);
});

Deno.test("CLAMP-02 — in-range value passes through", () => {
  assertEquals(clampInt("250", 1, 500, 100), 250);
  assertEquals(clampInt("1", 1, 500, 100), 1);
  assertEquals(clampInt("500", 1, 500, 100), 500);
});

Deno.test("CLAMP-03 — below min / above max are clamped", () => {
  assertEquals(clampInt("0", 1, 500, 100), 1);
  assertEquals(clampInt("-9999", 1, 500, 100), 1);
  assertEquals(clampInt("100000", 1, 500, 100), 500);
});

Deno.test("CLAMP-04 — non-numeric / NaN → fallback", () => {
  assertEquals(clampInt("abc", 1, 500, 100), 100);
  assertEquals(clampInt("NaN", 1, 500, 100), 100);
  assertEquals(clampInt("1e999", 1, 500, 100), 1); // parseInt("1e999")=1 → in range
});

Deno.test("CLAMP-05 — parseInt leniency: trailing junk uses leading digits", () => {
  // parseInt stops at the first non-digit, so "12abc" → 12 (still bounded).
  assertEquals(clampInt("12abc", 1, 500, 100), 12);
  assertEquals(clampInt("9999x", 1, 500, 100), 500);
});
