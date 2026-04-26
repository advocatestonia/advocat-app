import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
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

const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY")!;
const STRIPE_WEBHOOK_SECRET = Deno.env.get("STRIPE_WEBHOOK_SECRET");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// No CORS headers needed — Stripe calls server-to-server, not from browsers
const responseHeaders = {
  "Content-Type": "application/json",
};

/** Constant-time equality for hex strings (prevents timing oracle). */
function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let r = 0;
  for (let i = 0; i < a.length; i++) {
    r |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return r === 0;
}

// Stripe recommends rejecting events older than 5 minutes to block replays.
const MAX_WEBHOOK_AGE_SEC = 300;

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204 });
  }

  try {
    const body = await req.text();

    // Verify Stripe webhook signature
    const signature = req.headers.get("stripe-signature");
    if (!signature || !STRIPE_WEBHOOK_SECRET) {
      return new Response(JSON.stringify({ error: "Missing signature" }), {
        status: 401, headers: responseHeaders,
      });
    }

    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey(
      "raw",
      encoder.encode(STRIPE_WEBHOOK_SECRET),
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"]
    );

    const parts = signature.split(",");
    const timestamp = parts.find((p: string) => p.startsWith("t="))?.split("=")[1];
    const sig = parts.find((p: string) => p.startsWith("v1="))?.split("=")[1];

    if (!timestamp || !sig) {
      return new Response(JSON.stringify({ error: "Invalid signature format" }), {
        status: 401, headers: responseHeaders,
      });
    }

    // Replay-attack protection: reject stale webhooks
    const timestampNum = parseInt(timestamp, 10);
    const nowSec = Math.floor(Date.now() / 1000);
    if (!timestampNum || Math.abs(nowSec - timestampNum) > MAX_WEBHOOK_AGE_SEC) {
      return new Response(JSON.stringify({ error: "Stale webhook" }), {
        status: 401, headers: responseHeaders,
      });
    }

    const signedPayload = `${timestamp}.${body}`;
    const expectedSig = await crypto.subtle.sign("HMAC", key, encoder.encode(signedPayload));
    const expectedHex = Array.from(new Uint8Array(expectedSig))
      .map((b: number) => b.toString(16).padStart(2, "0")).join("");

    if (!timingSafeEqual(expectedHex, sig)) {
      return new Response(JSON.stringify({ error: "Invalid signature" }), {
        status: 401, headers: responseHeaders,
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
        const billingPeriod = metadata.billing_period; // "monthly", "yearly", "founding"
        const metaUserId = metadata.user_id; // set by create-checkout (authenticated caller)

        const tier = PLAN_MAPPING[planId] || "basic";

        // Calculate expiry date
        let expiresAt: Date;
        if (billingPeriod === "yearly") {
          expiresAt = new Date();
          expiresAt.setFullYear(expiresAt.getFullYear() + 1);
        } else if (billingPeriod === "founding") {
          expiresAt = new Date();
          expiresAt.setMonth(expiresAt.getMonth() + 3);
        } else {
          expiresAt = new Date();
          expiresAt.setMonth(expiresAt.getMonth() + 1);
        }

        // Resolve user. Prefer the authenticated user_id from create-checkout
        // metadata; fall back to email lookup for legacy sessions.
        let userId: string | null = null;
        if (metaUserId) {
          userId = metaUserId;
        } else if (customerEmail) {
          const { data: users } = await supabase
            .from("profiles")
            .select("id")
            .eq("email", customerEmail)
            .limit(1);
          if (users && users.length > 0) userId = users[0].id;
        }

        if (!userId) {
          console.error(
            `checkout.completed: no user_id in metadata and no profile for customer=${session.customer}`,
          );
          break;
        }

        resolvedUserId = userId;

        // Upsert — if the profile row doesn't exist yet (trigger gap), create
        // it. This eliminates the silent-failure class where a paying user
        // had no profile row and their Pro never activated.
        //
        // is_pro = true is REQUIRED — check-ai-quota Edge Function reads
        // is_pro to decide if quota is enforced; subscription_tier alone is
        // not enough. Sofia's manual activation 2026-04-26 surfaced this.
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
        const { error: subUpErr } = await supabase.from("subscriptions").upsert({
          user_id: userId,
          status: "active",
          tier: tier,
          current_period_end: expiresAt.toISOString(),
          stripe_subscription_id: session.subscription || null,
          updated_at: new Date().toISOString(),
        }, { onConflict: "user_id" });
        if (subUpErr) {
          throw new Error(`subscriptions upsert failed: ${subUpErr.message}`);
        }
        await verifySubscriptionWrite(supabase, userId, { status: "active" });

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

        const { data: users } = await supabase
          .from("profiles")
          .select("id")
          .eq("stripe_customer_id", stripeCustomerId)
          .limit(1);

        if (users && users.length > 0) {
          const userId = users[0].id;
          resolvedUserId = userId;
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

      default:
        console.log(`Unhandled event type: ${event.type}`);
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
});
