// scrub_body.ts — apply the identifiers-only PII scrub to an Anthropic-shaped
// request body (system + messages[].content). Shared by every egress site so
// the scrub logic lives in ONE tested place.
// ----------------------------------------------------------------------------
// "identifiers-only" tier (Data Fortress, 2026-06-13): strips DIRECT
// government/financial identifiers (isikukood, HETU, IBAN) that the LLM never
// needs to reason about, while KEEPING names/emails/phones/case-numbers that
// tool-calling and draft fidelity require. EU-residency is the backstop for
// the contextual PII that stays.
//
// Pure and defensive: never throws. On any malformed body it returns the input
// unchanged — a scrub bug must never take a chat/extraction path down, and the
// identifiers stay inside our own EU infra either way.
// ----------------------------------------------------------------------------

import { pseudonymize } from "./pseudonymizer.ts";

/**
 * Scrub direct identifiers from an Anthropic-shaped request body's `system`
 * string and `messages[].content` (string or text-block array). Returns a new
 * body; does not mutate the input. Use at the point just before the fetch to
 * api.anthropic.com.
 */
export function scrubAnthropicBody(body: unknown): unknown {
  try {
    // deno-lint-ignore no-explicit-any
    const b = body as any;
    if (!b || typeof b !== "object") return body;

    const scrub = (s: unknown): unknown =>
      typeof s === "string" && s
        ? pseudonymize(s, { identifiersOnly: true }).text
        : s;

    const out = { ...b };
    if (typeof out.system === "string") out.system = scrub(out.system);
    if (Array.isArray(out.messages)) {
      out.messages = out.messages.map((m: { content?: unknown }) => {
        if (typeof m?.content === "string") {
          return { ...m, content: scrub(m.content) };
        }
        if (Array.isArray(m?.content)) {
          return {
            ...m,
            content: m.content.map((blk: { type?: string; text?: string }) =>
              blk && blk.type === "text" && typeof blk.text === "string"
                ? { ...blk, text: scrub(blk.text) }
                : blk
            ),
          };
        }
        return m;
      });
    }
    return out;
  } catch (_e) {
    return body;
  }
}

/**
 * Scrub a single plaintext string (for non-Anthropic shapes: OpenAI embeddings
 * `input`, whisper text, etc.). identifiers-only by default; pass full=true to
 * strip names/emails too (for paths with no tool-calling/draft needs).
 */
export function scrubText(text: string, opts: { full?: boolean } = {}): string {
  if (!text) return text;
  try {
    return pseudonymize(text, { identifiersOnly: !opts.full }).text;
  } catch (_e) {
    return text;
  }
}
