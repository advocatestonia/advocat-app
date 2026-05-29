// gmail-oauth-exchange Edge Function (2026-05-26)
// -----------------------------------------------------------------------------
// Step 2 of the side-channel Gmail OAuth flow. The browser redirect from
// Google lands on https://advocat.ee/oauth/gmail/return?code=...&state=...
// which POSTs {code, state} here. We:
//
//   1. Verify the state token (HMAC + 5-min TTL) — this is the user-binding,
//      because the redirect carries no Supabase Authorization header.
//   2. Exchange the code at https://oauth2.googleapis.com/token for
//      {access_token, refresh_token, expires_in, scope, id_token}.
//   3. DEFENSIVE: if refresh_token is missing, return 502 + log warn. With
//      access_type=offline + prompt=consent on the init step it should
//      never happen — but the whole reason this side-channel exists is
//      that Supabase's gotrue swallowed those flags, so we trust nothing.
//   4. Extract the user's email from id_token (or fall back to userinfo).
//   5. Upsert user_oauth_tokens (user_id from STATE, never from body).
//
// Why no Authorization header check:
//   The HTTP redirect from Google is a plain GET → our callback HTML →
//   POST to this function. There is no Supabase session in that POST. The
//   state HMAC is the only proof of "who initiated this flow"; we rely on
//   EMAIL_AGENT_GATE_SECRET being server-only to make it unforgeable.
//
// Why ignore body.user_id (even if a client sets it):
//   Letting the body decide who to write the token row for would re-enable
//   the exact CVE we closed in oauth-callback. State token is the source
//   of truth; body fields beyond {code, state} are ignored.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders, jsonError, jsonOk } from "../_shared/auth.ts";
import { killOn, signupPausedResponse } from "../_shared/kill_switches.ts";
import { verifyState } from "../gmail-oauth-init/state.ts";
import { buildExchangeBody } from "./exchange.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const GOOGLE_CLIENT_ID = Deno.env.get("GOOGLE_CLIENT_ID") ?? "";
const GOOGLE_CLIENT_SECRET = Deno.env.get("GOOGLE_CLIENT_SECRET") ?? "";
const EMAIL_AGENT_GATE_SECRET = Deno.env.get("EMAIL_AGENT_GATE_SECRET") ?? "";
const REDIRECT_URI = Deno.env.get("GMAIL_OAUTH_REDIRECT_URI") ??
  "https://advocat.ee/oauth/gmail/return";

const GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token";
const GOOGLE_USERINFO_URL = "https://www.googleapis.com/oauth2/v2/userinfo";

// =============================================================================
// Handler — exported for tests
// =============================================================================

export interface HandleExchangeArgs {
  /** Parsed JSON body. We read `code` and `state`; ignore everything else. */
  body: Record<string, unknown>;
  /** killOn("KILL_SIGNUP") result, injected for testability. */
  killSignup: boolean;
  /** Google OAuth client id. */
  clientId: string;
  /** Google OAuth client secret. */
  clientSecret: string;
  /** EMAIL_AGENT_GATE_SECRET — used to verify state HMAC. */
  gateSecret: string;
  /** Must equal the redirect_uri used at init (Google enforces this). */
  redirectUri: string;
  /** Supabase service-role client (or the test fake). */
  // deno-lint-ignore no-explicit-any
  supabase: any;
  /** Injectable fetch — tests swap this for a stub. */
  fetchImpl?: typeof fetch;
  /** Injectable clock for tests (used for both expires_at and updated_at). */
  nowMs?: number;
}

