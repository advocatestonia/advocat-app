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

import type { CaseContext, SupportedLanguage } from "../consilium_roles/types.ts";
import { normalizeLanguage } from "../consilium_roles/types.ts";

/** Anthropic model id this agent should run on. */
export type LawyerModel = "sonnet" | "opus" | "haiku";

// ─── Reply-language directive helper ─────────────────────────────────────────
//
// Each lawyer agent prepends a one-line "respond in <language>" directive to
// its system prompt so the model output language matches the user's UI locale.
//
// P0 bug fix 2026-05-25: previously each agent ended its replyLang ternary
// with a Russian default. Any user whose ctx.language was not in
// {fi, et, en} (or {fi, et, ru} for FI-native lawyers) got Russian output —
// Polish user → Russian, Arabic → Russian, Ukrainian → Russian. Now every
// one of the 17 SUPPORTED_LANGUAGES has an explicit directive. Languages
// without a native legal-register polish fall back to an English directive
// that names the target language — the model can still produce the correct
// output language even when our prompt isn't in that language yet.
//
// `flavour` lets a lawyer agent override the directive for languages where
// the agent has native-quality polish (e.g. senior_asianajaja uses Finnish
// for fi, but Russian-with-Finnish-terms for ru). The base table covers the
// "general" case; flavour entries take precedence.
// -----------------------------------------------------------------------------

const BASE_REPLY_DIRECTIVES: Readonly<Record<SupportedLanguage, string>> = {
  en: "Reply in English; statute citations in source language.",
  ru: "Отвечай по-русски. Цитаты норм — на родном языке (FI / ET / EN).",
  et: "Vasta eesti keeles.",
  fi: "Vastaa suomeksi.",
  de: "Antworte auf Deutsch; Gesetzeszitate in Originalsprache.",
  fr: "Réponds en français ; cite les textes de loi dans leur langue d'origine.",
  es: "Responde en español; cita las leyes en su idioma original.",
  it: "Rispondi in italiano; cita le leggi nella lingua originale.",
  pl: "Odpowiadaj po polsku; cytaty ustaw w języku oryginału.",
  sv: "Svara på svenska; lagcitat i originalspråk.",
  lt: "Atsakyk lietuviškai; teisės aktų citatos – originalo kalba.",
  lv: "Atbildi latviešu valodā; likumu citāti – oriģinālvalodā.",
  uk: "Відповідай українською; цитати норм — мовою оригіналу (FI / ET / EN).",
  ro: "Răspunde în română; citează legile în limba originală.",
  ar: "أجب بالعربية؛ اقتبس النصوص القانونية بلغتها الأصلية.",
  fa: "به فارسی پاسخ دهید؛ متون قانونی را به زبان اصلی نقل قول کنید.",
  tr: "Türkçe cevap ver; kanun alıntılarını orijinal dilinde tut.",
};

/** Build the per-language reply directive for a lawyer agent.
 *
 *  @param lang    The case context language (will be normalised — region
 *                 tags stripped, unknowns mapped to "en").
 *  @param flavour Optional overrides for specific languages where this
 *                 lawyer has native-quality polish (e.g. senior_asianajaja
 *                 overrides "fi" with a longer Finnish directive). Languages
 *                 not in the flavour map use the BASE_REPLY_DIRECTIVES entry.
 *  @returns       The directive string (always non-empty). NEVER returns
 *                 Russian unless the user explicitly requested ru.
 */
export function buildReplyDirective(
  lang: CaseContext["language"] | string | undefined,
  flavour?: Partial<Record<SupportedLanguage, string>>,
): string {
  const normalised = normalizeLanguage(lang);
  if (flavour && flavour[normalised]) return flavour[normalised]!;
  return BASE_REPLY_DIRECTIVES[normalised];
}

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
      return "claude-opus-4-8";
    case "haiku":
      return "claude-haiku-4-5-20251001";
    case "sonnet":
    default:
      return "claude-sonnet-4-6";
  }
}

/** Minimal context shim the router can build from raw query + lang when no
 *  case is loaded yet. Lets the lawyer agents always receive a real CaseContext.
 *
 *  P0 fix 2026-05-25: the `lang` parameter is now normalised so callers can
 *  pass raw BCP47 tags ("fi-FI", " RU ", "pl_PL", "xx") and downstream agents
 *  still see a SupportedLanguage. */
export function buildLawyerCtx(
  query: string,
  lang: NonNullable<CaseContext["language"]> | string,
  base?: CaseContext,
): CaseContext {
  const ctx: CaseContext = base ? { ...base } : {};
  // Normalise the incoming lang; preserve base.language if it was already set
  // (so an explicit ctx.language survives even if the caller passed something
  // unusable in `lang`).
  const normalised = normalizeLanguage(ctx.language ?? lang);
  ctx.language = normalised;
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
