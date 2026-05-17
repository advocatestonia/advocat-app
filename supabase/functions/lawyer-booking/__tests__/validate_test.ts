// lawyer-booking/__tests__/validate_test.ts
// -----------------------------------------------------------------------------
// Pure-function tests for the request validator. No network, no Supabase.
//
// Run:
//   deno test --allow-read --allow-env \
//     supabase/functions/lawyer-booking/__tests__/validate_test.ts
// -----------------------------------------------------------------------------

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { validateBody } from "../validate.ts";

const VALID_UUID = "11111111-1111-4111-8111-111111111111";

// ─── op:create — happy paths ────────────────────────────────────────────────

Deno.test("CRT-OK-01 — minimal create with topic only", () => {
  const out = validateBody({ op: "create", topic: "Contract" });
  assertEquals(out.kind, "ok");
  if (out.kind === "ok" && out.body.op === "create") {
    assertEquals(out.body.topic, "contract"); // normalised
    assertEquals(out.body.language, "et"); // default
    assertEquals(out.body.lawyerId, null);
    assertEquals(out.body.caseId, null);
    assertEquals(out.body.scheduledAt, null);
  }
});

Deno.test("CRT-OK-02 — full create with all fields", () => {
  const future = new Date(Date.now() + 3 * 24 * 3600 * 1000).toISOString();
  const out = validateBody({
    op: "create",
    topic: "immigration",
    language: "EN",
    lawyer_id: VALID_UUID,
    case_id: VALID_UUID,
    scheduled_at: future,
    user_brief: "Lost my residence permit appeal, want to discuss KHO options.",
    time_preference: "Mornings any day next week",
  });
  assertEquals(out.kind, "ok");
  if (out.kind === "ok" && out.body.op === "create") {
    assertEquals(out.body.topic, "immigration");
    assertEquals(out.body.language, "en");
    assertEquals(out.body.lawyerId, VALID_UUID);
    assertEquals(out.body.caseId, VALID_UUID);
    assertEquals(typeof out.body.scheduledAt, "string");
  }
});

Deno.test("CRT-OK-03 — free-form topic is kept as-is", () => {
  const out = validateBody({ op: "create", topic: "Mortgage refinancing" });
  assertEquals(out.kind, "ok");
  if (out.kind === "ok" && out.body.op === "create") {
    assertEquals(out.body.topic, "Mortgage refinancing");
  }
});

// ─── op:create — rejection paths ────────────────────────────────────────────

Deno.test("CRT-FAIL-01 — topic too short → bad_topic", () => {
  const out = validateBody({ op: "create", topic: "AB" });
  assertEquals(out.kind, "error");
  if (out.kind === "error") assertEquals(out.payload.reason, "bad_topic");
});

Deno.test("CRT-FAIL-02 — topic too long → bad_topic", () => {
  const out = validateBody({ op: "create", topic: "x".repeat(101) });
  assertEquals(out.kind, "error");
  if (out.kind === "error") assertEquals(out.payload.reason, "bad_topic");
});

Deno.test("CRT-FAIL-03 — bad language code → bad_language", () => {
  const out = validateBody({
    op: "create",
    topic: "family",
    language: "english",
  });
  assertEquals(out.kind, "error");
  if (out.kind === "error") assertEquals(out.payload.reason, "bad_language");
});

Deno.test("CRT-FAIL-04 — non-UUID lawyer_id → bad_lawyer_id", () => {
  const out = validateBody({
    op: "create",
    topic: "family",
    lawyer_id: "not-a-uuid",
  });
  assertEquals(out.kind, "error");
  if (out.kind === "error") assertEquals(out.payload.reason, "bad_lawyer_id");
});

Deno.test("CRT-FAIL-05 — non-UUID case_id → bad_case_id", () => {
  const out = validateBody({
    op: "create",
    topic: "family",
    case_id: "case-007",
  });
  assertEquals(out.kind, "error");
  if (out.kind === "error") assertEquals(out.payload.reason, "bad_case_id");
});

Deno.test("CRT-FAIL-06 — scheduled_at in the past → scheduled_in_past", () => {
  const past = new Date(Date.now() - 24 * 3600 * 1000).toISOString();
  const out = validateBody({
    op: "create",
    topic: "family",
    scheduled_at: past,
  });
  assertEquals(out.kind, "error");
  if (out.kind === "error") {
    assertEquals(out.payload.reason, "scheduled_in_past");
  }
});

Deno.test("CRT-FAIL-07 — scheduled_at > 60 days → scheduled_too_far", () => {
  const far = new Date(Date.now() + 90 * 24 * 3600 * 1000).toISOString();
  const out = validateBody({
    op: "create",
    topic: "family",
    scheduled_at: far,
  });
  assertEquals(out.kind, "error");
  if (out.kind === "error") {
    assertEquals(out.payload.reason, "scheduled_too_far");
  }
});

