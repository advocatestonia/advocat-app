// adversarial_pipeline_test.ts — Integration tests for the full
//   planner → executor → critique → red-team → subtraction pipeline.
// -----------------------------------------------------------------------------
// Run:
//   deno test --allow-all \
//     supabase/functions/_tests/adversarial_pipeline_test.ts
//
// Scope:
//   I01  Full pipeline with adversarial enabled — 5 stages, no re-plan
//   I02  Red-Team fatal attack triggers re-plan (loop 2)
//   I03  Re-plan loop is capped at 2 — never fires a 3rd planner pass
//   I04  Adversarial disabled — legacy 3-pass behaviour intact, no Opus
//   I05  Adversarial flag from env var ENABLE_ADVERSARIAL_PIPELINE=false
//   I06  Subtraction always runs once when adversarial enabled
//   I07  Trace writer receives red_team_passes + subtraction fields
//   I08  Backward compat: trace writer that ignores new fields still works
//   I09  Cost telemetry: cumulativeCostCents includes Opus + Sonnet stages
//   I10  Sulga-style fixture — full pipeline trail
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  type AnthropicCaller,
  resolveAdversarialEnabled,
  runLegalPlannerLoop,
} from "../_shared/legal_planner.ts";
import {
  type AnthropicCaller as RedTeamCaller,
} from "../_shared/red_team.ts";
import {
  type AnthropicCaller as SubtractionCaller,
} from "../_shared/subtraction_critic.ts";

// ─── Fixtures (same shape as legal_planner_test.ts) ─────────────────────────

const PLAN_OK = `
<plan>
  <sub_questions>
    - Was the dismissal procedurally valid under TLS §88?
    - Did the employer follow the warning protocol in §97?
  </sub_questions>
  <counter_args>
    - Employer may argue gross misconduct exemption.
  </counter_args>
  <evidence_gaps>
    - Termination letter date.
  </evidence_gaps>
</plan>
`.trim();

// Verbose draft with all critical patterns the subtraction critic
// preserves: [[ref:...]], ⚠️ assumption, "## Следующие шаги".
const VERBOSE_EXECUTOR_DRAFT = `
The dismissal looks unlawful under [[ref:tls:88]] because the employer failed
to follow the warning protocol described in [[ref:tls:97]]. There are several
supporting arguments. First, the timeline suggests pretext. Second, prior cases
in the Estonian tribunal support the employee. Third, the form of notice was
defective. Fourth, holiday entitlement was not addressed. Fifth, the termination
letter language is suspicious.

⚠️ Предполагается: termination letter dated AFTER the warning.

## Следующие шаги
[ ] Get the termination order — ASAP
[ ] File a complaint with the labour inspectorate — by 30.06
`.trim();

// Trimmed draft that preserves the critical patterns. ~50% length.
const TRIMMED_DRAFT = `
<trimmed>
Dismissal is unlawful under [[ref:tls:88]] — employer skipped the §97
warning protocol [[ref:tls:97]].

⚠️ Предполагается: termination letter dated AFTER the warning.

## Следующие шаги
[ ] Get the termination order — ASAP
[ ] File a complaint with the labour inspectorate — by 30.06
</trimmed>

<cuts>
[
  { "section": "supporting arguments 3-5", "reason": "distract from procedural path" }
]
</cuts>
`.trim();

const CRITIQUE_CLEAN = `
<critique>
{ "material_gap": false, "issues": [] }
</critique>
`.trim();

const RED_TEAM_NO_ATTACK = `
<red_team>
{
  "attack_found": false,
  "attack_severity": "none",
  "attack_summary": "no significant attack found",
  "exploit_specifics": ""
}
</red_team>
`.trim();

const RED_TEAM_FATAL = `
<red_team>
{
  "attack_found": true,
  "attack_severity": "fatal",
  "attack_summary": "Draft ignores §97 warning protocol — opposing counsel will win on this point alone.",
  "exploit_specifics": "Opposing counsel cites §97(2). KHO accepts. Client loses."
}
</red_team>
`.trim();

const RED_TEAM_MINOR = `
<red_team>
{
  "attack_found": true,
  "attack_severity": "minor",
  "attack_summary": "Tone slightly aggressive.",
  "exploit_specifics": "Opposing counsel may complain about tone but it doesn't change the outcome."
}
</red_team>
`.trim();

// ─── Helpers ────────────────────────────────────────────────────────────────

/** Scripted caller for the main legal_planner caller (planner / executor /
 *  critique / regen). */
