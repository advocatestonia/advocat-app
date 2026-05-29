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

// -----------------------------------------------------------------------------
// Emergency in-process backstop (Wave-2 fix W2-01, audit P1-07)
// -----------------------------------------------------------------------------
// The Postgres `consume_rate_limit` RPC is the PRIMARY rate-limit defence and
// is the only one that coordinates across the N Deno isolates Supabase runs
// behind a load balancer. When the RPC errors (network blip, pgbouncer
// saturation, schema drift), we used to fail OPEN — log a warning and admit
// the request — on the theory that 500ing every paying user during a Postgres
// outage was worse than admitting a burst. The audit (2026-05-28 P1-07)
// pointed out this is exploitable: an attacker who can independently exhaust
// the Postgres pool (e.g. via heavy unauthenticated `landmark-search` reads
// against the same pgbouncer) can force every rate-limiter into fail-open
// mode and then burst `claude-proxy` until Anthropic's account-level cap
// fires.
//
// The backstop is a per-isolate Map-based token bucket that activates ONLY
// when the RPC fails. It is intentionally NOT the primary limiter:
//
//   - LIMITATION: A cold-start farm bypasses it. Supabase scales isolates
//     dynamically; under sustained traffic an attacker may hit N fresh
//     isolates and get N × backstopCap admissions before reuse. This is
//     acceptable because the backstop is degraded-mode-only — once the RPC
//     recovers, the per-principal cap snaps back to the documented value.
//
//   - The backstop sits in front of the same response surface as the normal
//     limiter, so denials still return 429 with the right metadata.
//
//   - The `X-RateLimit-Degraded: 1` header on allow/deny lets ops dashboards
//     count how often we drop into emergency mode (alert if non-zero for
//     more than a couple of minutes — that means the RPC layer is sick).
//
// Caps (hardcoded so they cannot be disabled by env-var attack surface):
//   - 100 admissions / 60s / principal for authenticated users (10x the
//     typical per-fn cap; tolerates a brief Postgres blip without paging).
//   - 10 admissions / 60s / principal for anonymous users (matches the
//     conservative anon envelope across billable fns).
// -----------------------------------------------------------------------------

const EMERGENCY_AUTHED_CAP = 100;
const EMERGENCY_ANON_CAP = 10;

interface EmergencyBucketEntry {
  count: number;
  resetAt: number;
}

const _emergencyBucket = new Map<string, EmergencyBucketEntry>();

/**
 * Per-isolate token bucket used only when the Postgres RPC fails. Returns
 * TRUE if admitted under the degraded-mode cap, FALSE if the principal has
 * already hit the cap within the current 60s window.
 *
 * Exported for test access only.
 */
export function _emergencyAllow(key: string, max: number): boolean {
  const now = Date.now();
  const cur = _emergencyBucket.get(key);
  if (!cur || now >= cur.resetAt) {
    _emergencyBucket.set(key, { count: 1, resetAt: now + WINDOW_MS });
    return true;
  }
  if (cur.count >= max) return false;
  cur.count++;
  return true;
}

/** Test-only: wipe the emergency bucket between tests. */
export function _resetEmergencyBucketForTest() {
  _emergencyBucket.clear();
}

/**
 * Test-only RPC injector. When set, `checkRateLimit` calls this instead of
 * the real Supabase RPC. Returning a `throws` value or `{ error: ... }`
 * exercises the emergency-backstop branch in tests.
 */
let _rpcOverrideForTest:
  | ((identifier: string, maxPerMinute: number) =>
      Promise<{ data?: boolean; error?: { message: string } } | never>)
  | null = null;

export function __setRpcOverrideForTest(
  fn:
    | ((identifier: string, maxPerMinute: number) =>
        Promise<{ data?: boolean; error?: { message: string } } | never>)
    | null,
) {
  _rpcOverrideForTest = fn;
}

/** Result of the rate-limit check, including whether we fell through to the backstop. */
export interface RateLimitCheckResult {
  admitted: boolean;
  /** True when the Postgres RPC failed and we fell through to `_emergencyAllow`. */
  degraded: boolean;
}

/**
 * Atomic increment-and-check against `app.rate_limit_buckets` via the
 * `consume_rate_limit` RPC. Returns admission decision plus a `degraded`
 * flag indicating whether the in-process emergency backstop kicked in.
 *
 * When the RPC errors (returns `{ error }` or throws), the gate falls
 * through to `_emergencyAllow`, applying a hardcoded backstop cap. See the
 * Emergency backstop block above for the threat model and cap rationale.
 *
 * Exported so individual fns can probe rate-limit state without going
 * through the full `requireUserWithRateLimit` gate.
 */
