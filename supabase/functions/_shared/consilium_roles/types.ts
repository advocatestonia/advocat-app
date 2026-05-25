// consilium_roles/types.ts — shared role-type contracts for the v2.2 consilium.
// -----------------------------------------------------------------------------
// Two layers of roles power the new consilium:
//   • DomainExpert      — statute-specific (Ulkomaalaislaki, BGB, GDPR, …)
//   • StrategicPosition — reasoning patterns (decision-maker-risk, 23-test, …)
//
// Each role compiles to a single ConsiliumRole object consumed by the runner.
// -----------------------------------------------------------------------------

// ─── Supported UI locales ─────────────────────────────────────────────────────
//
// MUST stay in sync with lib/l10n/app_*.arb (17 locales as of 2026-05-25):
//   ar, de, en, es, et, fa, fi, fr, it, lt, lv, pl, ro, ru, sv, tr, uk
//
// P0 bug fix 2026-05-25: previously the enum supported only ru|et|fi|en|de and
// every fallback site hardcoded `?? "ru"`. A Finnish user landing without an
// explicit ctx.language got Russian consilium synthesis; Polish got Russian;
// Arabic got Russian. The default fallback is now ALWAYS "en" — the lawyer
// agents already include English reply branches for unknown languages.
// -----------------------------------------------------------------------------

/** The 17 UI locales we support across the app. Keep in alphabetical order
 *  for stable diffs. NEVER add a locale here without adding the matching
 *  lib/l10n/app_<code>.arb file. */
export const SUPPORTED_LANGUAGES = [
  "ar",
  "de",
  "en",
  "es",
  "et",
  "fa",
  "fi",
  "fr",
  "it",
  "lt",
  "lv",
  "pl",
  "ro",
  "ru",
  "sv",
  "tr",
  "uk",
] as const;

export type SupportedLanguage = typeof SUPPORTED_LANGUAGES[number];

/** Default fallback locale. ENGLISH — NEVER Russian. This was the P0 bug:
 *  hardcoded "ru" defaults coerced every unknown-locale user to Russian
 *  output regardless of their UI language. */
export const DEFAULT_LANGUAGE: SupportedLanguage = "en";

const SUPPORTED_LANGUAGE_SET: ReadonlySet<string> =
  new Set<string>(SUPPORTED_LANGUAGES);

/** Normalise any candidate language tag to a SupportedLanguage.
 *
 *  Rules:
 *    1. null / undefined / empty / non-string → DEFAULT_LANGUAGE ("en")
 *    2. Trim whitespace, lowercase
 *    3. Strip region/script subtag: "fi-FI" → "fi", "zh_Hant" → "zh"
 *    4. If the resulting primary tag is in SUPPORTED_LANGUAGES → return it
 *    5. Otherwise → DEFAULT_LANGUAGE ("en")
 *
 *  NEVER falls back to "ru". Callers wanting Russian must pass "ru" explicitly.
 */
export function normalizeLanguage(
  input: string | null | undefined,
): SupportedLanguage {
  if (typeof input !== "string") return DEFAULT_LANGUAGE;
  const trimmed = input.trim();
  if (trimmed.length === 0) return DEFAULT_LANGUAGE;
  // Lowercase first, then take the part before -/_ (BCP 47 region/script).
  const primary = trimmed.toLowerCase().split(/[-_]/)[0];
  if (SUPPORTED_LANGUAGE_SET.has(primary)) {
    return primary as SupportedLanguage;
  }
  return DEFAULT_LANGUAGE;
}

/** Case-context shape consumed by the router. All fields optional so the
 *  caller can pass whatever the chat layer has already extracted. */
