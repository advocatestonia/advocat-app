// Deno tests for send-email/token_refresh.ts (Phase C — Gmail token refresh).
// -----------------------------------------------------------------------------
// Pure helpers only. The HTTP refresh fetch + Supabase write live in
// index.ts::tryRefreshGmailToken; those are exercised by the post-deploy
// canary smoke tests on staging. Here we lock the decision logic that is
// easy to regress.
//
// Run with:
//   deno test --allow-read --allow-env \
//     supabase/functions/send-email/__tests__/token_refresh_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertFalse,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  buildRefreshRequestBody,
  computeNewExpiry,
  REFRESH_MARGIN_MS,
  shouldRefresh,
  type TokenRow,
} from "../token_refresh.ts";

// ---------------------------------------------------------------------------
// shouldRefresh
// ---------------------------------------------------------------------------

const FRESH_ROW: TokenRow = {
  access_token: "ya29.fresh",
  refresh_token: "1//rt",
  // Expires 1 hour from now in test cases — we add `now` at call time.
  expires_at: null,
};

Deno.test("shouldRefresh — false when expires_at is far in the future", () => {
  const now = Date.UTC(2026, 4, 5, 12, 0, 0);
  const row: TokenRow = {
    ...FRESH_ROW,
    expires_at: new Date(now + 60 * 60_000).toISOString(), // +1h
  };
  assertFalse(shouldRefresh(row, now));
});

Deno.test("shouldRefresh — true when within REFRESH_MARGIN_MS of expiry", () => {
  const now = Date.UTC(2026, 4, 5, 12, 0, 0);
  const row: TokenRow = {
    ...FRESH_ROW,
    expires_at: new Date(now + REFRESH_MARGIN_MS - 1000).toISOString(),
  };
  assert(shouldRefresh(row, now));
});

Deno.test("shouldRefresh — true when token already expired", () => {
  const now = Date.UTC(2026, 4, 5, 12, 0, 0);
  const row: TokenRow = {
    ...FRESH_ROW,
    expires_at: new Date(now - 60_000).toISOString(),
  };
  assert(shouldRefresh(row, now));
});

Deno.test("shouldRefresh — true when expires_at is null", () => {
  const row: TokenRow = { ...FRESH_ROW, expires_at: null };
  assert(shouldRefresh(row, Date.now()));
});

Deno.test("shouldRefresh — true when expires_at is unparseable garbage", () => {
  const row: TokenRow = { ...FRESH_ROW, expires_at: "not-a-date" };
  assert(shouldRefresh(row, Date.now()));
});

Deno.test("shouldRefresh — false when no refresh_token (cannot refresh)", () => {
  const now = Date.UTC(2026, 4, 5, 12, 0, 0);
  const row: TokenRow = {
    access_token: "x",
    refresh_token: null,
    expires_at: new Date(now - 60_000).toISOString(),
  };
  // Even though expired, we can't refresh — caller will fall back to Resend.
  assertFalse(shouldRefresh(row, now));
});

Deno.test("shouldRefresh — false when refresh_token is empty string", () => {
  const now = Date.UTC(2026, 4, 5, 12, 0, 0);
  const row: TokenRow = {
    access_token: "x",
    refresh_token: "",
    expires_at: null,
  };
  assertFalse(shouldRefresh(row, now));
});

Deno.test("REFRESH_MARGIN_MS — 5 minutes", () => {
  assertEquals(REFRESH_MARGIN_MS, 5 * 60_000);
});

// ---------------------------------------------------------------------------
// buildRefreshRequestBody
// ---------------------------------------------------------------------------

Deno.test("buildRefreshRequestBody — emits all four required fields", () => {
  const body = buildRefreshRequestBody({
    clientId: "cid",
    clientSecret: "csec",
    refreshToken: "rt",
  });
  assertEquals(body.get("client_id"), "cid");
  assertEquals(body.get("client_secret"), "csec");
  assertEquals(body.get("refresh_token"), "rt");
  assertEquals(body.get("grant_type"), "refresh_token");
});

Deno.test("buildRefreshRequestBody — URL-encodes special chars", () => {
  const body = buildRefreshRequestBody({
    clientId: "id with space",
    clientSecret: "a/b+c=",
    refreshToken: "rt",
  });
  // URLSearchParams handles encoding for us; we just verify round-trip.
  assertEquals(body.get("client_id"), "id with space");
  assertEquals(body.get("client_secret"), "a/b+c=");
});

// ---------------------------------------------------------------------------
// computeNewExpiry
// ---------------------------------------------------------------------------

Deno.test("computeNewExpiry — uses Google's expires_in when present", () => {
  const now = Date.UTC(2026, 4, 5, 12, 0, 0);
  const iso = computeNewExpiry({ expires_in: 3600 }, now);
  assertEquals(iso, "2026-05-05T13:00:00.000Z");
});

Deno.test("computeNewExpiry — falls back to 3000s when expires_in missing", () => {
  const now = Date.UTC(2026, 4, 5, 12, 0, 0);
  const iso = computeNewExpiry({}, now);
  // 3000 seconds = 50 minutes
  assertEquals(iso, "2026-05-05T12:50:00.000Z");
});

Deno.test("computeNewExpiry — falls back when expires_in is non-numeric", () => {
  const now = Date.UTC(2026, 4, 5, 12, 0, 0);
  const iso = computeNewExpiry(
    { expires_in: "abc" as unknown as number },
    now,
  );
  assertEquals(iso, "2026-05-05T12:50:00.000Z");
});

Deno.test("computeNewExpiry — falls back when expires_in is negative", () => {
  const now = Date.UTC(2026, 4, 5, 12, 0, 0);
  const iso = computeNewExpiry({ expires_in: -1 }, now);
  assertEquals(iso, "2026-05-05T12:50:00.000Z");
});

// ---------------------------------------------------------------------------
// Source-code contract — index.ts must call shouldRefresh before Gmail send,
// and must record the GDPR-relevant provider variant in correspondence.
// ---------------------------------------------------------------------------

Deno.test("contract — index.ts wires shouldRefresh into Gmail token path", async () => {
  const src = await Deno.readTextFile(new URL("../index.ts", import.meta.url));
  assertStringIncludes(src, "shouldRefresh");
  assertStringIncludes(src, "tryRefreshGmailToken");
});

Deno.test("contract — index.ts records gmail_user vs resend_fallback in audit log", async () => {
  const src = await Deno.readTextFile(new URL("../index.ts", import.meta.url));
  // GDPR posture flips on this exact distinction (controller vs processor).
  // If a refactor renames the literals, the audit becomes inscrutable.
  assertStringIncludes(src, '"gmail_user"');
  assertStringIncludes(src, '"resend_fallback"');
});

Deno.test("contract — index.ts reads refresh_token + expires_at from oauth tokens", async () => {
  const src = await Deno.readTextFile(new URL("../index.ts", import.meta.url));
  // The .select() projection MUST include refresh_token and expires_at —
  // otherwise the refresh path always sees expires_at:null and treats every
  // token as expired (correct fallback, but wasteful).
  assertStringIncludes(src, "refresh_token");
  assertStringIncludes(src, "expires_at");
});
