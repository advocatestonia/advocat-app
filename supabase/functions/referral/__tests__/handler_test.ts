// referral/__tests__/handler_test.ts
// -----------------------------------------------------------------------------
// Tests for handler.ts — routes hit a fake Supabase client.
//
// Run:
//   deno test --allow-read --allow-env \
//     supabase/functions/referral/__tests__/handler_test.ts
// -----------------------------------------------------------------------------

import {
  assertEquals,
  assertExists,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  handleAttribute,
  handleCode,
  handleStats,
  routeReferral,
} from "../handler.ts";
import { emptyState, makeFakeSb } from "./_fakes.ts";

// ─── handleCode ─────────────────────────────────────────────────────────────

Deno.test("CODE-T01 — handleCode generates new code first time", async () => {
  const state = emptyState();
  const sb = makeFakeSb(state);
  const res = await handleCode(sb, "user-1");
  assertEquals(res.status, 200);
  assertExists(res.body.code);
  assertStringIncludes(String(res.body.share_url), "advocat.ee/r/");
  assertEquals(state.referral_codes.length, 1);
});

Deno.test("CODE-T02 — handleCode returns existing code on second call", async () => {
  const state = emptyState();
  const sb = makeFakeSb(state);
  const first = await handleCode(sb, "user-1");
  const second = await handleCode(sb, "user-1");
  assertEquals(first.body.code, second.body.code);
  assertEquals(state.referral_codes.length, 1);
});

// ─── handleAttribute ────────────────────────────────────────────────────────

Deno.test("ATTR-T01 — missing code → 400", async () => {
  const sb = makeFakeSb(emptyState());
  const res = await handleAttribute(sb, "user-2", {});
  assertEquals(res.status, 400);
  assertEquals(res.body.error, "missing_referral_code");
});

Deno.test("ATTR-T02 — malformed code → 400", async () => {
  const sb = makeFakeSb(emptyState());
  const res = await handleAttribute(sb, "user-2", { referral_code: "BAD!" });
  assertEquals(res.status, 400);
  assertEquals(res.body.error, "invalid_referral_code");
});

Deno.test("ATTR-T03 — unknown code → 404", async () => {
  const sb = makeFakeSb(emptyState());
  const res = await handleAttribute(sb, "user-2", {
    referral_code: "abc12345",
  });
  assertEquals(res.status, 404);
});

Deno.test("ATTR-T04 — self-referral rejected", async () => {
  const state = emptyState();
  state.referral_codes.push({
    user_id: "user-1",
    code: "abc12345",
    total_invites_sent: 0,
    total_conversions: 0,
    total_free_months_earned: 0,
  });
  const sb = makeFakeSb(state);
  const res = await handleAttribute(sb, "user-1", {
    referral_code: "abc12345",
  });
  assertEquals(res.status, 400);
  assertEquals(res.body.error, "self_referral");
});

Deno.test("ATTR-T05 — happy path creates attribution row", async () => {
  const state = emptyState();
  state.referral_codes.push({
    user_id: "inviter-1",
    code: "abc12345",
    total_invites_sent: 0,
    total_conversions: 0,
    total_free_months_earned: 0,
  });
  const sb = makeFakeSb(state);
  const res = await handleAttribute(sb, "referred-1", {
    referral_code: "abc12345",
  });
  assertEquals(res.status, 200);
  assertEquals(res.body.inviter_user_id, "inviter-1");
  assertEquals(state.referral_attributions.length, 1);
  assertEquals(state.referral_attributions[0].status, "attributed");
  assertEquals(state.referral_codes[0].total_invites_sent, 1);
});

Deno.test("ATTR-T06 — idempotent: second claim returns already_attributed", async () => {
  const state = emptyState();
  state.referral_codes.push({
    user_id: "inviter-1",
    code: "abc12345",
    total_invites_sent: 0,
    total_conversions: 0,
    total_free_months_earned: 0,
  });
  const sb = makeFakeSb(state);
  await handleAttribute(sb, "referred-1", { referral_code: "abc12345" });
  const second = await handleAttribute(sb, "referred-1", {
    referral_code: "abc12345",
  });
  assertEquals(second.status, 200);
  assertEquals(second.body.already_attributed, true);
  assertEquals(state.referral_attributions.length, 1);
});

Deno.test("ATTR-T07 — code normalised to lowercase + trimmed", async () => {
  const state = emptyState();
  state.referral_codes.push({
    user_id: "inviter-1",
    code: "abc12345",
    total_invites_sent: 0,
    total_conversions: 0,
    total_free_months_earned: 0,
  });
  const sb = makeFakeSb(state);
  const res = await handleAttribute(sb, "referred-1", {
    referral_code: "  ABC12345  ",
  });
  assertEquals(res.status, 200);
  assertEquals(res.body.inviter_user_id, "inviter-1");
});

// ─── handleStats ────────────────────────────────────────────────────────────

Deno.test("STATS-T01 — no code yet → null fields", async () => {
  const sb = makeFakeSb(emptyState());
  const res = await handleStats(sb, "user-1");
  assertEquals(res.status, 200);
  assertEquals(res.body.code, null);
  assertEquals(res.body.invites_sent, 0);
});

Deno.test("STATS-T02 — counts attributions correctly", async () => {
  const state = emptyState();
  state.referral_codes.push({
    user_id: "inviter-1",
    code: "abc12345",
    total_invites_sent: 3,
    total_conversions: 2,
    total_free_months_earned: 1,
  });
  state.referral_attributions.push(
    {
      id: "a1",
      inviter_user_id: "inviter-1",
      referred_user_id: "r1",
      referral_code: "abc12345",
      attributed_at: "2026-05-01",
      converted_at: "2026-05-02",
      free_month_credited_at: "2026-05-03",
      status: "credited",
      metadata: {},
    },
    {
      id: "a2",
      inviter_user_id: "inviter-1",
      referred_user_id: "r2",
      referral_code: "abc12345",
      attributed_at: "2026-05-01",
      converted_at: "2026-05-02",
      free_month_credited_at: null,
      status: "converted",
      metadata: {},
    },
    {
      id: "a3",
      inviter_user_id: "inviter-1",
      referred_user_id: "r3",
      referral_code: "abc12345",
      attributed_at: "2026-05-01",
      converted_at: null,
      free_month_credited_at: null,
      status: "attributed",
      metadata: {},
    },
  );
  const sb = makeFakeSb(state);
  const res = await handleStats(sb, "inviter-1");
  assertEquals(res.status, 200);
  assertEquals(res.body.invites_sent, 3);
  const computed = res.body.computed as Record<string, number>;
  assertEquals(computed.attributions, 3);
  assertEquals(computed.conversions, 2);
  assertEquals(computed.credited, 1);
});

// ─── routeReferral ──────────────────────────────────────────────────────────

Deno.test("ROUTE-T01 — unknown action → 404", async () => {
  const sb = makeFakeSb(emptyState());
  const res = await routeReferral(sb, {
    action: "delete-everything",
    userId: "u1",
    body: {},
  });
  assertEquals(res.status, 404);
});

Deno.test("ROUTE-T02 — code action dispatches to handleCode", async () => {
  const sb = makeFakeSb(emptyState());
  const res = await routeReferral(sb, {
    action: "code",
    userId: "u1",
    body: {},
  });
  assertEquals(res.status, 200);
  assertExists(res.body.code);
});