export async function handleExchange(
  args: HandleExchangeArgs,
): Promise<Response> {
  if (args.killSignup) {
    return signupPausedResponse();
  }

  const code = args.body?.code;
  const state = args.body?.state;
  if (typeof code !== "string" || code.length === 0 || code.length > 8192) {
    return jsonError("code is required", 400);
  }
  if (typeof state !== "string" || state.length === 0 || state.length > 4096) {
    return jsonError("state is required", 400);
  }

  const verified = await verifyState(state, args.gateSecret, args.nowMs);
  if (!verified.ok) {
    // Don't echo the reason — that would help an attacker probe.
    console.warn(`gmail-oauth-exchange: state rejected (${verified.reason})`);
    return jsonError("Invalid or expired state", 401, {
      error_code: "invalid_state",
    });
  }
  // CRITICAL: user_id is taken from the state token, NEVER from
  // args.body.user_id. The body's user_id (if any) is ignored.
  const userId = verified.user_id;

  if (!args.clientId || !args.clientSecret) {
    return jsonError("OAuth client not configured", 503, {
      error_code: "google_client_id_missing",
    });
  }

  const doFetch = args.fetchImpl ?? fetch;

  // --- 2. Exchange the code -------------------------------------------------
  let tokenResp: Response;
  try {
    tokenResp = await doFetch(GOOGLE_TOKEN_URL, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: buildExchangeBody({
        code,
        clientId: args.clientId,
        clientSecret: args.clientSecret,
        redirectUri: args.redirectUri,
      }).toString(),
    });
  } catch (e) {
    console.error("gmail-oauth-exchange: token fetch failed:", String(e));
    return jsonError("Failed to reach Google OAuth", 502, {
      error_code: "google_unreachable",
    });
  }

  if (!tokenResp.ok) {
    const text = await tokenResp.text().catch(() => "");
    console.warn(
      `gmail-oauth-exchange: Google returned ${tokenResp.status}: ${text}`,
    );
    return jsonError("Google rejected the code", 502, {
      error_code: "google_token_exchange_failed",
      status: tokenResp.status,
    });
  }

  interface GoogleTokenResponse {
    access_token?: string;
    refresh_token?: string;
    expires_in?: number;
    scope?: string;
    id_token?: string;
    token_type?: string;
  }

  let token: GoogleTokenResponse;
  try {
    token = await tokenResp.json();
  } catch (e) {
    console.error("gmail-oauth-exchange: bad JSON from Google:", String(e));
    return jsonError("Google returned invalid JSON", 502, {
      error_code: "google_invalid_json",
    });
  }

  if (!token.access_token) {
    console.warn("gmail-oauth-exchange: Google response missing access_token");
    return jsonError("Google response missing access_token", 502, {
      error_code: "google_missing_access_token",
    });
  }

  // --- 3. Defensive: refresh_token MUST be present --------------------------
  // The whole point of the side-channel is to fix the prod bug where
  // refresh_token IS NULL because Supabase gotrue stripped offline+consent.
  // If Google STILL omits it here, fail loud — we will NOT silently persist
  // a row that resurrects the original bug.
  if (!token.refresh_token) {
    console.warn(
      "gmail-oauth-exchange: Google omitted refresh_token despite " +
        "access_type=offline + prompt=consent — ALERT",
    );
    // The `error` field is the machine-readable code so Flutter / Sentry
    // can pattern-match on it without parsing English. `message` carries
    // the user-friendly text.
    return jsonError("google_omitted_refresh_token", 502, {
      message:
        "Google did not return a refresh_token (consent flow may need to be re-initiated).",
      error_code: "google_omitted_refresh_token",
    });
  }

  // --- 4. Extract the user's email -----------------------------------------
  let email: string | null = null;
  if (typeof token.id_token === "string" && token.id_token.length > 0) {
    email = extractEmailFromIdToken(token.id_token);
  }
  if (!email) {
    // Fall back to /userinfo. This is rare — id_token is always returned
    // when "openid email" is in scope, which our scopes effectively are.
    try {
      const u = await doFetch(GOOGLE_USERINFO_URL, {
        headers: { Authorization: `Bearer ${token.access_token}` },
      });
      if (u.ok) {
        const json = await u.json() as { email?: string };
        if (json && typeof json.email === "string") email = json.email;
      }
    } catch (e) {
      console.warn(
        "gmail-oauth-exchange: userinfo fallback failed:",
        String(e),
      );
    }
  }

  // --- 5. Upsert ------------------------------------------------------------
  const now = args.nowMs ?? Date.now();
  const expiresInS = typeof token.expires_in === "number" && token.expires_in > 0
    ? Math.floor(token.expires_in)
    : 3000; // mirrors DEFAULT_EXPIRES_IN_S from oauth-callback/payload.ts
  const expiresAt = new Date(now + expiresInS * 1000).toISOString();
  const updatedAt = new Date(now).toISOString();

  // Wave-1 security audit P0-5 (2026-05-28): dual-write encrypted token
  // columns alongside the deprecated plain-text columns. Encryption is
  // performed via the public.vault_encrypt_text RPC which delegates to
  // app_vault.encrypt_text (SECURITY DEFINER, owner-scoped). Failures here
  // are LOGGED but non-fatal — we still write the plain row so the OAuth
  // flow completes; Wave 2 will drop the plain columns and a failure to
  // encrypt will become fatal. See migration
  // 20260528120000_security_audit_p0_revokes.sql for column definitions.
  let accessTokenEnc: string | null = null;
  let refreshTokenEnc: string | null = null;
  try {
    const { data: accEnc, error: accErr } = await args.supabase.rpc(
      "vault_encrypt_text",
      { p_plaintext: token.access_token, p_user_id: userId },
    );
    if (accErr) {
      console.warn(
        "gmail-oauth-exchange: vault_encrypt_text(access_token) failed:",
        accErr,
      );
    } else if (typeof accEnc === "string") {
      accessTokenEnc = accEnc;
    }

    const { data: refEnc, error: refErr } = await args.supabase.rpc(
      "vault_encrypt_text",
      { p_plaintext: token.refresh_token, p_user_id: userId },
    );
    if (refErr) {
      console.warn(
        "gmail-oauth-exchange: vault_encrypt_text(refresh_token) failed:",
        refErr,
      );
    } else if (typeof refEnc === "string") {
      refreshTokenEnc = refEnc;
    }
  } catch (e) {
    console.warn(
      "gmail-oauth-exchange: vault encrypt step threw (non-fatal):",
      String(e),
    );
  }

  // Base row (always-present columns). The *_enc shadow columns are added
  // separately so this is deploy-order-independent with migration
  // 20260528120000 (which introduces access_token_enc/refresh_token_enc).
  // If the edge fn ships BEFORE the migration, the *_enc upsert 42703s and we
  // retry plain-only — otherwise OAuth token persistence (and Gmail send)
  // would break 100% on any deploy where the fn leads the migration.
  const baseRow: Record<string, unknown> = {
    user_id: userId,
    provider: "gmail",
    // DEPRECATED 2026-05-28: plain-text columns retained for the dual-write
    // window. Wave 2 will drop these after readers migrate to *_enc.
    access_token: token.access_token,
    refresh_token: token.refresh_token,
    email,
    expires_at: expiresAt,
    scope: typeof token.scope === "string" ? token.scope : null,
    updated_at: updatedAt,
  };

  // Wave-1 P0-5: encrypted shadow columns. Readers may opt in via
  // vault_decrypt_text(<col>, user_id).
  const encRow: Record<string, unknown> = {
    ...baseRow,
    access_token_enc: accessTokenEnc,
    refresh_token_enc: refreshTokenEnc,
  };

  let { error } = await args.supabase
    .from("user_oauth_tokens")
    .upsert(encRow, { onConflict: "user_id,provider" });

  // 42703 = undefined_column: the *_enc columns are not in this deploy yet.
  // Retry plain-only so the token still persists (dual-write degrades to
  // single-write until migration 20260528120000 lands).
  if (error && (error as { code?: string }).code === "42703") {
    console.warn(
      "gmail-oauth-exchange: *_enc columns absent — retrying plain-only " +
        "(apply migration 20260528120000 to enable encryption-at-rest)",
    );
    ({ error } = await args.supabase
      .from("user_oauth_tokens")
      .upsert(baseRow, { onConflict: "user_id,provider" }));
  }

  if (error) {
    // Log the raw DB error server-side; do NOT echo it to the client (it can
    // carry internal column/constraint detail). Same leak-class fix as
    // create-checkout / whisper-stt / landmark-search.
    console.error("gmail-oauth-exchange: upsert failed", error);
    return jsonError("Failed to persist OAuth token", 502, {
      error_code: "db_upsert_failed",
    });
  }

  return jsonOk({
    ok: true,
    email,
    has_refresh_token: true,
  });
}

