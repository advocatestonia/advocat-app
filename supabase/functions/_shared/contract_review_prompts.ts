// contract_review_prompts.ts — Composable prompt modules for the Contract
// Review feature. TypeScript port of `lib/services/contract_review_prompts.dart`
// (45 Dart tests pinned; 45 Deno tests in _tests/contract_review_prompts.test.ts).
// -----------------------------------------------------------------------------
// Internal product name: "Contract Review". Never the legacy three-letter
// commerce label in user-facing strings.
//
// DESIGN: every module is a small, pure builder returning a string fragment.
// `buildContractReviewPrompt()` (alias `buildContractReviewSystemPrompt`) is
// the orchestrator that stitches them together. Each module can be unit-
// tested in isolation and versioned independently via the
// `CONTRACT_REVIEW_PROMPT_VERSION` env var (mirrors the pattern in
// `email_agent_prompt.ts`).
//
// SIZE BUDGET: <= 30 KB per module, <= 120 KB total assembled (shares the
// 200 KB system-prompt cap with the rest of the platform).
//
// LIABILITY BACKSTOP (hard-coded in buildContractAnalysisCore):
//   - Forbidden verbs: "sign", "don't sign", "safe to sign", "you should sign".
//   - Allowed verbs: flag, suggest, recommend reviewing, propose alternative
//     wording.
//   - Localised disclaimer footer on every page.
//   - PDF cover always says "Advocat AI" — never a personal name.
//
// CONSUMER COMPATIBILITY: handler.ts imports `ContractReviewOutput`,
// `SUPPORTED_OUTPUT_LANGUAGES`, `buildContractReviewSystemPrompt`,
// `ContractJurisdictionHint`, `ContractIndustryHint`. All five remain
// exported here so the integration PR is import-stable.
// -----------------------------------------------------------------------------

import {
  kContractReviewPromptKnownVersions,
  kContractReviewPromptVersionDefault,
  pickContractReviewVersion,
} from "./contract_review/prompts_version.ts";
import {
  disclaimerFor,
  kContractReviewDisclaimers,
} from "./contract_review/prompts_disclaimers.ts";
import { buildJurisdictionContext } from "./contract_review/prompts_jurisdiction.ts";
import { buildRiskTaxonomy } from "./contract_review/prompts_risks.ts";
import { buildContractAnalysisCore } from "./contract_review/prompts_core.ts";
import { buildEmailDraftAddendum } from "./contract_review/prompts_email.ts";

// ─── Re-exports (public surface) ────────────────────────────────────────────

export {
  buildContractAnalysisCore,
  buildEmailDraftAddendum,
  buildJurisdictionContext,
  buildRiskTaxonomy,
  disclaimerFor,
  kContractReviewDisclaimers,
  kContractReviewPromptKnownVersions,
  kContractReviewPromptVersionDefault,
  pickContractReviewVersion,
};

// ─── Handler-facing types (preserved from the previous stub) ────────────────

/** Output shape the planner returns for a contract review run.
 *
 * Kept intentionally simple at the TypeScript layer: handler.ts validates
 * this shape defensively before persisting. The richer JSON schema documented
 * in [buildContractAnalysisCore] is the wire format the planner emits; the
 * edge function maps it into this interface. */
export interface ContractReviewOutput {
  cover: {
    contract_name: string;
    counterparty: string;
    client_role: string;
    jurisdiction: string;
    score: number; // 0..100; higher = lower risk
  };
  summary: string;
  translation?: string;
  checklist: Array<{
    clause: string;
    risk_level: "critical" | "high" | "medium" | "low" | "info";
    finding: string;
    recommendation: string;
    citation?: string;
  }>;
  email_to_counterparty: string;
}

/** Optional jurisdiction hint accepted by the legacy single-tag orchestrator
 * call shape. The richer [buildJurisdictionContext] accepts arrays. */
export type ContractJurisdictionHint =
  | "de"
  | "us"
  | "eu"
  | "uk"
  | "at"
  | "ch"
  | undefined;

/** Optional industry hint. Matches the Dart switch cases. */
export type ContractIndustryHint =
  | "dealer"
  | "saas"
  | "nda"
  | "employment"
  | "m&a"
  | "real_estate"
  | undefined;

