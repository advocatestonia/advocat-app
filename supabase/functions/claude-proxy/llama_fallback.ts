// =============================================================================
// claude-proxy — Llama 3.3 70B fallback (Deepinfra)
// 2026-05-11
// =============================================================================
//
// Protects Advocat.ee from Anthropic outages, ToS changes, and rate limits
// by routing to Llama 3.3 70B (via Deepinfra) ONLY when Claude is unavailable.
//
// Activation matrix (and ONLY these):
//   - Claude returns 5xx               (Anthropic outage)
//   - Claude returns 429               (rate-limited)
//   - Claude times out (>30s)          (network / capacity)
//   - ADVOCAT_FORCE_FALLBACK=true      (manual override for ops drills)
//
// In ALL OTHER CASES, Claude is primary. Llama is BACKUP, not primary.
//
// Provider choice: Deepinfra (https://deepinfra.com/)
//   - OpenAI-compatible Chat Completions endpoint
//   - meta-llama/Llama-3.3-70B-Instruct
//   - Pricing 2026: ~$0.25/M input, ~$0.50/M output (vs Sonnet ~$3/$15 per M)
//
// Auth: DEEPINFRA_API_KEY env var (Bearer token).
//
// Design constraints:
//   - Pure module: NO Deno.env reads at import time (env read inside funcs);
//     keeps the unit tests trivially mockable.
//   - Anthropic shape on the way OUT: callers (index.ts) keep speaking the
//     same response shape, so the rest of the pipeline (citation verifier,
//     persistence, SSE wrapping) doesn't need to know.
//   - 30s timeout via AbortController — no hanging on Deepinfra's tail latency.
//   - Quality disclosure: prepend a small bilingual note to fallback output.
// -----------------------------------------------------------------------------

import { scrubText } from "../_shared/llm_egress/scrub_body.ts";

export const DEEPINFRA_URL =
  "https://api.deepinfra.com/v1/openai/chat/completions";
export const LLAMA_MODEL = "meta-llama/Llama-3.3-70B-Instruct";
export const LLAMA_TIMEOUT_MS = 30_000;

/** Identifier surfaced via metadata + X-Advocat-Model-Used header. */
export const LLAMA_MODEL_ID = "llama-3.3-70b-fallback";

/** Bilingual disclosure prepended to fallback replies. */
export const FALLBACK_DISCLOSURE =
  "\u26A0\uFE0F Vastasime varuv\u00F5imaluse abil \u2014 kvaliteet v\u00F5ib olla veidi madalam. / Using backup AI \u2014 quality may be slightly lower.\n\n";

/** Reasons a fallback was triggered. Used in logs + metadata. */
export type FallbackReason =
  | "claude_5xx"
  | "claude_429"
  | "claude_timeout"
  | "force_fallback_env"
  | "claude_network_error";

export interface AnthropicMessage {
  role: "user" | "assistant" | "system";
  // Anthropic accepts string OR an array of content blocks. We only use
  // string here — the planner / tool branches that produce content blocks
  // never reach the fallback path (see index.ts).
  content: string | unknown;
}

export interface OpenAIMessage {
  role: "user" | "assistant" | "system";
  content: string;
}

/**
 * Anthropic → OpenAI message conversion.
 *
 * Anthropic puts the system prompt in a top-level `system` field, while
 * OpenAI Chat Completions puts it as the first message with role=system.
 * Content blocks (when `system` is an array of {type:"text",text:...}) are
 * concatenated into a single string. Non-string user/assistant content is
 * stringified — Llama doesn't speak tool-use blocks in the same shape as
 * Anthropic, but the fallback path is only reached on Claude errors so the
 * previous turn's tools are already executed (we re-send the joined text).
 */
export function convertToOpenAIMessages(
  systemPrompt: string | unknown,
  anthropicMessages: AnthropicMessage[]
): OpenAIMessage[] {
  const out: OpenAIMessage[] = [];

  const sysText = coerceToString(systemPrompt);
  if (sysText) {
    out.push({ role: "system", content: sysText });
  }

  for (const m of anthropicMessages) {
    out.push({
      role: m.role === "system" ? "system" : m.role,
      content: coerceToString(m.content),
    });
  }
  return out;
}

/** Coerce Anthropic-shaped content (string OR content-block array) to plain text. */
function coerceToString(value: unknown): string {
  if (value === null || value === undefined) return "";
  if (typeof value === "string") return value;
  if (Array.isArray(value)) {
    return value
      .map((b) => {
        if (typeof b === "string") return b;
        if (b && typeof b === "object") {
          const block = b as { type?: string; text?: string };
          if (block.type === "text" && typeof block.text === "string") {
            return block.text;
          }
        }
        return "";
      })
      .filter(Boolean)
      .join("\n");
  }
  return String(value);
}

export interface OpenAIChatCompletion {
  id?: string;
  model?: string;
  choices?: Array<{
    index?: number;
    message?: { role?: string; content?: string };
    finish_reason?: string;
  }>;
  usage?: {
    prompt_tokens?: number;
    completion_tokens?: number;
    total_tokens?: number;
  };
}

/**
 * Anthropic-shaped non-streaming Messages response. The fields we populate
 * are exactly the ones the rest of the proxy pipeline reads:
 *   - content[]  : the citation verifier + SSE wrapper concat text from here.
 *   - stop_reason: "end_turn" so the tool-use branch is NOT triggered.
 *   - usage      : surfaced to monitoring; we map OpenAI token counts.
 *   - model      : LLAMA_MODEL_ID so X-Advocat-Model-Used is accurate.
 */
