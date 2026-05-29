// Pure reconciliation logic for reconcile-subscriptions.
// -----------------------------------------------------------------------------
// Sprint 0 — daily safety-net for the payment activation bug. Even if a webhook drops,
// paying users get fixed within 24h.
//
// The actual HTTP handler in index.ts wires this to:
//   - Stripe REST API   (live subscriptions)
//   - Supabase service-role client (profiles + subscriptions tables)
//
// This module is import-clean: no top-level fetches, no Deno.env reads, no
// network. That means tests can drive every branch with synthetic input.
// -----------------------------------------------------------------------------

import { PLAN_MAPPING } from "../stripe-webhook/subscription_router.ts";

/** Shape of a Stripe subscription row we care about (subset). */
export interface StripeSubscription {
  id: string;
  status: string; // active|trialing|past_due|canceled|unpaid|incomplete|...
  current_period_end?: number; // unix seconds
  customer: string | StripeCustomer;
  metadata?: { plan_id?: string; user_id?: string };
  // For "stale-cancel" downgrades — when did Stripe mark this canceled/past_due?
  // Stripe exposes both `canceled_at` and `ended_at`; we use whichever is set.
  canceled_at?: number | null;
  ended_at?: number | null;
}

/** Shape of the Stripe customer object we look up when subscription has bare id. */
export interface StripeCustomer {
  id: string;
  email?: string | null;
  metadata?: { user_id?: string };
}

/** Subset of a Supabase profiles row. */
export interface ProfileRow {
  id: string;
  email?: string | null;
  is_pro?: boolean | null;
  subscription_tier?: string | null;
  subscription_expires_at?: string | null;
  stripe_customer_id?: string | null;
}

/** Subset of a subscriptions row. */
export interface SubscriptionRow {
  user_id: string;
  status?: string | null;
  tier?: string | null;
  current_period_end?: string | null;
  stripe_subscription_id?: string | null;
}

/** A drift the reconciler decides to repair. */
export type DriftAction =
  | {
    kind: "upgrade";
    user_id: string;
    stripe_sub_id: string;
    tier: string;
    expires_at: string;
    customer_id: string;
    drift: string;
  }
  | {
    kind: "downgrade";
    user_id: string;
    stripe_sub_id: string;
    customer_id: string;
    drift: string;
  }
  | {
    kind: "noop";
    user_id?: string;
    stripe_sub_id?: string;
    reason: string;
  }
  | {
    kind: "orphan";
    stripe_sub_id: string;
    customer_id: string;
    customer_email: string | null;
    reason: string;
  };

/** Conservative downgrade window: only flip is_pro=false if Stripe has been
 *  in canceled/past_due state for at least this long. Prevents flapping. */
export const DOWNGRADE_GRACE_DAYS = 7;
const SECONDS_PER_DAY = 24 * 60 * 60;

/** Decide tier from a Stripe subscription's metadata.plan_id. */
export function tierFromSub(sub: StripeSubscription): string {
  const planId = sub.metadata?.plan_id;
  return (planId && PLAN_MAPPING[planId]) || "basic";
}

/**
 * Find a profile to attach a Stripe subscription to.
 *
 * Wave 1 fix P0-RC5 (2026-05-28): the email-match branch has been REMOVED.
 * Previously, any Stripe customer whose email matched a profiles.email row
 * would be linked — exploitable by signing up with a victim's email (or
 * any leaked Stripe customer email) and waiting for the daily reconcile to
 * grant is_pro=true on the attacker's profile. Profiles.email is not
 * cryptographically tied to auth.users.email (it's mirrored at signup,
 * can drift, and some flows allow PATCH from the client), so the email
 * fallback was a free-Pro vector.
 *
 * The new resolution order is strictly canonical:
 *   1. profiles.stripe_customer_id linked to the Stripe customer.id
 *   2. checkout metadata.user_id (set by create-checkout / create-org-checkout)
 *
 * If neither matches, the caller logs an unmatched-customer record to
 * `reconcile_unmatched` (a human triages it manually). This is the right
 * trade-off: in the steady state every paying customer has either a
 * canonical link or a recorded checkout, and the rare missed link is
 * far less harmful than a silent free-Pro for a random email twin.
 */
export function matchProfile(
  sub: StripeSubscription,
  customer: StripeCustomer,
  profiles: ProfileRow[],
): { profile: ProfileRow; via: "customer_id" | "metadata_user_id" } | null {
  const customerId = customer.id;
  const metaUserId = sub.metadata?.user_id ?? customer.metadata?.user_id;

  // 1. canonical: stripe_customer_id link
  const byCustomer = profiles.find((p) => p.stripe_customer_id === customerId);
  if (byCustomer) return { profile: byCustomer, via: "customer_id" };

  // 2. checkout metadata user_id (the create-checkout edge fn embeds the
  //    authenticated user_id in session.metadata; create-org-checkout uses
  //    metadata.actor_user_id which we deliberately do NOT match here —
  //    org subs go through the B2B path in stripe-webhook, never reconcile
  //    against B2C profiles).
  if (metaUserId) {
    const byMeta = profiles.find((p) => p.id === metaUserId);
    if (byMeta) return { profile: byMeta, via: "metadata_user_id" };
  }

  return null;
}

