// stripe-webhook/signature.ts
// -----------------------------------------------------------------------------
// Pure Stripe webhook signature verification, extracted from index.ts so the
// HMAC + replay-window logic is unit-testable without booting Deno.serve.
//
// Behaviour is byte-identical to the previous inline block in index.ts:
//   * missing signature / secret           → { ok:false, reason:"missing" }
//   * malformed `t=`/`v1=` header           → { ok:false, reason:"format" }
//   * timestamp outside MAX_WEBHOOK_AGE_SEC → { ok:false, reason:"stale" }
//   * HMAC-SHA256 mismatch                  → { ok:false, reason:"mismatch" }
//   * otherwise                             → { ok:true }
//
// The caller maps every failure to the same HTTP 401 it returned before; the
// reason is for logging / tests only.
// -----------------------------------------------------------------------------

/** Stripe recommends rejecting events older than 5 minutes to block replays. */
export const MAX_WEBHOOK_AGE_SEC = 300;

export type SignatureFailure = "missing" | "format" | "stale" | "mismatch";

export type VerifyResult =
  | { ok: true }
  | { ok: false; reason: SignatureFailure };

/** Constant-time string compare — avoids leaking the signature via timing. */
export function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let r = 0;
  for (let i = 0; i < a.length; i++) {
    r |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return r === 0;
}

/**
 * Verify the `Stripe-Signature` header against the raw request body.
 *
 * @param rawBody    the request body EXACTLY as received (pre-JSON.parse)
 * @param signature  the `stripe-signature` header value (or null)
 * @param secret     STRIPE_WEBHOOK_SECRET (or undefined/empty if unset)
 * @param nowSec     current unix seconds — injectable so the replay window
 *                   is testable with a fixed clock
 */
export async function verifyStripeSignature(
  rawBody: string,
  signature: string | null,
  secret: string | undefined,
  nowSec: number = Math.floor(Date.now() / 1000),
): Promise<VerifyResult> {
  if (!signature || !secret) return { ok: false, reason: "missing" };

  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const parts = signature.split(",");
  const timestamp = parts.find((p) => p.startsWith("t="))?.split("=")[1];
  const sig = parts.find((p) => p.startsWith("v1="))?.split("=")[1];
  if (!timestamp || !sig) return { ok: false, reason: "format" };

  // Replay-attack protection: reject stale webhooks.
  const timestampNum = parseInt(timestamp, 10);
  if (
    !timestampNum || Math.abs(nowSec - timestampNum) > MAX_WEBHOOK_AGE_SEC
  ) {
    return { ok: false, reason: "stale" };
  }

  const signedPayload = `${timestamp}.${rawBody}`;
  const expectedSig = await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode(signedPayload),
  );
  const expectedHex = Array.from(new Uint8Array(expectedSig))
    .map((b) => b.toString(16).padStart(2, "0")).join("");

  if (!timingSafeEqual(expectedHex, sig)) {
    return { ok: false, reason: "mismatch" };
  }
  return { ok: true };
}
