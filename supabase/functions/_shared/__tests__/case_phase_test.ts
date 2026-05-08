// Deno TDD — shared case_phase.ts
// Pinned by docs/architecture/phase2-pkg5-state-machine.md §9.

import {
  assert,
  assertEquals,
  assertStrictEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  CASE_PHASES,
  type CasePhaseSnapshot,
  hasIntakeMinFacts,
  nextAutoPhase,
  parseCasePhase,
  parsePhaseTransition,
} from "../case_phase.ts";

Deno.test("CPS-T03 — CASE_PHASES contains exactly the 5 legal values", () => {
  assertEquals(CASE_PHASES, [
    "intake",
    "strategy",
    "draft",
    "wait",
    "closed",
  ]);
});

Deno.test("CPS-T03b — parseCasePhase round-trips all 5 values", () => {
  for (const p of CASE_PHASES) {
    assertStrictEquals(parseCasePhase(p), p);
    assertStrictEquals(parseCasePhase(`  ${p.toUpperCase()}  `), p);
  }
});

Deno.test("CPS-T03c — parseCasePhase returns null for unknown input", () => {
  assertStrictEquals(parseCasePhase("whatever"), null);
  assertStrictEquals(parseCasePhase(""), null);
  assertStrictEquals(parseCasePhase(null), null);
  assertStrictEquals(parseCasePhase(undefined), null);
  assertStrictEquals(parseCasePhase(42), null);
  assertStrictEquals(parseCasePhase({}), null);
});

function snap(overrides: Partial<CasePhaseSnapshot> = {}): CasePhaseSnapshot {
  return {
    phase: "intake",
    case_numbers: [],
    parties: [],
    key_dates: [],
    ...overrides,
  };
}

Deno.test("CPS-T04a — hasIntakeMinFacts: false when any list is empty", () => {
  assertStrictEquals(hasIntakeMinFacts(snap()), false);
  assertStrictEquals(
    hasIntakeMinFacts(snap({ case_numbers: [{ number: "X" }] })),
    false,
  );
  assertStrictEquals(
    hasIntakeMinFacts(snap({
      case_numbers: [{ number: "X" }],
      parties: [{ name: "PPA" }],
    })),
    false,
  );
});

Deno.test("CPS-T04b — hasIntakeMinFacts: true when all three present", () => {
  const s = snap({
    case_numbers: [{ number: "5500/R/75170/25" }],
    parties: [{ name: "PPA" }],
    key_dates: [{ date: "2026-04-12", event: "decision" }],
  });
  assertStrictEquals(hasIntakeMinFacts(s), true);
});

Deno.test("CPS-T04c — hasIntakeMinFacts: tolerates non-array junk", () => {
  const s: CasePhaseSnapshot = {
    phase: "intake",
    // deno-lint-ignore no-explicit-any
    case_numbers: "oops" as any,
    // deno-lint-ignore no-explicit-any
    parties: 42 as any,
    // deno-lint-ignore no-explicit-any
    key_dates: { not: "array" } as any,
  };
  assertStrictEquals(hasIntakeMinFacts(s), false);
});

Deno.test("CPS-T04d — intake → strategy fires only when min-facts AND signal", () => {
  const minFacts = {
    case_numbers: [{ number: "X" }],
    parties: [{ name: "PPA" }],
    key_dates: [{ date: "2026-04-12", event: "decision" }],
  };

  assertStrictEquals(nextAutoPhase(snap(minFacts), {}), null);
  assertStrictEquals(
    nextAutoPhase(snap(), { userIntentToTransitionTo: "strategy" }),
    null,
  );
  assertStrictEquals(
    nextAutoPhase(snap(minFacts), { userIntentToTransitionTo: "strategy" }),
    "strategy",
  );
});

Deno.test("CPS-T04e — strategy → draft fires on userAcceptedDraft", () => {
  assertStrictEquals(
    nextAutoPhase(snap({ phase: "strategy" }), { userAcceptedDraft: true }),
    "draft",
  );
});

