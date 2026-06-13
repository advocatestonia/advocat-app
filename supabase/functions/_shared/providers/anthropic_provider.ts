// =============================================================================
// _shared/providers/anthropic_provider.ts
// =============================================================================
// FIX-WAVE 14 — Anthropic Messages provider for the fallback chain.
//
// This module hoists the bare `fetch('https://api.anthropic.com/v1/messages')`
// call previously inlined in claude-proxy/index.ts (~line 2031 and ~line 1657)
// into a shared, error-classifying wrapper. The chain layer (FIX 15) calls it
// the same way it calls callOpenAI — uniform shape, uniform errors.
//
// Special case — credit exhaustion:
//   Anthropic returns HTTP 400 with body containing "credit balance is too low"
//   when the org's prepaid credit hits zero. This is NOT a generic 400; the
//   chain should treat it as a hard signal to fall over to OpenAI. Mapped to
//   ProviderCreditExhaustedError. See lesson_anthropic_zero_balance_fallback
//   (commit f0394f5, 2026-05-13) for the user-visible incident this prevents.
//
// Headers and request body shape match the existing claude-proxy contract —
// see prompt_caching.ts::buildAnthropicHeaders for the canonical headers.
// =============================================================================

import {
  Provider429Error,
  ProviderAuthError,
  ProviderCreditExhaustedError,
  ProviderError,
  type ProviderResponse,
  ProviderTimeoutError,
} from "./types.ts";

const ANTHROPIC_TIMEOUT_MS = 60_000;
const ANTHROPIC_ENDPOINT = "https://api.anthropic.com/v1/messages";

export interface CallAnthropicArgs {
  systemPrompt: string;
  messages: Array<{ role: string; content: string }>;
  maxTokens: number;
  model: string;
}

function parseRetryAfter(header: string | null): number | undefined {
  if (!header) return undefined;
  const trimmed = header.trim();
  const asInt = Number.parseInt(trimmed, 10);
  if (Number.isFinite(asInt) && asInt >= 0 && /^\d+$/.test(trimmed)) {
    return asInt;
  }
  const ts = Date.parse(trimmed);
  if (Number.isFinite(ts)) {
    const deltaMs = ts - Date.now();
    return deltaMs > 0 ? Math.ceil(deltaMs / 1000) : 0;
  }
  return undefined;
}

/**
 * Returns true if the Anthropic 400 body is the "credit balance is too low"
 * shape. Conservative — only the exact substring, no false positives from
 * validation 400s.
 */
function isCreditExhaustedBody(body: string): boolean {
  if (!body) return false;
  const lower = body.toLowerCase();
  return (
    lower.includes("credit balance") &&
    (lower.includes("too low") || lower.includes("insufficient"))
  );
}

/**
 * Concatenate all text blocks in an Anthropic response into a single string.
 * Non-text blocks (tool_use, image, etc.) are ignored — the fallback chain
 * is text-only.
 */
function concatTextBlocks(content: unknown): string {
  if (!Array.isArray(content)) {
    return typeof content === "string" ? content : "";
  }
  const parts: string[] = [];
  for (const block of content) {
    if (
      block &&
      typeof block === "object" &&
      (block as { type?: string }).type === "text" &&
      typeof (block as { text?: unknown }).text === "string"
    ) {
      parts.push((block as { text: string }).text);
    }
  }
  return parts.join("");
}

/**
 * Call Anthropic Messages. Returns text + token usage. Throws typed errors.
 */
export async function callAnthropic(
  args: CallAnthropicArgs
): Promise<ProviderResponse> {
  const { systemPrompt, messages, maxTokens, model } = args;

  const apiKey =
    Deno.env.get("CLAUDE_API_KEY") ?? Deno.env.get("ANTHROPIC_API_KEY");
  if (!apiKey) {
    throw new ProviderAuthError();
  }

  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), ANTHROPIC_TIMEOUT_MS);

  let res: Response;
  try {
    res = await fetch(ANTHROPIC_ENDPOINT, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model,
        system: systemPrompt,
        messages,
        max_tokens: maxTokens,
      }),
      signal: ctrl.signal,
    });
  } catch (e) {
    if ((e as Error).name === "AbortError") {
      throw new ProviderTimeoutError();
    }
    throw new ProviderError(`network error: ${String(e).slice(0, 200)}`, 0);
  } finally {
    clearTimeout(timer);
  }

  if (res.status === 401) {
    throw new ProviderAuthError();
  }
  if (res.status === 429) {
    const retryAfter = parseRetryAfter(res.headers.get("retry-after"));
    throw new Provider429Error(retryAfter);
  }
  if (res.status === 400) {
    const body = await res.text().catch(() => "");
    if (isCreditExhaustedBody(body)) {
      throw new ProviderCreditExhaustedError();
    }
    throw new ProviderError(`anthropic 400`, 400, body.slice(0, 1000));
  }
  if (!res.ok) {
    const body = await res.text().catch(() => "");
    throw new ProviderError(
      `anthropic ${res.status}`,
      res.status,
      body.slice(0, 1000)
    );
  }

  const data = (await res.json()) as {
    content?: unknown;
    usage?: { input_tokens?: number; output_tokens?: number };
  };

  const text = concatTextBlocks(data.content);
  const inputTokens = Number(data.usage?.input_tokens ?? 0);
  const outputTokens = Number(data.usage?.output_tokens ?? 0);

  return { text, inputTokens, outputTokens };
}
