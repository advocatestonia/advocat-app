// Prompt-caching helper for claude-proxy (Sprint 0 — FIX-1).
// -----------------------------------------------------------------------------
// Ref: docs/performance/05-cost.md §2.4-2.5 — flips unit economics from
// −€0.11/user to +€2.39/user by saving 30-45% of input tokens.
//
// Strategy:
//   - When body.system is a STRING: wrap in a single content block and mark
//     the whole block with cache_control: ephemeral. ~90% of the typical
//     Advocat system prompt (~5k tokens) is legal corpus + base role — all
//     stable across a user's session, so a 5-min ephemeral cache captures
//     essentially everything. The per-message dynamic "user context" bit is
//     in `body.messages[]`, NOT `body.system` — so caching the full system
//     string is safe and produces excellent hit rates.
//   - When body.system is an ARRAY: honour the client's explicit split.
//     We add cache_control to any content block that doesn't already have
//     one and has meaningful length (>=1024 chars, Anthropic's practical
//     floor for cache viability). Blocks that are already marked are left
//     alone.
//
// Anthropic requirements:
//   - `anthropic-version: 2023-06-01` (already present)
//   - `anthropic-beta: prompt-caching-2024-07-31` (added — see buildAnthropicHeaders)
//
// Cache-write cost = 1.25x base input. Cache-read cost = 0.1x base input.
// With repeat-hit ratio > 0.17 we already net positive. Typical session has
// 10-30 messages within a 5-min window → ratio is 0.9+.
// -----------------------------------------------------------------------------

/** Min block size where prompt caching is worth the 1.25x write overhead. */
export const CACHE_MIN_CHARS = 1024;

export interface TextBlock {
  type: "text";
  text: string;
  cache_control?: { type: "ephemeral" };
}

/**
 * Rewrite body.system in-place to enable prompt caching. Returns the new
 * body. Idempotent: if body.system is already an array with cache_control
 * set, leaves it alone.
 */
export function applyPromptCaching<T extends { system?: unknown }>(
  body: T,
): T {
  const system = body.system;
  if (system === undefined || system === null) {
    return body; // Nothing to cache.
  }
  if (typeof system === "string") {
    if (system.length === 0) {
      // Empty — drop the field entirely; Anthropic accepts both.
      return body;
    }
    if (system.length < CACHE_MIN_CHARS) {
      // Too small to be worth the 1.25x write overhead. Leave as string.
      return body;
    }
    // Wrap in a single cached block.
    (body as { system: TextBlock[] }).system = [
      {
        type: "text",
        text: system,
        cache_control: { type: "ephemeral" },
      },
    ];
    return body;
  }
  if (Array.isArray(system)) {
    for (const block of system) {
      if (
        block && typeof block === "object" &&
        (block as TextBlock).type === "text" &&
        typeof (block as TextBlock).text === "string" &&
        (block as TextBlock).text.length >= CACHE_MIN_CHARS &&
        !(block as TextBlock).cache_control
      ) {
        (block as TextBlock).cache_control = { type: "ephemeral" };
      }
    }
    return body;
  }
  // Other shapes (object, number, boolean) are a protocol error — but that's
  // handled upstream by validateSystemPrompt; nothing to do here.
  return body;
}

/** Build the header set for Anthropic API calls, including caching beta. */
export function buildAnthropicHeaders(apiKey: string): Record<string, string> {
  return {
    "Content-Type": "application/json",
    "x-api-key": apiKey,
    // Stable API version the function has always used.
    "anthropic-version": "2023-06-01",
    // FIX-1 (Sprint 0): enables cache_control on content blocks.
    // Safe to always send — Anthropic ignores the beta header on calls
    // that don't use the feature.
    "anthropic-beta": "prompt-caching-2024-07-31",
  };
}
