// supabase/functions/referral/conversion.ts
// -----------------------------------------------------------------------------
// Conversion + credit path, invoked by stripe-webhook on
// customer.subscription.created / checkout.session.completed for a paid plan.
//
// Two phases:
//
//   1. processConversionForReferred(sb, stripe, referredUserId, customerId)
//      → if the referred user has an `attributed` row, mark it `converted`,
//        attach a 30-day coupon to their Stripe customer, and stamp the
//        coupon id into metadata.
//
//   2. creditInviterForReferred(sb, stripe, referredUserId)
//      → finds the attribution row, runs the 365-day anti-abuse check, and
//        either credits the inviter via Stripe `customer_balance_transactions`
//        (negative amount → applied to next invoice) or marks the row
//        `abuse_blocked`.
//
// We keep this as a SEPARATE module from handler.ts because the stripe-webhook
// needs to import it directly without dragging in the HTTP routing surface.
//
// Stripe operations are wrapped behind a {@link StripeAdapter} interface so
// tests can substitute a fake. Real wiring is in index.ts → it instantiates
// a StripeAdapter that calls api.stripe.com.
// -----------------------------------------------------------------------------

import { shouldBlockForAbuse } from "./anti_abuse.ts";

// deno-lint-ignore no-explicit-any
type SupabaseLike = any;

/** Stripe operations needed by the conversion path. */
export interface StripeAdapter {
  /** Create a 30-day percent_off=100 coupon scoped to this customer. */
  createReferredFriendCoupon(): Promise<{ id: string }>;
  /** Attach a coupon to a customer (applied to next invoice). */
  attachCouponToCustomer(customerId: string, couponId: string): Promise<void>;
  /** Credit a customer balance (negative amount cents → discount).
   *  idempotencyToken MUST be unique per logical credit (the attribution id)
   *  so Stripe rejects retries without colliding distinct referrals. */
  creditCustomerBalance(
    customerId: string,
    amountCents: number,
    description: string,
    idempotencyToken?: string,
    /** ISO 4217 currency for the balance transaction. MUST match the
     *  inviter's Stripe customer currency or Stripe rejects the call.
     *  Defaults to "eur" when omitted (back-compat for callers that don't
     *  thread a plan price). */
    currency?: string,
  ): Promise<{ id: string }>;
}

/** Plan price hint used to size the inviter's credit. */
export interface PlanPrice {
  /** ISO 4217, e.g. "eur". */
  currency: string;
  /** Monthly price in cents (1999 for €19.99 Pro, 2999 for Premium). */
  amountCents: number;
}

/** Result of {@link processConversionForReferred}. */
export type ConversionOutcome =
  | { kind: "noop"; reason: string }
  | {
      kind: "converted";
      attributionId: string;
      inviterUserId: string;
      couponId: string;
    };