Deno.test("CRT-FAIL-08 — scheduled_at unparseable → bad_scheduled_at", () => {
  const out = validateBody({
    op: "create",
    topic: "family",
    scheduled_at: "tomorrow morning",
  });
  assertEquals(out.kind, "error");
  if (out.kind === "error") {
    assertEquals(out.payload.reason, "bad_scheduled_at");
  }
});

Deno.test("CRT-FAIL-09 — overlong user_brief → user_brief_too_long", () => {
  const out = validateBody({
    op: "create",
    topic: "family",
    user_brief: "x".repeat(4001),
  });
  assertEquals(out.kind, "error");
  if (out.kind === "error") {
    assertEquals(out.payload.reason, "user_brief_too_long");
  }
});

// ─── op:outcome ─────────────────────────────────────────────────────────────

Deno.test("OUT-OK-01 — minimal outcome", () => {
  const out = validateBody({
    op: "outcome",
    booking_id: VALID_UUID,
    outcome_summary: "Discussed appeal options. Recommended Track B.",
  });
  assertEquals(out.kind, "ok");
  if (out.kind === "ok" && out.body.op === "outcome") {
    assertEquals(out.body.bookingId, VALID_UUID);
  }
});

Deno.test("OUT-FAIL-01 — outcome too short → bad_outcome_summary", () => {
  const out = validateBody({
    op: "outcome",
    booking_id: VALID_UUID,
    outcome_summary: "ok",
  });
  assertEquals(out.kind, "error");
  if (out.kind === "error") {
    assertEquals(out.payload.reason, "bad_outcome_summary");
  }
});

Deno.test("OUT-FAIL-02 — missing booking_id → bad_booking_id", () => {
  const out = validateBody({
    op: "outcome",
    outcome_summary: "Discussed appeal options.",
  });
  assertEquals(out.kind, "error");
  if (out.kind === "error") assertEquals(out.payload.reason, "bad_booking_id");
});

// ─── op:rate ────────────────────────────────────────────────────────────────

Deno.test("RAT-OK-01 — rating with feedback", () => {
  const out = validateBody({
    op: "rate",
    booking_id: VALID_UUID,
    user_rating: 5,
    user_feedback: "Very useful — saved hours.",
  });
  assertEquals(out.kind, "ok");
  if (out.kind === "ok" && out.body.op === "rate") {
    assertEquals(out.body.userRating, 5);
    assertEquals(out.body.userFeedback, "Very useful — saved hours.");
  }
});

Deno.test("RAT-OK-02 — rating without feedback", () => {
  const out = validateBody({
    op: "rate",
    booking_id: VALID_UUID,
    user_rating: 3,
  });
  assertEquals(out.kind, "ok");
  if (out.kind === "ok" && out.body.op === "rate") {
    assertEquals(out.body.userFeedback, null);
  }
});

Deno.test("RAT-FAIL-01 — rating out of range → bad_user_rating", () => {
  const out = validateBody({
    op: "rate",
    booking_id: VALID_UUID,
    user_rating: 6,
  });
  assertEquals(out.kind, "error");
  if (out.kind === "error") assertEquals(out.payload.reason, "bad_user_rating");
});

Deno.test("RAT-FAIL-02 — rating non-integer → bad_user_rating", () => {
  const out = validateBody({
    op: "rate",
    booking_id: VALID_UUID,
    user_rating: 4.5,
  });
  assertEquals(out.kind, "error");
  if (out.kind === "error") assertEquals(out.payload.reason, "bad_user_rating");
});

// ─── op:cancel ──────────────────────────────────────────────────────────────

Deno.test("CAN-OK-01 — cancel minimal", () => {
  const out = validateBody({ op: "cancel", booking_id: VALID_UUID });
  assertEquals(out.kind, "ok");
  if (out.kind === "ok" && out.body.op === "cancel") {
    assertEquals(out.body.bookingId, VALID_UUID);
  }
});

Deno.test("CAN-FAIL-01 — missing booking_id → bad_booking_id", () => {
  const out = validateBody({ op: "cancel" });
  assertEquals(out.kind, "error");
  if (out.kind === "error") assertEquals(out.payload.reason, "bad_booking_id");
});

// ─── Dispatch ───────────────────────────────────────────────────────────────

Deno.test("DSP-FAIL-01 — unknown op → bad_op", () => {
  const out = validateBody({ op: "delete" });
  assertEquals(out.kind, "error");
  if (out.kind === "error") assertEquals(out.payload.reason, "bad_op");
});

Deno.test("DSP-OK-01 — missing op defaults to create", () => {
  const out = validateBody({ topic: "Family" });
  assertEquals(out.kind, "ok");
  if (out.kind === "ok") assertEquals(out.body.op, "create");
});
