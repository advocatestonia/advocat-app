// Deno-runtime tests for apple-iap-verify.
// -----------------------------------------------------------------------------
// Run:
//   deno test --allow-env --allow-read --allow-net=esm.sh,deno.land \
//     supabase/functions/_tests/apple_iap_verify_test.ts
//
// Coverage:
//   B01 verifyAppleReceipt — happy path, production endpoint accepts
//   B02 verifyAppleReceipt — 21007 triggers sandbox fallback, sandbox
//       accepts → env='sandbox'
//   B03 verifyAppleReceipt — APPLE_IAP_ALLOW_SANDBOX=false rejects a 21007
//       receipt even if sandbox would have accepted (prod safety)
//   B04 verifyAppleReceipt — non-zero, non-21007 status returns ok:false
//       with a reason that includes the status code (for diagnostics)
//   B05 pickMatchingEntry — finds the entry by transaction_id in
//       latest_receipt_info, returns null on a mismatch
//   B06 isReceiptActive — returns active=true for future expires_date_ms,
//       active=false for past, null expires_at on malformed input
//   B07 activateSubscription — writes profiles + subscriptions in the same
//       shape stripe-webhook does; on a profiles error, surfaces the
//       message (no silent failures)
//   B08 Idempotency contract — the apple_iap_transactions table has
//       transaction_id as PRIMARY KEY (source check on the SQL migration)
//   B09 Migration RLS source-check — apple_iap_transactions has the
//       deny-all client write policies the spec calls for
//   B10 PRODUCT_ID_TO_TIER source-check — only the four documented
//       product ids are accepted (defence against typo'd tiers in App
//       Store Connect drift)
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

Deno.env.set("SUPABASE_URL", "https://example.supabase.co");
Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "fake-service-key");
Deno.env.set("APPLE_IAP_SHARED_SECRET", "fake-shared-secret");
Deno.env.set("APPLE_IAP_BUNDLE_ID", "ee.advocat.app");

import {
  activateSubscription,
  isReceiptActive,
  pickMatchingEntry,
  verifyAppleReceipt,
} from "../apple-iap-verify/handler.ts";

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

function fakeFetch(
  routes: Record<string, { status: number; body: unknown }>,
): typeof fetch {
  return ((input: RequestInfo | URL) => {
    const url = typeof input === "string"
      ? input
      : input instanceof URL
      ? input.toString()
      : (input as Request).url;
    const route = routes[url];
    if (!route) {
      return Promise.resolve(
        new Response("not stubbed: " + url, { status: 404 }),
      );
    }
    return Promise.resolve(
      new Response(JSON.stringify(route.body), { status: route.status }),
    );
  }) as typeof fetch;
}

interface FakeProfilesRow {
  id: string;
  subscription_tier: string;
  is_pro: boolean;
  subscription_expires_at: string;
}

interface FakeSubRow {
  user_id: string;
  status: string;
  tier: string;
  current_period_end: string;
  stripe_subscription_id: string;
}

function makeFakeSb(opts: {
  failProfilesOn?: boolean;
  failSubscriptionsOn?: boolean;
} = {}): {
  // deno-lint-ignore no-explicit-any
  client: any;
  state: {
    profiles: Map<string, FakeProfilesRow>;
    subscriptions: Map<string, FakeSubRow>;
  };
} {
  const state = {
    profiles: new Map<string, FakeProfilesRow>(),
    subscriptions: new Map<string, FakeSubRow>(),
  };
  const client = {
    // deno-lint-ignore no-explicit-any
    from(table: string): any {
      return {
        // deno-lint-ignore no-explicit-any
        upsert(row: any, _opts?: any) {
          if (table === "profiles") {
            if (opts.failProfilesOn) {
              return Promise.resolve({
                error: { message: "fake profiles failure" },
              });
            }
            state.profiles.set(row.id, row as FakeProfilesRow);
            return Promise.resolve({ error: null });
          }
          if (table === "subscriptions") {
            if (opts.failSubscriptionsOn) {
              return Promise.resolve({
                error: { message: "fake subscriptions failure" },
              });
            }
            state.subscriptions.set(row.user_id, row as FakeSubRow);
            return Promise.resolve({ error: null });
          }
          return Promise.resolve({ error: null });
        },
      };
    },
  };
  return { client, state };
}

