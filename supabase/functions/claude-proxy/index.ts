import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import {
  corsHeaders,
  jsonError,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import { validateSystemPrompt } from "./system_prompt_guard.ts";
import {
  applyPromptCaching,
  buildAnthropicHeaders,
} from "./prompt_caching.ts";
import { mapAnthropicError } from "./error_mapping.ts";
import { classifyComplexity } from "./classify_complexity.ts";
import {
  applyActiveCaseToBody,
  isValidCaseId,
  loadActiveCase,
} from "./active_case_injection.ts";
import {
  concatAnthropicTextBlocks,
  extractRagContext,
  type GroundingChunk,
  verifyCitations,
} from "../_shared/citation_grounder.ts";
import {
  buildCitationRows,
  isValidMessageId,
  persistCitations,
} from "./citation_persistence.ts";
import { wrapAnthropicStreamWithCitations } from "./streaming_citations.ts";
import { runLegalPlannerLoop } from "../_shared/legal_planner.ts";
import { persistPlannerTrace } from "./planner_trace_persistence.ts";
import { runConsilium, shouldRunConsilium } from "../_shared/consilium.ts";
import {
  ASSISTANT_TOOLS,
  executeToolCalls,
  extractToolUseBlocks,
} from "./tool_handlers.ts";

const CLAUDE_API_KEY = Deno.env.get("CLAUDE_API_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY =
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

// SECURITY 2026-05-04 U1+U2+U3 — claude-proxy hardening.
// -----------------------------------------------------------------------------
// BEFORE (pre-f8f6a58): this function had its own inline auth that called
//   supabase.auth.getUser(token) and, when the token was the public
//   Supabase anon key (i.e. no associated end-user), set
//   `effectiveRateLimit = 10` and FORWARDED to Anthropic anyway.
// That made the function a free Claude proxy: anyone who pulled the
// anon key out of `main.dart.js` could burn unlimited credits.
//
// AFTER (f8f6a58):
//   1) requireUserWithRateLimit — only real end-user JWTs may call this.
//   2) Server-side `check-ai-quota` round-trip enforces the free cap.
//   3) The legacy in-process rate-limit Map is removed.
//
// 2026-05-05 DEMO RESTORE: f8f6a58 set anonymousPerMinute=0, which 401'd
// the "Proovi demorežiimi" → "AI õigusabi" flow (chat UI showed "Временная
// ошибка AI"). We restore demo with a HARD CAP that keeps cost bounded:
//   • anonymousPerMinute = 3            — IP rate-limit, 3 msgs / min
//   • ANON_MAX_TOKENS = 500             — clamp anon responses to 500 tokens
//                                         (vs 4096 for authenticated users)
// Worst case per anon IP: 3 calls/min × 500 tokens × ~$1.5/1M out tokens
// (Haiku 4.5) ≈ $0.13/hour. Authenticated callers retain the full 4096 cap.
// -----------------------------------------------------------------------------

const RATE_LIMIT_MAX = 10;
const ANON_RATE_LIMIT_PER_MINUTE = 3;

const ALLOWED_MODELS = new Set([
  "claude-sonnet-4-20250514",
  "claude-haiku-4-5-20251001",
  "claude-3-5-sonnet-20241022",
  "claude-3-haiku-20240307",
]);

// 2026-05-08: raised 16384 → 32000 (Anthropic API max for Sonnet 4.6).
// No artificial cap — AI writes contracts, pleadings, full legal dossiers
// without stopping mid-document. Anon callers stay clamped at 500 (demo).
const MAX_TOKENS_LIMIT = 32000;
const ANON_MAX_TOKENS = 500;
const MAX_MESSAGES = 20;

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  try {
    // ── 1. AuthN + per-user rate limit ────────────────────────────────────
    // 2026-05-05 DEMO RESTORE: anonymousPerMinute=3 lets demo-mode callers
    // (anon-key Bearer) through with an IP-bucketed 3/min cap. The
    // `anon:<ip>` synthetic principal is bucketed separately from
    // authenticated users in the shared helper.
    const gate = await requireUserWithRateLimit(req, {
      bucket: "claude-proxy",
      maxPerMinute: RATE_LIMIT_MAX,
      anonymousPerMinute: ANON_RATE_LIMIT_PER_MINUTE,
    });
    if (gate.kind === "deny") return gate.response;
    const isAnon = gate.user.id.startsWith("anon:");

    // ── 2. Server-side quota check (SECURITY U3) ──────────────────────────
    // Even an authenticated free-tier user cannot bypass the 7-message cap
    // by calling this endpoint directly. We forward the caller's JWT so
    // check-ai-quota's RLS-aware `auth.uid()` resolves correctly.
    //
    // For anon callers, check-ai-quota returns a synthetic
    // { allowed: true, plan: "free" } payload (see check-ai-quota/index.ts
    // lines 75-84) — no real per-IP counter is persisted server-side. The
    // bound on anon abuse is the rate-limit (3/min/IP) + ANON_MAX_TOKENS
    // clamp below.
    const authHeader = req.headers.get("Authorization") ?? "";
    const quotaAllowed = await checkQuota(authHeader);
    if (!quotaAllowed.ok) {
      // 402 Payment Required — semantic match for "out of free quota".
      // Body shape mirrors check-ai-quota for client compatibility.
      return new Response(
        JSON.stringify({
          error: "AI quota exceeded",
          quota: quotaAllowed.payload ?? null,
        }),
        {
          status: 402,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const body = await req.json();

    // ── Citations pipeline (Pkg 2, 2026-05-06) ───────────────────────────
    // Pull `rag_context` off the body BEFORE we do anything else with it.
    // The field is proxy-only — the verifier (post-Anthropic) needs the
    // chunks to ground markers, but Anthropic must NEVER see it (it's not
    // a Messages API field and would 400). extractRagContext both strips
    // the field in-place and returns the parsed chunks.
    //
    // Why here, before the model/quota normalisation: keeps the strip a
    // single, predictable point of mutation. Even if the request fails
    // every subsequent guard (model not allowed, system prompt rejected),
    // we already removed `rag_context` from `body`, so any path that
    // forwards `body` cannot leak it.
    const ragChunks: GroundingChunk[] = extractRagContext(
      body as Record<string, unknown>,
    );

    // ── Citations persistence opt-in (Pkg 2 closeout, 2026-05-06) ────────
    // The client may pre-generate the assistant chat_messages.id (UUID v4)
    // and pass it back via `body.message_id`. When present + valid, the
    // proxy persists the verifier's citations[] to chat_message_citations
    // (service-role write — RLS forbids anon/authenticated INSERT). When
    // absent or invalid, persistence silently no-ops so legacy callers see
    // zero observable change.
    //
    // We strip message_id from the body before any path that forwards to
    // Anthropic — same hygiene rule as case_id and rag_context. We also
    // capture case_id ONCE here, before the active-case branch deletes it
    // below, so the persistence row carries a real case_id.
    const messageIdRaw = (body as { message_id?: unknown }).message_id;
    const persistMessageId = isValidMessageId(messageIdRaw)
      ? messageIdRaw
      : null;
    const persistCaseId = typeof body.case_id === "string" ? body.case_id : null;
    const persistUserId = isAnon ? null : gate.user.id;
    delete (body as { message_id?: unknown }).message_id;

    // Enforce allowed model
    if (!body.model || !ALLOWED_MODELS.has(body.model)) {
      body.model = "claude-haiku-4-5-20251001";
    }

    // Enforce limits — global 4096 cap applies to everyone.
    body.max_tokens = Math.min(body.max_tokens || MAX_TOKENS_LIMIT, MAX_TOKENS_LIMIT);

    // 2026-05-05 DEMO RESTORE: tighten the cap for anon callers to
    // ANON_MAX_TOKENS (500). This is a defence-in-depth bound on per-call
    // cost — even if the rate-limit (3/min/IP) is somehow bypassed, an anon
    // caller cannot get a full-cost 4096-token response. Authenticated
    // users keep the full 4096 cap unchanged.
    if (isAnon) {
      body.max_tokens = Math.min(body.max_tokens, ANON_MAX_TOKENS);
    }

    if (Array.isArray(body.messages) && body.messages.length > MAX_MESSAGES) {
      body.messages = body.messages.slice(-MAX_MESSAGES);
    }

    // Reasoning Trail v1 (2026-05-05): server-side complexity classifier.
    // Decides per-turn whether to attach an extended-thinking budget so the
    // client doesn't have to. Anon callers (max_tokens clamped to 500) never
    // get thinking — the budget would exceed max_tokens and error the API.
    // Authenticated users get medium (2K) by default, complex (6K) when
    // the message is long or contains legal keywords.
    //
    // We honour any pre-existing `body.thinking` set by the client — only
    // overwrite when the field is absent.
    if (body.thinking === undefined) {
      const inferred = classifyComplexity(body.messages ?? [], isAnon, {
        hasTools: Array.isArray(body.tools) && body.tools.length > 0,
      });
      if (inferred !== null) {
        body.thinking = inferred;
      }
    }

    // ── Case Memory injection (Pkg 1.B, 2026-05-06) ──────────────────────
    // When the chat call carries `case_id`, load the user's active case via
    // RLS-bound RPC and fold an <active_case> block into the system prompt.
    // The model now reasons against a real case file (parties, timeline,
    // open questions, recent docs) instead of stateless turns.
    //
    // - Missing/invalid case_id → silent no-op (chat continues unchanged).
    // - Non-UUID case_id → 400 BadRequest, callers must pass a real UUID
    //   (matches the SupabaseService.requireUuid contract on the client).
    // - RPC returns null (case missing or RLS-blocked) → silent no-op.
    // - Total system-prompt size guard runs AFTER injection so the 200 KB
    //   cap covers base + RAG + memory + active_case combined.
    if (body.case_id !== undefined && body.case_id !== null) {
      if (typeof body.case_id !== "string" || !isValidCaseId(body.case_id)) {
        return new Response(
          JSON.stringify({ error: "case_id must be a UUID" }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          },
        );
      }
      // Authenticated callers only — anon callers cannot own a case.
      if (!isAnon) {
        const payload = await loadActiveCase(body.case_id, authHeader);
        applyActiveCaseToBody(body, payload);
      }
      // Strip the field before forwarding — Anthropic does not know it.
      delete body.case_id;
    }

    // FIX-4 (Sprint 0): block the "free Claude proxy" abuse vector.
    // Legit Advocat prompts always begin with a recognised identity marker
    // (see system_prompt_guard.ts). Anything else — "Respond in pirate
    // English", "You are ChatGPT", plain code-generation prompts —
    // is rejected with 400 so the caller gets a clear signal rather than
    // a silent rewrite. Also enforces the 50 KB size cap.
    const guard = validateSystemPrompt(body.system);
    if (guard.kind === "reject") {
      return new Response(
        JSON.stringify({
          error: "system prompt is server-controlled",
          details: guard.reason,
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    if (!CLAUDE_API_KEY) {
      return jsonError("API key not configured", 500);
    }

    // FIX-1 (Sprint 0): enable prompt caching. Wraps body.system in the
    // content-block shape with cache_control: ephemeral for blocks large
    // enough to pay back the 1.25x write cost. Flips unit economics from
    // −€0.11/user to +€2.39/user — see docs/performance/05-cost.md §2.5.
    applyPromptCaching(body);

    // ── Legal Planner mode (Pkg 6, 2026-05-07) ───────────────────────────
    // When the client passes `mode: "legal_planner"` we run the three-pass
    // planner+executor+critique loop and return a single non-streaming
    // JSON response. The loop:
    //   1. Planner   (Sonnet, temp=0.0, ≤500 tok)
    //   2. Executor  (Sonnet, temp=0.2, ≤4096 tok) — citation markers
    //   3. Critique  (Haiku,  temp=0.0, ≤300 tok)
    //   4. Optional ONE-SHOT regen if material_gap=true
    //
    // The Dart side gates this on (Pro tier && enable_planner_for_legal_turns
    // && looksLegalish). Server-side defence: we still verify the user is
    // authenticated (gate above caught anon already). We also do NOT enable
    // the planner for streaming requests — the loop is non-streaming by
    // design (3-4 sequential round-trips), and mixing it with `stream=true`
    // would silently degrade to a single-pass response.
    const plannerMode = (body as { mode?: unknown }).mode === "legal_planner";
    delete (body as { mode?: unknown }).mode;
    if (plannerMode && !body.stream && !isAnon) {
      const systemPrompt = typeof body.system === "string"
        ? body.system
        : Array.isArray(body.system)
          // applyPromptCaching may have wrapped system in content-blocks;
          // unwrap to a plain string for the orchestrator.
          ? (body.system as Array<{ text?: string }>)
            .map((b) => b.text ?? "")
            .join("")
          : "";
      const messages = Array.isArray(body.messages)
        ? body.messages as Array<{ role: string; content: string }>
        : [];

      // ── Consilium upgrade path (Phase 2, 2026-05-07) ─────────────────────
      // For complex multi-angle legal questions, escalate to the 4-role
      // consilium (Процессуалист + Материальный юрист + Тактик + Risk Auditor)
      // instead of the 3-pass planner. shouldRunConsilium() uses Haiku to
      // classify in ~200ms; on any error it returns false so we fall through
      // to the existing planner path.
      //
      // The consilium runs with SSE streaming so we switch the response to
      // text/event-stream. The ragContext is the joined chunk texts from the
      // ragChunks already extracted above; caseContext is empty string because
      // applyActiveCaseToBody already folded it into systemPrompt.
      const userMessage = messages.length > 0
        ? String(messages[messages.length - 1].content ?? "")
        : "";
      if (userMessage) {
        const useConsilium = await shouldRunConsilium(userMessage, CLAUDE_API_KEY);
        if (useConsilium) {
          const ragContext = ragChunks
            .map((c) => c.body ?? "")
            .filter(Boolean)
            .join("\n\n");

          const { readable, writable } = new TransformStream<Uint8Array, Uint8Array>();
          const writer = writable.getWriter();
          const encoder = new TextEncoder();

          // Run consilium asynchronously — the stream closes itself when done.
          runConsilium({
            userMessage,
            systemPrompt,
            ragContext,
            caseContext: "",
            anthropicApiKey: CLAUDE_API_KEY,
            onEvent: (event) => {
              const frame = `data: ${JSON.stringify(event)}\n\n`;
              writer.write(encoder.encode(frame)).catch(() => {});
            },
          }).finally(() => {
            writer.close().catch(() => {});
          });

          return new Response(readable, {
            status: 200,
            headers: {
              ...corsHeaders,
              "Content-Type": "text/event-stream",
              "Cache-Control": "no-cache",
              "Connection": "keep-alive",
              "X-Accel-Buffering": "no",
              "X-Advocat-Mode": "consilium",
            },
          });
        }
      }
      // ── End consilium upgrade path ────────────────────────────────────────

      try {
        const loopResult = await runLegalPlannerLoop({
          apiKey: CLAUDE_API_KEY,
          systemPrompt,
          messages,
          messageId: persistMessageId ?? undefined,
          traceWriter: persistMessageId
            ? (trace) =>
              persistPlannerTrace(trace, {
                supabaseUrl: SUPABASE_URL,
                serviceRoleKey: SUPABASE_SERVICE_ROLE_KEY,
              })
            : undefined,
        });

        // Reuse Pkg 2 verifier on the final draft. Reuse Pkg 0 UPL footer
        // is already in `systemPrompt` (system_prompts.dart bakes it in
        // for every assistant turn). The verifier downgrades unverified
        // markers — invented citations don't earn a "verified" badge.
        const citations = verifyCitations(loopResult.replyText, ragChunks);

        if (
          persistMessageId !== null &&
          persistUserId !== null &&
          persistCaseId !== null &&
          citations.length > 0
        ) {
          const rows = buildCitationRows({
            message_id: persistMessageId,
            user_id: persistUserId,
            case_id: persistCaseId,
            citations,
          });
          await persistCitations(rows, {
            supabaseUrl: SUPABASE_URL,
            serviceRoleKey: SUPABASE_SERVICE_ROLE_KEY,
          });
        }

        // Shape: mirror the non-streaming Anthropic response so the
        // existing Flutter parser keeps working. `mode: "legal_planner"`
        // is echoed back for client-side telemetry / trace fetch.
        const augmented = {
          mode: "legal_planner",
          content: [{ type: "text", text: loopResult.replyText }],
          citations,
          message_id: persistMessageId ?? undefined,
          planner: {
            regenerated_once: loopResult.regeneratedOnce,
            latency_ms: loopResult.latencyMs,
            cost_cents: loopResult.costCents,
          },
        };
        return new Response(JSON.stringify(augmented), {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      } catch (e) {
        // Planner failure → fall through to single-pass. The user still
        // gets an answer; the trace just isn't recorded. Loud log so
        // ops can see the failure rate without the user noticing.
        console.warn(
          `claude-proxy: planner mode failed, falling back to single-pass: ${
            String(e).slice(0, 300)
          }`,
        );
      }
    }

    // ── Tool-use injection ────────────────────────────────────────────────
    // Must be BEFORE the streaming branch so tools are available in BOTH
    // streaming and non-streaming modes. Without this, Claude sees no tools
    // during streaming and emits raw XML tool-call text to the client.
    if (!isAnon && !Array.isArray(body.tools)) {
      body.tools = ASSISTANT_TOOLS;
    }

    // Streaming mode — pipe SSE events from Claude directly to client.
    // When tools are injected, force non-streaming so tool_use blocks are
    // handled server-side and never leak raw XML to the client.
    if (body.stream && Array.isArray(body.tools) && body.tools.length > 0) {
      body.stream = false;
    }

    if (body.stream) {
      const claudeStreamResponse = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: buildAnthropicHeaders(CLAUDE_API_KEY),
        body: JSON.stringify(body),
      });

      if (!claudeStreamResponse.ok) {
        const errorText = await claudeStreamResponse.text();
        // Pre-launch (2026-04-29): translate 429 / 529 into a friendly
        // shape so the Flutter client can show a localized message
        // ("service is temporarily overloaded, try again in 1-2 min")
        // instead of the generic «Временная ошибка AI». All other
        // statuses keep the legacy { error: <text> } body.
        const mapped = mapAnthropicError({
          status: claudeStreamResponse.status,
          body: errorText,
          retryAfter: claudeStreamResponse.headers.get("retry-after"),
        });
        return new Response(JSON.stringify(mapped.body), {
          status: mapped.status,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      // ── Streaming citations (Pkg 2 closeout, design §9 risk #2) ────────
      // Wrap the upstream Anthropic SSE pipe with a TransformStream that
      // (a) forwards every byte unchanged so the Flutter UI keeps rendering
      // text deltas live, and (b) accumulates the assistant's reply text
      // into a shadow buffer. On message_stop / upstream close, the wrapper
      // runs the verifier on the assembled text and APPENDS one trailing
      // SSE frame `event: citations\ndata: {citations:[...], message_id}\n\n`.
      // The Flutter SSE parser routes that named event to the citation chip
      // updater. Persistence opt-in is the same as the non-streaming branch:
      // when persistMessageId / persistCaseId / persistUserId are all set,
      // the wrap fires onCitations to upsert rows via service-role.
      const wrappedBody = claudeStreamResponse.body === null
        ? null
        : wrapAnthropicStreamWithCitations(claudeStreamResponse.body, {
          ragChunks,
          messageId: persistMessageId,
          onCitations: async (citations) => {
            if (
              persistMessageId === null ||
              persistUserId === null ||
              persistCaseId === null ||
              citations.length === 0
            ) {
              return;
            }
            const rows = buildCitationRows({
              message_id: persistMessageId,
              user_id: persistUserId,
              case_id: persistCaseId,
              citations,
            });
            await persistCitations(rows, {
              supabaseUrl: SUPABASE_URL,
              serviceRoleKey: SUPABASE_SERVICE_ROLE_KEY,
            });
          },
        });
      return new Response(wrappedBody, {
        status: 200,
        headers: {
          ...corsHeaders,
          "Content-Type": "text/event-stream",
          "Cache-Control": "no-cache",
          "Connection": "keep-alive",
          "X-Accel-Buffering": "no",
        },
      });
    }

    // Non-streaming mode (existing behavior)
    const claudeResponse = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: buildAnthropicHeaders(CLAUDE_API_KEY),
      body: JSON.stringify(body),
    });

    // Happy path: forward Anthropic's JSON augmented with grounded citations.
    if (claudeResponse.ok) {
      const result = await claudeResponse.json() as {
        content?: unknown;
        stop_reason?: string;
        [key: string]: unknown;
      };

      // ── Tool-use execution (2026-05-07) ───────────────────────────────
      // When Anthropic returns stop_reason="tool_use", extract the
      // tool_use blocks, execute them (send_email / generate_pdf), and
      // send ONE follow-up call to Anthropic so the model can produce a
      // final user-facing text reply incorporating the tool results.
      //
      // Design constraints:
      //   - Max ONE tool loop iteration (avoids runaway chains).
      //   - Tool execution errors are surfaced as tool_result.is_error=true;
      //     the follow-up call lets the model explain the failure gracefully.
      //   - Only authenticated callers (isAnon=false) reach this branch
      //     because tools are never injected for anon.
      //   - We skip the loop if the body had stream=true (shouldn't happen
      //     in the non-streaming branch, but belt+suspenders).
      if (
        !isAnon &&
        result.stop_reason === "tool_use" &&
        Array.isArray(result.content)
      ) {
        const toolBlocks = extractToolUseBlocks(result.content);
        if (toolBlocks.length > 0) {
          const toolResults = await executeToolCalls(
            toolBlocks,
            authHeader,
            gate.user.id,
          );

          // Build follow-up messages: existing messages + assistant turn +
          // tool results as a "user" turn (Anthropic's tool_result protocol).
          const followUpMessages = [
            ...(Array.isArray(body.messages) ? body.messages : []),
            { role: "assistant", content: result.content },
            { role: "user", content: toolResults },
          ];

          // Strip tools from the follow-up so the model produces a text reply.
          const followUpBody = {
            ...body,
            messages: followUpMessages,
            tools: undefined,
            // Allow the full token budget for the final answer.
            max_tokens: isAnon ? ANON_MAX_TOKENS : MAX_TOKENS_LIMIT,
          };
          delete followUpBody.tools;

          const followUpResponse = await fetch(
            "https://api.anthropic.com/v1/messages",
            {
              method: "POST",
              headers: buildAnthropicHeaders(CLAUDE_API_KEY),
              body: JSON.stringify(followUpBody),
            },
          );

          if (followUpResponse.ok) {
            const followUpResult = await followUpResponse.json() as {
              content?: unknown;
              [key: string]: unknown;
            };
            // Run citations on the follow-up text.
            const followUpText = concatAnthropicTextBlocks(
              followUpResult.content,
            );
            const followUpCitations = verifyCitations(followUpText, ragChunks);

            // The client sent stream:true so it expects SSE, not JSON.
            // Wrap the follow-up result as synthetic SSE so the Flutter
            // SSE parser receives it correctly (message_start → text deltas
            // → message_stop). This avoids the client hanging on a silent
            // JSON response it doesn't know how to parse.
            const toolsExecuted = toolBlocks.map((b) => b.name);
            const encoder = new TextEncoder();
            const sseBody = buildSseFromAnthropicResult(
              followUpResult,
              followUpCitations,
              persistMessageId,
              toolsExecuted,
            );
            return new Response(encoder.encode(sseBody), {
              status: 200,
              headers: {
                ...corsHeaders,
                "Content-Type": "text/event-stream",
                "Cache-Control": "no-cache",
              },
            });
          }
          // Follow-up call failed — fall through to return the raw tool_use
          // response so the client isn't left with a total failure.
          console.warn(
            `claude-proxy: tool follow-up call failed HTTP ${followUpResponse.status}`,
          );
        }
      }
      // ── End tool-use execution ─────────────────────────────────────────

      // ── Grounding verifier (Pkg 2) ─────────────────────────────────────
      // Pure regex + Map lookup against ragChunks (already in memory from
      // this turn). p95 < 50 ms per design. Never throws; returns [] on
      // empty inputs so legacy callers (no rag_context) keep working.
      const replyText = concatAnthropicTextBlocks(
        result.content,
      );
      const citations = verifyCitations(replyText, ragChunks);

      // ── Persistence (Pkg 2 closeout) ──────────────────────────────────
      // Opt-in via body.message_id (validated above as `persistMessageId`).
      // Required prereqs: (1) valid UUID, (2) authenticated user, (3) a
      // case_id was on the request, (4) verifier produced rows. Any
      // missing prereq → silent no-op. Errors are logged-and-swallowed
      // inside persistCitations — never block the chat reply.
      if (
        persistMessageId !== null &&
        persistUserId !== null &&
        persistCaseId !== null &&
        citations.length > 0
      ) {
        const rows = buildCitationRows({
          message_id: persistMessageId,
          user_id: persistUserId,
          case_id: persistCaseId,
          citations,
        });
        await persistCitations(rows, {
          supabaseUrl: SUPABASE_URL,
          serviceRoleKey: SUPABASE_SERVICE_ROLE_KEY,
        });
      }

      // Augmented response — citations[] always present (back-compat
      // with Flutter parser which expects the field). message_id echoed
      // back ONLY when persistence was opted in, so the client can wire
      // its chat_messages row to the same UUID.
      const augmented = persistMessageId !== null
        ? { ...result, citations, message_id: persistMessageId }
        : { ...result, citations };
      return new Response(JSON.stringify(augmented), {
        status: claudeResponse.status,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Error path: map 429 / 529 to the friendly shape (see comment in
    // streaming branch above). Other 4xx/5xx keep the legacy body so
    // upstream callers (auth/quota/etc.) keep working unchanged.
    const errorText = await claudeResponse.text();
    const mapped = mapAnthropicError({
      status: claudeResponse.status,
      body: errorText,
      retryAfter: claudeResponse.headers.get("retry-after"),
    });
    return new Response(JSON.stringify(mapped.body), {
      status: mapped.status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: "Internal error", details: String(error) }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

/**
 * Server-side quota check (SECURITY 2026-05-04 U3).
 *
 * Calls `check-ai-quota` with action=consume so the counter only increments
 * when we actually proceed to forward to Anthropic. Returns:
 *   { ok: true,  payload }       — caller may proceed.
 *   { ok: false, payload }       — caller is over the free-tier cap.
 *
 * Failure modes (network error, quota service down, malformed response)
 * intentionally fail OPEN: we log and let the request through. Rationale:
 * a quota outage should not also take chat down. The much-bigger U1 (anon
 * key cost burn) is already neutralised by the auth gate above; this
 * function exists only to stop authenticated free-tier users from
 * curl-bypassing the 7-msg cap, which is a strictly smaller blast radius
 * than killing chat for everyone during a partial outage.
 */
/**
 * Wrap a completed Anthropic non-streaming result as synthetic SSE so the
 * Flutter client (which sent stream:true) can parse it correctly.
 * Emits: message_start → content_block_start → text deltas → content_block_stop
 *        → message_delta → message_stop → (optional citations frame).
 */
function buildSseFromAnthropicResult(
  result: { content?: unknown; usage?: unknown; model?: unknown; id?: unknown; [key: string]: unknown },
  citations: unknown[],
  messageId: string | null,
  toolsExecuted: string[],
): string {
  const text = concatAnthropicTextBlocks(result.content);
  const model = (result.model as string) ?? "claude-sonnet";
  const msgId = (result.id as string) ?? `msg_tool_${Date.now()}`;
  const usage = (result.usage as Record<string, unknown>) ?? {};

  const frames: string[] = [];
  const sse = (event: string, data: unknown) =>
    `event: ${event}\ndata: ${JSON.stringify(data)}\n\n`;

  frames.push(sse("message_start", {
    type: "message_start",
    message: { id: msgId, type: "message", role: "assistant", model, content: [], usage },
  }));

  frames.push(sse("content_block_start", {
    type: "content_block_start", index: 0,
    content_block: { type: "text", text: "" },
  }));

  // Chunk text into ~200-char deltas so Flutter renders progressively.
  const chunkSize = 200;
  for (let i = 0; i < text.length; i += chunkSize) {
    frames.push(sse("content_block_delta", {
      type: "content_block_delta", index: 0,
      delta: { type: "text_delta", text: text.slice(i, i + chunkSize) },
    }));
  }

  frames.push(sse("content_block_stop", { type: "content_block_stop", index: 0 }));
  frames.push(sse("message_delta", {
    type: "message_delta",
    delta: { stop_reason: "end_turn" },
    usage: { output_tokens: Math.ceil(text.length / 4) },
  }));
  frames.push(sse("message_stop", { type: "message_stop" }));

  // Citations frame (Pkg 2 format) — picked up by Flutter SSE parser.
  if (citations.length > 0 || toolsExecuted.length > 0) {
    frames.push(`event: citations\ndata: ${JSON.stringify({
      citations,
      message_id: messageId,
      tool_calls_executed: toolsExecuted,
    })}\n\n`);
  }

  return frames.join("");
}

async function checkQuota(
  authHeader: string,
): Promise<{ ok: boolean; payload: Record<string, unknown> | null }> {
  try {
    const res = await fetch(`${SUPABASE_URL}/functions/v1/check-ai-quota`, {
      method: "POST",
      headers: {
        "Authorization": authHeader,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ action: "consume" }),
    });
    if (!res.ok) {
      console.warn(
        `claude-proxy: check-ai-quota returned ${res.status}; failing open`,
      );
      return { ok: true, payload: null };
    }
    const payload = await res.json() as Record<string, unknown>;
    const allowed = payload?.allowed === true;
    return { ok: allowed, payload };
  } catch (e) {
    console.warn(
      `claude-proxy: check-ai-quota fetch threw; failing open: ${
        String(e).slice(0, 200)
      }`,
    );
    return { ok: true, payload: null };
  }
}
