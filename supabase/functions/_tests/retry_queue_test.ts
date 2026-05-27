// retry_queue_test.ts
// -----------------------------------------------------------------------------
// Unit tests for the email_triage_queue retry / DLQ mechanics.
//
// These tests exercise the LOGIC contract — enqueue → claim → complete with
// exponential backoff and dead-letter transition — through a fake Supabase
// client that emulates the SECURITY DEFINER RPCs in memory. They cover the
// state-machine assertions that matter for production correctness:
//
//   T01 — enqueue creates a pending row with attempts=0
//   T02 — enqueue is idempotent on the same thread (open row reused)
//   T03 — claim returns rows with status=in_progress + attempts incremented
//   T04 — claim respects batch_size cap
//   T05 — complete(done) → terminal status='done'
//   T06 — complete(retry) → backoff 2^attempts * 60 s, capped at 3600 s
//   T07 — complete(retry) when attempts >= max → dead_letter
//   T08 — complete(dead_letter) overrides everything → terminal failure
//   T09 — claim_next_triage skips rows with next_retry_at > now()
//   T10 — concurrent claim simulation (skip-locked) → no double-claim
//
// Run with:
//   deno test --allow-env --allow-read --allow-net=esm.sh,deno.land \
//     supabase/functions/_tests/retry_queue_test.ts
// -----------------------------------------------------------------------------

