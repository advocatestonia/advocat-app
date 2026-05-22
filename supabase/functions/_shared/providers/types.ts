// =============================================================================
// _shared/providers/types.ts
// =============================================================================
// FIX-WAVE 14 — Shared types and error classes for the provider abstraction
// layer. Each LLM provider (Anthropic, OpenAI, …) exports a single async
// `callXxx(args): Promise<ProviderResponse>` function and signals failure via
// one of the typed error classes below. The provider chain (FIX 15) inspects
// the error class to decide whether to fall back to the next provider.
//
// Design notes:
//   • `ProviderResponse` is intentionally minimal — text + token counts —
//     because the chain layer is provider-agnostic and only needs enough to
//     bookkeep spend and return a body to the user.
//   • Token shapes match Anthropic's `usage.input_tokens / output_tokens`
//     naming convention. OpenAI's `prompt_tokens / completion_tokens` are
//     mapped to this shape inside `openai_provider.ts`.
//   • `Provider429Error` carries `retryAfterSec` so the chain can decide
//     between "back-off and retry same provider" vs "skip to next provider".
//   • `ProviderCreditExhaustedError` exists specifically for the Anthropic
//     400 "credit balance is too low" case (lesson_anthropic_zero_balance_
//     fallback, 2026-05-13). It is a strong signal to switch providers,
//     not a transient retry condition.
// =============================================================================

export interface ProviderResponse {
  /** The assistant text reply (concatenated if multiple content blocks). */
  text: string;
  /** Prompt-side tokens (Anthropic: input_tokens / OpenAI: prompt_tokens). */
  inputTokens: number;
  /** Completion-side tokens (Anthropic: output_tokens / OpenAI: completion_tokens). */
  outputTokens: number;
}

export class ProviderError extends Error {
  status: number;
  body?: string;
  constructor(msg: string, status: number, body?: string) {
    super(msg);
    this.name = "ProviderError";
    this.status = status;
    this.body = body;
  }
}

export class Provider429Error extends ProviderError {
  retryAfterSec?: number;
  constructor(retryAfterSec?: number) {
    super("rate limited", 429);
    this.name = "Provider429Error";
    this.retryAfterSec = retryAfterSec;
  }
}

export class ProviderAuthError extends ProviderError {
  constructor() {
    super("auth failed", 401);
    this.name = "ProviderAuthError";
  }
}

export class ProviderCreditExhaustedError extends ProviderError {
  constructor() {
    super("credit exhausted", 400);
    this.name = "ProviderCreditExhaustedError";
  }
}

export class ProviderTimeoutError extends ProviderError {
  constructor() {
    super("timeout", 408);
    this.name = "ProviderTimeoutError";
  }
}
