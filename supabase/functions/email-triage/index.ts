// supabase/functions/email-triage/index.ts
// -----------------------------------------------------------------------------
// D4 — Sonnet 4.6 v1.1-final triage with reviewer + policy gate.
//
// Phase 1 wiring:
//   * auto-send DISABLED — every triage row lands as `hold_for_user_review`.
//     The 12-check policy gate still runs and emits an HMAC token for
//     audit; D6 (UI Approve & Send) consumes it eventually.
//   * Reviewer is local regex-grade (Haiku-shaped checks, deterministic).
//   * Quota: free=0, basic=300/mo, premium=1200/mo for kind=email_triage.
//
// Auth: two modes match `email-inbox-sync`.
//   * `x-cron-secret` header → cron tick; iterates pending threads for all
//     users (bounded fan-out).
//   * Bearer JWT → per-user (called from `email-inbox-sync` enqueue).
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

import { corsHeaders, jsonError, jsonOk } from "../_shared/auth.ts";
import { checkCronSecret } from "../agent-intentions-cron/auth_gate.ts";
import { buildAnthropicHeaders } from "../claude-proxy/prompt_caching.ts";
import {
  type AnthropicCallArgs,
  type AnthropicResponse,
  type MemoryBlock,
  type MinimalTriageDeps,
  type QuotaResult,
  runTriage,
  type ThreadRecord,
  type TriageInsertRow,
  type UserPrefs,
} from "./triage_logic.ts";
import {
  appendCaseEventReal,
  applyMemoryUpdatesReal,
  loadLawSearchReal,
  loadMemoryBlockReal,
  maybeTransitionWaitToStrategyOnInbound,
} from "./wiring.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY") ?? "";
const GATE_SECRET = Deno.env.get("EMAIL_AGENT_GATE_SECRET") ??
  Deno.env.get("CRON_SECRET") ?? "dev-gate-secret";

const QUOTA_TIERS: Record<string, number> = {
  free: 0,
  basic: 300,
  premium: 1200,
  pro: 1200,
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  let body: { thread_id?: string; user_id?: string };
  try {
    body = await req.json();
  } catch (_) {
    return jsonError("Invalid JSON body", 400);
  }
  if (!body?.thread_id) {
    return jsonError("thread_id is required", 400);
  }

  // Cron path
  const cronHeader = req.headers.get("x-cron-secret");
  const internalCall = req.headers.get("x-internal-call");
  if (cronHeader || internalCall === "email-inbox-sync") {
    if (cronHeader) {
      const gate = checkCronSecret(cronHeader, Deno.env.get("CRON_SECRET"));
      if (gate.kind === "deny") {
        return jsonError(gate.body.error, gate.status);
      }
    }
    const userId = body.user_id;
    if (!userId) return jsonError("user_id required for cron", 400);
    return await dispatchTriage(body.thread_id!, userId);
  }

  // Per-user JWT path
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return jsonError("Unauthorized", 401);
  const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  const token = authHeader.replace("Bearer ", "");
  const { data, error } = await sb.auth.getUser(token);
  if (error || !data?.user) return jsonError("Invalid session", 401);
  return await dispatchTriage(body.thread_id!, data.user.id);
});

