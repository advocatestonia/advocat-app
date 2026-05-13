// =============================================================================
// model_router.ts — smart Haiku-driven model & max_tokens router.
// =============================================================================
//
// Goal: 5-10x cost reduction on simple traffic. Instead of letting Sonnet
// answer "tere" or "thanks", we run a tiny ~50-token Haiku classifier FIRST,
// then route the main response to:
//
//   general_chat / off_topic           → Haiku  + 200 max_tokens
//   simple legal question              → Haiku  + 2000 max_tokens
//   medium legal question              → Haiku  + 4096 max_tokens
//   complex legal question             → Sonnet + 8000 max_tokens
//   clarification (follow-up turn)     → caller's choice (or Haiku default)
//
// Cost per router call (Haiku 4.5, $1/M in + $5/M out):
//   ~500 tokens in × $1/M + ~50 tokens out × $5/M ≈ $0.00075 per query
//
// Math (per current memory: ~€5,140/mo Claude bill, est. 60% goes to Sonnet
// but only 30% of traffic genuinely needs it):
//   - 30% of queries × €5,140 saved by Haiku-routing them ≈ €1,500/month
//   - minus router cost: 10K queries/mo × $0.00075 = $7.50/mo (negligible)
//
// Failure-mode contract:
//   1. Router timeout / network error / malformed JSON  → return `null`
//   2. Caller falls back to legacy `chooseModel()` heuristics
//   3. Tests pin this fallback so an Anthropic outage never breaks chat
//
// Safety guardrails:
//   - Always allow Pro users to manually request Sonnet (caller passes
//     `body.model = "claude-sonnet-..."` explicitly → router is skipped)
//   - If router says "simple" BUT message has ≥3 complex legal keywords,
//     upgrade to Sonnet anyway (defence against router under-classification)
//   - Anon callers: router is bypassed (their max_tokens is clamped to 500
//     and they always land on Haiku regardless — no point spending $0.00075)
// =============================================================================

export const ROUTER_MODEL = "claude-haiku-4-5-20251001";
export const SONNET_MODEL = "claude-sonnet-4-20250514";
export const HAIKU_MODEL = "claude-haiku-4-5-20251001";

/** Hard cap on time the router gets to respond. Exceeding it = fall back. */
export const ROUTER_TIMEOUT_MS = 3000;

/** Token budget for the router's response. ~50 tokens of JSON is plenty. */
export const ROUTER_MAX_TOKENS = 100;

/** Number of strong-legal keyword hits required to override a `simple`
 *  router verdict and force Sonnet. Defence against under-classification. */
export const COMPLEX_KEYWORD_OVERRIDE_THRESHOLD = 3;

export type Intent =
  | "legal_question"
  | "general_chat"
  | "clarification"
  | "off_topic";

export type Complexity = "simple" | "medium" | "complex";

export type Language = "et" | "ru" | "en" | "fi" | "other";

export interface RouterClassification {
  intent: Intent;
  complexity: Complexity;
  language: Language;
  /** Recommended model. Caller can still override. */
  recommended_model: "haiku" | "sonnet";
  /** Recommended max_tokens for the main response. */
  recommended_max_tokens: number;
  /** Whether the verdict came from the live classifier or fallback. */
  source: "classifier" | "fallback" | "override";
  /** Round-trip latency of the classifier call (ms). 0 for fallback. */
  latency_ms: number;
}

/** Routing matrix — intent × complexity → (model, max_tokens). */
export function deriveRecommendation(
  intent: Intent,
  complexity: Complexity,
): { model: "haiku" | "sonnet"; max_tokens: number } {
  if (intent === "general_chat") {
    return { model: "haiku", max_tokens: 200 };
  }
  if (intent === "off_topic") {
    return { model: "haiku", max_tokens: 200 };
  }
  if (intent === "clarification") {
    // Follow-ups inherit the previous turn's model. Caller is responsible
    // for honouring this — we just suggest a sensible default if they don't.
    return { model: "haiku", max_tokens: 2000 };
  }
  // intent === "legal_question"
  if (complexity === "complex") {
    return { model: "sonnet", max_tokens: 8000 };
  }
  if (complexity === "medium") {
    return { model: "haiku", max_tokens: 4096 };
  }
  return { model: "haiku", max_tokens: 2000 };
}

/** The classifier prompt. Kept short (~300 tokens) and stable so it caches
 *  well on the Anthropic side (5-min ephemeral cache). */
