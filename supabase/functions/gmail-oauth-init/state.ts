// gmail-oauth-init/state.ts
// -----------------------------------------------------------------------------
// Pure helpers for the OAuth state token. This token is the single binding
// between gmail-oauth-init (issuer) and gmail-oauth-exchange (consumer).
// The OAuth redirect from Google arrives at our callback URL WITHOUT a
// Supabase JWT (the browser is mid-OAuth-bounce, the user is not yet
// signed-in to Supabase from the exchanger's POV), so we cannot rely on
// the normal `requireUserWithRateLimit` gate for the exchange step. The
// state token carries the user_id and an expiry, signed with
// EMAIL_AGENT_GATE_SECRET so it cannot be forged.
//
// Token format:
//   base64url(JSON(payload)) "." hex(HMAC-SHA-256(secret, base64url(payload)))
//
// Where payload = { user_id: string, exp_ms: number }.
//
// TTL: 5 minutes by default. Long enough that a user can complete the
// Google consent flow but short enough that a leaked state value is
// useless within a single coffee break.
//
// All crypto goes through Web Crypto (SubtleCrypto) so this works in
// Deno edge runtime and standard Deno test runs without any additional
// permissions.
// -----------------------------------------------------------------------------

const TEXT_ENC = new TextEncoder();
const DEFAULT_TTL_MS = 5 * 60 * 1000; // 5 minutes

export interface StatePayload {
  user_id: string;
  exp_ms: number;
}

export interface SignArgs {
  user_id: string;
  /** Clock injection — defaults to Date.now(). Tests pin this. */
  now_ms?: number;
  /** TTL override — defaults to DEFAULT_TTL_MS. */
  ttl_ms?: number;
}

export type VerifyResult =
  | { ok: true; user_id: string }
  | { ok: false; reason: string };

/**
 * Sign a fresh state token binding `user_id` with a 5-minute expiry.
 *
 * Returns `base64url(JSON(payload)).hex(HMAC(secret, base64url(payload)))`.
 * Both halves are URL-safe, so the token can be passed directly through
 * the Google `state` query parameter without escaping.
 */
export async function signState(
  args: SignArgs,
  secret: string,
): Promise<string> {
  const now = args.now_ms ?? Date.now();
  const ttl = args.ttl_ms ?? DEFAULT_TTL_MS;
  const payload: StatePayload = {
    user_id: args.user_id,
    exp_ms: now + ttl,
  };
  const b64uPayload = base64urlEncode(JSON.stringify(payload));
  const sig = await hmacSha256Hex(secret, b64uPayload);
  return `${b64uPayload}.${sig}`;
}

/**
 * Verify a token's HMAC + TTL and return the bound user_id.
 *
 * Returns `{ok: false}` on:
 *   - malformed structure (missing dot, non-base64url first half)
 *   - non-JSON payload
 *   - missing user_id / exp_ms fields
 *   - HMAC mismatch (forged or wrong-secret)
 *   - expired (now > exp_ms)
 *
 * `now_ms` is injected for testability. Production callers omit it and we
 * use `Date.now()`.
 */
export async function verifyState(
  token: string,
  secret: string,
  now_ms?: number,
): Promise<VerifyResult> {
  if (typeof token !== "string" || token.length === 0) {
    return { ok: false, reason: "malformed_token_empty" };
  }
  const dot = token.indexOf(".");
  if (dot < 0 || dot === token.length - 1) {
    return { ok: false, reason: "malformed_token_structure" };
  }
  const b64uPayload = token.slice(0, dot);
  const claimedHmac = token.slice(dot + 1);
  if (!/^[A-Za-z0-9_-]+$/.test(b64uPayload)) {
    return { ok: false, reason: "malformed_token_base64" };
  }
  if (!/^[a-f0-9]{64}$/.test(claimedHmac)) {
    return { ok: false, reason: "malformed_token_hmac" };
  }

  // Re-derive HMAC and compare. We use a constant-time compare via the
  // direct equality of the lowered-case hex strings — both are 64 chars.
  const expectedHmac = await hmacSha256Hex(secret, b64uPayload);
  if (!constantTimeEq(expectedHmac, claimedHmac)) {
    return { ok: false, reason: "hmac_mismatch" };
  }

  let payload: StatePayload;
  try {
    payload = JSON.parse(base64urlDecode(b64uPayload)) as StatePayload;
  } catch (_) {
    return { ok: false, reason: "malformed_payload_json" };
  }
  if (typeof payload?.user_id !== "string" || payload.user_id.length === 0) {
    return { ok: false, reason: "malformed_payload_user_id" };
  }
  if (typeof payload?.exp_ms !== "number" || !Number.isFinite(payload.exp_ms)) {
    return { ok: false, reason: "malformed_payload_exp_ms" };
  }
  const now = now_ms ?? Date.now();
  if (now > payload.exp_ms) {
    return { ok: false, reason: "token_expired" };
  }

  return { ok: true, user_id: payload.user_id };
}

// -----------------------------------------------------------------------------
// Internal helpers
// -----------------------------------------------------------------------------

function base64urlEncode(s: string): string {
  // btoa works on Latin-1 bytes — TextEncoder + Uint8Array fixes UTF-8.
  const bytes = TEXT_ENC.encode(s);
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

function base64urlDecode(s: string): string {
  // Restore padding so atob is happy.
  const padded = s.replace(/-/g, "+").replace(/_/g, "/");
  const pad = padded.length % 4;
  const full = pad ? padded + "=".repeat(4 - pad) : padded;
  const bin = atob(full);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return new TextDecoder().decode(bytes);
}

async function hmacSha256Hex(secret: string, payload: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    TEXT_ENC.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign(
    "HMAC",
    key,
    TEXT_ENC.encode(payload),
  );
  const bytes = new Uint8Array(sig);
  let hex = "";
  for (const b of bytes) hex += b.toString(16).padStart(2, "0");
  return hex;
}

/** Constant-time equality for two equal-length hex strings. */
function constantTimeEq(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) {
    diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return diff === 0;
}
