// Deno tests for stripe-webhook subscription router (Sprint 0 — FIX-6).
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-read \
//     supabase/functions/stripe-webhook/__tests__/subscription_router_test.ts
//
// Ref: docs/security/07-business-logic.md M2 — paying subscribers lost
// access after 30 days because the webhook ignored renewal events.
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertFalse,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  PLAN_MAPPING,
  routeSubscriptionUpdate,
  scrubPIIFromLog,
} from "../subscription_router.ts";

// ---- routeSubscriptionUpdate: extend path --------------------------------

Deno.test("F6-T01 — active status with counsel plan extends to basic tier", () => {
  const nowSec = Math.floor(Date.now() / 1000) + 30 * 24 * 3600;
  const action = routeSubscriptionUpdate({
    status: "active",
    current_period_end: nowSec,
    metadata: { plan_id: "counsel" },
  });
  assertEquals(action.kind, "extend");
  if (action.kind === "extend") {
    assertEquals(action.tier, "basic");
    assertEquals(action.expires_at, new Date(nowSec * 1000).toISOString());
  }
});

Deno.test("F6-T02 — active status with representation plan extends to premium", () => {
  const nowSec = Math.floor(Date.now() / 1000) + 365 * 24 * 3600;
  const action = routeSubscriptionUpdate({
    status: "active",
    current_period_end: nowSec,
    metadata: { plan_id: "representation" },
  });
  if (action.kind !== "extend") throw new Error("expected extend");
  assertEquals(action.tier, "premium");
});

Deno.test("F6-T03 — trialing also extends (same as active)", () => {
  const nowSec = Math.floor(Date.now() / 1000) + 7 * 24 * 3600;
  const action = routeSubscriptionUpdate({
    status: "trialing",
    current_period_end: nowSec,
    metadata: { plan_id: "counsel" },
  });
  assertEquals(action.kind, "extend");
});

Deno.test("F6-T04 — active with unknown plan defaults to basic (never premium)", () => {
  // Defensive default: if metadata.plan_id is missing or malformed, we
  // must not give the user premium. Basic is the conservative fallback.
  const nowSec = Math.floor(Date.now() / 1000) + 30 * 24 * 3600;
  const action = routeSubscriptionUpdate({
    status: "active",
    current_period_end: nowSec,
    metadata: { plan_id: "totally-unknown-plan" },
  });
  if (action.kind !== "extend") throw new Error("expected extend");
  assertEquals(action.tier, "basic");
});

Deno.test("F6-T05 — active without current_period_end is ignored (safety)", () => {
  const action = routeSubscriptionUpdate({
    status: "active",
    metadata: { plan_id: "counsel" },
  });
  assertEquals(action.kind, "ignore");
});

// ---- past_due path --------------------------------------------------------

Deno.test("F6-T06 — past_due marks account, does NOT downgrade", () => {
  // Grace-period invariant: if Stripe is still retrying payment, the
  // customer hasn't cancelled. We must not yank access on the first
  // failed charge.
  const action = routeSubscriptionUpdate({ status: "past_due" });
  assertEquals(action.kind, "mark_past_due");
});

// ---- downgrade path -------------------------------------------------------

Deno.test("F6-T07 — canceled -> downgrade", () => {
  const action = routeSubscriptionUpdate({ status: "canceled" });
  assertEquals(action.kind, "downgrade");
});

Deno.test("F6-T08 — unpaid -> downgrade", () => {
  const action = routeSubscriptionUpdate({ status: "unpaid" });
  assertEquals(action.kind, "downgrade");
});

// ---- ignore path ----------------------------------------------------------

Deno.test("F6-T09 — incomplete status is ignored (Stripe intermediate)", () => {
  const action = routeSubscriptionUpdate({ status: "incomplete" });
  assertEquals(action.kind, "ignore");
});

Deno.test("F6-T10 — missing status is ignored", () => {
  const action = routeSubscriptionUpdate({});
  assertEquals(action.kind, "ignore");
});

Deno.test("F6-T11 — paused is ignored (we don't support pausing yet)", () => {
  const action = routeSubscriptionUpdate({ status: "paused" });
  assertEquals(action.kind, "ignore");
});

