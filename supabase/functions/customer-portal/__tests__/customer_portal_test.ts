// Source-contract tests for customer-portal Edge Function.
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-read \
//     supabase/functions/customer-portal/__tests__/customer_portal_test.ts
//
// Pre-launch QA pass (2026-04-29) — customer-portal had ZERO tests. These
// tests pin the current behaviour as a regression baseline.
//
// Sprint 1 hardening (2026-05-19) — all five gaps documented in the original
// test suite (T16/T17/T18/T19 + missing AbortSignal timeout) were closed in
// the same edit pass. The tests below now assert the hardened state.
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

Deno.test("CP-T01 — uses requireUserWithRateLimit JWT gate", () => {
  // We delegate JWT validation + rate-limit to the shared helper. If the
  // gate denies, the function returns the helper's 401/429 response.
  assertStringIncludes(stripped, "requireUserWithRateLimit");
  assertStringIncludes(stripped, 'bucket: "customer-portal"');
});

Deno.test("CP-T02 — auth gate runs before any Stripe call", () => {
  // The gate (which calls supabase.auth.getUser) must happen BEFORE any
  // fetch() to Stripe. Otherwise a forged token could trigger Stripe API
  // calls (and receipt emails).
  const gateIdx = stripped.indexOf("requireUserWithRateLimit");
  const stripeFetchIdx = stripped.indexOf("api.stripe.com");
  assert(gateIdx !== -1, "Must call requireUserWithRateLimit");
  assert(stripeFetchIdx !== -1, "Must call Stripe API");
  assert(
    gateIdx < stripeFetchIdx,
    "Auth must run before Stripe fetch — otherwise unauth requests waste " +
      "Stripe API quota and surface error details",
  );
});

Deno.test("CP-T03 — denied gate returns helper response (401/429)", () => {
  // The auth gate path returns gate.response on deny.
  assertStringIncludes(stripped, 'gate.kind === "deny"');
  assertStringIncludes(stripped, "return gate.response");
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

Deno.test("CP-T10 — Stripe error from portal creation returns 400 with generic message", () => {
  // If Stripe rejects (e.g. customer doesn't exist in this Stripe mode),
  // surface a generic error to the client. We do NOT echo session.error.message
  // anymore (Sprint 1 PII scrub) — Stripe error strings sometimes embed the
  // customer object.
  assertStringIncludes(stripped, "session.error");
  assertStringIncludes(stripped, '"Failed to open billing portal"');
  assertFalse(
    /session\.error\.message/.test(stripped),
    "Must not echo raw Stripe error.message — may contain PII",
  );
});

Deno.test("CP-T11 — successful portal creation returns 200 with url field", () => {
  // Body shape: { url: session.url } — verify via jsonOk helper.
  assertStringIncludes(stripped, "jsonOk({ url: session.url })");
});

// ---- CORS ------------------------------------------------------------------

Deno.test("CP-T12 — uses shared corsHeaders from _shared/auth.ts", () => {
  // Sprint 1 hardening: inline corsHeaders replaced with shared constant.
  // The shared constant restricts Allow-Origin to https://advocat.ee.
  assertStringIncludes(stripped, '"../_shared/auth.ts"');
  assertStringIncludes(stripped, "corsHeaders");
});

Deno.test("CP-T13 — does NOT define inline Allow-Methods (uses shared)", () => {
  // The shared corsHeaders constant defines POST, OPTIONS — verify we don't
  // shadow it with a more permissive inline header.
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

Deno.test("CP-T15 — outer catch returns 500 with generic message (no PII leak)", () => {
  assertStringIncludes(stripped, "} catch (error) {");
  assertStringIncludes(stripped, '"Internal error"');
  // Sprint 1: we must NOT return String(error) to the client anymore.
  assertFalse(
    /error:\s*String\(error\)/.test(stripped),
    "Must not echo raw error to client — Sprint 1 PII scrub",
  );
});

// ---- Hardening assertions (Sprint 1 closed) -------------------------------

Deno.test("CP-T16 — USES requireUserWithRateLimit (Sprint 1 closed)", () => {
  assert(
    stripped.includes("requireUserWithRateLimit"),
    "Sprint 1 hardening: must rate-limit Stripe portal creation",
  );
});

Deno.test("CP-T17 — USES _shared/auth.ts corsHeaders (Sprint 1 closed)", () => {
  assert(
    stripped.includes("../_shared/auth.ts"),
    "Sprint 1 hardening: must use shared corsHeaders constant",
  );
});

Deno.test("CP-T18 — error log truncated (Sprint 1 PII scrub closed)", () => {
  // console.error must slice the error message to bound PII exposure.
  assertStringIncludes(stripped, ".slice(0, 200)");
});

Deno.test("CP-T19 — null-check on customerId from Stripe creation (Sprint 1 closed)", () => {
  // After `customerId = customer.id`, we must throw / return early if
  // customer.id was missing (e.g. Stripe returned an error envelope).
  const assignIdx = stripped.indexOf("customerId = customer.id");
  assert(assignIdx !== -1, "expected `customerId = customer.id` assignment");
  // Check pre-assign guards: !res.ok or !customer?.id branch.
  const head = stripped.slice(Math.max(0, assignIdx - 600), assignIdx + 200);
  const hasGuard = /if\s*\(\s*!\s*res\.ok\s*\)/.test(head) ||
    /if\s*\(\s*!\s*customer\??\.id\s*\)/.test(head);
  assert(hasGuard, "Must guard Stripe response before using customer.id");
});

Deno.test("CP-T20 — AbortSignal.timeout on outbound Stripe fetch (Sprint 1 closed)", () => {
  // Without a timeout an unhealthy Stripe API could hang the edge fn until
  // Supabase's wall-clock cap (~150s) — burns paying-user attempts.
  assertStringIncludes(stripped, "AbortSignal.timeout(");
});

// ---- Path inspection: still uses fetch() not Stripe SDK -------------------

Deno.test("CP-T21 — uses fetch() with Bearer Stripe key (no SDK)", () => {
  // create-checkout uses the Stripe Deno SDK; customer-portal uses raw fetch.
  // This is fine but worth pinning so a refactor doesn't silently change auth
  // mechanism.
  assertStringIncludes(stripped, "fetch(");
  assertStringIncludes(stripped, "Bearer ${STRIPE_SECRET_KEY}");
});
