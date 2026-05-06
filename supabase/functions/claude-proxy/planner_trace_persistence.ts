// planner_trace_persistence.ts — Phase 2 Pkg 6 trace upserter.
// -----------------------------------------------------------------------------
// Service-role write to public.chat_planner_traces. Mirrors the contract of
// citation_persistence.ts (same proxy):
//   • PostgREST direct call (no Supabase JS client — fewer deps in edge
//     bundle, faster cold-start).
//   • Errors are logged-and-swallowed by the caller — never block chat.
//   • Idempotent — message_id is uniquely indexed, we use the upsert
//     `Prefer: resolution=merge-duplicates` so a retry / regen never
//     creates a second row.
// -----------------------------------------------------------------------------

import type { PlannerCritique, PlannerPlan } from "../_shared/legal_planner.ts";

export interface PlannerTraceRow {
  message_id: string;
  plan: PlannerPlan;
  executor_response: string;
  critique: PlannerCritique;
  regenerated_once: boolean;
  latency_ms: number;
  cost_cents: number;
}

export interface PersistConfig {
  supabaseUrl: string;
  serviceRoleKey: string;
}

/** Upsert a trace row keyed on message_id. The unique index on
 *  chat_planner_traces.message_id makes the upsert race-safe. Any HTTP
 *  failure is rethrown so the caller (legal_planner.runLegalPlannerLoop)
 *  can decide whether to swallow — today it does. */
export async function persistPlannerTrace(
  row: PlannerTraceRow,
  cfg: PersistConfig,
): Promise<void> {
  if (!cfg.supabaseUrl || !cfg.serviceRoleKey) {
    // Misconfiguration — log loud, skip. Don't throw because the caller
    // already handles errors but we shouldn't 500 the user reply.
    console.warn(
      "planner_trace_persistence: missing supabaseUrl or serviceRoleKey",
    );
    return;
  }
  const url = `${cfg.supabaseUrl}/rest/v1/chat_planner_traces`;
  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "apikey": cfg.serviceRoleKey,
      "Authorization": `Bearer ${cfg.serviceRoleKey}`,
      "Prefer": "resolution=merge-duplicates,return=minimal",
    },
    body: JSON.stringify({
      message_id: row.message_id,
      plan: row.plan,
      executor_response: row.executor_response,
      critique: row.critique,
      regenerated_once: row.regenerated_once,
      latency_ms: row.latency_ms,
      cost_cents: row.cost_cents,
    }),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(
      `chat_planner_traces upsert ${res.status}: ${text.slice(0, 200)}`,
    );
  }
}
