// =============================================================================
// _shared/providers/openai_provider.ts
// =============================================================================
// FIX-WAVE 14 — OpenAI Chat Completions provider for the fallback chain.
//
// Why this exists:
//   When the primary Anthropic provider trips (credit exhausted, sustained
//   429, regional outage), the proxy needs a second source of generations.
//   GPT-4o-mini is ~20× cheaper than Sonnet ($0.15/M in vs $3/M in) and
//   sufficient for the kind of degraded-mode answers we serve from the
//   fallback chain. Higher-tier OpenAI models can be requested by the chain
//   via the `model` argument.
//
// Anthropic-style call signature, OpenAI-style wire format:
//   The Anthropic SDK treats the system prompt as a top-level `system` field
//   while OpenAI expects it as the first message with `{role: 'system'}`.
//   We accept the Anthropic-style separate `systemPrompt` arg and inline it
//   as the first message ourselves, so callers can pass identical bodies to
//   both providers.
//
// Error mapping is uniform across providers — see ./types.ts.
// =============================================================================

import {
  Provider429Error,
  ProviderAuthError,
  ProviderError,
  type ProviderResponse,
  ProviderTimeoutError,
} from "./types.ts";

const OPENAI_TIMEOUT_MS = 60_000;
const OPENAI_ENDPOINT = "https://api.openai.com/v1/chat/completions";

export interface CallOpenAIArgs {
  systemPrompt: string;
  messages: Array<{ role: string; content: string }>;
  maxTokens: number;
  model?: string;
}

/**
 * Parse the OpenAI `retry-after` header. The spec allows either a number of
 * seconds OR an HTTP date. Returns `undefined` if neither parses cleanly.
 */
function parseRetryAfter(header: string | null): number | undefined {
  if (!header) return undefined;
  const trimmed = header.trim();
  // Plain integer seconds.
  const asInt = Number.parseInt(trimmed, 10);
  if (Number.isFinite(asInt) && asInt >= 0 && /^\d+$/.test(trimmed)) {
    return asInt;
  }
  // HTTP-date — compute the delta in seconds from now.
  const ts = Date.parse(trimmed);
  if (Number.isFinite(ts)) {
    const deltaMs = ts - Date.now();
    return deltaMs > 0 ? Math.ceil(deltaMs / 1000) : 0;
  }
  return undefined;
}

/**
 * Call OpenAI Chat Completions. Returns the assistant text + token usage.
 * Throws one of the typed provider errors on any non-2xx response.
 */
export async function callOpenAI(
  args: CallOpenAIArgs,
): Promise<ProviderResponse> {
  const { systemPrompt, messages, maxTokens, model = "gpt-4o-mini" } = args;

  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) {
    throw new ProviderAuthError();
  }

  // Convert Anthropic-style {system, messages} → OpenAI {messages with system}.
  const openaiMessages = [
    { role: "system", content: systemPrompt },
    ...messages,
  ];

  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), OPENAI_TIMEOUT_MS);

  let res: Response;
  try {
    res = await fetch(OPENAI_ENDPOINT, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model,
        messages: openaiMessages,
        max_tokens: maxTokens,
      }),
      signal: ctrl.signal,
    });
  } catch (e) {
    if ((e as Error).name === "AbortError") {
      throw new ProviderTimeoutError();
    }
    throw new ProviderError(
      `network error: ${String(e).slice(0, 200)}`,
      0,
    );
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
  if (!res.ok) {
    const body = await res.text().catch(() => "");
    throw new ProviderError(
      `openai ${res.status}`,
      res.status,
      body.slice(0, 1000),
    );
  }

  const data = await res.json() as {
    choices?: Array<{ message?: { content?: string } }>;
    usage?: { prompt_tokens?: number; completion_tokens?: number };
  };

  const text = data.choices?.[0]?.message?.content ?? "";
  const inputTokens = Number(data.usage?.prompt_tokens ?? 0);
  const outputTokens = Number(data.usage?.completion_tokens ?? 0);

  return { text, inputTokens, outputTokens };
}