/**
 * Given a paying Stripe subscription and the matched profile + sub row,
 * decide if there's drift to fix.
 *
 * "Paying" means Stripe says active OR trialing. In both cases the user
 * MUST have is_pro=true and a non-free tier in our DB.
 */
export function decideForActiveSub(
  stripeSub: StripeSubscription,
  customerId: string,
  profile: ProfileRow,
  subRow: SubscriptionRow | null,
  nowMs: number,
): DriftAction {
  const tier = tierFromSub(stripeSub);
  const periodEnd = stripeSub.current_period_end;
  if (!periodEnd || periodEnd <= 0) {
    return {
      kind: "noop",
      user_id: profile.id,
      stripe_sub_id: stripeSub.id,
      reason: "stripe sub has no current_period_end",
    };
  }
  const expiresAtIso = new Date(periodEnd * 1000).toISOString();

  const drifts: string[] = [];
  if (profile.is_pro !== true) drifts.push("is_pro=false");
  if ((profile.subscription_tier ?? "free") === "free") {
    drifts.push("tier=free");
  }
  // expires_at: drift if stale (more than a day off) OR null while sub active
  const profExp = profile.subscription_expires_at
    ? Date.parse(profile.subscription_expires_at)
    : null;
  if (profExp === null) {
    drifts.push("expires_at=null");
  } else if (Math.abs(profExp - periodEnd * 1000) > SECONDS_PER_DAY * 1000) {
    drifts.push("expires_at_stale");
  }
  if (profile.stripe_customer_id !== customerId) {
    drifts.push("stripe_customer_id_unlinked");
  }
  if (!subRow || (subRow.status !== "active" && subRow.status !== "trialing")) {
    drifts.push(`subscriptions.status=${subRow?.status ?? "missing"}`);
  }

  if (drifts.length === 0) {
    return {
      kind: "noop",
      user_id: profile.id,
      stripe_sub_id: stripeSub.id,
      reason: "in sync",
    };
  }
  return {
    kind: "upgrade",
    user_id: profile.id,
    stripe_sub_id: stripeSub.id,
    tier,
    expires_at: expiresAtIso,
    customer_id: customerId,
    drift: drifts.join(","),
  };
  // nowMs is unused for the upgrade path but kept in signature for symmetry
  // with the downgrade decision and to allow future "expired" handling.
  void nowMs;
}

/**
 * For a Stripe subscription that's been canceled/past_due/unpaid for a while,
 * decide whether we should downgrade the profile. Conservative: only flip
 * is_pro=false if status has been bad for >= DOWNGRADE_GRACE_DAYS.
 */
export function decideForCanceledSub(
  stripeSub: StripeSubscription,
  customerId: string,
  profile: ProfileRow,
  nowMs: number,
): DriftAction {
  const status = stripeSub.status;
  if (status !== "canceled" && status !== "past_due" && status !== "unpaid") {
    return {
      kind: "noop",
      user_id: profile.id,
      stripe_sub_id: stripeSub.id,
      reason: `not a downgrade status (${status})`,
    };
  }

  const markerSec = stripeSub.canceled_at ?? stripeSub.ended_at ?? null;
  if (!markerSec || markerSec <= 0) {
    return {
      kind: "noop",
      user_id: profile.id,
      stripe_sub_id: stripeSub.id,
      reason: "no canceled_at/ended_at marker — wait until Stripe sets one",
    };
  }
  const ageMs = nowMs - markerSec * 1000;
  if (ageMs < DOWNGRADE_GRACE_DAYS * SECONDS_PER_DAY * 1000) {
    return {
      kind: "noop",
      user_id: profile.id,
      stripe_sub_id: stripeSub.id,
      reason: `within ${DOWNGRADE_GRACE_DAYS}d grace period`,
    };
  }

  // Already downgraded — no action needed.
  const alreadyDown = profile.is_pro !== true &&
    (profile.subscription_tier ?? "free") === "free";
  if (alreadyDown) {
    return {
      kind: "noop",
      user_id: profile.id,
      stripe_sub_id: stripeSub.id,
      reason: "already free",
    };
  }

  return {
    kind: "downgrade",
    user_id: profile.id,
    stripe_sub_id: stripeSub.id,
    customer_id: customerId,
    drift:
      `stripe.status=${status} for >=${DOWNGRADE_GRACE_DAYS}d, ` +
      `profile.is_pro=${profile.is_pro}`,
  };
}

/** Format a [RECONCILE-FIX] log line — single shape so log scrapers are stable. */
export function formatFixLog(action: DriftAction): string {
  if (action.kind === "upgrade") {
    return `[RECONCILE-FIX] user=${action.user_id} ` +
      `stripe_sub=${action.stripe_sub_id} drift=${action.drift}`;
  }
  if (action.kind === "downgrade") {
    return `[RECONCILE-FIX] user=${action.user_id} ` +
      `stripe_sub=${action.stripe_sub_id} drift=${action.drift}`;
  }
  if (action.kind === "orphan") {
    // Orphans have no user_id. We deliberately do not log emails — see FIX-6.
    return `[RECONCILE-ORPHAN] stripe_sub=${action.stripe_sub_id} ` +
      `customer=${action.customer_id} reason=${action.reason}`;
  }
  return `[RECONCILE-NOOP] reason=${action.reason}`;
}
