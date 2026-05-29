// create-org-checkout Edge Function
// -----------------------------------------------------------------------------
// Open a Stripe Checkout session for a NEW org subscription (per-seat).
//
// Auth: JWT + X-Org-Context. Min role: owner. Rate-limit 5/min/user.
//
// Critical: stripe-webhook discriminates between B2C and B2B by looking at
// `metadata.org_id`. We MUST set it here. Plan-change flows (upgrade/downgrade)
// for an existing subscription go through the Billing Portal, not this endpoint.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  jsonError,
  jsonOk,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import { requireOrgContext } from "../_shared/orgAuth.ts";
import { writeOrgAudit } from "../_shared/auditLog.ts";
import { killOn, paymentsPausedResponse } from "../_shared/kill_switches.ts";
import { validateCheckoutRedirects } from "../_shared/redirect_allowlist.ts";

const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const APP_URL = Deno.env.get("APP_URL") ?? "https://advocat.ee";

// KMKR gate: while we are not VAT-registered, B2B invoices for foreign
// VAT-registered customers cannot be issued correctly. The architecture doc
// requires us to refuse with a 503 if vat_id is supplied AND country != EE.
const KMKR_REGISTERED =
  (Deno.env.get("KMKR_REGISTERED") ?? "false").toLowerCase() === "true";

// Current DPA version (must match create-checkout / lib/features/legal).
const CURRENT_DPA_VERSION = "v1.0-2026-05-20";

// Plan/period → unit_amount_cents per seat. Single source of truth for B2B
// pricing. Annual = 2 months free (16.7% discount).
const SEAT_PRICES: Record<string, Record<string, { amount: number; interval: "month" | "year" }>> = {
  starter: {
    monthly: { amount: 2900, interval: "month" }, // €29
    yearly:  { amount: 29000, interval: "year" }, // €290 (10 × €29)
  },
  firm: {
    monthly: { amount: 4900, interval: "month" }, // €49
    yearly:  { amount: 49000, interval: "year" },
  },
  enterprise: {
    monthly: { amount: 9900, interval: "month" }, // €99
    yearly:  { amount: 99000, interval: "year" },
  },
};

const PLAN_SEAT_BOUNDS: Record<string, { min: number; max: number }> = {
  starter:    { min: 1, max: 5 },
  firm:       { min: 3, max: 25 },
  enterprise: { min: 10, max: 1000 },
};

interface CheckoutBody {
  plan?: string;
  billing_period?: string;
  seats?: number;
  success_url?: string;
  cancel_url?: string;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  if (killOn("KILL_PAYMENTS")) {
    return paymentsPausedResponse();
  }

  const gate = await requireUserWithRateLimit(req, {
    bucket: "create-org-checkout",
    maxPerMinute: 5,
  });
  if (gate.kind === "deny") return gate.response;

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const orgGate = await requireOrgContext(
    req,
    supabase,
    gate.user.id,
    gate.user.email,
    { minRole: "owner" },
  );
  if (orgGate.kind === "deny") return orgGate.response;
  const ctx = orgGate.ctx;

  let body: CheckoutBody;
  try {
    body = await req.json();
  } catch {
    return jsonError("Invalid JSON body", 400, { reason: "invalid_json" });
  }

  const plan = (body.plan ?? "").toLowerCase();
  const billingPeriod = (body.billing_period ?? "").toLowerCase();
  const seats = Number(body.seats ?? 0);

  if (!SEAT_PRICES[plan]) {
    return jsonError("Invalid plan", 400, { reason: "invalid_plan" });
  }
  if (!SEAT_PRICES[plan][billingPeriod]) {
    return jsonError("Invalid billing period", 400, {
      reason: "invalid_billing_period",
    });
  }
  const bounds = PLAN_SEAT_BOUNDS[plan];
  if (!Number.isInteger(seats) || seats < bounds.min || seats > bounds.max) {
    return jsonError("Invalid seat count", 400, {
      reason: "invalid_seats",
      min: bounds.min,
      max: bounds.max,
    });
  }

  // ── Org pre-checks ────────────────────────────────────────────────────
  const { data: org, error: orgErr } = await supabase
    .from("organizations")
    .select(
      "id, name, country, billing_email, vat_id, stripe_customer_id, plan, status",
    )
    .eq("id", ctx.org_id)
    .maybeSingle();
  if (orgErr || !org) {
    return jsonError("Org not found", 404, { reason: "org_not_found" });
  }
  if (!org.country || !org.billing_email) {
    return jsonError("Org billing details incomplete", 412, {
      reason: "billing_details_incomplete",
      missing: [
        ...(org.country ? [] : ["country"]),
        ...(org.billing_email ? [] : ["billing_email"]),
      ],
    });
  }

  // KMKR gate (architecture §7 risks): refuse cross-border B2B invoices
  // until we're VAT-registered.
  if (org.vat_id && org.country !== "EE" && !KMKR_REGISTERED) {
    return jsonError("B2B billing temporarily unavailable", 503, {
      reason: "b2b_billing_temporarily_unavailable",
      detail: "KMKR registration in progress",
    });
  }

