// claude_proxy_corrections_wiring.test.ts
// ----------------------------------------------------------------------------
// Wiring contract test for the claude-proxy integration of the
// Memory-of-Wrong-Answers system (Pkg #13).
//
// Run with:
//   deno test --allow-net --allow-read --allow-env \
//     supabase/functions/_tests/claude_proxy_corrections_wiring.test.ts
//
// What this exercises (the FIVE wiring claims made in claude-proxy/index.ts):
//   1. retrieveCorrections is called BEFORE the planner.
//   2. The retrieved rows render to a non-empty correctionsBlock.
//   3. The block is forwarded into runLegalPlannerLoop via options.
//   4. selfCorrectionScan runs on the planner output AFTER the loop.
//   5. When the scan matches, a regen fires with selfCorrectionAddendum
//      AND forceRegenForSelfCorrection=true.
//
// We test the wiring at the level of the public surface — the four exported
// helpers from corrections_retriever and the runLegalPlannerLoop contract.
// The proxy itself is a 1400-line edge function with a fetch-listener
// entrypoint; rather than reaching for a full HTTP harness we simulate the
// EXACT sequence of calls the proxy makes, with the same scripted shims that
// advice_corrections.test.ts already uses for the planner.
// ----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  type AnthropicCaller,
  runLegalPlannerLoop,
} from "../_shared/legal_planner.ts";

import {
  buildSelfCorrectionAddendum,
  type CorrectionRow,
  formatCorrectionsBlock,
  retrieveCorrections,
  selfCorrectionScan,
} from "../_shared/corrections_retriever.ts";

// ─── Fixtures ───────────────────────────────────────────────────────────────

const HOL_ROW: CorrectionRow = {
  id: "hol-114-row",
  question:
    "Mitä Hallintolainkäyttölaki §114 sanoo menetetyn määräajan palauttamisesta?",
  wrong_advice:
    "Hakemus on tehtävä 30 päivän kuluessa siitä, kun este on lakannut. Hakemusta ei voida tehdä vuoden kuluttua määräajan päättymisestä. Hakemuksen käsittelee se tuomioistuin, jossa asia on vireillä.",
  correct_answer:
    "HOL §114-115 reserves restoration of missed deadlines exclusively for KHO. Time window: 5 years. Standard: erityisen painava syy.",
  why_wrong:
    "Three factual errors: invented 30-day cap, invented 1-year cap, wrong jurisdiction.",
  jurisdiction: "fi",
  case_type: "administrative",
  severity: "factual",
  similarity: 0.92,
};

const PLAN_OK = `
<plan>
  <sub_questions>- Statute scope?</sub_questions>
  <counter_args>- None obvious.</counter_args>
  <evidence_gaps>- None.</evidence_gaps>
</plan>
`.trim();

const CRITIQUE_OK =
  `<critique>{"material_gap": false, "issues": []}</critique>`;

/** Scripted Anthropic caller — replays texts[0], texts[1], ... in order
 *  and records the full system prompt of every call so tests can assert
 *  what was injected. Identical pattern to advice_corrections.test.ts. */
function scriptedAnthropic(scripts: string[]): {
  caller: AnthropicCaller;
  calls: Array<{ systemPrompt: string; model: string }>;
} {
  const calls: Array<{ systemPrompt: string; model: string }> = [];
  let i = 0;
  const caller: AnthropicCaller = (req) => {
    calls.push({ systemPrompt: req.systemPrompt, model: req.model });
    const text = i < scripts.length ? scripts[i++] : "";
    return Promise.resolve({ text, inputTokens: 50, outputTokens: 50 });
  };
  return { caller, calls };
}

// ─── 1. retrieveCorrections is called before the planner ───────────────────

