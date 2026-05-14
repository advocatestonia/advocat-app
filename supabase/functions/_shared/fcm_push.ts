// _shared/fcm_push.ts
// -----------------------------------------------------------------------------
// FCM HTTP v1 sender. Used by retention loops + Pkg 9 deadline radar.
//
// Behaviour when GOOGLE_APPLICATION_CREDENTIALS is NOT configured:
//   * sendPush() returns { ok: false, error: "fcm_not_configured" }
//   * No network call is made.
//   * Caller can log the attempt and continue. The code path is exercised
//     in tests so flipping the env var on later in prod activates push
//     without any code change.
//
// When credentials ARE configured (service-account JSON in env var
// `FCM_SERVICE_ACCOUNT_JSON`), we mint a short-lived OAuth token via
// service-account JWT and POST to FCM HTTP v1.
//
// Spec ref:
//   * docs/architecture/phase2-pkg9-deadline-radar.md §6
//   * reference_pkg9_deadline_radar.md
// -----------------------------------------------------------------------------

export interface FcmPushParams {
  /** Either fcmToken OR topic must be set. */
  fcmToken?: string;
  topic?: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}

export interface FcmPushResult {
  ok: boolean;
  messageId?: string;
  error?: string;
}

interface ServiceAccount {
  client_email: string;
  private_key: string;
  project_id: string;
}

/** Cached parsed service account, so we don't re-parse JSON on every call. */
let saCache: ServiceAccount | null = null;
/** Cached OAuth token + expiry (epoch ms). */
let tokenCache: { token: string; expiresAt: number } | null = null;

function loadServiceAccount(): ServiceAccount | null {
  if (saCache) return saCache;
  const raw =
    Deno.env.get("FCM_SERVICE_ACCOUNT_JSON") ||
    Deno.env.get("GOOGLE_APPLICATION_CREDENTIALS_JSON");
  if (!raw) return null;
  try {
    const parsed = JSON.parse(raw) as ServiceAccount;
    if (!parsed.client_email || !parsed.private_key || !parsed.project_id) {
      console.warn("fcm_push: service account JSON missing required fields");
      return null;
    }
    saCache = parsed;
    return parsed;
  } catch (e) {
    console.warn(`fcm_push: failed to parse service account JSON: ${e}`);
    return null;
  }
}

/** Returns true iff FCM is fully configured and a send would actually fire. */
export function isFcmConfigured(): boolean {
  return loadServiceAccount() !== null;
}

/**
 * Mint an OAuth2 access token from the FCM service account. Cached for
 * ~50 minutes (Google tokens last 1h; we refresh 10 min early).
 */
async function getAccessToken(sa: ServiceAccount): Promise<string | null> {
  const now = Date.now();
  if (tokenCache && tokenCache.expiresAt > now + 60_000) {
    return tokenCache.token;
  }

  // Build + sign JWT (RS256). Service-account flow per
  // https://developers.google.com/identity/protocols/oauth2/service-account
  const header = { alg: "RS256", typ: "JWT" };
  const iat = Math.floor(now / 1000);
  const exp = iat + 3600;
  const claims = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat,
    exp,
  };

  const enc = (obj: unknown) =>
    btoa(JSON.stringify(obj))
      .replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  const signingInput = `${enc(header)}.${enc(claims)}`;

  let signatureBytes: ArrayBuffer;
  try {
    const pkcs8 = pemToPkcs8(sa.private_key);
    const key = await crypto.subtle.importKey(
      "pkcs8",
      pkcs8,
      { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
      false,
      ["sign"],
    );
    signatureBytes = await crypto.subtle.sign(
      "RSASSA-PKCS1-v1_5",
      key,
      new TextEncoder().encode(signingInput),
    );
  } catch (e) {
    console.warn(`fcm_push: JWT signing failed: ${e}`);
    return null;
  }
  const signature = uint8ToBase64Url(new Uint8Array(signatureBytes));
  const jwt = `${signingInput}.${signature}`;

  let resp: Response;
  try {
    resp = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body:
        `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
    });
  } catch (e) {
    console.warn(`fcm_push: token fetch failed: ${e}`);
    return null;
  }
  if (!resp.ok) {
    console.warn(`fcm_push: token endpoint ${resp.status}: ${await resp.text()}`);
    return null;
  }
  const data = await resp.json();
  if (!data.access_token) return null;
  tokenCache = {
    token: data.access_token,
    expiresAt: now + (data.expires_in ?? 3600) * 1000,
  };
  return data.access_token;
}

/**
 * Send a single push. Returns { ok: false, error: "fcm_not_configured" }
 * when the service-account env var is missing — caller should log and
 * continue (this is expected in dev / before credential rotation).
 */
export async function sendPush(params: FcmPushParams): Promise<FcmPushResult> {
  const sa = loadServiceAccount();
  if (!sa) {
    return { ok: false, error: "fcm_not_configured" };
  }
  if (!params.fcmToken && !params.topic) {
    return { ok: false, error: "missing_token_or_topic" };
  }

  const token = await getAccessToken(sa);
  if (!token) {
    return { ok: false, error: "oauth_token_failed" };
  }

  const message: Record<string, unknown> = {
    notification: { title: params.title, body: params.body },
    data: params.data ?? {},
  };
  if (params.fcmToken) message.token = params.fcmToken;
  if (params.topic) message.topic = params.topic;

  let resp: Response;
  try {
    resp = await fetch(
      `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`,
      {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ message }),
      },
    );
  } catch (e) {
    return { ok: false, error: `fcm_fetch_failed:${String(e).slice(0, 100)}` };
  }
  if (!resp.ok) {
    const txt = await resp.text();
    return { ok: false, error: `fcm_${resp.status}:${txt.slice(0, 200)}` };
  }
  const data = await resp.json();
  return { ok: true, messageId: data.name as string };
}

// ── PEM helpers ────────────────────────────────────────────────────────────

function pemToPkcs8(pem: string): ArrayBuffer {
  const cleaned = pem
    .replace(/-----BEGIN [^-]+-----/g, "")
    .replace(/-----END [^-]+-----/g, "")
    .replace(/\s+/g, "");
  const bin = atob(cleaned);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return bytes.buffer;
}

function uint8ToBase64Url(b: Uint8Array): string {
  let s = "";
  for (let i = 0; i < b.length; i++) s += String.fromCharCode(b[i]);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

/** Test-only: reset the in-process caches. */
export function __resetFcmCaches() {
  saCache = null;
  tokenCache = null;
}