/** Phase 1 — mark conversion + give referred user the 30-day discount. */
export async function processConversionForReferred(
  sb: SupabaseLike,
  stripe: StripeAdapter,
  referredUserId: string,
  referredStripeCustomerId: string,
): Promise<ConversionOutcome> {
  // Pull the attribution row.
  const { data: attrib, error: attribErr } = await sb
    .from("referral_attributions")
    .select("id, inviter_user_id, status, metadata")
    .eq("referred_user_id", referredUserId)
    .maybeSingle();
  if (attribErr) {
    return { kind: "noop", reason: `attrib_lookup_failed:${attribErr.message}` };
  }
  if (!attrib) return { kind: "noop", reason: "not_referred" };
  if (attrib.status !== "attributed") {
    return { kind: "noop", reason: `already_${attrib.status}` };
  }

  // Create + attach the coupon. Best-effort: failure here just means the
  // referred user does not get their discount, but we still mark the
  // attribution converted so the inviter credit fires.
  let couponId = "";
  try {
    const coupon = await stripe.createReferredFriendCoupon();
    couponId = coupon.id;
    await stripe.attachCouponToCustomer(referredStripeCustomerId, couponId);
  } catch (e) {
    console.error(
      `referral: coupon attach failed for referred=${referredUserId}: ${e}`,
    );
  }

  const mergedMeta = {
    ...(attrib.metadata ?? {}),
    referred_coupon_id: couponId || null,
    referred_stripe_customer_id: referredStripeCustomerId,
    converted_at: new Date().toISOString(),
  };

  const { error: upErr } = await sb
    .from("referral_attributions")
    .update({
      status: "converted",
      converted_at: new Date().toISOString(),
      metadata: mergedMeta,
    })
    .eq("id", attrib.id);
  if (upErr) {
    return {
      kind: "noop",
      reason: `attrib_update_failed:${upErr.message}`,
    };
  }

  // Bump conversion stat (best-effort).
  const { data: codeRow } = await sb
    .from("referral_codes")
    .select("total_conversions")
    .eq("user_id", attrib.inviter_user_id)
    .maybeSingle();
  if (codeRow) {
    await sb
      .from("referral_codes")
      .update({
        total_conversions: Number(codeRow.total_conversions ?? 0) + 1,
      })
      .eq("user_id", attrib.inviter_user_id);
  }

  return {
    kind: "converted",
    attributionId: attrib.id,
    inviterUserId: attrib.inviter_user_id,
    couponId,
  };
}

/** Result of {@link creditInviterForReferred}. */
export type CreditOutcome =
  | { kind: "noop"; reason: string }
  | {
      kind: "credited";
      attributionId: string;
      inviterUserId: string;
      balanceTxnId: string;
      amountCents: number;
    }
  | {
      kind: "abuse_blocked";
      attributionId: string;
      inviterUserId: string;
      recentCreditCount: number;
    };