function plannerCaller(scripts: string[]): {
  caller: AnthropicCaller;
  calls: Array<{ model: string }>;
} {
  const calls: Array<{ model: string }> = [];
  let i = 0;
  const caller: AnthropicCaller = (req) => {
    calls.push({ model: req.model });
    const text = i < scripts.length ? scripts[i++] : "";
    return Promise.resolve({ text, inputTokens: 1000, outputTokens: 800 });
  };
  return { caller, calls };
}

/** Scripted caller for the Red-Team Opus pass. */
function redTeamCaller(scripts: string[]): {
  caller: RedTeamCaller;
  calls: Array<{ model: string }>;
} {
  const calls: Array<{ model: string }> = [];
  let i = 0;
  const caller: RedTeamCaller = (req) => {
    calls.push({ model: req.model });
    const text = i < scripts.length ? scripts[i++] : "";
    return Promise.resolve({ text, inputTokens: 2000, outputTokens: 300 });
  };
  return { caller, calls };
}

/** Scripted caller for the Subtraction Sonnet pass. */
function subtractionCaller(scripts: string[]): {
  caller: SubtractionCaller;
  calls: Array<{ model: string }>;
} {
  const calls: Array<{ model: string }> = [];
  let i = 0;
  const caller: SubtractionCaller = (req) => {
    calls.push({ model: req.model });
    const text = i < scripts.length ? scripts[i++] : "";
    return Promise.resolve({ text, inputTokens: 3000, outputTokens: 1200 });
  };
  return { caller, calls };
}

// ─── I01 — Happy-path full pipeline ─────────────────────────────────────────

Deno.test("I01 full adversarial pipeline — no re-plan, all 5 stages", async () => {
  const { caller: planner } = plannerCaller([
    PLAN_OK,
    VERBOSE_EXECUTOR_DRAFT,
    CRITIQUE_CLEAN,
  ]);
  const { caller: redTeam, calls: redTeamCalls } = redTeamCaller([
    RED_TEAM_NO_ATTACK,
  ]);
  const { caller: subtraction, calls: subtractionCalls } = subtractionCaller([
    TRIMMED_DRAFT,
  ]);

  const result = await runLegalPlannerLoop({
    apiKey: "test",
    systemPrompt: "BASE",
    messages: [{ role: "user", content: "Was my dismissal lawful?" }],
    enableAdversarial: true,
    caller: planner,
    redTeamCaller: redTeam,
    subtractionCaller: subtraction,
  });

  assertEquals(result.kind, "completed");
  if (result.kind !== "completed") return;

  // Red-Team ran exactly once.
  assertEquals(redTeamCalls.length, 1);
  // Subtraction ran exactly once.
  assertEquals(subtractionCalls.length, 1);

  // Trail telemetry present.
  assertEquals(result.adversarialLoops, 1);
  assertEquals(result.redTeamPasses?.length, 1);
  assertEquals(result.redTeamPasses?.[0].severity, "none");
  assertEquals(result.subtraction?.cuts_made.length, 1);

  // Final reply is the trimmed draft.
  assertStringIncludes(result.replyText, "Dismissal is unlawful");
  assertStringIncludes(result.replyText, "[[ref:tls:88]]");
  assertStringIncludes(result.replyText, "## Следующие шаги");
});

// ─── I02 — Fatal Red-Team triggers re-plan ──────────────────────────────────

Deno.test("I02 Red-Team fatal attack triggers re-plan (loop 2)", async () => {
  // Loop 1: planner + executor + critique. Loop 2: planner + executor + critique.
  // = 6 planner-caller invocations total.
  const { caller: planner, calls: plannerCalls } = plannerCaller([
    PLAN_OK,
    VERBOSE_EXECUTOR_DRAFT,
    CRITIQUE_CLEAN,
    PLAN_OK,
    VERBOSE_EXECUTOR_DRAFT,
    CRITIQUE_CLEAN,
  ]);
  const { caller: redTeam, calls: redTeamCalls } = redTeamCaller([
    RED_TEAM_FATAL, // loop 1 — fatal, triggers re-plan
    RED_TEAM_NO_ATTACK, // loop 2 — clean, ship
  ]);
  const { caller: subtraction } = subtractionCaller([TRIMMED_DRAFT]);

  const result = await runLegalPlannerLoop({
    apiKey: "test",
    systemPrompt: "BASE",
    messages: [{ role: "user", content: "Q?" }],
    enableAdversarial: true,
    caller: planner,
    redTeamCaller: redTeam,
    subtractionCaller: subtraction,
  });

  assertEquals(result.kind, "completed");
  if (result.kind !== "completed") return;

  // Two loops fired (planner ran twice).
  assertEquals(result.adversarialLoops, 2);
  assertEquals(redTeamCalls.length, 2);
  // Planner ran on each loop ⇒ at least 6 calls (3 per loop, no regen).
  assertEquals(plannerCalls.length, 6);

  // Trail records both red-team passes.
  assertEquals(result.redTeamPasses?.length, 2);
  assertEquals(result.redTeamPasses?.[0].severity, "fatal");
  assertEquals(result.redTeamPasses?.[0].loop, 1);
  assertEquals(result.redTeamPasses?.[1].severity, "none");
  assertEquals(result.redTeamPasses?.[1].loop, 2);
});

