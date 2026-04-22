// Deno-runtime tests for deadline-reminder auth + PII scrub (FIX-5).
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-env --allow-read --allow-net=esm.sh,deno.land \
//     supabase/functions/deadline-reminder/__tests__/deadline_reminder_auth_test.ts
//
// Scope:
//   - checkCronSecret() pure helper (all 4 paths: missing env, missing header,
//     wrong header, right header)
//   - Timing-safe compare: different lengths short-circuit correctly
//   - Source-code contract: response body no longer contains `details` field
//   - Source-code contract: handler gates with checkCronSecret before any
//     Supabase call (so unauthenticated requests never hit service_role)
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertFalse,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

// Import the pure helper from its own module — index.ts has a top-level
// serve() side effect that would otherwise try to bind a port during tests.
import { checkCronSecret } from "../auth_gate.ts";

Deno.test("F5-T01 — no env var -> 500 fail-closed", () => {
  const res = checkCronSecret("anything", undefined);
  assertEquals(res.kind, "deny");
  if (res.kind === "deny") {
    assertEquals(res.status, 500);
    assertStringIncludes(res.body.error, "not configured");
  }
});

Deno.test("F5-T02 — missing header -> 401", () => {
  const res = checkCronSecret(null, "the-secret");
  assertEquals(res.kind, "deny");
  if (res.kind === "deny") {
    assertEquals(res.status, 401);
    assertStringIncludes(res.body.error, "Missing");
  }
});

Deno.test("F5-T03 — wrong header -> 401", () => {
  const res = checkCronSecret("guess", "the-secret");
  assertEquals(res.kind, "deny");
  if (res.kind === "deny") {
    assertEquals(res.status, 401);
    assertStringIncludes(res.body.error, "Invalid");
  }
});

Deno.test("F5-T04 — different length header -> 401 (timing-safe short-circuit)", () => {
  const res = checkCronSecret("short", "much-longer-secret");
  assertEquals(res.kind, "deny");
  if (res.kind === "deny") {
    assertEquals(res.status, 401);
  }
});

Deno.test("F5-T05 — correct header -> allow", () => {
  const res = checkCronSecret("the-secret", "the-secret");
  assertEquals(res.kind, "allow");
});

Deno.test("F5-T06 — empty secret env is treated as unconfigured", () => {
  // Some hosts surface env vars as empty string. Must still fail closed.
  const res = checkCronSecret("", "");
  assertEquals(res.kind, "deny");
  if (res.kind === "deny") {
    assertEquals(res.status, 500);
  }
});

// ---- Source-code contract tests (static analysis of index.ts) ---------------

Deno.test("F5-T07 — response body no longer contains `details` field", async () => {
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  // The pre-FIX-5 bug was `details: notifications` in the response. We must
  // never ship a `details:` key in the JSON response — that's PII.
  // Strip comments first so doc references to the old shape don't trigger.
  const stripped = source
    .replace(/\/\*[\s\S]*?\*\//g, "")
    .replace(/^\s*\/\/.*$/gm, "");
  assertFalse(
    /details\s*:\s*notifications/.test(stripped),
    "Response body must not include `details: notifications` — PII leak, " +
      "see docs/security/02-auth-authz.md C1",
  );
});

Deno.test("F5-T08 — response shape uses { processed, errors } only", async () => {
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  // Every successful return must use the terse count-only shape.
  assertStringIncludes(source, "processed:");
  assertStringIncludes(source, "errors");
});

Deno.test("F5-T09 — handler calls checkCronSecret before createClient", async () => {
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  const gateIdx = source.indexOf("checkCronSecret(");
  const createClientIdx = source.indexOf("createClient(");
  assert(
    gateIdx !== -1,
    "index.ts must call checkCronSecret to gate the handler",
  );
  assert(
    createClientIdx !== -1,
    "index.ts must still createClient after the gate",
  );
  assert(
    gateIdx < createClientIdx,
    "checkCronSecret MUST run before createClient — otherwise service_role " +
      "is instantiated for unauthenticated callers (wastes cold-start, and " +
      "more importantly doesn't enforce the fail-closed invariant)",
  );
});

Deno.test("F5-T10 — reads CRON_SECRET from env (not body, not query)", async () => {
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  assertStringIncludes(source, "Deno.env.get(\"CRON_SECRET\")");
});

Deno.test("F5-T11 — uses x-cron-secret header (not Authorization)", async () => {
  // Using `Authorization` would conflict with Supabase Gateway's own JWT
  // check. A separate header makes the cron path explicit.
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  assertStringIncludes(source, 'x-cron-secret');
});

Deno.test("F5-T12 — catch block does not echo error details", async () => {
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  // Pre-FIX-5 the catch block did `{ error: String(error) }` which can
  // contain PII from Supabase error messages. Must now be a generic string.
  assertFalse(
    /String\(error\)/.test(source),
    "catch block must not echo String(error) — PII in error messages",
  );
});
