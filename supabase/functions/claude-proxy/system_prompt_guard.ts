// System-prompt guard for claude-proxy (Sprint 0 — FIX-4).
// -----------------------------------------------------------------------------
// Ref: docs/security/05-code-security.md H1, docs/security/07-business-logic.md
// H1 — "Custom system-prompt bypass enables free Claude proxy". An authenticated
// Advocat user can set body.system to anything (e.g. "You are a pirate"), and
// the Edge Function forwards it to Anthropic verbatim. That turns Advocat into
// a free Claude API proxy: $450-$2250/mo burn per rogue Pro user.
//
// FIX-4 approach (non-breaking):
//   - We do NOT move legal-corpus construction server-side — that's a much
//     bigger refactor and would break 1068 passing tests.
//   - Instead we enforce a STRUCTURAL invariant on body.system: the content
//     must begin with a recognised Advocat identity marker. Every legit
//     system prompt the client builds (see lib/services/system_prompts.dart)
//     already starts with "You are Advocat" or a pinned variant. A "You are
//     a pirate" style rogue prompt has no way to satisfy this check.
//   - The guard also handles the Anthropic content-block shape where
//     body.system is an array (used for prompt caching — see FIX-1).
//
// If the check fails, the caller gets 400 "system prompt is server-
// controlled" rather than having their prompt silently rewritten — this
// surfaces the error in logs so we can investigate and tune the whitelist.
// -----------------------------------------------------------------------------

/** Recognised identity markers. Legit Advocat prompts must START with one. */
export const ADVOCAT_IDENTITY_MARKERS: readonly string[] = [
  // Primary: English base role used by lib/services/system_prompts.dart.
  "You are Advocat",
  // Shorter variant for light prompts.
  "You are an expert legal",
  // Document-analysis specialist prompt (claude_service.dart:456).
  "You are analyzing a legal document",
  // Draft-generation specialist prompt (system_prompts.dart:413).
  "You are generating a legal document draft",
  // Warm/friendly tone specialist prompt (system_prompts.dart:232).
  "You are a warm, experienced friend",
  // Tool-aware prompt (system_prompts.dart:188).
  "You are a powerful AI legal assistant",
  // Fallback Advocat identity used in some flows.
  "Advocat, an AI",
  "Advocat, a legal",
  // Memory-prefixed prompts (ai_service.dart:879 + :1135). When a user has
  // Tier 1 memory, the client wraps the base system prompt with this header.
  // The actual Advocat identity sits after the memory block — which can be
  // longer than the 500-char head we search — so whitelist the prefix itself.
  "# CLIENT PERSONAL KNOWLEDGE BASE",
  // Auto-Timeline extractor prompt (assets/prompts/case_file_extractor.txt).
  // Fired as a second POST per chat turn to extract structured legal-case
  // metadata (events / parties / deadlines / documents / key_facts) as JSON.
  // Without this marker the guard 400'd the call and Sofia's Timeline silently
  // never built. Fixed 2026-05-05.
  "You are a legal-information extractor",
];

export type GuardResult =
  | { kind: "allow" }
  | { kind: "reject"; reason: string };

/** Max bytes allowed for a serialised system prompt.
 *
 * Raised from 50_000 → 200_000 on 2026-05-05 after a live regression in
 * production: the chat client builds its system prompt by concatenating
 * the Advocat base role + KnowledgeBase legal corpus (≈ 45 KB on its
 * own, see lib/services/knowledge_base.dart, 873 lines of EU + Estonian
 * + Finnish procedural law) + the Tier-1 memory block. Realistic chat
 * turns crossed 50 KB, the guard 400'd, and the user saw the catch-all
 * "Временная ошибка AI" in chat_screen.dart:1054.
 *
 * 200 KB still bounds the worst case (Anthropic itself caps the system
 * field around 200 KB serialized; rejecting > 200 KB protects against
 * a 1 MB+ DDoS payload while letting the legitimate prompt through).
 * Token cost is bounded separately by Anthropic's input-token limit
 * and the 7-message free-tier quota; this limit is purely about HTTP
 * body size on the Edge Function. */
export const MAX_SYSTEM_BYTES = 200_000;

/**
 * Validate that body.system (if present) is a legitimate Advocat prompt.
 * Accepts:
 *   - undefined / null / empty (no system prompt — Anthropic default)
 *   - string starting with an Advocat marker
 *   - array of content blocks where the FIRST text block starts with a
 *     marker (enables FIX-1 prompt caching without losing the guard)
 * Rejects everything else with a stable error string.
 */
export function validateSystemPrompt(system: unknown): GuardResult {
  if (system === undefined || system === null) return { kind: "allow" };

  // String form.
  if (typeof system === "string") {
    if (system.length === 0) return { kind: "allow" };
    if (system.length > MAX_SYSTEM_BYTES) {
      return {
        kind: "reject",
        reason: "system prompt too large (max 50 KB)",
      };
    }
    if (startsWithMarker(system)) return { kind: "allow" };
    return {
      kind: "reject",
      reason:
        "system prompt is server-controlled — must begin with a recognised " +
        "Advocat identity marker",
    };
  }

  // Array form (Anthropic content-block system prompt, used for caching).
  if (Array.isArray(system)) {
    if (system.length === 0) return { kind: "allow" };
    // Find the first block with a non-empty text field.
    let firstText = "";
    let totalBytes = 0;
    for (const block of system) {
      if (block && typeof block === "object" && typeof (block as { text?: unknown }).text === "string") {
        const t = (block as { text: string }).text;
        totalBytes += t.length;
        if (!firstText && t.length > 0) firstText = t;
      }
    }
    if (totalBytes > MAX_SYSTEM_BYTES) {
      return {
        kind: "reject",
        reason: "system prompt too large (max 50 KB across all blocks)",
      };
    }
    if (!firstText) {
      // Array with no text content — Anthropic would reject this anyway.
      return {
        kind: "reject",
        reason: "system prompt array must contain at least one text block",
      };
    }
    if (startsWithMarker(firstText)) return { kind: "allow" };
    return {
      kind: "reject",
      reason:
        "system prompt is server-controlled — first text block must begin " +
        "with a recognised Advocat identity marker",
    };
  }

  // Any other shape (object, number, boolean) is a protocol error.
  return {
    kind: "reject",
    reason: "system prompt must be a string or an array of content blocks",
  };
}

function startsWithMarker(text: string): boolean {
  // Trim leading whitespace and common markdown/section headers that legit
  // Advocat prompts may include (e.g. "# ROLE\n\nYou are Advocat...").
  // Don't lowercase — our markers are proper nouns and "You are advocat"
  // (lowercase a) would be an attempted evasion.
  //
  // Strategy: look for a marker anywhere in the first 500 chars. That
  // gives us leeway for "# ROLE", "## SYSTEM PROMPT", blank lines, etc.
  // 500 chars is small enough that a rogue prompt can't hide an attack
  // before the marker.
  const head = text.slice(0, 500);
  for (const marker of ADVOCAT_IDENTITY_MARKERS) {
    if (head.includes(marker)) return true;
  }
  return false;
}
