// red_team.test.ts — Deno tests for the adversarial Red-Team pass.
// -----------------------------------------------------------------------------
// Run:
//   deno test --allow-all \
//     supabase/functions/_tests/red_team.test.ts
//
// Scope:
//   T01  parseRedTeamOutput — extracts JSON from <red_team> tags
//   T02  parseRedTeamOutput — enforces contract (severity none ⇔ found=false)
//   T03  parseRedTeamOutput — malformed output ⇒ no-attack default
//   T04  runRedTeam — detects obvious missed-statute attack
//   T05  runRedTeam — returns no-attack when draft is sound
//   T06  runRedTeam — swallows Anthropic errors, returns no-attack
//   T07  runRedTeam — passes draft and plan into the adversarial user message
//   T08  runRedTeam — calls Opus, not Sonnet/Haiku
//   T09  severityTriggersReplan — fatal/serious yes, minor/none no
//   T10  redTeamCostCents — rough cost estimate
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  type AnthropicCaller,
  MODEL_OPUS,
  parseRedTeamOutput,
  RED_TEAM_MAX_TOKENS,
  RED_TEAM_TEMPERATURE,
  redTeamCostCents,
  runRedTeam,
  severityTriggersReplan,
} from "../_shared/red_team.ts";

// ─── Helpers ────────────────────────────────────────────────────────────────

/** Build a scripted caller that returns canned strings in call order and
 *  records what was sent. Mirrors the legal_planner test pattern. */
function scriptedCaller(scripts: string[]): {
  caller: AnthropicCaller;
  calls: Array<{
    model: string;
    maxTokens: number;
    temperature: number;
    systemPrompt: string;
    userMessage: string;
  }>;
} {
  const calls: Array<{
    model: string;
    maxTokens: number;
    temperature: number;
    systemPrompt: string;
    userMessage: string;
  }> = [];
  let i = 0;
  const caller: AnthropicCaller = (req) => {
    calls.push({
      model: req.model,
      maxTokens: req.maxTokens,
      temperature: req.temperature,
      systemPrompt: req.systemPrompt,
      userMessage: req.messages.map((m) => m.content).join("\n"),
    });
    const text = i < scripts.length ? scripts[i++] : "";
    return Promise.resolve({ text, inputTokens: 2000, outputTokens: 250 });
  };
  return { caller, calls };
}

// ─── Fixtures ───────────────────────────────────────────────────────────────

const FATAL_ATTACK = `
<red_team>
{
  "attack_found": true,
  "attack_severity": "fatal",
  "attack_summary": "Draft cites TLS §88 but ignores the §97 warning protocol — opposing counsel will argue the dismissal was lawful because the employer followed §97.",
  "exploit_specifics": "Opposing counsel reads the draft and points to §97(2): 'an employee may be dismissed without notice for gross misconduct AFTER a documented warning.' The draft never addresses whether the warning was given. KHO will accept the employer's submission as the only one on this point."
}
</red_team>
`.trim();

const NO_ATTACK = `
<red_team>
{
  "attack_found": false,
  "attack_severity": "none",
  "attack_summary": "no significant attack found",
  "exploit_specifics": ""
}
</red_team>
`.trim();

const SERIOUS_ATTACK = `
<red_team>
{
  "attack_found": true,
  "attack_severity": "serious",
  "attack_summary": "You forgot to mention statute X — wrong jurisdiction.",
  "exploit_specifics": "The draft routes the client to HAO when the appeal must be filed at KHO under HOL § 114-115. HAO will refuse to even examine the petition."
}
</red_team>
`.trim();

const SAMPLE_PLAN = {
  sub_questions: ["Was §97 warning protocol followed?"],
  counter_args: ["Employer may argue gross misconduct."],
  evidence_gaps: ["Warning notice copy."],
  probability_signal: "weak — 20%",
};

const SAMPLE_DRAFT =
  "The dismissal looks unlawful under [[ref:tls:88]] because procedure was not followed.";

// ─── T01 — Parser extracts JSON ─────────────────────────────────────────────

Deno.test("T01 parseRedTeamOutput — extracts JSON from <red_team> tags", () => {
  const r = parseRedTeamOutput(FATAL_ATTACK);
  assertEquals(r.attack_found, true);
  assertEquals(r.attack_severity, "fatal");
  assertStringIncludes(r.attack_summary, "TLS §88");
  assertStringIncludes(r.exploit_specifics, "§97");
  assert(r.raw.length > 0);
});

