// ACSP_V2 signature-protocol helpers (Smart-ID RP API v3).
// Spec: https://sk-eid.github.io/smart-id-documentation/rp-api/signature_protocols.html
// All functions are pure (WebCrypto only) and covered by tests/acsp_test.ts.

import { b64Encode, utf8 } from "./b64.ts";

/** rpChallenge := BASE64-ENCODE(CRYPTO-RANDOM(64)). Keep server-side for the whole session. */
export function generateRpChallenge(): { bytes: Uint8Array; base64: string } {
  const bytes = new Uint8Array(64);
  crypto.getRandomValues(bytes);
  return { bytes, base64: b64Encode(bytes) };
}

/**
 * Verification code shown to the user in notification-based authentication:
 *   VC = integer(last 2 bytes of SHA-256(rpChallenge raw bytes), big-endian) mod 10000
 * zero-padded to 4 digits.
 * Spec: rp-api/notification_based_flows.html. Verified against a live demo
 * session (fixtures/live_notification.json → expectedVC).
 */
export async function computeVerificationCode(
  rpChallengeBytes: Uint8Array
): Promise<string> {
  const digest = new Uint8Array(
    await crypto.subtle.digest("SHA-256", rpChallengeBytes.slice())
  );
  const n = (digest[digest.length - 2] << 8) | digest[digest.length - 1];
  return String(n % 10000).padStart(4, "0");
}

export interface AcspV2MessageParams {
  /** "smart-id" (LIVE) or "smart-id-demo" (DEMO). */
  schemeName: string;
  /** signature.serverRandom from the session response — Base64, used as-is. */
  serverRandom: string;
  /** The rpChallenge we sent at session init — Base64, used as-is. */
  rpChallengeB64: string;
  /** signature.userChallenge from the session response — Base64URL, used as-is. */
  userChallenge: string;
  /** Plain RP name, byte-for-byte as sent at init (will be Base64-encoded here). */
  relyingPartyName: string;
  /** Plain brokered RP name; empty string when RP is not a broker. */
  brokeredRpName?: string;
  /** The EXACT Base64 interactions string sent at init (never re-serialize). */
  interactionsB64: string;
  /** interactionTypeUsed from the session response. */
  interactionTypeUsed: string;
  /** Empty for QR and Notification flows; the initial callback URL otherwise. */
  initialCallbackUrl?: string;
  /** signature.flowType from the session response (QR/App2App/Web2App/Notification). */
  flowType: string;
}

/**
 * Reconstructs the ACSP_V2 data-to-be-signed message:
 *   schemeName|ACSP_V2|serverRandom|rpChallenge|userChallenge|
 *   B64(relyingPartyName)|B64(brokeredRpName)|B64(SHA-256(interactions))|
 *   interactionTypeUsed|initialCallbackUrl|flowType
 * The signature is verified over UTF-8 bytes of this string (hashing is done
 * inside RSASSA-PSS verification).
 */
export async function buildAcspV2Message(
  p: AcspV2MessageParams
): Promise<string> {
  const interactionsHash = new Uint8Array(
    await crypto.subtle.digest("SHA-256", utf8(p.interactionsB64).slice())
  );
  return [
    p.schemeName,
    "ACSP_V2",
    p.serverRandom,
    p.rpChallengeB64,
    p.userChallenge,
    b64Encode(utf8(p.relyingPartyName)),
    p.brokeredRpName ? b64Encode(utf8(p.brokeredRpName)) : "",
    b64Encode(interactionsHash),
    p.interactionTypeUsed,
    p.initialCallbackUrl ?? "",
    p.flowType,
  ].join("|");
}
