import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  jsonError,
  jsonOk,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";

const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// 10s upper bound on outbound Stripe calls — without this an unhealthy
// Stripe API could hang the edge fn until Supabase's wall-clock timeout
// (~150s) and burn paying-user attempts.
const STRIPE_FETCH_TIMEOUT_MS = 10_000;

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // JWT + 10 req/min/user. Customer-portal is rarely hit in normal flow
  // (one click per user per session) — 10/min is generous abuse-prevention.
  const gate = await requireUserWithRateLimit(req, {
    bucket: "customer-portal",
    maxPerMinute: 10,
  });
  if (gate.kind === "deny") return gate.response;

  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const user = gate.user;

    // Get the user's Stripe customer ID from profiles
    const { data: profile } = await supabase
      .from("profiles")
      .select("stripe_customer_id, email")
      .eq("id", user.id)
      .maybeSingle();

    let customerId = profile?.stripe_customer_id as string | undefined;

    // If no Stripe customer yet, create one
    if (!customerId) {
      const customerEmail = profile?.email || user.email;
      const res = await fetch("https://api.stripe.com/v1/customers", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${STRIPE_SECRET_KEY}`,
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: new URLSearchParams({
          email: customerEmail || "",
          metadata: JSON.stringify({ supabase_user_id: user.id }),
        }),
        signal: AbortSignal.timeout(STRIPE_FETCH_TIMEOUT_MS),
      });

      if (!res.ok) {
        console.error("customer-portal: Stripe customer create failed", res.status);
        return jsonError("Failed to create billing profile", 502);
      }

      const customer = await res.json();
      if (!customer?.id) {
        console.error("customer-portal: Stripe response missing id");
        return jsonError("Failed to create billing profile", 502);
      }
      customerId = customer.id as string;

      // Save to profile
      await supabase
        .from("profiles")
        .update({ stripe_customer_id: customerId })
        .eq("id", user.id);
    }

    // Create a Stripe Customer Portal session
    const portalRes = await fetch(
      "https://api.stripe.com/v1/billing_portal/sessions",
      {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${STRIPE_SECRET_KEY}`,
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: new URLSearchParams({
          customer: customerId,
          return_url: "https://advocat.ee/app.html",
        }),
        signal: AbortSignal.timeout(STRIPE_FETCH_TIMEOUT_MS),
      }
    );

    const session = await portalRes.json();

    if (session.error) {
      // Don't leak Stripe internals — log them, return generic user msg.
      console.error("customer-portal: Stripe portal error", session.error.code ?? "unknown");
      return jsonError("Failed to open billing portal", 400);
    }

    return jsonOk({ url: session.url });
  } catch (error) {
    // Scrub: never echo raw error.stack / String(error) to the client.
    const msg = error instanceof Error ? error.message : "unknown";
    console.error("customer-portal failed:", msg.slice(0, 200));
    return jsonError("Internal error", 500);
  }
});
