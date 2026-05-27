// apple-iap-verify — Apple StoreKit receipt validation + subscription activation.
// -----------------------------------------------------------------------------
// Parallel path to stripe-webhook for the iOS native install funnel. Triggered
// by IapService in the Flutter app after StoreKit hands us a fresh
// PurchaseDetails (purchase or restore).
//
// Flow:
//   1. Auth gate (JWT required) + per-user rate-limit via consume_rate_limit
//      RPC (10/min — handles legitimate burst from restorePurchases without
//      letting a leaked JWT spam Apple's server).
//   2. Validate body shape (receipt_data, product_id, transaction_id).
//   3. Call verifyAppleReceipt — sandbox-first per Apple's recommendation,
//      then production on the 21007 hint.
//   4. Cross-check product_id, transaction_id, expires_at against the receipt
//      entry (defence against a forged body re-using a real receipt with a
//      different product claim).
//   5. Upsert apple_iap_transactions (idempotent on transaction_id PK).
//   6. Mirror stripe-webhook's activation write — profiles + subscriptions
//      tables, the same 5-layer pattern (write + verify-after-write).
//   7. Return { ok: true, tier, expires_at } to the client.
//
// Idempotency: apple_iap_transactions.transaction_id is the PK, so a restore
// that replays the same transaction is a no-op upsert. The profiles /
// subscriptions writes are themselves idempotent (always upsert the same row
// by user_id).
//
// Configuration (Supabase env):
//   APPLE_IAP_SHARED_SECRET   — App-specific shared secret from App Store
//                                Connect → App Info → App-Specific Shared
//                                Secret. REQUIRED to validate auto-renewable
//                                subscriptions.
//   APPLE_IAP_BUNDLE_ID       — Bundle identifier the app ships with
//                                (e.g. ee.advocat.app). Used to reject
//                                receipts from other apps.
//   APPLE_IAP_ALLOW_SANDBOX   — "true" to accept sandbox receipts in
//                                production (default: true on staging,
//                                MUST be false on prod after first paying
//                                customer).
//
// Pure helpers live in handler.ts so the Deno test runner can import them
// without triggering serve().
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

import {
  corsHeaders,
  jsonError,
  jsonOk,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import {
  activateSubscription,
  isReceiptActive,
  pickMatchingEntry,
  PRODUCT_ID_TO_TIER,
  type VerifyBody,
  verifyAppleReceipt,
} from "./handler.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const APPLE_IAP_SHARED_SECRET = Deno.env.get("APPLE_IAP_SHARED_SECRET") ?? "";
const APPLE_IAP_BUNDLE_ID = Deno.env.get("APPLE_IAP_BUNDLE_ID") ?? "";
const APPLE_IAP_ALLOW_SANDBOX =
  (Deno.env.get("APPLE_IAP_ALLOW_SANDBOX") ?? "true").toLowerCase() === "true";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  if (!APPLE_IAP_SHARED_SECRET) {
    return jsonError(
      "apple-iap-verify: APPLE_IAP_SHARED_SECRET not configured",
      503,
    );
  }

  const gate = await requireUserWithRateLimit(req, {
    bucket: "apple-iap-verify",
    maxPerMinute: 10,
  });
  if (gate.kind === "deny") return gate.response;

  let body: VerifyBody;
  try {
    body = (await req.json()) as VerifyBody;
  } catch (_e) {
    return jsonError("Invalid JSON body", 400);
  }
  const receiptData = (body.receipt_data ?? "").trim();
  const productId = (body.product_id ?? "").trim();
  const transactionId = (body.transaction_id ?? "").trim();
  if (!receiptData || !productId || !transactionId) {
    return jsonError(
      "receipt_data, product_id and transaction_id are required",
      400,
    );
  }
  const tier = PRODUCT_ID_TO_TIER[productId];
  if (!tier) {
    return jsonError(`unknown product_id: ${productId}`, 400);
  }

  // 1. Verify with Apple.
  const verifyResult = await verifyAppleReceipt(
    receiptData,
    APPLE_IAP_SHARED_SECRET,
    { allowSandbox: APPLE_IAP_ALLOW_SANDBOX },
  );
  if (!verifyResult.ok) {
    return jsonError(`apple verifyReceipt: ${verifyResult.reason}`, 409, {
      apple_status: verifyResult.status,
    });
  }
  const appleBody = verifyResult.body;

  // 2. Bundle id cross-check (defence against a receipt from another app).
  if (
    APPLE_IAP_BUNDLE_ID &&
    appleBody.receipt?.bundle_id &&
    appleBody.receipt.bundle_id !== APPLE_IAP_BUNDLE_ID
  ) {
    return jsonError(
      `bundle_id mismatch: receipt=${appleBody.receipt.bundle_id}`,
      409,
    );
  }

  // 3. Find the entry matching the claimed transaction_id.
  const entry = pickMatchingEntry(appleBody, transactionId);
  if (!entry) {
    return jsonError("transaction_id not found in receipt", 409);
  }
  if (entry.product_id !== productId) {
    return jsonError(
      `product_id mismatch: claimed=${productId} receipt=${entry.product_id ?? "?"}`,
      409,
    );
  }

  const { active, expiresAt } = isReceiptActive(entry);
  if (!expiresAt) {
    return jsonError("expires_date_ms missing from receipt", 409);
  }
  if (!active) {
    return jsonError("subscription expired", 410, {
      expires_at: expiresAt.toISOString(),
    });
  }

  const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // 4. Upsert the ledger row (idempotent on transaction_id PK).
  const { error: ledgerErr } = await sb.from("apple_iap_transactions").upsert(
    {
      transaction_id: transactionId,
      user_id: gate.user.id,
      product_id: productId,
      original_transaction_id: entry.original_transaction_id ?? transactionId,
      expires_at: expiresAt.toISOString(),
      environment: verifyResult.env,
      raw_receipt: entry as unknown as Record<string, unknown>,
    },
    { onConflict: "transaction_id" },
  );
  if (ledgerErr) {
    return jsonError(
      `apple_iap_transactions upsert: ${ledgerErr.message}`,
      500,
    );
  }

  // 5. Mirror the Stripe activation write-shape on profiles + subscriptions.
  const activation = await activateSubscription(
    sb,
    gate.user.id,
    tier,
    expiresAt,
    {
      transaction_id: transactionId,
      original_transaction_id: entry.original_transaction_id ?? transactionId,
    },
  );
  if (!activation.ok) {
    return jsonError(activation.reason, 500);
  }

  console.log(
    `[apple-iap-verify] user=${gate.user.id} tier=${tier} ` +
      `tx=${transactionId} env=${verifyResult.env} source=${body.source ?? "purchase"}`,
  );

  return jsonOk({
    ok: true,
    tier,
    expires_at: expiresAt.toISOString(),
    environment: verifyResult.env,
  });
});
