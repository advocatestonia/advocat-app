// Deno TDD — Phase 2 Pkg 6 three-pass orchestrator (_shared/legal_planner.ts).
// -----------------------------------------------------------------------------
// Pure-module contract tests. The Anthropic caller is injected via the
// AnthropicCaller seam so every pass can be scripted deterministically
// without a network round-trip.
//
// Run with:
//   deno test --allow-net=api.anthropic.com \
//     supabase/functions/_shared/__tests__/legal_planner_test.ts
//
// (--allow-net is required because the module top-level imports `fetch`
// even though the tests don't exercise it.)
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  type AnthropicCaller,
  buildExecutorSystem,
  CRITIQUE_MAX_TOKENS,
  CRITIQUE_TEMPERATURE,
  EXECUTOR_MAX_TOKENS,
  EXECUTOR_TEMPERATURE,
  parseCritiqueOutput,
  parsePlannerOutput,
  PLANNER_MAX_TOKENS,
  PLANNER_TEMPERATURE,
  runLegalPlannerLoop,
} from "../legal_planner.ts";

// ─── Fixtures ───────────────────────────────────────────────────────────────

const SAMPLE_PLAN_XML = `
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
    - Last warning notice copy.
  </evidence_gaps>
</plan>
`.trim();

const SAMPLE_EXECUTOR = `
The dismissal looks unlawful under [[ref:tls:88]] because... [[ref:tls:97]].
`.trim();

const SAMPLE_CRITIQUE_GAP = `
<critique>
{
  "material_gap": true,
  "issues": [
    "sub-question on §97 warning protocol unanswered",
    "no marker for the §88 grace period claim"
  ]
}
</critique>
`.trim();

const SAMPLE_CRITIQUE_OK = `
<critique>
{
  "material_gap": false,
  "issues": []
}
</critique>
`.trim();

/** Build a deterministic caller that returns canned strings in pass order. */
function scriptedCaller(scripts: string[]): {
  caller: AnthropicCaller;
  calls: Array<{
    model: string;
    maxTokens: number;
    temperature: number;
    systemPrompt: string;
  }>;
} {
  const calls: Array<{
    model: string;
    maxTokens: number;
    temperature: number;
    systemPrompt: string;
  }> = [];
  let i = 0;
  const caller: AnthropicCaller = (req) => {
    calls.push({
      model: req.model,
      maxTokens: req.maxTokens,
      temperature: req.temperature,
      systemPrompt: req.systemPrompt,
    });
    const text = i < scripts.length ? scripts[i++] : "";
    return Promise.resolve({ text, inputTokens: 100, outputTokens: 50 });
  };
  return { caller, calls };
}

// ─── Parser tests ───────────────────────────────────────────────────────────

Deno.test("parsePlannerOutput — extracts bullets from XML-shaped plan", () => {
  const plan = parsePlannerOutput(SAMPLE_PLAN_XML);
  assertEquals(plan.sub_questions.length, 2);
  assertStringIncludes(plan.sub_questions[0], "TLS §88");
  assertEquals(plan.counter_args.length, 1);
  assertEquals(plan.evidence_gaps.length, 2);
  assert(plan.raw.length > 0);
});

Deno.test("parsePlannerOutput — tolerates missing tags", () => {
  const plan = parsePlannerOutput("<plan><sub_questions>- only one</sub_questions></plan>");
  assertEquals(plan.sub_questions, ["only one"]);
  assertEquals(plan.counter_args, []);
  assertEquals(plan.evidence_gaps, []);
});

Deno.test("parsePlannerOutput — drops (none) sentinel and empty bullets", () => {
  const plan = parsePlannerOutput(`
    <plan>
      <sub_questions>
        - (none)
      </sub_questions>
    </plan>
  `);
  assertEquals(plan.sub_questions, []);
});

Deno.test("parseCritiqueOutput — material_gap=true round-trips", () => {
  const c = parseCritiqueOutput(SAMPLE_CRITIQUE_GAP);
  assertEquals(c.material_gap, true);
  assertEquals(c.issues.length, 2);
});

