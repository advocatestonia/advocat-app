import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
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
import {
  buildEmbedFn,
  buildRagOnlyJsonResponse,
  buildRagOnlyResponse,
  buildRagOnlySseResponse,
  isCreditBalanceError,
} from "./credit_fallback.ts";
import { classifyComplexity } from "./classify_complexity.ts";
import {
  classifyQuery,
  estimateCostCents,
  formatTelemetry,
  HAIKU_MODEL,
  SONNET_MODEL,
} from "./model_router.ts";
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
  enforceCitations,
  summariseViolations,
} from "../_shared/citation_enforcement.ts";
import {
  buildCitationRows,
  isValidMessageId,
  persistCitations,
} from "./citation_persistence.ts";
import { wrapAnthropicStreamWithCitations } from "./streaming_citations.ts";
import { runLegalPlannerLoop } from "../_shared/legal_planner.ts";
import { persistPlannerTrace } from "./planner_trace_persistence.ts";
import {
  buildSelfCorrectionAddendum,
  type CorrectionRow,
  formatCorrectionsBlock,
  retrieveCorrections,
  selfCorrectionScan,
} from "../_shared/corrections_retriever.ts";
import { enqueueGoldCandidate } from "../_shared/gold_enqueue.ts";
import { runConsilium, shouldRunConsilium } from "../_shared/consilium.ts";
import { extractAndPatchFacts } from "../_shared/fact_extractor.ts";
import { appendAdviceDigest } from "../_shared/advice_digest.ts";
import { LEGAL_LOOKUP_TOOL_USE_INSTRUCTION } from "../_shared/legal_lookup.ts";
import {
  ASSISTANT_TOOLS,
  executeToolCalls,
  extractToolUseBlocks,
} from "./tool_handlers.ts";
import {
  type AnthropicShapedResponse,
  callLlamaFallback,
  type FallbackReason,
  fallbackReasonFromStatus,
  forceFallbackEnabled,
  LLAMA_MODEL_ID,
  LLAMA_TIMEOUT_MS,
  shouldFallback,
} from "./llama_fallback.ts";
import {
  anonDisabledResponse,
  flagOn,
  maintenanceResponse,
} from "../_shared/kill_switches.ts";

