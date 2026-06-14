// contract-compare/handler.ts — pure business logic for Contract Version Compare.
// -----------------------------------------------------------------------------
// Feature: the user (especially a B2B reviewer) receives a NEW REDLINE of a
// contract they already reviewed — a fresh lease / employment / services
// agreement edition — and cannot tell WHAT changed or whether the delta is
// dangerous. contract-review analyses ONE contract; this function diffs two
// versions (v1 -> v2) clause-by-clause and risk-classifies each change.
//
// DESIGN (mirrors contract-review/handler.ts):
//   - All logic here is pure + dependency-injected so __tests__ can fake the
//     planner, the DB document loader, the clock, and the uuid.
//   - The HTTP shim (index.ts) builds the real dependencies and serialises.
//   - We DO NOT touch contract-review/index.ts. We REUSE its shared prompt
//     vocabulary (_shared/contract_review/prompts_risks.ts severities) so the
//     two surfaces stay consistent — we don't re-implement the risk taxonomy.
//
// COST GUARD: two long contracts is the main token risk. We cap each side's
// text (MAX_CHARS_PER_SIDE) before it reaches the planner and instruct the
// model to anchor on clause headings, which keeps the diff structured and
// avoids token-blowup from full re-quoting.
//
// LIABILITY: same backstop posture as contract-review — the model FLAGS and
// EXPLAINS deltas; it never tells the user to "sign" / "don't sign". The
// directional label is the user-impact of the change, never an instruction.
// -----------------------------------------------------------------------------

import { wrapUntrusted } from "../_shared/untrusted_data.ts";

// ─── Tunables ───────────────────────────────────────────────────────────────

/** Max characters per contract side fed to the planner. Two long contracts is
 * the token-cost risk this feature carries; clamping each side bounds it. A
 * 60k-char contract is ~15k tokens; two sides + system prompt stays well under
 * the model context window and keeps a single compare affordable. */
export const MAX_CHARS_PER_SIDE = 60_000;

/** Lower bound — comparing near-empty text is almost always a parse failure
 * upstream (an un-OCR'd scan), not a real contract. Reject early with a clear
 * error rather than spending a planner call on garbage. */
export const MIN_CHARS_PER_SIDE = 40;

/** Allowlist of output languages. Kept in sync with contract-review's
 * SUPPORTED_OUTPUT_LANGUAGES; duplicated here (not imported) to avoid coupling
 * this function's request validation to the heavier prompts module. */
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

// ─── Public contracts ───────────────────────────────────────────────────────

/** Direction of a single change from the USER's perspective. Mirrors the
 * "severity" vocabulary contract-review uses but collapsed to the axis a
 * version-diff cares about: did this edit help or hurt the reader?
 *  - "favorable"  — the new wording is BETTER for the user.
 *  - "adverse"    — the new wording is WORSE / riskier for the user.
 *  - "neutral"    — no material shift in risk allocation. */
export type ChangeDirection = "favorable" | "adverse" | "neutral";

/** What kind of structural edit produced the change. */
export type ChangeKind = "added" | "removed" | "modified";

/** Severity scale shared with contract-review's risk taxonomy. Only relevant
 * for adverse/neutral changes; favorable wins carry "good". */
export type ChangeSeverity =
  | "critical"
  | "high"
  | "medium"
  | "low"
  | "info"
  | "good";

/** One clause-level delta between v1 and v2. */
export interface ContractChange {
  /** Short clause label / section heading the change lives under. */
  clause: string;
  kind: ChangeKind;
  direction: ChangeDirection;
  severity: ChangeSeverity;
  /** One-paragraph plain-language explanation of WHAT changed and why it
   *  matters. Never an instruction to sign / not sign. */
  explanation: string;
  /** Verbatim (short) quote from the OLD version, when applicable. */
  before_quote?: string;
  /** Verbatim (short) quote from the NEW version, when applicable. */
  after_quote?: string;
}

/** Structured result the planner returns. handler validates this shape
 * defensively before returning it to the client. */
export interface ContractCompareOutput {
  /** One-paragraph executive summary of the redline as a whole. */
  summary: string;
  /** Net direction of the redline overall. */
  overall_direction: ChangeDirection;
  changes: ContractChange[];
}

