// oauth-callback/payload.ts
// -----------------------------------------------------------------------------
// Pure helpers for validating and normalizing OAuth callback payloads.
// Kept in a separate module so they can be Deno-tested without booting the
// HTTP server (which would grab port 8000 at module load).
//
// Used by index.ts. See full contract in oauth-callback/index.ts.
// -----------------------------------------------------------------------------

/** Providers we are willing to persist in user_oauth_tokens. */
export const ALLOWED_PROVIDERS = new Set<string>(["gmail"]);

/**
 * Default token lifetime when Google does not return `expires_in`. Google's
 * access tokens are typically valid for 3600 s; we use a slightly shorter
 * fallback (50 minutes) as a defensive default so the refresh path runs
 * before a real expiry.
 */
export const DEFAULT_EXPIRES_IN_S = 3000;

/** Hard cap so a malicious client cannot persist a forever-token that we
 * would never refresh (Google's max is 3600 s; we cap at 24 h to be safe). */
export const MAX_EXPIRES_IN_S = 86_400;

/** RFC-2822-ish minimal email shape — same as send-email::emailRe. */
const EMAIL_RE = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

export interface OAuthCallbackPayload {
  provider: string;
  access_token: string;
  refresh_token?: string;
  email?: string;
  expires_in?: number;
}

export interface NormalizedToken {
  provider: string;
  access_token: string;
  refresh_token: string | null;
  email: string | null;
  /** Absolute expiry timestamp in ISO-8601 UTC. */
  expires_at: string;
}

export type ValidationResult =
  | { ok: true; value: OAuthCallbackPayload }
  | { ok: false; error: string };

/**
 * Validate the JSON body of POST /oauth-callback. Returns either the typed
 * payload or a human-readable error string suitable for a 400 response.
 *
 * The provider must be in ALLOWED_PROVIDERS, access_token must be a non-empty
 * string, and email (if present) must look like a real address.
 */
export function validatePayload(body: unknown): ValidationResult {
  if (body === null || typeof body !== "object" || Array.isArray(body)) {
    return { ok: false, error: "Body must be a JSON object" };
  }
  const b = body as Record<string, unknown>;

  const provider = b.provider;
  if (typeof provider !== "string" || !ALLOWED_PROVIDERS.has(provider)) {
    return {
      ok: false,
      error: `Unsupported provider — must be one of: ${
        [...ALLOWED_PROVIDERS].join(", ")
      }`,
    };
  }

  const accessToken = b.access_token;
  if (typeof accessToken !== "string" || accessToken.length === 0) {
    return { ok: false, error: "access_token is required" };
  }
  // Defence against absurdly large payloads — Google tokens are ~200-2000 chars.
  if (accessToken.length > 8192) {
    return { ok: false, error: "access_token is too large" };
  }

  let refreshToken: string | undefined;
  if (b.refresh_token !== undefined && b.refresh_token !== null) {
    if (typeof b.refresh_token !== "string") {
      return { ok: false, error: "refresh_token must be a string" };
    }
    if (b.refresh_token.length > 8192) {
      return { ok: false, error: "refresh_token is too large" };
    }
    refreshToken = b.refresh_token;
  }

  let email: string | undefined;
  if (b.email !== undefined && b.email !== null) {
    if (typeof b.email !== "string" || !EMAIL_RE.test(b.email)) {
      return { ok: false, error: "email is not a valid address" };
    }
    if (b.email.length > 320) {
      return { ok: false, error: "email is too large" };
    }
    email = b.email;
  }

  let expiresIn: number | undefined;
  if (b.expires_in !== undefined && b.expires_in !== null) {
    const n = typeof b.expires_in === "number"
      ? b.expires_in
      : Number(b.expires_in);
    if (!Number.isFinite(n) || n <= 0) {
      return { ok: false, error: "expires_in must be a positive number" };
    }
    if (n > MAX_EXPIRES_IN_S) {
      return {
        ok: false,
        error: `expires_in exceeds max (${MAX_EXPIRES_IN_S}s)`,
      };
    }
    expiresIn = Math.floor(n);
  }

  return {
    ok: true,
    value: {
      provider,
      access_token: accessToken,
      refresh_token: refreshToken,
      email,
      expires_in: expiresIn,
    },
  };
}

/**
 * Convert a validated payload into the row-shape we upsert into
 * user_oauth_tokens. `now` is injected for testability — production callers
 * pass `Date.now()`, tests can pin a fixed clock.
 */
export function normalizeForUpsert(
  payload: OAuthCallbackPayload,
  nowMs: number,
): NormalizedToken {
  const expiresInS = payload.expires_in ?? DEFAULT_EXPIRES_IN_S;
  const expiresAt = new Date(nowMs + expiresInS * 1000).toISOString();
  return {
    provider: payload.provider,
    access_token: payload.access_token,
    refresh_token: payload.refresh_token ?? null,
    email: payload.email ?? null,
    expires_at: expiresAt,
  };
}
