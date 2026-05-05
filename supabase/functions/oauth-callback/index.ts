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
//     }
//   Response 200: { ok: true, email?: string, expires_at: string }
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
  const { error } = await supabase
    .from("user_oauth_tokens")
    .upsert(
      {
        user_id: userId,
        provider: row.provider,
        access_token: row.access_token,
        refresh_token: row.refresh_token,
        email: row.email,
        expires_at: row.expires_at,
        updated_at: new Date().toISOString(),
      },
      { onConflict: "user_id,provider" },
    );

  if (error) {
    console.error("oauth-callback: upsert failed", error);
    return jsonError("Failed to persist OAuth token", 502, {
      details: error.message,
    });
  }

  return jsonOk({
    ok: true,
    email: row.email,
    expires_at: row.expires_at,
  });
});
