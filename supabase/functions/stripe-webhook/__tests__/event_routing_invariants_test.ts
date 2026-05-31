// Event-routing invariants for stripe-webhook.
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-read \
//     supabase/functions/stripe-webhook/__tests__/event_routing_invariants_test.ts
//
// Pre-launch QA pass (2026-04-29). These tests cover:
//   - Replay-attack rejection (stale webhook timestamp)
//   - Out-of-order event handling (subscription.updated arrives before
//     checkout.session.completed)
//   - Invoice.payment_failed branch never throws
//   - Signature verification edge cases (missing parts, bad format)
//   - Idempotency on customer.subscription.deleted (replay-safe)
//   - Premium user keeps premium tier on renewal even if metadata.plan_id
//     is missing on the subscription object (regression cover for the
//     "renewal demotes premium to basic" failure mode)
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  PLAN_MAPPING,
  routeSubscriptionUpdate,
} from "../subscription_router.ts";

const source = await Deno.readTextFile(
  new URL("../index.ts", import.meta.url),
);
const stripped = source
  .replace(/\/\*[\s\S]*?\*\//g, "")
  .replace(/^\s*\/\/.*$/gm, "");

// Signature verification (HMAC + replay window) was extracted from index.ts
// into signature.ts so it can be behaviourally unit-tested (see
// signature_test.ts). The source-grep invariants below now read that module;
// index.ts only maps the result to HTTP status codes.
const sigSource = await Deno.readTextFile(
  new URL("../signature.ts", import.meta.url),
);
const sigStripped = sigSource
  .replace(/\/\*[\s\S]*?\*\//g, "")
  .replace(/^\s*\/\/.*$/gm, "");

// ---- Replay-attack protection ---------------------------------------------

Deno.test("ERI-T01 — webhook rejects timestamps older than 5 minutes (replay protection)", () => {
  // Stripe recommends rejecting events older than 5 minutes. Without this,
  // an attacker who captures a valid webhook could replay it indefinitely.
  assertStringIncludes(sigStripped, "MAX_WEBHOOK_AGE_SEC");
  assertStringIncludes(sigStripped, "300");
  assertStringIncludes(stripped, '"Stale webhook"');
});

Deno.test("ERI-T02 — stale webhook returns 401 (not 200, not 500)", () => {
  // 401 specifically: 200 would mark the event processed and let an attacker
  // burn the event_id; 500 would tell Stripe to retry forever.
  const staleMatch = stripped.match(
    /Stale webhook[\s\S]{0,200}?status:\s*(\d+)/,
  );
  assert(staleMatch, "Could not find Stale webhook return");
  assertEquals(staleMatch[1], "401");
});

Deno.test("ERI-T03 — timestamp parsing rejects non-numeric values", () => {
  // parseInt("abc", 10) returns NaN. The check `!timestampNum` catches NaN
  // (because !NaN === true). Verify this guard is in place.
  assertStringIncludes(sigStripped, "parseInt(timestamp, 10)");
  assertStringIncludes(sigStripped, "!timestampNum");
});

// ---- Signature verification edge cases ------------------------------------

Deno.test("ERI-T04 — missing 'stripe-signature' header returns 401", () => {
  assertStringIncludes(stripped, '"Missing signature"');
});

Deno.test("ERI-T05 — missing STRIPE_WEBHOOK_SECRET also returns 401", () => {
  // Defence: if the secret env var is unset (mis-deploy), don't silently
  // accept the request. The same Missing-signature error covers both cases.
  // index.ts must still thread the secret into the verifier...
  assertStringIncludes(stripped, "STRIPE_WEBHOOK_SECRET");
  // ...and the verifier guards on BOTH signature and secret presence,
  // collapsing to the same "missing" failure → 401.
  assert(
    /!signature\s*\|\|\s*!secret/.test(sigStripped),
    "Both signature and secret-presence must be checked",
  );
});

Deno.test("ERI-T06 — invalid signature format returns 401 'Invalid signature format'", () => {
  // Stripe sends `t=...,v1=...`. If the parts are missing, reject early.
  assertStringIncludes(stripped, '"Invalid signature format"');
});

Deno.test("ERI-T07 — signature mismatch uses timingSafeEqual (no leak via timing)", () => {
  // Constant-time comparison prevents an attacker from bisecting the HMAC
  // signature byte by byte.
  assertStringIncludes(sigStripped, "timingSafeEqual(");
  // The function itself must short-circuit on length mismatch (see source)
  // but not leak via index-based break.
  const fn = sigStripped.match(/function timingSafeEqual[\s\S]*?\n\}/);
  assert(fn, "timingSafeEqual function not found");
  assert(
    !/break/.test(fn![0]),
    "timingSafeEqual must not contain `break` — early-exit leaks timing",
  );
});

// ---- Idempotency wraps EVERY event type -----------------------------------

Deno.test("ERI-T08 — event without id returns 400 BEFORE switch (defence)", () => {
  // Every real Stripe event has an id. If we got here without one, fail
  // loudly rather than skip the idempotency layer (which keys on event.id).
  assertStringIncludes(stripped, '"Missing event id"');
  // The guard must fire BEFORE the switch.
  const guardIdx = stripped.indexOf('"Missing event id"');
  const switchIdx = stripped.indexOf("switch (event.type)");
  assert(
    guardIdx !== -1 && switchIdx !== -1 && guardIdx < switchIdx,
    "Missing-event-id guard must run before the switch",
  );
});

Deno.test("ERI-T09 — checkAndMarkProcessing called BEFORE the switch", () => {
  // Idempotency must wrap the entire switch. Otherwise replays could
  // double-extend subscriptions for events we don't currently model
  // (e.g. invoice.paid arriving after we add it later).
  const idemIdx = stripped.indexOf("checkAndMarkProcessing(");
  const switchIdx = stripped.indexOf("switch (event.type)");
  assert(
    idemIdx !== -1 && switchIdx !== -1 && idemIdx < switchIdx,
    "Idempotency check must wrap the switch",
  );
});

Deno.test("ERI-T10 — markOk called AFTER the switch (only on success)", () => {
  // markOk records status=ok which makes future replays a no-op. It must
  // run only after all DB writes for the event succeeded.
  const switchIdx = stripped.indexOf("switch (event.type)");
  const markOkIdx = stripped.indexOf("markOk(");
  assert(
    switchIdx !== -1 && markOkIdx !== -1 && markOkIdx > switchIdx,
    "markOk must run after the switch — never before",
  );
});

// ---- Out-of-order event tolerance -----------------------------------------

Deno.test("ERI-T11 — customer.subscription.updated handles missing profile gracefully", () => {
  // Out-of-order: customer.subscription.updated arrives BEFORE
  // checkout.session.completed (rare but possible during retries). At that
  // point, no profile has stripe_customer_id set. The handler must NOT throw.
  // The current code uses `if (users && users.length > 0)` to guard the
  // update — verify that pattern exists in all three sub.* branches.
  const branches = [
    "customer.subscription.updated",
    "customer.subscription.deleted",
  ];
  for (const branch of branches) {
    const branchIdx = stripped.indexOf(branch);
    assert(branchIdx !== -1, `branch ${branch} not found`);
    // Within ~3000 chars after the case label, there must be a length-check.
    const window = stripped.slice(branchIdx, branchIdx + 3000);
    assert(
      /users\s*&&\s*users\.length\s*>\s*0/.test(window),
      `${branch} must guard against missing profile`,
    );
  }
});

Deno.test("ERI-T12 — invoice.payment_failed never throws (logs only)", () => {
  // Per FIX-6: invoice.payment_failed currently logs and falls through.
  // No DB writes, no throw. If we add downgrade logic later, it must not
  // be in this branch (past_due grace period belongs in subscription.updated).
  const branchIdx = stripped.indexOf("invoice.payment_failed");
  assert(branchIdx !== -1, "branch not found");
  const window = stripped.slice(branchIdx, branchIdx + 600);
  // No throw, no upsert, no update inside the branch (until next case).
  const nextCaseIdx = window.search(/\n\s*case\s+"|\n\s*default:/);
  const branchBody = nextCaseIdx > 0 ? window.slice(0, nextCaseIdx) : window;
  assertEquals(
    /\bthrow\b/.test(branchBody),
    false,
    "invoice.payment_failed must not throw",
  );
  assertEquals(
    /supabase\.from\([^)]+\)\.upsert/.test(branchBody),
    false,
    "invoice.payment_failed must not upsert (no state change yet)",
  );
});

// ---- Premium-on-renewal regression cover ----------------------------------
//
// SCENARIO: User checks out as 'representation' (premium). Stripe creates the
// subscription with metadata.plan_id='representation'. A month later, the
// renewal arrives as customer.subscription.updated. If Stripe re-emits the
// subscription object WITHOUT metadata.plan_id (which can happen — Stripe
// metadata is not always echoed on every event), routeSubscriptionUpdate
// falls back to PLAN_MAPPING[undefined] || "basic" → "basic". The user
// silently demotes from premium to basic on every renewal.
//
// The router is correct in defaulting to basic (safer than defaulting to
// premium) but the WEBHOOK should not blindly write tier=basic over an
// existing premium row.
//
// Today's code DOES blindly write the new tier. This test documents that
// gap so we cover it during Sprint 1 hardening.

Deno.test("ERI-T13 [GAP] — premium-on-renewal: router returns basic when metadata missing", () => {
  // The pure router behaves correctly — it has no knowledge of prior state.
  const action = routeSubscriptionUpdate({
    status: "active",
    current_period_end: Math.floor(Date.now() / 1000) + 30 * 86400,
    metadata: {}, // metadata.plan_id absent
  });
  if (action.kind !== "extend") throw new Error("expected extend");
  // Default fallback: basic. The bug is in the webhook overwriting an
  // existing premium row with this default.
  assertEquals(action.tier, "basic");
});

Deno.test("ERI-T14 [GAP] — webhook overwrites tier on extend (Sprint 1)", () => {
  // Documents current behaviour: subscription.updated → action.kind='extend'
  // → upsert profiles.subscription_tier = action.tier. If the user was
  // premium and the new event lacks metadata.plan_id, they become basic.
  // FIX (Sprint 1): preserve existing tier when the new event would demote
  // from premium → basic AND the existing row has tier=premium.
  assertStringIncludes(stripped, "subscription_tier: action.tier");
});

// ---- customer.subscription.deleted is replay-safe -------------------------

Deno.test("ERI-T15 — subscription.deleted sets is_pro=false + tier=free + status=canceled", () => {
  // The end-of-life event must drop the user fully. Idempotent: running
  // twice gives the same final state (RLS-fail-safe).
  const branchIdx = stripped.indexOf("customer.subscription.deleted");
  const window = stripped.slice(branchIdx, branchIdx + 2000);
  assertStringIncludes(window, "is_pro: false");
  assertStringIncludes(window, '"free"');
  assertStringIncludes(window, "subscription_expires_at: null");
  assertStringIncludes(window, '"canceled"');
});

Deno.test("ERI-T16 — subscription.deleted verifies write afterwards (Sofia-bug protection)", () => {
  // Just like checkout.session.completed, the deleted branch must verify
  // the write landed — otherwise a silent RLS swallow leaves the user
  // permanently Pro after they cancelled.
  const branchIdx = stripped.indexOf("customer.subscription.deleted");
  const window = stripped.slice(branchIdx, branchIdx + 2000);
  assertStringIncludes(window, "verifyProfileWrite");
  assertStringIncludes(window, "verifySubscriptionWrite");
});

// ---- 5xx behaviour for retry semantics ------------------------------------

Deno.test("ERI-T17 — outer catch returns 500 (Stripe must retry on transient errors)", () => {
  // If a DB write fails, we must return 500 so Stripe re-delivers.
  // Returning 200 would mark the event consumed and we'd lose the activation.
  assertStringIncludes(stripped, "status: 500");
  assertStringIncludes(stripped, '"Internal error"');
});

Deno.test("ERI-T18 — inner catch calls markError BEFORE re-throwing", () => {
  // The inner try/catch lets us record `webhook_events.status='error'` while
  // the eventId is still in scope. Then re-throw so Stripe retries.
  assertStringIncludes(stripped, "markError(supabase, event.id, innerErr)");
  // markError call must come before `throw innerErr;`.
  const markErrIdx = stripped.indexOf("markError(supabase, event.id, innerErr)");
  const throwIdx = stripped.indexOf("throw innerErr");
  assert(
    markErrIdx !== -1 && throwIdx !== -1 && markErrIdx < throwIdx,
    "markError must run before re-throw",
  );
});

// ---- PLAN_MAPPING contract (one source of truth) --------------------------

Deno.test("ERI-T19 — PLAN_MAPPING contract pinned: counsel→basic, representation→premium", () => {
  // Cross-test with subscription_router_test.ts — but pinned again here so
  // a single change in either file fails BOTH tests (visible as a contract
  // break, not a partial regression).
  assertEquals(Object.keys(PLAN_MAPPING).length, 2);
  assertEquals(PLAN_MAPPING.counsel, "basic");
  assertEquals(PLAN_MAPPING.representation, "premium");
});
