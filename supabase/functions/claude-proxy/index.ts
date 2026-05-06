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

const CLAUDE_API_KEY = Deno.env.get("CLAUDE_API_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;

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

const MAX_TOKENS_LIMIT = 4096;
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

    // Streaming mode — pipe SSE events from Claude directly to client
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

      // Pipe SSE stream directly through — no server-side parsing needed
      return new Response(claudeStreamResponse.body, {
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
      const result = await claudeResponse.json();
      // ── Grounding verifier (Pkg 2) ─────────────────────────────────────
      // Pure regex + Map lookup against ragChunks (already in memory from
      // this turn). p95 < 50 ms per design. Never throws; returns [] on
      // empty inputs so legacy callers (no rag_context) keep working.
      const replyText = concatAnthropicTextBlocks(
        (result as { content?: unknown }).content,
      );
      const citations = verifyCitations(replyText, ragChunks);
      const augmented = { ...result, citations };
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
