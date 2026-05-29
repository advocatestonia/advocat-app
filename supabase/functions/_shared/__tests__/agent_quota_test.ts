// Tests for _shared/agent_quota.ts — tier detection + atomic quota gate.

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  AGENT_TIER_CAP,
  checkAndConsumeAgentQuota,
  detectAgentTier,
  recordAgentAudit,
  sonnetCostMicrocents,
} from "../agent_quota.ts";

// ─── Fake supabase client ─────────────────────────────────────────────────
// deno-lint-ignore no-explicit-any
function fakeSb(opts: {
  // `subscriptions.tier` stores "basic" | "premium" | "free" (NOT "plan").
  tier?: string | null;
  // ISO string for current_period_end. Defaults to a far-future date so the
  // expiry guard passes; pass a past date to exercise the lapse-to-free path.
  periodEnd?: string | null;
  rpcResult?: { turns_used: number; tier_cap: number; exhausted: boolean };
  rpcError?: { message: string };
  rpcThrow?: Error;
  auditCapture?: Array<Record<string, unknown>>;
}): any {
  const farFuture = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
    .toISOString();
  return {
    from(table: string) {
      if (table === "subscriptions") {
        return {
          select: () => ({
            eq: () => ({
              in: () => ({
                order: () => ({
                  limit: () => ({
                    maybeSingle: () =>
                      Promise.resolve({
                        data: opts.tier === undefined
                          ? null
                          : {
                            tier: opts.tier,
                            current_period_end: opts.periodEnd === undefined
                              ? farFuture
                              : opts.periodEnd,
                          },
                      }),
                  }),
                }),
              }),
            }),
          }),
        };
      }
      throw new Error(`unexpected table ${table}`);
    },
    rpc(name: string, args: Record<string, unknown>) {
      if (opts.rpcThrow) throw opts.rpcThrow;
      if (name === "check_and_increment_agent_quota") {
        if (opts.rpcError) {
          return Promise.resolve({ data: null, error: opts.rpcError });
        }
        return Promise.resolve({
          data: opts.rpcResult ?? {
            turns_used: 1,
            tier_cap: 50,
            exhausted: false,
          },
          error: null,
        });
      }
      if (name === "record_agent_audit") {
        opts.auditCapture?.push(args);
        return Promise.resolve({ data: "audit-id", error: null });
      }
      throw new Error(`unexpected RPC ${name}`);
    },
  };
}

// ─── detectAgentTier ──────────────────────────────────────────────────────

Deno.test("detectAgentTier: premium tier → pro cap", async () => {
  // subscriptions.tier='premium' is the Pro plan.
  const sb = fakeSb({ tier: "premium" });
  assertEquals(await detectAgentTier(sb, "u1"), "pro");
});

Deno.test("detectAgentTier: basic tier → counsel cap", async () => {
  // subscriptions.tier='basic' is the Counsel plan.
  const sb = fakeSb({ tier: "basic" });
  assertEquals(await detectAgentTier(sb, "u1"), "counsel");
});

Deno.test("detectAgentTier: no row → free", async () => {
  const sb = fakeSb({});
  assertEquals(await detectAgentTier(sb, "u1"), "free");
});

Deno.test("detectAgentTier: unknown tier → free", async () => {
  const sb = fakeSb({ tier: "weird_legacy" });
  assertEquals(await detectAgentTier(sb, "u1"), "free");
});

Deno.test("detectAgentTier: lapsed period (status active, expired) → free", async () => {
  // Regression: Apple IAP has no expiry webhook in prod, so a cancelled/
  // refunded sub can read status='active' with a past period end. Must read
  // as free, not perpetual Pro.
  const sb = fakeSb({
    tier: "premium",
    periodEnd: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(),
  });
  assertEquals(await detectAgentTier(sb, "u1"), "free");
});

Deno.test("detectAgentTier: null period end → still grants tier", async () => {
  // A null current_period_end (legacy/lifetime row) is not treated as
  // expired — only an explicitly-past date downgrades.
  const sb = fakeSb({ tier: "premium", periodEnd: null });
  assertEquals(await detectAgentTier(sb, "u1"), "pro");
});

// ─── AGENT_TIER_CAP ───────────────────────────────────────────────────────

Deno.test("AGENT_TIER_CAP constants", () => {
  assertEquals(AGENT_TIER_CAP.free, 0);
  assertEquals(AGENT_TIER_CAP.counsel, 20);
  assertEquals(AGENT_TIER_CAP.premium, 50);
  assertEquals(AGENT_TIER_CAP.pro, 50);
});

// ─── checkAndConsumeAgentQuota ────────────────────────────────────────────

Deno.test("checkAndConsumeAgentQuota: free tier denied", async () => {
  const sb = fakeSb({ tier: null });
  const r = await checkAndConsumeAgentQuota({ sb, userId: "u1" });
  assertEquals(r.ok, false);
  assertEquals(r.tier, "free");
  assertEquals(r.reason, "agent_mode_requires_pro");
});