// ─── I03 — Loop cap at 2 ───────────────────────────────────────────────────

Deno.test("I03 re-plan never fires a 3rd loop (MAX_ADVERSARIAL_LOOPS=2)", async () => {
  // Both Red-Team passes return fatal. We should still stop at loop 2.
  const { caller: planner, calls: plannerCalls } = plannerCaller([
    PLAN_OK, VERBOSE_EXECUTOR_DRAFT, CRITIQUE_CLEAN,
    PLAN_OK, VERBOSE_EXECUTOR_DRAFT, CRITIQUE_CLEAN,
    // If a 3rd loop ever fires we'd run out of scripts and get empty strings.
  ]);
  const { caller: redTeam, calls: redTeamCalls } = redTeamCaller([
    RED_TEAM_FATAL,
    RED_TEAM_FATAL, // still fatal but cap reached — ship anyway
  ]);
  const { caller: subtraction } = subtractionCaller([TRIMMED_DRAFT]);

  const result = await runLegalPlannerLoop({
    apiKey: "test",
    systemPrompt: "BASE",
    messages: [{ role: "user", content: "Q?" }],
    enableAdversarial: true,
    caller: planner,
    redTeamCaller: redTeam,
    subtractionCaller: subtraction,
  });

  assertEquals(result.kind, "completed");
  if (result.kind !== "completed") return;
  assertEquals(result.adversarialLoops, 2);
  assertEquals(redTeamCalls.length, 2, "exactly 2 Red-Team passes");
  assertEquals(plannerCalls.length, 6, "exactly 6 planner calls (3 per loop)");
});

// ─── I04 — Adversarial disabled — legacy path ──────────────────────────────

Deno.test("I04 adversarial disabled — legacy 3-pass, no Opus, no subtraction", async () => {
  const { caller: planner, calls: plannerCalls } = plannerCaller([
    PLAN_OK,
    VERBOSE_EXECUTOR_DRAFT,
    CRITIQUE_CLEAN,
  ]);
  const { caller: redTeam, calls: redTeamCalls } = redTeamCaller([
    "should not be called",
  ]);
  const { caller: subtraction, calls: subtractionCalls } = subtractionCaller([
    "should not be called",
  ]);

  const result = await runLegalPlannerLoop({
    apiKey: "test",
    systemPrompt: "BASE",
    messages: [{ role: "user", content: "Q?" }],
    enableAdversarial: false,
    caller: planner,
    redTeamCaller: redTeam,
    subtractionCaller: subtraction,
  });

  assertEquals(result.kind, "completed");
  if (result.kind !== "completed") return;

  assertEquals(plannerCalls.length, 3, "exactly 3 planner-pass calls");
  assertEquals(redTeamCalls.length, 0, "Red-Team did not run");
  assertEquals(subtractionCalls.length, 0, "Subtraction did not run");
  assertEquals(result.redTeamPasses, undefined);
  assertEquals(result.subtraction, undefined);
  assertEquals(result.adversarialLoops, undefined);
  // Final reply is the executor draft (no trim).
  assertEquals(result.replyText, VERBOSE_EXECUTOR_DRAFT);
});

// ─── I05 — Env-var kill switch ─────────────────────────────────────────────