export const CLASSIFIER_SYSTEM_PROMPT = `You are a routing classifier for a legal-assistant chat.

Classify the user's LAST message into JSON with these exact fields:
{
  "intent": "legal_question" | "general_chat" | "clarification" | "off_topic",
  "complexity": "simple" | "medium" | "complex",
  "language": "et" | "ru" | "en" | "fi" | "other"
}

Rules:
- intent=general_chat   → greetings, thanks, "hi", "tere", "ok", smalltalk
- intent=legal_question → user asks about law, rights, court, contracts, deportation, employment, family law, etc.
- intent=clarification  → user is re-asking, following up, asking "what do you mean", asking for more detail on previous reply
- intent=off_topic      → cooking, weather, code generation, unrelated to legal advice
- complexity=simple     → single yes/no question, short factual lookup
- complexity=medium     → one law / one jurisdiction / single legal concept
- complexity=complex    → multi-step reasoning, multiple laws, cross-jurisdiction, contract drafting, pleading, multi-paragraph analysis
- language              → primary language of the user's message

Output ONLY valid JSON, no prose, no markdown fences.`;

/** Strong-legal keywords used by the override check. Subset of the
 *  Dart-side `_complexKeywords` — only the truly unambiguous ones. */
const STRONG_LEGAL_KEYWORDS = [
  // EN
  "deportation", "asylum", "court", "appeal", "lawsuit", "subpoena",
  "custody", "alimony", "eviction", "indictment", "warrant",
  // RU
  "депортац", "апелляц", "обжалов", "иск", "судебн", "приговор",
  "развод", "опек", "алимент", "выселен",
  // ET
  "kohus", "kohtu", "kaebus", "väljasaatm", "elamisluba", "lahutus",
  "töövaidlus", "üürilepin",
  // FI
  "tuomioistuin", "valituslupa", "karkot", "käännytys", "kho", "hao",
  "oikaisuvaatimus",
];

/** Count strong legal keyword hits in the user's text. */
export function countStrongLegalKeywords(text: string): number {
  const lower = text.toLowerCase();
  let n = 0;
  for (const kw of STRONG_LEGAL_KEYWORDS) {
    if (lower.includes(kw)) n++;
  }
  return n;
}

/** Pull plain text out of a Messages-API content field (string or blocks). */
export function extractUserText(content: unknown): string {
  if (typeof content === "string") return content;
  if (Array.isArray(content)) {
    const out: string[] = [];
    for (const block of content) {
      if (
        block && typeof block === "object" &&
        (block as Record<string, unknown>).type === "text" &&
        typeof (block as Record<string, unknown>).text === "string"
      ) {
        out.push((block as Record<string, string>).text);
      }
    }
    return out.join(" ");
  }
  return "";
}

interface Message {
  role?: string;
  content?: unknown;
}

/** Lightweight heuristic fallback when the Haiku classifier is unavailable.
 *  Mirrors the existing Dart `chooseModel()` rules so behaviour is consistent
 *  with what the client would have chosen. */
export function heuristicFallback(
  text: string,
): RouterClassification {
  const lower = text.toLowerCase().trim();
  const len = lower.length;
  const kwHits = countStrongLegalKeywords(lower);

  // Language sniff — simple Cyrillic / Estonian / Finnish detection.
  let language: Language = "en";
  if (/[\u0400-\u04FF]/.test(lower)) language = "ru";
  else if (/(õ|ä|ö|ü|š|ž)/.test(lower) && /(et|kohus|kaebus|seadus)/.test(lower)) language = "et";
  else if (/(ä|ö)/.test(lower) && /(tuomio|valitus|laki|oikeu)/.test(lower)) language = "fi";

  // Pure greeting heuristic.
  const greetings = ["hi", "hello", "tere", "привет", "kiitos", "thanks", "ok", "okay", "yes", "no"];
  if (len < 25 && greetings.some((g) => lower === g || lower.startsWith(g + " ") || lower.startsWith(g + "!"))) {
    const rec = deriveRecommendation("general_chat", "simple");
    return {
      intent: "general_chat",
      complexity: "simple",
      language,
      recommended_model: rec.model,
      recommended_max_tokens: rec.max_tokens,
      source: "fallback",
      latency_ms: 0,
    };
  }

  // Strong-legal override → complex.
  if (kwHits >= 2 || len > 300) {
    const rec = deriveRecommendation("legal_question", "complex");
    return {
      intent: "legal_question",
      complexity: "complex",
      language,
      recommended_model: rec.model,
      recommended_max_tokens: rec.max_tokens,
      source: "fallback",
      latency_ms: 0,
    };
  }

  if (kwHits >= 1 || len > 150) {
    const rec = deriveRecommendation("legal_question", "medium");
    return {
      intent: "legal_question",
      complexity: "medium",
      language,
      recommended_model: rec.model,
      recommended_max_tokens: rec.max_tokens,
      source: "fallback",
      latency_ms: 0,
    };
  }

  const rec = deriveRecommendation("legal_question", "simple");
  return {
    intent: "legal_question",
    complexity: "simple",
    language,
    recommended_model: rec.model,
    recommended_max_tokens: rec.max_tokens,
    source: "fallback",
    latency_ms: 0,
  };
}