export interface ContractCompareRequest {
  output_language: string;
  /** Inline text of the two versions. Provide EITHER both *_text fields OR
   *  both *_document_id fields (resolved server-side from case_documents). */
  old_text?: string;
  new_text?: string;
  old_document_id?: string;
  new_document_id?: string;
  /** Optional jurisdiction tag carried into the prompt for law-aware
   *  flagging (e.g. "de", "ee", "fi"). */
  jurisdiction_hint?: string;
}

export interface ContractCompareSuccess {
  kind: "success";
  status: 200;
  body: {
    summary: string;
    overall_direction: ChangeDirection;
    /** Count of adverse changes — drives the headline risk badge in the UI. */
    adverse_count: number;
    /** Count of favorable changes. */
    favorable_count: number;
    changes: ContractChange[];
    /** True when either side was clamped to MAX_CHARS_PER_SIDE — the UI shows
     *  a "long contract — partial compare" note. */
    truncated: boolean;
  };
}

export interface ContractCompareFailure {
  kind: "failure";
  status: number;
  body: { error: string };
}

export type ContractCompareResult =
  | ContractCompareSuccess
  | ContractCompareFailure;

// ─── Injected dependencies ──────────────────────────────────────────────────

/** Minimal DB surface — resolve a document's parsed text by id, scoped to the
 * owner. Returns null when the row is missing or not owned by the user. */
export interface CompareDbClient {
  loadOwnedDocumentText(
    userId: string,
    documentId: string
  ): Promise<string | null>;
}

export interface ComparePlannerRequest {
  systemPrompt: string;
  userPrompt: string;
}

export type ComparePlannerCaller = (
  req: ComparePlannerRequest
) => Promise<ContractCompareOutput>;

export interface RunContractCompareDeps {
  userId: string;
  request: ContractCompareRequest;
  db: CompareDbClient;
  planner: ComparePlannerCaller;
}

// ─── Request validation ─────────────────────────────────────────────────────

export type ValidationResult =
  | { ok: true; value: ContractCompareRequest }
  | { ok: false; error: string };

/** Validate the raw JSON body. We accept inline text OR document ids for each
 * side, but require exactly one mode per side and that BOTH sides resolve to
 * the same mode-completeness (you can't compare a text against nothing). */
export function validateRequest(raw: unknown): ValidationResult {
  if (typeof raw !== "object" || raw === null) {
    return { ok: false, error: "Body must be a JSON object" };
  }
  const r = raw as Record<string, unknown>;

  const outputLanguage =
    typeof r.output_language === "string" ? r.output_language : "en";
  if (!SUPPORTED_OUTPUT_LANGUAGES.has(outputLanguage)) {
    return {
      ok: false,
      error: `Unsupported output_language: ${outputLanguage}`,
    };
  }

  const oldText = typeof r.old_text === "string" ? r.old_text : undefined;
  const newText = typeof r.new_text === "string" ? r.new_text : undefined;
  const oldDocId =
    typeof r.old_document_id === "string" ? r.old_document_id : undefined;
  const newDocId =
    typeof r.new_document_id === "string" ? r.new_document_id : undefined;

  const haveOld =
    (oldText !== undefined && oldText.length > 0) || oldDocId !== undefined;
  const haveNew =
    (newText !== undefined && newText.length > 0) || newDocId !== undefined;
  if (!haveOld || !haveNew) {
    return {
      ok: false,
      error:
        "Provide both an old and a new version (old_text/new_text or old_document_id/new_document_id)",
    };
  }

  const jurisdiction =
    typeof r.jurisdiction_hint === "string"
      ? r.jurisdiction_hint.slice(0, 16)
      : undefined;

  return {
    ok: true,
    value: {
      output_language: outputLanguage,
      old_text: oldText,
      new_text: newText,
      old_document_id: oldDocId,
      new_document_id: newDocId,
      jurisdiction_hint: jurisdiction,
    },
  };
}

// ─── Text resolution ────────────────────────────────────────────────────────

/** Resolve the two sides to concrete strings, preferring inline text and
 * falling back to a DB document lookup. Clamps each side to MAX_CHARS_PER_SIDE
 * and reports whether any clamping happened. */
export async function resolveSides(
  deps: RunContractCompareDeps
): Promise<
  | { ok: true; oldText: string; newText: string; truncated: boolean }
  | { ok: false; status: number; error: string }