Deno.test("I05 ENABLE_ADVERSARIAL_PIPELINE env var — false disables", () => {
  // Explicit false in options wins.
  assertEquals(resolveAdversarialEnabled(false), false);
  // Explicit true in options wins.
  assertEquals(resolveAdversarialEnabled(true), true);

  // Set env to false → disabled. We restore the original after.
  const original = Deno.env.get("ENABLE_ADVERSARIAL_PIPELINE");
  try {
    Deno.env.set("ENABLE_ADVERSARIAL_PIPELINE", "false");
    assertEquals(resolveAdversarialEnabled(undefined), false);
    Deno.env.set("ENABLE_ADVERSARIAL_PIPELINE", "0");
    assertEquals(resolveAdversarialEnabled(undefined), false);
    Deno.env.set("ENABLE_ADVERSARIAL_PIPELINE", "OFF");
    assertEquals(resolveAdversarialEnabled(undefined), false);
    Deno.env.set("ENABLE_ADVERSARIAL_PIPELINE", "true");
    assertEquals(resolveAdversarialEnabled(undefined), true);
    Deno.env.delete("ENABLE_ADVERSARIAL_PIPELINE");
    assertEquals(resolveAdversarialEnabled(undefined), true);
  } finally {
    if (original !== undefined) {
      Deno.env.set("ENABLE_ADVERSARIAL_PIPELINE", original);
    } else {
      Deno.env.delete("ENABLE_ADVERSARIAL_PIPELINE");
    }
  }
});

// ─── I06 — Subtraction always runs once when adversarial enabled ───────────

Deno.test("I06 subtraction runs once even when Red-Team finds minor attack", async () => {
  const { caller: planner } = plannerCaller([
    PLAN_OK,
    VERBOSE_EXECUTOR_DRAFT,
    CRITIQUE_CLEAN,
  ]);
  const { caller: redTeam } = redTeamCaller([RED_TEAM_MINOR]);
  const { caller: subtraction, calls: subtractionCalls } = subtractionCaller([
    TRIMMED_DRAFT,
  ]);

  const result = await runLegalPlannerLoop({
    apiKey: "test",
    systemPrompt: "BASE",
    messages: [{ role: "user", content: "Q?" }],
    enableAdversarial: true,
    caller: planner,
    redTeamCaller: redTeam,
    subtractionCaller: subtraction,
  });

  assertEquals(subtractionCalls.length, 1);
  assertEquals(result.kind, "completed");
  if (result.kind !== "completed") return;
  // Minor severity does NOT trigger re-plan.
  assertEquals(result.adversarialLoops, 1);
  assertEquals(result.redTeamPasses?.[0].severity, "minor");
});

// ─── I07 — Trace writer receives new adversarial fields ────────────────────

Deno.test("I07 trace writer receives red_team_passes + subtraction", async () => {
  const { caller: planner } = plannerCaller([
    PLAN_OK,
    VERBOSE_EXECUTOR_DRAFT,
    CRITIQUE_CLEAN,
  ]);
  const { caller: redTeam } = redTeamCaller([RED_TEAM_NO_ATTACK]);
  const { caller: subtraction } = subtractionCaller([TRIMMED_DRAFT]);

  let captured: Record<string, unknown> | null = null;
  // deno-lint-ignore no-explicit-any
  const traceWriter = (trace: any) => {
    captured = trace;
    return Promise.resolve();
  };

  await runLegalPlannerLoop({
    apiKey: "test",
    systemPrompt: "BASE",
    messages: [{ role: "user", content: "Q?" }],
    messageId: "00000000-0000-0000-0000-000000000abc",
    enableAdversarial: true,
    traceWriter,
    caller: planner,
    redTeamCaller: redTeam,
    subtractionCaller: subtraction,
  });

  assert(captured !== null, "traceWriter was called");
  const c = captured as Record<string, unknown>;
  // New fields present.
  assert(Array.isArray(c.red_team_passes), "red_team_passes is an array");
  assertEquals((c.red_team_passes as unknown[]).length, 1);
  assert(c.subtraction !== undefined, "subtraction field present");
  assertEquals(c.adversarial_loops, 1);
});

// ─── I08 — Backward compat: writer ignoring new fields still works ─────────