// ─── T02 — Parser enforces contract invariants ──────────────────────────────

Deno.test("T02 parseRedTeamOutput — found=false + minor severity ⇒ both coerced to none", () => {
  // When severity is non-promoting (minor/none), found=false wins and
  // severity is forced to "none" — the parser normalises an incoherent
  // "minor attack but not really found" input into a clean no-attack.
  const broken = `<red_team>{"attack_found": false, "attack_severity": "minor"}</red_team>`;
  const r = parseRedTeamOutput(broken);
  // Contract: !found AND non-promoting severity ⇒ severity=none.
  assertEquals(r.attack_found, false);
  assertEquals(r.attack_severity, "none");
});

Deno.test("T02-conflict parseRedTeamOutput — found=false + fatal severity ⇒ severity wins", () => {
  // When severity is serious/fatal we treat it as the authoritative signal
  // (severity dominates). This is the safe failure mode: prefer triggering
  // a re-plan over shipping a flawed draft.
  const broken = `<red_team>{"attack_found": false, "attack_severity": "fatal", "attack_summary": "x"}</red_team>`;
  const r = parseRedTeamOutput(broken);
  assertEquals(r.attack_found, true);
  assertEquals(r.attack_severity, "fatal");
});

Deno.test("T02b parseRedTeamOutput — serious severity coerces found=true", () => {
  const broken = `<red_team>{"attack_found": false, "attack_severity": "serious", "attack_summary": "x", "exploit_specifics": "y"}</red_team>`;
  const r = parseRedTeamOutput(broken);
  // Contract: severity in {serious,fatal} ⇒ found=true.
  assertEquals(r.attack_found, true);
  assertEquals(r.attack_severity, "serious");
});

Deno.test("T02c parseRedTeamOutput — found=true + severity=none ⇒ minor", () => {
  const broken = `<red_team>{"attack_found": true, "attack_severity": "none", "attack_summary": "x"}</red_team>`;
  const r = parseRedTeamOutput(broken);
  // Contract: found=true but severity=none is incoherent; treat as minor.
  assertEquals(r.attack_found, true);
  assertEquals(r.attack_severity, "minor");
});

// ─── T03 — Malformed output is safe ─────────────────────────────────────────

Deno.test("T03 parseRedTeamOutput — malformed JSON defaults to no-attack", () => {
  const r = parseRedTeamOutput("not even close to JSON or tags");
  assertEquals(r.attack_found, false);
  assertEquals(r.attack_severity, "none");
});

Deno.test("T03b parseRedTeamOutput — missing tags but valid JSON inside", () => {
  // Tag is optional — JSON alone should still parse.
  const r = parseRedTeamOutput(
    `{"attack_found": true, "attack_severity": "minor", "attack_summary": "nit", "exploit_specifics": "small"}`,
  );
  assertEquals(r.attack_found, true);
  assertEquals(r.attack_severity, "minor");
});

// ─── T04 — Detects obvious attack ───────────────────────────────────────────

Deno.test("T04 runRedTeam — detects fatal missed-statute attack", async () => {
  const { caller, calls } = scriptedCaller([FATAL_ATTACK]);
  const result = await runRedTeam({
    apiKey: "test",
    systemPrompt: "BASE",
    plan: SAMPLE_PLAN,
    draft: SAMPLE_DRAFT,
    messages: [{ role: "user", content: "Was my dismissal lawful?" }],
    caller,
  });

  assertEquals(result.attack_found, true);
  assertEquals(result.attack_severity, "fatal");
  assertStringIncludes(result.attack_summary, "§97");
  assertEquals(calls.length, 1);
});

// ─── T05 — No-attack case ───────────────────────────────────────────────────

Deno.test("T05 runRedTeam — returns no-attack when draft is sound", async () => {
  const { caller } = scriptedCaller([NO_ATTACK]);
  const result = await runRedTeam({
    apiKey: "test",
    systemPrompt: "BASE",
    plan: SAMPLE_PLAN,
    draft: SAMPLE_DRAFT,
    messages: [{ role: "user", content: "Q?" }],
    caller,
  });

  assertEquals(result.attack_found, false);
  assertEquals(result.attack_severity, "none");
  assertEquals(result.attack_summary, "");
});

// ─── T06 — Error swallowing ─────────────────────────────────────────────────

