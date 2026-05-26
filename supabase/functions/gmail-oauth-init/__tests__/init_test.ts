// gmail-oauth-init/__tests__/init_test.ts
// -----------------------------------------------------------------------------
// HTTP-handler tests for gmail-oauth-init. The handler is exported as a
// pure-ish function `handleInit({...})` so we can drive it without
// `serve()` grabbing port 8000 at module load.
//
// Tests:
//   (1) denies-without-auth          — requireUserWithRateLimit-equivalent
//   (2) returns Google authorize URL with prompt=consent + access_type=offline
//   (3) state token is bound to the authenticated user (verifyState round-trip)
//   (4) honours KILL_SIGNUP kill switch
//
// Run:
//   deno test --allow-env --allow-net --allow-read \
//     supabase/functions/gmail-oauth-init/__tests__/init_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import { handleInit } from "../index.ts";
import { verifyState } from "../state.ts";

const TEST_SECRET = "test-state-secret-init-tests-1234567890";
const USER_ID = "u-init-aaaa-bbbb-cccc-dddd-eeeeeeeeeeee";
const CLIENT_ID = "1234567890-abc.apps.googleusercontent.com";
const REDIRECT_URI = "https://advocat.ee/oauth/gmail/return";

async function readJson(resp: Response): Promise<Record<string, unknown>> {
  const text = await resp.text();
  return text ? JSON.parse(text) : {};
}

// =============================================================================
// (1) — denied without auth (anonymous principal not allowed)
// =============================================================================

Deno.test("gmail-oauth-init (1): denied when no authenticated user", async () => {
  const resp = await handleInit({
    authedUserId: null,
    killSignup: false,
    clientId: CLIENT_ID,
    gateSecret: TEST_SECRET,
    redirectUri: REDIRECT_URI,
  });
  assertEquals(resp.status, 401);
  const body = await readJson(resp);
  assert(typeof body.error === "string");
});

// =============================================================================
// (2) — returns authorize URL with the required Google OAuth params
// =============================================================================

Deno.test(
  "gmail-oauth-init (2): URL contains prompt=consent + access_type=offline + Gmail scopes",
  async () => {
    const resp = await handleInit({
      authedUserId: USER_ID,
      killSignup: false,
      clientId: CLIENT_ID,
      gateSecret: TEST_SECRET,
      redirectUri: REDIRECT_URI,
    });
    assertEquals(resp.status, 200);
    const body = await readJson(resp);
    const authUrl = body.auth_url as string;
    assertStringIncludes(authUrl, "https://accounts.google.com/o/oauth2/v2/auth");
    // Hard-coded must-haves so a refresh_token actually comes back.
    assertStringIncludes(authUrl, "access_type=offline");
    assertStringIncludes(authUrl, "prompt=consent");
    assertStringIncludes(authUrl, "response_type=code");
    assertStringIncludes(authUrl, `client_id=${encodeURIComponent(CLIENT_ID)}`);
    assertStringIncludes(
      authUrl,
      `redirect_uri=${encodeURIComponent(REDIRECT_URI)}`,
    );
    // Gmail scope set must include gmail.send, gmail.readonly, gmail.modify
    // — these are kGmailScopesActive on the Flutter side. We compare on the
    // decoded URL so encoding doesn't matter.
    const decoded = decodeURIComponent(authUrl);
    assertStringIncludes(decoded, "https://www.googleapis.com/auth/gmail.send");
    assertStringIncludes(
      decoded,
      "https://www.googleapis.com/auth/gmail.readonly",
    );
    assertStringIncludes(
      decoded,
      "https://www.googleapis.com/auth/gmail.modify",
    );
    assertStringIncludes(decoded, "email");
    // state is also exposed in the body (so the client can pass it along to
    // the exchange step out-of-band if needed).
    assert(typeof body.state === "string" && (body.state as string).length > 0);
  },
);

// =============================================================================
// (3) — the state token round-trips back to the same user_id
// =============================================================================

Deno.test(
  "gmail-oauth-init (3): state token is bound to the authenticated user",
  async () => {
    const resp = await handleInit({
      authedUserId: USER_ID,
      killSignup: false,
      clientId: CLIENT_ID,
      gateSecret: TEST_SECRET,
      redirectUri: REDIRECT_URI,
    });
    assertEquals(resp.status, 200);
    const body = await readJson(resp);
    const state = body.state as string;
    // verifyState round-trip must yield exactly USER_ID, signed with the
    // same secret. A different user cannot have minted this state without
    // EMAIL_AGENT_GATE_SECRET.
    const v = await verifyState(state, TEST_SECRET);
    assert(v.ok);
    if (v.ok) {
      assertEquals(v.user_id, USER_ID);
    }
    // And it must also be visible inside the auth_url's `state=` param —
    // they should be identical.
    const url = new URL(body.auth_url as string);
    assertEquals(url.searchParams.get("state"), state);
  },
);

// =============================================================================
// (4) — KILL_SIGNUP kill switch short-circuits before the URL is built
// =============================================================================

Deno.test("gmail-oauth-init (4): respects KILL_SIGNUP kill switch", async () => {
  const resp = await handleInit({
    authedUserId: USER_ID,
    killSignup: true,
    clientId: CLIENT_ID,
    gateSecret: TEST_SECRET,
    redirectUri: REDIRECT_URI,
  });
  assertEquals(resp.status, 503);
  const body = await readJson(resp);
  assertEquals(body.error, "signup_paused");
});

// =============================================================================
// Source-code contract on index.ts
// =============================================================================

Deno.test("contract — index.ts uses requireUserWithRateLimit + correct bucket", async () => {
  const src = await Deno.readTextFile(new URL("../index.ts", import.meta.url));
  assertStringIncludes(src, "requireUserWithRateLimit");
  assertStringIncludes(src, 'bucket: "gmail-oauth-init"');
});

Deno.test("contract — index.ts checks KILL_SIGNUP", async () => {
  const src = await Deno.readTextFile(new URL("../index.ts", import.meta.url));
  assertStringIncludes(src, "KILL_SIGNUP");
});