/**
 * Pull `.email` out of a Google id_token (JWT). We never verify the JWT
 * signature here — we just received this token directly from Google's
 * token endpoint over TLS in response to a one-shot authorization code,
 * so the claim is trusted-by-channel. If we ever switched to receiving
 * id_tokens out-of-band we'd need full JWT verification.
 *
 * Returns null on any malformed input; the caller falls back to /userinfo.
 */
function extractEmailFromIdToken(idToken: string): string | null {
  try {
    const parts = idToken.split(".");
    if (parts.length < 2) return null;
    const padded = parts[1].replace(/-/g, "+").replace(/_/g, "/");
    const pad = padded.length % 4;
    const full = pad ? padded + "=".repeat(4 - pad) : padded;
    const bin = atob(full);
    const bytes = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
    const json = new TextDecoder().decode(bytes);
    const claims = JSON.parse(json) as { email?: string };
    return typeof claims.email === "string" ? claims.email : null;
  } catch (_) {
    return null;
  }
}

// =============================================================================
// HTTP wiring
// =============================================================================

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // KILL_SIGNUP first — must respond identically regardless of body state.
  if (killOn("KILL_SIGNUP")) {
    return signupPausedResponse();
  }

  let raw: unknown;
  try {
    raw = await req.json();
  } catch (_) {
    return jsonError("Invalid JSON body", 400);
  }

  if (raw === null || typeof raw !== "object" || Array.isArray(raw)) {
    return jsonError("Body must be a JSON object", 400);
  }

  if (!EMAIL_AGENT_GATE_SECRET) {
    return jsonError("OAuth gate secret not configured", 503, {
      error_code: "gate_secret_missing",
    });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  return await handleExchange({
    body: raw as Record<string, unknown>,
    killSignup: false, // already checked above
    clientId: GOOGLE_CLIENT_ID,
    clientSecret: GOOGLE_CLIENT_SECRET,
    gateSecret: EMAIL_AGENT_GATE_SECRET,
    redirectUri: REDIRECT_URI,
    supabase,
  });
});