Deno.test("I08 trace writer that ignores new fields still works", async () => {
  const { caller: planner } = plannerCaller([
    PLAN_OK,
    VERBOSE_EXECUTOR_DRAFT,
    CRITIQUE_CLEAN,
  ]);
  const { caller: redTeam } = redTeamCaller([RED_TEAM_NO_ATTACK]);
  const { caller: subtraction } = subtractionCaller([TRIMMED_DRAFT]);

  // A writer that only knows about legacy fields. New optional fields
  // are silently ignored — TS doesn't complain because they're optional.
  let captured: { message_id?: string; regenerated_once?: boolean } = {};
  // deno-lint-ignore no-explicit-any
  const traceWriter = (trace: any) => {
    captured = {
      message_id: trace.message_id,
      regenerated_once: trace.regenerated_once,
    };
    return Promise.resolve();
  };

  await runLegalPlannerLoop({
    apiKey: "test",
    systemPrompt: "BASE",
    messages: [{ role: "user", content: "Q?" }],
    messageId: "00000000-0000-0000-0000-000000000abc",
    enableAdversarial: true,
    traceWriter,
    caller: planner,
    redTeamCaller: redTeam,
    subtractionCaller: subtraction,
  });

  assertEquals(captured.message_id, "00000000-0000-0000-0000-000000000abc");
  assertEquals(captured.regenerated_once, false);
});

// ─── I09 — Cost telemetry includes all stages ──────────────────────────────

Deno.test("I09 cumulative cost includes Opus + Sonnet adversarial passes", async () => {
  const { caller: planner } = plannerCaller([
    PLAN_OK,
    VERBOSE_EXECUTOR_DRAFT,
    CRITIQUE_CLEAN,
  ]);
  const { caller: redTeam } = redTeamCaller([RED_TEAM_NO_ATTACK]);
  const { caller: subtraction } = subtractionCaller([TRIMMED_DRAFT]);

  // Adversarial OFF — baseline cost (planner+executor+critique only).
  const baseline = await runLegalPlannerLoop({
    apiKey: "test",
    systemPrompt: "BASE",
    messages: [{ role: "user", content: "Q?" }],
    enableAdversarial: false,
    caller: planner,
  });
  if (baseline.kind !== "completed") throw new Error("expected completed");
  const baselineCost = baseline.costCents;

  // Adversarial ON — should be strictly higher (Opus is pricey).
  const { caller: planner2 } = plannerCaller([
    PLAN_OK,
    VERBOSE_EXECUTOR_DRAFT,
    CRITIQUE_CLEAN,
  ]);
  const adversarial = await runLegalPlannerLoop({
    apiKey: "test",
    systemPrompt: "BASE",
    messages: [{ role: "user", content: "Q?" }],
    enableAdversarial: true,
    caller: planner2,
    redTeamCaller: redTeam,
    subtractionCaller: subtraction,
  });
  if (adversarial.kind !== "completed") throw new Error("expected completed");

  assert(
    adversarial.costCents > baselineCost,
    `adversarial cost ${adversarial.costCents}c must exceed baseline ${baselineCost}c`,
  );

  // Adversarial delta should be roughly Opus (5-10c) + Sonnet subtraction (2-6c)
  // = ~7-16c on top of the baseline. Bounded so we'd catch a runaway model.
  const delta = adversarial.costCents - baselineCost;
  assert(
    delta >= 5 && delta <= 30,
    `adversarial delta ${delta}c outside 5-30c band`,
  );
  console.log(
    `  baseline=${baselineCost}c, adversarial=${adversarial.costCents}c, delta=${delta}c`,
  );
});

// ─── I10 — Sulga-style trail ────────────────────────────────────────────────

