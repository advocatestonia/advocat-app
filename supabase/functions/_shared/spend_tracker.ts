// =============================================================================
// _shared/spend_tracker.ts
// =============================================================================
// P3 anti-abuse (Bentley batch, 2026-05-15)
//
// Soft cap on Anthropic API daily spend. Pairs with:
//   • Migration 20260515220031_anti_abuse_protection.sql
//   • RPCs: record_anthropic_spend, get_anthropic_spend_today
//
// Why "soft" cap:
//   • The Anthropic console limit is the AUTHORITATIVE hard cap (owner must
//     set this in console.anthropic.com → Billing → Spend Limits).
//   • This soft cap is a defence-in-depth: by the time the console cap
//     trips, the org is already burning at full speed. The soft cap stops
//     traffic at the proxy layer BEFORE Anthropic returns 400 credit
//     errors, giving us:
//       - Better error UX (503 "try later" vs broken chat)
//       - Spend predictability (we can pause before hitting hard cap)
//       - Observability (one row per request in anthropic_daily_spend)
//
// Defaults:
//   DAILY_CAP_CENTS       = 50000   ($500/day)
//   WARN_RATIO            = 0.85    (log warn from 85% onwards)
//   BLOCK_RATIO           = 1.00    (refuse new requests at 100%)
//
// Override via env:
//   ANTHROPIC_DAILY_CAP_CENTS  (integer, cents)
//   ANTHROPIC_WARN_RATIO       (float 0..1)
//
// Fail-open: any DB error returns "allowed=true, degraded=true" so a flaky
// Postgres connection never kills chat. Cost: a brief overshoot of the cap.
// =============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const DEFAULT_DAILY_CAP_CENTS = 50_000; // $500
const DEFAULT_ANON_DAILY_CAP_CENTS = 5_000; // $50 — anon-traffic-only sub-cap
const DEFAULT_WARN_RATIO = 0.85;

export const DAILY_CAP_CENTS = (() => {
  const raw = Deno.env.get("ANTHROPIC_DAILY_CAP_CENTS");
  if (!raw) return DEFAULT_DAILY_CAP_CENTS;
  const n = Number.parseInt(raw, 10);
  return Number.isFinite(n) && n > 0 ? n : DEFAULT_DAILY_CAP_CENTS;
})();

/**
 * Hard sub-cap on anonymous (demo) traffic spend. Defence in depth: even
 * though anon requests are clamped to ANON_MAX_TOKENS and the 3/min demo
 * limit, a sustained botnet still costs real money. This cap stops new
 * anon calls once the day's anon-attributed spend exceeds the threshold,
 * while authenticated users continue under the main $500/day cap.
 */
export const ANON_DAILY_CAP_CENTS = (() => {
  const raw = Deno.env.get("ANTHROPIC_ANON_DAILY_CAP_CENTS");
  if (!raw) return DEFAULT_ANON_DAILY_CAP_CENTS;
  const n = Number.parseInt(raw, 10);
  return Number.isFinite(n) && n > 0 ? n : DEFAULT_ANON_DAILY_CAP_CENTS;
})();

export const WARN_RATIO = (() => {
  const raw = Deno.env.get("ANTHROPIC_WARN_RATIO");
  if (!raw) return DEFAULT_WARN_RATIO;
  const f = Number.parseFloat(raw);
  return Number.isFinite(f) && f > 0 && f <= 1 ? f : DEFAULT_WARN_RATIO;
})();

// Note: we do NOT cache the client across invocations.  A naive
// `ReturnType<typeof createClient>` cache strips the generic schema
// parameter and makes the typed `.rpc(name, args)` signature reject
// our typed argument bag.  Constructing per-call is cheap (no socket
// open until the first request) and the Edge Function runtime keeps
// the underlying fetch pool warm.
function client() {
  // persistSession/autoRefreshToken OFF: this is a service-role client that
  // never carries a user session, so token auto-refresh is pointless. Leaving
  // autoRefreshToken on also starts a setInterval the client never clears,
  // which trips Deno's leak sanitizer in batch test runs (and needlessly
  // ticks a timer in the edge runtime).
  return createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

export interface SpendCheckResult {
  /** allowed=false ⇒ the proxy must 503 instead of calling Anthropic. */
  allowed: boolean;
  /** Today's total cents BEFORE this request. */
  spentCents: number;
  /** Cap in cents (informational). */
  capCents: number;
  /** Warning band reached but not yet blocking. */
  warning: boolean;
  /** True if the DB layer was unreachable; caller may want to log. */
  degraded: boolean;
}

/**
 * Pre-flight check: does today's spend leave room for another Anthropic
 * call?  Best-effort.  Never throws.  Fails open on DB errors.
 */
export async function checkDailyCap(): Promise<SpendCheckResult> {
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    return {
      allowed: true,
      spentCents: 0,
      capCents: DAILY_CAP_CENTS,
      warning: false,
      degraded: true,
    };
  }
  try {
    const { data, error } = await client().rpc("get_anthropic_spend_today");
    if (error) {
      console.warn(`spend_tracker: get RPC failed: ${error.message}`);
      return {
        allowed: true,
        spentCents: 0,
        capCents: DAILY_CAP_CENTS,
        warning: false,
        degraded: true,
      };
    }
    const row = Array.isArray(data) ? data[0] : data;
    const spent = Number((row as { cents_spent?: number })?.cents_spent ?? 0);
    return {
      allowed: spent < DAILY_CAP_CENTS,
      spentCents: spent,
      capCents: DAILY_CAP_CENTS,
      warning: spent >= DAILY_CAP_CENTS * WARN_RATIO,
      degraded: false,
    };
  } catch (e) {
    console.warn(`spend_tracker: check threw: ${String(e).slice(0, 200)}`);
    return {
      allowed: true,
      spentCents: 0,
      capCents: DAILY_CAP_CENTS,
      warning: false,
      degraded: true,
    };
  }
}