import {
  assertEquals,
  assert,
  assertExists,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

// In-memory queue row shape mirroring app.email_triage_queue.
interface QueueRow {
  id: string;
  thread_id: string;
  user_id: string;
  payload: Record<string, unknown>;
  attempts: number;
  max_attempts: number;
  next_retry_at: number; // ms since epoch (we manipulate the clock)
  last_error: string | null;
  dead_letter_at: number | null;
  status: "pending" | "in_progress" | "done" | "dead_letter";
  trace_id: string | null;
  created_at: number;
  updated_at: number;
}

// deno-lint-ignore no-explicit-any
type RpcResult = { data: any; error: any };

interface FakeSb {
  rows: Map<string, QueueRow>;
  rpc: (name: string, params: Record<string, unknown>) => Promise<RpcResult>;
}

/** Minimal fake SB exposing rpc() with the four queue RPCs. */
function makeFakeSb(opts: { now: () => number; maxAttempts?: number }): FakeSb {
  const rows = new Map<string, QueueRow>();
  const byThread = new Map<string, string>(); // open row id by thread_id
  const max = opts.maxAttempts ?? 5;

  function uuid(): string {
    return crypto.randomUUID();
  }

  function delaySeconds(attempts: number): number {
    return Math.min(60 * Math.pow(2, attempts), 3600);
  }

  return {
    rows, // exposed for assertions
    rpc: async (name: string, params: Record<string, unknown>): Promise<RpcResult> => {
      const now = opts.now();
      if (name === "enqueue_triage") {
        const threadId = params.p_thread_id as string;
        const existing = byThread.get(threadId);
        if (existing) {
          const row = rows.get(existing)!;
          if (row.status === "pending" || row.status === "in_progress") {
            row.next_retry_at = Math.min(row.next_retry_at, now);
            row.trace_id = (params.p_trace_id as string) ?? row.trace_id;
            row.updated_at = now;
            return { data: row.id, error: null };
          }
        }
        const id = uuid();
        const row: QueueRow = {
          id,
          thread_id: threadId,
          user_id: params.p_user_id as string,
          payload: (params.p_payload as Record<string, unknown>) ?? {},
          attempts: 0,
          max_attempts: max,
          next_retry_at: now,
          last_error: null,
          dead_letter_at: null,
          status: "pending",
          trace_id: (params.p_trace_id as string) ?? null,
          created_at: now,
          updated_at: now,
        };
        rows.set(id, row);
        byThread.set(threadId, id);
        return { data: id, error: null };
      }
      if (name === "claim_next_triage") {
        const batch = (params.p_batch_size as number) ?? 10;
        const ready: QueueRow[] = [];
        for (const r of rows.values()) {
          if (r.status === "pending" && r.next_retry_at <= now) {
            ready.push(r);
          }
        }
        ready.sort((a, b) => a.next_retry_at - b.next_retry_at);
        const claimed = ready.slice(0, batch);
        for (const r of claimed) {
          r.status = "in_progress";
          r.attempts += 1;
          r.updated_at = now;
        }
        return {
          data: claimed.map((r) => ({
            id: r.id,
            thread_id: r.thread_id,
            user_id: r.user_id,
            payload: r.payload,
            attempts: r.attempts,
            max_attempts: r.max_attempts,
            trace_id: r.trace_id,
          })),
          error: null,
        };
      }
      if (name === "complete_triage") {
        const id = params.p_id as string;
        const outcome = params.p_outcome as "done" | "retry" | "dead_letter";
        const err = (params.p_error as string | null) ?? null;
        const row = rows.get(id);
        if (!row) return { data: null, error: null };

        if (outcome === "done") {
          row.status = "done";
          row.next_retry_at = now;
        } else if (outcome === "dead_letter" || row.attempts >= row.max_attempts) {
          row.status = "dead_letter";
          row.dead_letter_at = now;
          row.next_retry_at = now;
        } else {
          row.status = "pending";
          row.next_retry_at = now + delaySeconds(row.attempts) * 1000;
        }
        if (err) row.last_error = err;
        row.updated_at = now;
        // Free the open-row slot if terminal.
        if (row.status === "done" || row.status === "dead_letter") {
          byThread.delete(row.thread_id);
        }
        return {
          data: [{
            id: row.id,
            status: row.status,
            attempts: row.attempts,
            next_retry_at: new Date(row.next_retry_at).toISOString(),
          }],
          error: null,
        };
      }
      return { data: null, error: { message: `unknown rpc ${name}` } };
    },
  };
}

// -----------------------------------------------------------------------------
// T01 — enqueue creates a pending row with attempts=0
// -----------------------------------------------------------------------------
Deno.test("T01 — enqueue_triage creates pending row attempts=0", async () => {
  const now = 1_700_000_000_000;
  const sb = makeFakeSb({ now: () => now });
  const { data: id, error } = await sb.rpc("enqueue_triage", {
    p_thread_id: "thread-1",
    p_user_id: "user-1",
    p_payload: { foo: "bar" },
    p_trace_id: null,
  });
  assertEquals(error, null);
  assertExists(id);
  const row = sb.rows.get(id)!;
  assertEquals(row.status, "pending");
  assertEquals(row.attempts, 0);
  assertEquals(row.thread_id, "thread-1");
  assertEquals(row.next_retry_at, now);
});

// -----------------------------------------------------------------------------
// T02 — enqueue is idempotent on the same thread_id (open row reused)
// -----------------------------------------------------------------------------
Deno.test("T02 — enqueue same thread twice keeps one open row", async () => {
  const now = 1_700_000_000_000;
  const sb = makeFakeSb({ now: () => now });
  const { data: id1 } = await sb.rpc("enqueue_triage", {
    p_thread_id: "thread-X",
    p_user_id: "user-1",
    p_payload: {},
    p_trace_id: null,
  });
  const { data: id2 } = await sb.rpc("enqueue_triage", {
    p_thread_id: "thread-X",
    p_user_id: "user-1",
    p_payload: {},
    p_trace_id: null,
  });
  assertEquals(id1, id2);
  assertEquals(sb.rows.size, 1);
});

// -----------------------------------------------------------------------------
// T03 — claim_next_triage flips status + bumps attempts
// -----------------------------------------------------------------------------
Deno.test("T03 — claim flips status to in_progress and bumps attempts", async () => {
  const now = 1_700_000_000_000;
  const sb = makeFakeSb({ now: () => now });
  await sb.rpc("enqueue_triage", {
    p_thread_id: "T",
    p_user_id: "u",
    p_payload: {},
    p_trace_id: null,
  });
  const { data: claimed } = await sb.rpc("claim_next_triage", {
    p_worker_id: "w",
    p_batch_size: 10,
  });
  assertEquals(claimed.length, 1);
  assertEquals(claimed[0].attempts, 1);
  // Underlying row flipped.
  const row = sb.rows.get(claimed[0].id)!;
  assertEquals(row.status, "in_progress");
});

// -----------------------------------------------------------------------------
// T04 — claim respects batch_size cap
// -----------------------------------------------------------------------------
Deno.test("T04 — claim_next_triage caps result at batch_size", async () => {
  const now = 1_700_000_000_000;
  const sb = makeFakeSb({ now: () => now });
  for (let i = 0; i < 15; i++) {
    await sb.rpc("enqueue_triage", {
      p_thread_id: `t${i}`,
      p_user_id: "u",
      p_payload: {},
      p_trace_id: null,
    });
  }
  const { data } = await sb.rpc("claim_next_triage", {
    p_worker_id: "w",
    p_batch_size: 5,
  });
  assertEquals(data.length, 5);
});

// -----------------------------------------------------------------------------
// T05 — complete(done) → terminal status='done'
// -----------------------------------------------------------------------------
Deno.test("T05 — complete done → terminal", async () => {
  const now = 1_700_000_000_000;
  const sb = makeFakeSb({ now: () => now });
  const { data: id } = await sb.rpc("enqueue_triage", {
    p_thread_id: "T",
    p_user_id: "u",
    p_payload: {},
    p_trace_id: null,
  });
  await sb.rpc("claim_next_triage", {
    p_worker_id: "w",
    p_batch_size: 10,
  });
  const { data: result } = await sb.rpc("complete_triage", {
    p_id: id,
    p_outcome: "done",
    p_error: null,
  });
  assertEquals(result[0].status, "done");
  // Re-enqueue should now create a NEW row (open slot freed).
  const { data: id2 } = await sb.rpc("enqueue_triage", {
    p_thread_id: "T",
    p_user_id: "u",
    p_payload: {},
    p_trace_id: null,
  });
  assert(id2 !== id, "expected new id after done");
});

// -----------------------------------------------------------------------------
// T06 — complete(retry) → exponential backoff 2^attempts * 60s, capped 3600s
// -----------------------------------------------------------------------------
Deno.test("T06 — retry backoff follows 2^attempts * 60s capped at 3600s", async () => {
  let now = 1_700_000_000_000;
  const sb = makeFakeSb({ now: () => now, maxAttempts: 20 });
  await sb.rpc("enqueue_triage", {
    p_thread_id: "T",
    p_user_id: "u",
    p_payload: {},
    p_trace_id: null,
  });
  const { data: claimed } = await sb.rpc("claim_next_triage", {
    p_worker_id: "w",
    p_batch_size: 10,
  });
  const id = claimed[0].id;
  // attempts=1 (incremented by claim) → delay = 60 * 2^1 = 120 s
  await sb.rpc("complete_triage", {
    p_id: id,
    p_outcome: "retry",
    p_error: "529",
  });
  const row1 = sb.rows.get(id)!;
  assertEquals(row1.next_retry_at - now, 120 * 1000, "attempts=1 → 120s");

  // Bump attempts to 6 to verify cap.
  row1.attempts = 6;
  row1.status = "in_progress";
  now += 200_000;
  await sb.rpc("complete_triage", {
    p_id: id,
    p_outcome: "retry",
    p_error: null,
  });
  const fresh = sb.rows.get(id)!;
  // attempts=6 → 60*64=3840 → capped to 3600
  assertEquals(fresh.next_retry_at - now, 3600 * 1000, "cap at 3600s");
});

// -----------------------------------------------------------------------------
// T07 — complete(retry) when attempts >= max → dead_letter
// -----------------------------------------------------------------------------
Deno.test("T07 — exhausted attempts → dead_letter on next retry", async () => {
  let now = 1_700_000_000_000;
  const sb = makeFakeSb({ now: () => now, maxAttempts: 3 });
  const { data: id } = await sb.rpc("enqueue_triage", {
    p_thread_id: "T",
    p_user_id: "u",
    p_payload: {},
    p_trace_id: null,
  });
  // Three claims + retries → attempts hits 3 (== max_attempts).
  for (let i = 0; i < 3; i++) {
    // Force-clear the backoff so the next claim is ready (production
    // would wait the exponential interval).
    const r = sb.rows.get(id)!;
    r.next_retry_at = now;
    const { data: c } = await sb.rpc("claim_next_triage", {
      p_worker_id: "w",
      p_batch_size: 10,
    });
    assertEquals(c.length, 1, `iter ${i} should claim 1 row`);
    await sb.rpc("complete_triage", {
      p_id: c[0].id,
      p_outcome: "retry",
      p_error: "503",
    });
    now += 1_000;
  }
  // After the third retry, attempts >= max_attempts → status='dead_letter'.
  const row = sb.rows.get(id)!;
  assertEquals(row.status, "dead_letter");
  assertExists(row.dead_letter_at);
  assertEquals(row.last_error, "503");
});

// -----------------------------------------------------------------------------
// T08 — complete(dead_letter) forces terminal failure regardless of attempts
// -----------------------------------------------------------------------------
Deno.test("T08 — complete dead_letter forces terminal failure", async () => {
  const now = 1_700_000_000_000;
  const sb = makeFakeSb({ now: () => now });
  await sb.rpc("enqueue_triage", {
    p_thread_id: "T",
    p_user_id: "u",
    p_payload: {},
    p_trace_id: null,
  });
  const { data: claimed } = await sb.rpc("claim_next_triage", {
    p_worker_id: "w",
    p_batch_size: 10,
  });
  await sb.rpc("complete_triage", {
    p_id: claimed[0].id,
    p_outcome: "dead_letter",
    p_error: "400 bad request",
  });
  const row = sb.rows.get(claimed[0].id)!;
  assertEquals(row.status, "dead_letter");
  assertEquals(row.last_error, "400 bad request");
});

// -----------------------------------------------------------------------------
// T09 — claim skips rows with next_retry_at > now()
// -----------------------------------------------------------------------------
Deno.test("T09 — claim_next_triage skips rows not yet ready", async () => {
  let now = 1_700_000_000_000;
  const sb = makeFakeSb({ now: () => now });
  await sb.rpc("enqueue_triage", {
    p_thread_id: "T1",
    p_user_id: "u",
    p_payload: {},
    p_trace_id: null,
  });
  const { data: c1 } = await sb.rpc("claim_next_triage", {
    p_worker_id: "w",
    p_batch_size: 10,
  });
  await sb.rpc("complete_triage", {
    p_id: c1[0].id,
    p_outcome: "retry",
    p_error: "5xx",
  });
  // Right after retry, next_retry_at is in the future → claim returns 0.
  const { data: c2 } = await sb.rpc("claim_next_triage", {
    p_worker_id: "w",
    p_batch_size: 10,
  });
  assertEquals(c2.length, 0);
  // Advance clock past the backoff.
  now += 200 * 1000;
  const { data: c3 } = await sb.rpc("claim_next_triage", {
    p_worker_id: "w",
    p_batch_size: 10,
  });
  assertEquals(c3.length, 1);
});

// -----------------------------------------------------------------------------
// T10 — concurrent claim simulation: two workers, no double-claim
// -----------------------------------------------------------------------------
Deno.test("T10 — concurrent claim — each row claimed exactly once", async () => {
  const now = 1_700_000_000_000;
  const sb = makeFakeSb({ now: () => now });
  for (let i = 0; i < 5; i++) {
    await sb.rpc("enqueue_triage", {
      p_thread_id: `t${i}`,
      p_user_id: "u",
      p_payload: {},
      p_trace_id: null,
    });
  }
  // Two parallel claim calls; the fake serialises via Map ops but the
  // contract is "in_progress rows don't satisfy the ready filter".
  const [a, b] = await Promise.all([
    sb.rpc("claim_next_triage", { p_worker_id: "wa", p_batch_size: 3 }),
    sb.rpc("claim_next_triage", { p_worker_id: "wb", p_batch_size: 3 }),
  ]);
  const all = [...a.data, ...b.data].map((r: { id: string }) => r.id);
  const unique = new Set(all);
  assertEquals(all.length, unique.size, "no row appears in both claim sets");
  // 5 rows total, batch 3+3 → 5 claimed (3 + 2).
  assertEquals(all.length, 5);
});
