// Tests for estimate-case/estimator.ts — pure validation + output normalization.
//
// Focus areas (highest-trust feature): the normalizer must NEVER let a model
// surface false precision, negative/NaN figures, inverted bands, an undersized
// total, or an out-of-enum strength value.

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  buildUserPrompt,
  normalizeOutput,
  parseModelJson,
  STRENGTHS,
  validateInput,
} from "../estimate-case/estimator.ts";

// ─── validateInput ───────────────────────────────────────────────────────────

Deno.test("validateInput: rejects non-object body", () => {
  assertEquals(validateInput(null).ok, false);
  assertEquals(validateInput("nope").ok, false);
  assertEquals(validateInput(42).ok, false);
});

Deno.test("validateInput: requires case_type and jurisdiction", () => {
  assertEquals(validateInput({ jurisdiction: "EE" }).ok, false);
  assertEquals(validateInput({ case_type: "debt" }).ok, false);
  assertEquals(
    validateInput({ case_type: "  ", jurisdiction: "EE" }).ok,
    false
  );
});

Deno.test("validateInput: trims and accepts a minimal valid body", () => {
  const r = validateInput({ case_type: "  Debt claim ", jurisdiction: " EE " });
  assert(r.ok);
  if (r.ok) {
    assertEquals(r.value.caseType, "Debt claim");
    assertEquals(r.value.jurisdiction, "EE");
    assertEquals(r.value.disputeAmountEur, null);
    assertEquals(r.value.b2bMode, false);
  }
});

Deno.test("validateInput: parses numeric and string amounts", () => {
  const numeric = validateInput({
    case_type: "x",
    jurisdiction: "EE",
    dispute_amount_eur: 5000.7,
  });
  assert(numeric.ok);
  if (numeric.ok) assertEquals(numeric.value.disputeAmountEur, 5001);

  const stringy = validateInput({
    case_type: "x",
    jurisdiction: "EE",
    dispute_amount_eur: "€12,500",
  });
  assert(stringy.ok);
  if (stringy.ok) assertEquals(stringy.value.disputeAmountEur, 12500);
});

Deno.test("validateInput: rejects negative or absurd amounts", () => {
  assertEquals(
    validateInput({
      case_type: "x",
      jurisdiction: "EE",
      dispute_amount_eur: -1,
    }).ok,
    false
  );
  assertEquals(
    validateInput({
      case_type: "x",
      jurisdiction: "EE",
      dispute_amount_eur: 9e12,
    }).ok,
    false
  );
});

Deno.test("validateInput: empty-string amount treated as non-monetary", () => {
  const r = validateInput({
    case_type: "x",
    jurisdiction: "EE",
    dispute_amount_eur: "",
  });
  assert(r.ok);
  if (r.ok) assertEquals(r.value.disputeAmountEur, null);
});

Deno.test("validateInput: caps description length", () => {
  const long = "a".repeat(9000);
  const r = validateInput({
    case_type: "x",
    jurisdiction: "EE",
    description: long,
  });
  assert(r.ok);
  if (r.ok) assertEquals(r.value.description.length, 4000);
});

Deno.test("validateInput: b2b_mode only true on strict boolean true", () => {
  const truthy = validateInput({
    case_type: "x",
    jurisdiction: "EE",
    b2b_mode: 1,
  });
  assert(truthy.ok);
  if (truthy.ok) assertEquals(truthy.value.b2bMode, false);

  const real = validateInput({
    case_type: "x",
    jurisdiction: "EE",
    b2b_mode: true,
  });
  assert(real.ok);
  if (real.ok) assertEquals(real.value.b2bMode, true);
});

// ─── buildUserPrompt ─────────────────────────────────────────────────────────

Deno.test(
  "buildUserPrompt: includes core fields and non-monetary marker",
  () => {
    const prompt = buildUserPrompt({
      caseType: "Employment dismissal",
      jurisdiction: "FI",
      disputeAmountEur: null,
      description: "Fired without notice",
      b2bMode: false,
    });
    assert(prompt.includes("Employment dismissal"));
    assert(prompt.includes("FI"));
    assert(prompt.includes("not monetary"));
    assert(prompt.includes("Fired without notice"));
  }
);

Deno.test(
  "buildUserPrompt: formats amount and adds B2B note when enabled",
  () => {
    const prompt = buildUserPrompt({
      caseType: "Debt",
      jurisdiction: "EE",
      disputeAmountEur: 25000,
      description: "",
      b2bMode: true,
    });
    assert(prompt.includes("€25,000"));
    assert(prompt.includes("B2B lead qualification"));
  }
);

// ─── normalizeOutput ─────────────────────────────────────────────────────────

