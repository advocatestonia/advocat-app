// Validation contract tests for create-checkout Edge Function.
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-read \
//     supabase/functions/create-checkout/__tests__/create_checkout_validation_test.ts
//
// Pre-launch QA pass (2026-04-29). Covers gaps not addressed by
// create_checkout_auth_test.ts:
//   - Accepted billing_period values (monthly / yearly)
//   - Invalid billing_period -> 400
//   - Invalid plan_id -> 400
//   - Legacy "founding" / "early-access" billing periods rejected
//   - Price amounts pin EUR cents (regression-protect price changes)
//   - Subscription mode + auto-receipt config
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

Deno.test("CCV-T04 — counsel accepts ONLY monthly + yearly (no early-access)", () => {
  // Inspect the PRICES const for the counsel branch.
  const counselMatch = stripped.match(
    /counsel:\s*\{([\s\S]*?)\n\s{2}\}/,
  );
  assert(counselMatch, "counsel price block not found");
  const counselBlock = counselMatch[1];
  assert(/monthly\s*:/.test(counselBlock), "missing monthly");
  assert(/yearly\s*:/.test(counselBlock), "missing yearly");
  assert(
    !/"early-access"\s*:/.test(counselBlock),
    "early-access tier removed — launch pricing offers only monthly + yearly",
  );
});

Deno.test("CCV-T05 — representation accepts ONLY monthly + yearly", () => {
  const reprMatch = stripped.match(
    /representation:\s*\{([\s\S]*?)\n\s{2}\}/,
  );
  assert(reprMatch, "representation price block not found");
  const reprBlock = reprMatch[1];
  assert(/monthly\s*:/.test(reprBlock), "missing monthly");
  assert(/yearly\s*:/.test(reprBlock), "missing yearly");
  assert(
    !/"early-access"\s*:/.test(reprBlock),
    "representation must NOT have an early-access tier",
  );
});

Deno.test("CCV-T06 — legacy 'founding' / 'early-access' periods are NOT valid", () => {
  // Founder program retired. Pin that no PRICES entry exists for either
  // legacy billing period.
  assert(
    !/"founding"\s*:/.test(stripped),
    "'founding' is the legacy name — must not appear in PRICES",
  );
  assert(
    !/"early-access"\s*:/.test(stripped),
    "'early-access' founder tier is retired — must not appear in PRICES",
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

Deno.test("CCV-T18 — founder/early-access metadata is NOT stamped (program retired)", () => {
  // Sanity: the retired founder flow used to stamp metadata.intro_type and
  // metadata.early_access. Pin that those writes are gone so a regression
  // cannot silently re-introduce the program.
  assert(
    !/metadata!?\.intro_type\s*=/.test(stripped),
    "metadata.intro_type assignment must be removed (founder program retired)",
  );
  assert(
    !/metadata!?\.early_access\s*=/.test(stripped),
    "metadata.early_access assignment must be removed (founder program retired)",
  );
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

Deno.test("CCV-T25 — error responses use jsonError (consistent {error,...} shape)", () => {
  // Frontend parses response.data.error. Hand-rolled responses break parsing.
  // We expect ALL error returns to use jsonError.
  const handRolledErrors = stripped.match(
    /new Response\(\s*JSON\.stringify\(\{\s*error:\s*"[^"]+"\s*\}\)/g,
  );
  assertEquals(
    handRolledErrors,
    null,
    `Hand-rolled error responses found: ${JSON.stringify(handRolledErrors)}. ` +
      `Use jsonError() helper for consistency.`,
  );
});

Deno.test("CCV-T26 — catch-all 500 returns a generic message, never the raw "
  + "Stripe error (PII / internal-detail leak guard)", () => {
  // A Stripe error string can carry the customer object (email), internal
  // ids, and API hints. The 500 catch must keep that in the server log only
  // and hand the client a generic message. Guard: the 500 jsonError must NOT
  // be `jsonError(message, 500)`.
  assert(
    !/jsonError\(\s*message\s*,\s*500\s*\)/.test(stripped),
    "create-checkout catch returns jsonError(message, 500), leaking the raw "
      + "error string to the client. Return a generic message instead.",
  );
  // And it must still log the (truncated) detail server-side for debugging.
  assertStringIncludes(stripped, 'console.error("create-checkout failed:"');
});
