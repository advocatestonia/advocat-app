import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "@supabase/supabase-js";
import {
  PLAN_MAPPING,
  routeSubscriptionUpdate,
  scrubPIIFromLog,
} from "./subscription_router.ts";
import {
  checkAndMarkProcessing,
  markError,
  markOk,
  verifyProfileWrite,
  verifySubscriptionWrite,
} from "./idempotency.ts";
import {
  decideQuotaReset,
  resetContractReviewWindow,
  type Tier,
} from "./contract_review_period_reset.ts";
// Referral program — best-effort hooks fired on first paid conversion.
// Pure functions; the Stripe-side calls are isolated in stripe_adapter.ts.
import {
  creditInviterForReferred,
  processConversionForReferred,
  type PlanPrice,
} from "../referral/conversion.ts";
import { makeStripeAdapter } from "../referral/stripe_adapter.ts";
import { withSentry } from "../_shared/sentry.ts";
// Signature verification extracted to a pure, unit-testable module.
import { verifyStripeSignature } from "./signature.ts";

const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY")!;
const STRIPE_WEBHOOK_SECRET = Deno.env.get("STRIPE_WEBHOOK_SECRET");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// No CORS headers needed — Stripe calls server-to-server, not from browsers
const responseHeaders = {
  "Content-Type": "application/json",
};

/**
 * Read the user's prior subscription tier from profiles so the
 * Contract Review quota window can be reset on real tier changes.
 * Returns "free" if the row is missing — that's the safe default and
 * makes a brand-new checkout count as a real free→paid change.
 */
// deno-lint-ignore no-explicit-any
async function readPriorTier(sb: any, userId: string): Promise<Tier> {
  try {
    const { data } = await sb
      .from("profiles")
      .select("subscription_tier")
      .eq("id", userId)
      .maybeSingle();
    const t = data?.subscription_tier as string | undefined;
    if (t === "basic" || t === "premium" || t === "free") return t;
    return "free";
  } catch (_) {
    return "free";
  }
}

/**
 * Apply the Contract Review window reset side-effect when the tier really
 * changes. Best-effort — failures are logged inside resetContractReviewWindow().
 */
// deno-lint-ignore no-explicit-any
async function maybeResetContractReviewQuota(
  sb: any,
  userId: string,
  prev: Tier,
  next: Tier,
): Promise<void> {
  const action = decideQuotaReset(prev, next);
  if (action.kind === "reset") {
    await resetContractReviewWindow(sb, userId, new Date().toISOString());
    console.log(
      `[stripe-webhook] contract-review quota reset user=${userId} ${prev}->${next}`,
    );
  }
}

// ─── Wave 1 fix P0-W2 (2026-05-28) — B2B / B2C routing helpers ────────────
//
// Pre-fix the webhook had a single path: resolve user via metadata.user_id
// OR email → upsert profiles.is_pro=true. For org checkouts (which set
// metadata.org_id and metadata.actor_user_id, NOT metadata.user_id), the
// email fallback would match the org's billing_email against ANY profile
// row with the same email and corrupt the wrong B2C account. Exploit:
// Mallory creates an org whose billing_email matches a B2C profile, pays
// €29 once, refunds within 14 days, reconcile-subscriptions re-asserts
// is_pro=true forever via the leaked link. Fix: route by metadata.org_id
// BEFORE the B2C path. Org subs land in `org_subscriptions`, not in the
// B2C `profiles` table.

/** Find the org_id either from event metadata or by resolving via stripe_customer_id. */
// deno-lint-ignore no-explicit-any
async function resolveOrgIdForCustomer(
  sb: any,
  metadataOrgId: string | undefined | null,
  stripeCustomerId: string | null | undefined,
): Promise<string | null> {
  if (metadataOrgId && typeof metadataOrgId === "string" && metadataOrgId.length > 0) {
    return metadataOrgId;
  }
  if (!stripeCustomerId) return null;
  try {
    const { data } = await sb
      .from("organizations")
      .select("id")
      .eq("stripe_customer_id", stripeCustomerId)
      .limit(1)
      .maybeSingle();
    return (data?.id as string | undefined) ?? null;
  } catch (_e) {
    return null;
  }
}