/**
 * Identifier for which LLM provider drove a given call.  Used by the
 * multi-provider fallback chain (FIX-WAVE 14) so that spend can be
 * attributed correctly:
 *   • anthropic_sonnet     — $3/M in,    $15/M out
 *   • anthropic_haiku      — $1/M in,    $5/M out
 *   • openai_gpt4o_mini    — $0.15/M in, $0.60/M out
 */
export type SpendProvider =
  | "anthropic_sonnet"
  | "anthropic_haiku"
  | "openai_gpt4o_mini";

/**
 * Post-call accounting: record the estimated cost of one model response.
 * Returns the new daily total in cents (0 if the DB call failed).
 *
 * `model` is matched against /sonnet/i for tier pricing; anything else is
 * treated as Haiku-tier.  Token counts come from the provider's usage block.
 *
 * `provider` is the FIX-WAVE 14 attribution tag.  Default 'anthropic_sonnet'
 * preserves backwards compatibility — all historical callers (claude-proxy
 * Anthropic path) recorded Sonnet calls.  The DB RPC pricing is now provider-
 * driven, so passing 'openai_gpt4o_mini' applies the ~20× cheaper OpenAI
 * pricing instead of accidentally billing at Sonnet rates.
 */
export async function recordSpend(
  inputTokens: number,
  outputTokens: number,
  model: string,
  provider: SpendProvider = "anthropic_sonnet",
): Promise<number> {
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) return 0;
  try {
    const { data, error } = await client().rpc("record_anthropic_spend", {
      p_input_tokens: Math.max(0, Math.floor(inputTokens)),
      p_output_tokens: Math.max(0, Math.floor(outputTokens)),
      p_model: model ?? "haiku",
      p_provider: provider,
    });
    if (error) {
      console.warn(`spend_tracker: record RPC failed: ${error.message}`);
      return 0;
    }
    const row = Array.isArray(data) ? data[0] : data;
    return Number((row as { cents_spent?: number })?.cents_spent ?? 0);
  } catch (e) {
    console.warn(`spend_tracker: record threw: ${String(e).slice(0, 200)}`);
    return 0;
  }
}

/**
 * Log a structured incident to the error_log table.  Best-effort; never
 * throws.  Used by claude-proxy when the cap is breached, when the rate
 * limit triggers, or for any other non-fatal incident worth visiting.
 */
export async function logIncident(opts: {
  kind: string;
  severity?: "info" | "warn" | "error" | "critical";
  source?: string;
  message?: string;
  details?: Record<string, unknown>;
  principal?: string;
  requestId?: string;
}): Promise<void> {
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) return;
  try {
    const { error } = await client().rpc("log_incident", {
      p_kind: opts.kind,
      p_severity: opts.severity ?? "warn",
      p_source: opts.source ?? null,
      p_message: opts.message ?? null,
      p_details: opts.details ?? null,
      p_principal: opts.principal ?? null,
      p_request_id: opts.requestId ?? null,
    });
    if (error) {
      console.warn(`spend_tracker: log_incident failed: ${error.message}`);
    }
  } catch (e) {
    console.warn(`spend_tracker: log_incident threw: ${String(e).slice(0, 200)}`);
  }
}

/**
 * Build the 503 body that the proxy returns when the daily cap is breached.
 * Centralised so the streaming + non-streaming paths emit the same shape.
 */
export function capExceededBody(spentCents: number): Record<string, unknown> {
  return {
    error: "Service capacity reached. Please try again in 1 hour.",
    cap_breach: true,
    spent_cents: spentCents,
    cap_cents: DAILY_CAP_CENTS,
    retry_after_seconds: 3600,
  };
}