const CLAUDE_API_KEY = Deno.env.get("CLAUDE_API_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY =
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
// Memory-of-Wrong-Answers retrieval (Pkg #13). OPENAI_API_KEY is optional —
// when absent the retrieval gracefully no-ops (corrections is an additive
// uplift, not a blocker).
//
// 2026-05-14 (lesson_corrections_retrieval_debug.md): default lowered from
// 0.75 → 0.45 because cross-language queries (RU user question → FI/EN
// correction row) produce cosine similarities ~0.45-0.55 with OpenAI
// text-embedding-3-small. At 0.75 every cross-language query returned
// zero matches and the HOL §114 / KHO restoration lesson never fired on
// gold-001 or gold-009 (eval baseline). At 0.45 we still cleanly reject
// noise (unrelated queries score <0.40) but recover the cross-language
// recall the corpus was designed for. Same-language queries score >0.85
// so we never lose precision on them.
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";
const CORRECTIONS_SIMILARITY_THRESHOLD = parseFloat(
  Deno.env.get("CORRECTIONS_SIMILARITY_THRESHOLD") ?? "0.45",
);

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
// ошибка AI"). We restored demo with a HARD CAP that keeps cost bounded.
//
// 2026-05-13 TIGHTEN (post $0-balance): owner had to top up Anthropic
// credits; to stretch each top-up further for PAID users we cut anon and
// auth limits to a third:
//   • anonymousPerMinute   3 → 1
//   • ANON_MAX_TOKENS    500 → 200
//   • RATE_LIMIT_MAX      10 → 5     (auth users / minute / IP bucket)
// Worst case per anon IP: 1 call/min × 200 tokens × ~$1.5/1M out tokens
// (Haiku 4.5) ≈ $0.018/hour (was $0.13). Free-tier never burns through a
// $20 wallet in a day even under abuse. Authenticated free-tier users are
// also rate-limited at 5/min so a paid user's call always wins the race.
// -----------------------------------------------------------------------------

const RATE_LIMIT_MAX = 5;
const ANON_RATE_LIMIT_PER_MINUTE = 1;

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
const ANON_MAX_TOKENS = 200;
const MAX_MESSAGES = 20;

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // ── 0. Kill switch: CLAUDE_PROXY_MAINTENANCE ──────────────────────────
  // Severe shutdown — trumps every downstream check (auth, quota, anon).
  // See _shared/kill_switches.ts and /tmp/hn_launch_runbook.md.
  if (flagOn("CLAUDE_PROXY_MAINTENANCE")) {
    return maintenanceResponse();
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

    // ── 1b. Kill switch: ANON_CHAT_DISABLED ───────────────────────────────
    // Lets us shut the open demo while paid users keep working. Runs AFTER
    // the auth gate so we know `isAnon` reliably.
    if (isAnon && flagOn("ANON_CHAT_DISABLED")) {
      return anonDisabledResponse();
    }

    // ── 2. Server-side quota check (SECURITY U3) ──────────────────────────
    // Even an authenticated free-tier user cannot bypass the 7-message cap
    // by calling this endpoint directly. We forward the caller's JWT so
    // check-ai-quota's RLS-aware `auth.uid()` resolves correctly.
    //
    // For anon callers, check-ai-quota returns a synthetic
    // { allowed: true, plan: "free" } payload (see check-ai-quota/index.ts
    // lines 75-84) — no real per-IP counter is persisted server-side. The
    // bound on anon abuse is the rate-limit (1/min/IP, see ANON_RATE_LIMIT_PER_MINUTE)
    // + ANON_MAX_TOKENS clamp below.
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

    // ── Smart model routing (2026-05-11) ─────────────────────────────────
    // Pre-screen the user's last message with a tiny Haiku call (~$0.00075)
    // to decide whether the main response really needs Sonnet. The router:
    //   - Skips entirely for anon callers (already Haiku-clamped to 500 tok)
    //   - Skips when the caller explicitly requested Sonnet (Pro UI override)
    //   - Falls back to a heuristic on any failure (never blocks chat)
    //
    // We honour the `router_skip` body flag so internal callers (planner,
    // consilium, smoke tests) can opt out. The flag is stripped before
    // forwarding to Anthropic.
    const routerSkip = (body as { router_skip?: unknown }).router_skip === true;
    delete (body as { router_skip?: unknown }).router_skip;

    // Detect explicit Sonnet request — Pro users clicking "use Sonnet for
    // this turn" pass body.model === SONNET_MODEL. We keep their choice.
    const clientRequestedSonnet = body.model === SONNET_MODEL ||
      body.model === "claude-3-5-sonnet-20241022";

    if (!routerSkip && !isAnon && !clientRequestedSonnet && CLAUDE_API_KEY) {
      const cls = await classifyQuery(body.messages ?? [], isAnon, {
        apiKey: CLAUDE_API_KEY,
      });
      const targetModel = cls.recommended_model === "sonnet"
        ? SONNET_MODEL
        : HAIKU_MODEL;
      // Only downgrade-aware: if the client picked Sonnet but router says
      // Haiku is enough, switch to Haiku and trim max_tokens.
      // If the client picked Haiku and router agrees, keep Haiku.
      // If the client picked Haiku but router says complex → upgrade to Sonnet.
      const previousModel = body.model;
      body.model = targetModel;
      // Cap max_tokens to the recommendation (clients usually request more
      // than they need). Never raise above what the client asked for.
      if (typeof body.max_tokens === "number" && body.max_tokens > 0) {
        body.max_tokens = Math.min(body.max_tokens, cls.recommended_max_tokens);
      } else {
        body.max_tokens = cls.recommended_max_tokens;
      }
      // Telemetry: log one structured line per routed turn so we can later
      // build a dashboard and measure routing accuracy.
      const inTokens = Array.isArray(body.messages)
        ? body.messages.reduce((acc: number, m: { content?: unknown }) => {
            const t = typeof m.content === "string" ? m.content : "";
            return acc + Math.ceil(t.length / 4);
          }, 0)
        : 0;
      const costCents = estimateCostCents(
        targetModel,
        inTokens,
        body.max_tokens ?? 0,
      );
      console.log(
        formatTelemetry(cls, targetModel, costCents) +
        ` previous_model=${previousModel}`,
      );
    }

    // Enforce limits — global 4096 cap applies to everyone.
    body.max_tokens = Math.min(body.max_tokens || MAX_TOKENS_LIMIT, MAX_TOKENS_LIMIT);

    // 2026-05-05 DEMO RESTORE: tighten the cap for anon callers to
    // ANON_MAX_TOKENS (200 post 2026-05-13 tighten). This is a
    // defence-in-depth bound on per-call cost — even if the rate-limit
    // (1/min/IP) is somehow bypassed, an anon caller cannot get a
    // full-cost 4096-token response. Authenticated users keep the
    // 32000 cap unchanged.
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

    // ── Memory-of-Wrong-Answers retrieval (Pkg #13) — GLOBAL ────────────────
    // 2026-05-14 (lesson_corrections_retrieval_debug.md): before today,
    // retrieval was gated behind `mode: "legal_planner"`. The Flutter client
    // only sets that mode for Pro users with the planner-enabled setting AND
    // a query that looksLegalish — and the eval harness never sets it. As a
    // result the gold-001 / gold-009 HOL §114 / KHO restoration questions
    // went through the legacy single-pass path with NO corrections injection.
    //
    // Fix: lift retrieval to the top-level request handler. Three paths
    // consume the result:
    //   1. Legacy single-pass    — prepends to body.system below.
    //   2. Legal-planner mode    — uses correctionsBlock passed into
    //                              runLegalPlannerLoop (it does the prepend
    //                              once and only once).
    //   3. Consilium mode        — explicitly prepends to its systemPrompt
    //                              because runConsilium has no correctionsBlock
    //                              parameter.
    //
    // To avoid DOUBLE injection in the planner path, we prepend to body.system
    // ONLY when the request is NOT going to enter the planner branch.
    //
    // Fails open on every failure mode (see corrections_retriever.ts):
    //   • OPENAI_API_KEY missing      → empty rows, empty block, no prepend.
    //   • match_corrections RPC fails → empty rows, empty block, no prepend.
    //   • Embedding cap (1536) fails  → empty rows, empty block, no prepend.
    const globalUserMessage = Array.isArray(body.messages) && body.messages.length > 0
      ? String((body.messages[body.messages.length - 1] as { content?: unknown }).content ?? "")
      : "";
    const willEnterPlannerBranch =
      (body as { mode?: unknown }).mode === "legal_planner" &&
      !body.stream &&
      !isAnon;
    let globalCorrectionsRows: CorrectionRow[] = [];
    let globalCorrectionsBlock = "";
    if (globalUserMessage && OPENAI_API_KEY) {
      globalCorrectionsRows = await retrieveCorrections({
        question: globalUserMessage,
        jurisdiction: null,
        threshold: CORRECTIONS_SIMILARITY_THRESHOLD,
        supabaseUrl: SUPABASE_URL,
        serviceRoleKey: SUPABASE_SERVICE_ROLE_KEY,
        openaiApiKey: OPENAI_API_KEY,
      });
      globalCorrectionsBlock = formatCorrectionsBlock(globalCorrectionsRows);
      // Only prepend to body.system for paths that don't have their own
      // prepend logic (legacy single-pass, streaming, anon, etc).
      // The planner branch does its own prepend inside runLegalPlannerLoop.
      if (globalCorrectionsBlock && !willEnterPlannerBranch) {
        if (typeof body.system === "string") {
          body.system = `${globalCorrectionsBlock}\n\n${body.system}`;
        } else if (body.system == null) {
          body.system = globalCorrectionsBlock;
        }
        // If body.system is already an array (caller pre-wrapped) we leave it
        // alone — applyPromptCaching would rewrap our string anyway.
      }
    }

    // ── legal_lookup TOOL USE wiring (Phase 2 fix, 2026-05-13) ──────────────
    // The tool is registered in ASSISTANT_TOOLS and auto-attached below
    // (≈line 800) for non-anon callers, BUT the TOOL USE directive only lived
    // inside legal_planner.ts EXECUTOR_INSTRUCTIONS_HEADER — which fires only
    // when the client passes `mode: "legal_planner"`. Most prod chat turns
    // don't pass that mode, so Claude never saw an instruction to invoke the
    // tool. Eval Phase 2 measured citation_validity flat at 2.10 because of
    // exactly this gap.
    //
    // Fix: inject the directive into body.system whenever legal_lookup will
    // actually be available for this turn. Three gates:
    //   1. Skip anon — anon never gets tools (see !isAnon at body.tools=…).
    //   2. Skip legal_planner mode — its own header already covers this.
    //   3. If the caller pre-set body.tools to an array, only inject when
    //      legal_lookup is in it. If they did NOT pre-set (most callers),
    //      we know ASSISTANT_TOOLS will be auto-attached and includes the
    //      tool, so inject.
    //
    // Idempotent: if the directive substring is already present we skip,
    // so the planner branch's own header is never duplicated.
    if (!isAnon && !willEnterPlannerBranch) {
      const callerToolsArray = Array.isArray(body.tools)
        ? (body.tools as Array<{ name?: unknown }>)
        : null;
      const legalLookupWillBeAvailable = callerToolsArray
        ? callerToolsArray.some((t) => t && t.name === "legal_lookup")
        : true; // ASSISTANT_TOOLS auto-injection covers this case
      if (legalLookupWillBeAvailable) {
        const directive = LEGAL_LOOKUP_TOOL_USE_INSTRUCTION;
        const marker = "## TOOL USE — legal_lookup";
        if (typeof body.system === "string") {
          if (!body.system.includes(marker)) {
            body.system = `${body.system}\n\n${directive}`;
          }
        } else if (body.system == null) {
          body.system = directive;
        }
        // Array form (caller pre-wrapped content blocks): leave untouched —
        // applyPromptCaching has not run yet for the string path, and a pre-
        // wrapped array means the caller is asserting full control of the
        // system prompt shape. Conservative: skip rather than mutate.
      }
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

          // 2026-05-14: consilium has no correctionsBlock parameter, and the
          // global retrieval (above) skipped the body.system prepend because
          // willEnterPlannerBranch was true. So we explicitly prepend here so
          // every consilium role sees the learned mistakes. The block is
          // ≤4 KB by formatCorrectionsBlock's cap so this never pushes the
          // system prompt past the 50 KB ceiling.
          const consiliumSystemPrompt = globalCorrectionsBlock
            ? `${globalCorrectionsBlock}\n\n${systemPrompt}`
            : systemPrompt;

          const { readable, writable } = new TransformStream<Uint8Array, Uint8Array>();
          const writer = writable.getWriter();
          const encoder = new TextEncoder();

          // Run consilium asynchronously — the stream closes itself when done.
          runConsilium({
            userMessage,
            systemPrompt: consiliumSystemPrompt,
            ragContext,
            caseContext: "",
            anthropicApiKey: CLAUDE_API_KEY,
            onEvent: (event) => {
              const frame = `data: ${JSON.stringify(event)}\n\n`;
              writer.write(encoder.encode(frame)).catch(() => {});
            },
          }).then((synthesisText) => {
            // Fire-and-forget advice digest after consilium.
            if (!isAnon && persistCaseId && synthesisText) {
              appendAdviceDigest({
                caseId: persistCaseId,
                replyText: synthesisText,
                probabilitySignal: "",
                supabaseUrl: SUPABASE_URL,
                serviceRoleKey: SUPABASE_SERVICE_ROLE_KEY,
                anthropicApiKey: CLAUDE_API_KEY,
              }).catch((e) =>
                console.warn(`advice_digest: consilium: ${String(e).slice(0, 200)}`)
              );
            }
          }).finally(() => {
            writer.close().catch(() => {});
          });

          // Upgrade 2: fire-and-forget fact extraction + advice digest after consilium.
          // runConsilium returns the synthesis text — capture it for digest.
          if (!isAnon && persistCaseId && persistUserId) {
            extractAndPatchFacts({
              caseId: persistCaseId,
              userId: persistUserId,
              conversationText: "",
              userMessage,
              supabaseUrl: SUPABASE_URL,
              serviceRoleKey: SUPABASE_SERVICE_ROLE_KEY,
              anthropicApiKey: CLAUDE_API_KEY,
            }).catch((e) =>
              console.warn(
                `claude-proxy: fact_extractor consilium failed: ${
                  String(e).slice(0, 200)
                }`,
              )
            );
          }

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
        // ── Memory-of-Wrong-Answers — rows reused from global retrieval ─────
        // The top-level handler retrieved corrections and rendered the block.
        // We reuse both here:
        //   • correctionsRows  → for the self-correction reflex's substring
        //                        scan against the planner's draft.
        //   • correctionsBlock → passed to runLegalPlannerLoop which prepends
        //                        it to its synthesized system prompt (this is
        //                        the planner's ONLY exposure to corrections;
        //                        body.system was not prepended for this
        //                        branch — see willEnterPlannerBranch above).
        const correctionsRows: CorrectionRow[] = globalCorrectionsRows;
        const correctionsBlock = globalCorrectionsBlock;

        let loopResult = await runLegalPlannerLoop({
          apiKey: CLAUDE_API_KEY,
          systemPrompt,
          messages,
          messageId: persistMessageId ?? undefined,
          correctionsBlock,
          traceWriter: persistMessageId
            ? (trace) =>
              persistPlannerTrace(trace, {
                supabaseUrl: SUPABASE_URL,
                serviceRoleKey: SUPABASE_SERVICE_ROLE_KEY,
              })
            : undefined,
        });

        if (loopResult.kind === "blocked") {
          return new Response(JSON.stringify({
            mode: "legal_planner",
            content: [{ type: "text", text: loopResult.question }],
            citations: [],
            planner: { blocking_gap: true, latency_ms: loopResult.latencyMs, cost_cents: loopResult.costCents },
          }), { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } });
        }

        // ── Self-correction reflex (Pkg #13) ────────────────────────────────
        // Scan the planner's final draft against the retrieved corrections'
        // wrong_advice phrases. If we caught a paraphrase of a known-wrong
        // pattern, fire ONE additional regen with a DO_NOT_REPEAT addendum.
        // The regen is bounded — runLegalPlannerLoop's own MAX_REGENERATIONS
        // guard caps further iteration inside the planner. Fails open: any
        // error in the scan or the second loop falls through to the first
        // draft so the user always gets an answer.
        if (correctionsRows.length > 0) {
          try {
            const matches = selfCorrectionScan(
              loopResult.replyText,
              correctionsRows,
            );
            if (matches.length > 0) {
              const addendum = buildSelfCorrectionAddendum(matches);
              console.warn(
                `claude-proxy: self-correction reflex fired — ${matches.length} match(es), regenerating`,
              );
              const regenerated = await runLegalPlannerLoop({
                apiKey: CLAUDE_API_KEY,
                systemPrompt,
                messages,
                messageId: persistMessageId ?? undefined,
                correctionsBlock,
                selfCorrectionAddendum: addendum,
                forceRegenForSelfCorrection: true,
                traceWriter: persistMessageId
                  ? (trace) =>
                    persistPlannerTrace(trace, {
                      supabaseUrl: SUPABASE_URL,
                      serviceRoleKey: SUPABASE_SERVICE_ROLE_KEY,
                    })
                  : undefined,
              });
              if (regenerated.kind === "completed") {
                loopResult = regenerated;
              }
            }
          } catch (e) {
            console.warn(
              `claude-proxy: self-correction scan failed (using first draft): ${
                String(e).slice(0, 200)
              }`,
            );
          }
        }

        // Reuse Pkg 2 verifier on the final draft. Reuse Pkg 0 UPL footer
        // is already in `systemPrompt` (system_prompts.dart bakes it in
        // for every assistant turn). The verifier downgrades unverified
        // markers — invented citations don't earn a "verified" badge.
        const citations = verifyCitations(loopResult.replyText, ragChunks);

        // ── Fail-closed enforcement (2026-05-11) ─────────────────────────
        // The verifier only catches WHAT the model marked. It is silent on
        // citations the model SHOULD have marked but did not. The enforcer
        // scans the reply text for known law-citation shapes (TLS § 88,
        // Directive 2019/1152 art 5, ECHR Article 8) and strips any
        // paragraph-level claim that lacks a `[[ref:...:...]]` marker.
        // Generic mentions ("üürilepingu seadustes on sätestatud") are
        // explicitly left alone — see citation_enforcement.ts §4.
        const enforced = enforceCitations(loopResult.replyText, citations);
        if (enforced.violations.length > 0) {
          console.warn(
            `claude-proxy: citation enforcement (planner) stripped ` +
              `${enforced.violations.length} bare cite(s): ${
                JSON.stringify(summariseViolations(enforced.violations))
              }`,
          );
        }
        const enforcedReplyText = enforced.cleanedText;

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

        // Upgrade 2: fire-and-forget fact extraction after planner.
        // loopResult is narrowed to PlannerLoopResult here because the
        // `kind === "blocked"` branch returns early above.
        if (!isAnon && persistCaseId && persistUserId) {
          const plannerUserMessage = messages.length > 0
            ? String(messages[messages.length - 1].content ?? "")
            : "";
          // deno-lint-ignore no-explicit-any
          const _completedResult = loopResult as any;
          extractAndPatchFacts({
            caseId: persistCaseId,
            userId: persistUserId,
            conversationText: _completedResult.replyText as string,
            userMessage: plannerUserMessage,
            supabaseUrl: SUPABASE_URL,
            serviceRoleKey: SUPABASE_SERVICE_ROLE_KEY,
            anthropicApiKey: CLAUDE_API_KEY,
          }).catch((e) =>
            console.warn(
              `claude-proxy: fact_extractor planner failed: ${
                String(e).slice(0, 200)
              }`,
            )
          );
        }

        // Fire-and-forget advice digest after planner (kind==="completed" branch).
        if (!isAnon && persistCaseId) {
          appendAdviceDigest({
            caseId: persistCaseId,
            replyText: loopResult.replyText,
            probabilitySignal: loopResult.plan?.probability_signal ?? "",
            supabaseUrl: SUPABASE_URL,
            serviceRoleKey: SUPABASE_SERVICE_ROLE_KEY,
            anthropicApiKey: CLAUDE_API_KEY,
          }).catch((e) =>
            console.warn(`advice_digest: ${String(e).slice(0, 200)}`)
          );
        }

        // ── Sofia Gold Corpus enqueue (Phase A) ─────────────────────────────
        // Fire-and-forget queue insert. The helper handles sampling
        // (GOLD_CORPUS_SAMPLE_RATE, default 0.5), anon skip, and short-message
        // skip (<50 chars). All failure modes are swallowed inside the helper
        // — the user reply is never blocked on this.
        if (!isAnon && persistUserId) {
          const plannerUserMessage = messages.length > 0
            ? String(messages[messages.length - 1].content ?? "")
            : "";
          enqueueGoldCandidate({
            userId: persistUserId,
            sourceMessageId: persistMessageId ?? null,
            userQuestion: plannerUserMessage,
            aiAnswer: enforcedReplyText,
            aiModel: typeof body.model === "string" ? body.model : null,
            aiCitations: citations.map((c) => c.marker ?? "").filter(Boolean),
            language: null,
            category: null,
            jurisdiction: null,
            supabaseUrl: SUPABASE_URL,
            serviceRoleKey: SUPABASE_SERVICE_ROLE_KEY,
          }).catch(() => {/* helper already logs */});
        }

        // Shape: mirror the non-streaming Anthropic response so the
        // existing Flutter parser keeps working. `mode: "legal_planner"`
        // is echoed back for client-side telemetry / trace fetch.
        // NOTE: we ship `enforcedReplyText` (post-strip) — bare paragraph
        // citations without a marker were stripped above.
        const augmented = {
          mode: "legal_planner",
          content: [{ type: "text", text: enforcedReplyText }],
          citations,
          message_id: persistMessageId ?? undefined,
          planner: {
            regenerated_once: loopResult.regeneratedOnce,
            latency_ms: loopResult.latencyMs,
            cost_cents: loopResult.costCents,
            citation_violations: enforced.violations.length,
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
      // ── Llama fallback path A: ADVOCAT_FORCE_FALLBACK=true ─────────────
      // Manual override (ops drills, ToS contingency) — skip Claude entirely
      // and go straight to Llama. We synthesise SSE from the non-streaming
      // Llama response so the Flutter client (which sent stream:true) still
      // parses the reply correctly. Citation verifier runs on the joined text.
      if (forceFallbackEnabled()) {
        console.warn(
          "claude-proxy: ADVOCAT_FORCE_FALLBACK=true — routing to Llama",
        );
        return await runLlamaFallbackForStream({
          body,
          reason: "force_fallback_env",
          ragChunks,
          persistMessageId,
          persistUserId,
          persistCaseId,
        });
      }

      // Claude call with 30s timeout. Network errors / aborts both surface
      // as caught exceptions and route to Llama; HTTP error statuses are
      // handled below per shouldFallback() classifier.
      let claudeStreamResponse: Response;
      try {
        claudeStreamResponse = await fetchClaudeWithTimeout(body);
      } catch (e) {
        const isAbort = (e as { name?: string })?.name === "AbortError";
        const reason: FallbackReason = isAbort
          ? "claude_timeout"
          : "claude_network_error";
        console.warn(
          `claude-proxy: Claude ${reason} — routing to Llama: ${
            String(e).slice(0, 200)
          }`,
        );
        return await runLlamaFallbackForStream({
          body,
          reason,
          ragChunks,
          persistMessageId,
          persistUserId,
          persistCaseId,
        });
      }

      if (!claudeStreamResponse.ok) {
        // Llama fallback path B: classify the upstream status. 429 and 5xx
        // route to Llama; everything else (4xx other than 429) is forwarded
        // unchanged because Llama wouldn't fix a real client-side bug.
        if (shouldFallback(claudeStreamResponse.status)) {
          const reason = fallbackReasonFromStatus(claudeStreamResponse.status);
          console.warn(
            `claude-proxy: Claude HTTP ${claudeStreamResponse.status} (${reason}) — routing to Llama`,
          );
          // Drain the body so we don't leak the response.
          await claudeStreamResponse.body?.cancel().catch(() => {});
          return await runLlamaFallbackForStream({
            body,
            reason,
            ragChunks,
            persistMessageId,
            persistUserId,
            persistCaseId,
          });
        }
        const errorText = await claudeStreamResponse.text();

        // ── $0-balance graceful degradation (2026-05-13) ──────────────────
        // Anthropic returns 400 with "credit balance" body when the org
        // wallet hits zero. shouldFallback() does NOT route 400 to Llama
        // (Llama wouldn't fix a real client-side bug, normally), so we
        // intercept HERE and ship a RAG-only reply built from law_search
        // instead. The user sees a banner + real statute text — much
        // better than the generic «Временная ошибка AI» they'd get from
        // the mapAnthropicError 400 passthrough.
        if (isCreditBalanceError(claudeStreamResponse.status, errorText)) {
          const fallback = await runCreditExhaustedFallback(
            body,
            true,
            persistMessageId,
          );
          if (fallback) return fallback;
          // No OpenAI key configured — fall through to legacy 400 shape.
        }

        // Pre-launch (2026-04-29): translate 429 / 529 into a friendly
        // shape so the Flutter client can show a localized message
        // ("service is temporarily overloaded, try again in 1-2 min")
        // instead of the generic «Временная ошибка AI». All other
        // statuses keep the legacy { error: <text> } body.
        //
        // NOTE: with fallback active, 429 / 5xx no longer reach this branch
        // (handled above). This stays defensive in case of a future status
        // we'd want translated but NOT fallback'd.
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
          "X-Advocat-Model-Used": (body.model as string) ?? "claude-haiku-4-5-20251001",
        },
      });
    }

    // Non-streaming mode (existing behavior)
    //
    // Llama fallback path A: ADVOCAT_FORCE_FALLBACK=true short-circuits the
    // Claude call entirely (ops drill / ToS contingency).
    if (forceFallbackEnabled()) {
      console.warn(
        "claude-proxy: ADVOCAT_FORCE_FALLBACK=true — routing to Llama",
      );
      return await runLlamaFallbackForJson({
        body,
        reason: "force_fallback_env",
        ragChunks,
        persistMessageId,
        persistUserId,
        persistCaseId,
      });
    }

    let claudeResponse: Response;
    try {
      claudeResponse = await fetchClaudeWithTimeout(body);
    } catch (e) {
      const isAbort = (e as { name?: string })?.name === "AbortError";
      const reason: FallbackReason = isAbort
        ? "claude_timeout"
        : "claude_network_error";
      console.warn(
        `claude-proxy: Claude ${reason} — routing to Llama: ${
          String(e).slice(0, 200)
        }`,
      );
      return await runLlamaFallbackForJson({
        body,
        reason,
        ragChunks,
        persistMessageId,
        persistUserId,
        persistCaseId,
      });
    }

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

            // Fail-closed enforcement on the follow-up reply too. Tool
            // results often prompt the model to summarise law in prose;
            // it can slip in bare § citations without markers there.
            const followUpEnforced = enforceCitations(
              followUpText,
              followUpCitations,
            );
            if (followUpEnforced.violations.length > 0) {
              console.warn(
                `claude-proxy: citation enforcement (tool follow-up) ` +
                  `stripped ${followUpEnforced.violations.length} bare ` +
                  `cite(s): ${
                    JSON.stringify(summariseViolations(followUpEnforced.violations))
                  }`,
              );
              // Replace the text block in result.content so the synthetic
              // SSE downstream sees the cleaned text. We rebuild content
              // as a single text block (the only thing the client renders).
              followUpResult.content = [
                { type: "text", text: followUpEnforced.cleanedText },
              ];
            }

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

      // ── Fail-closed enforcement (2026-05-11) ──────────────────────────
      // Same rationale as the planner branch above: bare paragraph
      // citations without a `[[ref:ACT:PARA]]` marker are stripped before
      // the reply ships. We rebuild `result.content` as a single text
      // block when violations are found so the augmented response
      // downstream (and any caller reading from .content) sees the
      // cleaned text.
      const enforced = enforceCitations(replyText, citations);
      if (enforced.violations.length > 0) {
        console.warn(
          `claude-proxy: citation enforcement stripped ` +
            `${enforced.violations.length} bare cite(s): ${
              JSON.stringify(summariseViolations(enforced.violations))
            }`,
        );
        result.content = [
          { type: "text", text: enforced.cleanedText },
        ];
      }

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
      //
      // model_used metadata: emitted into BOTH the JSON body AND the
      // X-Advocat-Model-Used response header so ops can grep for fallback
      // activations and clients can route quality signals.
      const claudeModelUsed = (body.model as string) ?? "claude-haiku-4-5-20251001";
      const augmented = persistMessageId !== null
        ? {
          ...result,
          citations,
          message_id: persistMessageId,
          model_used: claudeModelUsed,
        }
        : { ...result, citations, model_used: claudeModelUsed };
      return new Response(JSON.stringify(augmented), {
        status: claudeResponse.status,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
          "X-Advocat-Model-Used": claudeModelUsed,
        },
      });
    }

    // Error path: 429 / 5xx → route to Llama fallback. Other 4xx (400/401/
    // 403/404/etc.) keep the legacy shape so upstream callers (auth/quota)
    // keep working unchanged — Llama wouldn't fix a bad request.
    if (shouldFallback(claudeResponse.status)) {
      const reason = fallbackReasonFromStatus(claudeResponse.status);
      console.warn(
        `claude-proxy: Claude HTTP ${claudeResponse.status} (${reason}) — routing to Llama`,
      );
      await claudeResponse.body?.cancel().catch(() => {});
      return await runLlamaFallbackForJson({
        body,
        reason,
        ragChunks,
        persistMessageId,
        persistUserId,
        persistCaseId,
      });
    }

    // Map other 4xx (e.g. 400/401) to the friendly shape (see comment in
    // streaming branch above).
    const errorText = await claudeResponse.text();

    // ── $0-balance graceful degradation (2026-05-13) ──────────────────────
    // Mirror the streaming branch: a 400 with "credit balance" body means
    // the Anthropic wallet is empty. Ship a RAG-only reply instead of the
    // generic 400 passthrough.
    if (isCreditBalanceError(claudeResponse.status, errorText)) {
      const fallback = await runCreditExhaustedFallback(
        body,
        false,
        persistMessageId,
      );
      if (fallback) return fallback;
    }

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

