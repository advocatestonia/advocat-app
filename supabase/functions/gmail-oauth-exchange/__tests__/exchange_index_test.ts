// gmail-oauth-exchange/__tests__/exchange_index_test.ts
// -----------------------------------------------------------------------------
// Handler-level tests for gmail-oauth-exchange. The handler is exported as
// a pure-ish `handleExchange({...})` so we can drive it deterministically:
//
//   - fetch() is stubbed via dependency injection (so the test never hits
//     Google).
//   - The Supabase client is mocked with a tiny `.from().upsert()` chain
//     that captures the row + onConflict args.
//
// Tests:
//   (1) rejects invalid state                — bad HMAC → 401
//   (2) rejects expired state                — past exp_ms → 401
//   (3) defensive: 502 when Google omits refresh_token even with
//                   prompt=consent (alerting bait + the whole reason this
//                   side-channel exists).
//   (4) happy path: upserts user_oauth_tokens with refresh_token + email
//                   + scope, returns has_refresh_token: true.
//   (5) user_id comes from the state token, NEVER from the request body —
//                   a forged body cannot write a token row for another
//                   user even if the body says so.
//
// Run:
//   deno test --allow-env --allow-net --allow-read \
//     supabase/functions/gmail-oauth-exchange/__tests__/exchange_index_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import { handleExchange } from "../index.ts";
import { signState } from "../../gmail-oauth-init/state.ts";

const TEST_SECRET = "test-state-secret-exchange-tests-1234567890";
const USER_ID = "u-xchg-aaaa-bbbb-cccc-dddd-eeeeeeeeeeee";
const ATTACKER_ID = "u-evil-aaaa-bbbb-cccc-dddd-eeeeeeeeeeee";
const CLIENT_ID = "1234.apps.googleusercontent.com";
const CLIENT_SECRET = "GOCSPX-fake";
const REDIRECT_URI = "https://advocat.ee/oauth/gmail/return";

// =============================================================================
// Test harness — fake Supabase client + fetch responder
// =============================================================================

interface UpsertCall {
  table: string;
  row: Record<string, unknown>;
  onConflict: string;
}

function makeFakeSupabase(
  upsertResult: { error: unknown } = { error: null },
): { client: unknown; calls: UpsertCall[] } {
  const calls: UpsertCall[] = [];
  const client = {
    from(table: string) {
      return {
        upsert(row: Record<string, unknown>, opts: { onConflict: string }) {
          calls.push({ table, row, onConflict: opts.onConflict });
          // Supabase upsert returns a thenable.
          return Promise.resolve(upsertResult);
        },
      };
    },
  };
  return { client, calls };
}

