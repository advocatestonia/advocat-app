// =============================================================================
// Supabase Edge Function: check-ai-quota (P0-3)
// =============================================================================
//
// Two modes, controlled by `action` in the POST body:
//
//   action = "check"      — read-only; returns remaining/limit/plan.
//   action = "consume"    — atomically increments the user's counter and
//                           returns the post-increment state.
//
// Response shape:
//   {
//     allowed: bool,        // true if the user may send another message
//     remaining: number,    // messages left this month (Infinity for pro)
//     limit: number,        // monthly limit (7 for free, -1 for pro)
//     plan: "free" | "pro",
//     used: number,
//     resetAt: string       // ISO timestamp of next month boundary
//   }
//
// Plan detection:
//   A user is "pro" when a row exists in `public.subscriptions` with
//   status in ('active','trialing') for their uid. Falls back to "free".
//
// Auth:
//   Requires an Authorization: Bearer <jwt> header. We read the JWT via
//   the user-scoped Supabase client (anon key + auth header), not the
//   service-role key, so the request context carries `auth.uid()` for the
//   SECURITY DEFINER RPCs.
// =============================================================================

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.8";

const corsHeaders = {
  "Access-Control-Allow-Origin": "https://advocat.ee",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "Authorization, Content-Type, apikey, x-client-info",
};

// Free tier monthly quota (conversion lever, Bentley P8 2026-05-16).
// Bumped 7 → 10 to give users more room to hit "aha" before paywall —
// avg conversation = 8 messages, so 7 was cutting them off mid-train.
// NOTE: the launch pricing REFUND policy (14 days OR 7 AI responses) is a
// separate ceiling in supabase/functions/_shared/refund_policy.ts and is
// intentionally NOT bumped — refund eligibility is a legal/financial
// promise to paying users and stays at 7.
const FREE_LIMIT = 10;

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return json({ error: "missing Authorization header" }, 401);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    if (!supabaseUrl || !anonKey) {
      return json({ error: "supabase env not configured" }, 500);
    }

    // Important: create a *per-request* client that forwards the caller's
    // JWT so that `auth.uid()` inside the SECURITY DEFINER RPCs resolves
    // to the calling user, not the service role.
    const sb = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false, autoRefreshToken: false },
    });

    // Resolve the user — we need their uid for the plan lookup.
    const { data: userData, error: userErr } = await sb.auth.getUser();
    if (userErr || !userData?.user) {
      // Demo mode: no real Supabase user, but anon key is valid.
      // Return a synthetic free-tier payload so the client doesn't block.
      // No usage is persisted; demo users effectively have a local-only counter.
      return json(buildPayload({
        plan: "free",
        used: 0,
        limit: FREE_LIMIT,
        allowed: true,
      }));
    }
    const uid = userData.user.id;

    // Determine plan by looking at subscriptions.
    const plan = await detectPlan(sb, uid);

    const body = await req.json().catch(() => ({}));
    const action = (body?.action as string | undefined) ?? "check";

    if (action === "check") {
      if (plan === "pro") {
        return json(buildPayload({
          plan,
          used: 0,
          limit: -1,
          allowed: true,
        }));
      }
      // Free — read current usage via RPC (does not mutate).
      const { data, error } = await sb.rpc("get_ai_usage");
      if (error) {
        return json({ error: error.message }, 500);
      }
      const used = (data as number) ?? 0;
      return json(buildPayload({
        plan,
        used,
        limit: FREE_LIMIT,
        allowed: used < FREE_LIMIT,
      }));
    }

    if (action === "consume") {
      if (plan === "pro") {
        // ── B2B signal: pro_quota_pressure (2026-05-26) ────────────────
        // Pro users have no enforced ceiling, but a Pro user grinding
        // >=90 messages in the last 24h is a strong "needs team plan"
        // signal. Fire-and-forget — never block the consume response.
        maybeRecordProQuotaPressure(supabaseUrl, uid).catch((e) => {
          console.warn(
            `check-ai-quota: b2b signal failed: ${String(e).slice(0, 150)}`,
          );
        });
        return json(buildPayload({
          plan,
          used: 0,
          limit: -1,
          allowed: true,
        }));
      }
      // 1. Read current state.
      const current = await sb.rpc("get_ai_usage");
      const currentCount = (current.data as number) ?? 0;
      if (current.error) {
        return json({ error: current.error.message }, 500);
      }
      if (currentCount >= FREE_LIMIT) {
        // Exhausted — do NOT increment further.
        return json(buildPayload({
          plan,
          used: currentCount,
          limit: FREE_LIMIT,
          allowed: false,
        }));
      }
      // 2. Atomic increment.
      const inc = await sb.rpc("increment_ai_usage");
      if (inc.error) {
        return json({ error: inc.error.message }, 500);
      }
      const newCount = (inc.data as number) ?? currentCount + 1;
      return json(buildPayload({
        plan,
        used: newCount,
        limit: FREE_LIMIT,
        allowed: newCount <= FREE_LIMIT,
      }));
    }

    return json({ error: `unknown action: ${action}` }, 400);
  } catch (error) {
    const msg = error instanceof Error ? error.message : "unknown";
    console.error("check-ai-quota failed:", msg.slice(0, 200));
    return json({ error: "Internal error" }, 500);
  }
});

