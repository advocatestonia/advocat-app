// create-checkout Edge Function
// -----------------------------------------------------------------------------
// Sprint 0 — FIX-7 (HIGH): Require JWT and force customer_email from the
// authenticated user's session, never from the request body. Rate-limit to
// 5 req/min per user.
//
// Ref: docs/security/02-auth-authz.md H2 — the pre-FIX-7 function accepted
// `customer_email` from the client, which enabled:
//   - Phishing: send `victim@bank.com` a legitimate-looking Stripe checkout
//     URL; victim pays; we take the blame via chargebacks
//   - Email enumeration against our user base
//   - Email bombardment via Stripe receipt emails
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import Stripe from "https://esm.sh/stripe@14.14.0?target=deno";
import {
  corsHeaders,
  jsonError,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, {
  apiVersion: "2023-10-16",
  httpClient: Stripe.createFetchHttpClient(),
});

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
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // FIX-7: JWT required + 5 req/min/user cap.
  const gate = await requireUserWithRateLimit(req, {
    bucket: "create-checkout",
    maxPerMinute: 5,
  });
  if (gate.kind === "deny") return gate.response;

  try {
    // FIX-7: ignore `customer_email` from the body entirely. We use only
    // the JWT-verified email. Destructure the remaining fields only.
    const { plan_id, billing_period, success_url, cancel_url } = await req
      .json();

    // Validate inputs
    if (!plan_id || !billing_period) {
      return jsonError("plan_id and billing_period are required", 400);
    }

    const planPrices = PRICES[plan_id];
    if (!planPrices) {
      return jsonError(`Unknown plan_id: ${plan_id}`, 400);
    }

    const priceEntry = planPrices[billing_period];
    if (!priceEntry) {
      return jsonError(
        `Unknown billing_period: ${billing_period} for plan ${plan_id}`,
        400,
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
      success_url: success_url || "https://advocat.ee/payment-success.html",
      cancel_url: cancel_url || "https://advocat.ee/payment-cancel.html",
      metadata: {
        plan_id,
        billing_period,
        // Record the authenticated user ID so the webhook can resolve the
        // row in `profiles` even if the email later changes.
        user_id: gate.user.id,
      },
      // In subscription mode Stripe auto-generates an invoice per billing
      // cycle; putting a human-readable description on the subscription
      // makes the invoice PDF legible.
      subscription_data: {
        description: priceEntry.name,
      },
    };

    // Note: the "invoice PDF + receipt email" behaviour depends on the
    // Stripe Dashboard setting *Settings → Customer emails →
    // "Successful payments"* being ON. If it's OFF, customers won't get
    // an email even though the invoice exists. We also send our own
    // confirmation via the `send-email` Edge Function from stripe-webhook.

    // Founding member: metadata flag so the webhook enforces the 3-month
    // limit. The price itself is already discounted.
    if (billing_period === "founding") {
      sessionParams.metadata!.founding_months = "3";
    }

    // FIX-7: email comes from the JWT session, never from the body.
    // A user without an email on their auth record cannot check out —
    // that's the correct behaviour: Stripe Checkout needs an email and
    // accepting one from the client re-opens the phishing vector.
    if (gate.user.email) {
      sessionParams.customer_email = gate.user.email;
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
    // Do NOT include user email or full message in the log — Stripe errors
    // sometimes surface the customer object which contains PII.
    console.error("create-checkout failed:", message.slice(0, 200));
    return jsonError(message, 500);
  }
});
