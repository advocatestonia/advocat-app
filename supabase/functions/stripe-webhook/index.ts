import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  PLAN_MAPPING,
  routeSubscriptionUpdate,
  scrubPIIFromLog,
} from "./subscription_router.ts";

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

    console.log(`Stripe webhook: ${event.type}`);

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    switch (event.type) {
      case "checkout.session.completed": {
        const session = event.data.object;
        const customerEmail = session.customer_email || session.customer_details?.email;
        const metadata = session.metadata || {};
        const planId = metadata.plan_id; // "counsel" or "representation"
        const billingPeriod = metadata.billing_period; // "monthly", "yearly", "founding"

        if (!customerEmail) {
          console.error("No customer email in checkout session");
          break;
        }

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

        // Find user by email
        const { data: users } = await supabase
          .from("profiles")
          .select("id")
          .eq("email", customerEmail)
          .limit(1);

        if (users && users.length > 0) {
          const userId = users[0].id;

          // Update subscription
          await supabase.from("profiles").update({
            subscription_tier: tier,
            subscription_expires_at: expiresAt.toISOString(),
            stripe_customer_id: session.customer,
          }).eq("id", userId);

          // FIX-6 (Sprint 0): log the customer id, never the email. Emails
          // in logs are a common GDPR violation — we don't need them for
          // debugging since stripe_customer_id is the canonical handle.
          console.log(
            `checkout.completed: customer=${session.customer} tier=${tier}`,
          );
        } else {
          // Even on the error path, avoid leaking the email.
          console.error(
            `checkout.completed: no profile row for customer=${session.customer}`,
          );
        }
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
            await supabase.from("profiles").update({
              subscription_tier: action.tier,
              subscription_expires_at: action.expires_at,
            }).eq("id", users[0].id);
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
            await supabase.from("profiles").update({
              subscription_tier: "free",
              subscription_expires_at: null,
            }).eq("id", users[0].id);
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
          await supabase.from("profiles").update({
            subscription_tier: "free",
            subscription_expires_at: null,
          }).eq("id", users[0].id);

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

    return new Response(JSON.stringify({ received: true }), {
      status: 200,
      headers: responseHeaders,
    });
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