// =============================================================================
// Llama fallback helpers (2026-05-11)
// =============================================================================

/**
 * Call Anthropic with a hard 30s timeout. Returns the raw Response on
 * success (HTTP status may still be 4xx/5xx — caller classifies). Throws on
 * network errors and AbortError (timeout); the caller catches and routes to
 * Llama via runLlamaFallback{ForJson,ForStream}.
 *
 * 30s matches the Llama timeout — symmetric so a Claude tail-latency event
 * doesn't double the user-visible delay (we abort Claude, then try Llama
 * with its own 30s budget = worst case ~60s, acceptable for chat).
 */
async function fetchClaudeWithTimeout(body: unknown): Promise<Response> {
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), LLAMA_TIMEOUT_MS);
  try {
    return await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: buildAnthropicHeaders(CLAUDE_API_KEY!),
      body: JSON.stringify(body),
      signal: ctrl.signal,
    });
  } finally {
    clearTimeout(timer);
  }
}

interface FallbackContext {
  // deno-lint-ignore no-explicit-any
  body: any;
  reason: FallbackReason;
  ragChunks: GroundingChunk[];
  persistMessageId: string | null;
  persistUserId: string | null;
  persistCaseId: string | null;
}

// =============================================================================
// Anthropic $0-balance graceful degradation
// =============================================================================
//
// When Anthropic returns 400 with "credit balance" we cannot route to Llama
// (Llama doesn't know our user's specific question is a legal one, and we want
// to ship REAL statute text instead of a paraphrase). The credit_fallback
// module runs an embedding via OpenAI (separate budget) + a law_search RPC and
// formats the top-K chunks as the assistant reply. Cost ≈ $0.0001 per call,
// well within the OpenAI budget the owner funds independently from Anthropic.
//
// Telemetry: `anthropic_credit_exhausted` count is exported via console.warn
// so ops can grep the function logs. We deliberately do NOT increment a
// counter table — credit exhaustion is supposed to be a brief window between
// "balance hit zero" and "owner tops up", not a steady-state condition.