/** Activation write for an org subscription — touches org_subscriptions + organizations, NEVER profiles. */
// deno-lint-ignore no-explicit-any
async function activateOrgSubscription(
  sb: any,
  orgId: string,
  session: {
    customer?: string;
    subscription?: string;
    amount_total?: number;
    currency?: string;
    metadata?: Record<string, string | undefined>;
  },
  periodEndIso: string | null,
): Promise<void> {
  const stripeCustomerId = session.customer ?? null;
  const stripeSubId = session.subscription ?? null;
  const meta = session.metadata ?? {};
  const plan = meta.plan ?? "starter";
  const billingPeriod = meta.billing_period ?? "monthly";
  const seats = Number(meta.seats ?? 1) || 1;

  // Update the org row's status + link the Stripe customer/sub. We do NOT
  // touch any profiles row here — that's the whole point of the routing fix.
  if (stripeCustomerId) {
    const orgUpdate: Record<string, unknown> = {
      status: "active",
      stripe_customer_id: stripeCustomerId,
    };
    if (stripeSubId) orgUpdate.stripe_subscription_id = stripeSubId;
    const { error: orgErr } = await sb
      .from("organizations")
      .update(orgUpdate)
      .eq("id", orgId);
    if (orgErr) {
      throw new Error(`organizations update failed: ${orgErr.message}`);
    }
  }

  // Upsert the org_subscriptions row. Schema lives in
  // 20260523010000_create_organizations.sql (unique on org_id + stripe_subscription_id).
  if (stripeSubId && stripeCustomerId) {
    const unitAmountCents = Math.max(
      1,
      Math.floor((session.amount_total ?? 0) / Math.max(1, seats)),
    );
    const { error: subErr } = await sb.from("org_subscriptions").upsert({
      org_id: orgId,
      stripe_subscription_id: stripeSubId,
      stripe_customer_id: stripeCustomerId,
      plan,
      billing_period: billingPeriod,
      seats_paid: seats,
      unit_amount_cents: unitAmountCents,
      currency: (session.currency ?? "eur").toLowerCase(),
      status: "active",
      current_period_end: periodEndIso,
      updated_at: new Date().toISOString(),
    }, { onConflict: "org_id" });
    if (subErr) {
      throw new Error(`org_subscriptions upsert failed: ${subErr.message}`);
    }
  }
  console.log(
    `[stripe-webhook] B2B activated org=${orgId} sub=${stripeSubId ?? "?"} ` +
      `plan=${plan} seats=${seats}`,
  );
}

/** Apply a status change (mark_past_due / canceled / refunded) to an org subscription. */
// deno-lint-ignore no-explicit-any
async function updateOrgSubscriptionStatus(
  sb: any,
  orgId: string,
  newStatus: string,
  orgRowStatus?: string,
): Promise<void> {
  if (orgRowStatus) {
    await sb
      .from("organizations")
      .update({ status: orgRowStatus })
      .eq("id", orgId);
  }
  await sb
    .from("org_subscriptions")
    .update({ status: newStatus, updated_at: new Date().toISOString() })
    .eq("org_id", orgId);
  console.log(`[stripe-webhook] B2B status org=${orgId} -> ${newStatus}`);
}

/**
 * Plan price in cents, indexed by Tier. Mirrors the live launch pricing
 * (Pro €19.99, Premium €29.99 monthly). Used to size the inviter's credit.
 */
function planPriceFromTier(tier: Tier): PlanPrice {
  switch (tier) {
    case "premium":
      return { currency: "eur", amountCents: 2999 };
    case "basic":
      return { currency: "eur", amountCents: 1999 };
    case "free":
    default:
      // Defensive: free tier should never reach the referral hooks, but if
      // it does we credit the smaller amount.
      return { currency: "eur", amountCents: 1999 };
  }
}

/**
 * Run the referral program hooks for a newly-paid user. Best-effort: any
 * exception is caught and logged so subscription activation cannot fail
 * because of a referral side-effect.
 */
