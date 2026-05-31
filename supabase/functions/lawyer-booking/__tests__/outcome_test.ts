// lawyer-booking/__tests__/outcome_test.ts
// -----------------------------------------------------------------------------
// Regression coverage for the op:outcome MONEY path (snapshots a partner-lawyer
// payout into the booking row + flips status='completed'). Uses a fake
// supabase-like client — no network, no Supabase.
//
// Run:
//   deno test --allow-net --allow-env --allow-read \
//     supabase/functions/lawyer-booking/__tests__/outcome_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { handleOutcome } from "../outcome.ts";
import type { ValidatedOutcome } from "../validate.ts";

const LAWYER_ID = "22222222-2222-4222-8222-222222222222";
const OTHER_USER = "33333333-3333-4333-8333-333333333333";
const BOOKING_ID = "11111111-1111-4111-8111-111111111111";

function outcomeBody(): ValidatedOutcome {
  return {
    op: "outcome",
    bookingId: BOOKING_ID,
    outcomeSummary: "Discussed KHO appeal strategy, advised on §150 grounds.",
  };
}

// ─── Fake supabase client ────────────────────────────────────────────────────
//
// Records every from()/select()/eq()/update()/maybeSingle()/rpc() call so a
// test can assert exactly what was written. Each from() returns a chainable
// builder. Reads resolve via `maybeSingle()`; the terminal CAS update resolves
// via `.select(...)` (returns the array of affected rows).

interface BookingRow {
  id: string;
  lawyer_id: string;
  status: string;
  payout_cents: number | null;
}

interface FakeOpts {
  bookingRead: { data: BookingRow | null; error: unknown };
  partnerRead?: { data: { payout_rate_cents: number | null } | null };
  /** Rows the terminal UPDATE ... .select("id") returns. [] = lost CAS race. */
  updateAffected?: Array<{ id: string }>;
  updateError?: unknown;
}

interface RecordedUpdate {
  values: Record<string, unknown>;
  eq: Array<[string, unknown]>;
}

function makeFake(opts: FakeOpts) {
  const recorded = {
    updates: [] as RecordedUpdate[],
    rpcCalls: [] as Array<{ fn: string; args: unknown }>,
  };

  // deno-lint-ignore no-explicit-any
  function from(table: string): any {
    if (table === "lawyer_bookings") {
      let mode: "read" | "update" = "read";
      const upd: RecordedUpdate = { values: {}, eq: [] };
      const builder = {
        // deno-lint-ignore no-explicit-any
        select(_cols?: string): any {
          if (mode === "update") {
            // Terminal CAS update resolves here with affected rows.
            recorded.updates.push(upd);
            return Promise.resolve({
              data: opts.updateError ? null : (opts.updateAffected ?? [{ id: BOOKING_ID }]),
              error: opts.updateError ?? null,
            });
          }
          return builder; // read: chain continues to .eq().maybeSingle()
        },
        // deno-lint-ignore no-explicit-any
        update(values: Record<string, unknown>): any {
          mode = "update";
          upd.values = values;
          return builder;
        },
        // deno-lint-ignore no-explicit-any
        eq(col: string, val: unknown): any {
          if (mode === "update") upd.eq.push([col, val]);
          return builder;
        },
        maybeSingle() {
          return Promise.resolve(opts.bookingRead);
        },
      };
      return builder;
    }
    if (table === "partner_lawyers") {
      const builder = {
        select() {
          return builder;
        },
        eq() {
          return builder;
        },
        maybeSingle() {
          return Promise.resolve(
            opts.partnerRead ?? { data: null },
          );
        },
      };
      return builder;
    }
    throw new Error(`unexpected table: ${table}`);
  }

  function rpc(fn: string, args: unknown) {
    recorded.rpcCalls.push({ fn, args });
    return {
      then(onFulfilled: () => void) {
        onFulfilled();
        return { catch() {} };
      },
    };
  }

  return { client: { from, rpc }, recorded };
}

async function bodyJson(res: Response): Promise<Record<string, unknown>> {
  return (await res.json()) as Record<string, unknown>;
}

// ─── Happy path ──────────────────────────────────────────────────────────────

Deno.test("OUT-OK-01 — completes booking, partner rate wins payout precedence", async () => {
  const { client, recorded } = makeFake({
    bookingRead: {
      data: {
        id: BOOKING_ID,
        lawyer_id: LAWYER_ID,
        status: "confirmed",
        payout_cents: 4000,
      },
      error: null,
    },
    partnerRead: { data: { payout_rate_cents: 5500 } },
  });

  const res = await handleOutcome(client, LAWYER_ID, outcomeBody());
  assertEquals(res.status, 200);
  assertEquals(await bodyJson(res), { ok: true, status: "completed" });

  // One UPDATE, gated on id + the read status (CAS), writes partner rate.
  assertEquals(recorded.updates.length, 1);
  const u = recorded.updates[0];
  assertEquals(u.values.status, "completed");
  assertEquals(u.values.payout_cents, 5500); // partner rate beats booking 4000
  assertEquals(u.values.outcome_summary, outcomeBody().outcomeSummary);
  assert(typeof u.values.outcome_at === "string");
  // CAS preconditions: both id AND the read status.
  assertEquals(u.eq, [["id", BOOKING_ID], ["status", "confirmed"]]);
  // Stats refresh fired once.
  assertEquals(recorded.rpcCalls.length, 1);
  assertEquals(recorded.rpcCalls[0].fn, "refresh_partner_lawyer_stats");
});

