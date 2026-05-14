// kill_switches.test.ts — HN-launch insurance kill-switch tests.
// -----------------------------------------------------------------------------
// Run:
//   deno test --allow-all supabase/functions/_tests/kill_switches.test.ts
//
// Scope (6 scenarios per the task spec):
//   T01  CLAUDE_PROXY_MAINTENANCE=true     → claude-proxy returns 503 + body
//   T02  ANON_CHAT_DISABLED=true + anon    → 403 + "anon_disabled"
//   T03  ANON_CHAT_DISABLED=true + authd   → normal flow (no kill-switch resp)
//   T04  CONTRACT_REVIEW_DISABLED=true     → contract-review returns 503
//   T05  CONTRACT_REVIEW_DISABLED=true     → classify-contract returns 503
//   T06  All flags unset                   → no function short-circuits
//
// Strategy:
//   * Tests T01/T02/T04/T05 + the unset half of T03/T06 are pure: they call
//     the response builders + `flagOn()` directly. The builders are the same
//     function instance the index.ts files import, so testing the response
//     shape there equals testing what users would see.
//   * Tests T01/T02/T04/T05 ALSO grep index.ts source to assert the guard is
//     actually wired (same pattern as contract_review.test.ts T11/T12). This
//     catches the "helper exists but nobody calls it" regression class.
//   * T03's "authenticated continues" + T06's "normal flow" half are
//     verified by `flagOn()` returning false when the env is unset, which
//     skips the early-return branch in index.ts.
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertFalse,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

// Stub minimum env BEFORE importing — _shared/auth.ts reads SUPABASE_URL at
// module top-level via `!`.
Deno.env.set("SUPABASE_URL", "https://example.supabase.co");
Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "fake-service-key");

import {
  anonDisabledResponse,
  contractReviewDisabledResponse,
  flagOn,
  maintenanceResponse,
} from "../_shared/kill_switches.ts";

// ─── Helpers ────────────────────────────────────────────────────────────────

async function readJson(res: Response): Promise<Record<string, unknown>> {
  return await res.json() as Record<string, unknown>;
}

function clearFlags(): void {
  Deno.env.delete("CLAUDE_PROXY_MAINTENANCE");
  Deno.env.delete("ANON_CHAT_DISABLED");
  Deno.env.delete("CONTRACT_REVIEW_DISABLED");
}

// =============================================================================
// T01 — CLAUDE_PROXY_MAINTENANCE=true → claude-proxy returns 503
// =============================================================================
Deno.test("T01 — maintenance response is 503 with 'maintenance' error", async () => {
  Deno.env.set("CLAUDE_PROXY_MAINTENANCE", "true");
  try {
    assert(flagOn("CLAUDE_PROXY_MAINTENANCE"));
    const res = maintenanceResponse();
    assertEquals(res.status, 503);
    assertEquals(res.headers.get("Content-Type"), "application/json");
    const body = await readJson(res);
    assertEquals(body.error, "maintenance");
    assertStringIncludes(String(body.message), "maintenance");
  } finally {
    clearFlags();
  }
});

Deno.test("T01b — claude-proxy index.ts wires the maintenance guard", async () => {
  const src = await Deno.readTextFile(
    new URL("../claude-proxy/index.ts", import.meta.url),
  );
  // Must import the helper.
  assertStringIncludes(src, 'from "../_shared/kill_switches.ts"');
  assertStringIncludes(src, "maintenanceResponse");
  // Must actually call the guard with the right env flag.
  assertStringIncludes(src, 'flagOn("CLAUDE_PROXY_MAINTENANCE")');
  assertStringIncludes(src, "return maintenanceResponse()");
});

// =============================================================================
// T02 — ANON_CHAT_DISABLED=true + anon request → 403
// =============================================================================
Deno.test("T02 — anon-disabled response is 403 with sign-up message", async () => {
  Deno.env.set("ANON_CHAT_DISABLED", "true");
  try {
    assert(flagOn("ANON_CHAT_DISABLED"));
    const res = anonDisabledResponse();
    assertEquals(res.status, 403);
    assertEquals(res.headers.get("Content-Type"), "application/json");
    const body = await readJson(res);
    assertEquals(body.error, "anon_disabled");
    assertStringIncludes(String(body.message), "Sign up");
  } finally {
    clearFlags();
  }
});

Deno.test("T02b — claude-proxy index.ts wires anon-disabled behind isAnon", async () => {
  const src = await Deno.readTextFile(
    new URL("../claude-proxy/index.ts", import.meta.url),
  );
  assertStringIncludes(src, "anonDisabledResponse");
  assertStringIncludes(src, 'flagOn("ANON_CHAT_DISABLED")');
  // Guard is gated on the `isAnon` predicate, NOT applied to all callers.
  // We assert the pattern `isAnon && flagOn("ANON_CHAT_DISABLED")` lives
  // somewhere in the source — strips whitespace to make the check robust.
  const compact = src.replace(/\s+/g, " ");
  assert(
    compact.includes('isAnon && flagOn("ANON_CHAT_DISABLED")'),
    "anon-disabled guard must be conjuncted with isAnon so paid users are unaffected",
  );
});

// =============================================================================
// T03 — ANON_CHAT_DISABLED=true + authenticated request → flow continues
// =============================================================================
Deno.test("T03 — authenticated caller bypasses anon-disabled guard", () => {
  Deno.env.set("ANON_CHAT_DISABLED", "true");
  try {
    // Emulate the index.ts predicate: `isAnon && flagOn(...)`.
    const isAnon = false; // authenticated caller
    const shouldBlock = isAnon && flagOn("ANON_CHAT_DISABLED");
    assertFalse(
      shouldBlock,
      "authenticated callers must continue when ANON_CHAT_DISABLED is set",
    );
  } finally {
    clearFlags();
  }
});

