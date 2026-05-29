// Tests for check-ai-quota — plan detection (entitlement expiry guard) +
// payload shaping. The serve() handler itself is an integration surface that
// needs a live JWT + DB; the testable logic lives in the exported helpers
// detectPlan() and buildPayload().

import {
  assert,
  assertEquals,
  assertRejects,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { buildPayload, detectPlan } from "../index.ts";

// ─── Fake supabase client ─────────────────────────────────────────────────
// detectPlan issues two reads:
//   subscriptions: .select().eq().in().limit().maybeSingle()
//   profiles:      .select().eq().maybeSingle()
// deno-lint-ignore no-explicit-any
function fakeSb(opts: {
  // subscriptions row. `subStatus` undefined => no active row (null data).
  subStatus?: string;
  // ISO string for current_period_end; defaults far-future. Pass a past date
  // to exercise the lapse-to-free path. Pass null for legacy/lifetime rows.
  periodEnd?: string | null;
  subError?: { code?: string; message: string };
  // profiles.is_pro fallback.
  isPro?: boolean;
  profError?: { code?: string; message: string };
}): any {
  const farFuture = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
    .toISOString();
  const subData = opts.subStatus === undefined ? null : {
    status: opts.subStatus,
    current_period_end: opts.periodEnd === undefined
      ? farFuture
      : opts.periodEnd,
  };
  const profData = opts.isPro === undefined ? null : { is_pro: opts.isPro };
  return {
    from(table: string) {
      if (table === "subscriptions") {
        return {
          select: () => ({
            eq: () => ({
              in: () => ({
                limit: () => ({
                  maybeSingle: () =>
                    Promise.resolve({
                      data: subData,
                      error: opts.subError ?? null,
                    }),
                }),
              }),
            }),
          }),
        };
      }
      if (table === "profiles") {
        return {
          select: () => ({
            eq: () => ({
              maybeSingle: () =>
                Promise.resolve({
                  data: profData,
                  error: opts.profError ?? null,
                }),
            }),
          }),
        };
      }
      throw new Error(`unexpected table ${table}`);
    },
  };
}

// ─── detectPlan ─────────────────────────────────────────────────────────────

Deno.test("detectPlan: active sub with future period → pro", async () => {
  const sb = fakeSb({ subStatus: "active" });
  assertEquals(await detectPlan(sb, "u1"), "pro");
});

Deno.test("detectPlan: trialing sub with future period → pro", async () => {
  const sb = fakeSb({ subStatus: "trialing" });
  assertEquals(await detectPlan(sb, "u1"), "pro");
});

Deno.test("detectPlan: no sub, no profile → free", async () => {
  const sb = fakeSb({});
  assertEquals(await detectPlan(sb, "u1"), "free");
});

Deno.test("detectPlan: null period end (lifetime row) → still pro", async () => {
  const sb = fakeSb({ subStatus: "active", periodEnd: null });
  assertEquals(await detectPlan(sb, "u1"), "pro");
});

Deno.test("detectPlan: lapsed period (status active, expired) → falls back, free", async () => {
  // The money-leak regression: Apple IAP has no expiry webhook in prod, so a
  // cancelled/refunded sub can read status='active' with a past period end.
  // Must NOT grant perpetual Pro. With no profiles.is_pro fallback → free.
  const sb = fakeSb({
    subStatus: "active",
    periodEnd: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(),
  });
  assertEquals(await detectPlan(sb, "u1"), "free");
});

Deno.test("detectPlan: lapsed sub but profiles.is_pro=true → pro via fallback", async () => {
  // A lapsed subscription must still honour a legacy profiles.is_pro grant.
  const sb = fakeSb({
    subStatus: "active",
    periodEnd: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(),
    isPro: true,
  });
  assertEquals(await detectPlan(sb, "u1"), "pro");
});

Deno.test("detectPlan: no sub but profiles.is_pro=true → pro", async () => {
  const sb = fakeSb({ isPro: true });
  assertEquals(await detectPlan(sb, "u1"), "pro");
});

Deno.test("detectPlan: no sub, profiles.is_pro=false → free", async () => {
  const sb = fakeSb({ isPro: false });
  assertEquals(await detectPlan(sb, "u1"), "free");
});

Deno.test("detectPlan: PGRST116 (no rows) on subscriptions is not an error", async () => {
  // maybeSingle() surfaces zero-rows as PGRST116; that must resolve to free,
  // not throw a 503.
  const sb = fakeSb({ subError: { code: "PGRST116", message: "no rows" } });
  assertEquals(await detectPlan(sb, "u1"), "free");
});

Deno.test("detectPlan: real subscriptions backend error → throws (loud 503)", async () => {
  // A non-PGRST116 error must propagate so the handler returns 503 rather
  // than silently granting free during a DB outage / RLS misconfig.
  const sb = fakeSb({
    subError: { code: "42501", message: "permission denied" },
  });
  await assertRejects(
    () => detectPlan(sb, "u1"),
    Error,
    "subscriptions lookup",
  );
});

Deno.test("detectPlan: real profiles backend error → throws", async () => {
  const sb = fakeSb({
    profError: { code: "42501", message: "permission denied" },
  });
  await assertRejects(
    () => detectPlan(sb, "u1"),
    Error,
    "profiles lookup",
  );
});

// ─── buildPayload ─────────────────────────────────────────────────────────

Deno.test("buildPayload: free under cap → remaining counts down", () => {
  const p = buildPayload({ plan: "free", used: 5, limit: 25, allowed: true });
  assertEquals(p.allowed, true);
  assertEquals(p.remaining, 20);
  assertEquals(p.limit, 25);
  assertEquals(p.used, 5);
  assertEquals(p.plan, "free");
  assertEquals(p.unlimited, false);
  assert(typeof p.resetAt === "string");
});

Deno.test("buildPayload: free at cap → remaining 0", () => {
  const p = buildPayload({ plan: "free", used: 25, limit: 25, allowed: false });
  assertEquals(p.allowed, false);
  assertEquals(p.remaining, 0);
});

Deno.test("buildPayload: free over cap → remaining clamped at 0, never negative", () => {
  const p = buildPayload({ plan: "free", used: 30, limit: 25, allowed: false });
  assertEquals(p.remaining, 0);
});

Deno.test("buildPayload: pro (limit -1) → unlimited, remaining null", () => {
  const p = buildPayload({ plan: "pro", used: 0, limit: -1, allowed: true });
  assertEquals(p.unlimited, true);
  assertEquals(p.remaining, null);
  assertEquals(p.limit, -1);
  assertEquals(p.allowed, true);
});

Deno.test("buildPayload: resetAt is the first of next month UTC", () => {
  const p = buildPayload({ plan: "free", used: 0, limit: 25, allowed: true });
  const reset = new Date(p.resetAt as string);
  assertEquals(reset.getUTCDate(), 1);
  const now = new Date();
  const expectedMonth = (now.getUTCMonth() + 1) % 12;
  assertEquals(reset.getUTCMonth(), expectedMonth);
});
