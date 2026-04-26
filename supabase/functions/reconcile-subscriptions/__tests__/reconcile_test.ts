// Deno-runtime tests for reconcile-subscriptions.
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-env --allow-read --allow-net=esm.sh,deno.land \
//     supabase/functions/reconcile-subscriptions/__tests__/reconcile_test.ts
//
// Scope:
//   - checkCronSecret (smoke; full coverage lives in deadline-reminder tests)
//   - matchProfile: customer_id / email / metadata fallbacks
//   - decideForActiveSub: paying user with is_pro=false -> upgrade
//   - decideForCanceledSub: stale-cancel >7d w/ is_pro=true -> downgrade
//   - Orphan (Stripe sub, no profile) -> log-only, no fix attempted
//   - Idempotency: synced state -> noop (running twice changes nothing)
//   - Static contract: index.ts gates with checkCronSecret before any IO
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import { checkCronSecret } from "../auth_gate.ts";
import {
  decideForActiveSub,
  decideForCanceledSub,
  DOWNGRADE_GRACE_DAYS,
  formatFixLog,
  matchProfile,
  type ProfileRow,
  type StripeCustomer,
  type StripeSubscription,
  type SubscriptionRow,
} from "../reconcile_logic.ts";

const NOW_MS = Date.parse("2026-04-23T00:00:00Z");
const ONE_DAY = 24 * 60 * 60;

// ---- auth gate (smoke) ------------------------------------------------------

Deno.test("R-T01 — auth: missing CRON_SECRET fails closed", () => {
  const res = checkCronSecret("anything", undefined);
  assertEquals(res.kind, "deny");
});

Deno.test("R-T02 — auth: correct header allows", () => {
  const res = checkCronSecret("the-secret", "the-secret");
  assertEquals(res.kind, "allow");
});

// ---- matchProfile -----------------------------------------------------------

Deno.test("R-T03 — matchProfile: prefers stripe_customer_id link", () => {
  const sub: StripeSubscription = {
    id: "sub_1",
    status: "active",
    customer: "cus_xyz",
  };
  const cust: StripeCustomer = { id: "cus_xyz", email: "a@b.co" };
  const profiles: ProfileRow[] = [
    { id: "u1", email: "a@b.co", stripe_customer_id: null },
    { id: "u2", email: "x@y.co", stripe_customer_id: "cus_xyz" },
  ];
  const m = matchProfile(sub, cust, profiles);
  assert(m !== null);
  assertEquals(m!.profile.id, "u2");
  assertEquals(m!.via, "customer_id");
});

Deno.test("R-T04 — matchProfile: falls back to email when no customer link", () => {
  // Sofia's case: paid via Stripe, but profiles.stripe_customer_id never set
  // because the webhook missed.
  const sub: StripeSubscription = {
    id: "sub_2",
    status: "active",
    customer: "cus_new",
  };
  const cust: StripeCustomer = { id: "cus_new", email: "Sofia@Example.com" };
  const profiles: ProfileRow[] = [
    { id: "u-sofia", email: "sofia@example.com", stripe_customer_id: null },
  ];
  const m = matchProfile(sub, cust, profiles);
  assert(m !== null);
  assertEquals(m!.profile.id, "u-sofia");
  assertEquals(m!.via, "email");
});

Deno.test("R-T05 — matchProfile: falls back to metadata.user_id", () => {
  const sub: StripeSubscription = {
    id: "sub_3",
    status: "active",
    customer: "cus_meta",
    metadata: { user_id: "u-meta" },
  };
  const cust: StripeCustomer = { id: "cus_meta", email: null };
  const profiles: ProfileRow[] = [
    { id: "u-meta", email: null, stripe_customer_id: null },
  ];
  const m = matchProfile(sub, cust, profiles);
  assert(m !== null);
  assertEquals(m!.via, "metadata_user_id");
});

Deno.test("R-T06 — matchProfile: orphan returns null", () => {
  const sub: StripeSubscription = {
    id: "sub_4",
    status: "active",
    customer: "cus_orphan",
  };
  const cust: StripeCustomer = { id: "cus_orphan", email: "ghost@nowhere.co" };
  const profiles: ProfileRow[] = [
    { id: "u-other", email: "other@here.co", stripe_customer_id: "cus_other" },
  ];
  const m = matchProfile(sub, cust, profiles);
  assertEquals(m, null);
});

// ---- decideForActiveSub: the Sofia bug --------------------------------------