Deno.test("T03b — anon caller IS blocked when flag is set", () => {
  Deno.env.set("ANON_CHAT_DISABLED", "true");
  try {
    const isAnon = true;
    const shouldBlock = isAnon && flagOn("ANON_CHAT_DISABLED");
    assert(shouldBlock, "anon callers must be blocked when flag is set");
  } finally {
    clearFlags();
  }
});

// =============================================================================
// T04 — CONTRACT_REVIEW_DISABLED=true → contract-review returns 503
// =============================================================================
Deno.test("T04 — contract-review-disabled response is 503 with right body", async () => {
  Deno.env.set("CONTRACT_REVIEW_DISABLED", "true");
  try {
    assert(flagOn("CONTRACT_REVIEW_DISABLED"));
    const res = contractReviewDisabledResponse();
    assertEquals(res.status, 503);
    assertEquals(res.headers.get("Content-Type"), "application/json");
    const body = await readJson(res);
    assertEquals(body.error, "contract_review_disabled");
    assertStringIncludes(String(body.message), "Contract Review");
  } finally {
    clearFlags();
  }
});

Deno.test("T04b — contract-review index.ts wires the kill switch", async () => {
  const src = await Deno.readTextFile(
    new URL("../contract-review/index.ts", import.meta.url),
  );
  assertStringIncludes(src, 'from "../_shared/kill_switches.ts"');
  assertStringIncludes(src, 'flagOn("CONTRACT_REVIEW_DISABLED")');
  assertStringIncludes(src, "return contractReviewDisabledResponse()");
});

// =============================================================================
// T05 — CONTRACT_REVIEW_DISABLED=true → classify-contract returns 503
// =============================================================================
Deno.test("T05 — classify-contract index.ts wires the kill switch", async () => {
  const src = await Deno.readTextFile(
    new URL("../classify-contract/index.ts", import.meta.url),
  );
  assertStringIncludes(src, 'from "../_shared/kill_switches.ts"');
  assertStringIncludes(src, 'flagOn("CONTRACT_REVIEW_DISABLED")');
  assertStringIncludes(src, "return contractReviewDisabledResponse()");
});

Deno.test("T05b — classify guard short-circuits BEFORE the auth/Haiku call", async () => {
  const src = await Deno.readTextFile(
    new URL("../classify-contract/index.ts", import.meta.url),
  );
  // The guard must appear BEFORE requireUserWithRateLimit so we don't bill
  // anything (incl. the auth round-trip) when the kill switch is flipped.
  const guardIdx = src.indexOf('flagOn("CONTRACT_REVIEW_DISABLED")');
  // Look for the actual CALL site, not the import line.
  const authIdx = src.indexOf("requireUserWithRateLimit(req");
  assert(guardIdx > 0, "guard must exist in classify-contract/index.ts");
  assert(authIdx > 0, "auth call must exist in classify-contract/index.ts");
  assert(
    guardIdx < authIdx,
    "kill-switch guard must run before requireUserWithRateLimit",
  );
});

Deno.test("T05c — contract-review guard short-circuits BEFORE the auth call", async () => {
  const src = await Deno.readTextFile(
    new URL("../contract-review/index.ts", import.meta.url),
  );
  const guardIdx = src.indexOf('flagOn("CONTRACT_REVIEW_DISABLED")');
  // Look for the actual CALL site, not the import line.
  const authIdx = src.indexOf("requireUserWithRateLimit(req");
  assert(guardIdx > 0);
  assert(authIdx > 0);
  assert(
    guardIdx < authIdx,
    "kill-switch guard must run before requireUserWithRateLimit",
  );
});

Deno.test("T05d — claude-proxy maintenance guard runs BEFORE auth", async () => {
  const src = await Deno.readTextFile(
    new URL("../claude-proxy/index.ts", import.meta.url),
  );
  const guardIdx = src.indexOf('flagOn("CLAUDE_PROXY_MAINTENANCE")');
  // Look for the actual CALL site, not the import line.
  const authIdx = src.indexOf("requireUserWithRateLimit(req");
  assert(guardIdx > 0);
  assert(authIdx > 0);
  assert(
    guardIdx < authIdx,
    "maintenance guard must run before any auth / DB work",
  );
});

// =============================================================================
// T06 — All flags unset → all guards no-op (backward compatibility)
// =============================================================================
Deno.test("T06 — flagOn returns false when env is unset (default behavior)", () => {
  clearFlags();
  assertFalse(flagOn("CLAUDE_PROXY_MAINTENANCE"));
  assertFalse(flagOn("ANON_CHAT_DISABLED"));
  assertFalse(flagOn("CONTRACT_REVIEW_DISABLED"));
});

Deno.test("T06b — flagOn only triggers on literal 'true' (not '1', 'yes', 'false')", () => {
  clearFlags();
  for (const value of ["1", "yes", "True", "TRUE", "false", "no", ""]) {
    Deno.env.set("CLAUDE_PROXY_MAINTENANCE", value);
    assertFalse(
      flagOn("CLAUDE_PROXY_MAINTENANCE"),
      `value '${value}' must not enable the kill switch`,
    );
  }
  clearFlags();
});

Deno.test("T06c — flagOn triggers exactly on 'true'", () => {
  clearFlags();
  Deno.env.set("CLAUDE_PROXY_MAINTENANCE", "true");
  assert(flagOn("CLAUDE_PROXY_MAINTENANCE"));
  clearFlags();
});
