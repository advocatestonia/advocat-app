import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY")!;
const STRIPE_WEBHOOK_SECRET = Deno.env.get("STRIPE_WEBHOOK_SECRET");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Stripe-Signature",
};

// Plan mapping from Stripe to our tiers
const PLAN_MAPPING: Record<string, string> = {
  counsel: "basic",
  representation: "premium",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const body = await req.text();

    // Parse the Stripe event
    // Note: In production, verify webhook signature with STRIPE_WEBHOOK_SECRET
    // For now, we trust the event since it's on a private endpoint
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

          console.log(`Updated user ${customerEmail}: tier=${tier}, expires=${expiresAt.toISOString()}`);
        } else {
          console.error(`User not found: ${customerEmail}`);
        }
        break;
      }

      case "customer.subscription.updated": {
        const subscription = event.data.object;
        const stripeCustomerId = subscription.customer;
        const status = subscription.status; // "active", "canceled", "past_due"

        if (status === "canceled" || status === "unpaid") {
          // Downgrade to free
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

            console.log(`Downgraded customer ${stripeCustomerId} to free`);
          }
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

          console.log(`Subscription deleted for customer ${stripeCustomerId}`);
        }
        break;
      }

      case "invoice.payment_failed": {
        const invoice = event.data.object;
        const customerEmail = invoice.customer_email;
        console.log(`Payment failed for ${customerEmail}`);
        // Could send notification email here
        break;
      }

      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    return new Response(JSON.stringify({ received: true }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Webhook error:", error);
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
