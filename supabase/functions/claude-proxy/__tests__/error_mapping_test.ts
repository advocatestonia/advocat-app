// Deno tests for claude-proxy 429 / 529 friendly-error mapping
// (pre-launch fix, 2026-04-29).
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-read \
//     supabase/functions/claude-proxy/__tests__/error_mapping_test.ts
//
// Contract:
//   • Anthropic returns 429 (rate-limit) → proxy returns
//       { "error":"rate_limit",
//         "retry_after_seconds":<int|null>,
//         "user_message_key":"ai_error_rate_limit" }
//     with HTTP 429, so the Flutter client can pick a localized message.
//   • Anthropic returns 529 (overloaded) → proxy returns
//       { "error":"overload",
//         "user_message_key":"ai_error_overload" }
//     with HTTP 529.
//   • Existing 4xx/5xx behaviour stays intact (we only added two branches).
// -----------------------------------------------------------------------------

import {
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import { mapAnthropicError } from "../error_mapping.ts";

Deno.test("E1 — 429 maps to rate_limit shape", () => {
  const out = mapAnthropicError({
    status: 429,
    body: '{"type":"error","error":{"type":"rate_limit_error","message":"x"}}',
    retryAfter: "30",
  });
  assertEquals(out.status, 429);
  assertEquals(out.body.error, "rate_limit");
  assertEquals(out.body.user_message_key, "ai_error_rate_limit");
  assertEquals(out.body.retry_after_seconds, 30);
});

Deno.test("E2 — 429 with no Retry-After defaults retry_after_seconds=null", () => {
  const out = mapAnthropicError({
    status: 429,
    body: '{"type":"error"}',
    retryAfter: null,
  });
  assertEquals(out.status, 429);
  assertEquals(out.body.error, "rate_limit");
  assertEquals(out.body.user_message_key, "ai_error_rate_limit");
  assertEquals(out.body.retry_after_seconds, null);
});

Deno.test("E3 — 529 maps to overload shape", () => {
  const out = mapAnthropicError({
    status: 529,
    body: '{"type":"error","error":{"type":"overloaded_error"}}',
    retryAfter: null,
  });
  assertEquals(out.status, 529);
  assertEquals(out.body.error, "overload");
  assertEquals(out.body.user_message_key, "ai_error_overload");
  // No retry_after_seconds for overload — clients show generic "try again".
  assertEquals(out.body.retry_after_seconds, undefined);
});

Deno.test("E4 — 500 keeps legacy { error: <text> } shape (no new key)", () => {
  const out = mapAnthropicError({
    status: 500,
    body: '{"type":"error","error":{"message":"boom"}}',
    retryAfter: null,
  });
  assertEquals(out.status, 500);
  // Legacy callers expect a string `error` field — must not break.
  if (typeof out.body.error !== "string") {
    throw new Error("500 must keep the legacy string `error` field");
  }
  assertEquals(out.body.user_message_key, undefined);
});

Deno.test("E5 — non-numeric Retry-After is treated as null", () => {
  const out = mapAnthropicError({
    status: 429,
    body: "",
    retryAfter: "not-a-number",
  });
  assertEquals(out.body.error, "rate_limit");
  assertEquals(out.body.retry_after_seconds, null);
});

// -- Source-code contract: index.ts wires the mapper -----------------------

Deno.test("E6 — claude-proxy/index.ts imports mapAnthropicError", async () => {
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  assertStringIncludes(source, "mapAnthropicError");
  assertStringIncludes(source, "error_mapping.ts");
});

Deno.test("E7 — claude-proxy/index.ts handles 429 and 529", async () => {
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  // Both status codes must be handled in the non-streaming and streaming
  // paths. We do a soft check — the mapper is the single source of truth,
  // we just need the index to ROUTE 429/529 through it.
  if (!/429/.test(source) || !/529/.test(source)) {
    throw new Error(
      "claude-proxy/index.ts must handle Anthropic 429 and 529 explicitly",
    );
  }
});