export interface AnthropicShapedResponse {
  id: string;
  type: "message";
  role: "assistant";
  model: string;
  content: Array<{ type: "text"; text: string }>;
  stop_reason: "end_turn";
  stop_sequence: null;
  usage: { input_tokens: number; output_tokens: number };
  // Custom field, ignored by Flutter parser but useful for diagnostics.
  advocat_fallback: { used: true; reason: FallbackReason };
}

/**
 * OpenAI → Anthropic response conversion. Prepends the bilingual quality
 * disclosure to the assistant's reply text so end-users always know when a
 * lower-quality backup served them.
 */
export function convertToAnthropicResponse(
  openai: OpenAIChatCompletion,
  reason: FallbackReason
): AnthropicShapedResponse {
  const choice = openai.choices?.[0];
  const replyText = choice?.message?.content ?? "";
  const withDisclosure = FALLBACK_DISCLOSURE + replyText;

  return {
    id: openai.id ?? `msg_llama_${Date.now()}`,
    type: "message",
    role: "assistant",
    model: LLAMA_MODEL_ID,
    content: [{ type: "text", text: withDisclosure }],
    stop_reason: "end_turn",
    stop_sequence: null,
    usage: {
      input_tokens: openai.usage?.prompt_tokens ?? 0,
      output_tokens: openai.usage?.completion_tokens ?? 0,
    },
    advocat_fallback: { used: true, reason },
  };
}

export interface CallLlamaOptions {
  systemPrompt: string | unknown;
  messages: AnthropicMessage[];
  maxTokens: number;
  reason: FallbackReason;
  /** Override the API key (tests). Defaults to env DEEPINFRA_API_KEY. */
  apiKey?: string;
  /** Override the URL (tests). Defaults to DEEPINFRA_URL. */
  url?: string;
  /** Override the abort timeout (tests). Defaults to LLAMA_TIMEOUT_MS. */
  timeoutMs?: number;
}

export interface CallLlamaResult {
  ok: boolean;
  /** When ok, the Anthropic-shaped response the proxy returns. */
  response?: AnthropicShapedResponse;
  /** When !ok, a short reason for the operator log. */
  error?: string;
  /** HTTP status from Deepinfra, when applicable. */
  status?: number;
}

/**
 * Call Llama 3.3 70B via Deepinfra with a hard 30s timeout. Returns an
 * Anthropic-shaped response on success, or an error envelope on failure
 * (the caller surfaces a 503 to the client — same behaviour as a generic
 * upstream outage).
 */
export async function callLlamaFallback(
  opts: CallLlamaOptions
): Promise<CallLlamaResult> {
  const apiKey = opts.apiKey ?? Deno.env.get("DEEPINFRA_API_KEY") ?? "";
  if (!apiKey) {
    return {
      ok: false,
      error: "DEEPINFRA_API_KEY not configured",
    };
  }

  const url = opts.url ?? DEEPINFRA_URL;
  const timeoutMs = opts.timeoutMs ?? LLAMA_TIMEOUT_MS;

  const openaiMessages = convertToOpenAIMessages(
    opts.systemPrompt,
    opts.messages
  ).map((m) => ({ ...m, content: scrubText(m.content) }));

  const requestBody = {
    model: LLAMA_MODEL,
    messages: openaiMessages,
    max_tokens: opts.maxTokens,
    // Match Claude defaults reasonably — Llama 3.3 70B obeys temperature
    // similarly to other instruct models.
    temperature: 0.7,
  };

  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), timeoutMs);

  try {
    const res = await fetch(url, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(requestBody),
      signal: ctrl.signal,
    });

    if (!res.ok) {
      const txt = await safeReadText(res);
      return {
        ok: false,
        status: res.status,
        error: `Deepinfra HTTP ${res.status}: ${txt.slice(0, 200)}`,
      };
    }

    const payload = (await res.json()) as OpenAIChatCompletion;
    return {
      ok: true,
      response: convertToAnthropicResponse(payload, opts.reason),
    };
  } catch (e) {
    const isAbort = (e as { name?: string })?.name === "AbortError";
    return {
      ok: false,
      error: isAbort
        ? `Deepinfra timeout after ${timeoutMs}ms`
        : `Deepinfra network error: ${String(e).slice(0, 200)}`,
    };
  } finally {
    clearTimeout(timer);
  }
}

async function safeReadText(res: Response): Promise<string> {
  try {
    return await res.text();
  } catch {
    return "";
  }
}

/**
 * Decide whether a Claude HTTP status should trigger fallback. Pure +
 * trivially unit-testable. Activation matrix (and ONLY these):
 *   - 429 rate-limited
 *   - 5xx upstream outage (any 5xx, including 500/502/503/504/529)
 *
 * Everything else (2xx, 4xx other than 429) is a "real" outcome we forward
 * unchanged. 401/403 in particular are NOT fallback triggers — they almost
 * always mean a misconfigured CLAUDE_API_KEY which Llama wouldn't fix.
 */
export function shouldFallback(status: number): boolean {
  if (status === 429) return true;
  if (status >= 500 && status <= 599) return true;
  return false;
}

/**
 * Pure helper for index.ts: classify a Claude failure into a FallbackReason.
 * Keeps the index code branch-free.
 */
export function fallbackReasonFromStatus(status: number): FallbackReason {
  if (status === 429) return "claude_429";
  if (status >= 500) return "claude_5xx";
  // Defensive default — shouldFallback() ensures we never reach here in
  // production, but keep a sensible value for log readability.
  return "claude_5xx";
}

/**
 * Check the manual override env var. Returns true ONLY when
 * ADVOCAT_FORCE_FALLBACK is the literal string "true" (case-insensitive).
 */
export function forceFallbackEnabled(): boolean {
  const v = Deno.env.get("ADVOCAT_FORCE_FALLBACK") ?? "";
  return v.toLowerCase() === "true";
}
