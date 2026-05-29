// Deno tests for stripe-webhook idempotency + verification helpers.
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-read \
//     supabase/functions/stripe-webhook/__tests__/idempotency_test.ts
//
// Ref: silent-failure mode #3 (DB write returns ok but row didn't update) and
// #4 (Stripe retries causing duplicate processing). Sofia's manual activation
// 2026-04-26 is the canonical example of #3 going undetected.
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertRejects,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  checkAndMarkProcessing,
  markError,
  markOk,
  type SupabaseLike,
  verifyProfileWrite,
  verifySubscriptionWrite,
} from "../idempotency.ts";

// ---------- Mock supabase client ---------------------------------------------
//
// Just enough of the supabase-js fluent API to drive our helpers. Each call
// returns a chainable object whose terminal awaitable resolves to
// {data, error}. We record every operation so tests can assert on them.

interface RowStore {
  webhook_events: Map<string, Record<string, unknown>>;
  profiles: Map<string, Record<string, unknown>>;
  subscriptions: Map<string, Record<string, unknown>>;
}

interface MockOpts {
  // Force the next select on this table to return an error.
  selectError?: { table: string; message: string };
  // Force the next upsert/update on this table to return an error.
  writeError?: { table: string; message: string };
  // Force the verification read to lie — return a row that says is_pro=false.
  verifyLies?: boolean;
}

function makeMock(initial: Partial<RowStore> = {}, opts: MockOpts = {}) {
  const store: RowStore = {
    webhook_events: initial.webhook_events ?? new Map(),
    profiles: initial.profiles ?? new Map(),
    subscriptions: initial.subscriptions ?? new Map(),
  };

  const calls: { op: string; table: string; payload?: unknown }[] = [];

  function from(table: keyof RowStore) {
    let pendingFilter: { col: string; val: unknown } | null = null;

    const builder: Record<string, unknown> = {
      select(_cols: string) {
        return {
          eq(col: string, val: unknown) {
            pendingFilter = { col, val };
            return {
              maybeSingle() {
                if (opts.selectError && opts.selectError.table === table) {
                  return Promise.resolve({
                    data: null,
                    error: { message: opts.selectError.message },
                  });
                }
                const row = store[table].get(String(pendingFilter!.val));
                return Promise.resolve({ data: row ?? null, error: null });
              },
              single() {
                if (opts.selectError && opts.selectError.table === table) {
                  return Promise.resolve({
                    data: null,
                    error: { message: opts.selectError.message },
                  });
                }
                if (opts.verifyLies && table === "profiles") {
                  // Simulate the bug: row exists but is_pro stayed false even
                  // though we just upserted is_pro=true.
                  return Promise.resolve({
                    data: { is_pro: false, subscription_tier: "free" },
                    error: null,
                  });
                }
                const row = store[table].get(String(pendingFilter!.val));
                return Promise.resolve({ data: row ?? null, error: null });
              },
              limit(_n: number) {
                const row = store[table].get(String(pendingFilter!.val));
                return Promise.resolve({
                  data: row ? [row] : [],
                  error: null,
                });
              },
            };
          },
        };
      },
      upsert(payload: Record<string, unknown>, _opts?: unknown) {
        calls.push({ op: "upsert", table, payload });
        if (opts.writeError && opts.writeError.table === table) {
          return Promise.resolve({
            data: null,
            error: { message: opts.writeError.message },
          });
        }
        const key = (payload.event_id ?? payload.id ?? payload.user_id) as string;
        store[table].set(String(key), { ...store[table].get(String(key)), ...payload });
        return Promise.resolve({ data: null, error: null });
      },
      update(payload: Record<string, unknown>) {
        return {
          eq(col: string, val: unknown) {
            calls.push({ op: "update", table, payload: { ...payload, [col]: val } });
            if (opts.writeError && opts.writeError.table === table) {
              return Promise.resolve({
                data: null,
                error: { message: opts.writeError.message },
              });
            }
            const existing = store[table].get(String(val)) ?? {};
            store[table].set(String(val), { ...existing, ...payload });
            return Promise.resolve({ data: null, error: null });
          },
        };
      },
    };
    return builder;
  }

  const supabase: SupabaseLike & { calls: typeof calls; store: RowStore } = {
    from: from as unknown as SupabaseLike["from"],
    rpc(name: string, args?: Record<string, unknown>) {
      calls.push({ op: "rpc", table: name, payload: args });

      // Emulate the atomic claim_webhook_event RPC against the store, mirroring
      // the migration's claim rules: no row → insert+process; ok → skip;
      // error/stale-processing → reclaim+process; fresh processing → skip.
      if (name === "claim_webhook_event") {
        if (opts.writeError && opts.writeError.table === "webhook_events") {
          return Promise.resolve({
            data: null,
            error: { message: opts.writeError.message },
          });
        }
        const eventId = String(args?.p_event_id);
        const eventType = String(args?.p_event_type);
        const existing = store.webhook_events.get(eventId);
        if (!existing) {
          store.webhook_events.set(eventId, {
            event_id: eventId,
            event_type: eventType,
            status: "processing",
          });
          return Promise.resolve({ data: "process", error: null });
        }
        if (existing.status === "ok") {
          return Promise.resolve({ data: "skip", error: null });
        }
        if (existing.status === "error") {
          store.webhook_events.set(eventId, { ...existing, status: "processing" });
          return Promise.resolve({ data: "process", error: null });
        }
        // status === 'processing' (fresh sibling, not stale in test) → skip.
        return Promise.resolve({ data: "skip", error: null });
      }

      return Promise.resolve({ data: null, error: null });
    },
    calls,
    store,
  };
  return supabase;
}

