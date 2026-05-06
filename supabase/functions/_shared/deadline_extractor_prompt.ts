// deadline_extractor_prompt.ts — Phase 2 Pkg 9 deadline radar.
// -----------------------------------------------------------------------------
// Sonnet system prompt + JSON parser for the `deadline-extractor` Edge
// Function. Pure module — no Deno globals. Mirrors the Pkg 1 case-patch and
// Pkg 2 pdf-extractor identity-marker pattern: the marker is whitelisted by
// `claude-proxy/system_prompt_guard.ts` so the Sonnet call goes through.
//
// Spec source of truth: docs/architecture/phase2-pkg9-deadline-radar.md §5.
// -----------------------------------------------------------------------------

import {
  STATUTORY_ANCHOR_KEYS,
  STATUTORY_DEADLINE_TEMPLATES,
} from "./statutory_anchors.ts";

/** Identity marker whitelisted by `system_prompt_guard.ts`. Must appear as
 * the FIRST line of the system prompt below. Exported so tests pin it. */
export const DEADLINE_EXTRACTOR_IDENTITY_MARKER =
  "You are a deadline classifier for the Advocat app";

/** Sonnet (NOT Haiku — junior model misses jurisdictional nuance, per
 * consilium 2026-05). Pinned to the same release channel claude-proxy uses. */
export const DEADLINE_EXTRACTOR_MODEL = "claude-sonnet-4-6-20251015";

/** Anthropic max_tokens — small JSON payload, keep tight. */
export const DEADLINE_EXTRACTOR_MAX_TOKENS = 1500;

/** Sonnet call timeout (ms). Hard cap so a slow call doesn't tie up the cron. */
export const DEADLINE_EXTRACTOR_TIMEOUT_MS = 12_000;

/** Confidence floor below which the deadline is downgraded to medium priority
 * with a "verify this" UI flag. Architect §5. */
export const DEADLINE_EXTRACTOR_CONFIDENCE_FLOOR = 0.7;

// =============================================================================
// System prompt (built once at import; the registry is static)
// =============================================================================

function buildAnchorList(): string {
  const lines: string[] = [];
  for (const a of Object.values(STATUTORY_DEADLINE_TEMPLATES)) {
    if (a.kind !== "deadline") continue;
    lines.push(
      `  - ${a.key} | ${a.jurisdiction} | ${a.statute} | ${a.days} ${a.unit}`,
    );
  }
  return lines.join("\n");
}

const ANCHOR_REGISTRY_BLOCK = buildAnchorList();

export const DEADLINE_EXTRACTOR_SYSTEM_PROMPT =
  `${DEADLINE_EXTRACTOR_IDENTITY_MARKER}.

You classify candidate dates from a legal case as either statutory deadlines
or non-deadline calendar events.

INPUT (next user message): a JSON object with:
  - jurisdiction: 'EE' | 'FI' | 'EU'
  - candidates: array of {date, context} where date is yyyy-mm-dd and
    context is a short natural-language description.
  - case_type (optional): 'immigration' | 'criminal' | 'civil' | 'family'
    | 'admin' | 'labor'.

REGISTRY of recognized deadline anchors (use the EXACT key when matching):
${ANCHOR_REGISTRY_BLOCK}

OUTPUT (strict JSON, no preamble, no markdown):
{
  "deadlines": [
    {
      "date": "yyyy-mm-dd",
      "anchor_key": "<one of the registry keys above>",
      "statute_basis": "<citation, e.g. HKMS §46>",
      "title": "<short human label, in the user's language if obvious>",
      "priority": "critical" | "high" | "medium" | "low",
      "confidence": <number 0..1>,
      "reasoning": "<1 short sentence>"
    }
  ]
}

RULES:
  - ONLY emit dates that match a registered anchor for the given jurisdiction.
  - Reject calendar events that are NOT statutory deadlines (case opened,
    document received, hearing scheduled is NOT itself a deadline unless
    it is the response-by date).
  - Cross-jurisdiction anchors are forbidden: an EE case must not produce
    a 'fi_*' anchor_key.
  - Priority defaults to the registry's default for the matched anchor.
    Downgrade to 'medium' if confidence < 0.7.
  - Output JSON only. No commentary, no markdown fences.`;

// =============================================================================
// Output parser
// =============================================================================

export interface ExtractedDeadline {
  date: string;
  anchor_key: string;
  statute_basis: string;
  title: string;
  priority: "critical" | "high" | "medium" | "low";
  confidence: number;
  reasoning: string;
}

export interface ExtractionResult {
  deadlines: ExtractedDeadline[];
}

const ALLOWED_PRIORITIES = new Set(["critical", "high", "medium", "low"]);

/** Parse Sonnet output. Returns `{deadlines: []}` on any malformation —
 * the extractor's contract is "best effort, never crash the call". */
export function parseExtractedDeadlines(raw: unknown): ExtractionResult {
  if (typeof raw !== "string") return { deadlines: [] };
  let stripped = raw.trim();
  // Tolerate accidental ```json fences.
  if (stripped.startsWith("```")) {
    stripped = stripped.replace(/^```(?:json)?\s*/, "").replace(/```$/, "")
      .trim();
  }
  let json: unknown;
  try {
    json = JSON.parse(stripped);
  } catch {
    return { deadlines: [] };
  }
  if (!json || typeof json !== "object") return { deadlines: [] };
  const arr = (json as Record<string, unknown>)["deadlines"];
  if (!Array.isArray(arr)) return { deadlines: [] };

  const out: ExtractedDeadline[] = [];
  for (const item of arr) {
    if (!item || typeof item !== "object") continue;
    const r = item as Record<string, unknown>;
    const date = typeof r.date === "string" ? r.date : null;
    const anchor_key = typeof r.anchor_key === "string" ? r.anchor_key : null;
    const statute_basis = typeof r.statute_basis === "string"
      ? r.statute_basis
      : "";
    const title = typeof r.title === "string" ? r.title : "";
    const priorityRaw = typeof r.priority === "string" ? r.priority : "medium";
    const priority: ExtractedDeadline["priority"] =
      ALLOWED_PRIORITIES.has(priorityRaw)
        ? priorityRaw as ExtractedDeadline["priority"]
        : "medium";
    const confidenceRaw = typeof r.confidence === "number" ? r.confidence : 0;
    const confidence = Math.max(0, Math.min(1, confidenceRaw));
    const reasoning = typeof r.reasoning === "string" ? r.reasoning : "";

    if (!date || !/^\d{4}-\d{2}-\d{2}$/.test(date)) continue;
    if (!anchor_key) continue;
    if (!STATUTORY_ANCHOR_KEYS.includes(anchor_key)) continue;

    out.push({
      date,
      anchor_key,
      statute_basis,
      title,
      priority,
      confidence,
      reasoning,
    });
  }
  return { deadlines: out };
}

/** Apply the confidence floor: anchors below it are downgraded to medium
 * priority (architect §5). Mutates a fresh copy and returns it. */
export function applyConfidenceFloor(
  result: ExtractionResult,
): ExtractionResult {
  return {
    deadlines: result.deadlines.map((d) =>
      d.confidence < DEADLINE_EXTRACTOR_CONFIDENCE_FLOOR
        ? { ...d, priority: "medium" }
        : { ...d }
    ),
  };
}