Deno.test("R-T07 — paid Stripe sub but profiles.is_pro=false → upgrade", () => {
  // Exactly Sofia's situation: Stripe says active, our DB says free.
  const periodEnd = Math.floor(NOW_MS / 1000) + 30 * ONE_DAY;
  const sub: StripeSubscription = {
    id: "sub_sofia",
    status: "active",
    current_period_end: periodEnd,
    customer: "cus_sofia",
    metadata: { plan_id: "representation" },
  };
  const profile: ProfileRow = {
    id: "u-sofia",
    email: "sofia@example.com",
    is_pro: false,
    subscription_tier: "free",
    subscription_expires_at: null,
    stripe_customer_id: null,
  };
  const action = decideForActiveSub(sub, "cus_sofia", profile, null, NOW_MS);

  assertEquals(action.kind, "upgrade");
  if (action.kind === "upgrade") {
    assertEquals(action.user_id, "u-sofia");
    assertEquals(action.tier, "premium"); // representation -> premium
    assertEquals(action.customer_id, "cus_sofia");
    assertStringIncludes(action.drift, "is_pro=false");
    assertStringIncludes(action.drift, "tier=free");
    assertStringIncludes(action.drift, "expires_at=null");
    assertStringIncludes(action.drift, "stripe_customer_id_unlinked");
  }
});

Deno.test("R-T08 — paid Stripe sub already in sync → noop (idempotent)", () => {
  const periodEnd = Math.floor(NOW_MS / 1000) + 30 * ONE_DAY;
  const expIso = new Date(periodEnd * 1000).toISOString();
  const sub: StripeSubscription = {
    id: "sub_synced",
    status: "active",
    current_period_end: periodEnd,
    customer: "cus_synced",
    metadata: { plan_id: "counsel" },
  };
  const profile: ProfileRow = {
    id: "u-synced",
    email: "ok@example.com",
    is_pro: true,
    subscription_tier: "basic",
    subscription_expires_at: expIso,
    stripe_customer_id: "cus_synced",
  };
  const subRow: SubscriptionRow = {
    user_id: "u-synced",
    status: "active",
    tier: "basic",
    current_period_end: expIso,
    stripe_subscription_id: "sub_synced",
  };
  const action = decideForActiveSub(sub, "cus_synced", profile, subRow, NOW_MS);
  assertEquals(action.kind, "noop");
});

Deno.test("R-T09 — trialing user counts as paying for upgrade decision", () => {
  const periodEnd = Math.floor(NOW_MS / 1000) + 14 * ONE_DAY;
  const sub: StripeSubscription = {
    id: "sub_trial",
    status: "trialing",
    current_period_end: periodEnd,
    customer: "cus_trial",
    metadata: { plan_id: "counsel" },
  };
  const profile: ProfileRow = {
    id: "u-trial",
    is_pro: false,
    subscription_tier: "free",
  };
  // The decideForActiveSub helper is called for both 'active' and 'trialing'
  // by index.ts. The function itself doesn't care about the status field —
  // it just trusts the caller. Here we exercise the same code path.
  const action = decideForActiveSub(sub, "cus_trial", profile, null, NOW_MS);
  assertEquals(action.kind, "upgrade");
});

// ---- decideForCanceledSub: stale-cancel cleanup -----------------------------

Deno.test("R-T10 — Stripe canceled >7d but profiles.is_pro=true → downgrade", () => {
  const canceledAt = Math.floor(NOW_MS / 1000) - 10 * ONE_DAY; // 10d ago
  const sub: StripeSubscription = {
    id: "sub_old_cancel",
    status: "canceled",
    customer: "cus_oc",
    canceled_at: canceledAt,
  };
  const profile: ProfileRow = {
    id: "u-stillpro",
    is_pro: true,
    subscription_tier: "premium",
    subscription_expires_at: null,
    stripe_customer_id: "cus_oc",
  };
  const action = decideForCanceledSub(sub, "cus_oc", profile, NOW_MS);
  assertEquals(action.kind, "downgrade");
  if (action.kind === "downgrade") {
    assertEquals(action.user_id, "u-stillpro");
    assertStringIncludes(action.drift, "stripe.status=canceled");
  }
});