// ---- checkAndMarkProcessing -------------------------------------------------

Deno.test("idem-T01 — first time: returns process and marks status=processing", async () => {
  const sb = makeMock();
  const decision = await checkAndMarkProcessing(
    sb,
    "evt_123",
    "checkout.session.completed",
  );
  assertEquals(decision.kind, "process");
  const row = sb.store.webhook_events.get("evt_123");
  assertEquals(row?.status, "processing");
  assertEquals(row?.event_type, "checkout.session.completed");
});

Deno.test("idem-T02 — duplicate ok event: returns skip, does not write", async () => {
  const sb = makeMock({
    webhook_events: new Map([
      ["evt_dup", { event_id: "evt_dup", status: "ok" }],
    ]),
  });
  const decision = await checkAndMarkProcessing(
    sb,
    "evt_dup",
    "checkout.session.completed",
  );
  assertEquals(decision.kind, "skip");
  // The ok row must be left untouched (no status flip back to processing).
  assertEquals(sb.store.webhook_events.get("evt_dup")?.status, "ok");
});

Deno.test("idem-T03 — prior status=error: re-processes (status flips back to processing)", async () => {
  const sb = makeMock({
    webhook_events: new Map([
      ["evt_retry", { event_id: "evt_retry", status: "error", retry_count: 1 }],
    ]),
  });
  const decision = await checkAndMarkProcessing(
    sb,
    "evt_retry",
    "checkout.session.completed",
  );
  assertEquals(decision.kind, "process");
  assertEquals(sb.store.webhook_events.get("evt_retry")?.status, "processing");
});

Deno.test("idem-T04 — DB claim error: throws (caller will 500 → Stripe retries)", async () => {
  const sb = makeMock({}, {
    writeError: { table: "webhook_events", message: "connection refused" },
  });
  await assertRejects(
    () => checkAndMarkProcessing(sb, "evt_x", "test.event"),
    Error,
    "webhook_events claim failed",
  );
});

Deno.test("idem-T03b — concurrent sibling already 'processing': returns skip (no double-fire)", async () => {
  // This is the race the atomic claim closes: a second delivery of the same
  // event arrives while the first is still processing. It must NOT also
  // 'process' (which would double-fire referral credit + confirmation email).
  const sb = makeMock({
    webhook_events: new Map([
      ["evt_race", { event_id: "evt_race", status: "processing" }],
    ]),
  });
  const decision = await checkAndMarkProcessing(
    sb,
    "evt_race",
    "checkout.session.completed",
  );
  assertEquals(decision.kind, "skip");
});

// ---- markOk / markError -----------------------------------------------------

Deno.test("idem-T05 — markOk records user_id and status=ok", async () => {
  const sb = makeMock({
    webhook_events: new Map([
      ["evt_ok", { event_id: "evt_ok", status: "processing" }],
    ]),
  });
  await markOk(sb, "evt_ok", "user-uuid-1");
  const row = sb.store.webhook_events.get("evt_ok");
  assertEquals(row?.status, "ok");
  assertEquals(row?.user_id, "user-uuid-1");
});

