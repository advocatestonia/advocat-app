// Prompt-caching helper for claude-proxy (Sprint 0 — FIX-1).
// -----------------------------------------------------------------------------
// Ref: docs/performance/05-cost.md §2.4-2.5 — flips unit economics from
// −€0.11/user to +€2.39/user by saving 30-45% of input tokens.
//
// Strategy:
//   - When body.system is a STRING: wrap in a single content block and mark
//     the whole block with cache_control: ephemeral. ~90% of the typical
//     Advocat system prompt (~5k tokens) is legal corpus + base role — all
//     stable across a user's session, so a 1h ephemeral cache captures
//     essentially everything. The per-message dynamic "user context" bit is
//     in `body.messages[]`, NOT `body.system` — so caching the full system
//     string is safe and produces excellent hit rates.
//   - When body.system is an ARRAY: honour the client's explicit split.
//     We add cache_control to any content block that doesn't already have
//     one and has meaningful length (>=1024 chars, Anthropic's practical
//     floor for cache viability). Blocks that are already marked are left
//     alone — but if they lack a TTL we upgrade them to the 1h tier so a
//     mixed shape never silently regresses to the 5m default.
//
// Anthropic requirements:
//   - `anthropic-version: 2023-06-01` (already present)
//   - `anthropic-beta: prompt-caching-2024-07-31` (added — see buildAnthropicHeaders)
//
// TTL choice — explicit 1h (CACHE_TTL = "1h"):
//   Anthropic changed the default cache_control TTL from 1h to 5m in
//   March 2026 (silent regression — no error, just degraded hit rates).
//   Production users on long sessions (Advocat dialogues run 20-90 min)
//   started losing 30-60% of expected cache hits because consecutive turns
//   stopped landing inside the 5-minute eviction window. We now set the TTL
//   explicitly on every cache_control block so the deployment is independent
//   of whatever default Anthropic ships next. Both Sonnet 4.6 and Haiku 4.5
//   support the 1h tier (announced 2024 GA, still active 2026).
//
// Cache write costs scale with TTL (1.25× for 5m, 2× for 1h base input).
// Cache reads are 0.1× either way. With Advocat's hit ratio (typically
// 0.8-0.95 across a session) the 2× write premium pays back inside the
// first 2-3 cached turns, and the longer window captures the entire
// session-mean dialogue length (~30 min for free, ~75 min for premium).
// -----------------------------------------------------------------------------

/** Min block size where prompt caching is worth the 2x write overhead. */
export const CACHE_MIN_CHARS = 1024;

/**
 * Explicit cache TTL applied to every cache_control block we set.
 *
 * Why this constant exists (March 2026): Anthropic silently regressed the
 * default TTL from "1h" to "5m". Without the explicit value below the API
 * still accepts our request — it just falls back to the new 5m default and
 * our long-session hit rate halves. Pin it here and adjust in ONE place if
 * the economics ever change.
 *
 * Supported values per Anthropic API (2026): "5m" or "1h".
 */
export const CACHE_TTL = "1h" as const;

export interface TextBlock {
  type: "text";
  text: string;
  cache_control?: { type: "ephemeral"; ttl?: string };
}

/**
 * Rewrite body.system in-place to enable prompt caching. Returns the new
 * body. Idempotent: if body.system is already an array with cache_control
 * set, leaves it alone — except that we upgrade any cache_control block
 * missing a TTL to our explicit CACHE_TTL, so mixed-shape callers can't
 * silently regress to Anthropic's 5m default.
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
      // Too small to be worth the 2x write overhead. Leave as string.
      return body;
    }
    // Wrap in a single cached block. Always pin TTL explicitly — see
    // CACHE_TTL doc comment for the March 2026 regression context.
    (body as { system: TextBlock[] }).system = [
      {
        type: "text",
        text: system,
        cache_control: { type: "ephemeral", ttl: CACHE_TTL },
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
        (block as TextBlock).text.length >= CACHE_MIN_CHARS
      ) {
        const tb = block as TextBlock;
        if (!tb.cache_control) {
          // New marker — always pinned to CACHE_TTL.
          tb.cache_control = { type: "ephemeral", ttl: CACHE_TTL };
        } else if (!tb.cache_control.ttl) {
          // Caller-supplied marker without explicit TTL would inherit
          // Anthropic's current default (5m as of March 2026). Force-pin
          // to CACHE_TTL so a single uniform policy holds across the
          // entire request body.
          tb.cache_control.ttl = CACHE_TTL;
        }
      }
    }
    return body;
  }
  // Other shapes (object, number, boolean) are a protocol error — but that's
  // handled upstream by validateSystemPrompt; nothing to do here.
  return body;
}

/** Build the header set for Anthropic API calls, including caching beta
 *  AND interleaved-thinking beta (Reasoning Trail v1, 2026-05-05).
 *
 *  `interleaved-thinking-2025-05-14` lets the model interleave thinking
 *  blocks with tool_use blocks within a single turn — required for the
 *  pill UX where the user sees stages like "thinking → searching law →
 *  thinking → composing answer". Safe to always send: Anthropic ignores
 *  the beta when the request doesn't use the feature.
 */
export function buildAnthropicHeaders(apiKey: string): Record<string, string> {
  return {
    "Content-Type": "application/json",
    "x-api-key": apiKey,
    // Stable API version the function has always used.
    "anthropic-version": "2023-06-01",
    // Comma-separated betas: prompt caching (Sprint 0) + interleaved
    // thinking (Reasoning Trail v1, 2026-05-05). Both ignored when the
    // request body doesn't use them.
    "anthropic-beta":
      "prompt-caching-2024-07-31,interleaved-thinking-2025-05-14",
  };
}
