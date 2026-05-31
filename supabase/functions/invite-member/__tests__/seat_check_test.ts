// invite-member/__tests__/seat_check_test.ts
// -----------------------------------------------------------------------------
// Pure-function tests for the invite-time seat bound. No network, no Supabase.
//
// Run:
//   deno test --allow-net --allow-env --allow-read \
//     supabase/functions/invite-member/__tests__/seat_check_test.ts
// -----------------------------------------------------------------------------

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { wouldExceedSeats } from "../seatCheck.ts";

// ─── below limit — admit ──────────────────────────────────────────────────
Deno.test("SEAT-OK-01 — empty org, room for one", () => {
  assertEquals(wouldExceedSeats(0, 0, 5), false);
});

Deno.test("SEAT-OK-02 — seats + pending below limit", () => {
  // 1 seat + 2 pending = 3; +1 = 4 <= 5
  assertEquals(wouldExceedSeats(1, 2, 5), false);
});

// ─── at-limit boundary ──────────────────────────────────────────────────────
Deno.test("SEAT-BOUNDARY-01 — last free seat is admitted", () => {
  // 1 seat + 3 pending = 4; +1 = 5 == limit -> still allowed
  assertEquals(wouldExceedSeats(1, 3, 5), false);
});

Deno.test("SEAT-BOUNDARY-02 — one past the last seat is rejected", () => {
  // 1 seat + 4 pending = 5; +1 = 6 > 5 -> reject (the bug scenario)
  assertEquals(wouldExceedSeats(1, 4, 5), true);
});

// ─── the original defect: seats alone fit, pending push over ────────────────
Deno.test("SEAT-DEFECT-01 — pending invites are counted (old check missed this)", () => {
  // seat_count=1, limit=5: old check (1+1>5) = false would let this through;
  // with 4 pending already queued it must now reject.
  assertEquals(wouldExceedSeats(1, 4, 5), true);
});

// ─── over limit ─────────────────────────────────────────────────────────────
Deno.test("SEAT-OVER-01 — seats alone already at limit", () => {
  assertEquals(wouldExceedSeats(5, 0, 5), true);
});

// ─── nullish-safety (mirrors `?? 0` upstream) ───────────────────────────────
Deno.test("SEAT-NULL-01 — undefined coerces to 0", () => {
  assertEquals(
    wouldExceedSeats(
      undefined as unknown as number,
      undefined as unknown as number,
      5,
    ),
    false,
  );
});
