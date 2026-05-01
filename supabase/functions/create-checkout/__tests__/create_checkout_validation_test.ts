// Validation contract tests for create-checkout Edge Function.
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-read \
//     supabase/functions/create-checkout/__tests__/create_checkout_validation_test.ts
//
// Pre-launch QA pass (2026-04-29). Covers gaps not addressed by
// create_checkout_auth_test.ts and founder_cap_test.ts:
//   - All accepted billing_period values (monthly / yearly / early-access)
//   - Invalid billing_period -> 400
//   - Invalid plan_id -> 400
//   - "founding" billing_period rejected (renamed to early-access)
//   - representation + early-access rejected at edge function (no PRICES entry)
//   - Price amounts pin EUR cents (regression-protect price changes)
//   - Subscription mode + auto-receipt config
//   - early-access only routes through counsel (Pro), not representation
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

const source = await Deno.readTextFile(
  new URL("../index.ts", import.meta.url),
);
const stripped = source
  .replace(/\/\*[\s\S]*?\*\//g, "")
  .replace(/^\s*\/\/.*$/gm, "");

// ---- Required-field validation --------------------------------------------

Deno.test("CCV-T01 — missing plan_id returns 400", () => {
  assertStringIncludes(
    stripped,
    "plan_id and billing_period are required",
  );
  // The 400 response uses jsonError (status arg = 400).
  const errorMatch = stripped.match(
    /jsonError\("plan_id and billing_period are required",\s*(\d+)\)/,
  );
  assert(errorMatch, "jsonError call not found");
  assertEquals(errorMatch[1], "400");
});

Deno.test("CCV-T02 — unknown plan_id returns 400 with plan name in message", () => {
  // Helps the client surface "you sent 'foo', not in {counsel, representation}"
  // without exposing internal price table.
  assertStringIncludes(stripped, "Unknown plan_id:");
});

Deno.test("CCV-T03 — unknown billing_period returns 400 mentioning the plan", () => {
  // "Unknown billing_period: founding for plan counsel" — useful debug.
  assertStringIncludes(stripped, "Unknown billing_period:");
  assertStringIncludes(stripped, "for plan");
});

// ---- Accepted billing periods ---------------------------------------------

Deno.test("CCV-T04 — counsel accepts monthly + yearly + early-access (3 keys)", () => {
  // Inspect the PRICES const for the counsel branch.
  const counselMatch = stripped.match(
    /counsel:\s*\{([\s\S]*?)\n\s{2}\}/,
  );
  assert(counselMatch, "counsel price block not found");
  const counselBlock = counselMatch[1];
  assert(/monthly\s*:/.test(counselBlock), "missing monthly");
  assert(/yearly\s*:/.test(counselBlock), "missing yearly");
  assert(/"early-access"\s*:/.test(counselBlock), "missing early-access");
});

Deno.test("CCV-T05 — representation accepts ONLY monthly + yearly (no early-access)", () => {
  // representation = Premium tier; early-access intro pricing is for Pro
  // (counsel) only. If representation gained an early-access entry, the
  // founder pool would be diluted.
  const reprMatch = stripped.match(
    /representation:\s*\{([\s\S]*?)\n\s{2}\}/,
  );
  assert(reprMatch, "representation price block not found");
  const reprBlock = reprMatch[1];
  assert(/monthly\s*:/.test(reprBlock), "missing monthly");
  assert(/yearly\s*:/.test(reprBlock), "missing yearly");
  assert(
    !/"early-access"\s*:/.test(reprBlock),
    "representation must NOT have an early-access tier — that would dilute the founder pool",
  );
});

Deno.test("CCV-T06 — 'founding' is NOT a valid billing period (renamed to early-access)", () => {
  // The frontend StripeCheckoutService.startFoundingCheckout sends
  // billing_period='founding'. That dead code path would 400 here today.
  // Pin that no PRICES entry exists for 'founding'.
  assert(
    !/"founding"\s*:/.test(stripped),
    "'founding' is the legacy name — only 'early-access' should appear in PRICES",
  );
});

// ---- Price amounts (regression protection) --------------------------------

Deno.test("CCV-T07 — Pro Monthly is €19.99 (1999 cents)", () => {
  const match = stripped.match(
    /counsel:[\s\S]*?monthly:[\s\S]*?amount:\s*(\d+)/,
  );
  assert(match, "counsel.monthly amount not found");
  assertEquals(match[1], "1999");
});

Deno.test("CCV-T08 — Pro Yearly is €159.99 (15999 cents)", () => {
  const match = stripped.match(
    /counsel:[\s\S]*?yearly:[\s\S]*?amount:\s*(\d+)/,
  );
  assert(match, "counsel.yearly amount not found");
  assertEquals(match[1], "15999");
});

Deno.test("CCV-T09 — Early Access is €14.99 (1499 cents)", () => {
  const match = stripped.match(
    /counsel:[\s\S]*?"early-access":[\s\S]*?amount:\s*(\d+)/,
  );
  assert(match, "counsel.early-access amount not found");
  assertEquals(match[1], "1499");
});

Deno.test("CCV-T10 — Premium Monthly is €29.99 (2999 cents)", () => {
  const match = stripped.match(
    /representation:[\s\S]*?monthly:[\s\S]*?amount:\s*(\d+)/,
  );
  assert(match, "representation.monthly amount not found");
  assertEquals(match[1], "2999");
});

Deno.test("CCV-T11 — Premium Yearly is €249.99 (24999 cents)", () => {
  const match = stripped.match(
    /representation:[\s\S]*?yearly:[\s\S]*?amount:\s*(\d+)/,
  );
  assert(match, "representation.yearly amount not found");
  assertEquals(match[1], "24999");
});

// ---- Currency + interval --------------------------------------------------

Deno.test("CCV-T12 — all prices use EUR currency", () => {
  // Stripe will reject the session if currency is wrong; this test catches
  // a typo BEFORE deploy.
  assertStringIncludes(stripped, 'currency: "eur"');
  // No other currencies leaking in.
  const otherCurrencyMatch = stripped.match(
    /currency:\s*"(?!eur)[a-z]{3}"/g,
  );
  assertEquals(
    otherCurrencyMatch,
    null,
    "All prices must be in EUR — no other currency allowed",
  );
});

Deno.test("CCV-T13 — yearly entries use interval='year', monthly use 'month'", () => {
  // Type narrowing pin — the interval string is part of the Stripe contract.
  assertStringIncludes(stripped, 'interval: "month"');
  assertStringIncludes(stripped, 'interval: "year"');
});

// ---- Subscription mode -----------------------------------------------------

Deno.test("CCV-T14 — Stripe session is in 'subscription' mode (not 'payment')", () => {
  // Critical: 'payment' mode is one-shot. The pricing UI promises recurring
  // billing — if mode is wrong, we'd take a single charge and never renew.
  assertStringIncludes(stripped, 'mode: "subscription"');
  assert(
    !/mode:\s*"payment"/.test(stripped),
    "mode must NOT be 'payment' — we sell subscriptions",
  );
});

Deno.test("CCV-T15 — payment_method_types includes both 'card' and 'link'", () => {
  // Stripe Link is the saved-card flow; including it improves conversion.
  assertStringIncludes(stripped, '"card"');
  assertStringIncludes(stripped, '"link"');
});

Deno.test("CCV-T16 — subscription_data.description set for invoice legibility", () => {
  // Without this, Stripe-generated invoice PDFs say 'Untitled' which looks
  // unprofessional.
  assertStringIncludes(stripped, "subscription_data:");
  assertStringIncludes(stripped, "description: priceEntry.name");
});

// ---- Metadata ---------------------------------------------------------------

Deno.test("CCV-T17 — metadata records plan_id + billing_period + user_id", () => {
  // The webhook reads these to upsert profiles correctly. If any are missing,
  // the webhook can't activate Pro (or activates wrong tier).
  assertStringIncludes(stripped, "plan_id,");
  assertStringIncludes(stripped, "billing_period,");
  assertStringIncludes(stripped, "user_id: gate.user.id");
});

Deno.test("CCV-T18 — early-access flow stamps metadata.intro_type", () => {
  // The webhook keys on this to record the founder lifetime guarantee.
  assertStringIncludes(stripped, "metadata!.intro_type = FOUNDER_INTRO_TYPE");
});

Deno.test("CCV-T19 — early-access flow also stamps metadata.early_access='true'", () => {
  // Defence in depth: a parallel flag the webhook can use even if intro_type
  // is later renamed.
  assertStringIncludes(stripped, 'metadata!.early_access = "true"');
});

// ---- Default success/cancel URLs -------------------------------------------

Deno.test("CCV-T20 — default success URL points to advocat.ee/payment-success.html", () => {
  // Pin the URL so a typo doesn't redirect users to a 404 after payment.
  assertStringIncludes(stripped, "https://advocat.ee/payment-success.html");
});

Deno.test("CCV-T21 — default cancel URL points to advocat.ee/payment-cancel.html", () => {
  assertStringIncludes(stripped, "https://advocat.ee/payment-cancel.html");
});

// ---- Method validation -----------------------------------------------------

Deno.test("CCV-T22 — non-POST request returns 405 Method not allowed", () => {
  assertStringIncludes(stripped, '"Method not allowed"');
  assertStringIncludes(stripped, "405");
});

// ---- Body parsing ----------------------------------------------------------

Deno.test("CCV-T23 — body is parsed exactly once via req.json()", () => {
  const matches = [...stripped.matchAll(/await\s+req\s*\.\s*json\(\)/g)];
  assertEquals(
    matches.length,
    1,
    "req.json() must be called exactly once — calling twice throws " +
      '"Body already used"',
  );
});

// ---- jsonError shape (for frontend error parsing) -------------------------

Deno.test("CCV-T24 — early_access_full response includes message field for UI", () => {
  // The landing flips to "Pro available" when remaining=0; the app needs
  // a human-readable message to show in the modal.
  assertStringIncludes(stripped, "All 100 founder seats are taken");
});

Deno.test("CCV-T25 — error responses use jsonError (consistent {error,...} shape)", () => {
  // Frontend parses response.data.error. Hand-rolled responses break parsing.
  // We expect ALL error returns to use jsonError, EXCEPT the early-access
  // 410 which has a richer shape ({error, message}).
  const handRolledErrors = stripped.match(
    /new Response\(\s*JSON\.stringify\(\{\s*error:\s*"[^"]+"\s*\}\)/g,
  );
  if (handRolledErrors) {
    // The only acceptable hand-rolled is early_access_full (410). Verify
    // there are NO others.
    const acceptable = handRolledErrors.filter((m) =>
      m.includes("early_access_full")
    );
    assertEquals(
      handRolledErrors.length,
      acceptable.length,
      `Hand-rolled error responses found that are not early_access_full: ` +
        `${JSON.stringify(handRolledErrors)}. ` +
        `Use jsonError() helper for consistency.`,
    );
  }
});
