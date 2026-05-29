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
// History: 7 → 10 (more room before paywall; avg conversation = 8 messages).
// 2026-05-29 launch: 10 → 25. A single legal matter routinely spans multiple
// back-and-forth turns (intake → clarify → draft → revise), and 10 was still
// cutting users off mid-matter before they reach the "aha" of a usable draft.
// 25 lets a real case play out end-to-end on the free tier.
// NOTE: the launch pricing REFUND policy (14 days OR 7 AI responses) is a
// separate ceiling in supabase/functions/_shared/refund_policy.ts and is
// intentionally NOT bumped — refund eligibility is a legal/financial
// promise to paying users and stays at 7.
const FREE_LIMIT = 25;

export async function handler(req: Request): Promise<Response> {
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

    // ── Wave 1 fix P0-Q4 (2026-05-28) — reject anon / demo fall-through ──
    //
    // The previous handler returned a synthetic free-tier payload (allowed:
    // true, used: 0) whenever sb.auth.getUser() failed to resolve a user.
    // That branch fired for ANY caller presenting just the public anon key
    // (or a forged/expired JWT). A scripted attacker could call check-ai-quota
    // with the anon key and always get allowed=true, then bombard claude-proxy
    // for as long as claude-proxy's own auth gate let them through.
    //
    // Defence-in-depth (mirrors _shared/auth.ts:189-201): require not only a
    // resolvable user, but `role === 'authenticated'` AND `aud === 'authenticated'`.
    // Service-role JWTs (role='service_role') and anonymous JWTs (role='anon')
    // are rejected. There is NO synthetic demo bypass — demo accounts MUST be
    // real auth.users rows. If you need to test client-side without auth,
    // mock the response in the client, not in the server.
    const { data: userData, error: userErr } = await sb.auth.getUser();
    if (userErr || !userData?.user) {
      return json({ error: "missing or invalid session" }, 401);
    }
    const u = userData.user as { id: string; role?: string; aud?: string };
    const looksAuthenticated =
      (!u.role || u.role === "authenticated") &&
      (!u.aud || u.aud === "authenticated");
    if (!looksAuthenticated) {
      return json({ error: "missing or invalid session" }, 401);
    }
    const uid = u.id;

    // Determine plan by looking at subscriptions. Wave 1 fix P0-Q4:
    // detectPlan now throws on backend error instead of silently returning
    // "free". A DB outage or RLS misconfig must NOT silently grant the free
    // tier (and the surface attack — claiming "pro" from a forged subscriptions
    // row — is closed by the role/aud check above, but we still want a loud
    // 503 if subscriptions is unavailable rather than a silent default).
    let plan: "free" | "pro";
    try {
      plan = await detectPlan(sb, uid);
    } catch (planErr) {
      const msg = planErr instanceof Error ? planErr.message : String(planErr);
      console.error(`check-ai-quota: detectPlan failed: ${msg.slice(0, 200)}`);
      return json({ error: "plan lookup unavailable" }, 503);
    }

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
        console.error("[check-ai-quota] get_ai_usage failed:", error.message);
        return json({ error: "quota check failed" }, 500);
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
        console.error("[check-ai-quota] get_ai_usage failed:", current.error.message);
        return json({ error: "quota check failed" }, 500);
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
        console.error("[check-ai-quota] increment_ai_usage failed:", inc.error.message);
        return json({ error: "quota check failed" }, 500);
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
}

// Only bind the HTTP server when run as the entrypoint. Importing this module
// from a test must NOT start a listener.
if (import.meta.main) {
  serve(handler);
}

// Exported for unit tests (see __tests__/check_ai_quota_test.ts). The serve()
// handler is an integration surface that needs a live JWT + DB, so the
// testable logic is factored into these pure/injectable helpers.
// deno-lint-ignore no-explicit-any
export async function detectPlan(
  // Widened from `ReturnType<typeof createClient>` (which generic-resolves to
  // `SupabaseClient<unknown, never, GenericSchema>`) to the call-site shape
  // `SupabaseClient<any, "public", any>` after the supabase-js@2.39 typing
  // upgrade. Body uses only string-keyed `.from()` so the schema generic is
  // irrelevant here.
  sb: any,
  uid: string,
): Promise<"free" | "pro"> {
  // Wave 1 fix P0-Q4 (2026-05-28): both lookups must complete without
  // throwing. Previously the bare `catch (_)` blocks silently mapped a DB
  // outage to "free", which is the safe direction *for free-tier capping*
  // but obscures real backend incidents. We now propagate any non-PostgREST
  // error so the caller can return a loud 503. Missing-row results (no
  // active subscription, no profile) are NOT errors — they correctly resolve
  // to "free".
  //
  // We allow `.maybeSingle()` to surface a `PGRST116` (zero rows) as
  // data=null, error=null — that's the documented contract and we keep
  // the historical behaviour of returning "free" in that case.
  const sub = await sb
    .from("subscriptions")
    .select("status, current_period_end")
    .eq("user_id", uid)
    .in("status", ["active", "trialing"])
    .limit(1)
    .maybeSingle();
  if (sub.error) {
    // PostgREST returns PGRST116 for "no rows" via maybeSingle(); anything
    // else is a real backend failure. We accept the absence-of-row case.
    const code = (sub.error as { code?: string }).code;
    if (code && code !== "PGRST116") {
      throw new Error(`subscriptions lookup: ${sub.error.message}`);
    }
  }
  if (sub.data) {
    // Expiry guard: a row can read status='active' long after the period
    // ended if no renewal/cancel/refund webhook arrived. Apple IAP in
    // particular has no server-notification handler in prod, so a cancelled
    // or refunded sub would otherwise grant Pro forever. A lapsed period is
    // treated as free regardless of the stored status.
    const periodEnd = (sub.data as { current_period_end?: string | null })
      .current_period_end;
    if (!periodEnd || new Date(periodEnd).getTime() >= Date.now()) {
      return "pro";
    }
    // else fall through to the profiles.is_pro check below.
  }

  const prof = await sb
    .from("profiles")
    .select("is_pro")
    .eq("id", uid)
    .maybeSingle();
  if (prof.error) {
    const code = (prof.error as { code?: string }).code;
    if (code && code !== "PGRST116") {
      throw new Error(`profiles lookup: ${prof.error.message}`);
    }
  }
  if (prof.data?.is_pro === true) return "pro";

  return "free";
}

export interface Payload {
  plan: "free" | "pro";
  used: number;
  limit: number;
  allowed: boolean;
}

export function buildPayload(p: Payload): Record<string, unknown> {
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