async function detectPlan(
  sb: ReturnType<typeof createClient>,
  uid: string,
): Promise<"free" | "pro"> {
  try {
    // Two common shapes in the Advocat codebase:
    //   1. `subscriptions` table with (user_id, status)
    //   2. `profiles.is_pro` boolean
    const sub = await sb
      .from("subscriptions")
      .select("status")
      .eq("user_id", uid)
      .in("status", ["active", "trialing"])
      .limit(1)
      .maybeSingle();
    if (sub.data) return "pro";
  } catch (_) {
    // Table may not exist yet — fall through to profiles.
  }
  try {
    const prof = await sb
      .from("profiles")
      .select("is_pro")
      .eq("id", uid)
      .maybeSingle();
    if (prof.data?.is_pro === true) return "pro";
  } catch (_) {
    // ignore
  }
  return "free";
}

interface Payload {
  plan: "free" | "pro";
  used: number;
  limit: number;
  allowed: boolean;
}

function buildPayload(p: Payload): Record<string, unknown> {
  const remaining = p.limit < 0
    ? Number.POSITIVE_INFINITY
    : Math.max(0, p.limit - p.used);
  const nextReset = nextMonthStart();
  return {
    allowed: p.allowed,
    remaining: isFinite(remaining) ? remaining : null,
    unlimited: p.limit < 0,
    limit: p.limit,
    used: p.used,
    plan: p.plan,
    resetAt: nextReset.toISOString(),
  };
}

function nextMonthStart(): Date {
  const now = new Date();
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 1));
}

function json(obj: unknown, status = 200) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

// =============================================================================
// B2B lead detection — pro_quota_pressure (2026-05-26)
// =============================================================================
//
// Triggers when a Pro user has accumulated >=90 messages in the last 24h —
// a strong indicator they're a power user candidate for the team plan.
// Idempotent on the 24h window via the b2b_signals row history.
//
// This uses the service-role key for the RPC and a count-only GET against
// PostgREST for the ai_usage rollup. We pass through best-effort: any failure
// is swallowed (the consume response has already shipped to the caller).
async function maybeRecordProQuotaPressure(
  supabaseUrl: string,
  userId: string,
): Promise<void> {
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!supabaseUrl || !serviceRoleKey || !userId) return;

  const since = new Date(Date.now() - 24 * 60 * 60_000).toISOString();
  const baseHeaders = {
    "apikey": serviceRoleKey,
    "Authorization": `Bearer ${serviceRoleKey}`,
    "Content-Type": "application/json",
  };

  // Idempotency: have we already recorded the signal in the last 24h?
  try {
    const existing = await fetch(
      `${supabaseUrl}/rest/v1/b2b_signals?select=id&user_id=eq.${userId}` +
        `&signal_type=eq.pro_quota_pressure&occurred_at=gte.${
          encodeURIComponent(since)
        }&limit=1`,
      { headers: baseHeaders },
    );
    if (existing.ok) {
      const rows = await existing.json() as Array<unknown>;
      if (Array.isArray(rows) && rows.length > 0) return;
    }
  } catch (_e) {
    // best effort
  }

  // Count messages in last 24h via ai_usage.
  let count = 0;
  try {
    const countRes = await fetch(
      `${supabaseUrl}/rest/v1/ai_usage?select=id&user_id=eq.${userId}` +
        `&created_at=gte.${encodeURIComponent(since)}`,
      {
        headers: {
          ...baseHeaders,
          "Prefer": "count=exact",
          "Range-Unit": "items",
          "Range": "0-0",
        },
      },
    );
    if (countRes.ok || countRes.status === 206) {
      const cr = countRes.headers.get("content-range") ?? "";
      const m = cr.match(/\/(\d+)$/);
      if (m) count = Number(m[1]);
    }
  } catch (_e) {
    return;
  }
  if (count < 90) return;

  try {
    await fetch(`${supabaseUrl}/rest/v1/rpc/record_b2b_signal`, {
      method: "POST",
      headers: baseHeaders,
      body: JSON.stringify({
        p_user_id: userId,
        p_signal_type: "pro_quota_pressure",
        p_score: 20,
        p_payload: { source: "check-ai-quota", messages_24h: count },
      }),
    });
  } catch (_e) {
    // best effort
  }
}
