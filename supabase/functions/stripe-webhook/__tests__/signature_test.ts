// stripe-webhook/__tests__/signature_test.ts
// -----------------------------------------------------------------------------
// Coverage for verifyStripeSignature — the gate that decides whether a webhook
// is a real Stripe event or a forgery. Previously this HMAC + replay-window
// logic was inline in serve() and untested (DEPT-3 gap, money path).
// -----------------------------------------------------------------------------

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  MAX_WEBHOOK_AGE_SEC,
  timingSafeEqual,
  verifyStripeSignature,
} from "../signature.ts";

const SECRET = "whsec_test_secret";
const BODY = `{"id":"evt_1","type":"checkout.session.completed"}`;

/** Build a valid `t=...,v1=...` Stripe-Signature header for (body, ts). */
async function signHeader(
  body: string,
  ts: number,
  secret: string,
): Promise<string> {
  const enc = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    enc.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const mac = await crypto.subtle.sign("HMAC", key, enc.encode(`${ts}.${body}`));
  const hex = Array.from(new Uint8Array(mac))
    .map((b) => b.toString(16).padStart(2, "0")).join("");
  return `t=${ts},v1=${hex}`;
}

// ─── happy path ──────────────────────────────────────────────────────────────

Deno.test("SIG-01 — a correctly signed, fresh webhook verifies", async () => {
  const now = 1_900_000_000;
  const header = await signHeader(BODY, now, SECRET);
  const r = await verifyStripeSignature(BODY, header, SECRET, now);
  assertEquals(r.ok, true);
});

// ─── failure modes ───────────────────────────────────────────────────────────

Deno.test("SIG-02 — missing signature header → missing", async () => {
  const r = await verifyStripeSignature(BODY, null, SECRET, 1_900_000_000);
  assertEquals(r, { ok: false, reason: "missing" });
});

Deno.test("SIG-03 — missing secret → missing", async () => {
  const now = 1_900_000_000;
  const header = await signHeader(BODY, now, SECRET);
  const r = await verifyStripeSignature(BODY, header, undefined, now);
  assertEquals(r, { ok: false, reason: "missing" });
});

Deno.test("SIG-04 — malformed header (no v1=) → format", async () => {
  const r = await verifyStripeSignature(
    BODY,
    "t=1900000000",
    SECRET,
    1_900_000_000,
  );
  assertEquals(r, { ok: false, reason: "format" });
});

Deno.test("SIG-05 — stale timestamp beyond the replay window → stale", async () => {
  const signedAt = 1_900_000_000;
  const header = await signHeader(BODY, signedAt, SECRET);
  // now is MAX_WEBHOOK_AGE_SEC + 1 seconds later → outside the window.
  const now = signedAt + MAX_WEBHOOK_AGE_SEC + 1;
  const r = await verifyStripeSignature(BODY, header, SECRET, now);
  assertEquals(r, { ok: false, reason: "stale" });
});

Deno.test("SIG-06 — exactly at the window edge still verifies", async () => {
  const signedAt = 1_900_000_000;
  const header = await signHeader(BODY, signedAt, SECRET);
  const now = signedAt + MAX_WEBHOOK_AGE_SEC; // abs diff == limit, not > limit
  const r = await verifyStripeSignature(BODY, header, SECRET, now);
  assertEquals(r.ok, true);
});

Deno.test("SIG-07 — wrong secret → mismatch (forgery rejected)", async () => {
  const now = 1_900_000_000;
  const header = await signHeader(BODY, now, "whsec_attacker_guess");
  const r = await verifyStripeSignature(BODY, header, SECRET, now);
  assertEquals(r, { ok: false, reason: "mismatch" });
});

Deno.test("SIG-08 — tampered body → mismatch", async () => {
  const now = 1_900_000_000;
  const header = await signHeader(BODY, now, SECRET);
  // Same signature, different body — the signed payload no longer matches.
  const r = await verifyStripeSignature(
    `${BODY}TAMPERED`,
    header,
    SECRET,
    now,
  );
  assertEquals(r, { ok: false, reason: "mismatch" });
});

// ─── timingSafeEqual ─────────────────────────────────────────────────────────

Deno.test("SIG-09 — timingSafeEqual: equal vs differing vs length-mismatch", () => {
  assertEquals(timingSafeEqual("abc123", "abc123"), true);
  assertEquals(timingSafeEqual("abc123", "abc124"), false);
  assertEquals(timingSafeEqual("abc", "abcd"), false);
});