/** Parse the classifier's JSON output and validate shape.
 *  Returns null on any parse / shape error. */
export function parseClassifierResponse(
  raw: string,
): { intent: Intent; complexity: Complexity; language: Language } | null {
  if (!raw) return null;
  // Strip code fences if the model wrapped its output despite instructions.
  let text = raw.trim();
  if (text.startsWith("```")) {
    text = text.replace(/^```(?:json)?\s*/i, "").replace(/```\s*$/, "").trim();
  }
  let parsed: unknown;
  try {
    parsed = JSON.parse(text);
  } catch {
    return null;
  }
  if (!parsed || typeof parsed !== "object") return null;
  const p = parsed as Record<string, unknown>;
  const validIntents: Intent[] = ["legal_question", "general_chat", "clarification", "off_topic"];
  const validComplexities: Complexity[] = ["simple", "medium", "complex"];
  const validLanguages: Language[] = ["et", "ru", "en", "fi", "other"];
  if (typeof p.intent !== "string" || !validIntents.includes(p.intent as Intent)) {
    return null;
  }
  if (typeof p.complexity !== "string" || !validComplexities.includes(p.complexity as Complexity)) {
    return null;
  }
  if (typeof p.language !== "string" || !validLanguages.includes(p.language as Language)) {
    return null;
  }
  return {
    intent: p.intent as Intent,
    complexity: p.complexity as Complexity,
    language: p.language as Language,
  };
}

/** Apply the override rule: if classifier said "simple" but ≥3 strong-legal
 *  keywords are present, upgrade to complex. Returns a possibly-modified
 *  classification. */
export function applyOverrideRules(
  cls: { intent: Intent; complexity: Complexity; language: Language },
  userText: string,
): { intent: Intent; complexity: Complexity; language: Language; overridden: boolean } {
  const kwHits = countStrongLegalKeywords(userText);
  if (
    cls.intent === "legal_question" &&
    cls.complexity === "simple" &&
    kwHits >= COMPLEX_KEYWORD_OVERRIDE_THRESHOLD
  ) {
    return { ...cls, complexity: "complex", overridden: true };
  }
  // Also: if router called it general_chat but message is long + has legal
  // keywords, it's almost certainly a legal question that the router missed.
  if (
    cls.intent === "general_chat" &&
    userText.length > 80 &&
    kwHits >= 2
  ) {
    return { intent: "legal_question", complexity: "medium", language: cls.language, overridden: true };
  }
  return { ...cls, overridden: false };
}

export interface ClassifyOptions {
  /** Anthropic API key. Required for the live classifier call. */
  apiKey: string;
  /** Override the fetch impl (used by tests). Defaults to globalThis.fetch. */
  fetchImpl?: typeof fetch;
  /** Override the timeout. Defaults to ROUTER_TIMEOUT_MS. */
  timeoutMs?: number;
}

/** Run the live Haiku classifier on the latest user message.
 *
 *  Returns a RouterClassification on success.
 *  Returns a heuristic-fallback RouterClassification on any failure
 *  (timeout, network error, malformed JSON, etc.) — NEVER throws.
 *
 *  Always falls back to heuristic on anon callers (their max_tokens is
 *  clamped to 500 and they always end up on Haiku anyway). */