Deno.test("T06 runRedTeam — swallows Anthropic errors, returns no-attack", async () => {
  const failingCaller: AnthropicCaller = () => {
    throw new Error("Anthropic 500 (claude-opus-4): server error");
  };
  const result = await runRedTeam({
    apiKey: "test",
    systemPrompt: "BASE",
    plan: SAMPLE_PLAN,
    draft: SAMPLE_DRAFT,
    messages: [{ role: "user", content: "Q?" }],
    caller: failingCaller,
  });

  assertEquals(result.attack_found, false);
  assertEquals(result.attack_severity, "none");
  assertStringIncludes(result.raw, "unavailable");
  assertEquals(result.costCents, 0);
});

// ─── T07 — Plan + draft folded into adversarial user message ───────────────

Deno.test("T07 runRedTeam — passes draft and plan into the user message", async () => {
  const { caller, calls } = scriptedCaller([NO_ATTACK]);
  await runRedTeam({
    apiKey: "test",
    systemPrompt: "BASE",
    plan: SAMPLE_PLAN,
    draft: SAMPLE_DRAFT,
    messages: [{ role: "user", content: "Was my dismissal lawful?" }],
    caller,
  });

  assertEquals(calls.length, 1);
  const userMsg = calls[0].userMessage;
  // Draft must be visible to the Red-Team.
  assertStringIncludes(userMsg, SAMPLE_DRAFT);
  // Plan sub-question must be visible.
  assertStringIncludes(userMsg, "§97 warning protocol");
  // Original client question must be visible.
  assertStringIncludes(userMsg, "Was my dismissal lawful?");
  // Adversarial framing must be explicit.
  assertStringIncludes(userMsg, "attack this draft");
});

// ─── T08 — Uses Opus, not Sonnet/Haiku ──────────────────────────────────────

Deno.test("T08 runRedTeam — calls Opus at correct budget/temp", async () => {
  const { caller, calls } = scriptedCaller([NO_ATTACK]);
  await runRedTeam({
    apiKey: "test",
    systemPrompt: "BASE",
    plan: SAMPLE_PLAN,
    draft: SAMPLE_DRAFT,
    messages: [{ role: "user", content: "Q?" }],
    caller,
  });

  assertEquals(calls[0].model, MODEL_OPUS);
  assertEquals(calls[0].maxTokens, RED_TEAM_MAX_TOKENS);
  assertEquals(calls[0].temperature, RED_TEAM_TEMPERATURE);
  // System prompt must include the Red-Team instructions block.
  assertStringIncludes(calls[0].systemPrompt, "Red-Team pass");
  assertStringIncludes(calls[0].systemPrompt, "opposing counsel");
});

// ─── T09 — severityTriggersReplan ───────────────────────────────────────────

Deno.test("T09 severityTriggersReplan — fatal/serious trigger, others don't", () => {
  assertEquals(severityTriggersReplan("fatal"), true);
  assertEquals(severityTriggersReplan("serious"), true);
  assertEquals(severityTriggersReplan("minor"), false);
  assertEquals(severityTriggersReplan("none"), false);
});

// ─── T10 — Cost estimate ────────────────────────────────────────────────────

Deno.test("T10 redTeamCostCents — bounded estimate for typical pass", () => {
  // 2000 input + 300 output tokens (typical Red-Team pass).
  const c = redTeamCostCents(2000, 300);
  // Opus: 2000 * 1500/Mtok + 300 * 7500/Mtok = 3 + 2.25 = ~5.25c (rounded up to 6).
  assert(c >= 5 && c <= 10, `expected ~5-10c got ${c}`);
});

Deno.test("T10b redTeamCostCents — zero tokens => zero cents", () => {
  assertEquals(redTeamCostCents(0, 0), 0);
});

// ─── Bonus: SERIOUS triggers re-plan, MINOR does not ────────────────────────

Deno.test("BONUS runRedTeam — SERIOUS attack returned with replan flag", async () => {
  const { caller } = scriptedCaller([SERIOUS_ATTACK]);
  const result = await runRedTeam({
    apiKey: "test",
    systemPrompt: "BASE",
    plan: SAMPLE_PLAN,
    draft: SAMPLE_DRAFT,
    messages: [{ role: "user", content: "Q?" }],
    caller,
  });
  assertEquals(result.attack_severity, "serious");
  assertEquals(severityTriggersReplan(result.attack_severity), true);
});
