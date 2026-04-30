// =============================================================================
// claude-proxy — Anthropic error → friendly client shape
// (pre-launch fix, 2026-04-29)
// =============================================================================
//
// Anthropic Tier 1 has an aggressive 50 RPM cap on Sonnet, so users on the
// public site occasionally trip 429 (rate-limit) or 529 (overloaded). The
// previous proxy behaviour was to forward Anthropic's raw error JSON, which
// Flutter saw as "Internal error" and rendered the generic
// «Временная ошибка AI» message — the user had no idea it was a transient
// upstream problem and that retrying in a minute would work.
//
// This module maps the two retry-friendly statuses to a structured shape
// the Flutter client can act on:
//
//   429 → { "error": "rate_limit",
//           "retry_after_seconds": <int|null>,
//           "user_message_key": "ai_error_rate_limit" }
//   529 → { "error": "overload",
//           "user_message_key": "ai_error_overload" }
//
// All other 4xx/5xx statuses keep the legacy shape: { error: <string> }
// with the original status code, so existing handlers (auth, quota, generic
// 500) keep working unchanged.

export interface AnthropicErrorInput {
  /** HTTP status code returned by Anthropic. */
  status: number;
  /** Raw response body (string, may be empty / non-JSON). */
  body: string;
  /** Value of the Retry-After response header, or null when absent. */
  retryAfter: string | null;
}

// deno-lint-ignore no-explicit-any
export interface MappedError {
  status: number;
  body: Record<string, any>;
}

/**
 * Pure mapper, easy to unit-test. Does NOT do I/O.
 *
 * Returns the JSON body the proxy should forward to the Flutter client,
 * along with the status code (preserved from upstream).
 */
export function mapAnthropicError(input: AnthropicErrorInput): MappedError {
  const { status, body, retryAfter } = input;

  if (status === 429) {
    const retryAfterSeconds = parseRetryAfter(retryAfter);
    return {
      status: 429,
      body: {
        error: "rate_limit",
        retry_after_seconds: retryAfterSeconds,
        user_message_key: "ai_error_rate_limit",
        // Keep original Anthropic body for diagnostics — Flutter ignores it.
        upstream: safeParseJson(body),
      },
    };
  }

  if (status === 529) {
    return {
      status: 529,
      body: {
        error: "overload",
        user_message_key: "ai_error_overload",
        upstream: safeParseJson(body),
      },
    };
  }

  // Legacy shape — preserve back-compat with existing 4xx/5xx handlers.
  return {
    status,
    body: { error: body || `Upstream error ${status}` },
  };
}

/**
 * Parse the Retry-After header. Anthropic uses delta-seconds; the HTTP spec
 * also allows an HTTP-date but we don't get those from Anthropic. Returns
 * null for any non-numeric / missing value so the client falls back to its
 * default retry hint.
 */
function parseRetryAfter(value: string | null): number | null {
  if (!value) return null;
  const n = parseInt(value, 10);
  if (!Number.isFinite(n) || n < 0) return null;
  return n;
}

// deno-lint-ignore no-explicit-any
function safeParseJson(text: string): any {
  if (!text) return null;
  try {
    return JSON.parse(text);
  } catch {
    return null;
  }
}
