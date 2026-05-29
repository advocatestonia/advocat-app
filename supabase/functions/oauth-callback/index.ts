// oauth-callback Edge Function (v24.3, 2026-05-05)
// -----------------------------------------------------------------------------
// Persists a Google OAuth `provider_token` (and optional `provider_refresh_token`)
// into public.user_oauth_tokens so send-email can pull it on subsequent
// requests and dispatch via Gmail API instead of falling back to Resend.
//
// Why this function exists:
//   Supabase's signInWithOAuth returns the user a Google identity but the
//   provider's access_token / refresh_token live only in the in-memory session
//   (session.providerToken / providerRefreshToken). They are NOT written to
//   any Postgres table by Supabase. To use them server-side (Gmail API call
//   from send-email), the client must POST them here once after sign-in.
//
// Contract:
//   POST /functions/v1/oauth-callback
//   Headers:
//     Authorization: Bearer <user JWT>
//   Body:
//     {
//       provider:        "gmail"      // only Gmail supported today
//       access_token:    string       // required — Google provider_token
//       refresh_token?:  string       // optional — for unattended refresh
//       email?:          string       // user's Gmail address (for From: header)
//       expires_in?:     number       // seconds; defaults to DEFAULT_EXPIRES_IN_S
//       scope?:          string       // space-separated OAuth scopes granted
//                                     // (optional — backward compat; older
//                                     //  clients don't send this)
//     }
//   Response 200: {
//     ok: true,
//     email?: string,
//     expires_at: string,
//     has_refresh_token: boolean,     // so the client can show honest UI state
//   }
//   Response 400: { error: <validation message> }
//   Response 401: Unauthorized
//   Response 429: Rate limit exceeded
//   Response 502: Upstream Postgres error
//
// Security:
//   - JWT-gated (shared `requireUserWithRateLimit` helper).
//   - CORS locked to advocat.ee.
//   - The body's user_id (if any) is IGNORED — we always use gate.user.id.
//     Otherwise any authenticated user could write a token row for another
//     user.
//   - Service role bypasses RLS to write the token row (the table policy
//     allows users to read/delete their own rows but never INSERT — that's
//     server-only).
//   - Provider is restricted to ALLOWED_PROVIDERS so a future "outlook" or
//     "yahoo" implementation cannot be silently activated by client payload.
//
// Rate limit: 10 req/min per user. The legitimate flow calls this exactly
// once per OAuth redirect, so 10/min is generous.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  jsonError,
  jsonOk,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import { killOn, signupPausedResponse } from "../_shared/kill_switches.ts";
import { normalizeForUpsert, validatePayload } from "./payload.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // ── Kill switch: KILL_SIGNUP=1 (DEPT 7 runbook) ────────────────────────
  // Set via `supabase secrets set KILL_SIGNUP=1` when we need to halt new
  // sign-ups (abuse spike, capacity overrun). Checked BEFORE the auth gate
  // so the response is consistent regardless of token state.
  if (killOn("KILL_SIGNUP")) {
    return signupPausedResponse();
  }

  const gate = await requireUserWithRateLimit(req, {
    bucket: "oauth-callback",
    maxPerMinute: 10,
  });
  if (gate.kind === "deny") return gate.response;

  let raw: unknown;
  try {
    raw = await req.json();
  } catch (_) {
    return jsonError("Invalid JSON body", 400);
  }

  const validation = validatePayload(raw);
  if (!validation.ok) {
    return jsonError(validation.error, 400);
  }

  const row = normalizeForUpsert(validation.value, Date.now());

  // user_id always comes from the auth gate — never from the body. This is
  // the load-bearing line: it's why a user cannot write a token row for
  // a different user.
  const userId = gate.user.id;

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  // Wave-1 security audit P0-5 (2026-05-28): dual-write encrypted token
  // columns alongside the deprecated plain-text columns. See migration
  // 20260528120000_security_audit_p0_revokes.sql. Failures are LOGGED but
  // non-fatal during the dual-write window; Wave 2 will drop the plain
  // columns and make encryption fatal.
  let accessTokenEnc: string | null = null;
  let refreshTokenEnc: string | null = null;
  try {
    const { data: accEnc, error: accErr } = await supabase.rpc(
      "vault_encrypt_text",
      { p_plaintext: row.access_token, p_user_id: userId },
    );
    if (accErr) {
      console.warn(
        "oauth-callback: vault_encrypt_text(access_token) failed:",
        accErr,
      );
    } else if (typeof accEnc === "string") {
      accessTokenEnc = accEnc;
    }

    if (row.refresh_token) {
      const { data: refEnc, error: refErr } = await supabase.rpc(
        "vault_encrypt_text",
        { p_plaintext: row.refresh_token, p_user_id: userId },
      );
      if (refErr) {
        console.warn(
          "oauth-callback: vault_encrypt_text(refresh_token) failed:",
          refErr,
        );
      } else if (typeof refEnc === "string") {
        refreshTokenEnc = refEnc;
      }
    }
  } catch (e) {
    console.warn(
      "oauth-callback: vault encrypt step threw (non-fatal):",
      String(e),
    );
  }

  // Base row (always-present columns). The encrypted shadow columns are
  // added separately so we can degrade gracefully if the P0-5 migration
  // (20260528120000) that introduces *_enc has not been applied yet —
  // otherwise the upsert would 42703 and OAuth token persistence (and thus
  // Gmail send) would break 100% for any deploy where the edge fn ships
  // before the migration. This makes the two deployable in EITHER order.
  const baseRow: Record<string, unknown> = {
    user_id: userId,
    provider: row.provider,
    // DEPRECATED 2026-05-28: plain-text columns retained for the dual-write
    // window. Wave 2 will drop these after readers migrate to *_enc columns.
    access_token: row.access_token,
    refresh_token: row.refresh_token,
    email: row.email,
    expires_at: row.expires_at,
    scope: row.scope,
    updated_at: new Date().toISOString(),
  };

  // Wave-1 P0-5: encrypted shadow columns. Readers may opt in via
  // vault_decrypt_text(<col>, user_id).
  const encRow: Record<string, unknown> = {
    ...baseRow,
    access_token_enc: accessTokenEnc,
    refresh_token_enc: refreshTokenEnc,
  };

  let { error } = await supabase
    .from("user_oauth_tokens")
    .upsert(encRow, { onConflict: "user_id,provider" });

  // 42703 = undefined_column: the *_enc columns are not in this deploy yet.
  // Retry plain-only so the token still persists (dual-write degrades to
  // single-write until the migration lands).
  if (error && (error as { code?: string }).code === "42703") {
    console.warn(
      "oauth-callback: *_enc columns absent — retrying plain-only " +
        "(apply migration 20260528120000 to enable encryption-at-rest)",
    );
    ({ error } = await supabase
      .from("user_oauth_tokens")
      .upsert(baseRow, { onConflict: "user_id,provider" }));
  }

  if (error) {
    // Log raw DB error server-side; do not echo to client (leak-class fix).
    console.error("oauth-callback: upsert failed", error);
    return jsonError("Failed to persist OAuth token", 502);
  }

  return jsonOk({
    ok: true,
    email: row.email,
    expires_at: row.expires_at,
    // Honest UI hint: the client can tell the user "you'll need to sign in
    // again in an hour" when this is false (no refresh token == every access
    // expiry forces re-consent). True means we have offline access via the
    // refresh token Google returned with `access_type=offline + prompt=consent`.
    has_refresh_token: !!row.refresh_token,
  });
});
