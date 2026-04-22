// Deno TDD — shared refund_policy.ts
// -----------------------------------------------------------------------------
// Mirrors the Dart RefundPolicy so the Edge Functions (check-refund-eligibility,
// stripe-webhook) and the Flutter client evaluate the same rule. Any change
// to one MUST be reflected in the other; these tests are the contract.
//
// Run with:
//   deno test --allow-read supabase/functions/_shared/__tests__/refund_policy_test.ts
// -----------------------------------------------------------------------------

import {
  assertEquals,
  assertStrictEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  computeDeadline,
  evaluateRefund,
  MESSAGE_CAP,
  type RefundReason,
  WITHDRAWAL_DAYS,
} from "../refund_policy.ts";

const subscribedAt = new Date("2026-04-01T12:00:00.000Z");
const dayAfter = new Date("2026-04-02T12:00:00.000Z");
const day15 = new Date("2026-04-16T12:00:00.001Z");
const day14ExactIso = new Date("2026-04-15T12:00:00.000Z"); // exactly +14d

Deno.test("RP-T01 — eligible within 14 days with 0 messages", () => {
  const r = evaluateRefund({
    subscribedAt,
    messagesUsed: 0,
    now: dayAfter,
  });
  assertStrictEquals(r.eligible, true);
  assertStrictEquals(r.reason, "eligible" satisfies RefundReason);
  assertStrictEquals(r.messagesRemaining, 7);
});

Deno.test("RP-T02 — NOT eligible once 7 messages consumed (boundary)", () => {
  const r = evaluateRefund({
    subscribedAt,
    messagesUsed: 7,
    now: dayAfter,
  });
  assertStrictEquals(r.eligible, false);
  assertStrictEquals(r.reason, "message_limit_reached" satisfies RefundReason);
  assertStrictEquals(r.messagesRemaining, 0);
});

Deno.test("RP-T03 — NOT eligible past 14-day deadline", () => {
  const r = evaluateRefund({
    subscribedAt,
    messagesUsed: 0,
    now: day15,
  });
  assertStrictEquals(r.eligible, false);
  assertStrictEquals(r.reason, "deadline_passed" satisfies RefundReason);
});

Deno.test("RP-T04 — exact +14d is still eligible (inclusive cutoff)", () => {
  const r = evaluateRefund({
    subscribedAt,
    messagesUsed: 0,
    now: day14ExactIso,
  });
  assertStrictEquals(r.eligible, true);
});

Deno.test("RP-T05 — message cap wins when both conditions breached", () => {
  const r = evaluateRefund({
    subscribedAt,
    messagesUsed: 10,
    now: new Date("2026-05-15T00:00:00.000Z"),
  });
  assertStrictEquals(r.eligible, false);
  assertStrictEquals(r.reason, "message_limit_reached" satisfies RefundReason);
});

Deno.test("RP-T06 — computeDeadline is subscribedAt + 14 days (UTC)", () => {
  const d = computeDeadline(subscribedAt);
  assertEquals(d.toISOString(), "2026-04-15T12:00:00.000Z");
});

Deno.test("RP-T07 — negative messagesUsed is clamped to 0", () => {
  const r = evaluateRefund({
    subscribedAt,
    messagesUsed: -5,
    now: dayAfter,
  });
  assertStrictEquals(r.eligible, true);
  assertStrictEquals(r.messagesRemaining, 7);
});

Deno.test("RP-T08 — constants match Dart side (contract)", () => {
  assertStrictEquals(MESSAGE_CAP, 7);
  assertStrictEquals(WITHDRAWAL_DAYS, 14);
});

Deno.test("RP-T09 — eligible with 6 messages reports 1 remaining", () => {
  const r = evaluateRefund({
    subscribedAt,
    messagesUsed: 6,
    now: dayAfter,
  });
  assertStrictEquals(r.eligible, true);
  assertStrictEquals(r.messagesRemaining, 1);
});

Deno.test("RP-T10 — deadline returned even when not eligible (for UI)", () => {
  const r = evaluateRefund({
    subscribedAt,
    messagesUsed: 7,
    now: dayAfter,
  });
  // UI can still show "window closed at ..." even when eligible=false.
  assertEquals(r.deadline.toISOString(), "2026-04-15T12:00:00.000Z");
});