/** Stub Google's POST /token (and optionally /userinfo for the id_token-missing fallback). */
function makeTokenFetcher(
  tokenResp: Record<string, unknown> | { _status: number; body: string },
  userinfoResp?: Record<string, unknown>,
): typeof fetch {
  // deno-lint-ignore no-explicit-any
  return (async (input: any, _init?: RequestInit) => {
    const url = typeof input === "string" ? input : input.url;
    if (url.startsWith("https://oauth2.googleapis.com/token")) {
      // Error-shape sentinel.
      if (
        typeof tokenResp === "object" && tokenResp &&
        "_status" in tokenResp && "body" in tokenResp
      ) {
        const e = tokenResp as { _status: number; body: string };
        return new Response(e.body, { status: e._status });
      }
      return new Response(JSON.stringify(tokenResp), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }
    if (url.startsWith("https://www.googleapis.com/oauth2/v2/userinfo")) {
      return new Response(JSON.stringify(userinfoResp ?? { email: "fb@x" }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }
    throw new Error("unexpected fetch URL: " + url);
  }) as typeof fetch;
}

/** Build a JWT-shaped id_token middle segment for `email` (header/sig are bogus
 *  — exchange.ts only base64url-decodes the middle and reads `.email`). */
function makeIdToken(email: string): string {
  const header = base64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const payload = base64url(JSON.stringify({ email, email_verified: true }));
  const sig = "fakesig";
  return `${header}.${payload}.${sig}`;
}

function base64url(s: string): string {
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function readJson(resp: Response): Promise<Record<string, unknown>> {
  const text = await resp.text();
  return text ? JSON.parse(text) : {};
}

// =============================================================================
// (1) — bad HMAC → 401
// =============================================================================

Deno.test("gmail-oauth-exchange (1): rejects invalid state HMAC", async () => {
  const goodState = await signState({ user_id: USER_ID }, TEST_SECRET);
  // Mutate the HMAC half.
  const forged = goodState.replace(/\.[a-f0-9]+$/, ".0".repeat(32));
  const { client, calls } = makeFakeSupabase();
  const resp = await handleExchange({
    body: { code: "fake-code", state: forged },
    killSignup: false,
    clientId: CLIENT_ID,
    clientSecret: CLIENT_SECRET,
    gateSecret: TEST_SECRET,
    redirectUri: REDIRECT_URI,
    supabase: client,
    fetchImpl: makeTokenFetcher({ access_token: "should-not-be-reached" }),
  });
  assertEquals(resp.status, 401);
  // No DB write.
  assertEquals(calls.length, 0);
});

// =============================================================================
// (2) — expired state → 401
// =============================================================================

Deno.test("gmail-oauth-exchange (2): rejects expired state token", async () => {
  // Token issued in 2026-01-01; verify at 2026-06-01 → expired.
  const past = Date.UTC(2026, 0, 1, 0, 0, 0);
  const state = await signState(
    { user_id: USER_ID, now_ms: past, ttl_ms: 60_000 /* 1 min */ },
    TEST_SECRET,
  );
  const { client, calls } = makeFakeSupabase();
  const resp = await handleExchange({
    body: { code: "fake-code", state },
    killSignup: false,
    clientId: CLIENT_ID,
    clientSecret: CLIENT_SECRET,
    gateSecret: TEST_SECRET,
    redirectUri: REDIRECT_URI,
    supabase: client,
    fetchImpl: makeTokenFetcher({ access_token: "should-not-be-reached" }),
    nowMs: Date.UTC(2026, 5, 1, 0, 0, 0),
  });
  assertEquals(resp.status, 401);
  // No DB write.
  assertEquals(calls.length, 0);
});

// =============================================================================
// (3) — Google omitted refresh_token → 502 + alert
// =============================================================================

Deno.test(
  "gmail-oauth-exchange (3): 502 when Google response is missing refresh_token",
  async () => {
    const state = await signState({ user_id: USER_ID }, TEST_SECRET);
    const { client, calls } = makeFakeSupabase();
    const resp = await handleExchange({
      body: { code: "fake-code", state },
      killSignup: false,
      clientId: CLIENT_ID,
      clientSecret: CLIENT_SECRET,
      gateSecret: TEST_SECRET,
      redirectUri: REDIRECT_URI,
      supabase: client,
      // Token response WITHOUT refresh_token — this is the bug we're
      // defending against. With access_type=offline + prompt=consent it
      // should never happen, but we still want loud failure if it does.
      fetchImpl: makeTokenFetcher({
        access_token: "ya29.abc",
        expires_in: 3600,
        scope: "email https://www.googleapis.com/auth/gmail.send",
        id_token: makeIdToken("user@gmail.com"),
        // refresh_token: intentionally absent.
      }),
    });
    assertEquals(resp.status, 502);
    const body = await readJson(resp);
    assertEquals(body.error, "google_omitted_refresh_token");
    // No DB write (we will NOT silently persist a row that's about to
    // resurrect the original "refresh_token IS NULL" prod bug).
    assertEquals(calls.length, 0);
  },
);

// =============================================================================
// (4) — happy path
// =============================================================================

Deno.test(
  "gmail-oauth-exchange (4): upserts user_oauth_tokens with refresh_token + email + scope",
  async () => {
    const state = await signState({ user_id: USER_ID }, TEST_SECRET);
    const { client, calls } = makeFakeSupabase();
    const idToken = makeIdToken("user@gmail.com");
    const t0 = Date.UTC(2026, 4, 26, 12, 0, 0);
    const resp = await handleExchange({
      body: { code: "good-code", state },
      killSignup: false,
      clientId: CLIENT_ID,
      clientSecret: CLIENT_SECRET,
      gateSecret: TEST_SECRET,
      redirectUri: REDIRECT_URI,
      supabase: client,
      fetchImpl: makeTokenFetcher({
        access_token: "ya29.fresh",
        refresh_token: "1//rt-real",
        expires_in: 3600,
        scope:
          "email https://www.googleapis.com/auth/gmail.send https://www.googleapis.com/auth/gmail.readonly",
        id_token: idToken,
      }),
      nowMs: t0,
    });

    assertEquals(resp.status, 200);
    const body = await readJson(resp);
    assertEquals(body.ok, true);
    assertEquals(body.email, "user@gmail.com");
    assertEquals(body.has_refresh_token, true);

    // Upserted with the right shape.
    assertEquals(calls.length, 1);
    assertEquals(calls[0].table, "user_oauth_tokens");
    assertEquals(calls[0].onConflict, "user_id,provider");
    const row = calls[0].row;
    assertEquals(row.user_id, USER_ID);
    assertEquals(row.provider, "gmail");
    assertEquals(row.access_token, "ya29.fresh");
    assertEquals(row.refresh_token, "1//rt-real");
    assertEquals(row.email, "user@gmail.com");
    assertStringIncludes(String(row.scope), "gmail.readonly");
    // expires_at = ISO(now + 3600 * 1000)
    assertEquals(
      row.expires_at,
      new Date(t0 + 3600 * 1000).toISOString(),
    );
    assert(typeof row.updated_at === "string");
  },
);

// =============================================================================
// (5) — user_id comes from state, never from body
// =============================================================================

Deno.test(
  "gmail-oauth-exchange (5): user_id is taken from state token, NOT from body",
  async () => {
    // State is signed for USER_ID …
    const state = await signState({ user_id: USER_ID }, TEST_SECRET);
    const { client, calls } = makeFakeSupabase();
    const resp = await handleExchange({
      // …but the (malicious) request body says ATTACKER_ID. Our handler
      // must ignore body.user_id entirely.
      body: {
        code: "good-code",
        state,
        user_id: ATTACKER_ID,
        // For paranoia also try email override:
        email: "attacker@example.com",
      },
      killSignup: false,
      clientId: CLIENT_ID,
      clientSecret: CLIENT_SECRET,
      gateSecret: TEST_SECRET,
      redirectUri: REDIRECT_URI,
      supabase: client,
      fetchImpl: makeTokenFetcher({
        access_token: "ya29.x",
        refresh_token: "1//rt",
        expires_in: 3600,
        scope: "email",
        id_token: makeIdToken("legitimate@gmail.com"),
      }),
    });
    assertEquals(resp.status, 200);
    assertEquals(calls.length, 1);
    // The row MUST be for USER_ID (the state signer), not ATTACKER_ID.
    assertEquals(calls[0].row.user_id, USER_ID);
    // Email MUST be the one Google asserted in id_token, not the body's.
    assertEquals(calls[0].row.email, "legitimate@gmail.com");
  },
);

// =============================================================================
// Source-code contract on index.ts
// =============================================================================

Deno.test("contract — index.ts checks KILL_SIGNUP", async () => {
  const src = await Deno.readTextFile(new URL("../index.ts", import.meta.url));
  assertStringIncludes(src, "KILL_SIGNUP");
});

Deno.test("contract — index.ts uses verifyState (NOT Supabase JWT for primary auth)", async () => {
  const src = await Deno.readTextFile(new URL("../index.ts", import.meta.url));
  assertStringIncludes(src, "verifyState");
});

Deno.test("contract — index.ts upserts with onConflict user_id,provider", async () => {
  const src = await Deno.readTextFile(new URL("../index.ts", import.meta.url));
  assertStringIncludes(src, "user_oauth_tokens");
  assertStringIncludes(src, "user_id,provider");
});