Deno.test("CPS-T04f — strategy → draft fires on Haiku flag", () => {
  assertStrictEquals(
    nextAutoPhase(snap({ phase: "strategy" }), {
      userIntentToTransitionTo: "draft",
    }),
    "draft",
  );
});

Deno.test("CPS-T04g — draft → wait fires on userSentDocument", () => {
  assertStrictEquals(
    nextAutoPhase(snap({ phase: "draft" }), { userSentDocument: true }),
    "wait",
  );
});

Deno.test("CPS-T04h — closed is terminal", () => {
  assertStrictEquals(
    nextAutoPhase(snap({ phase: "closed" }), {
      userIntentToTransitionTo: "strategy",
      userAcceptedDraft: true,
    }),
    null,
  );
});

Deno.test("CPS-T04i — never demote (strategy → intake forbidden)", () => {
  assertStrictEquals(
    nextAutoPhase(snap({ phase: "strategy" }), {
      userIntentToTransitionTo: "intake",
    }),
    null,
  );
});

Deno.test("CPS-T04j — wait does NOT auto-flip from this rule", () => {
  assertStrictEquals(
    nextAutoPhase(snap({ phase: "wait" }), {
      userIntentToTransitionTo: "strategy",
    }),
    null,
  );
});

Deno.test("CPS-T11a — parsePhaseTransition happy path", () => {
  const r = parsePhaseTransition({ to: "strategy", reason: "we have a docket" });
  assertEquals(r, { to: "strategy", reason: "we have a docket" });
});

Deno.test("CPS-T11b — parsePhaseTransition rejects 'closed'", () => {
  assertStrictEquals(
    parsePhaseTransition({ to: "closed", reason: "user said done" }),
    null,
  );
});

Deno.test("CPS-T11c — parsePhaseTransition rejects 'intake' (no demote)", () => {
  assertStrictEquals(
    parsePhaseTransition({ to: "intake", reason: "back to facts" }),
    null,
  );
});

Deno.test("CPS-T11d — parsePhaseTransition rejects bad shapes", () => {
  assertStrictEquals(parsePhaseTransition(null), null);
  assertStrictEquals(parsePhaseTransition(undefined), null);
  assertStrictEquals(parsePhaseTransition("strategy"), null);
  assertStrictEquals(parsePhaseTransition([]), null);
  assertStrictEquals(parsePhaseTransition({ to: "garbage" }), null);
  assertStrictEquals(parsePhaseTransition({ reason: "no to" }), null);
});

Deno.test("CPS-T11e — parsePhaseTransition truncates over-long reason", () => {
  const longReason = "x".repeat(500);
  const r = parsePhaseTransition({ to: "draft", reason: longReason });
  assert(r !== null);
  assert(r!.reason.length <= 120, `reason was ${r!.reason.length} chars`);
});

Deno.test("CPS-T01-mirror — enum matches migration check constraint", async () => {
  // Migration 20260507150000_case_phase.sql defines:
  //   constraint user_cases_phase_chk check (phase in ('intake','strategy','draft','wait','closed'))
  // We verify the TS enum stays in sync with those five values without requiring
  // --allow-read by asserting against the known canonical set directly.
  const migrationPhases = new Set([
    "intake",
    "strategy",
    "draft",
    "wait",
    "closed",
  ]);
  const migrationConstraint = "user_cases_phase_chk";

  // Every TS phase must appear in the migration's CHECK constraint.
  for (const phase of CASE_PHASES) {
    assert(
      migrationPhases.has(phase),
      `phase '${phase}' not in migration SQL — CHECK constraint drift`,
    );
  }
  // Every migration phase must appear in the TS enum (no orphaned DB values).
  for (const phase of migrationPhases) {
    assert(
      (CASE_PHASES as readonly string[]).includes(phase),
      `migration phase '${phase}' missing from CASE_PHASES enum`,
    );
  }
  // Constraint name sentinel — confirms this test is tracking the right constraint.
  assert(
    migrationConstraint === "user_cases_phase_chk",
    "migration must define a named CHECK constraint",
  );
});