  // DPA hard-gate: the user (acting as owner) must have accepted the current
  // DPA. Org-level acceptance lives in `dpa_acceptances` keyed by user_id.
  const { data: dpa } = await supabase
    .from("dpa_acceptances")
    .select("id")
    .eq("user_id", ctx.user_id)
    .eq("dpa_version", CURRENT_DPA_VERSION)
    .maybeSingle();
  if (!dpa) {
    return jsonError("DPA not accepted", 412, {
      reason: "dpa_not_accepted",
      version: CURRENT_DPA_VERSION,
    });
  }

  // ── Ensure Stripe customer exists for the org ─────────────────────────
  let customerId = org.stripe_customer_id as string | undefined;
  if (!customerId) {
    try {
      const params = new URLSearchParams({
        email: org.billing_email,
        name: org.name ?? "",
        "metadata[org_id]": org.id,
      });
      if (org.vat_id) {
        params.append("metadata[vat_id]", org.vat_id);
      }
      const res = await fetch("https://api.stripe.com/v1/customers", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${STRIPE_SECRET_KEY}`,
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: params,
        signal: AbortSignal.timeout(10_000),
      });
      if (!res.ok) {
        console.error("[create-org-checkout] customer create failed:", res.status);
        return jsonError("Could not initialise billing", 502, {
          reason: "stripe_customer_create_failed",
        });
      }
      const cust = await res.json();
      customerId = cust.id;
      await supabase
        .from("organizations")
        .update({ stripe_customer_id: customerId })
        .eq("id", org.id);
    } catch (e) {
      console.error("[create-org-checkout] customer create threw:", e);
      return jsonError("Billing backend error", 503, {
        reason: "stripe_backend_error",
      });
    }
  }

  // ── Build checkout session ────────────────────────────────────────────
  const price = SEAT_PRICES[plan][billingPeriod];

  // ── Wave 1 fix P1-08 (2026-05-28) — open-redirect protection ──────────
  // Same allowlist policy as create-checkout. APP_URL must itself be
  // inside ALLOWED_REDIRECT_HOSTS; if it isn't, validateCheckoutRedirects
  // returns ok=false so we fail loud rather than emit an unsafe default.
  const redirects = validateCheckoutRedirects(
    body.success_url,
    body.cancel_url,
    {
      success: `${APP_URL}/team/billing/success`,
      cancel: `${APP_URL}/team/billing/cancel`,
    },
  );
  if (!redirects.ok) {
    return jsonError("invalid redirect URL", 400, { reason: redirects.reason });
  }
  const successUrl = redirects.success;
  const cancelUrl = redirects.cancel;

  const params = new URLSearchParams();
  params.append("mode", "subscription");
  params.append("customer", customerId!);
  params.append("success_url", successUrl);
  params.append("cancel_url", cancelUrl);
  params.append("payment_method_types[]", "card");
  params.append("payment_method_types[]", "link");
  params.append("line_items[0][price_data][currency]", "eur");
  params.append("line_items[0][price_data][unit_amount]", String(price.amount));
  params.append("line_items[0][price_data][recurring][interval]", price.interval);
  params.append("line_items[0][price_data][product_data][name]",
    `Advocat ${plan[0].toUpperCase()}${plan.slice(1)} — per seat`);
  params.append("line_items[0][quantity]", String(seats));
  // Metadata is critical: the webhook routes by org_id presence.
  params.append("metadata[org_id]", org.id);
  params.append("metadata[plan]", plan);
  params.append("metadata[billing_period]", billingPeriod);
  params.append("metadata[seats]", String(seats));
  params.append("metadata[actor_user_id]", ctx.user_id);
  params.append("subscription_data[metadata][org_id]", org.id);
  params.append("subscription_data[metadata][plan]", plan);
  params.append("subscription_data[metadata][billing_period]", billingPeriod);

  let session: { id?: string; url?: string; error?: { code?: string } } = {};
  try {
    const res = await fetch("https://api.stripe.com/v1/checkout/sessions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${STRIPE_SECRET_KEY}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: params,
      signal: AbortSignal.timeout(10_000),
    });
    session = await res.json();
    if (!res.ok || session.error) {
      console.error("[create-org-checkout] session create failed:", session.error?.code);
      return jsonError("Failed to create checkout session", 502, {
        reason: "checkout_session_failed",
      });
    }
  } catch (e) {
    console.error("[create-org-checkout] session create threw:", e);
    return jsonError("Billing backend error", 503, {
      reason: "stripe_backend_error",
    });
  }

  await writeOrgAudit(supabase, {
    org_id: org.id,
    actor_user_id: ctx.user_id,
    action: "checkout_started",
    details: { plan, billing_period: billingPeriod, seats, session_id: session.id },
    req,
  });

  return jsonOk({ url: session.url, session_id: session.id });
});