/** Extract the bare paragraph id from a `law_search_v2.section_label`.
 *  Mirrors `paragraphFromSectionLabel` in tool_handlers.ts — duplicated here
 *  to keep the credit_fallback path free of cross-module imports beyond the
 *  ones it already has. */
function ragParagraphFromLabel(label: string): string {
  if (!label) return "";
  const trimmed = label.trim();
  // FI: "HOL 1:114 §"
  const fi = trimmed.match(/\d+:(\d+[a-zA-Z¹²³⁰⁴⁵⁶⁷⁸⁹]?)\s*§?\s*$/);
  if (fi) return fi[1];
  // EE: "KarS § 114" / "KarS § 114¹"
  const ee = trimmed.match(/§\s*(\d+[a-zA-Z¹²³⁰⁴⁵⁶⁷⁸⁹]?)\s*$/);
  if (ee) return ee[1];
  // EU EN/ET/FI variants
  const enArt = trimmed.match(/^Article\s+(\d+(?:[.\-]\d+)?)/i);
  if (enArt) return enArt[1];
  const etArt = trimmed.match(/^Artikkel\s+(\d+(?:[.\-]\d+)?)/i);
  if (etArt) return etArt[1];
  const fiArt = trimmed.match(/^(\d+(?:[.\-]\d+)?)\s+artikla/i);
  if (fiArt) return fiArt[1];
  const digits = trimmed.match(/(\d+[a-zA-Z¹²³⁰⁴⁵⁶⁷⁸⁹]?)/);
  return digits ? digits[1] : trimmed;
}

