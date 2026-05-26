// gmail-oauth-init Edge Function (2026-05-26)
// -----------------------------------------------------------------------------
// Side-channel Google OAuth init step. Returns the Google authorize URL
// with `access_type=offline + prompt=consent`, which Supabase's
// `signInWithOAuth(provider:'google')` strips out before forwarding to
// Google — that's why our 5 users in prod have refresh_token IS NULL in
// `user_oauth_tokens` and the inbox-sync cron silently skips them.
//
// Direct flow:
//   1) Flutter app calls POST /functions/v1/gmail-oauth-init
//      Headers: Authorization: Bearer <user JWT>
//      Body:    {} (empty — user_id always comes from the JWT)
//      Resp:    { auth_url: string, state: string }
//   2) Flutter opens auth_url in a system browser.
//   3) User consents at Google → Google redirects to
//      https://advocat.ee/oauth/gmail/return?code=...&state=...
//   4) That page POSTs {code, state} to /functions/v1/gmail-oauth-exchange
//      which verifies the state (NO Supabase JWT available at this hop —
//      the state is the trust binding) and upserts user_oauth_tokens with
//      access_token + refresh_token + email + expires_at + scope.
//
// Why both an Authorization header AND a state token:
//   - This init step uses the Supabase JWT — the user is signed-in to the
//     Flutter app.
//   - The exchange step gets called by a plain redirect from Google. There
//     is no Supabase session in that request. The state is the only proof
//     of "this exchanger is acting on behalf of user X".
//
// Contract:
//   POST /functions/v1/gmail-oauth-init
//   Headers:
//     Authorization: Bearer <user JWT>
//   Body: ignored.
//   Response 200: { auth_url: string, state: string }
//   Response 401: { error: "Unauthorized" }
//   Response 429: { error: "Rate limit ..." }
//   Response 503: { error: "signup_paused" }    (KILL_SIGNUP=1)
//
// Rate limit: 10 req/min per user. Legitimate users invoke this once per
// Gmail connect attempt; 10/min covers retry-on-network-blip without
// opening an abuse vector.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import {
  corsHeaders,
  jsonError,
  jsonOk,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import { killOn, signupPausedResponse } from "../_shared/kill_switches.ts";
import { signState } from "./state.ts";

const GOOGLE_CLIENT_ID = Deno.env.get("GOOGLE_CLIENT_ID") ?? "";
const EMAIL_AGENT_GATE_SECRET = Deno.env.get("EMAIL_AGENT_GATE_SECRET") ?? "";
const REDIRECT_URI = Deno.env.get("GMAIL_OAUTH_REDIRECT_URI") ??
  "https://advocat.ee/oauth/gmail/return";

/**
 * Hard-coded duplicate of `kGmailScopesActive` from the Flutter client
 * (`lib/services/google_oauth_service.dart`). Drift between the two is a
 * real bug — keep this list and the Flutter constant aligned.
 *
 * Order matters: Google preserves it in the consent screen, and the
 * `scope` returned by Google in the token response uses the same order.
 */
const GMAIL_SCOPES_ACTIVE = [
  "email",
  "https://www.googleapis.com/auth/gmail.send",
  "https://www.googleapis.com/auth/gmail.readonly",
  "https://www.googleapis.com/auth/gmail.modify",
].join(" ");

const GOOGLE_AUTHORIZE_URL = "https://accounts.google.com/o/oauth2/v2/auth";

// =============================================================================
// Pure-ish handler — exported for tests
// =============================================================================

export interface HandleInitArgs {
  /** User id from the auth gate, or null if unauthenticated. */
  authedUserId: string | null;
  /** killOn("KILL_SIGNUP") result, injected for testability. */
  killSignup: boolean;
  /** Google OAuth client ID. */
  clientId: string;
  /** EMAIL_AGENT_GATE_SECRET — used to HMAC-sign the state token. */
  gateSecret: string;
  /** Where Google should redirect after consent. */
  redirectUri: string;
  /** Clock injection for tests. */
  nowMs?: number;
}

export interface HandleInitResult {
  auth_url: string;
  state: string;
}

/**
 * Pure-ish handler. Returns the Response we'd return from the HTTP entry
 * point. Lifted out of `serve()` so tests can call it directly without
 * standing up a server or going through the real auth gate (the auth
 * decision is the `authedUserId` argument).
 */
export async function handleInit(args: HandleInitArgs): Promise<Response> {
  if (args.killSignup) {
    return signupPausedResponse();
  }
  if (!args.authedUserId) {
    return jsonError("Unauthorized", 401);
  }
  if (!args.clientId) {
    return jsonError("OAuth client not configured", 503, {
      error_code: "google_client_id_missing",
    });
  }
  if (!args.gateSecret) {
    return jsonError("OAuth gate secret not configured", 503, {
      error_code: "gate_secret_missing",
    });
  }

  const state = await signState(
    { user_id: args.authedUserId, now_ms: args.nowMs },
    args.gateSecret,
  );

  // URLSearchParams handles all encoding for us — including the spaces
  // between scopes (encoded as `+`, which Google accepts).
  const params = new URLSearchParams({
    client_id: args.clientId,
    redirect_uri: args.redirectUri,
    response_type: "code",
    access_type: "offline",
    prompt: "consent",
    scope: GMAIL_SCOPES_ACTIVE,
    state,
    // include_granted_scopes lets Google return a single token good for
    // every previously-granted scope plus the new ones — better UX when
    // a user has previously granted gmail.send and is now adding readonly.
    include_granted_scopes: "true",
  });

  const authUrl = `${GOOGLE_AUTHORIZE_URL}?${params.toString()}`;
  return jsonOk({ auth_url: authUrl, state });
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

  // Kill switch first (mirrors oauth-callback) — must respond identically
  // regardless of token state so an abuse spike cannot probe auth via the
  // signup-paused response.
  if (killOn("KILL_SIGNUP")) {
    return signupPausedResponse();
  }

  const gate = await requireUserWithRateLimit(req, {
    bucket: "gmail-oauth-init",
    maxPerMinute: 10,
  });
  if (gate.kind === "deny") return gate.response;

  return await handleInit({
    authedUserId: gate.user.id,
    killSignup: false, // already checked above; kept explicit for handler clarity
    clientId: GOOGLE_CLIENT_ID,
    gateSecret: EMAIL_AGENT_GATE_SECRET,
    redirectUri: REDIRECT_URI,
  });
});
