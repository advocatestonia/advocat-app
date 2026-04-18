import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import Stripe from "https://esm.sh/stripe@14.14.0?target=deno";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, {
  apiVersion: "2023-10-16",
  httpClient: Stripe.createFetchHttpClient(),
});

const corsHeaders = {
  "Access-Control-Allow-Origin": "https://advocat.ee",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// ── Price lookup table (EUR cents) ──────────────────────────────────────

interface PriceEntry {
  amount: number;
  interval: "month" | "year";
  name: string;
  trialDays?: number;
}

const PRICES: Record<string, Record<string, PriceEntry>> = {
  counsel: {
    monthly: {
      amount: 1499,
      interval: "month",
      name: "Legal Counsel — Monthly",
    },
    yearly: {
      amount: 11999,
      interval: "year",
      name: "Legal Counsel — Yearly",
    },
    founding: {
      amount: 999,
      interval: "month",
      name: "Legal Counsel — Founding Member",
      trialDays: 0,
    },
  },
  representation: {
    monthly: {
      amount: 2999,
      interval: "month",
      name: "Advocat Pro — Monthly",
    },
    yearly: {
      amount: 24999,
      interval: "year",
      name: "Advocat Pro — Yearly",
    },
    founding: {
      amount: 1999,
      interval: "month",
      name: "Advocat Pro — Founding Member",
      trialDays: 0,
    },
  },
};

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { plan_id, billing_period, success_url, cancel_url, customer_email } =
      await req.json();

    // Validate inputs
    if (!plan_id || !billing_period) {
      return new Response(
        JSON.stringify({ error: "plan_id and billing_period are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const planPrices = PRICES[plan_id];
    if (!planPrices) {
      return new Response(
        JSON.stringify({ error: `Unknown plan_id: ${plan_id}` }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const priceEntry = planPrices[billing_period];
    if (!priceEntry) {
      return new Response(
        JSON.stringify({
          error: `Unknown billing_period: ${billing_period} for plan ${plan_id}`,
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Build Stripe Checkout Session parameters
    const sessionParams: Stripe.Checkout.SessionCreateParams = {
      payment_method_types: ["card", "link"],
      mode: "subscription",
      currency: "eur",
      line_items: [
        {
          price_data: {
            currency: "eur",
            unit_amount: priceEntry.amount,
            recurring: { interval: priceEntry.interval },
            product_data: { name: priceEntry.name },
          },
          quantity: 1,
        },
      ],
      success_url: success_url || "https://advocat.ee/payment-success",
      cancel_url: cancel_url || "https://advocat.ee/payment-cancel",
      metadata: {
        plan_id,
        billing_period,
      },
    };

    // Founding member: 3-month subscription schedule
    // The founding price itself is already discounted; we use metadata
    // so the webhook can enforce the 3-month limit.
    if (billing_period === "founding") {
      sessionParams.metadata!.founding_months = "3";
    }

    if (customer_email) {
      sessionParams.customer_email = customer_email;
    }

    const session = await stripe.checkout.sessions.create(sessionParams);

    return new Response(
      JSON.stringify({ url: session.url, session_id: session.id }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("Checkout error:", message);
    return new Response(
      JSON.stringify({ error: message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