export async function checkRateLimit(
  identifier: string,
  maxPerMinute: number,
  opts: { emergencyCap?: number } = {},
): Promise<RateLimitCheckResult> {
  const backstopCap = opts.emergencyCap ?? EMERGENCY_AUTHED_CAP;
  try {
    const rpcCall = _rpcOverrideForTest
      ? _rpcOverrideForTest(identifier, maxPerMinute)
      // deno-lint-ignore no-explicit-any
      : (sbClient().rpc as any)("consume_rate_limit", {
        p_bucket_key: identifier,
        p_max_per_minute: maxPerMinute,
      });
    const { data, error } = await rpcCall;
    if (error) {
      // RPC reachable but returned an error — fall through to backstop.
      // We cannot rely on the RPC-backed `log_incident` table either (it
      // sits on the same DB), so emit to stderr only.
      console.error(
        `[auth] consume_rate_limit RPC error — falling through to ` +
          `in-process backstop (cap=${backstopCap}/min): ${error.message}`,
      );
      return {
        admitted: _emergencyAllow(identifier, backstopCap),
        degraded: true,
      };
    }
    // RPC returns boolean (true=admitted, false=denied)
    return { admitted: data === true, degraded: false };
  } catch (e) {
    // RPC unreachable (network, timeout, schema drift) — fall through.
    console.error(
      `[auth] consume_rate_limit threw — falling through to ` +
        `in-process backstop (cap=${backstopCap}/min): ${String(e)}`,
    );
    return {
      admitted: _emergencyAllow(identifier, backstopCap),
      degraded: true,
    };
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
  | {
      kind: "allow";
      user: { id: string; email?: string };
      /**
       * True when the Postgres rate limiter was unreachable and we admitted
       * the request via the in-process emergency backstop. Callers may add
       * `X-RateLimit-Degraded: 1` to their final Response for observability.
       */
      degraded?: boolean;
    }
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

  // Rate limit — IP resolver.
  //
  // SECURITY REGRESSION CLASS (Wave-1 fix 2026-05-28, audit P0-06):
  // The previous implementation read the LEFTMOST entry of `x-forwarded-for`
  // as the "real client IP". x-forwarded-for is a comma-separated chain
  // (`client, proxy1, proxy2, …`) supplied by intermediaries — but the
  // LEFTMOST entry is *client-controlled*. Any attacker could set
  // `x-forwarded-for: 1.2.3.<random>` and get a fresh rate-limit bucket on
  // every request, defeating the anon limiter entirely (audit exploit:
  // 10,000 anon claude-proxy calls/day from a single host by rotating XFF).
  //
  // The same primitive surfaced as the `anon_jwt_bypass` regression in
  // f8f6a58 (see lesson_anon_jwt_bypass.md): trusting client-supplied auth
  // material without an explicit allowlist. We close it the same way —
  // refuse to trust client headers in production unless TRUST_XFF=true is
  // set in env (for deployments fronted by a trusted reverse proxy that
  // strips client-set XFF on ingress).
  //
  // Canonical source on Supabase Edge is `x-real-ip`, which is set by the
  // deno-relay infrastructure and is NOT echoable by the caller. Read
  // that first; only fall back to XFF (leftmost) when TRUST_XFF=true.
  const TRUST_XFF = (Deno.env.get("TRUST_XFF") ?? "false") === "true";
  const realIp = req.headers.get("x-real-ip");
  const cfip = TRUST_XFF ? req.headers.get("cf-connecting-ip") : null;
  const xff = TRUST_XFF ? (req.headers.get("x-forwarded-for") ?? "") : "";
  const clientIp = (realIp && realIp.trim()) ||
    (cfip && cfip.trim()) ||
    (xff ? xff.split(",")[0]?.trim() : "") ||
    "unknown";
  const principal = userId ?? `ip:${clientIp}`;
  const limit = userId ? opts.maxPerMinute : (opts.anonymousPerMinute ?? 0);
  const key = rateLimitKey(principal, opts.bucket);
  // Tighter backstop for anon — 10/min/principal — so that a degraded-mode
  // burst from a single forged-IP attacker cannot still wipe out the
  // Anthropic budget while the RPC layer recovers.
  const emergencyCap = userId ? EMERGENCY_AUTHED_CAP : EMERGENCY_ANON_CAP;

  const { admitted, degraded } = await _gateCheckRateLimit(
    key,
    limit,
    { emergencyCap },
  );
  if (!admitted) {
    // Build the deny response. If we landed here via the backstop,
    // surface the degraded flag in the response so ops can dashboard it.
    const denyHeaders: Record<string, string> = {
      ...corsHeaders,
      "Content-Type": "application/json",
    };
    if (degraded) denyHeaders["X-RateLimit-Degraded"] = "1";
    return {
      kind: "deny",
      response: new Response(
        JSON.stringify({
          error: "Rate limit exceeded. Try again in a minute.",
          bucket: opts.bucket,
          limit,
          windowMs: WINDOW_MS,
          ...(degraded ? { degraded: true } : {}),
        }),
        { status: 429, headers: denyHeaders },
      ),
    };
  }

  if (!userId) {
    // Anonymous user was permitted by config — return a synthetic principal.
    return {
      kind: "allow",
      user: { id: `anon:${clientIp}` },
      degraded,
    };
  }

  return {
    kind: "allow",
    user: { id: userId, email: userEmail },
    degraded,
  };
}

/**
 * Test-only override of the rate-limit transport. Allows unit tests to
 * stub the postgres RPC without spinning a real DB. When set to null
 * (the default), the gate calls the real `consume_rate_limit` RPC.
 *
 * The override bypasses the emergency-backstop branch — use it to model
 * normal (non-degraded) traffic. To test the backstop itself, use
 * `__setRpcOverrideForTest` instead, which simulates an RPC error and
 * lets `checkRateLimit` fall through to `_emergencyAllow`.
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
 * `checkRateLimit` itself stays the public surface for external probes.
 *
 * Returns the same `{ admitted, degraded }` shape as `checkRateLimit` so
 * the gate can propagate the degraded flag to its caller. When the legacy
 * gate-level override is installed, `degraded` is always false (the
 * override models a healthy DB).
 */
async function _gateCheckRateLimit(
  identifier: string,
  maxPerMinute: number,
  opts: { emergencyCap?: number } = {},
): Promise<RateLimitCheckResult> {
  if (_rateLimitOverride) {
    const admitted = await _rateLimitOverride(identifier, maxPerMinute);
    return { admitted, degraded: false };
  }
  return checkRateLimit(identifier, maxPerMinute, opts);
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
