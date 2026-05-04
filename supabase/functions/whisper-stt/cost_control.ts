// whisper-stt/cost_control.ts
// -----------------------------------------------------------------------------
// Pure helpers for the whisper-stt Edge Function. Lives in its own module
// (rather than index.ts) so unit tests can import it without booting the
// HTTP server (Deno.serve grabs port 8000 at import-time).
//
// Same split pattern as claude-proxy/{system_prompt_guard,prompt_caching,
// error_mapping}.ts.
// -----------------------------------------------------------------------------

// ---- Cost-control constants -----------------------------------------------

/** Per-call hard binary cap. Whisper's own ceiling is 25 MB / 30 min; we
 *  cap tighter so a single call can never approach that. */
export const MAX_BINARY_BYTES = 10 * 1024 * 1024; // 10 MB

/** Base64 inflates by 4/3; 14 MB base64 covers a 10 MB binary with headroom. */
export const MAX_AUDIO_B64 = 14 * 1024 * 1024;

/** Per-call duration cap (seconds). 5 min — prevents "stream a lecture" abuse. */
export const SECONDS_PER_CALL_MAX = 5 * 60;

/** Conservative bitrate for the byte→seconds estimator (pre-flight only). */
const ESTIMATE_KBPS = 64;
const ESTIMATE_BYTES_PER_SECOND = (ESTIMATE_KBPS * 1024) / 8; // 8192 B/s

// ---- Tier → monthly seconds quota -----------------------------------------
//
// Tier names match subscriptions.tier as set by stripe-webhook
// (PLAN_MAPPING in supabase/functions/stripe-webhook/subscription_router.ts).
// "counsel" Stripe plan → "basic" tier; "representation" Stripe plan → "premium".

export type VoiceTier = "free" | "basic" | "premium";

export const TIER_MONTHLY_SECONDS: Record<VoiceTier, number> = {
  free: 0, // voice is a paid feature
  basic: 300 * 60, // 300 min  = 5 hours / month
  premium: 1200 * 60, // 1200 min = 20 hours / month
};

// ---- Pure helpers ---------------------------------------------------------

/**
 * Conservative seconds estimator: assumes 64 kbps webm/opus (the high end
 * of MediaRecorder's default range). Used ONLY for the pre-flight quota
 * check; the post-flight tally uses Whisper's verbose_json `duration` field
 * for billing accuracy. Returns whole seconds, rounded UP so we never
 * under-charge for the guard.
 */
export function estimateSecondsFromBytes(binaryBytes: number): number {
  if (binaryBytes <= 0) return 0;
  return Math.ceil(binaryBytes / ESTIMATE_BYTES_PER_SECOND);
}

/**
 * Decode a base64 string to a Uint8Array. Pulled out so tests can verify
 * the same path Whisper sees. Throws (via atob) on malformed input.
 */
export function decodeBase64(b64: string): Uint8Array {
  const binaryString = atob(b64);
  const bytes = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes;
}

/**
 * Pulls the user's tier from the subscriptions table. Same logic as
 * check-ai-quota.detectPlan() but maps to our 3-value VoiceTier shape.
 *
 * Lookup order:
 *   1. subscriptions row with status in ('active','trialing'); use .tier
 *   2. profiles.subscription_tier ('premium' / 'basic')
 *   3. profiles.is_pro=true → basic (legacy)
 *   4. fall through → 'free'
 *
 * Returns "free" if no active subscription is found, or if the lookup throws.
 * Failure-mode is "fall back to free", which means a DB hiccup blocks voice
 * for paying users instead of silently giving free users access — the
 * caller (whisper-stt/index.ts) treats free as a 402, which is the safer
 * direction for a cost-control gate.
 */
export async function detectVoiceTier(
  // deno-lint-ignore no-explicit-any
  sb: any,
  _uid: string,
): Promise<VoiceTier> {
  try {
    const sub = await sb
      .from("subscriptions")
      .select("tier, status")
      .eq("user_id", _uid)
      .in("status", ["active", "trialing"])
      .limit(1)
      .maybeSingle();
    const tier = sub?.data?.tier;
    if (tier === "premium") return "premium";
    if (tier === "basic") return "basic";
    // Active subscription with no tier set → treat as basic (paid).
    if (sub?.data) return "basic";
  } catch (_) {
    // Table may be missing or query failed — fall through to profiles lookup.
  }
  try {
    const prof = await sb
      .from("profiles")
      .select("is_pro, subscription_tier")
      .eq("id", _uid)
      .maybeSingle();
    const t = prof?.data?.subscription_tier;
    if (t === "premium") return "premium";
    if (t === "basic" || prof?.data?.is_pro === true) return "basic";
  } catch (_) {
    // ignore
  }
  return "free";
}