async function dispatchTriage(
  threadId: string,
  userId: string,
): Promise<Response> {
  const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  const deps = makeProdDeps(sb);
  try {
    const out = await runTriage(deps, {
      thread_id: threadId,
      user_id: userId,
      auto_send_enabled: false, // Phase 1
      gate_secret: GATE_SECRET,
    });
    if (!out.ok) {
      return jsonError(out.error_code, 500, out.detail ? { detail: out.detail } : {});
    }

    // Pkg 5 — wait → strategy auto-transition on HIGH/CRITICAL inbound.
    // Best-effort: any miss / error is swallowed inside the helper.
    // Re-fetch the thread row (just case_id) since runTriage's
    // ThreadRecord isn't returned in TriageOutcome and we don't want
    // to widen that contract for a sidecar effect.
    let phaseFlip:
      | { changed: boolean; from?: string; to?: string }
      | null = null;
    try {
      const { data: threadRow } = await sb
        .from("email_threads")
        .select("case_id")
        .eq("id", threadId)
        .maybeSingle();
      const caseId = (threadRow?.case_id as string | null) ?? null;
      if (caseId) {
        phaseFlip = await maybeTransitionWaitToStrategyOnInbound(sb, {
          case_id: caseId,
          severity: out.severity ?? null,
          triage_id: out.triage_id,
          thread_id: threadId,
        });
      }
    } catch (e) {
      console.warn(
        `email-triage: phase-flip post-step threw: ${
          String(e).slice(0, 200)
        }`,
      );
    }

    return jsonOk({
      ok: true,
      triage_id: out.triage_id,
      severity: out.severity,
      send_recommendation: out.send_recommendation,
      privilege_check: out.privilege_check,
      posture: out.posture,
      gate_pass: out.gate_result?.pass ?? null,
      ...(phaseFlip?.changed
        ? { case_phase: { from: phaseFlip.from, to: phaseFlip.to } }
        : {}),
    });
  } catch (e) {
    return jsonError("triage_failed", 502, {
      detail: String(e).slice(0, 200),
    });
  }
}

// =============================================================================
// Production deps — Supabase + Anthropic
// =============================================================================

