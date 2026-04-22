// Deno-runtime tests for create-checkout (FIX-7 — Sprint 0).
// -----------------------------------------------------------------------------
// Source-code contract tests (static analysis). A full integration test
// would need a Stripe test account and Supabase Auth instance — that is
// covered by the owner's manual smoke after deploy.
//
// Run with:
//   deno test --allow-read \
//     supabase/functions/create-checkout/__tests__/create_checkout_auth_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertFalse,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

const source = await Deno.readTextFile(
  new URL("../index.ts", import.meta.url),
);

// Strip comments so doc references to the old behaviour don't create
// false positives in the "must not accept body email" check below.
const stripped = source
  .replace(/\/\*[\s\S]*?\*\//g, "")
  .replace(/^\s*\/\/.*$/gm, "");

Deno.test("F7-T01 — imports requireUserWithRateLimit from shared auth", () => {
  assertStringIncludes(source, "requireUserWithRateLimit");
  assertStringIncludes(source, "_shared/auth.ts");
});

Deno.test("F7-T02 — applies the JWT gate before Stripe call", () => {
  const gateIdx = stripped.indexOf("requireUserWithRateLimit(");
  const stripeCreateIdx = stripped.indexOf("stripe.checkout.sessions.create(");
  assert(gateIdx !== -1, "Must call requireUserWithRateLimit");
  assert(stripeCreateIdx !== -1, "Must call Stripe create session");
  assert(
    gateIdx < stripeCreateIdx,
    "Gate must run before Stripe call — otherwise unauthenticated requests " +
      "would still spend Stripe API quota and surface error details.",
  );
});

Deno.test("F7-T03 — rate limit is 5 per minute (founding / phishing cap)", () => {
  assertStringIncludes(source, "bucket: \"create-checkout\"");
  assertStringIncludes(source, "maxPerMinute: 5");
});

Deno.test("F7-T04 — body destructure does NOT read customer_email", () => {
  // Pre-FIX-7: `const { ..., customer_email } = await req.json();`
  // After FIX-7: destructure must not include customer_email at all.
  // We look in the non-comment source for a destructure list.
  const destructureMatch = stripped.match(
    /await\s+req\s*\.json\(\)\s*;/,
  );
  assert(
    destructureMatch,
    "Handler must still parse JSON body (checked indirectly via req.json)",
  );
  // Search for `customer_email` in a non-comment context — anywhere it
  // appears should be the Stripe API field `customer_email =` assignment,
  // never a destructure from the body.
  const customerEmailMatches = [
    ...stripped.matchAll(/customer_email/g),
  ];
  assertFalse(
    customerEmailMatches.length === 0,
    "Code must still set customer_email on the Stripe session (from auth)",
  );
  // The only occurrences must be on the left-hand side of assignment
  // or inside a property access — never in a destructure list from req.json.
  const destructureRegex = /\{[^{}]*customer_email[^{}]*\}\s*=\s*await\s+req\s*\.\s*json/;
  assertFalse(
    destructureRegex.test(stripped),
    "customer_email must NOT be destructured from the request body — that " +
      "was the pre-FIX-7 phishing vector (see docs/security/02-auth-authz.md H2)",
  );
});

Deno.test("F7-T05 — customer_email is sourced from gate.user.email", () => {
  assertStringIncludes(
    stripped,
    "gate.user.email",
    "customer_email must come from the authenticated session (gate.user.email), " +
      "never from the client body.",
  );
});

Deno.test("F7-T06 — Stripe metadata records the authenticated user_id", () => {
  // The webhook currently resolves users by email; also recording user_id
  // in session metadata is a defence in depth — if a user changes their
  // email after checkout, we can still map the session back to the
  // correct profiles row.
  assertStringIncludes(stripped, "user_id: gate.user.id");
});

Deno.test("F7-T07 — CORS uses shared header constants (no inline origin)", () => {
  // Prevents drift. If this fails, someone hand-rolled CORS again.
  assertStringIncludes(source, "corsHeaders");
  // Make sure no hardcoded origin sneaked back in. Comments are stripped.
  assertFalse(
    /Access-Control-Allow-Origin['"]\s*:\s*['"]https:\/\/advocat\.ee['"]/
      .test(stripped),
    "Origin must come from the shared corsHeaders constant, not inline",
  );
});

Deno.test("F7-T08 — error responses use jsonError helper (consistent shape)", () => {
  assertStringIncludes(source, "jsonError(");
});

Deno.test("F7-T09 — log sanitises PII (truncates message, no full stack)", () => {
  // Stripe errors often include the customer object in their message.
  // We must not dump a full error into our logs.
  assertStringIncludes(
    stripped,
    "message.slice(0, 200)",
    "console.error must truncate the Stripe error message to prevent PII " +
      "from leaking into log files",
  );
});