export interface CaseContext {
  /** Primary case category. Drives which DomainExpert(s) are picked. */
  caseType?:
    | "immigration"
    | "criminal"
    | "contract"
    | "employment"
    | "tax"
    | "family"
    | "consumer"
    | "gdpr"
    | "unknown";
  /** Secondary case categories — used when a case spans multiple domains
   *  (e.g. Sulga: immigration primary + criminal as asianomistaja). The
   *  router treats each entry as a parallel applicable case type and may
   *  pull in additional domain experts. */
  secondaryTypes?: ReadonlyArray<NonNullable<CaseContext["caseType"]>>;
  /** ISO-3166 (FI, EE, DE, EU). Drives jurisdiction-specific experts. */
  jurisdiction?: "FI" | "EE" | "DE" | "EU" | "mixed" | "unknown";
  /** UI language — used for role display names AND for steering each lawyer
   *  agent's reply language. One of the 17 SUPPORTED_LANGUAGES. Callers
   *  should always pass through `normalizeLanguage()` first; the bridge and
   *  router both do this defensively. Default fallback is "en", never "ru". */
  language?: SupportedLanguage;
  /** Loose complexity score 1-10. > 6 unlocks the long-game / 23-test pair. */
  complexity?: number;
  /** Free-form keywords (lowercased) for routing nudges — e.g. "valituslupa". */
  keywords?: readonly string[];
  /** Whether a hard deadline drives the case. Forces deadline-strategist. */
  hasHardDeadline?: boolean;
  /** Whether opposing correspondence is in the case file. Forces silent-concession. */
  hasOpposingCorrespondence?: boolean;
}

/** Localised display name table. Falls back to the `en` entry first, then
 *  `ru` (legacy entries) when missing. */
export type LocalisedName = {
  /** Primary fallback — every role MUST define an English name. */
  en?: string;
  /** Legacy / Russian display name. Many roles only have ru today. Kept
   *  required for backward-compat with existing role definitions. */
  ru: string;
  et?: string;
  fi?: string;
  de?: string;
  fr?: string;
  es?: string;
  it?: string;
  pl?: string;
  sv?: string;
  lt?: string;
  lv?: string;
  uk?: string;
  ro?: string;
  ar?: string;
  fa?: string;
  tr?: string;
};

/** Common fields shared by both domain and strategic roles. */
interface BaseRole {
  /** Stable machine id (kebab-case). Used by the router + memory mapping. */
  id: string;
  /** Localised display name. */
  name: LocalisedName;
  /** Anthropic model id. Most roles run on Sonnet; cheap critics may run Haiku. */
  model: string;
  /** Max output tokens. Roles are deliberately tight to keep cost flat. */
  maxTokens: number;
  /** Short list of statutes / treaties / case names the role is expected
   *  to anchor every claim to. Embedded in the system prompt. */
  statuteShortlist: readonly string[];
  /** Concrete pitfalls — explicit "do not do X" anti-patterns. */
  knownPitfalls: readonly string[];
  /** Memory-file names (without path) whose body is auto-embedded if present. */
  memoryHooks?: readonly string[];
}

export interface DomainExpert extends BaseRole {
  kind: "domain";
  /** Predicate gating router selection. */
  applicableWhen: (ctx: CaseContext) => boolean;
  /** Builds the role's full system-prompt body (NO calibration / law context;
   *  the runner wraps these in). The string returned is appended to the
   *  base lawyer persona. */
  systemPromptFactory: (ctx: CaseContext, memoryBlobs: string) => string;
}

export interface StrategicPosition extends BaseRole {
  kind: "strategic";
  applicableWhen: (ctx: CaseContext) => boolean;
  systemPromptFactory: (ctx: CaseContext, memoryBlobs: string) => string;
}

export type RoleDef = DomainExpert | StrategicPosition;

/** Final compiled object the consilium runner consumes. Mirrors the legacy
 *  ConsiliumRole shape from consilium.ts so the rest of the pipeline doesn't
 *  need to change. */
export interface CompiledRole {
  id: string;
  name: string; // localised
  kind: "domain" | "strategic" | "legacy";
  model: string;
  maxTokens: number;
  /** Full system-prompt body (statute shortlist + pitfalls + memory + reasoning).
   *  Concatenated AFTER the chat-layer base lawyer persona by the runner. */
  systemBody: string;
}

/** Pick the best localised name.
 *
 *  Resolution order:
 *    1. Exact match for the requested language (after normalisation)
 *    2. English (`en`) — primary fallback
 *    3. Russian (`ru`) — last-resort legacy fallback
 *
 *  Previously this fell back directly to `ru` which forced Russian display
 *  names for every Finnish / Polish / Arabic / etc. user. The new order
 *  prefers English which every role is expected to populate over time;
 *  `ru` remains only because a handful of legacy roles still ship Russian-
 *  only display names. */
export function pickName(
  name: LocalisedName,
  lang: CaseContext["language"] | string | undefined,
): string {
  const normalised = normalizeLanguage(lang);
  const exact = name[normalised];
  if (typeof exact === "string" && exact.length > 0) return exact;
  if (typeof name.en === "string" && name.en.length > 0) return name.en;
  return name.ru;
}
