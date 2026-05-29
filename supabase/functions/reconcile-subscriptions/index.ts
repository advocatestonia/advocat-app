// reconcile-subscriptions
// -----------------------------------------------------------------------------
// Sprint 0 — daily safety-net for the payment activation bug.
//
// Problem: stripe-webhook had a hole. A user paid, Stripe charged them, but the
// `checkout.session.completed` event didn't activate Pro in our DB. The user was
// stuck on free for hours until manually fixed.
//
// Fix: even after the webhook is hardened, we run this reconciler daily.
// It treats Stripe as the source of truth for "who is paying" and repairs
// any drift in `profiles` / `subscriptions` within 24h, automatically.
//
// Idempotent: running twice in a row is a no-op (each iteration reads current
// state and only writes if drift is detected).
//
// Auth: same `x-cron-secret` header as deadline-reminder.
//
// Schedule: invoked daily by the scheduled remote agent
// `trig_01EiXPDgMD8NnXaxWSuzfDBt` (daily prod smoke). See REPORT below for the
// scheduling decision rationale.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { checkCronSecret } from "./auth_gate.ts";
import {
  listSubscriptionsByStatus,
  resolveCustomer,
} from "./stripe_client.ts";
import {
  decideForActiveSub,
  decideForCanceledSub,
  type DriftAction,
  formatFixLog,
  matchProfile,
  type ProfileRow,
  type StripeCustomer,
  type StripeSubscription,
  type SubscriptionRow,
  tierFromSub,
} from "./reconcile_logic.ts";

