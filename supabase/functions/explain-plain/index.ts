// explain-plain/index.ts — HTTP entry for the Plain-Language Explainer.
// -----------------------------------------------------------------------------
// Feature: "Объясни простыми словами" — single-shot, no-history endpoint that
// re-states a dense legal document (Migri/court/police decision, contract …) in
// plain language. Backed by the same Anthropic model + egress PII-scrub as
// chat, but with a narrow, stateless prompt (no conversation, no tools).
//
// Contract:
//   POST /functions/v1/explain-plain
//   Headers: Authorization: Bearer <user JWT>   (anonymous rejected)
//   Body:
//     {
//       source_text: string,                 // the legal text to explain
//       level?: "friend" | "with_terms",     // default "friend"
//       language?: <17 locales>,             // omit → auto-detect
//       case_id?: string,                    // optional informational link
//       source_document_id?: string          // optional informational link
//     }
//   -> 200 {
//        explain_request_id, explanation: ExplainOutput,
//        language, level, quota: { used, limit | null, tier }
//      }
//   -> 402 { error: "quota_exceeded", quota } when a free user is over cap.
//
// Security model (mirrors case-followups):
//   - JWT-gated; anonymous rejected (no per-user quota/history possible).
//   - DB reads/writes run on a per-user client carrying the caller's
//     Authorization header, so RLS confines quota/history to the caller. No
//     service-role writes here.
//   - The egress body is scrubbed before it leaves for Anthropic.
//   - UPL mitigation: the system prompt forbids individual legal advice and the
//     halt-rail advisory is appended for serious-case keywords. The Flutter
//     screen also surfaces the standard AI-disclaimer banner.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  jsonError,
  jsonOk,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import {
  buildExcerpt,
  buildSystemPrompt,
  buildUserPrompt,
  EXCERPT_CHARS,
  type ExplainLang,
  type ExplainOutput,
  FREE_MONTHLY_QUOTA,
  parseExplainResponse,
  validateRequest,
} from "./prompt.ts";
import { detectLangFromMessage } from "../_shared/halt_rail.ts";
import {
  appendHaltRailToSystem,
  detectSeriousCase,
} from "../_shared/halt_rail.ts";
import { scrubAnthropicBody } from "../_shared/llm_egress/scrub_body.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const ANTHROPIC_API_KEY =
  Deno.env.get("CLAUDE_API_KEY") ?? Deno.env.get("ANTHROPIC_API_KEY");
const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";
const ANTHROPIC_MODEL = "claude-sonnet-4-6";
const ANTHROPIC_MAX_TOKENS = 4096;
const ANTHROPIC_FETCH_TIMEOUT_MS = 90_000;

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // Auth — user JWT required, anon NEVER accepted.
  const gate = await requireUserWithRateLimit(req, {
    bucket: "explain-plain",
    maxPerMinute: 6,
    // anonymousPerMinute omitted → unauthenticated callers get 401.
  });
  if (gate.kind === "deny") return gate.response;
  const userId = gate.user.id;
  if (userId.startsWith("anon:")) {
    return jsonError("Unauthorized", 401);
  }

  // Parse + validate body.
  let raw: unknown;
  try {
    raw = await req.json();
  } catch {
    return jsonError("Invalid JSON body", 400);
  }
  const parsed = validateRequest(raw);
  if (!parsed.ok) {
    return jsonError(parsed.error, 400);
  }
  const request = parsed.value;

  // Per-user client (carries the caller's JWT → RLS scopes quota & history).
  const authHeader = req.headers.get("Authorization") ?? "";
  const sb = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false },
  });

  try {
    // ── Quota gate ───────────────────────────────────────────────────────
    const tier = await resolveTier(sb, userId);
    const isPro = tier !== "free";
    let used = 0;
    if (!isPro) {
      used = await usedThisMonth(sb);
      if (used >= FREE_MONTHLY_QUOTA) {
        return new Response(
          JSON.stringify({
            error: "quota_exceeded",
            quota: { used, limit: FREE_MONTHLY_QUOTA, tier },
          }),
          {
            status: 402,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }
    }

    // ── Language: explicit override or auto-detect from the source ───────
    const language: ExplainLang =
      request.language ??
      (detectLangFromMessage(request.source_text) as ExplainLang);

    // ── Build prompts ────────────────────────────────────────────────────
    let systemPrompt = buildSystemPrompt(request.level, language);
    // UPL mitigation: if the source mentions deportation/criminal/ECHR/etc.,
    // append the existing halt-rail advisory (consult a licensed advocate).
    const serious = detectSeriousCase(request.source_text);
    systemPrompt = appendHaltRailToSystem(systemPrompt, serious);
    const userPrompt = buildUserPrompt(request.source_text);

    // ── Call the model ───────────────────────────────────────────────────
    const explanation = await callExplainer(systemPrompt, userPrompt);

    // ── Persist to history (RLS owner-only insert) ───────────────────────
    const excerpt = buildExcerpt(request.source_text).slice(0, EXCERPT_CHARS);
    let explainRequestId: string | null = null;
    try {
      const { data, error } = await sb
        .from("explain_requests")
        .insert({
          user_id: userId,
          case_id: request.case_id ?? null,
          source_document_id: request.source_document_id ?? null,
          level: request.level,
          output_language: language,
          source_excerpt: excerpt,
          source_length: request.source_text.length,
          explanation,
          model_used: ANTHROPIC_MODEL,
        })
        .select("id")
        .single();
      if (!error && data) explainRequestId = data.id as string;
      else if (error) console.error("[explain-plain] insert:", error.message);
    } catch (e) {
      // History write is best-effort: never fail the user's explanation just
      // because the ledger insert hiccupped. Quota for THIS call is then not
      // recorded — acceptable (under-count by 1, fail-open on history only).
      console.error("[explain-plain] insert threw:", String(e));
    }

    return jsonOk(
      {
        explain_request_id: explainRequestId,
        explanation,
        language,
        level: request.level,
        quota: {
          used: isPro ? null : used + 1,
          limit: isPro ? null : FREE_MONTHLY_QUOTA,
          tier,
        },
      },
      200
    );
  } catch (e) {
    console.error("[explain-plain] unhandled:", e);
    return jsonError("Internal error", 500);
  }
});

