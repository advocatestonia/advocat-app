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
 * Sliding-window rate limiter, per bucket + per principal (user ID or IP).
 * O(1) per call — stores `{ count, windowStart }` per key, resets on window
 * expiry. State is in-process memory, so each Edge Function cold-start
 * starts empty; that is acceptable for our abuse-prevention use case
 * (cold-starts are rare compared to the rate-limit window).
 */
const rateLimits = new Map<string, { count: number; windowStart: number }>();
const WINDOW_MS = 60_000;

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
      const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
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
  const clientIp = req.headers.get("x-forwarded-for") || "unknown";
  const principal = userId ?? `ip:${clientIp}`;
  const limit = userId ? opts.maxPerMinute : (opts.anonymousPerMinute ?? 0);
  const key = `${opts.bucket}:${principal}`;

  const now = Date.now();
  const bucket = rateLimits.get(key);
  if (bucket) {
    if (now - bucket.windowStart < WINDOW_MS) {
      if (bucket.count >= limit) {
        return {
          kind: "deny",
          response: jsonError(
            "Rate limit exceeded. Try again in a minute.",
            429,
            { bucket: opts.bucket, limit, windowMs: WINDOW_MS },
          ),
        };
      }
      bucket.count++;
    } else {
      bucket.count = 1;
      bucket.windowStart = now;
    }
  } else {
    rateLimits.set(key, { count: 1, windowStart: now });
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

/** Helper for tests: wipe the in-process counters. */
export function __resetRateLimitForTest() {
  rateLimits.clear();
}
