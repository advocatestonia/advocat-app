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
import { createClient } from "@supabase/supabase-js";

import {
  constantTimeEqual,
  corsHeaders,
  jsonError,
  jsonOk,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import { checkCronSecret } from "../agent-intentions-cron/auth_gate.ts";
import { buildAnthropicHeaders } from "../claude-proxy/prompt_caching.ts";
import { getOrCreateTraceId, shortTrace } from "../_shared/tracing.ts";
import { withSentry } from "../_shared/sentry.ts";
import {
  type AnthropicCallArgs,
  type AnthropicResponse,
  type ConsiliumCallArgs,
  type LawyerOpinion,
  type MemoryBlock,
  type MinimalTriageDeps,
  type QuotaResult,
  runTriage,
  type ThreadRecord,
  type TriageInsertRow,
  type UserPrefs,
} from "./triage_logic.ts";
import {
  type ConsiliumSSEEvent,
  runConsilium,
} from "../_shared/consilium.ts";
import {
  appendCaseEventReal,
  applyMemoryUpdatesReal,
  type InboundAttachment,
  loadInboundAttachmentTexts,
  loadLawSearchReal,
  loadMemoryBlockReal,
  maybeTransitionWaitToStrategyOnInbound,
} from "./wiring.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY") ?? "";
// Upstream timeout — a hung Anthropic connection would otherwise pin the
// isolate and stall the triage queue. The resulting TimeoutError matches
// TRANSIENT_ERROR_RE below, so it's retried rather than dropped.
const ANTHROPIC_FETCH_TIMEOUT_MS = 120_000;
// SECURITY (2026-05-27): plaintext fallback "dev-gate-secret" removed.
// email-send already hard-fails 503 when EMAIL_AGENT_GATE_SECRET is unset
// in prod; this fn now mirrors that posture so HMAC tokens cannot be
// forged by anyone reading the repo. The optional CRON_SECRET reuse stays
// because cron paths require a high-entropy shared secret, but no public
// fallback ever ships.
const GATE_SECRET = Deno.env.get("EMAIL_AGENT_GATE_SECRET") ??
  Deno.env.get("CRON_SECRET") ?? "";

const QUOTA_TIERS: Record<string, number> = {
  free: 0,
  basic: 300,
  premium: 1200,
  pro: 1200,
};

// Retry queue / DLQ — when the triage call fails with a transient error
// (Anthropic 529 / 5xx / timeout), enqueue a retry row instead of returning
// 502 and leaving email_threads.triage_status='pending' forever. Default ON
// — flip EMAIL_TRIAGE_USE_RETRY_QUEUE=false in env to fall back to the old
// fail-loud behaviour during incident response.
const USE_RETRY_QUEUE =
  (Deno.env.get("EMAIL_TRIAGE_USE_RETRY_QUEUE") ?? "true").toLowerCase() !==
    "false";

// Anthropic errors we treat as transient (re-enqueue). Anything else is a
// permanent failure (parser bug, missing thread, config error) and bubbles
// as a 502 to the caller so the retry-tick worker dead-letters it.
const TRANSIENT_ERROR_RE = /\b(5\d\d|429|529|timeout|ECONNRESET|fetch failed)\b/i;

serve(withSentry("email-triage", async (req) => {
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

  // Cron / internal-call path — SECURITY (2026-05-27): the x-internal-call
  // header alone is NOT sufficient; the caller MUST also present the
  // service-role bearer (matches the pattern in pdf-parser/index.ts:130).
  // Otherwise any user with a valid Supabase JWT could forge
  // `x-internal-call: email-inbox-sync` + body.user_id and run paid
  // Sonnet triage on behalf of an arbitrary user.
  const cronHeader = req.headers.get("x-cron-secret");
  const internalCallHeader = req.headers.get("x-internal-call");
  const authHeaderRaw = req.headers.get("authorization") ??
    req.headers.get("Authorization") ?? "";
  const isInternalCall = internalCallHeader === "email-inbox-sync" &&
    constantTimeEqual(authHeaderRaw, `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`);
  // Trace propagation — pulled once from the request and threaded through
  // every Anthropic call / queue row / audit insert below.
  const traceId = getOrCreateTraceId(req);

  if (cronHeader || isInternalCall) {
    if (cronHeader) {
      const gate = checkCronSecret(cronHeader, Deno.env.get("CRON_SECRET"));
      if (gate.kind === "deny") {
        return jsonError(gate.body.error, gate.status);
      }
    }
    const userId = body.user_id;
    if (!userId) return jsonError("user_id required for cron", 400);
    return await dispatchTriage(body.thread_id!, userId, traceId);
  }
  // If the caller TRIED to use x-internal-call but didn't present the
  // service-role bearer, fail loud — never fall through to the per-user
  // JWT path (would let them forge `body.user_id`).
  if (internalCallHeader) {
    return jsonError("internal-call requires service-role bearer", 401);
  }

  // SECURITY (Wave-1 2026-05-28, audit P1-11):
  // Per-user JWT path previously did bare `sb.auth.getUser(token)` (no U1
  // role/aud check), so a forged token could trigger paid Sonnet triage
  // on arbitrary `thread_id`s — ~$0.02/triage burn. Gate now enforces
  // role/aud + postgres-backed rate limit. Internal-call (cron) path
  // above already validates the service-role bearer separately.
  const gate = await requireUserWithRateLimit(req, {
    bucket: "email-triage",
    maxPerMinute: 30,
  });
  if (gate.kind === "deny") return gate.response;
  return await dispatchTriage(body.thread_id!, gate.user.id, traceId);
}));