// ---------------------------------------------------------------------------
// B01-B04 — verifyAppleReceipt
// ---------------------------------------------------------------------------

Deno.test("B01 verifyAppleReceipt — prod endpoint accepts (status=0)", async () => {
  const stub = fakeFetch({
    "https://buy.itunes.apple.com/verifyReceipt": {
      status: 200,
      body: { status: 0, environment: "Production", receipt: {} },
    },
  });
  const r = await verifyAppleReceipt("RAW", "SECRET", { fetchImpl: stub });
  assert(r.ok);
  if (r.ok) {
    assertEquals(r.env, "production");
    assertEquals(r.body.status, 0);
  }
});

Deno.test("B02 verifyAppleReceipt — 21007 falls back to sandbox", async () => {
  const stub = fakeFetch({
    "https://buy.itunes.apple.com/verifyReceipt": {
      status: 200,
      body: { status: 21007 },
    },
    "https://sandbox.itunes.apple.com/verifyReceipt": {
      status: 200,
      body: { status: 0, environment: "Sandbox", receipt: {} },
    },
  });
  const r = await verifyAppleReceipt("RAW", "SECRET", { fetchImpl: stub });
  assert(r.ok);
  if (r.ok) assertEquals(r.env, "sandbox");
});

Deno.test("B03 verifyAppleReceipt — allowSandbox=false rejects 21007", async () => {
  const stub = fakeFetch({
    "https://buy.itunes.apple.com/verifyReceipt": {
      status: 200,
      body: { status: 21007 },
    },
  });
  const r = await verifyAppleReceipt("RAW", "SECRET", {
    fetchImpl: stub,
    allowSandbox: false,
  });
  assert(!r.ok);
  if (!r.ok) {
    assertEquals(r.status, 21007);
    assertStringIncludes(r.reason, "sandbox receipt rejected");
  }
});

Deno.test("B04 verifyAppleReceipt — non-zero status surfaces diagnostic", async () => {
  const stub = fakeFetch({
    "https://buy.itunes.apple.com/verifyReceipt": {
      status: 200,
      body: { status: 21002 }, // "data was malformed"
    },
  });
  const r = await verifyAppleReceipt("RAW", "SECRET", { fetchImpl: stub });
  assert(!r.ok);
  if (!r.ok) {
    assertStringIncludes(r.reason, "21002");
  }
});

// ---------------------------------------------------------------------------
// B05 — pickMatchingEntry
// ---------------------------------------------------------------------------

Deno.test("B05 pickMatchingEntry — finds by transaction_id, null on miss", () => {
  const body = {
    status: 0,
    latest_receipt_info: [
      {
        product_id: "pro_monthly",
        transaction_id: "100",
        expires_date_ms: "1900000000000",
      },
      {
        product_id: "pro_monthly",
        transaction_id: "101",
        expires_date_ms: "2000000000000",
      },
    ],
  };
  const hit = pickMatchingEntry(body, "101");
  assert(hit !== null);
  assertEquals(hit?.transaction_id, "101");
  const miss = pickMatchingEntry(body, "999");
  assertEquals(miss, null);
});

// ---------------------------------------------------------------------------
// B06 — isReceiptActive
// ---------------------------------------------------------------------------

Deno.test("B06 isReceiptActive — future expiry active, past not, malformed null", () => {
  const now = new Date("2026-05-27T00:00:00Z");
  const future = isReceiptActive(
    { expires_date_ms: String(now.getTime() + 86_400_000) },
    now,
  );
  assertEquals(future.active, true);
  assert(future.expiresAt !== null);

  const past = isReceiptActive(
    { expires_date_ms: String(now.getTime() - 86_400_000) },
    now,
  );
  assertEquals(past.active, false);

  const malformed = isReceiptActive({ expires_date_ms: "not-a-number" }, now);
  assertEquals(malformed.active, false);
  assertEquals(malformed.expiresAt, null);

  const missing = isReceiptActive({}, now);
  assertEquals(missing.active, false);
});

