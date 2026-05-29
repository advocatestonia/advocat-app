// =============================================================================
// _shared/rate_limit.ts
// =============================================================================
// P3 anti-abuse (Bentley batch, 2026-05-15)
//
// DB-backed sliding-window rate limiter via the `hit_rate_limit` RPC defined
// in migration 20260515220031_anti_abuse_protection.sql.
//
// Why not just trust the in-process Map in _shared/auth.ts?
//   • Each Edge Function cold-start has its own Map — an attacker who burns
//     enough cold starts can bypass the in-process counter.
//   • The DB-backed counter is authoritative across cold starts, regions,
//     and replicas. The in-process Map is still a fast first line of
//     defence for the common case (warm function, single replica).
//
// Pattern: call `checkAndRecordRateLimit({...})` from any sensitive edge fn.
// If it returns `{ allowed: false }`, immediately return a 429 to the client.
// If it returns `{ allowed: true }`, proceed with the request.
//
// The RPC is best-effort: if the DB is unreachable, we FAIL OPEN (log warn,
// allow the request). The in-process Map in auth.ts is the safety net.
// =============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

export interface RateLimitOptions {
  /** Logical bucket name (isolates counters between endpoints). */
  bucket: string;
  /** Principal: user UUID for authenticated, `ip:1.2.3.4` for anon. */
  principal: string;
  /** Hard cap per 60-second sliding window. */
  maxPerMinute: number;
}

export interface RateLimitResult {
  /** Whether the request was accepted. False ⇒ caller must 429. */
  allowed: boolean;
  /** Current count in the rolling window AFTER this call. */
  count: number;
  /** Window size in ms (always 60000 for now). */
  windowMs: number;
  /** True if the DB layer was unreachable; the caller may want to log. */
  degraded: boolean;
}

// See spend_tracker.ts for rationale: don't cache, the generic schema
// parameter on `ReturnType<typeof createClient>` makes `.rpc()` reject
// typed argument bags.  Per-call construction is cheap.
function client() {
  // persistSession/autoRefreshToken OFF: service-role client with no user
  // session — token auto-refresh is pointless and its uncleared setInterval
  // trips Deno's leak sanitizer in batch test runs. See spend_tracker.ts.
  return createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

/**
 * Check the DB-backed rate limit and atomically record the hit when allowed.
 * Fails OPEN on DB errors (returns allowed=true, degraded=true) so a flaky
 * Postgres connection never takes down chat.
 */
export async function checkAndRecordRateLimit(
  opts: RateLimitOptions,
): Promise<RateLimitResult> {
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    // Not running under Supabase — defer to caller's in-process limiter.
    return { allowed: true, count: 0, windowMs: 60_000, degraded: true };
  }
  try {
    const { data, error } = await client().rpc("hit_rate_limit", {
      p_bucket: opts.bucket,
      p_principal: opts.principal,
      p_max_per_minute: opts.maxPerMinute,
    });
    if (error) {
      console.warn(
        `rate_limit: hit_rate_limit RPC failed (${error.code ?? "?"}): ${error.message}`,
      );
      return { allowed: true, count: 0, windowMs: 60_000, degraded: true };
    }
    // RPC returns a SETOF of one row.
    const row = Array.isArray(data) ? data[0] : data;
    if (!row || typeof row !== "object") {
      return { allowed: true, count: 0, windowMs: 60_000, degraded: true };
    }
    return {
      allowed: Boolean((row as { allowed: boolean }).allowed),
      count: Number((row as { current_count: number }).current_count ?? 0),
      windowMs: Number((row as { window_ms: number }).window_ms ?? 60_000),
      degraded: false,
    };
  } catch (e) {
    console.warn(`rate_limit: RPC threw: ${String(e).slice(0, 200)}`);
    return { allowed: true, count: 0, windowMs: 60_000, degraded: true };
  }
}

/**
 * Best-effort GC.  Call from a low-frequency code path (e.g. once per ~1000
 * requests) — the RPC trims rows older than 1 hour.  Never throws.
 */
export async function pruneRateLimitEvents(): Promise<number> {
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) return 0;
  try {
    const { data, error } = await client().rpc("prune_rate_limit_events");
    if (error) {
      console.warn(`rate_limit: prune RPC failed: ${error.message}`);
      return 0;
    }
    return Number(data ?? 0);
  } catch (e) {
    console.warn(`rate_limit: prune threw: ${String(e).slice(0, 200)}`);
    return 0;
  }
}
