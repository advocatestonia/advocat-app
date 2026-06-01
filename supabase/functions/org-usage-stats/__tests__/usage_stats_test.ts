// org-usage-stats/__tests__/usage_stats_test.ts
// -----------------------------------------------------------------------------
// Pure-logic tests:
//   * resolvePeriod — range derivation + custom-range validation/caps
//   * countApiCalls — queries the REAL columns of org_api_rate_counters
//     (api_key_id / bucket_date / request_count), resolved via the org's
//     api keys. Regression for the silent fail-to-zero bug where it queried
//     non-existent org_id / day / count columns.
//
// Run:
//   deno test --allow-net --allow-env --allow-read \
//     supabase/functions/org-usage-stats/__tests__/usage_stats_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { countApiCalls, resolvePeriod } from "../index.ts";

// ─── resolvePeriod ───────────────────────────────────────────────────────

Deno.test("PERIOD-01 — current_month returns a valid range", () => {
  const r = resolvePeriod("current_month", null, null);
  assert(r !== null);
  assert(r!.start <= r!.end);
  assertEquals(r!.start.getUTCDate(), 1);
});

Deno.test("PERIOD-02 — custom without from/to is invalid", () => {
  assertEquals(resolvePeriod("custom", null, null), null);
  assertEquals(resolvePeriod("custom", "2026-01-01T00:00:00Z", null), null);
});

Deno.test("PERIOD-03 — custom with start>end is invalid", () => {
  const r = resolvePeriod(
    "custom",
    "2026-02-01T00:00:00Z",
    "2026-01-01T00:00:00Z",
  );
  assertEquals(r, null);
});

Deno.test("PERIOD-04 — custom range >366d is rejected", () => {
  const r = resolvePeriod(
    "custom",
    "2025-01-01T00:00:00Z",
    "2026-06-01T00:00:00Z",
  );
  assertEquals(r, null);
});

Deno.test("PERIOD-05 — valid custom range is accepted", () => {
  const r = resolvePeriod(
    "custom",
    "2026-01-01T00:00:00Z",
    "2026-03-01T00:00:00Z",
  );
  assert(r !== null);
  assertEquals(r!.start.toISOString(), "2026-01-01T00:00:00.000Z");
});

Deno.test("PERIOD-06 — garbage dates rejected", () => {
  assertEquals(resolvePeriod("custom", "not-a-date", "also-bad"), null);
});

// ─── countApiCalls ─────────────────────────────────────────────────────

const ORG = "11111111-1111-1111-1111-111111111111";

/** Minimal fake recording every table/column touched, so the test fails
 *  loudly if the query reverts to the phantom org_id/day/count columns. */
function makeFake(opts: {
  keyRows?: Array<{ id: string }>;
  counterRows?: Array<{ request_count: number }>;
  keysErr?: { message: string } | null;
  counterErr?: { message: string } | null;
}) {
  const calls: Record<string, unknown>[] = [];
  return {
    calls,
    from(table: string) {
      const rec: Record<string, unknown> = { table };
      calls.push(rec);
      const builder = {
        select(cols: string) {
          rec.select = cols;
          return builder;
        },
        eq(col: string, val: unknown) {
          rec[`eq_${col}`] = val;
          return builder;
        },
        in(col: string, vals: unknown) {
          rec[`in_${col}`] = vals;
          return builder;
        },
        gte(col: string, val: unknown) {
          rec[`gte_${col}`] = val;
          return builder;
        },
        lte(col: string, val: unknown) {
          rec[`lte_${col}`] = val;
          // Terminal on the counters query → return the promise shape.
          if (table === "org_api_rate_counters") {
            return Promise.resolve({
              data: opts.counterRows ?? [],
              error: opts.counterErr ?? null,
            });
          }
          return builder;
        },
        then(
          // org_api_keys query is awaited directly after .eq()
          resolve: (v: { data: unknown; error: unknown }) => unknown,
        ) {
          return Promise.resolve({
            data: opts.keyRows ?? [],
            error: opts.keysErr ?? null,
          }).then(resolve);
        },
      };
      return builder;
    },
  };
}

Deno.test("API-01 — sums request_count over the org's keys", async () => {
  const fake = makeFake({
    keyRows: [{ id: "k1" }, { id: "k2" }],
    counterRows: [{ request_count: 3 }, { request_count: 7 }, { request_count: 1 }],
  });
  const start = new Date("2026-05-01T00:00:00Z");
  const end = new Date("2026-05-31T00:00:00Z");
  const total = await countApiCalls(fake, ORG, start, end);
  assertEquals(total, 11);

  // Assert the REAL columns/tables were used — guards the phantom-column regression.
  const keyQuery = fake.calls.find((c) => c.table === "org_api_keys")!;
  assertEquals(keyQuery.eq_org_id, ORG);
  const counterQuery = fake.calls.find((c) => c.table === "org_api_rate_counters")!;
  assertEquals(counterQuery.select, "request_count");
  assertEquals(counterQuery.in_api_key_id, ["k1", "k2"]);
  assertEquals(counterQuery.gte_bucket_date, "2026-05-01");
  assertEquals(counterQuery.lte_bucket_date, "2026-05-31");
});

Deno.test("API-02 — org with no keys returns 0 without touching counters", async () => {
  const fake = makeFake({ keyRows: [] });
  const total = await countApiCalls(
    fake,
    ORG,
    new Date("2026-05-01T00:00:00Z"),
    new Date("2026-05-31T00:00:00Z"),
  );
  assertEquals(total, 0);
  assert(!fake.calls.some((c) => c.table === "org_api_rate_counters"));
});

Deno.test("API-03 — keys lookup error fails to 0", async () => {
  const fake = makeFake({ keysErr: { message: "boom" } });
  const total = await countApiCalls(
    fake,
    ORG,
    new Date("2026-05-01T00:00:00Z"),
    new Date("2026-05-31T00:00:00Z"),
  );
  assertEquals(total, 0);
});

Deno.test("API-04 — counter query error fails to 0", async () => {
  const fake = makeFake({
    keyRows: [{ id: "k1" }],
    counterErr: { message: "boom" },
  });
  const total = await countApiCalls(
    fake,
    ORG,
    new Date("2026-05-01T00:00:00Z"),
    new Date("2026-05-31T00:00:00Z"),
  );
  assertEquals(total, 0);
});
