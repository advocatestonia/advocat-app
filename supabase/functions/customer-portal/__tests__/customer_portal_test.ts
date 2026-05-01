// Source-contract tests for customer-portal Edge Function.
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-read \
//     supabase/functions/customer-portal/__tests__/customer_portal_test.ts
//
// Pre-launch QA pass (2026-04-29) — customer-portal had ZERO tests. These
// tests pin the current behaviour as a regression baseline and flag the
// hardening gaps that should be closed before scale (rate-limit, shared CORS,
// PII-scrub on logs).
//
// FLAGGED GAPS (not blocking launch — Sofia is the only paying user, so
// abuse risk is minimal — but should be fixed during Sprint 1 hardening):
//   - No requireUserWithRateLimit gate (vs. create-checkout's 5/min)
//   - Inline corsHeaders instead of shared _shared/auth.ts constant
//   - console.error logs full error string (no .slice(0, 200))
//   - No null-check on customerId returned from Stripe customer creation
// -----------------------------------------------------------------------------

import {
  assert,
  assertFalse,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

const source = await Deno.readTextFile(
  new URL("../index.ts", import.meta.url),
);

const stripped = source
  .replace(/\/\*[\s\S]*?\*\//g, "")
  .replace(/^\s*\/\/.*$/gm, "");

// ---- Authorization & request shape ----------------------------------------

Deno.test("CP-T01 — requires Authorization header (returns 401 if missing)", () => {
  // Without a bearer token, the function must not create any Stripe portal.
  // Otherwise an attacker could enumerate/manipulate customer accounts.
  assertStringIncludes(stripped, 'req.headers.get("Authorization")');
  assertStringIncludes(stripped, "Missing authorization");
  assertStringIncludes(stripped, "status: 401");
});

Deno.test("CP-T02 — verifies JWT via supabase.auth.getUser before any Stripe call", () => {
  // The auth.getUser() call must happen BEFORE any fetch() to Stripe.
  // Otherwise a forged token could trigger Stripe API calls (and receipt emails).
  const authIdx = stripped.indexOf("supabase.auth.getUser(");
  const stripeFetchIdx = stripped.indexOf("api.stripe.com");
  assert(authIdx !== -1, "Must call supabase.auth.getUser");
  assert(stripeFetchIdx !== -1, "Must call Stripe API");
  assert(
    authIdx < stripeFetchIdx,
    "Auth must run before Stripe fetch — otherwise unauth requests waste " +
      "Stripe API quota and surface error details",
  );
});

Deno.test("CP-T03 — invalid token returns 401 Unauthorized", () => {
  // The auth.getUser path must reject when authError is set or user is null.
  assertStringIncludes(stripped, "authError");
  assertStringIncludes(stripped, '"Unauthorized"');
});

// ---- Stripe customer resolution -------------------------------------------

Deno.test("CP-T04 — looks up profile by authenticated user.id (not email)", () => {
  // The lookup must use user.id (UUID) — using email would let attackers who
  // know a victim's email enumerate or hijack their portal session.
  assertStringIncludes(stripped, '.eq("id", user.id)');
  assertStringIncludes(stripped, 'from("profiles")');
});

Deno.test("CP-T05 — selects only stripe_customer_id and email columns", () => {
  // Defence in depth: don't hydrate the entire profile row into memory.
  assertStringIncludes(stripped, '"stripe_customer_id, email"');
});

Deno.test("CP-T06 — creates Stripe customer when profile has no stripe_customer_id", () => {
  // First-time portal user (paid before stripe_customer_id was wired in).
  // Must create a Stripe customer record and persist it back to profiles.
  assertStringIncludes(stripped, "/v1/customers");
  assertStringIncludes(stripped, "supabase_user_id: user.id");
});

Deno.test("CP-T07 — created Stripe customer ID is persisted to profiles row", () => {
  // After creating a Stripe customer, we MUST write the id back so
  // subsequent calls don't create duplicates.
  assertStringIncludes(stripped, "stripe_customer_id: customerId");
  assertStringIncludes(stripped, '.eq("id", user.id)');
});

// ---- Portal session creation -----------------------------------------------

Deno.test("CP-T08 — calls billing_portal/sessions endpoint with customer + return_url", () => {
  assertStringIncludes(stripped, "/v1/billing_portal/sessions");
  assertStringIncludes(stripped, "customer: customerId");
  assertStringIncludes(stripped, "return_url:");
});

Deno.test("CP-T09 — return_url is hardcoded to advocat.ee/app.html (no open redirect)", () => {
  // Critical: if return_url were taken from the request body, an attacker
  // could phish the user back to a malicious page after they manage their
  // subscription. We hardcode it.
  assertStringIncludes(stripped, '"https://advocat.ee/app.html"');
  // Verify return_url is NOT taken from req.json() body.
  assertFalse(
    /return_url:\s*[^\n]*req\.json/.test(stripped),
    "return_url must NOT come from request body — open redirect vector",
  );
});

Deno.test("CP-T10 — Stripe error from portal creation returns 400 with message", () => {
  // If Stripe rejects (e.g. customer doesn't exist in this Stripe mode),
  // surface the error to the client so the UI shows something useful.
  assertStringIncludes(stripped, "session.error");
  assertStringIncludes(stripped, "status: 400");
});

Deno.test("CP-T11 — successful portal creation returns 200 with url field", () => {
  // Body shape: { url: session.url } — verify both halves separately.
  assertStringIncludes(stripped, "url: session.url");
  assertStringIncludes(stripped, "status: 200");
});

// ---- CORS ------------------------------------------------------------------

Deno.test("CP-T12 — CORS Allow-Origin restricted to https://advocat.ee", () => {
  // Wildcard '*' would let any site with a logged-in user spawn portal
  // sessions. Whitelist advocat.ee only.
  assertStringIncludes(
    stripped,
    '"Access-Control-Allow-Origin": "https://advocat.ee"',
  );
  assertFalse(
    /"Access-Control-Allow-Origin"\s*:\s*"\*"/.test(stripped),
    "CORS must NOT allow * origin — would enable cross-origin portal abuse",
  );
});

Deno.test("CP-T13 — CORS Allow-Methods are POST + OPTIONS only", () => {
  assertStringIncludes(stripped, "POST, OPTIONS");
  // GET should NOT be allowed.
  assertFalse(
    /Allow-Methods[^"]*"GET/.test(stripped),
    "GET must not be allowed — portal session creation is a state mutation",
  );
});

Deno.test("CP-T14 — OPTIONS preflight returns CORS headers", () => {
  assertStringIncludes(stripped, 'req.method === "OPTIONS"');
  assertStringIncludes(stripped, "headers: corsHeaders");
});

// ---- Error handling --------------------------------------------------------

Deno.test("CP-T15 — outer catch returns 500 on unexpected error", () => {
  assertStringIncludes(stripped, "} catch (error) {");
  assertStringIncludes(stripped, "status: 500");
});

// ---- HARDENING GAPS (informational, not blocking) -------------------------
//
// These tests document gaps that exist today. They PASS on the current code
// (i.e. they assert the gap is present) so they show up as a TODO list when
// reviewing the test output, not as red builds. Convert to "must NOT have"
// during Sprint 1 hardening.

Deno.test("CP-T16 [GAP] — does NOT use requireUserWithRateLimit (Sprint 1)", () => {
  // TODO Sprint 1: import requireUserWithRateLimit from _shared/auth.ts and
  // gate with bucket="customer-portal", maxPerMinute=10.
  // Stripe portal creation costs API quota and creates billing-portal sessions
  // that send emails. Without rate-limit, a malicious authenticated user could
  // spam.
  assertFalse(
    stripped.includes("requireUserWithRateLimit"),
    "If this fires, the gap was closed — flip the assertion. (Sprint 1)",
  );
});

Deno.test("CP-T17 [GAP] — does NOT use _shared/auth.ts corsHeaders (Sprint 1)", () => {
  // TODO Sprint 1: replace inline corsHeaders with shared constant so origin
  // changes happen in one place.
  assertFalse(
    stripped.includes("../_shared/auth.ts"),
    "If this fires, customer-portal now imports the shared module. " +
      "Update this test to assert it DOES use it.",
  );
});

Deno.test("CP-T18 [GAP] — error log does NOT truncate (Sprint 1 PII scrub)", () => {
  // TODO Sprint 1: console.error(String(error).slice(0, 200)) — Stripe errors
  // can include the customer object with email. We currently log the full
  // error.
  // Note: there's no console.error in this file at all today — the catch
  // just returns 500 with the error stringified into the body. Even worse:
  // we leak the raw error to the CLIENT.
  const stringifiesToClient = /error: String\(error\)/.test(stripped);
  assert(
    stringifiesToClient,
    "Today's behaviour: raw error reaches the client. Sprint 1: scrub.",
  );
});

Deno.test("CP-T19 [GAP] — no null-check on customerId from Stripe creation (Sprint 1)", () => {
  // TODO Sprint 1: if Stripe rejects /v1/customers (rate limit, network), the
  // response JSON is {error: ...} not {id: ...}, and customerId becomes
  // undefined. The subsequent .update({stripe_customer_id: undefined}) call
  // is a no-op but logs an awkward null. The portal creation then fails
  // because customer is "undefined".
  //
  // Defence: AFTER `customerId = customer.id`, throw if customerId is
  // falsy. Today there is exactly one `if (!customerId)` guard, but it sits
  // BEFORE the assignment (it gates the customer-creation branch). What we
  // want is a SECOND guard right after the assignment — that one is missing.
  //
  // Locate the assignment, then look in the 200 chars that follow.
  const assignIdx = stripped.indexOf("customerId = customer.id;");
  assert(assignIdx !== -1, "expected `customerId = customer.id;` assignment");
  const tail = stripped.slice(assignIdx, assignIdx + 400);
  const hasPostAssignGuard = /if\s*\(\s*!\s*customerId\s*\)/.test(tail) ||
    /if\s*\(\s*!\s*customer\.id\s*\)/.test(tail) ||
    /if\s*\(\s*customer\.error\s*\)/.test(tail);
  assertFalse(
    hasPostAssignGuard,
    "If this fires, customer-portal now guards the Stripe response. " +
      "Update this test to assert it DOES (Sprint 1 hardening complete).",
  );
});

// ---- Path inspection: still uses fetch() not Stripe SDK -------------------

Deno.test("CP-T20 — uses fetch() with Bearer Stripe key (no SDK)", () => {
  // create-checkout uses the Stripe Deno SDK; customer-portal uses raw fetch.
  // This is fine but worth pinning so a refactor doesn't silently change auth
  // mechanism.
  assertStringIncludes(stripped, "fetch(");
  assertStringIncludes(stripped, "Bearer ${STRIPE_SECRET_KEY}");
});