Deno.test("checkAndConsumeAgentQuota: pro under cap → ok", async () => {
  const sb = fakeSb({
    tier: "premium",
    rpcResult: { turns_used: 5, tier_cap: 50, exhausted: false },
  });
  const r = await checkAndConsumeAgentQuota({ sb, userId: "u1" });
  assertEquals(r.ok, true);
  assertEquals(r.tier, "pro");
  assertEquals(r.turns_used, 5);
  assertEquals(r.tier_cap, 50);
});

Deno.test("checkAndConsumeAgentQuota: pro exhausted → denied", async () => {
  const sb = fakeSb({
    tier: "premium",
    rpcResult: { turns_used: 51, tier_cap: 50, exhausted: true },
  });
  const r = await checkAndConsumeAgentQuota({ sb, userId: "u1" });
  assertEquals(r.ok, false);
  assertEquals(r.reason, "daily_cap_reached");
  assertEquals(r.turns_used, 51);
});

Deno.test("checkAndConsumeAgentQuota: RPC error → fail closed", async () => {
  const sb = fakeSb({
    tier: "premium",
    rpcError: { message: "db down" },
  });
  const r = await checkAndConsumeAgentQuota({ sb, userId: "u1" });
  assertEquals(r.ok, false);
  assertEquals(r.reason, "quota_rpc_error");
});

Deno.test("checkAndConsumeAgentQuota: RPC throws → fail closed", async () => {
  const sb = fakeSb({
    tier: "premium",
    rpcThrow: new Error("network"),
  });
  const r = await checkAndConsumeAgentQuota({ sb, userId: "u1" });
  assertEquals(r.ok, false);
  assertEquals(r.reason, "quota_exception");
});

Deno.test("checkAndConsumeAgentQuota: explicit tier override skips DB lookup", async () => {
  const sb = fakeSb({
    rpcResult: { turns_used: 1, tier_cap: 20, exhausted: false },
  });
  // Pass tier: 'counsel' explicitly — should NOT call subscriptions.
  const r = await checkAndConsumeAgentQuota({
    sb,
    userId: "u1",
    tier: "counsel",
  });
  assertEquals(r.ok, true);
  assertEquals(r.tier, "counsel");
  assertEquals(r.tier_cap, 20);
});

// ─── recordAgentAudit ─────────────────────────────────────────────────────

Deno.test("recordAgentAudit: forwards all fields", async () => {
  const captured: Array<Record<string, unknown>> = [];
  const sb = fakeSb({ auditCapture: captured });
  await recordAgentAudit({
    sb,
    agentRunId: "run-1",
    userId: "u1",
    iter: 3,
    tool: "list_inbox",
    status: "ok",
    inputTokens: 1000,
    outputTokens: 200,
    costMicrocents: sonnetCostMicrocents(1000, 200),
    durationMs: 1234,
    caseId: "case-1",
    summary: "ok",
  });
  assertEquals(captured.length, 1);
  assertEquals(captured[0].p_user_id, "u1");
  assertEquals(captured[0].p_iter, 3);
  assertEquals(captured[0].p_tool, "list_inbox");
  assertEquals(captured[0].p_status, "ok");
  assertEquals(captured[0].p_input_tokens, 1000);
  // 1000 input × 0.3 + 200 output × 1.5 = 300 + 300 = 600 microcents
  assertEquals(captured[0].p_cost_microcents, 600);
});

Deno.test("recordAgentAudit: never throws on RPC failure", async () => {
  // deno-lint-ignore no-explicit-any
  const sb: any = {
    rpc: () => Promise.reject(new Error("db down")),
  };
  // No throw expected — telemetry must never break a chat reply.
  await recordAgentAudit({
    sb,
    userId: "u1",
    iter: 1,
    tool: "no_tool",
    status: "ok",
  });
  // pass — only assertion is "did not throw".
  assert(true);
});

// ─── sonnetCostMicrocents ─────────────────────────────────────────────────

Deno.test("sonnetCostMicrocents: input + output at correct rates", () => {
  // 1M input + 0 output = $3 = 300 cents = 300_000 microcents
  assertEquals(sonnetCostMicrocents(1_000_000, 0), 300_000);
  // 0 input + 1M output = $15 = 1500 cents = 1_500_000 microcents
  assertEquals(sonnetCostMicrocents(0, 1_000_000), 1_500_000);
  // 100 input + 50 output = round(100*0.3) + round(50*1.5) = 30 + 75 = 105
  assertEquals(sonnetCostMicrocents(100, 50), 105);
});

Deno.test("sonnetCostMicrocents: zero", () => {
  assertEquals(sonnetCostMicrocents(0, 0), 0);
});