/** Locked output language allowlist — keep in sync with product copy. */
export const SUPPORTED_OUTPUT_LANGUAGES: ReadonlySet<string> = new Set([
  "ru",
  "en",
  "et",
  "fi",
  "de",
  "uk",
  "lv",
  "lt",
  "sv",
  "no",
  "da",
  "fr",
  "es",
  "it",
  "pl",
]);

// ─── Orchestrator ───────────────────────────────────────────────────────────

/** Options accepted by [buildContractReviewPrompt] /
 * [buildContractReviewSystemPrompt]. Supports BOTH the Dart-faithful shape
 * (jurisdictions, industry, originalLanguage) AND the legacy stub shape
 * (jurisdictionHint, industryHint, clientName, clientCompany) so the
 * integration PR is import-stable. New code should prefer the Dart shape. */
export interface ContractReviewPromptOptions {
  /** ISO code for the user-facing report (et, fi, ru, en, de, ...). */
  outputLanguage: string;
  /** Jurisdiction tags (e.g. ["DE"], ["DE", "EU"]). Empty = generic toolkit. */
  jurisdictions?: string[];
  /** Optional industry add-on tag (dealer, saas, nda, employment, m&a, ...). */
  industry?: string;
  /** ISO code of the contract itself; drives the counterparty email language.
   * Defaults to [outputLanguage] when omitted. */
  originalLanguage?: string;
  /** Pin a specific prompt version; defaults to env-resolved. */
  version?: string;

  // --- Legacy stub keys (still honoured for handler.ts compatibility) -------
  /** @deprecated use [jurisdictions]. Single-tag hint is upcast to array. */
  jurisdictionHint?: ContractJurisdictionHint | string;
  /** @deprecated use [industry]. Identical semantics. */
  industryHint?: ContractIndustryHint | string;
  /** @deprecated no longer threaded into the prompt — name lives on the PDF
   * cover via the document parser. */
  clientName?: string;
  /** @deprecated no longer threaded into the prompt — see [clientName]. */
  clientCompany?: string;
}

/** Assembles the full Contract Review system prompt by concatenating the
 * individual modules in their canonical order. Each module is independently
 * testable; this function is just glue. */
export function buildContractReviewPrompt(
  opts: ContractReviewPromptOptions,
): string {
  // Resolve jurisdictions: prefer the Dart-style array; fall back to the
  // legacy single hint.
  const jurisdictions = (() => {
    if (opts.jurisdictions && opts.jurisdictions.length > 0) {
      return opts.jurisdictions;
    }
    const hint = opts.jurisdictionHint;
    if (typeof hint === "string" && hint.length > 0) return [hint];
    return [];
  })();

  // Industry: prefer Dart-style, fall back to legacy.
  const industry = (() => {
    if (typeof opts.industry === "string" && opts.industry.length > 0) {
      return opts.industry;
    }
    const hint = opts.industryHint;
    if (typeof hint === "string" && hint.length > 0) return hint;
    return undefined;
  })();

  // Original language: defaults to outputLanguage if not supplied (the email
  // still has a language to bind to even when the orchestrator doesn't know
  // the contract's source language).
  const originalLanguage = (() => {
    const raw = opts.originalLanguage;
    if (typeof raw === "string" && raw.trim().length > 0) return raw.trim();
    return opts.outputLanguage;
  })();

  const version = opts.version ?? pickContractReviewVersion();

  const parts: string[] = [
    "<meta>",
    "FEATURE: Contract Review",
    `CONTRACT_REVIEW_PROMPT_VERSION: ${version}`,
    "</meta>",
    "",
    buildJurisdictionContext(jurisdictions),
    "",
    buildRiskTaxonomy({ industry }),
    "",
    buildContractAnalysisCore(opts.outputLanguage),
    "",
    buildEmailDraftAddendum(originalLanguage),
  ];
  // Match Dart `writeln` semantics: trailing newline.
  return parts.join("\n") + "\n";
}

/** Alias preserved for handler.ts and the existing _tests/contract_review.test.ts
 * call site. Identical to [buildContractReviewPrompt]. */
export function buildContractReviewSystemPrompt(
  opts: ContractReviewPromptOptions,
): string {
  return buildContractReviewPrompt(opts);
}