// ─── Tier resolution ──────────────────────────────────────────────────────────
// Mirrors contract-review/handler.detectTier but runs on the per-user client.
// Any active, in-period paid subscription => not-free (unlimited explanations).

// deno-lint-ignore no-explicit-any
type SbClient = any;

async function resolveTier(
  sb: SbClient,
  _userId: string
): Promise<"free" | "basic" | "premium"> {
  try {
    const sub = await sb
      .from("subscriptions")
      .select("status, tier, current_period_end")
      .in("status", ["active", "trialing"])
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();
    if (sub.data) {
      const periodEnd = (sub.data as { current_period_end?: string | null })
        .current_period_end;
      if (periodEnd && new Date(periodEnd).getTime() < Date.now()) {
        return "free";
      }
      const t = (sub.data as { tier?: string }).tier;
      if (t === "premium") return "premium";
      if (t === "basic") return "basic";
      return "basic"; // legacy active row without a recognised tier
    }
  } catch (_) {
    /* fall through to free */
  }
  return "free";
}

async function usedThisMonth(sb: SbClient): Promise<number> {
  try {
    const { data, error } = await sb.rpc("explain_requests_used_this_month");
    if (error || typeof data !== "number") return 0;
    return data;
  } catch (_) {
    return 0;
  }
}

// ─── Anthropic binding ────────────────────────────────────────────────────────

async function callExplainer(
  systemPrompt: string,
  userPrompt: string
): Promise<ExplainOutput> {
  if (!ANTHROPIC_API_KEY) {
    throw new Error("CLAUDE_API_KEY not configured");
  }
  const res = await fetch(ANTHROPIC_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": ANTHROPIC_API_KEY,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify(
      scrubAnthropicBody({
        model: ANTHROPIC_MODEL,
        max_tokens: ANTHROPIC_MAX_TOKENS,
        temperature: 0.0,
        system: systemPrompt,
        messages: [{ role: "user", content: userPrompt }],
      })
    ),
    signal: AbortSignal.timeout(ANTHROPIC_FETCH_TIMEOUT_MS),
  });
  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Anthropic ${res.status}: ${err.slice(0, 200)}`);
  }
  const json = (await res.json()) as {
    content?: Array<{ type: string; text?: string }>;
  };
  const text = (json.content ?? [])
    .filter((b) => b.type === "text" && typeof b.text === "string")
    .map((b) => b.text!)
    .join("");
  return parseExplainResponse(text);
}
