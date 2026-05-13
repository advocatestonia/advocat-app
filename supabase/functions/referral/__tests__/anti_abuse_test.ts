// referral/__tests__/anti_abuse_test.ts
// -----------------------------------------------------------------------------
// Pure-function tests for shouldBlockForAbuse(). No IO.
//
// Run:
//   deno test --allow-read --allow-env \
//     supabase/functions/referral/__tests__/anti_abuse_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  ABUSE_WINDOW_MS,
  MAX_FREE_MONTHS_PER_YEAR,
  shouldBlockForAbuse,
} from "../anti_abuse.ts";

Deno.test("AB-T01 — empty history → allow with 0", () => {
  const out = shouldBlockForAbuse([]);
  assertEquals(out.kind, "allow");
  if (out.kind === "allow") assertEquals(out.recentCreditCount, 0);
});

Deno.test("AB-T02 — 11 credits in window → allow", () => {
  const now = new Date("2026-06-01T00:00:00Z");
  const recent = Array.from(
    { length: 11 },
    (_, i) => new Date(now.getTime() - i * 24 * 60 * 60 * 1000).toISOString(),
  );
  const out = shouldBlockForAbuse(recent, now);
  assertEquals(out.kind, "allow");
});

Deno.test("AB-T03 — 12 credits in window → block (cap inclusive)", () => {
  const now = new Date("2026-06-01T00:00:00Z");
  const recent = Array.from(
    { length: MAX_FREE_MONTHS_PER_YEAR },
    (_, i) => new Date(now.getTime() - i * 24 * 60 * 60 * 1000).toISOString(),
  );
  const out = shouldBlockForAbuse(recent, now);
  assertEquals(out.kind, "block");
  if (out.kind === "block") {
    assertEquals(out.recentCreditCount, 12);
  }
});

Deno.test("AB-T04 — old credits outside 365d ignored", () => {
  const now = new Date("2026-06-01T00:00:00Z");
  const recent = Array.from(
    { length: 11 },
    (_, i) => new Date(now.getTime() - i * 24 * 60 * 60 * 1000).toISOString(),
  );
  const ancient = Array.from(
    { length: 5 },
    (_, i) =>
      new Date(
        now.getTime() - ABUSE_WINDOW_MS - (i + 1) * 24 * 60 * 60 * 1000,
      ).toISOString(),
  );
  const out = shouldBlockForAbuse([...recent, ...ancient], now);
  assertEquals(out.kind, "allow");
  if (out.kind === "allow") assertEquals(out.recentCreditCount, 11);
});

Deno.test("AB-T05 — garbage timestamps tolerated", () => {
  const out = shouldBlockForAbuse(["not-a-date", "", "2026"]);
  assert(out.kind === "allow" || out.kind === "block");
});

Deno.test("AB-T06 — 13 credits → block with windowStart/windowEnd", () => {
  const now = new Date("2026-06-01T00:00:00Z");
  const recent = Array.from(
    { length: 13 },
    (_, i) => new Date(now.getTime() - i * 24 * 60 * 60 * 1000).toISOString(),
  );
  const out = shouldBlockForAbuse(recent, now);
  assertEquals(out.kind, "block");
  if (out.kind === "block") {
    assertEquals(out.recentCreditCount, 13);
    // windowStart should be exactly 365 days before windowEnd.
    const span = new Date(out.windowEnd).getTime() -
      new Date(out.windowStart).getTime();
    assertEquals(span, ABUSE_WINDOW_MS);
  }
});
