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
    return jsonOk({
      ok: true,
      triage_id: out.triage_id,
      severity: out.severity,
      send_recommendation: out.send_recommendation,
      privilege_check: out.privilege_check,
      posture: out.posture,
      gate_pass: out.gate_result?.pass ?? null,
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

    async loadMemoryBlock(_userId: string): Promise<MemoryBlock> {
      // Minimal Phase 1 implementation. The MemoryBlock surfaces from
      // `case_facts` (Pkg 1). Future revisions plug a real loader; for
      // now we return an empty shape so the model has a stable schema.
      return {
        identity_markers: {},
        dead_addresses: [],
        own_counsel_emails: [],
        known_privileged_individuals: [],
        relations: null,
        recent_owner_feedback: undefined,
      };
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

    async loadLawSearch(_query: string): Promise<unknown> {
      // The law-search edge fn is best-effort context — call inline only
      // when it's wired. Phase 1 keeps law context optional/empty so the
      // critical path doesn't depend on RAG availability.
      return [];
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
      // Best-effort. The `case_events` table lands in Pkg 1.A; the call
      // is wrapped in try/catch upstream. We use the user_cases timeline
      // jsonb column as the durable store for now (mirrors the
      // case-auto-patch pattern).
      try {
        if (!args.case_id) return;
        const { data: caseRow } = await sb
          .from("user_cases")
          .select("timeline")
          .eq("id", args.case_id)
          .eq("user_id", args.user_id)
          .maybeSingle();
        const tl = Array.isArray(caseRow?.timeline) ? caseRow!.timeline : [];
        tl.push({
          ts: new Date().toISOString(),
          type: args.type,
          ...args.payload,
        });
        await sb
          .from("user_cases")
          .update({ timeline: tl })
          .eq("id", args.case_id)
          .eq("user_id", args.user_id);
      } catch (_e) { /* ignore */ }
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
  };
}