// deno-lint-ignore no-explicit-any
async function applyReferralHooks(
  sb: any,
  referredUserId: string,
  referredCustomerId: string,
  planPrice: PlanPrice,
): Promise<void> {
  const stripeKey = Deno.env.get("STRIPE_SECRET_KEY");
  if (!stripeKey) {
    console.warn("[stripe-webhook] referral skipped: STRIPE_SECRET_KEY unset");
    return;
  }
  try {
    const stripe = makeStripeAdapter(stripeKey);
    const conv = await processConversionForReferred(
      sb,
      stripe,
      referredUserId,
      referredCustomerId,
    );
    if (conv.kind === "converted") {
      console.log(
        `[stripe-webhook] referral converted ` +
          `attribution=${conv.attributionId} inviter=${conv.inviterUserId}`,
      );
      const credit = await creditInviterForReferred(
        sb,
        stripe,
        referredUserId,
        planPrice,
      );
      if (credit.kind === "credited") {
        console.log(
          `[stripe-webhook] referral credited inviter=${credit.inviterUserId} ` +
            `txn=${credit.balanceTxnId} amount=${credit.amountCents}`,
        );
      } else if (credit.kind === "abuse_blocked") {
        console.warn(
          `[stripe-webhook] referral abuse-blocked inviter=${credit.inviterUserId} ` +
            `recent=${credit.recentCreditCount}`,
        );
      } else {
        console.log(`[stripe-webhook] referral credit noop: ${credit.reason}`);
      }
    }
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    console.error(`[stripe-webhook] referral hook failed: ${msg.slice(0, 300)}`);
  }
}