> {
  const { userId, request, db } = deps;

  let oldText = request.old_text ?? "";
  let newText = request.new_text ?? "";

  if (oldText.length === 0 && request.old_document_id) {
    const loaded = await db.loadOwnedDocumentText(
      userId,
      request.old_document_id
    );
    if (loaded === null) {
      return { ok: false, status: 404, error: "Old document not found" };
    }
    oldText = loaded;
  }
  if (newText.length === 0 && request.new_document_id) {
    const loaded = await db.loadOwnedDocumentText(
      userId,
      request.new_document_id
    );
    if (loaded === null) {
      return { ok: false, status: 404, error: "New document not found" };
    }
    newText = loaded;
  }

  oldText = oldText.trim();
  newText = newText.trim();

  if (
    oldText.length < MIN_CHARS_PER_SIDE ||
    newText.length < MIN_CHARS_PER_SIDE
  ) {
    return {
      ok: false,
      status: 422,
      error:
        "Both versions must contain extractable contract text (the upload may be an un-OCR'd scan)",
    };
  }

  let truncated = false;
  if (oldText.length > MAX_CHARS_PER_SIDE) {
    oldText = oldText.slice(0, MAX_CHARS_PER_SIDE);
    truncated = true;
  }
  if (newText.length > MAX_CHARS_PER_SIDE) {
    newText = newText.slice(0, MAX_CHARS_PER_SIDE);
    truncated = true;
  }

  return { ok: true, oldText, newText, truncated };
}

// ─── Prompt assembly ────────────────────────────────────────────────────────

const SEVERITY_GUIDE = `Severities (reuse the contract-review taxonomy — do not invent new ones):
- "critical" — the change could nullify the contract, expose unbounded
  liability, or breach mandatory law against the reader.
- "high" — clearly disadvantageous; commercially or legally one-sided.
- "medium" — worth negotiating; not deal-breaking.
- "low" — minor downside.
- "info" — neutral observation; no material risk shift.
- "good" — the change actually PROTECTS the reader; highlight as a win.`;

/** Build the system prompt. Pure (no env reads) so tests pin the exact
 * string. The output-language and jurisdiction are injected by the caller. */
export function buildCompareSystemPrompt(opts: {
  outputLanguage: string;
  jurisdiction?: string;
}): string {
  const juris =
    opts.jurisdiction && opts.jurisdiction.length > 0
      ? `\nGoverning-law context to weigh: ${opts.jurisdiction.toUpperCase()}. ` +
        `Flag changes that conflict with that jurisdiction's mandatory law.`
      : "";

  return `You are Advocat AI, comparing two versions of the SAME contract for a
non-lawyer reader who must understand how the new redline changed their position.

You receive an OLD version and a NEW version. Produce a clause-level diff: for
each clause that was ADDED, REMOVED, or MODIFIED, classify the DIRECTION of the
change from the READER's perspective and assign a severity.

Direction (from the reader's point of view):
- "favorable" — the new wording is BETTER / safer for the reader.
- "adverse" — the new wording is WORSE / riskier for the reader.
- "neutral" — no material shift in who bears the risk.

${SEVERITY_GUIDE}

RULES:
- Anchor each change on its clause heading or section number; keep before/after
  quotes SHORT (one sentence max) to stay token-efficient.
- Ignore pure formatting, numbering, or whitespace edits — report only changes
  that affect MEANING, money, risk, obligations, or rights.
- NEVER instruct the reader to "sign" or "not sign". You FLAG and EXPLAIN; the
  direction label is the impact of the edit, not advice to act.
- Output the analysis in this language (ISO code): ${opts.outputLanguage}.${juris}

Return ONLY valid JSON (no prose, no code fences) matching exactly:
{
  "summary": "one paragraph overview of the redline",
  "overall_direction": "favorable" | "adverse" | "neutral",
  "changes": [
    {
      "clause": "short heading",
      "kind": "added" | "removed" | "modified",
      "direction": "favorable" | "adverse" | "neutral",
      "severity": "critical" | "high" | "medium" | "low" | "info" | "good",
      "explanation": "what changed and why it matters",
      "before_quote": "short old-version quote (omit for added)",
      "after_quote": "short new-version quote (omit for removed)"
    }
  ]
}`;
}

/** Build the user-turn payload. Both contract bodies are wrapped as untrusted
 * data so a prompt-injection string embedded in a contract cannot hijack the
 * comparison instructions. */
