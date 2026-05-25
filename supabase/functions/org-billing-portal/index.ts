// org-billing-portal Edge Function
// -----------------------------------------------------------------------------
// Open a Stripe Billing Portal session scoped to the org's Stripe customer.
//
// Auth: JWT + X-Org-Context. Min role: billing OR admin (we use minRole=billing
// since billing < admin < owner in our rank table — any role >= billing
// passes).
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

const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const APP_URL = Deno.env.get("APP_URL") ?? "https://advocat.ee";

const STRIPE_FETCH_TIMEOUT_MS = 10_000;

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  const gate = await requireUserWithRateLimit(req, {
    bucket: "org-billing-portal",
    maxPerMinute: 10,
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
    { minRole: "billing" }, // billing ≥ admin/owner via rank
  );
  if (orgGate.kind === "deny") return orgGate.response;
  const ctx = orgGate.ctx;

  // ── Fetch org's Stripe customer ID ────────────────────────────────────
  const { data: org, error: orgErr } = await supabase
    .from("organizations")
    .select("id, stripe_customer_id, billing_email, name")
    .eq("id", ctx.org_id)
    .maybeSingle();
  if (orgErr || !org) {
    return jsonError("Org not found", 404, { reason: "org_not_found" });
  }

  let customerId = org.stripe_customer_id as string | undefined;

  // If the org has never been billed, lazily create the Stripe customer.
  if (!customerId) {
    try {
      const res = await fetch("https://api.stripe.com/v1/customers", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${STRIPE_SECRET_KEY}`,
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: new URLSearchParams({
          email: org.billing_email ?? "",
          name: org.name ?? "",
          "metadata[org_id]": org.id,
        }),
        signal: AbortSignal.timeout(STRIPE_FETCH_TIMEOUT_MS),
      });
      if (!res.ok) {
        console.error("[org-billing-portal] customer create failed:", res.status);
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
      console.error("[org-billing-portal] customer create threw:", e);
      return jsonError("Billing backend error", 503, {
        reason: "stripe_backend_error",
      });
    }
  }

  // ── Open portal session ───────────────────────────────────────────────
  try {
    const portalRes = await fetch(
      "https://api.stripe.com/v1/billing_portal/sessions",
      {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${STRIPE_SECRET_KEY}`,
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: new URLSearchParams({
          customer: customerId!,
          return_url: `${APP_URL}/team/billing`,
        }),
        signal: AbortSignal.timeout(STRIPE_FETCH_TIMEOUT_MS),
      },
    );
    const session = await portalRes.json();
    if (session.error) {
      console.error("[org-billing-portal] portal error:", session.error.code);
      return jsonError("Failed to open billing portal", 400, {
        reason: "portal_failed",
      });
    }

    await writeOrgAudit(supabase, {
      org_id: ctx.org_id,
      actor_user_id: ctx.user_id,
      action: "billing_portal_opened",
      req,
    });

    return jsonOk({ url: session.url });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "unknown";
    console.error("[org-billing-portal] failed:", msg.slice(0, 200));
    return jsonError("Internal error", 500);
  }
});