Deno.test("normalizeOutput: throws on non-object", () => {
  let threw = false;
  try {
    normalizeOutput("not json");
  } catch {
    threw = true;
  }
  assert(threw);
});

Deno.test("normalizeOutput: orders inverted bands (high >= low)", () => {
  const e = normalizeOutput({
    court_fee_low_eur: 800,
    court_fee_high_eur: 300, // inverted
    lawyer_fee_low_eur: 2000,
    lawyer_fee_high_eur: 1000, // inverted
    duration_low_months: 12,
    duration_high_months: 4, // inverted
    strength: "contested",
  });
  assertEquals(e.courtFee, { low: 300, high: 800 });
  assertEquals(e.lawyerFee, { low: 1000, high: 2000 });
  assertEquals(e.durationMonths, { low: 4, high: 12 });
});

Deno.test("normalizeOutput: clamps negatives and NaN to 0", () => {
  const e = normalizeOutput({
    court_fee_low_eur: -50,
    court_fee_high_eur: "abc",
    lawyer_fee_low_eur: NaN,
    lawyer_fee_high_eur: 500,
    duration_low_months: -3,
    duration_high_months: 6,
  });
  assertEquals(e.courtFee, { low: 0, high: 0 });
  assertEquals(e.lawyerFee, { low: 0, high: 500 });
  assertEquals(e.durationMonths, { low: 0, high: 6 });
});

Deno.test("normalizeOutput: total never undersells component sum", () => {
  // Model lowballs total below the obvious court+lawyer sum.
  const e = normalizeOutput({
    court_fee_low_eur: 500,
    court_fee_high_eur: 1000,
    lawyer_fee_low_eur: 2000,
    lawyer_fee_high_eur: 4000,
    total_low_eur: 100, // far too low
    total_high_eur: 200, // far too low
  });
  assertEquals(e.total.low, 2500); // 500 + 2000
  assertEquals(e.total.high, 5000); // 1000 + 4000
});

Deno.test(
  "normalizeOutput: keeps model total when it exceeds component sum",
  () => {
    // e.g. model adds expert-witness / disbursement costs into the total.
    const e = normalizeOutput({
      court_fee_low_eur: 500,
      court_fee_high_eur: 1000,
      lawyer_fee_low_eur: 2000,
      lawyer_fee_high_eur: 4000,
      total_low_eur: 3000,
      total_high_eur: 8000,
    });
    assertEquals(e.total.low, 3000);
    assertEquals(e.total.high, 8000);
  }
);

Deno.test("normalizeOutput: coerces invalid strength to contested", () => {
  assertEquals(
    normalizeOutput({ strength: "definitely_winning" }).strength,
    "contested"
  );
  assertEquals(normalizeOutput({ strength: 95 }).strength, "contested");
  assertEquals(normalizeOutput({}).strength, "contested");
  for (const s of STRENGTHS) {
    assertEquals(normalizeOutput({ strength: s }).strength, s);
  }
});

Deno.test("normalizeOutput: factors filtered, trimmed, capped at 6", () => {
  const e = normalizeOutput({
    factors_for: [
      "  written contract ",
      "",
      42,
      "witness",
      "a",
      "b",
      "c",
      "d",
      "e",
    ],
    factors_against: "not an array",
  });
  assertEquals(e.factorsFor[0], "written contract");
  assert(e.factorsFor.length <= 6);
  assert(!e.factorsFor.includes(""));
  assertEquals(e.factorsAgainst, []);
});

Deno.test("normalizeOutput: clamps cost/duration ceilings", () => {
  const e = normalizeOutput({
    court_fee_low_eur: 0,
    court_fee_high_eur: 99_000_000, // above €10M ceiling
    duration_low_months: 0,
    duration_high_months: 1000, // above 240mo ceiling
  });
  assertEquals(e.courtFee.high, 10_000_000);
  assertEquals(e.durationMonths.high, 240);
});

Deno.test("normalizeOutput: truncates long recommendation / next_step", () => {
  const e = normalizeOutput({
    recommendation: "x".repeat(1000),
    next_step: "y".repeat(1000),
  });
  assertEquals(e.recommendation.length, 600);
  assertEquals(e.nextStep.length, 300);
});

// ─── parseModelJson ──────────────────────────────────────────────────────────

Deno.test("parseModelJson: strips code fences", () => {
  const parsed = parseModelJson('```json\n{"strength":"weak"}\n```') as {
    strength: string;
  };
  assertEquals(parsed.strength, "weak");
});

Deno.test("parseModelJson: parses bare JSON", () => {
  const parsed = parseModelJson('{"a":1}') as { a: number };
  assertEquals(parsed.a, 1);
});
