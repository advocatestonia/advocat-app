// _shared/gmail_token.ts
// -----------------------------------------------------------------------------
// Shared Gmail OAuth helpers — extracted from `send-email/index.ts` so that
// the new `email-inbox-sync` (D3) edge function can reuse the same token
// loading + refresh logic without duplicating the proactive-refresh
// conditions.
//
// Only the I/O seam lives here; the pure decision helpers
// (`shouldRefresh`, `buildRefreshRequestBody`, `computeNewExpiry`) stay in
// `send-email/token_refresh.ts` because that's where their tests already
// live (`__tests__/token_refresh_test.ts`). Importing them from there
// keeps a single source of truth.
//
// `loadGmailToken` and `ensureFreshToken` are the two functions that the
// inbox-sync function (and any future Gmail reader) needs:
//
//   loadGmailToken(supabase, userId)
//     -> the persisted token row, or null if the user has not connected
//        Gmail at all.
//
//   ensureFreshToken(supabase, userId, row)
//     -> the access token to use for the upcoming Gmail API call.
//        Refreshes proactively when within REFRESH_MARGIN_MS of expiry,
//        persists the new token + expiry, and falls back to null when
//        the refresh fails (caller surfaces a `gmail_reauth_required`
//        error to the client).
// -----------------------------------------------------------------------------

import {
  buildRefreshRequestBody,
  computeNewExpiry,
  type GoogleRefreshResponse,
  shouldRefresh,
  type TokenRow,
} from "../send-email/token_refresh.ts";

const GOOGLE_CLIENT_ID = Deno.env.get("GOOGLE_CLIENT_ID");
const GOOGLE_CLIENT_SECRET = Deno.env.get("GOOGLE_CLIENT_SECRET");

export interface GmailTokenRow extends TokenRow {
  user_id: string;
  email: string | null;
  provider: string;
}

/**
 * Read a user's Gmail token row from `user_oauth_tokens`. Returns null if
 * the table has no row for this user (Gmail never connected) or on any
 * Supabase error — the caller treats null as "Gmail not connected".
 *
 * `supabase` is expected to be a service-role client (so it can read the
 * row regardless of RLS — this is a server-only helper).
 */
export async function loadGmailToken(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  userId: string
): Promise<GmailTokenRow | null> {
  try {
    const { data, error } = await supabase
      .from("user_oauth_tokens")
      .select(
        "user_id, access_token, refresh_token, email, expires_at, provider"
      )
      .eq("user_id", userId)
      .eq("provider", "gmail")
      .maybeSingle();
    if (error || !data || !data.access_token) return null;
    return {
      user_id: data.user_id as string,
      access_token: data.access_token as string,
      refresh_token: (data.refresh_token as string | null) ?? null,
      email: (data.email as string | null) ?? null,
      expires_at: (data.expires_at as string | null) ?? null,
      provider: (data.provider as string | null) ?? "gmail",
    };
  } catch (_) {
    return null;
  }
}

/**
 * Refresh a Gmail access token via Google's OAuth endpoint and persist the
 * new token + expiry back to `user_oauth_tokens`. Returns the new
 * access_token on success, or null when refresh failed (no GOOGLE_CLIENT_*
 * env, network error, Google 4xx, missing access_token in the response).
 *
 * Pure-ish wrapper around the test-pinned helpers in
 * `send-email/token_refresh.ts`; kept thin so the failure modes stay
 * obvious and the `console.warn` path is single-source.
 */
export async function refreshGmailToken(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  userId: string,
  refreshToken: string
): Promise<string | null> {
  if (!GOOGLE_CLIENT_ID || !GOOGLE_CLIENT_SECRET) {
    console.warn(
      "gmail_token: cannot refresh — GOOGLE_CLIENT_ID/SECRET not configured."
    );
    return null;
  }
  let resp: Response;
  try {
    resp = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: buildRefreshRequestBody({
        clientId: GOOGLE_CLIENT_ID,
        clientSecret: GOOGLE_CLIENT_SECRET,
        refreshToken,
      }),
    });
  } catch (e) {
    console.warn("gmail_token: refresh fetch failed:", String(e));
    return null;
  }
  if (!resp.ok) {
    // Drain the body so the connection is released, but do NOT log it: the
    // OAuth token endpoint can echo request parameters (incl. the refresh
    // token) back in some error responses. Status code alone is enough to
    // triage a refresh failure.
    await resp.text().catch(() => "");
    console.warn(`gmail_token: refresh failed with status ${resp.status}`);
    return null;
  }
  let data: GoogleRefreshResponse;
  try {
    data = await resp.json();
  } catch (e) {
    console.warn("gmail_token: refresh JSON parse failed:", String(e));
    return null;
  }
  if (!data.access_token) {
    console.warn("gmail_token: refresh response missing access_token");
    return null;
  }
  const newExpiresAt = computeNewExpiry(data, Date.now());
  try {
    await supabase
      .from("user_oauth_tokens")
      .update({
        access_token: data.access_token,
        expires_at: newExpiresAt,
        updated_at: new Date().toISOString(),
      })
      .eq("user_id", userId)
      .eq("provider", "gmail");
  } catch (e) {
    console.warn("gmail_token: failed to persist refreshed token:", String(e));
    // Token still works for this request even if persistence failed.
  }
  return data.access_token;
}

/**
 * Hand back the token to use for an upcoming Gmail API call. Refreshes
 * proactively when within REFRESH_MARGIN_MS of expiry. Returns null when
 * the token is dead (refresh failed and we have no usable bearer) — the
 * caller should surface a `gmail_reauth_required` error to the user.
 */
export async function ensureFreshToken(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  userId: string,
  row: TokenRow,
  now: number = Date.now()
): Promise<string | null> {
  if (!shouldRefresh(row, now)) return row.access_token;
  if (!row.refresh_token) {
    // No way to refresh — return what we have and let Gmail return 401
    // if it's stale. The caller's retry path will surface reauth.
    return row.access_token;
  }
  return await refreshGmailToken(supabase, userId, row.refresh_token);
}