function makeProdDeps(
  // deno-lint-ignore no-explicit-any
  sb: any,
): MinimalTriageDeps {
  return {
    async loadThread(threadId: string): Promise<ThreadRecord | null> {
      const { data: t, error } = await sb
        .from("email_threads")
        .select(
          "id, user_id, case_id, subject, participants",
        )
        .eq("id", threadId)
        .maybeSingle();
      if (error || !t) return null;
      const { data: msgs } = await sb
        .from("email_messages")
        .select(
          "id, gmail_message_id, sender_email, sender_name, " +
            "to_recipients, cc_recipients, subject, body_plaintext, " +
            "sent_at, has_attachments, attachments_meta, headers_meta",
        )
        .eq("thread_id", threadId)
        .order("sent_at", { ascending: true })
        .limit(5);
      return {
        id: t.id as string,
        user_id: t.user_id as string,
        case_id: (t.case_id as string | null) ?? null,
        subject: (t.subject as string | null) ?? null,
        participants: (t.participants as string[] | null) ?? [],
        messages: (msgs ?? []) as ThreadRecord["messages"],
      };
    },

    async loadActiveCase(caseId: string | null): Promise<unknown> {
      if (!caseId) return null;
      try {
        const { data, error } = await sb.rpc("load_active_case", {
          p_case_id: caseId,
        });
        if (error) return null;
        return data;
      } catch (_) {
        return null;
      }
    },

    async loadMemoryBlock(userId: string): Promise<MemoryBlock> {
      // Carry-over Task 1: build the MemoryBlock from real per-user
      // sources. The block is capped at ~2 KB before serialisation so
      // the cached prompt prefix stays well under the model's static
      // context budget (system_prompt v1.1-final §3.7).
      return await loadMemoryBlockReal(sb, userId);
    },

    async loadUserPrefs(userId: string): Promise<UserPrefs> {
      try {
        const { data } = await sb
          .from("profiles")
          .select("preferred_language, full_name, email")
          .eq("id", userId)
          .maybeSingle();
        const lang = (data?.preferred_language as string | null) ?? "en";
        return {
          preferred_language: lang,
          signature: {
            et: data?.full_name ?? "",
            ru: data?.full_name ?? "",
            fi: data?.full_name ?? "",
            en: data?.full_name ?? "",
          },
          tone: "neutral",
          timezone: "Europe/Helsinki",
          auto_send_opt_in: false,
          allowed_auto_send_categories: [],
        };
      } catch (_) {
        return {
          preferred_language: "en",
          signature: { et: "", ru: "", fi: "", en: "" },
          timezone: "Europe/Helsinki",
        };
      }
    },

    async loadLawSearch(query: string): Promise<unknown> {
      // Carry-over Task 2: call the existing `law-search` edge fn with a
      // tight timeout. Soft-fail to `[]` on any error — the triage
      // critical path must not hang on a RAG outage (per the law-search
      // graceful-degradation contract, the fn already returns
      // `{chunks: []}` on its own internal failures, but we still wrap
      // the network call defensively in case Supabase Functions are
      // unreachable).
      return await loadLawSearchReal(sb, query);
    },

    async checkQuota(userId: string): Promise<QuotaResult> {
      // Mirror the Whisper pattern: tiers free=0, basic=300, premium=1200.
      // Plan detection mirrors `check-ai-quota` (subscriptions or
      // profiles.is_pro).
      let plan: "free" | "basic" | "premium" | "pro" = "free";
      try {
        const sub = await sb
          .from("subscriptions")
          .select("status, tier")
          .eq("user_id", userId)
          .in("status", ["active", "trialing"])
          .limit(1)
          .maybeSingle();
        if (sub?.data) {
          const tier = String(sub.data.tier ?? "premium").toLowerCase();
          if (tier === "premium" || tier === "pro") plan = "premium";
          else if (tier === "basic") plan = "basic";
          else plan = "premium";
        }
      } catch (_) { /* fall through */ }
      const limit = QUOTA_TIERS[plan] ?? 0;
      return { allowed: limit > 0, remaining: limit, plan };
    },

    async callSonnet(args: AnthropicCallArgs): Promise<AnthropicResponse> {
      if (!ANTHROPIC_API_KEY) {
        throw new Error("ANTHROPIC_API_KEY not configured");
      }
      const headers = buildAnthropicHeaders(ANTHROPIC_API_KEY);
      const resp = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers,
        body: JSON.stringify({
          model: "claude-sonnet-4-6",
          max_tokens: args.maxTokens,
          temperature: args.temperature,
          system: args.systemBlocks,
          messages: [
            { role: "user", content: args.userMessage },
          ],
        }),
      });
      if (!resp.ok) {
        const errBody = await resp.text();
        throw new Error(`Anthropic ${resp.status}: ${errBody.slice(0, 200)}`);
      }
      const json = await resp.json();
      const content = (json?.content ?? [])
        .filter((b: { type?: string }) => b?.type === "text")
        .map((b: { text?: string }) => b?.text ?? "")
        .join("\n");
      const usage = json?.usage ?? {};
      return {
        content,
        input_tokens: Number(usage.input_tokens ?? 0),
        output_tokens: Number(usage.output_tokens ?? 0),
        cache_read_input_tokens: Number(usage.cache_read_input_tokens ?? 0),
        cache_creation_input_tokens: Number(
          usage.cache_creation_input_tokens ?? 0,
        ),
      };
    },

    async persistTriageRow(row: TriageInsertRow): Promise<{ id: string }> {
      const { data, error } = await sb
        .from("email_triage_results")
        .insert(row)
        .select("id")
        .single();
      if (error || !data?.id) {
        throw new Error(`persistTriageRow: ${error?.message ?? "unknown"}`);
      }
      return { id: data.id as string };
    },

    async markThreadTriageStatus(threadId: string, status: string) {
      try {
        await sb
          .from("email_threads")
          .update({ triage_status: status })
          .eq("id", threadId);
      } catch (_e) { /* ignore */ }
    },

    async appendCaseEvent(args) {
      // Carry-over Task 3: real append against `user_cases.timeline`
      // (jsonb), with idempotency guard on
      // (case_id, type, ref_email_id, occurred_at). The timeline jsonb
      // column already exists from `20260506100000_case_memory.sql`.
      await appendCaseEventReal(sb, args);
    },

    async scheduleAgentIntention(args) {
      try {
        await sb.from("agent_intentions").insert({
          user_id: args.user_id,
          case_id: args.case_id,
          intent_type: args.intent_type,
          next_check_at: args.next_check_at,
          conversation_context: {
            summary: args.summary,
            locale: args.locale,
          },
        });
      } catch (_e) { /* ignore */ }
    },

    async applyMemoryUpdates(args) {
      // Carry-over Task 5: persist OWN_COUNSEL_EMAIL discoveries from
      // the model into `user_settings.own_counsel_emails`. Best-effort.
      await applyMemoryUpdatesReal(sb, args.user_id, args.updates);
    },
  };
}
