// gmail-oauth-init/__tests__/state_test.ts
// -----------------------------------------------------------------------------
// Pure-function tests for the state-JWT helpers used by the side-channel
// Gmail OAuth flow. The state token is the *only* binding between
// gmail-oauth-init (which issues it) and gmail-oauth-exchange (which
// verifies it) — Supabase JWT is unavailable on the OAuth redirect, so the
// HMAC-signed state token is what proves the exchanger is talking about
// the same user-initiated flow.
//
// Token shape:
//   base64url(JSON(payload)) "." hex(HMAC-SHA-256(secret, base64url(payload)))
//
// Payload:
//   { user_id: string, exp_ms: number }
//
// TTL: 5 minutes by default.
//
// Run with:
//   deno test --allow-env --allow-net --allow-read \
//     supabase/functions/gmail-oauth-init/__tests__/state_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import { signState, verifyState } from "../state.ts";

const TEST_SECRET = "test-state-secret-do-not-use-in-prod-1234567890";
const USER_ID = "user-aaaa-bbbb-cccc-dddd-eeeeeeeeeeee";

// =============================================================================
// signState
// =============================================================================

Deno.test("signState — token has two segments joined by '.'", async () => {
  const token = await signState({ user_id: USER_ID }, TEST_SECRET);
  const parts = token.split(".");
  assertEquals(parts.length, 2);
  // base64url payload (no '=' padding, no '+/').
  assert(/^[A-Za-z0-9_-]+$/.test(parts[0]));
  // hex HMAC (64 chars = 256 bits / 4 bits-per-hex).
  assertEquals(parts[1].length, 64);
  assert(/^[a-f0-9]+$/.test(parts[1]));
});

Deno.test("signState — embeds user_id and 5-minute default TTL", async () => {
  const now = Date.UTC(2026, 4, 26, 12, 0, 0); // 2026-05-26T12:00:00Z
  const token = await signState(
    { user_id: USER_ID, now_ms: now },
    TEST_SECRET,
  );
  // Decode payload manually to assert exp_ms.
  const [b64u] = token.split(".");
  const json = atob(b64u.replace(/-/g, "+").replace(/_/g, "/"));
  const payload = JSON.parse(json);
  assertEquals(payload.user_id, USER_ID);
  // Default TTL = 5 minutes.
  assertEquals(payload.exp_ms, now + 5 * 60 * 1000);
});

// =============================================================================
// verifyState — happy path
// =============================================================================

Deno.test("verifyState — accepts a freshly signed token", async () => {
  const token = await signState({ user_id: USER_ID }, TEST_SECRET);
  const r = await verifyState(token, TEST_SECRET);
  assert(r.ok);
  if (r.ok) {
    assertEquals(r.user_id, USER_ID);
  }
});

// =============================================================================
// verifyState — rejection branches
// =============================================================================

Deno.test("verifyState — rejects token signed with a different secret", async () => {
  const token = await signState({ user_id: USER_ID }, TEST_SECRET);
  const r = await verifyState(token, "wrong-secret");
  assert(!r.ok);
  if (!r.ok) {
    assertStringIncludes(r.reason, "hmac");
  }
});

Deno.test("verifyState — rejects expired token", async () => {
  const past = Date.UTC(2026, 0, 1, 0, 0, 0); // 2026-01-01
  // 5-minute TTL → token exp is past + 5 min.
  const token = await signState(
    { user_id: USER_ID, now_ms: past },
    TEST_SECRET,
  );
  // Verify at "now" 10 minutes after exp — must reject.
  const future = past + 15 * 60 * 1000;
  const r = await verifyState(token, TEST_SECRET, future);
  assert(!r.ok);
  if (!r.ok) {
    assertStringIncludes(r.reason, "expired");
  }
});

Deno.test("verifyState — rejects malformed structure (no dot)", async () => {
  const r = await verifyState("not-a-token-without-dot", TEST_SECRET);
  assert(!r.ok);
  if (!r.ok) {
    assertStringIncludes(r.reason, "malformed");
  }
});

Deno.test("verifyState — rejects malformed payload (not JSON)", async () => {
  // base64url of "not json" + a fake hmac
  const badPayload = btoa("not json").replace(/=+$/, "").replace(/\+/g, "-")
    .replace(/\//g, "_");
  const r = await verifyState(`${badPayload}.deadbeef`, TEST_SECRET);
  assert(!r.ok);
});

Deno.test("verifyState — custom TTL is honoured", async () => {
  const t0 = Date.UTC(2026, 4, 26, 12, 0, 0);
  // 1 second TTL.
  const token = await signState(
    { user_id: USER_ID, now_ms: t0, ttl_ms: 1000 },
    TEST_SECRET,
  );
  // At t0+500 ms → still valid.
  const r1 = await verifyState(token, TEST_SECRET, t0 + 500);
  assert(r1.ok);
  // At t0+2 s → expired.
  const r2 = await verifyState(token, TEST_SECRET, t0 + 2000);
  assert(!r2.ok);
});
