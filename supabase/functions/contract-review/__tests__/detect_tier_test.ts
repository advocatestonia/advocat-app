// Tests for contract-review detectTier — subscription tier resolution.
// -----------------------------------------------------------------------------
// Regression guard for the `.select("plan")` bug: `subscriptions` stores the
// plan in column `tier`, not `plan`. The old read always returned undefined,
// silently downgrading premium (Pro) subscribers to the basic 5/30d cap
// instead of 20/30d. These tests exercise the real DB-read path that the
// quota_enforcement tests skip (they inject `tier` directly).

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { detectTier } from "../handler.ts";

// detectTier issues one read:
//   subscriptions: .select().eq().in().order().limit().maybeSingle()
// deno-lint-ignore no-explicit-any
function fakeSb(opts: {
  // `subscriptions.tier`: "free" | "basic" | "premium". undefined => no row.
  tier?: string;
  periodEnd?: string | null; // defaults far-future; pass past to lapse.
  throwOnQuery?: boolean;
}): any {
  const farFuture = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
    .toISOString();
  const data = opts.tier === undefined ? null : {
    status: "active",
    tier: opts.tier,
    current_period_end: opts.periodEnd === undefined
      ? farFuture
      : opts.periodEnd,
  };
  return {
    from() {
      return {
        select: () => ({
          eq: () => ({
            in: () => ({
              order: () => ({
                limit: () => ({
                  maybeSingle: () => {
                    if (opts.throwOnQuery) throw new Error("db down");
                    return Promise.resolve({ data, error: null });
                  },
                }),
              }),
            }),
          }),
        }),
      };
    },
  };
}

Deno.test("detectTier: premium → premium (was silently downgraded to basic)", async () => {
  const sb = fakeSb({ tier: "premium" });
  assertEquals(await detectTier(sb, "u1"), "premium");
});

Deno.test("detectTier: basic → basic", async () => {
  const sb = fakeSb({ tier: "basic" });
  assertEquals(await detectTier(sb, "u1"), "basic");
});

Deno.test("detectTier: no active subscription → free", async () => {
  const sb = fakeSb({});
  assertEquals(await detectTier(sb, "u1"), "free");
});

Deno.test("detectTier: unknown/legacy tier on active row → basic (paid floor)", async () => {
  const sb = fakeSb({ tier: "legacy_founder" });
  assertEquals(await detectTier(sb, "u1"), "basic");
});

Deno.test("detectTier: lapsed period (status active, expired) → free", async () => {
  const sb = fakeSb({
    tier: "premium",
    periodEnd: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(),
  });
  assertEquals(await detectTier(sb, "u1"), "free");
});

Deno.test("detectTier: null period end (legacy/lifetime row) → keeps tier", async () => {
  const sb = fakeSb({ tier: "premium", periodEnd: null });
  assertEquals(await detectTier(sb, "u1"), "premium");
});

Deno.test("detectTier: DB throws → free (fail-open is acceptable; under-grants)", async () => {
  // A backend blip resolves to free rather than crashing the review request.
  // This under-grants (denies a paid feature) rather than over-grants, which
  // is the safe direction for a quota gate.
  const sb = fakeSb({ throwOnQuery: true });
  assertEquals(await detectTier(sb, "u1"), "free");
});