export function buildCompareUserPrompt(
  oldText: string,
  newText: string
): string {
  return [
    "Compare these two contract versions and return the JSON diff.",
    "",
    "=== OLD VERSION (v1) ===",
    wrapUntrusted("contract_v1", oldText),
    "",
    "=== NEW VERSION (v2) ===",
    wrapUntrusted("contract_v2", newText),
  ].join("\n");
}

// ─── Output validation ──────────────────────────────────────────────────────

const VALID_DIRECTIONS: ReadonlySet<string> = new Set([
  "favorable",
  "adverse",
  "neutral",
]);
const VALID_KINDS: ReadonlySet<string> = new Set([
  "added",
  "removed",
  "modified",
]);
const VALID_SEVERITIES: ReadonlySet<string> = new Set([
  "critical",
  "high",
  "medium",
  "low",
  "info",
  "good",
]);

/** Defensively normalise a raw planner object into a typed
 * ContractCompareOutput. Drops malformed changes rather than throwing so one
 * bad row never sinks the whole compare. Returns null only when the top-level
 * shape is unusable. */
export function normalizeCompareOutput(
  raw: unknown
): ContractCompareOutput | null {
  if (typeof raw !== "object" || raw === null) return null;
  const r = raw as Record<string, unknown>;

  const summary = typeof r.summary === "string" ? r.summary : "";
  const overall = VALID_DIRECTIONS.has(r.overall_direction as string)
    ? (r.overall_direction as ChangeDirection)
    : "neutral";

  const rawChanges = Array.isArray(r.changes) ? r.changes : [];
  const changes: ContractChange[] = [];
  for (const c of rawChanges) {
    if (typeof c !== "object" || c === null) continue;
    const o = c as Record<string, unknown>;
    const clause = typeof o.clause === "string" ? o.clause.trim() : "";
    const explanation =
      typeof o.explanation === "string" ? o.explanation.trim() : "";
    if (clause.length === 0 || explanation.length === 0) continue;
    const kind = VALID_KINDS.has(o.kind as string)
      ? (o.kind as ChangeKind)
      : "modified";
    const direction = VALID_DIRECTIONS.has(o.direction as string)
      ? (o.direction as ChangeDirection)
      : "neutral";
    const severity = VALID_SEVERITIES.has(o.severity as string)
      ? (o.severity as ChangeSeverity)
      : direction === "favorable"
      ? "good"
      : "info";
    const change: ContractChange = {
      clause,
      kind,
      direction,
      severity,
      explanation,
    };
    if (
      typeof o.before_quote === "string" &&
      o.before_quote.trim().length > 0
    ) {
      change.before_quote = o.before_quote.trim().slice(0, 600);
    }
    if (typeof o.after_quote === "string" && o.after_quote.trim().length > 0) {
      change.after_quote = o.after_quote.trim().slice(0, 600);
    }
    changes.push(change);
  }

  return { summary, overall_direction: overall, changes };
}

// ─── Orchestrator ───────────────────────────────────────────────────────────

export async function runContractCompare(
  deps: RunContractCompareDeps
): Promise<ContractCompareResult> {
  const resolved = await resolveSides(deps);
  if (!resolved.ok) {
    return {
      kind: "failure",
      status: resolved.status,
      body: { error: resolved.error },
    };
  }

  const systemPrompt = buildCompareSystemPrompt({
    outputLanguage: deps.request.output_language,
    jurisdiction: deps.request.jurisdiction_hint,
  });
  const userPrompt = buildCompareUserPrompt(resolved.oldText, resolved.newText);

  let output: ContractCompareOutput;
  try {
    output = await deps.planner({ systemPrompt, userPrompt });
  } catch (e) {
    return {
      kind: "failure",
      status: 502,
      body: { error: `Comparison failed: ${String(e).slice(0, 160)}` },
    };
  }

  const normalized = normalizeCompareOutput(output);
  if (normalized === null) {
    return {
      kind: "failure",
      status: 502,
      body: { error: "Comparison returned an unusable result" },
    };
  }

  let adverse = 0;
  let favorable = 0;
  for (const c of normalized.changes) {
    if (c.direction === "adverse") adverse++;
    else if (c.direction === "favorable") favorable++;
  }

  return {
    kind: "success",
    status: 200,
    body: {
      summary: normalized.summary,
      overall_direction: normalized.overall_direction,
      adverse_count: adverse,
      favorable_count: favorable,
      changes: normalized.changes,
      truncated: resolved.truncated,
    },
  };
}
