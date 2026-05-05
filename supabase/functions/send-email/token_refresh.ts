// send-email/token_refresh.ts
// -----------------------------------------------------------------------------
// Pure helpers for the Gmail access-token refresh path.
// Kept in a separate module so the logic (expiry detection, OAuth body shape)
// is unit-testable without booting the HTTP server in index.ts.
// -----------------------------------------------------------------------------

/**
 * Margin (ms) before actual expiry at which we proactively refresh. 5 minutes
 * is enough headroom for clock skew and a slow refresh round-trip.
 */
export const REFRESH_MARGIN_MS = 5 * 60_000;

export interface TokenRow {
  /** ISO-8601 UTC timestamp, or null if unknown (treat as expired). */
  expires_at: string | null;
  refresh_token: string | null;
  access_token: string;
}

/**
 * Decide whether the access token in `row` should be refreshed before use.
 *
 * Rules:
 *   - If we have no refresh_token, we cannot refresh — return false (caller
 *     will use the existing token and let it fail naturally if expired).
 *   - If expires_at is null/unparseable, treat as expired and refresh.
 *   - If now + REFRESH_MARGIN_MS >= expires_at, refresh.
 */
export function shouldRefresh(row: TokenRow, nowMs: number): boolean {
  if (!row.refresh_token || row.refresh_token.length === 0) {
    return false;
  }
  if (!row.expires_at) {
    return true;
  }
  const expiryMs = Date.parse(row.expires_at);
  if (!Number.isFinite(expiryMs)) {
    return true;
  }
  return nowMs + REFRESH_MARGIN_MS >= expiryMs;
}

export interface GoogleRefreshResponse {
  access_token?: string;
  expires_in?: number;
  /** Sometimes returned, often not. We only care if access_token is present. */
  refresh_token?: string;
  /** Present on errors. */
  error?: string;
  error_description?: string;
}

/**
 * Build the URL-encoded body for Google's token-refresh endpoint
 * (https://oauth2.googleapis.com/token).
 *
 * Returned as a `URLSearchParams` so the caller can pass it directly to
 * `fetch` without re-encoding.
 */
export function buildRefreshRequestBody(args: {
  clientId: string;
  clientSecret: string;
  refreshToken: string;
}): URLSearchParams {
  return new URLSearchParams({
    client_id: args.clientId,
    client_secret: args.clientSecret,
    refresh_token: args.refreshToken,
    grant_type: "refresh_token",
  });
}

/**
 * Compute the new expires_at ISO timestamp from a Google refresh response.
 * Falls back to a 50-minute window if `expires_in` is missing/invalid (Google
 * normally returns 3600; we use a slightly shorter default so the next
 * refresh fires before any real expiry).
 */
export function computeNewExpiry(
  resp: GoogleRefreshResponse,
  nowMs: number,
): string {
  const fallbackS = 3000;
  const n = typeof resp.expires_in === "number" ? resp.expires_in : NaN;
  const seconds = Number.isFinite(n) && n > 0 ? Math.floor(n) : fallbackS;
  return new Date(nowMs + seconds * 1000).toISOString();
}
