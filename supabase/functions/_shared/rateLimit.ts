// _shared/rateLimit.ts
// -----------------------------------------------------------------------------
// B2B API-key authentication + rate limiting.
//
// Recognises `Authorization: Bearer av_live_*` keys, validates them against
// the `org_api_keys` table, enforces scope, and consumes from the daily
// rate-limit bucket via the `org_api_key_consume` RPC.
//
// The RPC is expected to:
//   1. SELECT the key by sha256(key) → key_hash.
//   2. Reject if revoked, expired, or unknown.
//   3. Atomically increment today's usage counter in org_api_rate_counters.
//   4. Compare against the per-plan daily limit (passed in).
//   5. Return { ok, org_id, scopes, count_today, plan_limit, reset_at }.
//
// On 429 we return `Retry-After: <seconds-until-midnight-UTC>`.
//
// On 2xx we set:
//   X-RateLimit-Limit
//   X-RateLimit-Remaining
//   X-RateLimit-Reset (ISO timestamp)
//
// Header injection into the final Response is the caller's responsibility —
// we return the headers as part of the ApiKeyContext so the handler can
// merge them with its own JSON response.
// -----------------------------------------------------------------------------

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { jsonError } from "./auth.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

/** All valid API scopes. Centralised so `generate-api-key` and the middleware
 *  agree on the set without drift. */
export const VALID_SCOPES = [
  "cases:read",
  "cases:write",
  "documents:read",
  "documents:write",
  "deadlines:read",
  "deadlines:write",
  "ai:query",
  "members:read",
] as const;

export type ApiScope = typeof VALID_SCOPES[number];

export interface ApiKeyContext {
  org_id: string;
  scopes: ApiScope[];
  api_key_id: string;
  /** Headers to merge into the outgoing Response. */
  responseHeaders: Record<string, string>;
}

export interface RequireApiKeyOpts {
  /** Scope this endpoint requires. The key MUST include it. */
  requiredScope: ApiScope;
  /** Daily call limit derived from the org's plan tier. Caller looks this
   *  up; we don't fetch the plan inside the middleware because that would
   *  add a round-trip. */
  planLimitPerDay: number;
}

export type RequireApiKeyResult =
  | { kind: "ok"; ctx: ApiKeyContext }
  | { kind: "deny"; response: Response };

/** SHA-256 over a string; returns lowercase hex. */
async function sha256Hex(s: string): Promise<string> {
  const buf = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(s));
  return Array.from(new Uint8Array(buf))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

/** Validate an `Authorization: Bearer av_live_*` header and consume one unit
 *  of the daily rate-limit bucket. Returns either an ApiKeyContext or a
 *  ready-to-return 4xx Response. */
export async function requireApiKey(
  req: Request,
  opts: RequireApiKeyOpts,
): Promise<RequireApiKeyResult> {
  const auth = req.headers.get("Authorization") ?? "";
  if (!auth.startsWith("Bearer av_live_")) {
    return {
      kind: "deny",
      response: jsonError("API key required", 401, { reason: "missing_api_key" }),
    };
  }

  const key = auth.slice("Bearer ".length).trim();
  // Cheap shape check — full pattern is `av_live_<8 hex>_<32 hex>`.
  if (!/^av_live_[0-9a-f]{8}_[0-9a-f]{32}$/.test(key)) {
    return {
      kind: "deny",
      response: jsonError("Invalid API key format", 401, {
        reason: "invalid_api_key_format",
      }),
    };
  }

  const keyHash = await sha256Hex(key);
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // RPC enforces existence/revocation/expiry/limit atomically.
  // Expected RPC signature:
  //   org_api_key_consume(p_key_hash text, p_plan_limit int)
  //     returns table(ok bool, reason text, org_id uuid, scopes text[],
  //                   api_key_id uuid, count_today int, plan_limit int,
  //                   reset_at timestamptz)
  // deno-lint-ignore no-explicit-any
  const { data, error } = await (supabase as any).rpc("org_api_key_consume", {
    p_key_hash: keyHash,
    p_plan_limit: opts.planLimitPerDay,
  });

  if (error) {
    console.error("[rateLimit] RPC failed:", error.message);
    return {
      kind: "deny",
      response: jsonError("Rate limit backend unavailable", 503, {
        reason: "rate_limit_backend_unavailable",
      }),
    };
  }

  // The RPC returns a single row (or none if the key wasn't found, depending
  // on how it's implemented; we accept both shapes).
  const row = Array.isArray(data) ? data[0] : data;
  if (!row || row.ok === false) {
    const reason = row?.reason ?? "unknown_key";
    if (reason === "rate_limited") {
      const resetAt = row?.reset_at as string | undefined;
      const retryAfter = resetAt
        ? Math.max(1, Math.floor((new Date(resetAt).getTime() - Date.now()) / 1000))
        : 60;
      return {
        kind: "deny",
        response: new Response(
          JSON.stringify({
            error: "Rate limit exceeded",
            reason: "rate_limited",
            limit: opts.planLimitPerDay,
            reset_at: resetAt,
          }),
          {
            status: 429,
            headers: {
              "Content-Type": "application/json",
              "Retry-After": String(retryAfter),
              "X-RateLimit-Limit": String(opts.planLimitPerDay),
              "X-RateLimit-Remaining": "0",
              "X-RateLimit-Reset": resetAt ?? "",
            },
          },
        ),
      };
    }
    if (reason === "expired") {
      return {
        kind: "deny",
        response: jsonError("API key expired", 401, { reason: "expired" }),
      };
    }
    if (reason === "revoked") {
      return {
        kind: "deny",
        response: jsonError("API key revoked", 401, { reason: "revoked" }),
      };
    }
    return {
      kind: "deny",
      response: jsonError("API key invalid", 401, { reason }),
    };
  }

  const scopes = (row.scopes ?? []) as ApiScope[];
  if (!scopes.includes(opts.requiredScope)) {
    return {
      kind: "deny",
      response: jsonError("Insufficient scope", 403, {
        reason: "insufficient_scope",
        required_scope: opts.requiredScope,
      }),
    };
  }

  const remaining = Math.max(0, opts.planLimitPerDay - (row.count_today ?? 0));

  return {
    kind: "ok",
    ctx: {
      org_id: row.org_id as string,
      scopes,
      api_key_id: row.api_key_id as string,
      responseHeaders: {
        "X-RateLimit-Limit": String(opts.planLimitPerDay),
        "X-RateLimit-Remaining": String(remaining),
        "X-RateLimit-Reset": (row.reset_at as string) ?? "",
      },
    },
  };
}

/** Per-plan daily limits. Centralised so handlers and docs don't drift. */
export const PLAN_API_LIMITS: Record<string, number> = {
  starter: 0, // Starter plan has no API access (handlers should refuse).
  firm: 1000,
  enterprise: 10_000,
};