/** Phase 2 — credit the inviter's next renewal. */
export async function creditInviterForReferred(
  sb: SupabaseLike,
  stripe: StripeAdapter,
  referredUserId: string,
  planPrice: PlanPrice,
): Promise<CreditOutcome> {
  const { data: attrib } = await sb
    .from("referral_attributions")
    .select("id, inviter_user_id, status, metadata")
    .eq("referred_user_id", referredUserId)
    .maybeSingle();
  if (!attrib) return { kind: "noop", reason: "not_referred" };
  if (attrib.status === "credited") {
    return { kind: "noop", reason: "already_credited" };
  }
  if (attrib.status === "abuse_blocked") {
    return { kind: "noop", reason: "already_abuse_blocked" };
  }
  if (attrib.status !== "converted") {
    return { kind: "noop", reason: `status_is_${attrib.status}` };
  }

  // Anti-abuse window check.
  const { data: priorCredits } = await sb
    .from("referral_attributions")
    .select("free_month_credited_at")
    .eq("inviter_user_id", attrib.inviter_user_id)
    .eq("status", "credited")
    .not("free_month_credited_at", "is", null);
  const timestamps: string[] = Array.isArray(priorCredits)
    ? priorCredits
        .map((r: { free_month_credited_at: string | null }) =>
          r.free_month_credited_at ?? "",
        )
        .filter((s: string) => s.length > 0)
    : [];

  const decision = shouldBlockForAbuse(timestamps);
  if (decision.kind === "block") {
    await sb
      .from("referral_attributions")
      .update({
        status: "abuse_blocked",
        metadata: {
          ...(attrib.metadata ?? {}),
          abuse_block_reason: "max_12_per_year",
          abuse_window_start: decision.windowStart,
          abuse_window_end: decision.windowEnd,
          recent_credit_count: decision.recentCreditCount,
        },
      })
      .eq("id", attrib.id);
    return {
      kind: "abuse_blocked",
      attributionId: attrib.id,
      inviterUserId: attrib.inviter_user_id,
      recentCreditCount: decision.recentCreditCount,
    };
  }

  // Lookup inviter's Stripe customer id.
  const { data: inviterProfile } = await sb
    .from("profiles")
    .select("stripe_customer_id")
    .eq("id", attrib.inviter_user_id)
    .maybeSingle();
  const inviterCustomerId: string | undefined =
    inviterProfile?.stripe_customer_id;
  if (!inviterCustomerId) {
    // No Stripe customer yet — defer. Leave status='converted' so a future
    // run (or the reconcile-subscriptions cron) can retry.
    return {
      kind: "noop",
      reason: "inviter_no_stripe_customer",
    };
  }

  // Claim the row BEFORE issuing the credit: a conditional compare-and-swap
  // (converted → credited) gated on the CURRENT status. Two concurrent
  // conversion webhooks for the same referred user would both pass the
  // line-174 read check; only the one whose UPDATE flips status here gets a
  // non-empty `claimed` set and proceeds to issue the (real-money) credit.
  // The loser sees 0 rows and aborts. The Stripe idempotency token (attrib.id)
  // is a second backstop.
  const creditedAt = new Date().toISOString();
  const { data: claimed } = await sb
    .from("referral_attributions")
    .update({
      status: "credited",
      free_month_credited_at: creditedAt,
      metadata: {
        ...(attrib.metadata ?? {}),
        inviter_credit_amount_cents: planPrice.amountCents,
        inviter_credit_currency: planPrice.currency,
        credited_at: creditedAt,
      },
    })
    .eq("id", attrib.id)
    .eq("status", "converted")
    .select("id");
  if (!Array.isArray(claimed) || claimed.length === 0) {
    // Another writer already claimed it between our read and this update.
    return { kind: "noop", reason: "already_credited" };
  }

  // Issue the credit. Negative amount on Stripe customer balance applies
  // as a discount on the NEXT invoice. Idempotency token = attribution id.
  let txn: { id: string };
  try {
    txn = await stripe.creditCustomerBalance(
      inviterCustomerId,
      -planPrice.amountCents,
      `Advocat referral credit: friend ${referredUserId} converted to paid`,
      attrib.id,
      // Pass the plan's currency (the same value recorded as
      // inviter_credit_currency above) so a non-EUR Stripe customer is not
      // silently rejected by a hardcoded "eur". Today all EE/FI plans are
      // EUR; this closes the latent trap.
      planPrice.currency,
    );
  } catch (e) {
    // Stripe failed AFTER we claimed the row. Revert to 'converted' so a
    // retry (webhook or reconcile cron) can credit again — otherwise the
    // inviter would be silently denied their earned credit.
    const { error: revertErr } = await sb
      .from("referral_attributions")
      .update({ status: "converted", free_month_credited_at: null })
      .eq("id", attrib.id)
      .eq("status", "credited");
    if (revertErr) {
      // The revert itself failed → the row is stuck 'credited' with no
      // balance_txn_id, and the next retry short-circuits on already_credited,
      // silently denying the inviter their earned credit. Log loudly so it is
      // reconcilable rather than lost.
      console.error(
        `referral: FAILED to revert attribution ${attrib.id} after Stripe ` +
          `credit error — row stuck 'credited' without txn, needs manual ` +
          `reconcile: ${revertErr.message}`,
      );
    }
    throw e;
  }

  await sb
    .from("referral_attributions")
    .update({
      metadata: {
        ...(attrib.metadata ?? {}),
        inviter_balance_txn_id: txn.id,
        inviter_credit_amount_cents: planPrice.amountCents,
        inviter_credit_currency: planPrice.currency,
        credited_at: creditedAt,
      },
    })
    .eq("id", attrib.id);

  // Bump inviter's free_months counter.
  const { data: codeRow } = await sb
    .from("referral_codes")
    .select("total_free_months_earned")
    .eq("user_id", attrib.inviter_user_id)
    .maybeSingle();
  if (codeRow) {
    await sb
      .from("referral_codes")
      .update({
        total_free_months_earned:
          Number(codeRow.total_free_months_earned ?? 0) + 1,
      })
      .eq("user_id", attrib.inviter_user_id);
  }

  return {
    kind: "credited",
    attributionId: attrib.id,
    inviterUserId: attrib.inviter_user_id,
    balanceTxnId: txn.id,
    amountCents: planPrice.amountCents,
  };
}