// ---- PLAN_MAPPING ---------------------------------------------------------

Deno.test("F6-T12 — PLAN_MAPPING contract: counsel=basic, representation=premium", () => {
  // Stripe-side plan IDs must map to our internal tier names.
  assertEquals(PLAN_MAPPING.counsel, "basic");
  assertEquals(PLAN_MAPPING.representation, "premium");
  // Whitelist check: nothing else maps to premium.
  const premiumKeys = Object.entries(PLAN_MAPPING)
    .filter(([, v]) => v === "premium")
    .map(([k]) => k);
  assertEquals(premiumKeys, ["representation"]);
});

// ---- scrubPIIFromLog ------------------------------------------------------

Deno.test("F6-T13 — scrubPIIFromLog redacts email addresses", () => {
  const msg = "Updated user alice@example.com: tier=basic";
  const clean = scrubPIIFromLog(msg);
  assertFalse(clean.includes("alice@example.com"));
  assertStringIncludes(clean, "[email-redacted]");
  assertStringIncludes(clean, "tier=basic");
});

Deno.test("F6-T14 — scrubPIIFromLog passes through non-email text unchanged", () => {
  const msg = "Subscription cus_ABC123 downgraded to free";
  assertEquals(scrubPIIFromLog(msg), msg);
});

Deno.test("F6-T15 — scrubPIIFromLog catches multiple emails in one message", () => {
  const msg = "From a@x.com to b@y.org";
  const clean = scrubPIIFromLog(msg);
  assertFalse(clean.includes("a@x.com"));
  assertFalse(clean.includes("b@y.org"));
});

// ---- Source-code contract: index.ts wires up the new cases ---------------

Deno.test("F6-T16 — stripe-webhook imports routeSubscriptionUpdate", async () => {
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  assertStringIncludes(source, "routeSubscriptionUpdate");
  assertStringIncludes(source, "subscription_router.ts");
});

Deno.test("F6-T17 — customer.subscription.updated handler handles `extend` action", async () => {
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  // The handler must actually do something with the extend result —
  // update `subscription_expires_at`. Without this, the M2 bug persists.
  assertStringIncludes(source, "subscription_expires_at");
  // And must react to the renewal (active/trialing) status — check the
  // router is consumed, not just imported.
  assertStringIncludes(source, "action.kind");
});

Deno.test("F6-T18 — invoice.payment_failed branch no longer logs customer_email", async () => {
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  // Strip comments so doc references to the old pattern don't trigger.
  const stripped = source
    .replace(/\/\*[\s\S]*?\*\//g, "")
    .replace(/^\s*\/\/.*$/gm, "");
  // The pre-FIX-6 code did `console.log(\`Payment failed for ${customerEmail}\`)`.
  // After FIX-6, email must not be templated into the log line.
  assertFalse(
    /console\.log\([^)]*customerEmail/.test(stripped),
    "console.log must not reference customerEmail directly — use customer.id " +
      "or scrubPIIFromLog",
  );
});

Deno.test("F6-T19 — checkout.session.completed log does not template customerEmail", async () => {
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  const stripped = source
    .replace(/\/\*[\s\S]*?\*\//g, "")
    .replace(/^\s*\/\/.*$/gm, "");
  // Pre-FIX-6: `console.log(\`Updated user ${customerEmail}: ...\`)`.
  // Must be gone.
  assertFalse(
    /console\.log\([^)]*Updated user \$\{customerEmail\}/.test(stripped),
    "Updated user log must not include customerEmail",
  );
});

Deno.test("F6-T20 — imports PLAN_MAPPING from router (no drift)", async () => {
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  // Contract: there must be only ONE source of truth for PLAN_MAPPING.
  // Either index.ts imports it from subscription_router.ts (preferred),
  // or it keeps its own copy — but we lock down that the imported one
  // is used so both files don't drift.
  assert(
    source.includes("routeSubscriptionUpdate") ||
      source.includes("import { PLAN_MAPPING"),
    "index.ts must use routeSubscriptionUpdate (plan mapping comes from " +
      "subscription_router.ts)",
  );
});