Deno.test("idem-T06 — markError truncates message and calls increment RPC", async () => {
  const sb = makeMock({
    webhook_events: new Map([
      ["evt_err", { event_id: "evt_err", status: "processing" }],
    ]),
  });
  const longErr = new Error("x".repeat(900));
  await markError(sb, "evt_err", longErr);
  const row = sb.store.webhook_events.get("evt_err");
  assertEquals(row?.status, "error");
  // Truncated to 500 chars.
  assertEquals((row?.error_message as string).length, 500);
  // RPC call recorded.
  const rpcCalls = sb.calls.filter((c) => c.op === "rpc");
  assertEquals(rpcCalls.length, 1);
  assertEquals(rpcCalls[0].table, "increment_webhook_retry_count");
});

// ---- verifyProfileWrite -----------------------------------------------------

Deno.test("idem-T07 — verifyProfileWrite passes when row matches", async () => {
  const sb = makeMock({
    profiles: new Map([
      ["user-1", { id: "user-1", is_pro: true, subscription_tier: "premium" }],
    ]),
  });
  // Should not throw.
  await verifyProfileWrite(sb, "user-1", {
    is_pro: true,
    subscription_tier: "premium",
  });
});

Deno.test("idem-T08 — verifyProfileWrite throws when row missing (Sofia's bug)", async () => {
  const sb = makeMock(); // no profile rows at all
  await assertRejects(
    () => verifyProfileWrite(sb, "user-missing", { is_pro: true }),
    Error,
    "profile write verification FAILED",
  );
});

Deno.test("idem-T09 — verifyProfileWrite throws when is_pro mismatch (silent write loss)", async () => {
  // The mock returns {is_pro: false} regardless because of verifyLies.
  const sb = makeMock({}, { verifyLies: true });
  await assertRejects(
    () => verifyProfileWrite(sb, "user-1", { is_pro: true }),
    Error,
    "is_pro=false expected=true",
  );
});

Deno.test("idem-T10 — verifyProfileWrite throws when tier mismatch", async () => {
  const sb = makeMock({
    profiles: new Map([
      ["user-1", { id: "user-1", is_pro: true, subscription_tier: "basic" }],
    ]),
  });
  await assertRejects(
    () =>
      verifyProfileWrite(sb, "user-1", {
        is_pro: true,
        subscription_tier: "premium",
      }),
    Error,
    "tier=basic expected=premium",
  );
});

// ---- verifySubscriptionWrite ------------------------------------------------

Deno.test("idem-T11 — verifySubscriptionWrite passes when status matches", async () => {
  const sb = makeMock({
    subscriptions: new Map([
      ["user-1", { user_id: "user-1", status: "active" }],
    ]),
  });
  await verifySubscriptionWrite(sb, "user-1", { status: "active" });
});

Deno.test("idem-T12 — verifySubscriptionWrite throws on status mismatch", async () => {
  const sb = makeMock({
    subscriptions: new Map([
      ["user-1", { user_id: "user-1", status: "canceled" }],
    ]),
  });
  await assertRejects(
    () => verifySubscriptionWrite(sb, "user-1", { status: "active" }),
    Error,
    "status=canceled expected=active",
  );
});

// ---- End-to-end idempotency flow --------------------------------------------

Deno.test("idem-T13 — same event_id processed twice: second call is no-op", async () => {
  const sb = makeMock();
  const eventId = "evt_replay";

  // First call
  const d1 = await checkAndMarkProcessing(sb, eventId, "checkout.session.completed");
  assertEquals(d1.kind, "process");
  await markOk(sb, eventId, "user-1");
  assertEquals(sb.store.webhook_events.get(eventId)?.status, "ok");

  // Second call (Stripe retried)
  const d2 = await checkAndMarkProcessing(sb, eventId, "checkout.session.completed");
  assertEquals(d2.kind, "skip");
  // Status remains ok, user_id unchanged.
  const row = sb.store.webhook_events.get(eventId);
  assertEquals(row?.status, "ok");
  assertEquals(row?.user_id, "user-1");
});

Deno.test("idem-T14 — failed write path: verification throws → markError records", async () => {
  const sb = makeMock({}, { verifyLies: true });
  const eventId = "evt_failed_write";

  await checkAndMarkProcessing(sb, eventId, "checkout.session.completed");

  // Caller would do: try { ...write...; verifyProfileWrite(...) } catch (e) { markError }
  let caught: Error | null = null;
  try {
    await verifyProfileWrite(sb, "user-1", { is_pro: true });
  } catch (e) {
    caught = e as Error;
  }
  assert(caught !== null, "expected verification to throw");
  await markError(sb, eventId, caught);

  const row = sb.store.webhook_events.get(eventId);
  assertEquals(row?.status, "error");
  assert(
    (row?.error_message as string).includes("verification FAILED"),
    "error_message should mention verification",
  );
});
