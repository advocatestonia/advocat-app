// estimate-case / estimator.ts
// -----------------------------------------------------------------------------
// Pure, side-effect-free logic for the Case Cost & Risk Estimator.
//
// Kept separate from index.ts so it is trivially unit-testable without a
// network or Supabase. Nothing here touches Deno.env, fetch, or the DB.
//
// Trust note (highest-risk feature): we deliberately model the output as
// *bands* (low/high), never a single point, and a coarse 3-state strength
// traffic-light — NEVER a "% chance of winning". The validation below clamps
// and normalizes anything the model returns so the UI cannot surface a false
// precision or an out-of-range probability dressed up as a guarantee.
// -----------------------------------------------------------------------------

/** Coarse strength signal. Never a probability. */
export type Strength = "worth_pursuing" | "contested" | "weak";

export const STRENGTHS: readonly Strength[] = [
  "worth_pursuing",
  "contested",
  "weak",
];

export interface EstimateInput {
  caseType: string;
  jurisdiction: string;
  /** EUR amount in dispute, or null for non-monetary matters. */
  disputeAmountEur: number | null;
  description: string;
  /** B2B lead-qualification mode → compact card output. */
  b2bMode: boolean;
}

/** A low/high integer band. high is always >= low after normalization. */
export interface Band {
  low: number;
  high: number;
}

export interface CaseEstimate {
  courtFee: Band;
  lawyerFee: Band;
  total: Band;
  durationMonths: Band;
  strength: Strength;
  factorsFor: string[];
  factorsAgainst: string[];
  recommendation: string;
  nextStep: string;
}

// ─── Input validation ────────────────────────────────────────────────────────

export interface ValidationOk {
  ok: true;
  value: EstimateInput;
}
export interface ValidationErr {
  ok: false;
  error: string;
}

const MAX_DESCRIPTION = 4000;
const MAX_AMOUNT = 1_000_000_000; // €1B sanity ceiling

/**
 * Validate and normalize the raw request body. Never throws — returns a
 * tagged result so the caller can map to a 400.
 */
export function validateInput(body: unknown): ValidationOk | ValidationErr {
  if (body === null || typeof body !== "object") {
    return { ok: false, error: "Body must be a JSON object" };
  }
  const b = body as Record<string, unknown>;

  const caseType = typeof b.case_type === "string" ? b.case_type.trim() : "";
  if (caseType.length === 0) {
    return { ok: false, error: "case_type is required" };
  }
  if (caseType.length > 120) {
    return { ok: false, error: "case_type too long" };
  }

  const jurisdiction =
    typeof b.jurisdiction === "string" ? b.jurisdiction.trim() : "";
  if (jurisdiction.length === 0) {
    return { ok: false, error: "jurisdiction is required" };
  }
  if (jurisdiction.length > 60) {
    return { ok: false, error: "jurisdiction too long" };
  }

  let disputeAmountEur: number | null = null;
  const rawAmount = b.dispute_amount_eur;
  if (rawAmount !== null && rawAmount !== undefined && rawAmount !== "") {
    const n =
      typeof rawAmount === "number"
        ? rawAmount
        : Number(String(rawAmount).replace(/[^\d.]/g, ""));
    if (!Number.isFinite(n) || n < 0) {
      return {
        ok: false,
        error: "dispute_amount_eur must be a positive number",
      };
    }
    if (n > MAX_AMOUNT) {
      return { ok: false, error: "dispute_amount_eur out of range" };
    }
    disputeAmountEur = Math.round(n);
  }

  const description =
    typeof b.description === "string"
      ? b.description.trim().slice(0, MAX_DESCRIPTION)
      : "";

  const b2bMode = b.b2b_mode === true;

  return {
    ok: true,
    value: { caseType, jurisdiction, disputeAmountEur, description, b2bMode },
  };
}

// ─── Prompt construction ─────────────────────────────────────────────────────

export const ESTIMATOR_SYSTEM_PROMPT =
  `You are a cautious legal-cost analyst for Estonian and Finnish (and broader EU) civil/administrative matters. ` +
  `You produce a ROUGH ORDER-OF-MAGNITUDE estimate to help a lay person decide whether a dispute is worth pursuing. ` +
  `\n\nHARD RULES:\n` +
  `- You are NOT giving legal advice and NOT predicting the outcome. Every figure is a broad RANGE, never a single number.\n` +
  `- NEVER output a probability or "% chance of winning". The only strength signal allowed is the enum below.\n` +
  `- Court fees: reason from the dispute amount and the jurisdiction's statutory fee schedule when known; if unknown, give a wide band.\n` +
  `- Lawyer fees: reflect typical market hourly rates × realistic hours for the matter type; give a wide band.\n` +
  `- Duration: realistic calendar months to a first-instance resolution.\n` +
  `- factors_for / factors_against: 2-4 short, concrete bullet phrases each (the things that actually move the outcome), no legalese.\n` +
  `- recommendation + next_step: one neutral sentence each. next_step should be an action the user can take now.\n` +
  `\nOUTPUT: a single JSON object, no markdown, no code fences, exactly these keys:\n` +
  `{\n` +
  `  "court_fee_low_eur": int, "court_fee_high_eur": int,\n` +
  `  "lawyer_fee_low_eur": int, "lawyer_fee_high_eur": int,\n` +
  `  "total_low_eur": int, "total_high_eur": int,\n` +
  `  "duration_low_months": int, "duration_high_months": int,\n` +
  `  "strength": "worth_pursuing" | "contested" | "weak",\n` +
  `  "factors_for": string[], "factors_against": string[],\n` +
  `  "recommendation": string, "next_step": string\n` +
  `}`;

