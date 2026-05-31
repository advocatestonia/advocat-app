// apple-iap-verify/__tests__/handler_test.ts
// -----------------------------------------------------------------------------
// Unit coverage for the pure IAP helpers. This is a MONEY path that previously
// had zero tests (DEPT-3 gap). We cover the two security/money-critical
// decisions:
//   * pickMatchingEntry — forged/replayed transaction_id MUST NOT match
//   * isReceiptActive   — expiry math (lapsed receipt MUST NOT stay Pro)
// plus the product→tier map and the activation write-shape (parity with
// stripe-webhook so check-ai-quota / isProActive don't care about the source).
// -----------------------------------------------------------------------------

import {
  assertEquals,
  assertExists,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  activateSubscription,
  type AppleInAppEntry,
  type AppleReceiptResponse,
  isReceiptActive,
  pickMatchingEntry,
  PRODUCT_ID_TO_TIER,
} from "../handler.ts";

// ─── pickMatchingEntry ───────────────────────────────────────────────────────

Deno.test("IAP-PICK-01 — matches transaction_id in latest_receipt_info", () => {
  const body: AppleReceiptResponse = {
    status: 0,
    latest_receipt_info: [
      { transaction_id: "t-1", product_id: "pro_monthly" },
      { transaction_id: "t-2", product_id: "pro_monthly" },
    ],
  };
  const e = pickMatchingEntry(body, "t-2");
  assertExists(e);
  assertEquals(e!.transaction_id, "t-2");
});

Deno.test("IAP-PICK-02 — falls back to receipt.in_app when not in latest", () => {
  const body: AppleReceiptResponse = {
    status: 0,
    latest_receipt_info: [{ transaction_id: "t-1" }],
    receipt: { in_app: [{ transaction_id: "t-9", product_id: "counsel_monthly" }] },
  };
  const e = pickMatchingEntry(body, "t-9");
  assertExists(e);
  assertEquals(e!.product_id, "counsel_monthly");
});

Deno.test("IAP-PICK-03 — forged/replayed transaction_id returns null (no match)", () => {
  // A client claiming a transaction_id that Apple's response does not contain
  // is a forgery or replay. pickMatchingEntry MUST return null so the caller
  // 409s rather than activating Pro on an unverifiable claim.
  const body: AppleReceiptResponse = {
    status: 0,
    latest_receipt_info: [{ transaction_id: "t-real" }],
  };
  assertEquals(pickMatchingEntry(body, "t-forged"), null);
});

Deno.test("IAP-PICK-04 — empty response returns null", () => {
  assertEquals(pickMatchingEntry({ status: 0 }, "t-1"), null);
});

// ─── isReceiptActive ─────────────────────────────────────────────────────────

const NOW = new Date("2026-05-30T12:00:00Z");

Deno.test("IAP-ACT-01 — future expiry → active", () => {
  const entry: AppleInAppEntry = {
    expires_date_ms: String(NOW.getTime() + 86_400_000), // +1 day
  };
  const r = isReceiptActive(entry, NOW);
  assertEquals(r.active, true);
  assertExists(r.expiresAt);
});

Deno.test("IAP-ACT-02 — past expiry → NOT active (lapsed sub must not stay Pro)", () => {
  const entry: AppleInAppEntry = {
    expires_date_ms: String(NOW.getTime() - 1_000), // 1s ago
  };
  const r = isReceiptActive(entry, NOW);
  assertEquals(r.active, false);
});

Deno.test("IAP-ACT-03 — missing expires_date_ms → NOT active", () => {
  assertEquals(isReceiptActive({}, NOW).active, false);
});

Deno.test("IAP-ACT-04 — non-numeric expires_date_ms → NOT active (no NaN trap)", () => {
  const r = isReceiptActive({ expires_date_ms: "garbage" }, NOW);
  assertEquals(r.active, false);
  assertEquals(r.expiresAt, null);
});

// ─── PRODUCT_ID_TO_TIER ──────────────────────────────────────────────────────

Deno.test("IAP-TIER-01 — product ids map to the correct tier", () => {
  assertEquals(PRODUCT_ID_TO_TIER["counsel_monthly"], "basic");
  assertEquals(PRODUCT_ID_TO_TIER["counsel_annual"], "basic");
  assertEquals(PRODUCT_ID_TO_TIER["pro_monthly"], "premium");
  assertEquals(PRODUCT_ID_TO_TIER["pro_annual"], "premium");
});

Deno.test("IAP-TIER-02 — unknown product id is undefined (caller must reject)", () => {
  assertEquals(PRODUCT_ID_TO_TIER["bogus_product"], undefined);
});

// ─── activateSubscription ────────────────────────────────────────────────────

interface UpsertCall {
  table: string;
  row: Record<string, unknown>;
  onConflict?: string;
}

function fakeSb(opts?: { failOn?: "profiles" | "subscriptions" }) {
  const calls: UpsertCall[] = [];
  return {
    calls,
    from(table: string) {
      return {
        upsert(
          row: Record<string, unknown>,
          cfg?: { onConflict?: string },
        ) {
          calls.push({ table, row, onConflict: cfg?.onConflict });
          if (opts?.failOn === table) {
            return Promise.resolve({ error: { message: `${table} boom` } });
          }
          return Promise.resolve({ error: null });
        },
      };
    },
  };
}

Deno.test("IAP-SUB-01 — writes profiles + subscriptions with Pro shape", async () => {
  const sb = fakeSb();
  const expires = new Date("2026-06-30T00:00:00Z");
  const r = await activateSubscription(sb, "user-1", "premium", expires, {
    transaction_id: "t-1",
    original_transaction_id: "ot-1",
  });
  assertEquals(r.ok, true);
  assertEquals(sb.calls.length, 2);

  const prof = sb.calls.find((c) => c.table === "profiles")!;
  assertEquals(prof.row.is_pro, true);
  assertEquals(prof.row.subscription_tier, "premium");
  assertEquals(prof.row.subscription_expires_at, expires.toISOString());
  assertEquals(prof.onConflict, "id");

  const sub = sb.calls.find((c) => c.table === "subscriptions")!;
  assertEquals(sub.row.status, "active");
  assertEquals(sub.row.tier, "premium");
  assertEquals(sub.row.current_period_end, expires.toISOString());
  // Apple subs are namespaced so they never collide with a real Stripe id.
  assertEquals(sub.row.stripe_subscription_id, "apple:ot-1");
  assertEquals(sub.onConflict, "user_id");
});

Deno.test("IAP-SUB-02 — profiles upsert failure aborts before subscriptions", async () => {
  const sb = fakeSb({ failOn: "profiles" });
  const r = await activateSubscription(sb, "user-1", "basic", new Date(), {
    transaction_id: "t-1",
    original_transaction_id: "ot-1",
  });
  assertEquals(r.ok, false);
  if (!r.ok) assertEquals(r.reason.includes("profiles upsert"), true);
  // Must NOT have attempted the subscriptions write after profiles failed.
  assertEquals(sb.calls.some((c) => c.table === "subscriptions"), false);
});

Deno.test("IAP-SUB-03 — subscriptions upsert failure surfaces reason", async () => {
  const sb = fakeSb({ failOn: "subscriptions" });
  const r = await activateSubscription(sb, "user-1", "basic", new Date(), {
    transaction_id: "t-1",
    original_transaction_id: "ot-1",
  });
  assertEquals(r.ok, false);
  if (!r.ok) assertEquals(r.reason.includes("subscriptions upsert"), true);
});
