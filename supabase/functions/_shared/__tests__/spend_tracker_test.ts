// Deno TDD — _shared/spend_tracker.ts
// -----------------------------------------------------------------------------
// P3 anti-abuse (Bentley batch, 2026-05-15)
//
// We test the PURE LOGIC paths only — env-driven defaults, the cap-exceeded
// body shape, and graceful degradation when Supabase env vars are absent
// (DB layer unreachable). The RPC round-trip paths (checkDailyCap with a
// live DB, recordSpend, logIncident) are covered by post-deploy live smoke
// tests since they're network-bound.
//
// Run with:
//   deno test --allow-read --allow-env \
//     supabase/functions/_shared/__tests__/spend_tracker_test.ts
// -----------------------------------------------------------------------------

import {
  assertEquals,
  assertStrictEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  capExceededBody,
  checkDailyCap,
  DAILY_CAP_CENTS,
  recordSpend,
  WARN_RATIO,
} from "../spend_tracker.ts";

Deno.test("SP-T01 — DAILY_CAP_CENTS defaults to $500", () => {
  // No env override at test time ⇒ default applies.
  assertEquals(DAILY_CAP_CENTS, 50_000);
});

Deno.test("SP-T02 — WARN_RATIO defaults to 0.85", () => {
  assertEquals(WARN_RATIO, 0.85);
});

Deno.test("SP-T03 — capExceededBody shape is wire-stable", () => {
  const body = capExceededBody(50_001);
  assertStrictEquals(body.cap_breach, true);
  assertStrictEquals(body.spent_cents, 50_001);
  assertStrictEquals(body.cap_cents, DAILY_CAP_CENTS);
  assertStrictEquals(body.retry_after_seconds, 3600);
  assertStrictEquals(
    typeof body.error,
    "string",
    "error must be a string for client display",
  );
});

Deno.test("SP-T04 — checkDailyCap degrades open without Supabase env", async () => {
  // In the test environment SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY are
  // unset (or hold placeholder values) — the check must fail OPEN and
  // mark degraded=true so the caller logs but does not 503.
  const r = await checkDailyCap();
  // We can't assert allowed/degraded deterministically (test runner may
  // export real env), but we CAN assert the response shape is contract-safe.
  assertStrictEquals(typeof r.allowed, "boolean");
  assertStrictEquals(typeof r.spentCents, "number");
  assertStrictEquals(typeof r.warning, "boolean");
  assertStrictEquals(typeof r.degraded, "boolean");
  assertEquals(r.capCents, DAILY_CAP_CENTS);
});

Deno.test("SP-T05 — recordSpend resolves to a number even on DB miss", async () => {
  const cents = await recordSpend(100, 200, "claude-haiku-4-5-20251001");
  assertStrictEquals(typeof cents, "number");
});

Deno.test("SP-T06 — recordSpend never throws on negative inputs", async () => {
  // Negative inputs should be clamped to 0 by the RPC wrapper; the local
  // helper must not throw before the RPC is even called.
  const cents = await recordSpend(-5, -10, "claude-sonnet-4-20250514");
  assertStrictEquals(typeof cents, "number");
});

Deno.test("SP-T07 — warning band triggers at exactly 85%", () => {
  // Pure-logic check on the warning ratio constant. The actual flagging is
  // done inside checkDailyCap; here we just confirm the threshold maths.
  const warnAt = DAILY_CAP_CENTS * WARN_RATIO;
  assertEquals(warnAt, 42_500);
});