/** Run the RAG-only fallback. Returns null if the OpenAI client / law_search_v2
 *  RPC are not configured (the caller then falls through to the legacy 400
 *  passthrough so we never silently swallow a real bug). */
async function runCreditExhaustedFallback(
  body: unknown,
  isStreamRequest: boolean,
  persistMessageId: string | null,
): Promise<Response | null> {
  if (!OPENAI_API_KEY) {
    console.warn(
      "claude-proxy: credit-exhausted fallback skipped (no OPENAI_API_KEY)",
    );
    return null;
  }

  // Pull the user's last message + a jurisdiction hint off the request.
  const userQuery = extractLastUserText(body);
  const jurisdiction = extractJurisdictionHint(body);

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  console.warn(
    `claude-proxy: anthropic_credit_exhausted — running RAG-only fallback ` +
      `(query_len=${userQuery.length}, jur=${jurisdiction ?? "FI"})`,
  );

  const result = await buildRagOnlyResponse(
    userQuery,
    {
      embed: buildEmbedFn(OPENAI_API_KEY),
      lawSearch: async (params) => {
        // 2026-05-13 P0 fix: route the credit-exhausted RAG fallback at the
        // same v2 corpus as the legal_lookup tool. `law_search_v2` covers
        // 15 295 rows (FI + EE + EU); v1 was EE-only with stale embeddings.
        // We translate the legacy positional params and adapt the response
        // back to `RagChunk` so buildRagOnlyResponse stays untouched.
        const v2Params = {
          query_embedding: params.query_embedding,
          jurisdiction_filter: params.query_jurisdiction
            ? params.query_jurisdiction.toLowerCase()
            : null,
          act_slug_filter: null as string | null,
          lang_filter: params.query_lang
            ? params.query_lang.toLowerCase()
            : null,
          valid_at: null as string | null,
          match_threshold: params.similarity_threshold,
          match_count: params.match_count,
        };
        const { data, error } = await supabase.rpc(
          "law_search_v2",
          v2Params,
        );
        if (error) {
          console.warn(
            `claude-proxy: fallback law_search_v2 RPC error — ${error.message}`,
          );
          return null;
        }
        if (!Array.isArray(data)) return null;
        // Map v2 → RagChunk: section_label → paragraph (extract bare id),
        // text → body. RagChunk's optional fields stay null.
        return data.map((r: {
          id: string;
          act_slug: string;
          section_label: string;
          text: string;
          similarity: number;
          source_url: string | null;
        }) => ({
          act_slug: r.act_slug ?? "",
          act_name: null,
          paragraph: ragParagraphFromLabel(r.section_label ?? ""),
          title: r.section_label ?? null,
          body: r.text ?? "",
          source_url: r.source_url ?? null,
          similarity: typeof r.similarity === "number" ? r.similarity : 0,
        }));
      },
      casesCiting: async (params) => {
        const { data, error } = await supabase.rpc("cases_citing", params);
        if (error) {
          // cases_citing is optional — silent on missing RPC.
          return null;
        }
        return Array.isArray(data) ? data : null;
      },
    },
    { jurisdiction },
  );

  return isStreamRequest
    ? buildRagOnlySseResponse(result, { messageId: persistMessageId })
    : buildRagOnlyJsonResponse(result, { messageId: persistMessageId });
}