async function dispatchTriage(
  threadId: string,
  userId: string,
  traceId: string,
): Promise<Response> {
  const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  const deps = makeProdDeps(sb, traceId);
  console.log(
    `email-triage start thread=${threadId} trace=${shortTrace(traceId)}`,
  );
  try {
    const out = await runTriage(deps, {
      thread_id: threadId,
      user_id: userId,
      auto_send_enabled: false, // Phase 1
      gate_secret: GATE_SECRET,
    });
    if (!out.ok) {
      // Non-transient failure (parser bug, missing thread). Don't enqueue
      // because retry won't help. Return 500 so the retry-tick worker (if
      // this was an internal-call) flips the queue row to dead_letter.
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
    const detail = String(e).slice(0, 200);
    const transient = TRANSIENT_ERROR_RE.test(detail);
    // Transient failure (Anthropic 529 / 5xx / timeout) + retry queue
    // enabled: enqueue a durable retry row so triage-retry-tick reruns
    // this thread with exponential backoff. Best-effort — if enqueue
    // itself fails we still surface 502 to the caller.
    if (transient && USE_RETRY_QUEUE) {
      try {
        const { error: enqErr } = await sb.rpc("enqueue_triage", {
          p_thread_id: threadId,
          p_user_id: userId,
          p_payload: { source: "email-triage-catch", error: detail },
          p_trace_id: traceId,
        });
        if (enqErr) {
          console.error("enqueue_triage failed:", enqErr.message);
        } else {
          console.log(
            `triage enqueued for retry thread=${threadId} trace=${
              shortTrace(traceId)
            } reason=${detail.slice(0, 60)}`,
          );
        }
      } catch (enqE) {
        console.error("enqueue_triage threw:", String(enqE).slice(0, 200));
      }
    }
    return jsonError("triage_failed", 502, {
      detail,
      enqueued_for_retry: transient && USE_RETRY_QUEUE,
      trace_id: traceId,
    });
  }
}

// =============================================================================
// Production deps — Supabase + Anthropic
// =============================================================================

function makeProdDeps(
  // deno-lint-ignore no-explicit-any
  sb: any,
  traceId: string | null = null,
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

    async loadInboundAttachments(
      threadId: string,
    ): Promise<InboundAttachment[]> {
      // Fix #2 (2026-05-26) — bridge email_attachments → pdf-parser →
      // triage context. Returns `[]` on any error so triage critical
      // path is never blocked by a parser outage.
      return await loadInboundAttachmentTexts(sb, threadId);
    },

    async checkQuota(userId: string): Promise<QuotaResult> {
      // Mirror the Whisper pattern: tiers free=0, basic=300, premium=1200.
      // Plan detection mirrors `check-ai-quota` (subscriptions or
      // profiles.is_pro).
      let plan: "free" | "basic" | "premium" | "pro" = "free";
      try {
        const sub = await sb
          .from("subscriptions")
          .select("status, tier, current_period_end")
          .eq("user_id", userId)
          .in("status", ["active", "trialing"])
          .order("created_at", { ascending: false })
          .limit(1)
          .maybeSingle();
        if (sub?.data) {
          // Expiry guard: a row can read status='active' long after the
          // period ended when no renewal/cancel/refund webhook arrived
          // (Apple IAP has no server-notification handler in prod). A lapsed
          // period stays free — it must not grant Email Agent access forever.
          const periodEnd = sub.data.current_period_end as string | null;
          if (!periodEnd || new Date(periodEnd).getTime() >= Date.now()) {
            const tier = String(sub.data.tier ?? "premium").toLowerCase();
            if (tier === "premium" || tier === "pro") plan = "premium";
            else if (tier === "basic") plan = "basic";
            else plan = "premium";
          }
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
        signal: AbortSignal.timeout(ANTHROPIC_FETCH_TIMEOUT_MS),
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

    async callConsilium(args: ConsiliumCallArgs): Promise<AnthropicResponse> {
      if (!ANTHROPIC_API_KEY) {
        throw new Error("ANTHROPIC_API_KEY not configured");
      }
      // ── 1. Run the 15-lawyer consilium ───────────────────────────────────
      // The runner streams role_opinion + delta events via the onEvent
      // callback; we capture them into in-memory buffers so the structured
      // formatting call below can be informed by the chairman synthesis and
      // the audit row can persist the per-role payloads.
      const lawyerOpinions: LawyerOpinion[] = [];
      let synthesisText = "";
      try {
        synthesisText = await runConsilium({
          userMessage: args.consiliumQuery,
          systemPrompt: args.baseLawyerSystemPrompt,
          ragContext: args.ragContext,
          caseContext: args.caseContext,
          anthropicApiKey: ANTHROPIC_API_KEY,
          onEvent: (event: ConsiliumSSEEvent) => {
            if (event.type === "role_opinion") {
              lawyerOpinions.push({
                role_id: event.role_id,
                role_name: event.role_name,
                opinion: event.opinion,
                position: event.position,
                confidence: event.confidence,
                key_citation: event.key_citation,
              });
            }
          },
          // Don't pass caseClassification — let the lawyer-department
          // router (when CONSILIUM_LAWYER_ROUTER_ENABLED) fire its own
          // routing. The bridge already wires into the consilium when the
          // flag is set in the runtime env.
        });
      } catch (e) {
        // runConsilium is documented as never-throws, but belt-and-braces.
        console.warn(
          `email-triage callConsilium: runConsilium threw: ${
            String(e).slice(0, 200)
          }`,
        );
      }

      // ── 2. Final structured formatting call ──────────────────────────────
      // Inject the consilium synthesis into the v1.1-final system blocks as
      // a new <consilium> section. The parser + reviewer + policy gate
      // remain unchanged — they parse Sonnet's structured 6-block output
      // exactly as on the legacy path.
      const consiliumBlock = synthesisText
        ? `\n<consilium_synthesis>\n${synthesisText.slice(0, 12_000)}\n</consilium_synthesis>\n`
        : "";
      const lawyerOpinionsBlock = lawyerOpinions.length > 0
        ? `\n<lawyer_opinions>\n${
          lawyerOpinions
            .map((o) =>
              `- ${o.role_name} (${o.position}): ${o.opinion.slice(0, 300)}`
            )
            .join("\n")
        }\n</lawyer_opinions>\n`
        : "";
      const augmentedSystemBlocks = consiliumBlock || lawyerOpinionsBlock
        ? [
          ...args.systemBlocks,
          {
            type: "text" as const,
            // No cache_control — this block is per-thread and must not
            // pollute the cached prefix.
            text: `${lawyerOpinionsBlock}${consiliumBlock}`,
          },
        ]
        : args.systemBlocks;

      const headers = buildAnthropicHeaders(ANTHROPIC_API_KEY);
      const resp = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers,
        body: JSON.stringify({
          model: "claude-sonnet-4-6",
          max_tokens: args.maxTokens,
          temperature: args.temperature,
          system: augmentedSystemBlocks,
          messages: [
            { role: "user", content: args.userMessage },
          ],
        }),
        signal: AbortSignal.timeout(ANTHROPIC_FETCH_TIMEOUT_MS),
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
        lawyer_opinions: lawyerOpinions,
        consilium_synthesis: synthesisText || undefined,
      };
    },

    async persistTriageRow(row: TriageInsertRow): Promise<{ id: string }> {
      // Bind the trace_id onto the triage row so app.trace_timeline can JOIN
      // the result back to the request that produced it. trace_id column is
      // nullable, so legacy callers (older edge fns) keep working.
      const enriched = traceId
        ? { ...(row as unknown as Record<string, unknown>), trace_id: traceId }
        : row;
      const { data, error } = await sb
        .from("email_triage_results")
        .insert(enriched)
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
