// =============================================================================
// tier_resolver.ts — server-side plan-tier lookup for the model router.
// =============================================================================
//
// Wave-1 fix (2026-06-11). The signal-based router (model_router.ts) keyed
// `RoutingSignals.userTier` off `body.user_tier` — but no client ever sends
// that field, so EVERY authenticated user routed as "free" and paying users
// never hit the pro-tier rules (`pro_with_chunks`). Worse, the field was
// client-controlled: a forged body could claim "pro".
//
// This module resolves the tier SERVER-SIDE from the same source of truth
// check-ai-quota uses (`detectPlan`, check-ai-quota/index.ts):
//
//   1. public.subscriptions — row with status in ('active','trialing') and
//      a non-lapsed current_period_end. `tier` column carries the Stripe
//      plan: "premium" (Representation/Pro) or "basic" (Counsel) — see
//      stripe-webhook/subscription_router.ts PLAN_MAPPING.
//   2. public.profiles — `is_pro` / `subscription_tier` fallback (Apple IAP
//      and legacy rows have no subscriptions entry).
//   3. Anything else (including lookup errors / timeout) → "free".
//
// Fail direction: "free" — this feeds ROUTING ONLY (which model answers),
// never billing/quota, so a degraded DB must not block chat nor grant the
// expensive model to everyone. Errors are logged loudly for ops.
//
// Uses raw PostgREST + the service-role key — same pattern as the other
// service-role reads in claude-proxy/index.ts (error_log, halt-rail).
// Resolved once per request at the routing site; no cross-request cache.
// =============================================================================

export type UserTier = "free" | "counsel" | "pro";

/** Hard cap on tier-lookup latency. Exceeding it = "free" fallback. */
export const TIER_LOOKUP_TIMEOUT_MS = 2500;

/** Map a `subscriptions.tier` / `profiles.subscription_tier` value to a
 *  RoutingSignals tier. Stripe-webhook writes "basic" (Counsel plan) or
 *  "premium" (Representation plan); unknown paid values map to "counsel"
 *  (the cheaper paid tier — routing rules treat both paid tiers alike). */
export function mapSubscriptionTier(raw: unknown): UserTier {
  const t = String(raw ?? "")
    .toLowerCase()
    .trim();
  if (t === "premium" || t === "pro" || t === "representation") return "pro";
  return "counsel";
}

interface SubscriptionRow {
  status?: string | null;
  tier?: string | null;
  current_period_end?: string | null;
}

interface ProfileRow {
  is_pro?: boolean | null;
  subscription_tier?: string | null;
}

export interface ResolveUserTierOptions {
  supabaseUrl: string;
  serviceRoleKey: string;
  userId: string;
  /** Override the fetch impl (used by tests). Defaults to globalThis.fetch. */
  fetchImpl?: typeof fetch;
  /** Override the timeout. Defaults to TIER_LOOKUP_TIMEOUT_MS. */
  timeoutMs?: number;
}

/** One PostgREST GET with the service-role key. Returns the parsed JSON
 *  array or null on any failure (caller decides the fallback). */
async function restGet(
  opts: ResolveUserTierOptions,
  pathAndQuery: string,
  signal: AbortSignal,
): Promise<unknown[] | null> {
  const fetchImpl = opts.fetchImpl ?? globalThis.fetch;
  const resp = await fetchImpl(`${opts.supabaseUrl}/rest/v1/${pathAndQuery}`, {
    method: "GET",
    headers: {
      apikey: opts.serviceRoleKey,
      Authorization: `Bearer ${opts.serviceRoleKey}`,
      Accept: "application/json",
    },
    signal,
  });
  if (!resp.ok) {
    console.warn(
      `tier_resolver: PostgREST ${resp.status} on ${
        pathAndQuery.split("?")[0]
      }`,
    );
    return null;
  }
  const json = await resp.json();
  return Array.isArray(json) ? json : null;
}

/** Resolve the caller's plan tier from subscriptions/profiles.
 *
 *  NEVER throws — any failure (network, timeout, malformed rows) resolves
 *  to "free" with a loud log line. Client-supplied tier claims must NOT be
 *  fed into this; the caller passes only the authenticated user id. */
export async function resolveUserTier(
  opts: ResolveUserTierOptions,
): Promise<UserTier> {
  if (!opts.supabaseUrl || !opts.serviceRoleKey || !opts.userId) {
    return "free";
  }
  const controller = new AbortController();
  const timer = setTimeout(
    () => controller.abort(),
    opts.timeoutMs ?? TIER_LOOKUP_TIMEOUT_MS,
  );
  try {
    const uid = encodeURIComponent(opts.userId);

    // 1. Active/trialing subscription with a non-lapsed period. Expiry
    //    guard mirrors check-ai-quota detectPlan: a stale 'active' row whose
    //    current_period_end passed (no cancel webhook arrived) is NOT paid.
    const subs = await restGet(
      opts,
      `subscriptions?user_id=eq.${uid}` +
        `&status=in.(active,trialing)` +
        `&select=status,tier,current_period_end` +
        `&order=current_period_end.desc.nullslast&limit=1`,
      controller.signal,
    );
    const sub = (subs?.[0] ?? null) as SubscriptionRow | null;
    if (sub) {
      const periodEnd = sub.current_period_end;
      if (!periodEnd || new Date(periodEnd).getTime() >= Date.now()) {
        return mapSubscriptionTier(sub.tier);
      }
      // lapsed — fall through to profiles.
    }

    // 2. Profiles fallback (Apple IAP / legacy rows).
    const profs = await restGet(
      opts,
      `profiles?id=eq.${uid}&select=is_pro,subscription_tier&limit=1`,
      controller.signal,
    );
    const prof = (profs?.[0] ?? null) as ProfileRow | null;
    if (prof?.is_pro === true) {
      return prof.subscription_tier
        ? mapSubscriptionTier(prof.subscription_tier)
        : "pro";
    }

    return "free";
  } catch (e) {
    console.warn(
      `tier_resolver: lookup failed, defaulting to free: ${
        String(e).slice(
          0,
          200,
        )
      }`,
    );
    return "free";
  } finally {
    clearTimeout(timer);
  }
}