/** Pull the most recent user-role message text from the Anthropic body. */
function extractLastUserText(body: unknown): string {
  if (!body || typeof body !== "object") return "";
  // deno-lint-ignore no-explicit-any
  const messages = (body as any).messages;
  if (!Array.isArray(messages)) return "";
  for (let i = messages.length - 1; i >= 0; i--) {
    const m = messages[i];
    if (m && m.role === "user") {
      if (typeof m.content === "string") return m.content;
      if (Array.isArray(m.content)) {
        const text = m.content
          .map((b: { type?: string; text?: string }) =>
            b && b.type === "text" && typeof b.text === "string" ? b.text : ""
          )
          .join("\n")
          .trim();
        if (text) return text;
      }
    }
  }
  return "";
}

/** Best-effort jurisdiction guess. Defaults to FI when unknown — that matches
 *  the production user base (FI/EE bilingual, FI majority). */
function extractJurisdictionHint(body: unknown): string | null {
  if (!body || typeof body !== "object") return null;
  // deno-lint-ignore no-explicit-any
  const b = body as any;
  if (typeof b.jurisdiction === "string") return b.jurisdiction;
  if (typeof b.query_jurisdiction === "string") return b.query_jurisdiction;
  return null;
}

/**
 * Run the Llama fallback for a non-streaming request. Returns an Anthropic-
 * shaped JSON response — same fields as a happy-path Claude reply, plus:
 *   - `model_used: "llama-3.3-70b-fallback"` in the body
 *   - `X-Advocat-Model-Used: llama-3.3-70b-fallback` response header
 *   - bilingual disclosure prepended to the assistant text
 *
 * Citation verifier runs over the joined text just like the Claude path so
 * any `[[ref:slug:para]]` markers Llama emits (it won't, typically) still
 * get verified.
 */