Deno.test("R-T11 — Stripe canceled <7d → noop (grace period)", () => {
  // Conservative: don't yank Pro until 7d after Stripe marks it canceled.
  // This avoids flapping during dunning / immediate retry windows.
  const canceledAt = Math.floor(NOW_MS / 1000) - 2 * ONE_DAY; // 2d ago
  const sub: StripeSubscription = {
    id: "sub_recent_cancel",
    status: "canceled",
    customer: "cus_rc",
    canceled_at: canceledAt,
  };
  const profile: ProfileRow = {
    id: "u-recent",
    is_pro: true,
    subscription_tier: "premium",
    stripe_customer_id: "cus_rc",
  };
  const action = decideForCanceledSub(sub, "cus_rc", profile, NOW_MS);
  assertEquals(action.kind, "noop");
  if (action.kind === "noop") {
    assertStringIncludes(action.reason, "grace");
  }
});

Deno.test("R-T12 — Stripe canceled >7d but already free → noop (idempotent)", () => {
  const canceledAt = Math.floor(NOW_MS / 1000) -
    (DOWNGRADE_GRACE_DAYS + 5) * ONE_DAY;
  const sub: StripeSubscription = {
    id: "sub_done",
    status: "canceled",
    customer: "cus_done",
    canceled_at: canceledAt,
  };
  const profile: ProfileRow = {
    id: "u-done",
    is_pro: false,
    subscription_tier: "free",
    stripe_customer_id: "cus_done",
  };
  const action = decideForCanceledSub(sub, "cus_done", profile, NOW_MS);
  assertEquals(action.kind, "noop");
});

Deno.test("R-T13 — past_due >7d also triggers downgrade (not just canceled)", () => {
  // The webhook flags past_due but doesn't downgrade. The reconciler is the
  // last line of defence — eventually past_due users do need to lose access.
  const markedAt = Math.floor(NOW_MS / 1000) - 8 * ONE_DAY;
  const sub: StripeSubscription = {
    id: "sub_pd",
    status: "past_due",
    customer: "cus_pd",
    ended_at: markedAt,
  };
  const profile: ProfileRow = {
    id: "u-pd",
    is_pro: true,
    subscription_tier: "basic",
    stripe_customer_id: "cus_pd",
  };
  const action = decideForCanceledSub(sub, "cus_pd", profile, NOW_MS);
  assertEquals(action.kind, "downgrade");
});

// ---- formatFixLog -----------------------------------------------------------

Deno.test("R-T14 — log line shape matches the [RECONCILE-FIX] contract", () => {
  const log = formatFixLog({
    kind: "upgrade",
    user_id: "u-sofia",
    stripe_sub_id: "sub_sofia",
    tier: "premium",
    expires_at: "2026-05-23T00:00:00Z",
    customer_id: "cus_sofia",
    drift: "is_pro=false,tier=free",
  });
  assertStringIncludes(log, "[RECONCILE-FIX]");
  assertStringIncludes(log, "user=u-sofia");
  assertStringIncludes(log, "stripe_sub=sub_sofia");
  assertStringIncludes(log, "drift=is_pro=false,tier=free");
});

Deno.test("R-T15 — orphan log line never includes email", () => {
  const log = formatFixLog({
    kind: "orphan",
    stripe_sub_id: "sub_ghost",
    customer_id: "cus_ghost",
    customer_email: "ghost@nowhere.co",
    reason: "no profile",
  });
  // Even though the action carries the email, the log formatter must drop it.
  // FIX-6: emails in logs are a GDPR violation.
  assertStringIncludes(log, "[RECONCILE-ORPHAN]");
  assertStringIncludes(log, "stripe_sub=sub_ghost");
  assertEquals(log.includes("ghost@nowhere.co"), false);
});

// ---- Static contracts on index.ts ------------------------------------------

Deno.test("R-T16 — index.ts gates with checkCronSecret before createClient", async () => {
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  const gateIdx = source.indexOf("checkCronSecret(");
  const createClientIdx = source.indexOf("createClient(");
  assert(gateIdx !== -1, "must call checkCronSecret");
  assert(createClientIdx !== -1, "must call createClient");
  assert(
    gateIdx < createClientIdx,
    "checkCronSecret MUST run before createClient",
  );
});

Deno.test("R-T17 — index.ts uses x-cron-secret header (not Authorization)", async () => {
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  assertStringIncludes(source, "x-cron-secret");
});

Deno.test("R-T18 — index.ts returns { checked, fixed, errors } shape", async () => {
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  assertStringIncludes(source, "checked");
  assertStringIncludes(source, "fixed");
  assertStringIncludes(source, "errors");
});
