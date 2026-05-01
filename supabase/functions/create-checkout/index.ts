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
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  jsonError,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, {
  apiVersion: "2023-10-16",
  httpClient: Stripe.createFetchHttpClient(),
});

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// Founder program — must mirror founder-spots/index.ts and stripe-webhook.
export const FOUNDER_INTRO_TYPE = "early-access-100";
export const FOUNDER_TOTAL = 100;

// ── Price lookup table (EUR cents) ──────────────────────────────────────

interface PriceEntry {
  amount: number;
  interval: "month" | "year";
  name: string;
  trialDays?: number;
}

// Pricing model (2026-04-29):
//   - Pro:           €19.99/mo  or  €159.99/yr
//   - Early Access:  €14.99/mo  (intro pricing — see note below)
//   - Premium:       €29.99/mo  or  €249.99/yr
//
// "Early Access" replaces the old "Founding Member" naming. It is sold as a
// flat €14.99/mo recurring subscription with no automatic step-up after
// 3 months. Auto-conversion to regular Pro pricing after 3 billing cycles
// would require Stripe Pricing Phases or a fixed-duration Coupon, both of
// which are intentionally deferred for the MVP launch — see the spec note
// in the pricing-update task.
//
// Plan-key mapping kept for backwards-compatibility with existing callers:
//   plan_id="counsel"        → Pro tier  (€19.99 / €159.99 / €14.99 ea)
//   plan_id="representation" → Premium   (€29.99 / €249.99, no early access)
const PRICES: Record<string, Record<string, PriceEntry>> = {
  counsel: {
    monthly: {
      amount: 1999,
      interval: "month",
      name: "Advocat Pro — Monthly",
    },
    yearly: {
      amount: 15999,
      interval: "year",
      name: "Advocat Pro — Yearly",
    },
    "early-access": {
      amount: 1499,
      interval: "month",
      name: "Advocat Pro — Early Access",
      trialDays: 0,
    },
  },
  representation: {
    monthly: {
      amount: 2999,
      interval: "month",
      name: "Advocat Premium — Monthly",
    },
    yearly: {
      amount: 24999,
      interval: "year",
      name: "Advocat Premium — Yearly",
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

    // ── Founder cap check ───────────────────────────────────────────────
    // For Early Access (€14.99/mo lifetime): only the first 100 paying
    // users get the founder rate. After that, the option must refuse —
    // the landing page also hides the CTA but a power-user could still
    // hit this endpoint directly with billing_period="early-access".
    //
    // Slot accounting: "taken" = subscriptions rows where
    // intro_type='early-access-100' AND status IN ('active','trialing').
    // A canceled subscription releases its slot back to the pool — that
    // matches the user-visible promise on the landing page.
    //
    // Race window between this check and the webhook write is tiny but
    // non-zero. The webhook re-checks the cap and downgrades intro_type
    // to NULL if the slot was taken by a parallel checkout — see
    // stripe-webhook/index.ts.
    if (billing_period === "early-access") {
      const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
      const { count, error: capErr } = await supabase
        .from("subscriptions")
        .select("*", { count: "exact", head: true })
        .eq("intro_type", FOUNDER_INTRO_TYPE)
        .in("status", ["active", "trialing"]);
      if (capErr) {
        // Fail closed: if we can't check the cap, do NOT create a €14.99
        // session — surface a generic error and let the user retry.
        console.error("create-checkout cap probe failed:", capErr.message.slice(0, 200));
        return jsonError("Could not verify Early Access availability", 503);
      }
      if ((count ?? 0) >= FOUNDER_TOTAL) {
        return new Response(
          JSON.stringify({
            error: "early_access_full",
            message:
              "All 100 founder seats are taken. Pro €19.99/mo is available.",
          }),
          {
            status: 410, // Gone — slot offer has been withdrawn
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          },
        );
      }
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

    // Early Access (intro pricing): metadata flag so the webhook can
    // recognize these subscriptions and record the founder intro_type on
    // the subscriptions row. The webhook re-checks the 100-slot cap before
    // recording — if a race lost the slot, intro_type stays NULL and the
    // user pays €14.99 without the lifetime guarantee (the founder claim).
    if (billing_period === "early-access") {
      sessionParams.metadata!.early_access = "true";
      sessionParams.metadata!.intro_type = FOUNDER_INTRO_TYPE;
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