/** Build the user-message content for the model from a validated input. */
export function buildUserPrompt(input: EstimateInput): string {
  const lines: string[] = [];
  lines.push(`Case type: ${input.caseType}`);
  lines.push(`Jurisdiction: ${input.jurisdiction}`);
  lines.push(
    input.disputeAmountEur === null
      ? `Amount in dispute: not monetary / unspecified`
      : `Amount in dispute: €${input.disputeAmountEur.toLocaleString("en-US")}`
  );
  if (input.description.length > 0) {
    lines.push(`Situation described by the user:\n${input.description}`);
  }
  if (input.b2bMode) {
    lines.push(
      `\nMode: B2B lead qualification. Keep factors crisp; the reader is a ` +
        `law firm triaging an inbound lead, not the claimant.`
    );
  }
  lines.push(`\nReturn ONLY the JSON object described in the system prompt.`);
  return lines.join("\n");
}

// ─── Output normalization ────────────────────────────────────────────────────

function toInt(v: unknown, fallback: number): number {
  const n = typeof v === "number" ? v : Number(v);
  if (!Number.isFinite(n)) return fallback;
  return Math.max(0, Math.round(n));
}

/** Order a band so high >= low, and clamp to a sane ceiling. */
function normBand(low: unknown, high: unknown, ceiling: number): Band {
  let lo = Math.min(toInt(low, 0), ceiling);
  let hi = Math.min(toInt(high, 0), ceiling);
  if (hi < lo) [lo, hi] = [hi, lo];
  return { low: lo, high: hi };
}

function coerceStrength(v: unknown): Strength {
  return STRENGTHS.includes(v as Strength) ? (v as Strength) : "contested";
}

function coerceFactors(v: unknown): string[] {
  if (!Array.isArray(v)) return [];
  return v
    .filter((x): x is string => typeof x === "string")
    .map((s) => s.trim())
    .filter((s) => s.length > 0)
    .slice(0, 6);
}

const COST_CEILING = 10_000_000; // €10M per band line
const DURATION_CEILING = 240; // 20 years in months

/**
 * Parse + clamp the model's raw JSON into a safe CaseEstimate. Tolerates
 * missing/garbage fields by falling back to neutral defaults so the UI never
 * sees NaN, negatives, or inverted bands. Throws only if `raw` is not an
 * object at all.
 */
export function normalizeOutput(raw: unknown): CaseEstimate {
  if (raw === null || typeof raw !== "object") {
    throw new Error("model output is not an object");
  }
  const r = raw as Record<string, unknown>;

  const courtFee = normBand(
    r.court_fee_low_eur,
    r.court_fee_high_eur,
    COST_CEILING
  );
  const lawyerFee = normBand(
    r.lawyer_fee_low_eur,
    r.lawyer_fee_high_eur,
    COST_CEILING
  );

  // Derive total from the model, but never let it fall below the sum of the
  // component bands (a model that lowballs "total" would understate cost,
  // which is the dangerous direction for a trust-sensitive estimate).
  let total = normBand(r.total_low_eur, r.total_high_eur, COST_CEILING);
  const componentLow = courtFee.low + lawyerFee.low;
  const componentHigh = courtFee.high + lawyerFee.high;
  total = {
    low: Math.max(total.low, componentLow),
    high: Math.max(total.high, componentHigh, total.low, componentLow),
  };

  const durationMonths = normBand(
    r.duration_low_months,
    r.duration_high_months,
    DURATION_CEILING
  );

  return {
    courtFee,
    lawyerFee,
    total,
    durationMonths,
    strength: coerceStrength(r.strength),
    factorsFor: coerceFactors(r.factors_for),
    factorsAgainst: coerceFactors(r.factors_against),
    recommendation:
      typeof r.recommendation === "string"
        ? r.recommendation.trim().slice(0, 600)
        : "",
    nextStep:
      typeof r.next_step === "string" ? r.next_step.trim().slice(0, 300) : "",
  };
}

/**
 * Strip a code-fence wrapper the model may emit despite instructions, then
 * JSON.parse. Returns the parsed value (caller passes to normalizeOutput).
 */
export function parseModelJson(text: string): unknown {
  const stripped = text
    .replace(/^\s*```(?:json)?\s*/i, "")
    .replace(/\s*```\s*$/i, "")
    .trim();
  return JSON.parse(stripped);
}
