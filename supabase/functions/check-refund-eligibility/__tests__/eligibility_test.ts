// Deno source-contract tests for check-refund-eligibility Edge Function.
// -----------------------------------------------------------------------------
// Like create-checkout/__tests__/create_checkout_auth_test.ts, these are
// static-analysis tests: they assert the index.ts *imports* and *calls* the
// right shared primitives (JWT gate, refund-policy evaluator). A full
// integration test would need a live Supabase + paying user and is out of
// scope — manual smoke after deploy covers that path.
//
// Run with:
//   deno test --allow-read \
//     supabase/functions/check-refund-eligibility/__tests__/eligibility_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertFalse,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

const source = await Deno.readTextFile(
  new URL("../index.ts", import.meta.url),
);

// Strip comments so doc strings don't create false positives.
const stripped = source
  .replace(/\/\*[\s\S]*?\*\//g, "")
  .replace(/^\s*\/\/.*$/gm, "");

Deno.test("CRE-T01 — imports evaluateRefund from shared module", () => {
  assertStringIncludes(source, "evaluateRefund");
  assertStringIncludes(source, "_shared/refund_policy.ts");
});

Deno.test("CRE-T02 — imports JWT gate + CORS helpers from shared auth", () => {
  assertStringIncludes(source, "requireUserWithRateLimit");
  assertStringIncludes(source, "_shared/auth.ts");
});

Deno.test("CRE-T03 — JWT gate runs before any Supabase query", () => {
  const gateIdx = stripped.indexOf("requireUserWithRateLimit(");
  const supabaseFromIdx = stripped.indexOf(".from(");
  assert(gateIdx !== -1, "Must call requireUserWithRateLimit");
  assert(supabaseFromIdx !== -1, "Must query at least one table");
  assert(
    gateIdx < supabaseFromIdx,
    "Gate must run before any DB query — unauthenticated requests must " +
      "not burn service-role SELECTs.",
  );
});

Deno.test("CRE-T04 — rate limit is 10 per minute (read-only endpoint)", () => {
  assertStringIncludes(source, 'bucket: "check-refund-eligibility"');
  assertStringIncludes(source, "maxPerMinute: 10");
});

Deno.test("CRE-T05 — queries subscriptions table by authenticated user_id", () => {
  assertStringIncludes(stripped, 'from("subscriptions")');
  // Must filter by the JWT-resolved user, not a body-supplied id.
  assertStringIncludes(stripped, "gate.user.id");
});

Deno.test("CRE-T06 — response exposes eligible + reason + deadline + messages_remaining", () => {
  assertStringIncludes(stripped, "eligible");
  assertStringIncludes(stripped, "reason");
  assertStringIncludes(stripped, "deadline");
  assertStringIncludes(stripped, "messages_remaining");
});

Deno.test("CRE-T07 — body user_id is NOT trusted (defence against spoofing)", () => {
  // If the Edge Function accepted a body-supplied user_id, a malicious
  // client could check another user's refund status. We always use the
  // JWT-resolved id.
  //
  // The function may still accept a subscription_id hint in the body to
  // scope by specific subscription, but never user_id.
  const destructureRegex =
    /\{[^{}]*user_id[^{}]*\}\s*=\s*await\s+req\s*\.\s*json/;
  assertFalse(
    destructureRegex.test(stripped),
    "user_id must NOT be destructured from the request body — use JWT only.",
  );
});

Deno.test("CRE-T08 — returns 404 when no active subscription exists", () => {
  // Free-tier users can't have a refund window — the endpoint returns 404
  // so the client treats it as "no active paid plan", not an error.
  assertStringIncludes(stripped, "404");
});

Deno.test("CRE-T09 — uses shared jsonError / jsonOk helpers", () => {
  assertStringIncludes(source, "jsonError");
  // jsonOk is also fine — or a Response with corsHeaders; check at least one.
  const usesShared = source.includes("jsonOk") ||
    source.includes("corsHeaders");
  assert(
    usesShared,
    "Must use shared CORS/response helpers — no hand-rolled headers.",
  );
});

Deno.test("CRE-T10 — OPTIONS preflight returns 204 with corsHeaders", () => {
  assertStringIncludes(stripped, "OPTIONS");
  assertStringIncludes(source, "corsHeaders");
});
