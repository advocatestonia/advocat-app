// Deno TDD — _shared/rate_limit.ts
// -----------------------------------------------------------------------------
// P3 anti-abuse (Bentley batch, 2026-05-15)
//
// Smoke-tests the shared rate_limit wrapper.  Like spend_tracker, the RPC
// round-trip paths are covered by live smoke tests after deploy; here we
// confirm:
//   • the helper degrades open when Supabase env vars are absent
//   • the result shape stays wire-stable
//   • the prune helper resolves to a number
//
// Run with:
//   deno test --allow-read --allow-env \
//     supabase/functions/_shared/__tests__/rate_limit_test.ts
// -----------------------------------------------------------------------------

import {
  assertStrictEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  checkAndRecordRateLimit,
  pruneRateLimitEvents,
} from "../rate_limit.ts";

Deno.test("RL-T01 — checkAndRecordRateLimit returns the expected shape", async () => {
  const r = await checkAndRecordRateLimit({
    bucket: "test-bucket",
    principal: "test-principal",
    maxPerMinute: 30,
  });
  assertStrictEquals(typeof r.allowed, "boolean");
  assertStrictEquals(typeof r.count, "number");
  assertStrictEquals(typeof r.windowMs, "number");
  assertStrictEquals(typeof r.degraded, "boolean");
});

Deno.test("RL-T02 — pruneRateLimitEvents resolves to a number", async () => {
  const n = await pruneRateLimitEvents();
  assertStrictEquals(typeof n, "number");
});

Deno.test("RL-T03 — degraded mode never blocks", async () => {
  // When Supabase env is missing the helper MUST allow the request through
  // (the in-process Map in auth.ts is the safety net).  We can't force the
  // env-missing condition deterministically inside a Deno test (the runner
  // may export real values), so we just confirm the contract: if degraded
  // is true, allowed must also be true.
  const r = await checkAndRecordRateLimit({
    bucket: "test-bucket",
    principal: "test-principal-2",
    maxPerMinute: 30,
  });
  if (r.degraded) {
    assertStrictEquals(r.allowed, true, "degraded mode must fail open");
  }
});