Deno.test("OUT-OK-02 — payout falls back to booking.payout_cents when no partner rate", async () => {
  const { client, recorded } = makeFake({
    bookingRead: {
      data: {
        id: BOOKING_ID,
        lawyer_id: LAWYER_ID,
        status: "assigned",
        payout_cents: 3300,
      },
      error: null,
    },
    partnerRead: { data: { payout_rate_cents: null } },
  });

  const res = await handleOutcome(client, LAWYER_ID, outcomeBody());
  assertEquals(res.status, 200);
  assertEquals(recorded.updates[0].values.payout_cents, 3300);
  // CAS gated on the 'assigned' read status.
  assertEquals(recorded.updates[0].eq, [["id", BOOKING_ID], ["status", "assigned"]]);
});

Deno.test("OUT-OK-03 — payout defaults to 2500 when neither partner nor booking carry a rate", async () => {
  const { client, recorded } = makeFake({
    bookingRead: {
      data: {
        id: BOOKING_ID,
        lawyer_id: LAWYER_ID,
        status: "confirmed",
        payout_cents: null,
      },
      error: null,
    },
    partnerRead: { data: null },
  });

  const res = await handleOutcome(client, LAWYER_ID, outcomeBody());
  assertEquals(res.status, 200);
  assertEquals(recorded.updates[0].values.payout_cents, 2500);
});

// ─── Error / guard paths ─────────────────────────────────────────────────────

Deno.test("OUT-ERR-01 — 500 on booking read error, no write", async () => {
  const { client, recorded } = makeFake({
    bookingRead: { data: null, error: { message: "db down" } },
  });
  const res = await handleOutcome(client, LAWYER_ID, outcomeBody());
  assertEquals(res.status, 500);
  assertEquals((await bodyJson(res)).reason, "read_failed");
  assertEquals(recorded.updates.length, 0);
});

Deno.test("OUT-ERR-02 — 404 when booking not found, no write", async () => {
  const { client, recorded } = makeFake({
    bookingRead: { data: null, error: null },
  });
  const res = await handleOutcome(client, LAWYER_ID, outcomeBody());
  assertEquals(res.status, 404);
  assertEquals((await bodyJson(res)).reason, "not_found");
  assertEquals(recorded.updates.length, 0);
});

Deno.test("OUT-ERR-03 — 403 when caller is not the assigned lawyer, no payout", async () => {
  const { client, recorded } = makeFake({
    bookingRead: {
      data: {
        id: BOOKING_ID,
        lawyer_id: LAWYER_ID,
        status: "confirmed",
        payout_cents: 2500,
      },
      error: null,
    },
  });
  const res = await handleOutcome(client, OTHER_USER, outcomeBody());
  assertEquals(res.status, 403);
  assertEquals((await bodyJson(res)).reason, "not_assigned");
  assertEquals(recorded.updates.length, 0);
});

Deno.test("OUT-ERR-04 — 409 already_completed (idempotency), no double payout", async () => {
  const { client, recorded } = makeFake({
    bookingRead: {
      data: {
        id: BOOKING_ID,
        lawyer_id: LAWYER_ID,
        status: "completed",
        payout_cents: 5500,
      },
      error: null,
    },
  });
  const res = await handleOutcome(client, LAWYER_ID, outcomeBody());
  assertEquals(res.status, 409);
  const b = await bodyJson(res);
  assertEquals(b.reason, "already_completed");
  assertEquals(b.state, "completed");
  assertEquals(recorded.updates.length, 0);
});

Deno.test("OUT-ERR-05 — 409 bad_state when booking is still pending", async () => {
  const { client, recorded } = makeFake({
    bookingRead: {
      data: {
        id: BOOKING_ID,
        lawyer_id: LAWYER_ID,
        status: "pending",
        payout_cents: null,
      },
      error: null,
    },
  });
  const res = await handleOutcome(client, LAWYER_ID, outcomeBody());
  assertEquals(res.status, 409);
  const b = await bodyJson(res);
  assertEquals(b.reason, "bad_state");
  assertEquals(b.state, "pending");
  assertEquals(recorded.updates.length, 0);
});

// ─── The NEW CAS guard: concurrent double-submit ─────────────────────────────

Deno.test("OUT-CAS-01 — UPDATE affects 0 rows (lost race) → 409 already_completed, no double payout", async () => {
  // Both reads pass (row was 'confirmed' at read time), but a concurrent
  // submit already flipped status='completed', so the CAS .eq("status",...)
  // matches nothing. The handler must NOT report success.
  const { client, recorded } = makeFake({
    bookingRead: {
      data: {
        id: BOOKING_ID,
        lawyer_id: LAWYER_ID,
        status: "confirmed",
        payout_cents: 4000,
      },
      error: null,
    },
    partnerRead: { data: { payout_rate_cents: 5500 } },
    updateAffected: [], // CAS matched nothing — we lost the race
  });

  const res = await handleOutcome(client, LAWYER_ID, outcomeBody());
  assertEquals(res.status, 409);
  const b = await bodyJson(res);
  assertEquals(b.reason, "already_completed");
  // The UPDATE statement was issued (CAS attempt), but affected 0 rows, so no
  // stats refresh / no payout was recorded by THIS request.
  assertEquals(recorded.updates.length, 1);
  assertEquals(recorded.rpcCalls.length, 0);
});

Deno.test("OUT-ERR-06 — 500 when terminal UPDATE errors", async () => {
  const { client, recorded } = makeFake({
    bookingRead: {
      data: {
        id: BOOKING_ID,
        lawyer_id: LAWYER_ID,
        status: "confirmed",
        payout_cents: 2500,
      },
      error: null,
    },
    partnerRead: { data: { payout_rate_cents: 5500 } },
    updateError: { message: "constraint violation" },
  });
  const res = await handleOutcome(client, LAWYER_ID, outcomeBody());
  assertEquals(res.status, 500);
  assertEquals((await bodyJson(res)).reason, "update_failed");
  assertEquals(recorded.rpcCalls.length, 0);
});
