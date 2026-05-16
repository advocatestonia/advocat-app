// lawyer_agents/types.ts — Shared types for the specialised lawyer department.
// -----------------------------------------------------------------------------
// Each lawyer agent is a real, individuated practitioner — not a thin domain
// wrapper. The department is invoked by the consilium router AFTER complexity
// triage decides a case warrants the senior bar.
//
// Contract for every agent file under lawyer_agents/:
//   • `name` — single string display name (no LocalisedName here; the
//     consilium runner already localises around it).
//   • `expertise` — corpus act_slugs / case categories the agent owns. Used
//     by the router for keyword + slug matching.
//   • `triggerKeywords` — lowercased substrings that surface this agent in
//     the router's keyword pass. Multilingual (RU/ET/FI/EN).
//   • `model` — Sonnet by default; Opus for litigator + strategist when the
//     case is high-stakes (router decides).
//   • `systemPrompt(query, ctx)` — full role prompt. Receives the original
//     user message + the same CaseContext the rest of the consilium sees.
//
// Style mandate:
//   The 11 agents MUST sound different. Each has a distinct voice (formalist,
//   strategist, empath, brawler, archivist). Same statute, different framings.
// -----------------------------------------------------------------------------

import type { CaseContext } from "../consilium_roles/types.ts";

/** Anthropic model id this agent should run on. */
export type LawyerModel = "sonnet" | "opus" | "haiku";

/** Display name + style flag — used by the consilium runner for the "Round 1"
 *  banner and for the synthesis header. */
export interface LawyerAgent {
  /** Stable id (kebab-case). Used by the router for selection + dedupe. */
  id: string;
  /** Display name shown in the consilium UI / synthesis header. */
  name: string;
  /** Free-form one-line summary of the agent's seat at the table. */
  tagline: string;
  /** Corpus act_slugs / case-category tags the agent specialises in. */
  expertise: readonly string[];
  /** Lowercase substrings that surface this agent in the keyword pass. */
  triggerKeywords: readonly string[];
  /** Default model for this role. Router may override for high-stakes. */
  model: LawyerModel;
  /** Cap on output tokens — keeps the consilium cost predictable. */
  maxTokens: number;
  /** Build the system prompt body. Receives the original user query (so the
   *  agent can self-anchor) and the case context (jurisdiction, complexity,
   *  case file). NO calibration / law context appended here — the consilium
   *  runner wraps these in. */
  systemPrompt: (query: string, ctx: CaseContext) => string;
}

/** Resolve the LawyerModel to the actual Anthropic model id. */
export function resolveModelId(m: LawyerModel): string {
  switch (m) {
    case "opus":
      return "claude-opus-4-1-20250805";
    case "haiku":
      return "claude-haiku-4-5-20251001";
    case "sonnet":
    default:
      return "claude-sonnet-4-6";
  }
}

/** Minimal context shim the router can build from raw query + lang when no
 *  case is loaded yet. Lets the lawyer agents always receive a real CaseContext. */
export function buildLawyerCtx(
  query: string,
  lang: NonNullable<CaseContext["language"]>,
  base?: CaseContext,
): CaseContext {
  const ctx: CaseContext = base ? { ...base } : {};
  ctx.language = ctx.language ?? lang;
  if (!ctx.keywords || ctx.keywords.length === 0) {
    ctx.keywords = extractKeywords(query);
  }
  return ctx;
}

/** Very small keyword extractor — splits on non-letters and keeps tokens
 *  ≥4 chars. Lowercase. No language-specific stemming; the router matches
 *  multilingual substrings directly. */
export function extractKeywords(text: string): readonly string[] {
  const tokens = text
    .toLowerCase()
    .split(/[^a-zа-яäöõüšž§0-9]+/u)
    .filter((t) => t.length >= 3);
  // Dedupe preserving order
  const seen = new Set<string>();
  const out: string[] = [];
  for (const t of tokens) {
    if (!seen.has(t)) {
      seen.add(t);
      out.push(t);
    }
  }
  return out;
}