Deno.test("parseCritiqueOutput — material_gap=false round-trips", () => {
  const c = parseCritiqueOutput(SAMPLE_CRITIQUE_OK);
  assertEquals(c.material_gap, false);
  assertEquals(c.issues.length, 0);
});

Deno.test("parseCritiqueOutput — heuristic fallback when JSON broken", () => {
  const c = parseCritiqueOutput(
    "<critique>not json but says material_gap: true here</critique>",
  );
  assertEquals(c.material_gap, true);
  assert(c.issues.length >= 1);
});

// ─── Executor system builder ────────────────────────────────────────────────

Deno.test("buildExecutorSystem — folds plan into base prompt", () => {
  const plan = parsePlannerOutput(SAMPLE_PLAN_XML);
  const out = buildExecutorSystem("BASE_PROMPT", plan, null);
  assertStringIncludes(out, "BASE_PROMPT");
  assertStringIncludes(out, "<plan>");
  assertStringIncludes(out, "TLS §88");
  // No critique block on the first pass.
  assert(!out.includes("<critique_for_regen>"));
});

Deno.test("buildExecutorSystem — appends critique block on regen", () => {
  const plan = parsePlannerOutput(SAMPLE_PLAN_XML);
  const critique = parseCritiqueOutput(SAMPLE_CRITIQUE_GAP);
  const out = buildExecutorSystem("BASE", plan, critique);
  assertStringIncludes(out, "<critique_for_regen>");
  assertStringIncludes(out, "material_gap=true");
  assertStringIncludes(out, "warning protocol unanswered");
});

// ─── Orchestrator: 3-pass happy path (no regen) ─────────────────────────────

Deno.test("runLegalPlannerLoop — 3 passes when critique reports no gap", async () => {
  const { caller, calls } = scriptedCaller([
    SAMPLE_PLAN_XML,
    SAMPLE_EXECUTOR,
    SAMPLE_CRITIQUE_OK,
  ]);

  const result = await runLegalPlannerLoop({
    apiKey: "test",
    systemPrompt: "BASE",
    messages: [{ role: "user", content: "Was I dismissed legally?" }],
    caller,
    now: () => 0,
  });

  assertEquals(calls.length, 3, "exactly 3 anthropic calls");
  assertEquals(result.regeneratedOnce, false);
  assertEquals(result.replyText, SAMPLE_EXECUTOR);
  assertEquals(result.plan.sub_questions.length, 2);
  assertEquals(result.critique.material_gap, false);

  // Verify per-pass model + budget contracts.
  assertEquals(calls[0].model, "claude-sonnet-4-20250514");
  assertEquals(calls[0].maxTokens, PLANNER_MAX_TOKENS);
  assertEquals(calls[0].temperature, PLANNER_TEMPERATURE);

  assertEquals(calls[1].model, "claude-sonnet-4-20250514");
  assertEquals(calls[1].maxTokens, EXECUTOR_MAX_TOKENS);
  assertEquals(calls[1].temperature, EXECUTOR_TEMPERATURE);
  // Plan must be folded into executor's system prompt.
  assertStringIncludes(calls[1].systemPrompt, "<plan>");

  assertEquals(calls[2].model, "claude-haiku-4-5-20251001");
  assertEquals(calls[2].maxTokens, CRITIQUE_MAX_TOKENS);
  assertEquals(calls[2].temperature, CRITIQUE_TEMPERATURE);
});

// ─── Orchestrator: 4 passes (regen fires once on material_gap) ──────────────

Deno.test("runLegalPlannerLoop — regenerates ONCE when critique flags gap", async () => {
  const REGEN_DRAFT =
    "Improved draft addressing §97 with [[ref:tls:88]] and [[ref:tls:97]].";
  const { caller, calls } = scriptedCaller([
    SAMPLE_PLAN_XML,
    SAMPLE_EXECUTOR,
    SAMPLE_CRITIQUE_GAP,
    REGEN_DRAFT,
  ]);

  const result = await runLegalPlannerLoop({
    apiKey: "test",
    systemPrompt: "BASE",
    messages: [{ role: "user", content: "Q?" }],
    caller,
  });

  assertEquals(calls.length, 4, "regen fires => 4 calls");
  assertEquals(result.regeneratedOnce, true);
  assertEquals(result.replyText, REGEN_DRAFT);
  assertEquals(result.critique.material_gap, true);

  // The regen pass is also Sonnet at executor budget.
  assertEquals(calls[3].model, "claude-sonnet-4-20250514");
  assertEquals(calls[3].maxTokens, EXECUTOR_MAX_TOKENS);
  // Regen system prompt must include the critique block.
  assertStringIncludes(calls[3].systemPrompt, "<critique_for_regen>");
  assertStringIncludes(calls[3].systemPrompt, "material_gap=true");
});

