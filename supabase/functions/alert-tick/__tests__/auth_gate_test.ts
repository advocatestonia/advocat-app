// alert-tick/__tests__/auth_gate_test.ts
// -----------------------------------------------------------------------------
// Regression for the alert-tick cron-secret gate. /functions/v1/alert-tick is
// reachable on the open internet; without this gate anyone could trigger the
// alert pipeline and spam the Slack channel. These tests lock the four
// checkCronSecret() branches plus the constant-time string compare.
//
// Imported from the pure auth_gate.ts module so index.ts's top-level serve()
// side effect never runs during tests.
//
// Run:
//   deno test --allow-read \
//     supabase/functions/alert-tick/__tests__/auth_gate_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertFalse,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import { checkCronSecret, timingSafeEqualStr } from "../auth_gate.ts";

// ─── checkCronSecret — fail-closed branches ─────────────────────────────────

Deno.test("AG-01 — no env secret -> 500 fail-closed", () => {
  const res = checkCronSecret("anything", undefined);
  assertEquals(res.kind, "deny");
  if (res.kind === "deny") {
    assertEquals(res.status, 500);
    assertStringIncludes(res.body.error, "not configured");
  }
});

Deno.test(
  "AG-02 — empty-string env secret treated as unconfigured -> 500",
  () => {
    // "" is falsy, so the !envSecret guard must fire before any comparison.
    const res = checkCronSecret("anything", "");
    assertEquals(res.kind, "deny");
    if (res.kind === "deny") assertEquals(res.status, 500);
  }
);

Deno.test("AG-03 — missing header -> 401", () => {
  const res = checkCronSecret(null, "the-secret");
  assertEquals(res.kind, "deny");
  if (res.kind === "deny") {
    assertEquals(res.status, 401);
    assertStringIncludes(res.body.error, "Missing");
  }
});

Deno.test("AG-04 — wrong header -> 401 invalid", () => {
  const res = checkCronSecret("not-the-secret", "the-secret");
  assertEquals(res.kind, "deny");
  if (res.kind === "deny") {
    assertEquals(res.status, 401);
    assertStringIncludes(res.body.error, "Invalid");
  }
});

Deno.test(
  "AG-05 — header that is a prefix of the secret -> 401 (length guard)",
  () => {
    const res = checkCronSecret("the-secre", "the-secret");
    assertEquals(res.kind, "deny");
    if (res.kind === "deny") assertEquals(res.status, 401);
  }
);

Deno.test(
  "AG-06 — header that is a superset of the secret -> 401 (length guard)",
  () => {
    const res = checkCronSecret("the-secret-extra", "the-secret");
    assertEquals(res.kind, "deny");
    if (res.kind === "deny") assertEquals(res.status, 401);
  }
);

Deno.test("AG-07 — exact match -> allow", () => {
  const res = checkCronSecret("the-secret", "the-secret");
  assertEquals(res.kind, "allow");
});

Deno.test(
  "AG-08 — empty header string is falsy -> 401 missing (not allow)",
  () => {
    // An attacker sending an empty header must NOT pass even if env were empty;
    // here env is set, so the missing-header branch fires.
    const res = checkCronSecret("", "the-secret");
    assertEquals(res.kind, "deny");
    if (res.kind === "deny") assertEquals(res.status, 401);
  }
);

// ─── timingSafeEqualStr — constant-time compare ─────────────────────────────

Deno.test("AG-09 — equal strings compare true", () => {
  assert(timingSafeEqualStr("abc123", "abc123"));
  assert(timingSafeEqualStr("", "")); // both empty -> equal
});

Deno.test("AG-10 — different lengths short-circuit to false", () => {
  assertFalse(timingSafeEqualStr("abc", "abcd"));
  assertFalse(timingSafeEqualStr("abcd", "abc"));
});

Deno.test("AG-11 — same length, single differing char -> false", () => {
  assertFalse(timingSafeEqualStr("secret", "secreT"));
  assertFalse(timingSafeEqualStr("aaaaaa", "aaaaab"));
});