serve(withSentry("stripe-webhook", async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204 });
  }

  try {
    const body = await req.text();

    // Verify Stripe webhook signature (HMAC + replay window). Behaviour is
    // identical to the previous inline block; the per-reason error strings are
    // preserved so any monitoring keyed on them keeps working.
    const signature = req.headers.get("stripe-signature");
    const sigResult = await verifyStripeSignature(
      body,
      signature,
      STRIPE_WEBHOOK_SECRET,
    );
    if (!sigResult.ok) {
      const errMsg = sigResult.reason === "missing"
        ? "Missing signature"
        : sigResult.reason === "format"
        ? "Invalid signature format"
        : sigResult.reason === "stale"
        ? "Stale webhook"
        : "Invalid signature";
      return new Response(JSON.stringify({ error: errMsg }), {
        status: 401,
        headers: responseHeaders,
      });
    }

    // Parse the Stripe event
    let event;
    try {
      event = JSON.parse(body);
    } catch {
      return new Response("Invalid JSON", { status: 400 });
    }

    console.log(`Stripe webhook: ${event.type} id=${event.id}`);

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Idempotency gate (silent-failure mode #4). If we already returned ok for
    // this event.id, return 200 without touching the DB again. Stripe retries
    // are common — duplicate processing would double-extend subscriptions.
    if (!event.id) {
      // Defensive: every real Stripe event has an id. If we got here without
      // one, fail loudly rather than skip the idempotency layer.
      return new Response(JSON.stringify({ error: "Missing event id" }), {
        status: 400, headers: responseHeaders,
      });
    }
    const decision = await checkAndMarkProcessing(
      supabase,
      event.id,
      event.type,
    );
    if (decision.kind === "skip") {
      console.log(`webhook: event ${event.id} already processed, skipping`);
      return new Response(
        JSON.stringify({ received: true, idempotent: true }),
        { status: 200, headers: responseHeaders },
      );
    }

    // Track the resolved user across the switch so we can stamp it onto the
    // webhook_events row when we mark ok.
    let resolvedUserId: string | null = null;

    // Inner try: surfaces DB write/verification failures so the outer catch
    // marks status='error' and returns 500 (Stripe will retry). Without this,
    // a thrown verification error would still bubble to the outer catch, but
    // we want the markError side-effect to fire with event.id in scope.
    try {

    switch (event.type) {
      case "checkout.session.completed": {
        const session = event.data.object;
        const customerEmail = session.customer_email || session.customer_details?.email;
        const metadata = session.metadata || {};
        const planId = metadata.plan_id; // "counsel" or "representation"
        const billingPeriod = metadata.billing_period; // "monthly" or "yearly"
        const metaUserId = metadata.user_id; // set by create-checkout (authenticated caller)
        // intro_type column kept on subscriptions for historical (grandfathered)
        // founder rows. New checkouts never set it — the launch pricing flow
        // (€19.99/mo standard) does not write metadata.intro_type, so this
        // resolves to null for every new subscription.
        const introType: string | null = metadata.intro_type ?? null;

        const tier = PLAN_MAPPING[planId] || "basic";

        // Calculate expiry date
        let expiresAt: Date;
        if (billingPeriod === "yearly") {
          expiresAt = new Date();
          expiresAt.setFullYear(expiresAt.getFullYear() + 1);
        } else {
          expiresAt = new Date();
          expiresAt.setMonth(expiresAt.getMonth() + 1);
        }

        // ── Wave 1 fix P0-W2 (2026-05-28) — B2B routing FIRST ────────────
        //
        // Org checkouts set metadata.org_id (see create-org-checkout/index.ts).
        // If present we MUST route to the org activation path. Falling through
        // to the B2C path corrupts random profiles whose email happens to
        // match the org's billing_email. resolveOrgIdForCustomer also handles
        // legacy sessions that have only stripe_customer_id (org row linked
        // by stripe_customer_id during create-org-checkout's customer create).
        const orgId = await resolveOrgIdForCustomer(
          supabase,
          metadata.org_id,
          session.customer as string | undefined,
        );
        if (orgId) {
          await activateOrgSubscription(
            supabase,
            orgId,
            session,
            expiresAt.toISOString(),
          );
          // Mark the actor (the human owner who clicked Subscribe) as the
          // resolved subject of this event for webhook_events stamping.
          // Note: actor's B2C is_pro is NOT touched — they get Pro by being
          // an active member of the org via the seat-grant flow, not by
          // this webhook.
          const actorId = metadata.actor_user_id;
          if (actorId && typeof actorId === "string") {
            resolvedUserId = actorId;
          }
          break;
        }

        // ── B2C path: resolve user. Wave 1 fix P0-W2 removes the
        // customer_email fallback — only canonical metadata.user_id or
        // session.client_reference_id (set by create-checkout for some flows)
        // are accepted. Without this guard, a Stripe customer whose email
        // matches an unrelated B2C user could overwrite that user's Pro
        // flag.
        let userId: string | null = null;
        if (metaUserId && typeof metaUserId === "string") {
          userId = metaUserId;
        } else if (
          session.client_reference_id &&
          typeof session.client_reference_id === "string"
        ) {
          userId = session.client_reference_id;
        }

        if (!userId) {
          // Loud log so missing canonical metadata is alertable. The
          // outer markOk still fires (Stripe should not retry) but ops
          // gets a paper trail. P1-W1 will convert this to a throw once
          // we're confident the create-checkout always sets metadata.user_id.
          console.error(
            `checkout.completed: no canonical user_id (metadata.user_id / ` +
              `client_reference_id) for customer=${session.customer}; ` +
              `customer_email fallback removed (P0-W2). Manual reconcile required.`,
          );
          break;
        }

        resolvedUserId = userId;

        // Capture the user's prior tier BEFORE the upsert overwrites it so
        // we can decide whether to reset the Contract Review window. See
        // contract_review_period_reset.ts for the policy.
        const priorTierCheckout = await readPriorTier(supabase, userId);

        // Upsert — if the profile row doesn't exist yet (trigger gap), create
        // it. This eliminates the silent-failure class where a paying user
        // had no profile row and their Pro never activated.
        //
        // is_pro = true is REQUIRED — check-ai-quota Edge Function reads
        // is_pro to decide if quota is enforced; subscription_tier alone is
        // not enough. A manual activation in 2026-04-26 surfaced this.
        const { error: profUpErr } = await supabase.from("profiles").upsert({
          id: userId,
          subscription_tier: tier,
          subscription_expires_at: expiresAt.toISOString(),
          stripe_customer_id: session.customer,
          is_pro: true,
        }, { onConflict: "id" });
        if (profUpErr) {
          throw new Error(`profiles upsert failed: ${profUpErr.message}`);
        }
        // Read-after-write verification — catches the silent-failure mode
        // where the upsert "succeeded" but the row didn't actually update
        // (RLS surprise, trigger error swallowed, etc.).
        await verifyProfileWrite(supabase, userId, {
          is_pro: true,
          subscription_tier: tier,
        });

        // Also write to subscriptions table (separate source of truth that
        // check-ai-quota also probes). status='active' is what unlocks Pro.
        // intro_type is NULL for new launch-pricing subscriptions; the column
        // is preserved on the schema for historical (grandfathered) founder
        // rows that signed up before the founder program was retired.
        const { error: subUpErr } = await supabase.from("subscriptions").upsert({
          user_id: userId,
          status: "active",
          tier: tier,
          current_period_end: expiresAt.toISOString(),
          stripe_subscription_id: session.subscription || null,
          intro_type: introType,
          updated_at: new Date().toISOString(),
        }, { onConflict: "user_id" });
        if (subUpErr) {
          throw new Error(`subscriptions upsert failed: ${subUpErr.message}`);
        }
        await verifySubscriptionWrite(supabase, userId, { status: "active" });

        // Reset the Contract Review 30-day window only when the tier
        // actually changed (real upgrade or first-paid checkout). Renewals
        // of the same tier are a no-op so we don't refresh the counter
        // mid-cycle.
        await maybeResetContractReviewQuota(
          supabase,
          userId,
          priorTierCheckout,
          tier as Tier,
        );

        // Referral program: if this user was referred, give them a free
        // month (coupon on their Stripe customer) and credit the inviter
        // on their next renewal. Best-effort — failures are logged and
        // never block subscription activation. Anti-abuse is enforced in
        // creditInviterForReferred (max 12 free months/year).
        await applyReferralHooks(
          supabase,
          userId,
          session.customer as string,
          planPriceFromTier(tier as Tier),
        );

        // Send our own confirmation email so customers always get one,
        // regardless of Stripe Dashboard "Customer emails" toggle.
        // Best-effort: failure here does not block activation.
        if (customerEmail) {
          try {
            const amount = (session.amount_total ?? 0) / 100;
            const currency = (session.currency ?? "eur").toUpperCase();
            const subject = tier === "premium"
              ? "Ваша подписка Advocat Pro активна"
              : "Оплата Advocat получена";
            const body =
              `Здравствуйте!\n\n` +
              `Спасибо за оплату. Ваша подписка активирована.\n\n` +
              `План: ${planId} (${billingPeriod})\n` +
              `Сумма: ${amount.toFixed(2)} ${currency}\n` +
              `Действует до: ${expiresAt.toISOString().slice(0, 10)}\n\n` +
              `Счёт и квитанцию вы также получите от Stripe.\n\n` +
              `Управление подпиской: https://advocat.ee/app.html#/subscription\n\n` +
              `С уважением,\nКоманда Advocat\nhttps://advocat.ee`;

            await fetch(`${SUPABASE_URL}/functions/v1/send-email`, {
              method: "POST",
              headers: {
                "Authorization": `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
                "Content-Type": "application/json",
              },
              body: JSON.stringify({
                to: customerEmail,
                subject,
                body,
                // skip_gmail_oauth: true — webhook has no user OAuth context,
                // always use Resend fallback.
                force_provider: "resend",
              }),
            }).catch((e) => {
              console.error(`confirm-email send failed: ${e}`);
            });
          } catch (e) {
            console.error(`confirm-email build failed: ${e}`);
          }
        }

        // FIX-6 (Sprint 0): log the customer id, never the email. Emails
        // in logs are a common GDPR violation — we don't need them for
        // debugging since stripe_customer_id is the canonical handle.
        console.log(
          `checkout.completed: customer=${session.customer} tier=${tier} user=${userId}`,
        );
        break;
      }

      case "customer.subscription.updated": {
        const subscription = event.data.object;
        const stripeCustomerId = subscription.customer;

        // ── Wave 1 fix P0-W2 (2026-05-28) — B2B routing FIRST ────────────
        const orgIdUpd = await resolveOrgIdForCustomer(
          supabase,
          subscription.metadata?.org_id,
          stripeCustomerId as string | null,
        );
        if (orgIdUpd) {
          const actionUpd = routeSubscriptionUpdate(subscription);
          if (actionUpd.kind === "extend") {
            await updateOrgSubscriptionStatus(supabase, orgIdUpd, "active", "active");
          } else if (actionUpd.kind === "mark_past_due") {
            await updateOrgSubscriptionStatus(supabase, orgIdUpd, "past_due", "past_due");
          } else if (actionUpd.kind === "downgrade") {
            await updateOrgSubscriptionStatus(supabase, orgIdUpd, "canceled", "canceled");
          }
          // ignore: nothing to do
          break;
        }

        // FIX-6 (Sprint 0): route by status.
        //   active/trialing -> extend (FIXES the 30-day-lockout bug)
        //   past_due        -> flag, do not downgrade yet (grace period)
        //   canceled/unpaid -> downgrade
        //   anything else   -> ignore (Stripe has ~30 subscription statuses)
        const action = routeSubscriptionUpdate(subscription);

        if (action.kind === "extend") {
          const { data: users } = await supabase
            .from("profiles")
            .select("id")
            .eq("stripe_customer_id", stripeCustomerId)
            .limit(1);
          if (users && users.length > 0) {
            const userId = users[0].id;
            resolvedUserId = userId;
            // Capture prior tier before the update so the Contract Review
            // window only resets on a real tier change (not on renewal).
            const priorTierExtend = await readPriorTier(supabase, userId);
            const { error: pErr } = await supabase.from("profiles").update({
              subscription_tier: action.tier,
              subscription_expires_at: action.expires_at,
              is_pro: true,
            }).eq("id", userId);
            if (pErr) {
              throw new Error(`profiles update (extend) failed: ${pErr.message}`);
            }
            await verifyProfileWrite(supabase, userId, {
              is_pro: true,
              subscription_tier: action.tier,
            });
            const { error: sErr } = await supabase.from("subscriptions").upsert({
              user_id: userId,
              status: "active",
              tier: action.tier,
              current_period_end: action.expires_at,
              stripe_subscription_id: subscription.id,
              updated_at: new Date().toISOString(),
            }, { onConflict: "user_id" });
            if (sErr) {
              throw new Error(`subscriptions upsert (extend) failed: ${sErr.message}`);
            }
            await verifySubscriptionWrite(supabase, userId, { status: "active" });
            await maybeResetContractReviewQuota(
              supabase,
              userId,
              priorTierExtend,
              action.tier as Tier,
            );
            console.log(
              `subscription.updated: extended customer=${stripeCustomerId} ` +
                `tier=${action.tier} until=${action.expires_at}`,
            );
          }
        } else if (action.kind === "mark_past_due") {
          // Best-effort column update — if the profiles table doesn't have
          // a `subscription_status` column yet (schema drift — see FIX-3),
          // the query returns an error which we swallow to avoid breaking
          // the webhook. The flag is diagnostic, not security-critical.
          const { data: users } = await supabase
            .from("profiles")
            .select("id")
            .eq("stripe_customer_id", stripeCustomerId)
            .limit(1);
          if (users && users.length > 0) {
            resolvedUserId = users[0].id;
            // No verification: the column may not exist (schema drift); the
            // flag is diagnostic, not security-critical, so we don't throw.
            await supabase.from("profiles").update({
              subscription_status: "past_due",
            }).eq("id", users[0].id);
          }
          console.log(
            `subscription.updated: past_due customer=${stripeCustomerId}`,
          );
        } else if (action.kind === "downgrade") {
          const { data: users } = await supabase
            .from("profiles")
            .select("id")
            .eq("stripe_customer_id", stripeCustomerId)
            .limit(1);
          if (users && users.length > 0) {
            const userId = users[0].id;
            resolvedUserId = userId;
            const priorTierDowngrade = await readPriorTier(supabase, userId);
            const { error: pErr } = await supabase.from("profiles").update({
              subscription_tier: "free",
              subscription_expires_at: null,
              is_pro: false,
            }).eq("id", userId);
            if (pErr) {
              throw new Error(`profiles update (downgrade) failed: ${pErr.message}`);
            }
            await verifyProfileWrite(supabase, userId, { is_pro: false });
            const { error: sErr } = await supabase.from("subscriptions").update({
              status: "canceled",
              updated_at: new Date().toISOString(),
            }).eq("user_id", userId);
            if (sErr) {
              throw new Error(`subscriptions update (downgrade) failed: ${sErr.message}`);
            }
            await verifySubscriptionWrite(supabase, userId, { status: "canceled" });
            await maybeResetContractReviewQuota(
              supabase,
              userId,
              priorTierDowngrade,
              "free",
            );
            console.log(
              `subscription.updated: downgraded customer=${stripeCustomerId}`,
            );
          }
        } else {
          // ignore
          console.log(
            `subscription.updated: ignored customer=${stripeCustomerId} ` +
              `reason=${action.reason}`,
          );
        }
        break;
      }

      case "customer.subscription.deleted": {
        const subscription = event.data.object;
        const stripeCustomerId = subscription.customer;

        // ── Wave 1 fix P0-W2 (2026-05-28) — B2B routing FIRST ────────────
        const orgIdDel = await resolveOrgIdForCustomer(
          supabase,
          subscription.metadata?.org_id,
          stripeCustomerId as string | null,
        );
        if (orgIdDel) {
          await updateOrgSubscriptionStatus(supabase, orgIdDel, "canceled", "canceled");
          break;
        }

        const { data: users } = await supabase
          .from("profiles")
          .select("id")
          .eq("stripe_customer_id", stripeCustomerId)
          .limit(1);

        if (users && users.length > 0) {
          const userId = users[0].id;
          resolvedUserId = userId;
          const priorTierDeleted = await readPriorTier(supabase, userId);
          const { error: pErr } = await supabase.from("profiles").update({
            subscription_tier: "free",
            subscription_expires_at: null,
            is_pro: false,
          }).eq("id", userId);
          if (pErr) {
            throw new Error(`profiles update (deleted) failed: ${pErr.message}`);
          }
          await verifyProfileWrite(supabase, userId, { is_pro: false });
          const { error: sErr } = await supabase.from("subscriptions").update({
            status: "canceled",
            updated_at: new Date().toISOString(),
          }).eq("user_id", userId);
          if (sErr) {
            throw new Error(`subscriptions update (deleted) failed: ${sErr.message}`);
          }
          await verifySubscriptionWrite(supabase, userId, { status: "canceled" });
          await maybeResetContractReviewQuota(
            supabase,
            userId,
            priorTierDeleted,
            "free",
          );

          console.log(
            `subscription.deleted: customer=${stripeCustomerId}`,
          );
        }
        break;
      }

      case "invoice.payment_failed": {
        // FIX-6 (Sprint 0): reference customer.id only, never customer_email.
        const invoice = event.data.object;
        console.log(
          `invoice.payment_failed: customer=${invoice.customer ?? "unknown"}`,
        );
        break;
      }

      case "charge.refunded": {
        // FIX-WAVE 8 (DEPT 4): full or partial refund → downgrade Pro.
        // Path: charge.payment_intent → invoice.payment_intent → invoice.subscription
        //   → subscriptions.stripe_subscription_id → profiles.id
        //
        // We follow exactly the same write+verify pattern as
        // customer.subscription.deleted so the read-after-write guarantee
        // is consistent across cancel paths. Idempotency is already
        // enforced by webhook_events (event_id PK + checkAndMarkProcessing).
        const charge = event.data.object;
        const paymentIntentId = charge.payment_intent as string | null;
        const stripeCustomerId = charge.customer as string | null;

        if (!paymentIntentId) {
          console.warn(
            `[stripe-webhook] charge.refunded: no payment_intent on charge=${charge.id}`,
          );
          break;
        }

        // Resolve invoice → subscription via Stripe REST. We don't import
        // the Stripe SDK here (the rest of this file uses raw fetch for
        // signature verification only) — mirror customer-portal's pattern.
        let subscriptionId: string | null = null;
        try {
          const piRes = await fetch(
            `https://api.stripe.com/v1/payment_intents/${paymentIntentId}`,
            {
              headers: {
                "Authorization": `Bearer ${STRIPE_SECRET_KEY}`,
                "Stripe-Version": "2024-06-20",
              },
            },
          );
          if (!piRes.ok) {
            throw new Error(`stripe payment_intents ${piRes.status}`);
          }
          const pi = await piRes.json();
          const invoiceId = pi.invoice as string | null;
          if (!invoiceId) {
            // Refund on a one-shot charge (no invoice/subscription).
            // Nothing to downgrade.
            console.log(
              `charge.refunded: payment_intent=${paymentIntentId} has no invoice ` +
                `(non-subscription charge); skipping downgrade`,
            );
            break;
          }
          const invRes = await fetch(
            `https://api.stripe.com/v1/invoices/${invoiceId}`,
            {
              headers: {
                "Authorization": `Bearer ${STRIPE_SECRET_KEY}`,
                "Stripe-Version": "2024-06-20",
              },
            },
          );
          if (!invRes.ok) {
            throw new Error(`stripe invoices ${invRes.status}`);
          }
          const inv = await invRes.json();
          subscriptionId = (inv.subscription as string | null) ?? null;
        } catch (e) {
          const msg = e instanceof Error ? e.message : String(e);
          // Throw so the outer catch marks status='error' and Stripe retries.
          throw new Error(
            `charge.refunded: stripe lookup failed: ${msg.slice(0, 200)}`,
          );
        }

        if (!subscriptionId) {
          console.log(
            `charge.refunded: invoice has no subscription_id ` +
              `(payment_intent=${paymentIntentId}); skipping downgrade`,
          );
          break;
        }

        // ── Wave 1 fix P0-W2 (2026-05-28) — B2B routing FIRST ────────────
        // If the refunded subscription belongs to an org, downgrade the org,
        // not a random B2C profile that happens to match by email/customer.
        {
          const { data: orgSubRow } = await supabase
            .from("org_subscriptions")
            .select("org_id")
            .eq("stripe_subscription_id", subscriptionId)
            .limit(1)
            .maybeSingle();
          let orgIdRef: string | null = orgSubRow?.org_id ?? null;
          if (!orgIdRef && stripeCustomerId) {
            orgIdRef = await resolveOrgIdForCustomer(
              supabase,
              null,
              stripeCustomerId,
            );
          }
          if (orgIdRef) {
            await updateOrgSubscriptionStatus(
              supabase,
              orgIdRef,
              "refunded",
              "canceled",
            );
            console.log(
              `charge.refunded (B2B): org=${orgIdRef} sub=${subscriptionId} ` +
                `amount_refunded=${charge.amount_refunded ?? 0}`,
            );
            break;
          }
        }

        // Find the user via subscriptions.stripe_subscription_id. Fall back
        // to profiles.stripe_customer_id if the subscriptions row is gone
        // (defensive — shouldn't happen but refunds can lag deletes).
        let userId: string | null = null;
        const { data: subRow } = await supabase
          .from("subscriptions")
          .select("user_id")
          .eq("stripe_subscription_id", subscriptionId)
          .limit(1);
        if (subRow && subRow.length > 0) {
          userId = subRow[0].user_id as string;
        } else if (stripeCustomerId) {
          const { data: profRow } = await supabase
            .from("profiles")
            .select("id")
            .eq("stripe_customer_id", stripeCustomerId)
            .limit(1);
          if (profRow && profRow.length > 0) {
            userId = profRow[0].id as string;
          }
        }

        if (!userId) {
          console.warn(
            `charge.refunded: no user for subscription=${subscriptionId} ` +
              `customer=${stripeCustomerId ?? "unknown"}`,
          );
          break;
        }

        resolvedUserId = userId;

        // Read prior tier so we can decide quota reset (refund of a paid
        // user → free counts as a real tier change).
        const priorTierRefunded = await readPriorTier(supabase, userId);

        // Only act if the linked profile is currently Pro. If they're
        // already free (e.g. previous webhook downgraded them), this is a
        // no-op for is_pro but we still flip subscriptions.status so the
        // refund is recorded.
        const { error: pErr } = await supabase.from("profiles").update({
          subscription_tier: "free",
          subscription_expires_at: null,
          is_pro: false,
        }).eq("id", userId);
        if (pErr) {
          throw new Error(`profiles update (refunded) failed: ${pErr.message}`);
        }
        await verifyProfileWrite(supabase, userId, { is_pro: false });

        // subscriptions.status is plain TEXT (no enum/CHECK constraint —
        // see migration 20260422005000_schema_drift_fix.sql line 97), so
        // 'refunded' is accepted. We use 'refunded' (not 'canceled') so
        // billing analytics can distinguish refund-driven churn from
        // user-initiated cancels.
        const { error: sErr } = await supabase.from("subscriptions").update({
          status: "refunded",
          updated_at: new Date().toISOString(),
        }).eq("user_id", userId);
        if (sErr) {
          throw new Error(`subscriptions update (refunded) failed: ${sErr.message}`);
        }
        await verifySubscriptionWrite(supabase, userId, { status: "refunded" });

        await maybeResetContractReviewQuota(
          supabase,
          userId,
          priorTierRefunded,
          "free",
        );

        console.log(
          `charge.refunded: downgraded customer=${stripeCustomerId ?? "unknown"} ` +
            `subscription=${subscriptionId} user=${userId} ` +
            `amount_refunded=${charge.amount_refunded ?? 0}`,
        );
        break;
      }

      default:
        // Launch-week observability: warn so unhandled events are visible in
        // Supabase Dashboard logs (filtered above info level). We still
        // return 200 — Stripe must not retry types we deliberately don't
        // handle. Schema: callers/tests grep for "[stripe-webhook] unhandled".
        console.warn(
          `[stripe-webhook] unhandled event type: ${event.type} id=${event.id}`,
        );
    }

    // All DB writes for this event succeeded AND verification passed.
    await markOk(supabase, event.id, resolvedUserId);

    return new Response(JSON.stringify({ received: true }), {
      status: 200,
      headers: responseHeaders,
    });

    } catch (innerErr) {
      // A write or verification threw. Mark webhook_events.status='error',
      // increment retry_count, and re-throw so the outer catch returns 500
      // and Stripe retries.
      await markError(supabase, event.id, innerErr);
      throw innerErr;
    }
  } catch (error) {
    // Scrub any email-shaped substrings before logging.
    const msg = error instanceof Error ? error.message : String(error);
    console.error("Webhook error:", scrubPIIFromLog(msg).slice(0, 300));
    return new Response(JSON.stringify({ error: "Internal error" }), {
      status: 500,
      headers: responseHeaders,
    });
  }
}));
