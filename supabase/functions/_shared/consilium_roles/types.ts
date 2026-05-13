// consilium_roles/types.ts — shared role-type contracts for the v2.2 consilium.
// -----------------------------------------------------------------------------
// Two layers of roles power the new consilium:
//   • DomainExpert      — statute-specific (Ulkomaalaislaki, BGB, GDPR, …)
//   • StrategicPosition — reasoning patterns (decision-maker-risk, 23-test, …)
//
// Each role compiles to a single ConsiliumRole object consumed by the runner.
// -----------------------------------------------------------------------------

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
  /** UI language — used for role display names only. */
  language?: "ru" | "et" | "fi" | "en" | "de";
  /** Loose complexity score 1-10. > 6 unlocks the long-game / 23-test pair. */
  complexity?: number;
  /** Free-form keywords (lowercased) for routing nudges — e.g. "valituslupa". */
  keywords?: readonly string[];
  /** Whether a hard deadline drives the case. Forces deadline-strategist. */
  hasHardDeadline?: boolean;
  /** Whether opposing correspondence is in the case file. Forces silent-concession. */
  hasOpposingCorrespondence?: boolean;
}

/** Localised display name table. Falls back to the `ru` entry when missing. */
export type LocalisedName = {
  ru: string;
  et?: string;
  fi?: string;
  en?: string;
  de?: string;
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

/** Pick the best localised name. */
export function pickName(
  name: LocalisedName,
  lang: CaseContext["language"] | undefined,
): string {
  if (lang && name[lang]) return name[lang]!;
  return name.ru;
}
