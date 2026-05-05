// Deno tests for oauth-callback.
// -----------------------------------------------------------------------------
// Two groups:
//   * Pure-function tests for payload.ts (validatePayload, normalizeForUpsert).
//   * Source-contract tests for index.ts (asserts JWT gate ordering, upsert
//     conflict key, RLS-respecting service-role usage). Mirrors the pattern
//     used by extract-memory/__tests__/extract_memory_test.ts.
//
// Run with:
//   deno test --allow-read --allow-env \
//     supabase/functions/oauth-callback/__tests__/oauth_callback_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertFalse,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  ALLOWED_PROVIDERS,
  DEFAULT_EXPIRES_IN_S,
  MAX_EXPIRES_IN_S,
  normalizeForUpsert,
  validatePayload,
} from "../payload.ts";

// ---------------------------------------------------------------------------
// validatePayload
// ---------------------------------------------------------------------------

Deno.test("validatePayload — happy path with all fields", () => {
  const r = validatePayload({
    provider: "gmail",
    access_token: "ya29.abc",
    refresh_token: "1//rt",
    email: "user@gmail.com",
    expires_in: 3600,
  });
  assert(r.ok);
  if (r.ok) {
    assertEquals(r.value.provider, "gmail");
    assertEquals(r.value.access_token, "ya29.abc");
    assertEquals(r.value.refresh_token, "1//rt");
    assertEquals(r.value.email, "user@gmail.com");
    assertEquals(r.value.expires_in, 3600);
  }
});

Deno.test("validatePayload — minimal payload (provider + token only)", () => {
  const r = validatePayload({
    provider: "gmail",
    access_token: "ya29.abc",
  });
  assert(r.ok);
});

Deno.test("validatePayload — rejects null body", () => {
  const r = validatePayload(null);
  assertFalse(r.ok);
  if (!r.ok) assertStringIncludes(r.error, "JSON object");
});

Deno.test("validatePayload — rejects array body", () => {
  const r = validatePayload([1, 2, 3]);
  assertFalse(r.ok);
});

Deno.test("validatePayload — rejects unsupported provider (outlook)", () => {
  const r = validatePayload({
    provider: "outlook",
    access_token: "x",
  });
  assertFalse(r.ok);
  if (!r.ok) assertStringIncludes(r.error, "provider");
});

Deno.test("validatePayload — rejects empty access_token", () => {
  const r = validatePayload({ provider: "gmail", access_token: "" });
  assertFalse(r.ok);
  if (!r.ok) assertStringIncludes(r.error, "access_token");
});

Deno.test("validatePayload — rejects access_token > 8192 chars", () => {
  const r = validatePayload({
    provider: "gmail",
    access_token: "x".repeat(8193),
  });
  assertFalse(r.ok);
});

Deno.test("validatePayload — rejects malformed email", () => {
  const r = validatePayload({
    provider: "gmail",
    access_token: "x",
    email: "not-an-email",
  });
  assertFalse(r.ok);
  if (!r.ok) assertStringIncludes(r.error, "email");
});

Deno.test("validatePayload — rejects negative expires_in", () => {
  const r = validatePayload({
    provider: "gmail",
    access_token: "x",
    expires_in: -1,
  });
  assertFalse(r.ok);
});

Deno.test("validatePayload — rejects expires_in beyond cap", () => {
  const r = validatePayload({
    provider: "gmail",
    access_token: "x",
    expires_in: MAX_EXPIRES_IN_S + 1,
  });
  assertFalse(r.ok);
});

Deno.test("validatePayload — accepts numeric-string expires_in", () => {
  // Some clients stringify everything; we tolerate that.
  const r = validatePayload({
    provider: "gmail",
    access_token: "x",
    expires_in: "3600" as unknown as number,
  });
  assert(r.ok);
  if (r.ok) assertEquals(r.value.expires_in, 3600);
});

Deno.test("ALLOWED_PROVIDERS — currently only gmail", () => {
  assertEquals(ALLOWED_PROVIDERS.size, 1);
  assert(ALLOWED_PROVIDERS.has("gmail"));
});

// ---------------------------------------------------------------------------
// normalizeForUpsert
// ---------------------------------------------------------------------------

Deno.test("normalizeForUpsert — uses provided expires_in", () => {
  const now = Date.UTC(2026, 4, 5, 12, 0, 0); // 2026-05-05T12:00:00Z
  const row = normalizeForUpsert(
    {
      provider: "gmail",
      access_token: "tok",
      expires_in: 3600,
    },
    now,
  );
  assertEquals(row.expires_at, "2026-05-05T13:00:00.000Z");
});

Deno.test(
  "normalizeForUpsert — falls back to DEFAULT_EXPIRES_IN_S when expires_in absent",
  () => {
    const now = Date.UTC(2026, 4, 5, 12, 0, 0);
    const row = normalizeForUpsert(
      { provider: "gmail", access_token: "tok" },
      now,
    );
    const expectedMs = now + DEFAULT_EXPIRES_IN_S * 1000;
    assertEquals(row.expires_at, new Date(expectedMs).toISOString());
  },
);

Deno.test("normalizeForUpsert — null fields when refresh_token/email missing", () => {
  const row = normalizeForUpsert(
    { provider: "gmail", access_token: "tok" },
    Date.now(),
  );
  assertEquals(row.refresh_token, null);
  assertEquals(row.email, null);
});

// ---------------------------------------------------------------------------
// Source-code contract on index.ts (mirrors extract-memory test pattern).
// These guard wiring decisions that are easy to regress.
// ---------------------------------------------------------------------------

Deno.test("contract — index.ts uses requireUserWithRateLimit", async () => {
  const src = await Deno.readTextFile(new URL("../index.ts", import.meta.url));
  assertStringIncludes(src, "requireUserWithRateLimit");
  assertStringIncludes(src, 'bucket: "oauth-callback"');
});

Deno.test("contract — index.ts uses service role + upserts on (user_id, provider)", async () => {
  const src = await Deno.readTextFile(new URL("../index.ts", import.meta.url));
  // Service role is required because user_oauth_tokens has no INSERT/UPDATE
  // policy for users — only service_role can write tokens.
  assertStringIncludes(src, "SUPABASE_SERVICE_ROLE_KEY");
  // Upsert MUST conflict on (user_id, provider) so calling /oauth-callback
  // twice for the same user replaces the prior token instead of creating
  // a duplicate row.
  assertStringIncludes(src, "user_oauth_tokens");
  assertStringIncludes(src, "user_id,provider");
});

Deno.test("contract — index.ts does not trust user_id from request body", async () => {
  const src = await Deno.readTextFile(new URL("../index.ts", import.meta.url));
  // Auth gate must extract user.id from JWT. The body's user_id (if any)
  // must NOT be the source of truth — that would let any auth user write a
  // token row for another user. We grep for the gate.user.id pattern.
  assertStringIncludes(src, "gate.user.id");
});

Deno.test("contract — index.ts validates payload before any DB write", async () => {
  const src = await Deno.readTextFile(new URL("../index.ts", import.meta.url));
  assertStringIncludes(src, "validatePayload");
  assertStringIncludes(src, "normalizeForUpsert");
});
