// _shared/auth.ts
// -----------------------------------------------------------------------------
// OMEGA-5 v24.2 — JWT auth + per-user rate-limit helper for billable Edge
// Functions. Ported from the claude-proxy pattern.
//
// Usage:
//
//   import { requireUserWithRateLimit, corsHeaders, jsonError } from "../_shared/auth.ts";
//
//   serve(async (req) => {
//     if (req.method === "OPTIONS") {
//       return new Response(null, { status: 204, headers: corsHeaders });
//     }
//     const gate = await requireUserWithRateLimit(req, {
//       bucket: "whisper",
//       maxPerMinute: 10,
//     });
//     if (gate.kind === "deny") return gate.response;
//     const user = gate.user;
//     // ...handler logic
//   });
//
// -----------------------------------------------------------------------------

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

/** CORS whitelist — advocat.ee only. */
export const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "https://advocat.ee",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "Authorization, Content-Type, apikey, x-client-info",
  "Vary": "Origin",
};

/** JSON error response with standard CORS headers. */
export function jsonError(msg: string, status: number, extra: Record<string, unknown> = {}) {
  return new Response(JSON.stringify({ error: msg, ...extra }), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/** JSON ok response with standard CORS headers. */
export function jsonOk(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/**
 * Postgres-backed per-minute rate limiter. State lives in
 * `app.rate_limit_buckets` and is mutated by the SECURITY DEFINER RPC
 * `consume_rate_limit(bucket_key, max_per_minute)`. The old in-process
 * `Map` could not coordinate across the N Deno isolates Supabase runs
 * behind a load balancer, so effective rate was N × maxPerMinute. The
 * RPC takes an advisory xact lock keyed on bucket_key, so concurrent
 * isolates serialise against the same principal and the documented cap
 * holds.
 *
 * Failure mode: if the DB RPC errors (network, timeout, schema drift),
 * the gate FAILS OPEN — we'd rather admit a few extra requests than
 * 500 every paying user during a postgres outage. The cost-bound on
 * such an outage is bounded by per-tier quota tables (agent_quota,
 * voice_usage) which sit on the same DB anyway.
 *
 * Backward-compat: the legacy `WINDOW_MS = 60_000` and `__resetRateLimitForTest`
 * surface are preserved so existing callers + tests keep compiling.
 */
const WINDOW_MS = 60_000;

/**
 * Build a stable rate-limit bucket key for (function, principal).
 * Used so call-sites that need to pre-compose a key (telemetry, audit)
 * stay aligned with what the gate writes to postgres.
 */
export function rateLimitKey(principal: string, fnName: string): string {
  return `${fnName}:${principal}`;
}

/**
 * Service-role Supabase client, lazily constructed once per isolate.
 * Re-use saves ~30-50ms per call vs `createClient` on every request.
 */
let _sb: ReturnType<typeof createClient> | null = null;
function sbClient() {
  if (!_sb) {
    _sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
  }
  return _sb;
}

/**
 * Atomic increment-and-check against `app.rate_limit_buckets` via the
 * `consume_rate_limit` RPC. Returns TRUE if admitted, FALSE if at cap.
 *
 * Fails open (returns TRUE + warning log) if the RPC call itself errors.
 * Exported so individual fns can probe rate-limit state without going
 * through the full `requireUserWithRateLimit` gate.
 */
export async function checkRateLimit(
  identifier: string,
  maxPerMinute: number,
): Promise<boolean> {
  try {
    // deno-lint-ignore no-explicit-any
    const { data, error } = await (sbClient().rpc as any)("consume_rate_limit", {
      p_bucket_key: identifier,
      p_max_per_minute: maxPerMinute,
    });
    if (error) {
      console.warn(
        `[auth] consume_rate_limit RPC error — failing OPEN: ${error.message}`,
      );
      return true;
    }
    // RPC returns boolean (true=admitted, false=denied)
    return data === true;
  } catch (e) {
    console.warn(`[auth] consume_rate_limit threw — failing OPEN: ${String(e)}`);
    return true;
  }
}

export interface GateOptions {
  /** Bucket name (appears in rate-limit key; keeps function quotas isolated). */
  bucket: string;
  /** Max requests per 60-second window for authenticated users. */
  maxPerMinute: number;
  /** Optional lower cap for requests without a valid JWT. Default: 0 (reject). */
  anonymousPerMinute?: number;
}

export type GateResult =
  | { kind: "allow"; user: { id: string; email?: string } }
  | { kind: "deny"; response: Response };

/**
 * Enforces JWT auth + rate-limit. Returns either an allowed user or a
 * ready-to-return 401/429 Response. The caller does not need to know
 * about the underlying counter storage.
 */
export async function requireUserWithRateLimit(
  req: Request,
  opts: GateOptions,
): Promise<GateResult> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    // No token at all — reject unless anonymousPerMinute is set and positive.
    if ((opts.anonymousPerMinute ?? 0) <= 0) {
      return { kind: "deny", response: jsonError("Unauthorized", 401) };
    }
    // Fall through: treat as anonymous, rate-limit by IP.
  }

  let userId: string | null = null;
  let userEmail: string | undefined;

  if (authHeader) {
    try {
      const supabase = sbClient();
      const token = authHeader.replace("Bearer ", "");
      const { data, error } = await supabase.auth.getUser(token);
      if (error || !data?.user) {
        // Token is present but not a valid user session (e.g. plain anon key
        // from a demo-mode client). If the function allows anonymous traffic,
        // fall through to IP-based rate limiting instead of rejecting.
        if ((opts.anonymousPerMinute ?? 0) <= 0) {
          return {
            kind: "deny",
            response: jsonError("Invalid session", 401),
          };
        }
      } else {
        // Defence-in-depth (SECURITY 2026-05-04 U1): even when getUser
        // returns a user object, refuse anything that isn't a real
        // authenticated end-user session. The anonymous Supabase JWT
        // carries `role: "anon"` and Supabase will not return a user for
        // it (so this branch is normally unreachable for the anon key) —
        // but a forged or service-role JWT could otherwise slip through.
        // Service-role tokens carry `role: "service_role"`; user JWTs
        // always carry `role: "authenticated"` and `aud: "authenticated"`.
        const userRole = (data.user as { role?: string }).role;
        const userAud = (data.user as { aud?: string }).aud;
        const looksAuthenticated =
          (!userRole || userRole === "authenticated") &&
          (!userAud || userAud === "authenticated");
        if (!looksAuthenticated) {
          if ((opts.anonymousPerMinute ?? 0) <= 0) {
            return {
              kind: "deny",
              response: jsonError("Invalid session", 401),
            };
          }
          // Function allows anon traffic — treat as anonymous (IP-rate-limited).
        } else {
          userId = data.user.id;
          userEmail = data.user.email ?? undefined;
        }
      }
    } catch (e) {
      return {
        kind: "deny",
        response: jsonError("Auth backend error", 503, {
          details: String(e),
        }),
      };
    }
  }

  // Rate limit
  // x-forwarded-for is a comma-separated chain (`client, proxy1, proxy2`)
  // where the LAST hop rotates per request (Supabase LB IPs like
  // 13.248.100.49/.51/.53/.72/.77).  If we key the bucket on the whole
  // chain, every request gets a fresh bucket and the limiter never trips.
  // Take ONLY the leftmost entry — that's the real client IP.
  // (cf-connecting-ip is preferred when present; some deploys carry it.)
  const xff = req.headers.get("x-forwarded-for") ?? "";
  const cfip = req.headers.get("cf-connecting-ip");
  const clientIp = (cfip && cfip.trim()) ||
    xff.split(",")[0]?.trim() ||
    "unknown";
  const principal = userId ?? `ip:${clientIp}`;
  const limit = userId ? opts.maxPerMinute : (opts.anonymousPerMinute ?? 0);
  const key = rateLimitKey(principal, opts.bucket);

  const admitted = await _gateCheckRateLimit(key, limit);
  if (!admitted) {
    return {
      kind: "deny",
      response: jsonError(
        "Rate limit exceeded. Try again in a minute.",
        429,
        { bucket: opts.bucket, limit, windowMs: WINDOW_MS },
      ),
    };
  }

  if (!userId) {
    // Anonymous user was permitted by config — return a synthetic principal.
    return {
      kind: "allow",
      user: { id: `anon:${clientIp}` },
    };
  }

  return {
    kind: "allow",
    user: { id: userId, email: userEmail },
  };
}

/**
 * Test-only override of the rate-limit transport. Allows unit tests to
 * stub the postgres RPC without spinning a real DB. When set to null
 * (the default), the gate calls the real `consume_rate_limit` RPC.
 *
 * In production this MUST stay null — call-sites should never override
 * the limiter at runtime.
 */
let _rateLimitOverride:
  | ((identifier: string, maxPerMinute: number) => Promise<boolean>)
  | null = null;

/** Tests only — inject a custom rate-limit transport. Pass null to restore. */
export function __setRateLimitOverrideForTest(
  fn: ((identifier: string, maxPerMinute: number) => Promise<boolean>) | null,
) {
  _rateLimitOverride = fn;
}

/**
 * Internal: route a rate-limit check through the test override if one is
 * installed, otherwise call the real RPC. Used by requireUserWithRateLimit;
 * `checkRateLimit` itself stays a thin public RPC wrapper so external
 * call-sites get the production behaviour.
 */
async function _gateCheckRateLimit(
  identifier: string,
  maxPerMinute: number,
): Promise<boolean> {
  if (_rateLimitOverride) return _rateLimitOverride(identifier, maxPerMinute);
  return checkRateLimit(identifier, maxPerMinute);
}

/**
 * Legacy test reset — kept for backward compat with auth.test.ts. Installs
 * a fresh in-memory Map-based stub so the old test suite (which counts
 * actual admissions and expects sliding-window behaviour) keeps passing
 * without spinning up a real postgres for every assertion. Production code
 * paths still hit the real `consume_rate_limit` RPC; the override only
 * fires inside Deno test runs after this helper is called.
 */
export function __resetRateLimitForTest() {
  const stub = new Map<string, { count: number; windowStart: number }>();
  _rateLimitOverride = (identifier: string, maxPerMinute: number) => {
    const now = Date.now();
    const cur = stub.get(identifier);
    if (cur && now - cur.windowStart < WINDOW_MS) {
      if (cur.count >= maxPerMinute) return Promise.resolve(false);
      cur.count++;
    } else {
      stub.set(identifier, { count: 1, windowStart: now });
    }
    return Promise.resolve(true);
  };
}