// ─── Orchestrator: regen never fires twice (loop guard) ─────────────────────

Deno.test("runLegalPlannerLoop — never re-fires regen even if critique returns gap again", async () => {
  // Even if the orchestrator were to re-critique after regen, the loop
  // guard caps re-execution at 1. Today the design only critiques once;
  // this test pins the contract so a future "critique again" change
  // can't accidentally remove the cap.
  const { caller, calls } = scriptedCaller([
    SAMPLE_PLAN_XML,
    SAMPLE_EXECUTOR,
    SAMPLE_CRITIQUE_GAP,
    "regen draft",
  ]);

  const result = await runLegalPlannerLoop({
    apiKey: "test",
    systemPrompt: "BASE",
    messages: [{ role: "user", content: "Q?" }],
    caller,
  });

  assertEquals(calls.length, 4);
  assertEquals(result.regeneratedOnce, true);
});

// ─── Orchestrator: trace writer is invoked ──────────────────────────────────

Deno.test("runLegalPlannerLoop — calls traceWriter with the assembled trace", async () => {
  const { caller } = scriptedCaller([
    SAMPLE_PLAN_XML,
    SAMPLE_EXECUTOR,
    SAMPLE_CRITIQUE_OK,
  ]);

  let captured: Record<string, unknown> | null = null;
  const traceWriter = (trace: Record<string, unknown>) => {
    captured = trace;
    return Promise.resolve();
  };

  await runLegalPlannerLoop({
    apiKey: "test",
    systemPrompt: "BASE",
    messages: [{ role: "user", content: "Q?" }],
    messageId: "00000000-0000-0000-0000-000000000abc",
    // deno-lint-ignore no-explicit-any
    traceWriter: traceWriter as any,
    caller,
  });

  assert(captured !== null, "traceWriter was called");
  const c = captured as Record<string, unknown>;
  assertEquals(c.message_id, "00000000-0000-0000-0000-000000000abc");
  assertEquals(c.regenerated_once, false);
  assertEquals(c.executor_response, SAMPLE_EXECUTOR);
  assert(typeof c.cost_cents === "number" && (c.cost_cents as number) >= 0);
  assert(typeof c.latency_ms === "number");
});

// ─── Orchestrator: trace persist failure does NOT block the user reply ─────

Deno.test("runLegalPlannerLoop — swallows traceWriter errors", async () => {
  const { caller } = scriptedCaller([
    SAMPLE_PLAN_XML,
    SAMPLE_EXECUTOR,
    SAMPLE_CRITIQUE_OK,
  ]);

  const traceWriter = () => Promise.reject(new Error("DB down"));
  // deno-lint-ignore no-explicit-any
  const result = await runLegalPlannerLoop({
    apiKey: "test",
    systemPrompt: "BASE",
    messages: [{ role: "user", content: "Q?" }],
    messageId: "00000000-0000-0000-0000-000000000abc",
    traceWriter: traceWriter as any,
    caller,
  });
  assertEquals(result.replyText, SAMPLE_EXECUTOR);
});

// ─── Marker syntax preserved end-to-end (Pkg 2 reuse) ──────────────────────

Deno.test("runLegalPlannerLoop — executor draft retains [[ref:...]] markers", async () => {
  const { caller } = scriptedCaller([
    SAMPLE_PLAN_XML,
    SAMPLE_EXECUTOR,
    SAMPLE_CRITIQUE_OK,
  ]);
  const result = await runLegalPlannerLoop({
    apiKey: "test",
    systemPrompt: "BASE",
    messages: [{ role: "user", content: "Q?" }],
    caller,
  });
  assertStringIncludes(result.replyText, "[[ref:tls:88]]");
});
