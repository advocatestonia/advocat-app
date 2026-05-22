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
import { killOn, paymentsPausedResponse } from "../_shared/kill_switches.ts";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, {
  apiVersion: "2023-10-16",
  httpClient: Stripe.createFetchHttpClient(),
});

// GDPR Art. 28 — current DPA version. MUST match `kCurrentDpaVersion` in
// `lib/features/legal/data/dpa_text.dart`. The edge function refuses to
// mint a Stripe session unless a row exists in `public.dpa_acceptances`
// for (user_id, this version). Defence-in-depth: even if the client UI
// is bypassed, no charge can happen without a recorded acceptance.
const CURRENT_DPA_VERSION = "v1.0-2026-05-20";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// ── Price lookup table (EUR cents) ──────────────────────────────────────

interface PriceEntry {
  amount: number;
  interval: "month" | "year";
  name: string;
  trialDays?: number;
}

// Pricing model (launch pricing, no founder program):
//   - Pro:     €19.99/mo  or  €159.99/yr
//   - Premium: €29.99/mo  or  €249.99/yr
//
// Plan-key mapping kept for backwards-compatibility with existing callers:
//   plan_id="counsel"        → Pro tier  (€19.99 / €159.99)
//   plan_id="representation" → Premium   (€29.99 / €249.99)
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

  // ── Kill switch: KILL_PAYMENTS=1 (DEPT 7 runbook) ──────────────────────
  // Flip via `supabase secrets set KILL_PAYMENTS=1` when Stripe or our
  // billing pipeline is in incident. Returns 503 with `error: "payments_paused"`;
  // the Flutter pricing page renders "Payments temporarily disabled."
  if (killOn("KILL_PAYMENTS")) {
    return paymentsPausedResponse();
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
    // UTM / click-id params are attribution-only — we forward them to Stripe
    // metadata for revenue attribution but never trust them for billing.
    const {
      plan_id,
      billing_period,
      success_url,
      cancel_url,
      utm_source,
      utm_medium,
      utm_campaign,
      utm_content,
      utm_term,
      gclid,
      fbclid,
      ttclid,
    } = await req.json();

    // Validate inputs
    if (!plan_id || !billing_period) {
      return jsonError("plan_id and billing_period are required", 400);
    }

    // Sanitise UTM strings: Stripe metadata value cap is 500 chars per key,
    // and we want to defend against ad-network injection garbage. Coerce to
    // string, trim, and truncate. Drop empties so we don't pollute metadata.
    const utmStr = (v: unknown): string => {
      if (typeof v !== "string") return "";
      return v.slice(0, 200);
    };

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

    // ── GDPR Art. 28 hard-gate ─────────────────────────────────────────
    // Refuse to mint a session if there is no acceptance row for the
    // current DPA version. The client-side dialog should have created
    // this row already; this is defence-in-depth for direct API callers.
    try {
      const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
        auth: { persistSession: false, autoRefreshToken: false },
      });
      const { data: dpa, error: dpaErr } = await admin
        .from("dpa_acceptances")
        .select("id")
        .eq("user_id", gate.user.id)
        .eq("dpa_version", CURRENT_DPA_VERSION)
        .limit(1)
        .maybeSingle();
      if (dpaErr) {
        console.error("dpa_acceptances lookup failed:", dpaErr.message);
        return jsonError("DPA verification failed", 500);
      }
      if (!dpa) {
        return jsonError("dpa_not_accepted", 412, {
          version: CURRENT_DPA_VERSION,
        });
      }
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      console.error("dpa_acceptances gate error:", msg.slice(0, 200));
      return jsonError("DPA verification failed", 500);
    }

    // Build Stripe Checkout Session parameters.
    //
    // VAT status (2026-05-20): Vorantis OÜ is NOT yet registered as
    // käibemaksukohuslane (KMKR / VAT-payer) in Estonia. By Estonian
    // käibemaksuseadus we therefore CANNOT charge VAT — prices shown are
    // simply the price the customer pays. Stripe automatic_tax stays OFF
    // until KMKR registration completes (mandatory at €40k EE turnover).
    //
    // When KMKR registration lands, re-enable:
    //   tax_behavior: "exclusive" on price_data
    //   automatic_tax: { enabled: true }
    //   billing_address_collection: "required"
    //   tax_id_collection: { enabled: true }
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
        // Attribution metadata — forwarded from the landing page's UTM
        // capture. The webhook (or any downstream BI job) can read these
        // from `session.metadata` for revenue attribution. Empty strings
        // are fine; Stripe accepts them and BI tools filter them out.
        utm_source: utmStr(utm_source),
        utm_medium: utmStr(utm_medium),
        utm_campaign: utmStr(utm_campaign),
        utm_content: utmStr(utm_content),
        utm_term: utmStr(utm_term),
        gclid: utmStr(gclid),
        fbclid: utmStr(fbclid),
        ttclid: utmStr(ttclid),
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