async function runLlamaFallbackForJson(
  ctx: FallbackContext,
): Promise<Response> {
  const messages = Array.isArray(ctx.body.messages) ? ctx.body.messages : [];
  const maxTokens = typeof ctx.body.max_tokens === "number"
    ? ctx.body.max_tokens
    : 4096;

  const result = await callLlamaFallback({
    systemPrompt: ctx.body.system,
    messages,
    maxTokens,
    reason: ctx.reason,
  });

  if (!result.ok || !result.response) {
    // Llama also unavailable — return a generic 503 so the Flutter client
    // shows the localized "service unavailable" toast. Do NOT pretend to
    // succeed: that would silently swallow a real outage.
    console.error(
      `claude-proxy: Llama fallback also failed: ${result.error ?? "unknown"}`,
    );
    return new Response(
      JSON.stringify({
        error: "service_unavailable",
        user_message_key: "ai_error_overload",
        details: result.error ?? "Llama fallback failed",
      }),
      {
        status: 503,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
          "X-Advocat-Model-Used": "none",
        },
      },
    );
  }

  const llamaResponse: AnthropicShapedResponse = result.response;
  const replyText = llamaResponse.content
    .map((b) => b.text ?? "")
    .join("");
  const citations = verifyCitations(replyText, ctx.ragChunks);

  if (
    ctx.persistMessageId !== null &&
    ctx.persistUserId !== null &&
    ctx.persistCaseId !== null &&
    citations.length > 0
  ) {
    const rows = buildCitationRows({
      message_id: ctx.persistMessageId,
      user_id: ctx.persistUserId,
      case_id: ctx.persistCaseId,
      citations,
    });
    await persistCitations(rows, {
      supabaseUrl: SUPABASE_URL,
      serviceRoleKey: SUPABASE_SERVICE_ROLE_KEY,
    });
  }

  const augmented = {
    ...llamaResponse,
    citations,
    model_used: LLAMA_MODEL_ID,
    ...(ctx.persistMessageId !== null
      ? { message_id: ctx.persistMessageId }
      : {}),
  };

  return new Response(JSON.stringify(augmented), {
    status: 200,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
      "X-Advocat-Model-Used": LLAMA_MODEL_ID,
    },
  });
}