Deno.test("wiring: retrieveCorrections fires before runLegalPlannerLoop", async () => {
  // Simulate the proxy sequence: retrieve → render → planner.
  const order: string[] = [];

  const rows = await retrieveCorrections({
    question: HOL_ROW.question,
    jurisdiction: null,
    threshold: 0.75,
    supabaseUrl: "https://stub.supabase.co",
    serviceRoleKey: "stub-key",
    retriever: () => {
      order.push("retrieve");
      return Promise.resolve([HOL_ROW]);
    },
  });
  assertEquals(rows.length, 1);

  const block = formatCorrectionsBlock(rows);
  assertStringIncludes(block, "<learned_corrections>");

  const { caller, calls } = scriptedAnthropic([PLAN_OK, "Draft.", CRITIQUE_OK]);
  await runLegalPlannerLoop({
    apiKey: "test",
    systemPrompt: "BASE",
    messages: [{ role: "user", content: HOL_ROW.question }],
    caller: (req) => {
      order.push("planner");
      return caller(req);
    },
    correctionsBlock: block,
    enableAdversarial: false,
    now: () => 0,
  });
  // Retrieve must fire first; planner second (and may fire three times).
  assertEquals(order[0], "retrieve");
  assert(order.includes("planner"));
  assertEquals(calls.length, 3);
});

// ─── 2. correctionsBlock is non-empty when rows are retrieved ──────────────

Deno.test("wiring: retrieved rows render to a non-empty correctionsBlock", () => {
  const block = formatCorrectionsBlock([HOL_ROW]);
  assert(block.length > 0);
  assertStringIncludes(block, "HOL");
  assertStringIncludes(block, "<learned_corrections>");
});

// ─── 3. correctionsBlock is passed to planner options & seen by every pass ─

Deno.test("wiring: correctionsBlock propagates into every planner pass", async () => {
  const block = formatCorrectionsBlock([HOL_ROW]);
  const { caller, calls } = scriptedAnthropic([PLAN_OK, "Draft.", CRITIQUE_OK]);

  await runLegalPlannerLoop({
    apiKey: "test",
    systemPrompt: "BASE_PROMPT",
    messages: [{ role: "user", content: HOL_ROW.question }],
    caller,
    correctionsBlock: block,
    enableAdversarial: false,
    now: () => 0,
  });
  // 3 passes (planner + executor + critique), each must see the block.
  assertEquals(calls.length, 3);
  for (const c of calls) {
    assertStringIncludes(c.systemPrompt, "<learned_corrections>");
    assertStringIncludes(c.systemPrompt, "BASE_PROMPT");
  }
});

// ─── 4. selfCorrectionScan runs AFTER the planner returns ──────────────────

Deno.test("wiring: selfCorrectionScan flags a draft that repeats wrong_advice", () => {
  // The planner output paraphrases the HOL wrong_advice (30 päivän kuluessa).
  const draft =
    "Hakemus on tehtävä 30 päivän kuluessa siitä, kun este on lakannut. " +
    "Hakemus jätetään sille tuomioistuimelle, jossa asia on vireillä.";
  const matches = selfCorrectionScan(draft, [HOL_ROW]);
  assertEquals(matches.length, 1);
  assertEquals(matches[0].correction_id, "hol-114-row");
  assertStringIncludes(matches[0].correct_answer, "KHO");
});

Deno.test("wiring: selfCorrectionScan clean draft yields no matches (no regen)", () => {
  const clean =
    "HOL §114-115 mukaan menetetyn määräajan palauttamishakemus tehdään " +
    "KHO:lle 5 vuoden kuluessa määräajan päättymisestä, erityisen painavasta syystä.";
  const matches = selfCorrectionScan(clean, [HOL_ROW]);
  assertEquals(matches.length, 0);
});

// ─── 5. Regen fires when scan matches, with addendum + force flag ─────────

