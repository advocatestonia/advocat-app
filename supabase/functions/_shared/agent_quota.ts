// _shared/agent_quota.ts — Day 9 (2026-05-27) per-user agent turn cap.
// ----------------------------------------------------------------------------
// Each claude-proxy turn that runs the agent loop (≥1 tool iteration)
// counts against the user's daily quota. Pro = 50/day, Counsel = 20/day,
// Free = 0/day. Read-only chat (no tool_use) does NOT count — only paid
// iterations.
//
// The check is run AT THE START of the agent loop (right after the model
// returns stop_reason=tool_use on iteration 1). If the cap is exhausted,
// we fail-closed: return 429 to the client. Increment uses an atomic
// upsert RPC so concurrent claude-proxy calls cannot race past the cap.

export type AgentTier = "free" | "counsel" | "premium" | "pro";

export const AGENT_TIER_CAP: Record<AgentTier, number> = {
  free: 0, // disabled — agent mode is Pro-only at launch
  counsel: 20,
  premium: 50,
  pro: 50,
};

export interface QuotaResult {
  ok: boolean;
  turns_used: number;
  tier_cap: number;
  tier: AgentTier;
  reason?: string;
}

/**
 * Read the user's subscription tier. Mirrors the rule used by the chat
 * quota check (check-ai-quota edge fn). Falls back to "free" when no
 * row is found.
 */
// deno-lint-ignore no-explicit-any
export async function detectAgentTier(sb: any, userId: string): Promise<AgentTier> {
  try {
    const { data } = await sb
      .from("subscriptions")
      .select("tier, current_period_end")
      .eq("user_id", userId)
      .in("status", ["active", "trialing"])
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();
    if (!data) return "free";

    // Expiry guard: the row can read status='active' long after the period
    // ended when no renewal/cancel webhook arrived (e.g. Apple IAP has no
    // server-notification handler in prod). A lapsed period is "free".
    const periodEnd = data.current_period_end as string | null;
    if (periodEnd && new Date(periodEnd).getTime() < Date.now()) return "free";

    // `subscriptions.tier` stores the Stripe/IAP tier: "basic" | "premium"
    // | "free" (NOT "plan" — that column does not exist). basic == Counsel,
    // premium == Pro for agent-cap purposes.
    const tier = (data.tier as string | null)?.toLowerCase() ?? "";
    if (tier === "premium" || tier.includes("pro")) return "pro";
    if (tier === "basic" || tier.includes("counsel")) return "counsel";
    return "free";
  } catch (_) {
    return "free";
  }
}

/**
 * Atomic check + increment. Wraps the SQL RPC
 * `check_and_increment_agent_quota(user_id, tier_cap)` which returns the
 * row AFTER bumping turns_used. We bail-close on any RPC error — better
 * to deny one turn than to leak past the cap on a transient DB blip.
 *
 * Returns ok=false when:
 *   - tier_cap is 0 (free-tier explicit deny)
 *   - turns_used (post-increment) > tier_cap
 *   - RPC fails
 */
export async function checkAndConsumeAgentQuota(args: {
  // deno-lint-ignore no-explicit-any
  sb: any;
  userId: string;
  tier?: AgentTier;
}): Promise<QuotaResult> {
  const tier = args.tier ?? (await detectAgentTier(args.sb, args.userId));
  const cap = AGENT_TIER_CAP[tier];
  if (cap === 0) {
    return {
      ok: false,
      turns_used: 0,
      tier_cap: 0,
      tier,
      reason: "agent_mode_requires_pro",
    };
  }
  try {
    const { data, error } = await args.sb.rpc(
      "check_and_increment_agent_quota",
      { p_user_id: args.userId, p_tier_cap: cap },
    );
    if (error) {
      console.warn(`agent_quota RPC failed: ${error.message}`);
      return {
        ok: false,
        turns_used: 0,
        tier_cap: cap,
        tier,
        reason: "quota_rpc_error",
      };
    }
    const row = Array.isArray(data) ? data[0] : data;
    const used = Number(row?.turns_used ?? 0);
    const exhausted = !!row?.exhausted;
    return {
      ok: !exhausted,
      turns_used: used,
      tier_cap: cap,
      tier,
      reason: exhausted ? "daily_cap_reached" : undefined,
    };
  } catch (e) {
    console.warn(`agent_quota threw: ${String(e).slice(0, 200)}`);
    return {
      ok: false,
      turns_used: 0,
      tier_cap: cap,
      tier,
      reason: "quota_exception",
    };
  }
}

/**
 * Fire-and-forget audit log insert. Never throws — telemetry can never
 * break a chat reply.
 */
export async function recordAgentAudit(args: {
  // deno-lint-ignore no-explicit-any
  sb: any;
  agentRunId?: string | null;
  userId: string;
  iter: number;
  tool: string;
  status: "ok" | "error" | "declined" | "expired" | "rate_limited" | "approval_pending";
  inputTokens?: number;
  outputTokens?: number;
  costMicrocents?: number;
  durationMs?: number;
  caseId?: string | null;
  summary?: string | null;
}): Promise<void> {
  try {
    await args.sb.rpc("record_agent_audit", {
      p_agent_run_id: args.agentRunId ?? null,
      p_user_id: args.userId,
      p_iter: args.iter,
      p_tool: args.tool,
      p_status: args.status,
      p_input_tokens: args.inputTokens ?? 0,
      p_output_tokens: args.outputTokens ?? 0,
      p_cost_microcents: args.costMicrocents ?? 0,
      p_duration_ms: args.durationMs ?? null,
      p_case_id: args.caseId ?? null,
      p_summary: args.summary ?? null,
    });
  } catch (e) {
    console.warn(`agent_audit insert failed: ${String(e).slice(0, 200)}`);
  }
}

/**
 * Sonnet 4.6 pricing as of 2026-05: $3/M in, $15/M out. Returns cost in
 * micro-cents (1 cent = 1000 microcents) to avoid float precision loss.
 *
 * Math:
 *   $3 / 1M tokens = 300 cents / 1M tokens = 300_000 microcents / 1M tokens
 *                  = 0.3 microcents/token
 *   $15 / 1M tokens = 1500 cents / 1M tokens = 1_500_000 microcents / 1M
 *                  = 1.5 microcents/token
 *
 * We multiply by ×1000 then divide so the function returns integers
 * (microcents) — caller divides by 100_000 to get dollars or 1000 to
 * get cents.
 */
export function sonnetCostMicrocents(
  inputTokens: number,
  outputTokens: number,
): number {
  // ($3 per 1M input tokens) × tokens × 1_000_000 microcents/$
  //   = tokens × 3 × 1_000_000 / 1_000_000
  //   = tokens × 3
  // Wait — we want microCENTS not microDOLLARS.
  //   $3 per 1M tokens = 300 cents per 1M tokens = 300 * 1000 microcents
  //                    = 300_000 microcents per 1M tokens
  //                    = 0.3 microcents per token
  // Use 10× integer arithmetic to avoid float: track as 1/10 microcent
  // internally is overkill — round to nearest microcent.
  const inMicro = Math.round(inputTokens * 0.3);
  const outMicro = Math.round(outputTokens * 1.5);
  return inMicro + outMicro;
}