/**
 * Run the Llama fallback for a streaming request. The Deepinfra call is
 * non-streaming (simpler, same UX outcome since we synthesise SSE deltas);
 * we wrap the result as synthetic SSE so the Flutter SSE parser keeps
 * working unchanged. This is the same approach the tool-use branch uses
 * for its follow-up response (see buildSseFromAnthropicResult).
 */
async function runLlamaFallbackForStream(
  ctx: FallbackContext,
): Promise<Response> {
  const messages = Array.isArray(ctx.body.messages) ? ctx.body.messages : [];
  const maxTokens = typeof ctx.body.max_tokens === "number"
    ? ctx.body.max_tokens
    : 4096;

  const result = await callLlamaFallback({
    systemPrompt: ctx.body.system,
    messages,
    maxTokens,
    reason: ctx.reason,
  });

  if (!result.ok || !result.response) {
    console.error(
      `claude-proxy: Llama fallback also failed: ${result.error ?? "unknown"}`,
    );
    return new Response(
      JSON.stringify({
        error: "service_unavailable",
        user_message_key: "ai_error_overload",
        details: result.error ?? "Llama fallback failed",
      }),
      {
        status: 503,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
          "X-Advocat-Model-Used": "none",
        },
      },
    );
  }

  const llamaResponse: AnthropicShapedResponse = result.response;
  const replyText = llamaResponse.content.map((b) => b.text ?? "").join("");
  const citations = verifyCitations(replyText, ctx.ragChunks);

  if (
    ctx.persistMessageId !== null &&
    ctx.persistUserId !== null &&
    ctx.persistCaseId !== null &&
    citations.length > 0
  ) {
    const rows = buildCitationRows({
      message_id: ctx.persistMessageId,
      user_id: ctx.persistUserId,
      case_id: ctx.persistCaseId,
      citations,
    });
    await persistCitations(rows, {
      supabaseUrl: SUPABASE_URL,
      serviceRoleKey: SUPABASE_SERVICE_ROLE_KEY,
    });
  }

  const encoder = new TextEncoder();
  // Cast: buildSseFromAnthropicResult takes a structural bag (with index
  // signature). AnthropicShapedResponse is structurally compatible but TS
  // does not widen a strict shape to an index-signature shape.
  const sseInput = llamaResponse as unknown as {
    content?: unknown;
    usage?: unknown;
    model?: unknown;
    id?: unknown;
    [key: string]: unknown;
  };
  const sseBody = buildSseFromAnthropicResult(
    sseInput,
    citations,
    ctx.persistMessageId,
    [],
  );
  return new Response(encoder.encode(sseBody), {
    status: 200,
    headers: {
      ...corsHeaders,
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-cache",
      "X-Advocat-Model-Used": LLAMA_MODEL_ID,
    },
  });
}

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