export async function classifyQuery(
  messages: Message[],
  userIsAnon: boolean,
  options: ClassifyOptions,
): Promise<RouterClassification> {
  // Bypass for anon — they always land on Haiku with 500-token clamp.
  if (userIsAnon) {
    return {
      intent: "general_chat",
      complexity: "simple",
      language: "other",
      recommended_model: "haiku",
      recommended_max_tokens: 500,
      source: "override",
      latency_ms: 0,
    };
  }

  // Defensive: empty / malformed message list → fallback.
  if (!Array.isArray(messages) || messages.length === 0) {
    return heuristicFallback("");
  }
  const last = messages[messages.length - 1];
  if (last?.role !== "user") {
    return heuristicFallback("");
  }
  const userText = extractUserText(last.content).trim();
  if (userText.length === 0) {
    return heuristicFallback("");
  }

  // Tiny early-exit: very short greetings never need a classifier call.
  // Save the $0.00075 router cost AND ~300ms of latency.
  const lower = userText.toLowerCase();
  const tinyGreetings = ["hi", "hello", "tere", "привет", "ok", "okay", "thanks", "kiitos", "yes", "no", "thx", "ty"];
  if (
    userText.length < 12 &&
    tinyGreetings.some((g) => lower === g || lower === g + "!" || lower === g + ".")
  ) {
    return heuristicFallback(userText);
  }

  const fetchImpl = options.fetchImpl ?? globalThis.fetch;
  const timeoutMs = options.timeoutMs ?? ROUTER_TIMEOUT_MS;

  // Run the classifier call with a hard timeout.
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  const t0 = Date.now();

  try {
    const resp = await fetchImpl("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": options.apiKey,
        "anthropic-version": "2023-06-01",
        // Cache the short system prompt so subsequent classifier calls
        // pay the cheap cache-read rate (0.1x base input) instead of
        // re-billing the full 300 tokens every time.
        "anthropic-beta": "prompt-caching-2024-07-31",
      },
      body: JSON.stringify({
        model: ROUTER_MODEL,
        max_tokens: ROUTER_MAX_TOKENS,
        system: [
          {
            type: "text",
            text: CLASSIFIER_SYSTEM_PROMPT,
            // ttl pinned to "1h" — Anthropic silently regressed the
            // cache_control default from 1h to 5m in March 2026. The
            // classifier runs on every turn; long sessions need the 1h
            // window to keep hit rate above the 2x write-cost break-even.
            cache_control: { type: "ephemeral", ttl: "1h" },
          },
        ],
        messages: [
          {
            role: "user",
            // Truncate to first 1000 chars — more than enough to classify.
            content: userText.slice(0, 1000),
          },
        ],
        temperature: 0,
      }),
      signal: controller.signal,
    });

    if (!resp.ok) {
      return heuristicFallback(userText);
    }
    const json = await resp.json();
    const blocks = (json as { content?: Array<{ type?: string; text?: string }> }).content ?? [];
    const raw = blocks
      .filter((b) => b.type === "text" && typeof b.text === "string")
      .map((b) => b.text!)
      .join("");
    const parsed = parseClassifierResponse(raw);
    if (!parsed) {
      return heuristicFallback(userText);
    }
    const overridden = applyOverrideRules(parsed, userText);
    const rec = deriveRecommendation(overridden.intent, overridden.complexity);
    return {
      intent: overridden.intent,
      complexity: overridden.complexity,
      language: overridden.language,
      recommended_model: rec.model,
      recommended_max_tokens: rec.max_tokens,
      source: overridden.overridden ? "override" : "classifier",
      latency_ms: Date.now() - t0,
    };
  } catch {
    return heuristicFallback(userText);
  } finally {
    clearTimeout(timer);
  }
}

/** Render a classification as a single-line telemetry log entry. */
export function formatTelemetry(
  cls: RouterClassification,
  chosenModel: string,
  estimatedCostCents: number,
): string {
  return JSON.stringify({
    event: "model_router",
    intent: cls.intent,
    complexity: cls.complexity,
    language: cls.language,
    recommended_model: cls.recommended_model,
    chosen_model: chosenModel,
    source: cls.source,
    router_latency_ms: cls.latency_ms,
    estimated_cost_cents: estimatedCostCents,
  });
}

/** Rough cost estimate in CENTS for a turn (input + output tokens).
 *  Used purely for telemetry; not load-bearing for billing. */
export function estimateCostCents(
  model: string,
  inputTokens: number,
  outputTokens: number,
): number {
  // 2026-05 prices (USD, $1 ≈ €0.92 — close enough for telemetry):
  //   Haiku 4.5   $1.00/M input + $5.00/M output
  //   Sonnet 4.6  $3.00/M input + $15.00/M output
  let inRate: number;
  let outRate: number;
  if (model === SONNET_MODEL || model.includes("sonnet")) {
    inRate = 3.0;
    outRate = 15.0;
  } else {
    inRate = 1.0;
    outRate = 5.0;
  }
  const usd = (inputTokens * inRate + outputTokens * outRate) / 1_000_000;
  return Math.round(usd * 100 * 100) / 100; // cents, 2 decimals
}
