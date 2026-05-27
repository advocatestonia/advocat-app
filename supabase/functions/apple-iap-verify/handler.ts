// apple-iap-verify — Pure helpers (no serve() side-effect).
// -----------------------------------------------------------------------------
// Extracted from index.ts so the Deno test runner can import these without
// triggering Deno.serve's listen on port 8000. See index.ts for the wired
// HTTP handler and the architecture / configuration notes.
// -----------------------------------------------------------------------------

export const APPLE_VERIFY_PROD = "https://buy.itunes.apple.com/verifyReceipt";
export const APPLE_VERIFY_SANDBOX =
  "https://sandbox.itunes.apple.com/verifyReceipt";

/** Map StoreKit product_id → internal tier label used by check-ai-quota. */
export const PRODUCT_ID_TO_TIER: Record<string, "basic" | "premium"> = {
  counsel_monthly: "basic",
  counsel_annual: "basic",
  pro_monthly: "premium",
  pro_annual: "premium",
};

export interface VerifyBody {
  receipt_data?: string;
  product_id?: string;
  transaction_id?: string;
  source?: "purchase" | "restore";
}

// Subset of Apple's verifyReceipt response we care about. The full schema is
// huge; we only pull the fields needed to activate + audit.
export interface AppleReceiptResponse {
  status: number;
  environment?: "Sandbox" | "Production";
  receipt?: {
    bundle_id?: string;
    in_app?: AppleInAppEntry[];
  };
  latest_receipt_info?: AppleInAppEntry[];
  pending_renewal_info?: unknown[];
}

export interface AppleInAppEntry {
  product_id?: string;
  transaction_id?: string;
  original_transaction_id?: string;
  expires_date_ms?: string;
  purchase_date_ms?: string;
  is_trial_period?: string;
}

/**
 * POST verifyReceipt against Apple. Implements the sandbox-fallback handshake:
 * production endpoint returns status=21007 to say "this is a sandbox receipt,
 * try the sandbox endpoint". Apple's documentation explicitly warns against
 * detecting environment client-side — always probe production first.
 */
export async function verifyAppleReceipt(
  receiptData: string,
  sharedSecret: string,
  opts: {
    fetchImpl?: typeof fetch;
    allowSandbox?: boolean;
  } = {},
): Promise<
  | { ok: true; body: AppleReceiptResponse; env: "sandbox" | "production" }
  | { ok: false; status: number; reason: string }
> {
  const fetchImpl = opts.fetchImpl ?? fetch;
  const payload = JSON.stringify({
    "receipt-data": receiptData,
    password: sharedSecret,
    "exclude-old-transactions": true,
  });

  const prodResp = await fetchImpl(APPLE_VERIFY_PROD, {
    method: "POST",
    body: payload,
  });
  if (!prodResp.ok) {
    return {
      ok: false,
      status: prodResp.status,
      reason: `apple prod HTTP ${prodResp.status}`,
    };
  }
  const prodBody = (await prodResp.json()) as AppleReceiptResponse;

  // 21007 = "this receipt is from sandbox but you sent it to production"
  if (prodBody.status === 21007) {
    if (!(opts.allowSandbox ?? true)) {
      return {
        ok: false,
        status: 21007,
        reason: "sandbox receipt rejected (APPLE_IAP_ALLOW_SANDBOX=false)",
      };
    }
    const sandboxResp = await fetchImpl(APPLE_VERIFY_SANDBOX, {
      method: "POST",
      body: payload,
    });
    if (!sandboxResp.ok) {
      return {
        ok: false,
        status: sandboxResp.status,
        reason: `apple sandbox HTTP ${sandboxResp.status}`,
      };
    }
    const sandboxBody = (await sandboxResp.json()) as AppleReceiptResponse;
    if (sandboxBody.status !== 0) {
      return {
        ok: false,
        status: sandboxBody.status,
        reason: `apple sandbox status=${sandboxBody.status}`,
      };
    }
    return { ok: true, body: sandboxBody, env: "sandbox" };
  }

  if (prodBody.status !== 0) {
    return {
      ok: false,
      status: prodBody.status,
      reason: `apple prod status=${prodBody.status}`,
    };
  }
  return { ok: true, body: prodBody, env: "production" };
}

/**
 * Pick the entry from latest_receipt_info (or fallback to receipt.in_app) that
 * matches the claimed transaction_id. Returns null if no match — this is a
 * forged or replayed request and the caller must 409.
 */
export function pickMatchingEntry(
  body: AppleReceiptResponse,
  transactionId: string,
): AppleInAppEntry | null {
  const candidates: AppleInAppEntry[] = [
    ...(body.latest_receipt_info ?? []),
    ...(body.receipt?.in_app ?? []),
  ];
  for (const e of candidates) {
    if (e.transaction_id === transactionId) return e;
  }
  return null;
}

/**
 * Decide if a receipt entry is currently active (paid period hasn't lapsed).
 * Apple gives us expires_date_ms as a string of milliseconds since epoch.
 */
export function isReceiptActive(
  entry: AppleInAppEntry,
  now: Date = new Date(),
): { active: boolean; expiresAt: Date | null } {
  if (!entry.expires_date_ms) return { active: false, expiresAt: null };
  const expiresMs = Number.parseInt(entry.expires_date_ms, 10);
  if (!Number.isFinite(expiresMs)) return { active: false, expiresAt: null };
  const expiresAt = new Date(expiresMs);
  return { active: expiresAt.getTime() > now.getTime(), expiresAt };
}

/**
 * Pure activation helper. Same write-shape as stripe-webhook (profiles upsert
 * + subscriptions upsert) so check-ai-quota and isProActive don't need to care
 * where the activation came from. Exported for tests.
 */
export async function activateSubscription(
  // deno-lint-ignore no-explicit-any
  sb: any,
  userId: string,
  tier: "basic" | "premium",
  expiresAt: Date,
  source: { transaction_id: string; original_transaction_id: string },
): Promise<{ ok: true } | { ok: false; reason: string }> {
  const { error: profErr } = await sb.from("profiles").upsert(
    {
      id: userId,
      subscription_tier: tier,
      subscription_expires_at: expiresAt.toISOString(),
      is_pro: true,
    },
    { onConflict: "id" },
  );
  if (profErr) {
    return { ok: false, reason: `profiles upsert: ${profErr.message}` };
  }
  const { error: subErr } = await sb.from("subscriptions").upsert(
    {
      user_id: userId,
      status: "active",
      tier,
      current_period_end: expiresAt.toISOString(),
      stripe_subscription_id: `apple:${source.original_transaction_id}`,
      updated_at: new Date().toISOString(),
    },
    { onConflict: "user_id" },
  );
  if (subErr) {
    return { ok: false, reason: `subscriptions upsert: ${subErr.message}` };
  }
  return { ok: true };
}