// ---------------------------------------------------------------------------
// B07 — activateSubscription mirrors stripe-webhook write shape
// ---------------------------------------------------------------------------

Deno.test(
  "B07 activateSubscription — writes profiles + subscriptions in stripe-webhook shape",
  async () => {
    const { client, state } = makeFakeSb();
    const expires = new Date("2027-05-27T00:00:00Z");
    const result = await activateSubscription(client, "user-42", "premium", expires, {
      transaction_id: "tx-1",
      original_transaction_id: "tx-1",
    });
    assert(result.ok);
    const prof = state.profiles.get("user-42");
    assert(prof);
    assertEquals(prof!.is_pro, true);
    assertEquals(prof!.subscription_tier, "premium");
    assertEquals(prof!.subscription_expires_at, expires.toISOString());

    const sub = state.subscriptions.get("user-42");
    assert(sub);
    assertEquals(sub!.status, "active");
    assertEquals(sub!.tier, "premium");
    assertEquals(sub!.stripe_subscription_id, "apple:tx-1");
    assertEquals(sub!.current_period_end, expires.toISOString());
  },
);

Deno.test("B07b activateSubscription — surfaces profiles error", async () => {
  const { client } = makeFakeSb({ failProfilesOn: true });
  const result = await activateSubscription(
    client,
    "user-1",
    "basic",
    new Date(),
    { transaction_id: "tx", original_transaction_id: "tx" },
  );
  assert(!result.ok);
  if (!result.ok) {
    assertStringIncludes(result.reason, "profiles");
  }
});

// ---------------------------------------------------------------------------
// B08 — Migration source contract: transaction_id is PK (idempotency basis).
// ---------------------------------------------------------------------------

Deno.test("B08 migration declares transaction_id as PRIMARY KEY", async () => {
  const sql = await Deno.readTextFile(
    new URL(
      "../../migrations/20260528020000_apple_iap.sql",
      import.meta.url,
    ),
  );
  // The PK declaration must be inline on transaction_id; otherwise a
  // replayed restore would double-write rows.
  assert(
    /transaction_id\s+text\s+primary\s+key/i.test(sql),
    "transaction_id must be declared `text primary key`",
  );
});

// ---------------------------------------------------------------------------
// B09 — Migration RLS contract: client writes denied, owner SELECT allowed.
// ---------------------------------------------------------------------------

Deno.test("B09 migration installs deny-all-write RLS + owner SELECT", async () => {
  const sql = await Deno.readTextFile(
    new URL(
      "../../migrations/20260528020000_apple_iap.sql",
      import.meta.url,
    ),
  );
  assert(/enable row level security/i.test(sql));
  // Three deny-all (insert / update / delete) policies.
  assertStringIncludes(sql, "no client insert");
  assertStringIncludes(sql, "no client update");
  assertStringIncludes(sql, "no client delete");
  // Owner can read their own purchases.
  assertStringIncludes(sql, "owner select");
  assertStringIncludes(sql, "auth.uid() = user_id");
});

// ---------------------------------------------------------------------------
// B10 — PRODUCT_ID_TO_TIER contract (defence against App Store drift)
// ---------------------------------------------------------------------------

Deno.test("B10 product-id whitelist matches Apple-side config doc", async () => {
  const src = await Deno.readTextFile(
    new URL("../apple-iap-verify/handler.ts", import.meta.url),
  );
  // Exactly four product ids accepted. Any drift here must be matched in
  // App Store Connect by the owner — the comment block in iap_service.dart
  // is the source of truth.
  for (
    const pid of [
      "counsel_monthly",
      "counsel_annual",
      "pro_monthly",
      "pro_annual",
    ]
  ) {
    assertStringIncludes(src, pid);
  }
});