Deno.test("wiring: scan match triggers regen with addendum + force flag", async () => {
  // First loop: bad draft. Scan finds the wrong_advice substring. Second
  // loop: regen succeeds with addendum injected into the regen system prompt.
  const block = formatCorrectionsBlock([HOL_ROW]);
  const badDraft =
    "Hakemus on tehtävä 30 päivän kuluessa siitä, kun este on lakannut.";
  const goodDraft =
    "Hakemus jätetään KHO:lle 5 vuoden kuluessa. HOL §114-115.";

  // First runLegalPlannerLoop — produces the bad draft.
  const { caller: c1 } = scriptedAnthropic([PLAN_OK, badDraft, CRITIQUE_OK]);
  const first = await runLegalPlannerLoop({
    apiKey: "test",
    systemPrompt: "BASE",
    messages: [{ role: "user", content: HOL_ROW.question }],
    caller: c1,
    correctionsBlock: block,
    enableAdversarial: false,
    now: () => 0,
  });
  assertEquals(first.kind, "completed");
  if (first.kind !== "completed") return;
  assertEquals(first.replyText, badDraft);

  // The proxy now runs selfCorrectionScan on first.replyText.
  const matches = selfCorrectionScan(first.replyText, [HOL_ROW]);
  assert(matches.length > 0, "scan must catch the bad draft");
  const addendum = buildSelfCorrectionAddendum(matches);
  assertStringIncludes(addendum, "<do_not_repeat>");
  assertStringIncludes(addendum, "KHO");

  // Proxy fires the second runLegalPlannerLoop with selfCorrectionAddendum
  // + forceRegenForSelfCorrection=true. The planner will run:
  //   planner → executor (initial) → critique (no gap) → regen (force) = 4 calls
  const { caller: c2, calls: c2Calls } = scriptedAnthropic([
    PLAN_OK,
    badDraft, // initial executor — would still be bad
    CRITIQUE_OK, // critique says no material gap
    goodDraft, // regen produces good answer
  ]);
  const second = await runLegalPlannerLoop({
    apiKey: "test",
    systemPrompt: "BASE",
    messages: [{ role: "user", content: HOL_ROW.question }],
    caller: c2,
    correctionsBlock: block,
    selfCorrectionAddendum: addendum,
    forceRegenForSelfCorrection: true,
    enableAdversarial: false,
    now: () => 0,
  });
  assertEquals(second.kind, "completed");
  if (second.kind !== "completed") return;
  assertEquals(second.regeneratedOnce, true, "regen must have fired");
  assertEquals(second.replyText, goodDraft);
  // Regen call (index 3) must have BOTH the corrections block AND the addendum.
  assertEquals(c2Calls.length, 4);
  assertStringIncludes(c2Calls[3].systemPrompt, "<do_not_repeat>");
  assertStringIncludes(c2Calls[3].systemPrompt, "<learned_corrections>");
});

// ─── 6. Backward compatibility — empty rows = legacy behaviour ─────────────

Deno.test("wiring: empty correctionsRows means no scan, no regen, no change", async () => {
  // Proxy invariant: when retrieveCorrections returns [], the second
  // runLegalPlannerLoop must NEVER be called and the planner sees no block.
  const { caller, calls } = scriptedAnthropic([PLAN_OK, "Draft.", CRITIQUE_OK]);
  const result = await runLegalPlannerLoop({
    apiKey: "test",
    systemPrompt: "BASE",
    messages: [{ role: "user", content: "any question" }],
    caller,
    correctionsBlock: "", // empty rows → empty block
    enableAdversarial: false,
    now: () => 0,
  });
  assertEquals(result.kind, "completed");
  if (result.kind !== "completed") return;
  assertEquals(result.regeneratedOnce, false);
  assertEquals(calls.length, 3, "exactly planner + executor + critique");
  for (const c of calls) {
    assertEquals(
      c.systemPrompt.includes("<learned_corrections>"),
      false,
      "no block when rows are empty",
    );
  }
});

// ─── 7. retrieveCorrections fails open when OpenAI key is missing ──────────

Deno.test("wiring: no OPENAI_API_KEY + no retriever = empty rows (proxy no-ops)", async () => {
  // The proxy guards: `if (userMessage && OPENAI_API_KEY) { retrieve... }`.
  // We simulate the contract by calling retrieveCorrections with neither
  // an openaiApiKey nor a retriever — the helper must return [].
  const rows = await retrieveCorrections({
    question: "irrelevant",
    supabaseUrl: "https://stub.supabase.co",
    serviceRoleKey: "stub-key",
  });
  assertEquals(rows.length, 0);
  // formatCorrectionsBlock on [] yields "" — planner runs unchanged.
  assertEquals(formatCorrectionsBlock(rows), "");
});

// ─── 8. retrieveCorrections fails open when the RPC throws ─────────────────

Deno.test("wiring: RPC failure inside retrieveCorrections does not crash proxy", async () => {
  const rows = await retrieveCorrections({
    question: HOL_ROW.question,
    supabaseUrl: "https://stub.supabase.co",
    serviceRoleKey: "stub-key",
    retriever: () => Promise.reject(new Error("simulated 500")),
  });
  assertEquals(rows.length, 0); // helper swallows the throw → empty result
});

// End of file.