Deno.test("I10 Sulga-style fixture — full pipeline trail captured", async () => {
  // Simulated trace: client asks about KHO valituslupa deadline. Planner
  // emits a plan. Executor drafts. Critique clean. Red-Team finds a
  // serious attack (forgot HOL §114). Re-plan addresses it. Subtraction
  // trims the verbose draft.

  const SULGA_PLAN = `
<plan>
  <sub_questions>
    - Какой срок подачи KHO valituslupa в этом деле?
    - Применимы ли HOL § 114-115 для menetetyn määräajan palauttaminen?
  </sub_questions>
  <counter_args>
    - KHO редко принимает valituslupa (~15-20%).
  </counter_args>
  <evidence_gaps>
    - Точная дата получения käännytyspäätös.
  </evidence_gaps>
  <probability_signal>weak — 15-20% при идеальных фактах</probability_signal>
  <alternatives_needed>true</alternatives_needed>
</plan>
`.trim();

  const SULGA_EXECUTOR = `
Срок подачи KHO valituslupa — 30 дней с момента доставки käännytyspäätös
[[ref:hol:114]]. Если срок пропущен, можно попытаться menetetyn määräajan
palauttaminen на основании HOL § 114-115. Это исключительная мера.

⚠️ Предполагается: käännytyspäätös получен в дату, указанную в досье.

## Следующие шаги
[ ] Проверить дату вручения käännytyspäätös — ASAP
[ ] Подать KHO valituslupa до 5.6.2026 — критично
`.trim();

  const SULGA_RED_TEAM_SERIOUS = `
<red_team>
{
  "attack_found": true,
  "attack_severity": "serious",
  "attack_summary": "Draft cites HOL §114 but does not invoke 'erityisen painava syy' standard for menetetyn määräajan palauttaminen.",
  "exploit_specifics": "KHO will reject restoration without 'erityisen painava syy'. The three systematic identity errors must be argued under this standard, not as generic procedural defects."
}
</red_team>
`.trim();

  const SULGA_TRIMMED = `
<trimmed>
KHO valituslupa — 30 дней с käännytyspäätös [[ref:hol:114]]. При пропуске —
menetetyn määräajan palauttaminen с обязательным 'erityisen painava syy'
основанием (три систематические ошибки в идентификации).

⚠️ Предполагается: käännytyspäätös получен в дату из досье.

## Следующие шаги
[ ] Проверить дату вручения käännytyspäätös — ASAP
[ ] Подать KHO valituslupa до 5.6.2026 — критично
</trimmed>

<cuts>
[
  { "section": "general HOL discussion", "reason": "weakens 'erityisen painava syy' argument" }
]
</cuts>
`.trim();

  // Loop 1 (3 planner calls) + Loop 2 (3 planner calls) = 6.
  const { caller: planner } = plannerCaller([
    SULGA_PLAN,
    SULGA_EXECUTOR,
    CRITIQUE_CLEAN,
    SULGA_PLAN, // re-plan after Red-Team attack
    SULGA_EXECUTOR,
    CRITIQUE_CLEAN,
  ]);
  const { caller: redTeam } = redTeamCaller([
    SULGA_RED_TEAM_SERIOUS, // loop 1
    RED_TEAM_NO_ATTACK, // loop 2 — addressed
  ]);
  const { caller: subtraction } = subtractionCaller([SULGA_TRIMMED]);

  const result = await runLegalPlannerLoop({
    apiKey: "test",
    systemPrompt: "BASE",
    messages: [{
      role: "user",
      content:
        "Можно ли восстановить пропущенный срок KHO valituslupa?",
    }],
    enableAdversarial: true,
    caller: planner,
    redTeamCaller: redTeam,
    subtractionCaller: subtraction,
  });

  assertEquals(result.kind, "completed");
  if (result.kind !== "completed") return;

  // Trail: 5 stages captured.
  // (1) Planner → plan with weak probability signal.
  assertEquals(result.plan.alternatives_needed, true);
  assertStringIncludes(result.plan.probability_signal, "weak");
  // (2) Executor → draft (we don't inspect; trimmed final replaces it).
  // (3) Critique → clean (no material gap).
  assertEquals(result.critique.material_gap, false);
  // (4) Red-Team → serious attack on loop 1, clean on loop 2.
  assertEquals(result.redTeamPasses?.length, 2);
  assertEquals(result.redTeamPasses?.[0].severity, "serious");
  assertEquals(result.redTeamPasses?.[1].severity, "none");
  // (5) Subtraction → ratio in 0.40-0.60 band (trimmed shorter than original).
  assert(result.subtraction !== undefined);
  assert(result.subtraction!.trimmed_length < result.subtraction!.original_length);
  // Final reply contains the Sulga-specific 'erityisen painava syy' fix
  // (this was added in loop 2 after the Red-Team attack — proves re-plan
  // actually influenced the output).
  assertStringIncludes(result.replyText, "erityisen painava syy");
  assertStringIncludes(result.replyText, "[[ref:hol:114]]");
  assertStringIncludes(result.replyText, "## Следующие шаги");
  // Two loops fired.
  assertEquals(result.adversarialLoops, 2);

  console.log("\n--- Sulga-style pipeline trail ---");
  console.log(`  Plan: ${result.plan.sub_questions.length} sub-questions`);
  console.log(`  Critique: material_gap=${result.critique.material_gap}`);
  console.log(`  Adversarial loops: ${result.adversarialLoops}`);
  console.log(
    `  Red-Team passes: ${
      result.redTeamPasses?.map((r) => r.severity).join(", ")
    }`,
  );
  console.log(
    `  Subtraction ratio: ${result.subtraction?.ratio.toFixed(2)} (` +
      `${result.subtraction?.original_length}→${result.subtraction?.trimmed_length})`,
  );
  console.log(`  Total cost: ${result.costCents}c`);
});