const responseHeaders = { "Content-Type": "application/json" };

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204 });
  }
  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      { status: 405, headers: responseHeaders },
    );
  }

  const gate = checkCronSecret(
    req.headers.get("x-cron-secret"),
    Deno.env.get("CRON_SECRET"),
  );
  if (gate.kind === "deny") {
    return new Response(
      JSON.stringify(gate.body),
      { status: gate.status, headers: responseHeaders },
    );
  }

  const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY");
  const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
  const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!STRIPE_SECRET_KEY || !SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    return new Response(
      JSON.stringify({ error: "Server not configured" }),
      { status: 500, headers: responseHeaders },
    );
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  const errors: string[] = [];
  let checked = 0;
  let fixed = 0;

  try {
    // 1. Fetch ALL relevant Stripe subscriptions (paying + likely-cancelled).
    //    We pull active+trialing for "should be Pro", and canceled+past_due+
    //    unpaid for the conservative downgrade pass.
    const [active, trialing, canceled, pastDue, unpaid] = await Promise.all([
      listSubscriptionsByStatus("active", { apiKey: STRIPE_SECRET_KEY }),
      listSubscriptionsByStatus("trialing", { apiKey: STRIPE_SECRET_KEY }),
      listSubscriptionsByStatus("canceled", { apiKey: STRIPE_SECRET_KEY }),
      listSubscriptionsByStatus("past_due", { apiKey: STRIPE_SECRET_KEY }),
      listSubscriptionsByStatus("unpaid", { apiKey: STRIPE_SECRET_KEY }),
    ]);

    const allSubs = [...active, ...trialing, ...canceled, ...pastDue, ...unpaid];
    checked = allSubs.length;

    // 2. Pre-fetch the candidate profile rows in one shot. We pull the slim
    //    set of columns we need, and rely on local matching rather than a
    //    per-sub round-trip. This keeps the function under the Edge Function
    //    timeout even with hundreds of subs.
    //
    // Wave 1 fix P0-RC5 (2026-05-28): the `emails` lookup branch was
    // REMOVED — matchProfile no longer falls back to email match (free-Pro
    // exploit if a paying Stripe customer's email matched a B2C profile
    // by coincidence). Only stripe_customer_id and metadata.user_id are
    // canonical. Unmatched customers get logged to reconcile_unmatched.
    const customerIds = new Set<string>();
    const userIds = new Set<string>();
    for (const sub of allSubs) {
      const cRef = sub.customer;
      if (typeof cRef === "string") {
        customerIds.add(cRef);
      } else if (cRef && typeof cRef === "object") {
        if (cRef.id) customerIds.add(cRef.id);
        if (cRef.metadata?.user_id) userIds.add(cRef.metadata.user_id);
      }
      if (sub.metadata?.user_id) userIds.add(sub.metadata.user_id);
    }

    // OR-fetch profiles matching either canonical lookup key.
    const profileMap = new Map<string, ProfileRow>();
    if (customerIds.size > 0 || userIds.size > 0) {
      // Two queries; UNIONing in SQL is not exposed via supabase-js.
      // Each builder is a thenable, so awaiting it is the documented pattern.
      const PROFILE_COLS =
        "id,email,is_pro,subscription_tier,subscription_expires_at,stripe_customer_id";
      const queries: Array<
        PromiseLike<{ data: ProfileRow[] | null; error: unknown }>
      > = [];
      if (customerIds.size > 0) {
        queries.push(
          supabase.from("profiles").select(PROFILE_COLS).in(
            "stripe_customer_id",
            Array.from(customerIds),
          ) as unknown as PromiseLike<
            { data: ProfileRow[] | null; error: unknown }
          >,
        );
      }
      if (userIds.size > 0) {
        queries.push(
          supabase.from("profiles").select(PROFILE_COLS).in(
            "id",
            Array.from(userIds),
          ) as unknown as PromiseLike<
            { data: ProfileRow[] | null; error: unknown }
          >,
        );
      }
      const results = await Promise.all(queries);
      for (const r of results) {
        for (const row of r.data ?? []) {
          profileMap.set(row.id, row);
        }
      }
    }
    const allProfiles = Array.from(profileMap.values());

    // Pre-fetch existing subscriptions rows for the matched profiles.
    const subsRowMap = new Map<string, SubscriptionRow>();
    if (allProfiles.length > 0) {
      const { data: subRows } = await supabase
        .from("subscriptions")
        .select(
          "user_id,status,tier,current_period_end,stripe_subscription_id",
        )
        .in("user_id", allProfiles.map((p) => p.id));
      for (const row of subRows ?? []) {
        subsRowMap.set(row.user_id, row);
      }
    }

    const nowMs = Date.now();
    const actions: DriftAction[] = [];

    // 3. Decide what to do for each Stripe subscription.
    for (const sub of allSubs) {
      let customer: StripeCustomer;
      try {
        customer = await resolveCustomer(sub.customer, {
          apiKey: STRIPE_SECRET_KEY,
        });
      } catch (e) {
        errors.push(`resolveCustomer failed: sub=${sub.id}`);
        continue;
      }

      const matched = matchProfile(sub, customer, allProfiles);

      // Orphan: paying customer in Stripe, no profile in our DB. We can't
      // fix this from here (no auth user to link to) but we LOG so the
      // ops dashboard can flag it. Don't fail the whole run — log only.
      //
      // Wave 1 fix P0-RC5 (2026-05-28): we now also INSERT into
      // reconcile_unmatched so ops can triage from Supabase Studio without
      // grepping logs. Previously, the email-fallback in matchProfile would
      // silently grant Pro to whoever's email happened to match (free-Pro
      // exploit). With email match removed, every unmatched customer surfaces
      // here for human review.
      if (!matched) {
        const reason = `no profile for stripe sub status=${sub.status}`;
        const action: DriftAction = {
          kind: "orphan",
          stripe_sub_id: sub.id,
          customer_id: customer.id,
          customer_email: null, // never log emails to console — see FIX-6
          reason,
        };
        actions.push(action);
        console.warn(formatFixLog(action));
        // Persist for ops triage. Best-effort: failure here must not abort
        // the whole reconcile run.
        try {
          await supabase.from("reconcile_unmatched").insert({
            stripe_subscription_id: sub.id,
            stripe_customer_id: customer.id,
            // We store the email here because the row is RLS-locked to
            // service-role and the ops human needs it to reconcile.
            customer_email: customer.email ?? null,
            stripe_status: sub.status,
            metadata_user_id: sub.metadata?.user_id ??
              customer.metadata?.user_id ?? null,
            reason,
          });
        } catch (insertErr) {
          const m = insertErr instanceof Error
            ? insertErr.message
            : String(insertErr);
          errors.push(
            `reconcile_unmatched insert failed: ${m.slice(0, 120)}`,
          );
        }
        continue;
      }

      const profile = matched.profile;
      const subRow = subsRowMap.get(profile.id) ?? null;

      let action: DriftAction;
      if (sub.status === "active" || sub.status === "trialing") {
        action = decideForActiveSub(
          sub,
          customer.id,
          profile,
          subRow,
          nowMs,
        );
      } else if (
        sub.status === "canceled" ||
        sub.status === "past_due" ||
        sub.status === "unpaid"
      ) {
        action = decideForCanceledSub(sub, customer.id, profile, nowMs);
      } else {
        action = {
          kind: "noop",
          user_id: profile.id,
          stripe_sub_id: sub.id,
          reason: `stripe.status=${sub.status} not actionable`,
        };
      }
      actions.push(action);
    }

    // 4. Apply drift fixes. We run them sequentially to keep error messages
    //    attributable; per-sub volume is small (hundreds, not millions).
    for (const action of actions) {
      if (action.kind === "upgrade") {
        try {
          await supabase.from("profiles").upsert({
            id: action.user_id,
            subscription_tier: action.tier,
            subscription_expires_at: action.expires_at,
            stripe_customer_id: action.customer_id,
            is_pro: true,
          }, { onConflict: "id" });
          await supabase.from("subscriptions").upsert({
            user_id: action.user_id,
            status: "active",
            tier: action.tier,
            current_period_end: action.expires_at,
            stripe_subscription_id: action.stripe_sub_id,
            updated_at: new Date().toISOString(),
          }, { onConflict: "user_id" });
          console.log(formatFixLog(action));
          fixed++;
        } catch (_e) {
          errors.push(`upgrade failed: user=${action.user_id}`);
        }
      } else if (action.kind === "downgrade") {
        try {
          await supabase.from("profiles").update({
            subscription_tier: "free",
            subscription_expires_at: null,
            is_pro: false,
          }).eq("id", action.user_id);
          await supabase.from("subscriptions").update({
            status: "canceled",
            updated_at: new Date().toISOString(),
          }).eq("user_id", action.user_id);
          console.log(formatFixLog(action));
          fixed++;
        } catch (_e) {
          errors.push(`downgrade failed: user=${action.user_id}`);
        }
      }
      // noop / orphan: nothing to do (orphan already logged)
    }

    return new Response(
      JSON.stringify({ checked, fixed, errors }),
      { headers: responseHeaders },
    );
  } catch (_error) {
    // Never echo error details — they often contain PII (emails, IDs).
    return new Response(
      JSON.stringify({
        checked,
        fixed,
        errors: [...errors, "Internal error"],
      }),
      { status: 500, headers: responseHeaders },
    );
  }
});

// Re-export for convenience (the test file imports the pure helpers from
// reconcile_logic.ts directly; this is just to keep the module surface
// discoverable from index.ts).
export { tierFromSub };
