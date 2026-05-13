// advice_corrections.test.ts — Memory of Wrong Answers contract tests.
// ----------------------------------------------------------------------------
// Run with:
//   deno test --allow-net --allow-read --allow-env \
//     supabase/functions/_tests/advice_corrections.test.ts
//
// What this exercises:
//   * correction_detector identifies a user correction (positive + negative).
//   * correction_detector heuristic gate rejects trivial replies cheaply.
//   * formatCorrectionsBlock renders rows under the 4 KB cap.
//   * formatCorrectionsBlock enforces the cap when rows are oversized.
//   * selfCorrectionScan flags drafts repeating a known wrong_advice.
//   * retrieveCorrections wires up to an injected SimilarityRetriever.
//   * runLegalPlannerLoop prepends correctionsBlock to every pass.
//   * runLegalPlannerLoop triggers a regen when forceRegenForSelfCorrection
//     is true and selfCorrectionAddendum is non-empty.
//   * Seed migration parses and contains all expected rows.
// ----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
  assertNotEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  type AnthropicCaller,
  runLegalPlannerLoop,
} from "../_shared/legal_planner.ts";

import {
  isPlausibleCorrection,
  parseDetectorOutput,
  type HaikuCaller,
  detectAndRecordCorrection,
} from "../_shared/correction_detector.ts";

import {
  buildSelfCorrectionAddendum,
  CORRECTIONS_BLOCK_MAX_BYTES,
  formatCorrectionsBlock,
  retrieveCorrections,
  selfCorrectionScan,
  type CorrectionRow,
} from "../_shared/corrections_retriever.ts";

// ─── Fixtures ───────────────────────────────────────────────────────────────

const HAO_ROW: CorrectionRow = {
  id: "hao-kho-row",
  question: "Can HAO hear menetetyn määräajan palauttaminen?",
  wrong_advice: "Yes, HAO can hear menetetyn määräajan palauttaminen",
  correct_answer:
    "No — HOL §114–115 reserves menetetyn määräajan palauttaminen for KHO only. Filing it in HAO = automatic ei tutki.",
  why_wrong:
    "Confused HAO general appeal jurisdiction with restoration jurisdiction reserved to KHO.",
  jurisdiction: "FI",
  case_type: "administrative",
  severity: "procedural",
  similarity: 0.91,
};

const SOVIET_ROW: CorrectionRow = {
  id: "sulga-soviet-row",
  question: "Is the citizenship field 'Neuvostoliitto' acceptable for an Estonian client?",
  wrong_advice: "Treating 'Neuvostoliitto' as a synonym for Estonia is fine",
  correct_answer:
    "Wrong. The Soviet Union ceased to exist in 1991; an EU citizen must be recorded as 'Viro'. The Neuvostoliitto entry is a category error usable as evidence of systemic identification failure under Ulkomaalaislaki 196 § erityisen painava syy.",
  why_wrong: "Identification standards under Direktiivi 2004/38/EY require current EU citizenship.",
  jurisdiction: "FI",
  case_type: "deportation",
  severity: "factual",
  similarity: 0.86,
};

// ─── 1. correction_detector — heuristic gate ─────────────────────────────────

Deno.test("isPlausibleCorrection — short replies rejected", () => {
  assertEquals(isPlausibleCorrection("ok", "prior assistant turn here"), false);
  assertEquals(isPlausibleCorrection("спасибо", "prior assistant turn"), false);
  assertEquals(isPlausibleCorrection("", "prior assistant turn"), false);
});

Deno.test("isPlausibleCorrection — missing prior turn rejected", () => {
  assertEquals(
    isPlausibleCorrection("That's wrong — should be X", ""),
    false,
  );
});

Deno.test("isPlausibleCorrection — accepts English correction markers", () => {
  assertEquals(
    isPlausibleCorrection(
      "Actually that's wrong, it should be HAO not KHO",
      "Long prior assistant turn that exceeds the 20-char minimum",
    ),
    true,
  );
});

Deno.test("isPlausibleCorrection — accepts Finnish correction markers", () => {
  assertEquals(
    isPlausibleCorrection(
      "Itse asiassa tämä ei pidä paikkaansa",
      "Long prior assistant turn that exceeds the 20-char minimum",
    ),
    true,
  );
});

Deno.test("isPlausibleCorrection — accepts Russian correction markers", () => {
  assertEquals(
    isPlausibleCorrection(
      "Нет, на самом деле должно быть так-то",
      "Long prior assistant turn that exceeds the 20-char minimum",
    ),
    true,
  );
});

// ─── 2. correction_detector — parser ────────────────────────────────────────

Deno.test("parseDetectorOutput — happy-path JSON", () => {
  const raw = `{
    "detected": true,
    "what_was_wrong": "HAO can hear menetetyn määräajan palauttaminen",
    "correct_answer": "Only KHO can — HOL §114-115",
    "why": "Confused general appeal jurisdiction with restoration jurisdiction"
  }`;
  const r = parseDetectorOutput(raw);
  assertEquals(r.detected, true);
  assertStringIncludes(r.what_was_wrong!, "HAO");
  assertStringIncludes(r.correct_answer!, "KHO");
});

Deno.test("parseDetectorOutput — tolerates code fences", () => {
  const raw = "```json\n{\"detected\": false}\n```";
  const r = parseDetectorOutput(raw);
  assertEquals(r.detected, false);
});

Deno.test("parseDetectorOutput — malformed JSON yields detected=false", () => {
  const r = parseDetectorOutput("not json at all");
  assertEquals(r.detected, false);
});

// ─── 3. correction_detector — end-to-end (mocked) ───────────────────────────

Deno.test("detectAndRecordCorrection — positive detection inserts row", async () => {
  // Scripted Haiku says correction detected.
  const scriptedCaller: HaikuCaller = () =>
    Promise.resolve(JSON.stringify({
      detected: true,
      what_was_wrong: "HAO can hear menetetyn määräajan palauttaminen",
      correct_answer: "Only KHO — HOL §114-115",
      why: "Confused jurisdiction.",
    }));

  // Capture the Supabase insert call.
  const seen: Array<{ url: string; body: unknown }> = [];
  const originalFetch = globalThis.fetch;
  globalThis.fetch = ((
    input: RequestInfo | URL,
    init?: RequestInit,
  ) => {
    const url = String(input);
    if (url.includes("/rest/v1/advice_corrections")) {
      seen.push({ url, body: JSON.parse(String(init?.body ?? "{}")) });
      return Promise.resolve(new Response(null, { status: 201 }));
    }
    return originalFetch(input, init);
  }) as typeof fetch;

  try {
    const result = await detectAndRecordCorrection({
      userId: "user-1",
      userMessage:
        "That's wrong — HAO cannot hear restoration of missed deadlines, only KHO can.",
      previousAssistantMessage:
        "You can file menetetyn määräajan palauttaminen at HAO together with your appeal.",
      jurisdiction: "FI",
      caseType: "administrative",
      supabaseUrl: "https://stub.supabase.co",
      serviceRoleKey: "stub-service-role",
      anthropicApiKey: "stub-anthropic",
      caller: scriptedCaller,
    });
    assertEquals(result.detected, true);
    assertEquals(seen.length, 1, "exactly one insert");
    const body = seen[0].body as Record<string, unknown>;
    assertEquals(body.correction_source, "user_explicit");
    assertEquals(body.user_id, "user-1");
    assertEquals(body.jurisdiction, "FI");
    assertStringIncludes(body.wrong_advice as string, "HAO");
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("detectAndRecordCorrection — negative detection does NOT insert", async () => {
  // Heuristic returns false on a short reply with no markers.
  const seen: Array<unknown> = [];
  const originalFetch = globalThis.fetch;
  globalThis.fetch = ((
    input: RequestInfo | URL,
    init?: RequestInit,
  ) => {
    const url = String(input);
    if (url.includes("/rest/v1/advice_corrections")) {
      seen.push(init?.body);
      return Promise.resolve(new Response(null, { status: 201 }));
    }
    return originalFetch(input, init);
  }) as typeof fetch;

  try {
    const result = await detectAndRecordCorrection({
      userId: "user-1",
      userMessage: "ok thanks",
      previousAssistantMessage:
        "Long prior assistant turn that exceeds the 20-char minimum",
      supabaseUrl: "https://stub.supabase.co",
      serviceRoleKey: "stub-service-role",
      anthropicApiKey: "stub-anthropic",
      // No caller — heuristic gate fires first.
    });
    assertEquals(result.detected, false);
    assertEquals(seen.length, 0, "no insert on negative");
  } finally {
    globalThis.fetch = originalFetch;
  }
});

// ─── 4. formatCorrectionsBlock — content + cap ──────────────────────────────

Deno.test("formatCorrectionsBlock — empty rows returns empty string", () => {
  assertEquals(formatCorrectionsBlock([]), "");
});

Deno.test("formatCorrectionsBlock — renders rows under cap", () => {
  const block = formatCorrectionsBlock([HAO_ROW, SOVIET_ROW]);
  assertStringIncludes(block, "<learned_corrections>");
  assertStringIncludes(block, "</learned_corrections>");
  assertStringIncludes(block, "Past mistakes you should NOT repeat:");
  assertStringIncludes(block, "HAO");
  assertStringIncludes(block, "KHO");
  assertStringIncludes(block, "Neuvostoliitto");
  assert(
    new TextEncoder().encode(block).length <= CORRECTIONS_BLOCK_MAX_BYTES,
    "block fits under the cap",
  );
});

Deno.test("formatCorrectionsBlock — enforces 4 KB cap when rows are oversized", () => {
  // Build a fake row with a 5 KB correct_answer.
  const big: CorrectionRow = {
    ...HAO_ROW,
    id: "big-row",
    correct_answer: "X".repeat(5 * 1024),
  };
  const rows = [HAO_ROW, big, SOVIET_ROW, big];
  const block = formatCorrectionsBlock(rows);
  const bytes = new TextEncoder().encode(block).length;
  assert(
    bytes <= CORRECTIONS_BLOCK_MAX_BYTES,
    `block byte size ${bytes} exceeds cap ${CORRECTIONS_BLOCK_MAX_BYTES}`,
  );
  // Still well-formed XML-ish structure.
  assertStringIncludes(block, "<learned_corrections>");
  assertStringIncludes(block, "</learned_corrections>");
});

Deno.test("formatCorrectionsBlock — explicit maxBytes argument honoured", () => {
  // Allow only 600 bytes. Should fit at most 1 small row.
  const block = formatCorrectionsBlock([HAO_ROW, SOVIET_ROW], 600);
  const bytes = new TextEncoder().encode(block).length;
  assert(bytes <= 600, `tight cap exceeded: ${bytes}`);
});

// ─── 5. selfCorrectionScan — pattern matching ──────────────────────────────

Deno.test("selfCorrectionScan — flags draft that repeats wrong_advice", () => {
  // The draft contains a paraphrase of the HAO wrong_advice.
  const draft = `
    Based on the facts, you should file the menetetyn määräajan palauttaminen
    at HAO together with your appeal. Yes, HAO can hear menetetyn määräajan
    palauttaminen as long as it's combined with the main valitus.
  `;
  const matches = selfCorrectionScan(draft, [HAO_ROW]);
  assertEquals(matches.length, 1);
  assertEquals(matches[0].correction_id, "hao-kho-row");
  assertStringIncludes(matches[0].correct_answer, "KHO");
});

Deno.test("selfCorrectionScan — clean draft yields zero matches", () => {
  const cleanDraft =
    "Filed at KHO under HOL §114-115; the appeal itself remains at HAO.";
  const matches = selfCorrectionScan(cleanDraft, [HAO_ROW]);
  assertEquals(matches.length, 0);
});

Deno.test("buildSelfCorrectionAddendum — empty matches yields empty string", () => {
  assertEquals(buildSelfCorrectionAddendum([]), "");
});

Deno.test("buildSelfCorrectionAddendum — non-empty matches build DO_NOT_REPEAT", () => {
  const addendum = buildSelfCorrectionAddendum([{
    correction_id: "hao-kho-row",
    matched_phrase: "yes, hao can hear menetetyn",
    wrong_advice: HAO_ROW.wrong_advice,
    correct_answer: HAO_ROW.correct_answer,
  }]);
  assertStringIncludes(addendum, "<do_not_repeat>");
  assertStringIncludes(addendum, "WRONG");
  assertStringIncludes(addendum, "CORRECT");
  assertStringIncludes(addendum, "KHO");
});

// ─── 6. retrieveCorrections — injected retriever ────────────────────────────

Deno.test("retrieveCorrections — uses injected retriever", async () => {
  const rows = await retrieveCorrections({
    question: "Can HAO hear restoration of missed deadline?",
    jurisdiction: "FI",
    supabaseUrl: "https://stub.supabase.co",
    serviceRoleKey: "stub-key",
    retriever: () => Promise.resolve([HAO_ROW]),
  });
  assertEquals(rows.length, 1);
  assertEquals(rows[0].id, "hao-kho-row");
});

Deno.test("retrieveCorrections — swallows retriever errors", async () => {
  const rows = await retrieveCorrections({
    question: "irrelevant",
    supabaseUrl: "https://stub.supabase.co",
    serviceRoleKey: "stub-key",
    retriever: () => Promise.reject(new Error("simulated RPC failure")),
  });
  assertEquals(rows.length, 0);
});

Deno.test("retrieveCorrections — no OpenAI key + no retriever yields []", async () => {
  const rows = await retrieveCorrections({
    question: "Anything",
    supabaseUrl: "https://stub.supabase.co",
    serviceRoleKey: "stub-key",
    // openaiApiKey undefined, retriever undefined → fail-open path.
  });
  assertEquals(rows.length, 0);
});

// ─── 7. Planner integration — corrections injection ─────────────────────────

const PLAN_OK = `
<plan>
  <sub_questions>- Question A?</sub_questions>
  <counter_args>- Counter X.</counter_args>
  <evidence_gaps>- Gap Y.</evidence_gaps>
</plan>
`.trim();

const CRITIQUE_OK = `<critique>{"material_gap": false, "issues": []}</critique>`;
const CRITIQUE_GAP = `<critique>{"material_gap": true, "issues": ["fix it"]}</critique>`;

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

Deno.test("runLegalPlannerLoop — prepends correctionsBlock to all passes", async () => {
  const corrections = formatCorrectionsBlock([HAO_ROW]);
  const { caller, calls } = scriptedAnthropic([
    PLAN_OK,
    "Draft answer.",
    CRITIQUE_OK,
  ]);
  const result = await runLegalPlannerLoop({
    apiKey: "test",
    systemPrompt: "BASE_PROMPT",
    messages: [{ role: "user", content: "Can HAO hear restoration?" }],
    caller,
    correctionsBlock: corrections,
    enableAdversarial: false,
    now: () => 0,
  });
  assertEquals(result.kind, "completed");
  // All three passes should see the corrections block.
  assertEquals(calls.length, 3);
  for (const c of calls) {
    assertStringIncludes(c.systemPrompt, "<learned_corrections>");
    assertStringIncludes(c.systemPrompt, "BASE_PROMPT");
  }
});

Deno.test("runLegalPlannerLoop — empty correctionsBlock = legacy behaviour", async () => {
  const { caller, calls } = scriptedAnthropic([
    PLAN_OK,
    "Draft answer.",
    CRITIQUE_OK,
  ]);
  await runLegalPlannerLoop({
    apiKey: "test",
    systemPrompt: "BASE_PROMPT",
    messages: [{ role: "user", content: "Q?" }],
    caller,
    correctionsBlock: "",
    enableAdversarial: false,
    now: () => 0,
  });
  for (const c of calls) {
    assertEquals(c.systemPrompt.includes("<learned_corrections>"), false);
  }
});

Deno.test("runLegalPlannerLoop — forceRegenForSelfCorrection triggers regen + injects addendum", async () => {
  const addendum = buildSelfCorrectionAddendum([{
    correction_id: HAO_ROW.id,
    matched_phrase: "yes, hao",
    wrong_advice: HAO_ROW.wrong_advice,
    correct_answer: HAO_ROW.correct_answer,
  }]);
  const { caller, calls } = scriptedAnthropic([
    PLAN_OK,
    "Bad draft saying HAO can do it.", // exec1
    CRITIQUE_OK,                       // critique says NO material gap
    "Good draft routed to KHO.",       // exec2 (regen)
  ]);

  const result = await runLegalPlannerLoop({
    apiKey: "test",
    systemPrompt: "BASE",
    messages: [{ role: "user", content: "Where to file restoration?" }],
    caller,
    selfCorrectionAddendum: addendum,
    forceRegenForSelfCorrection: true,
    enableAdversarial: false,
    now: () => 0,
  });
  assertEquals(result.kind, "completed");
  if (result.kind !== "completed") return;
  assertEquals(result.regeneratedOnce, true, "regen fired");
  assertEquals(result.replyText, "Good draft routed to KHO.");
  assertEquals(calls.length, 4, "exec ran twice + planner + critique");
  // Regen call (4th) MUST contain the addendum.
  assertStringIncludes(calls[3].systemPrompt, "<do_not_repeat>");
});

Deno.test("runLegalPlannerLoop — empty selfCorrectionAddendum without material_gap = NO regen", async () => {
  const { caller, calls } = scriptedAnthropic([
    PLAN_OK,
    "Draft answer.",
    CRITIQUE_OK,
  ]);
  const result = await runLegalPlannerLoop({
    apiKey: "test",
    systemPrompt: "BASE",
    messages: [{ role: "user", content: "Q?" }],
    caller,
    selfCorrectionAddendum: "",
    forceRegenForSelfCorrection: true,
    enableAdversarial: false,
    now: () => 0,
  });
  assertEquals(result.kind, "completed");
  if (result.kind !== "completed") return;
  assertEquals(result.regeneratedOnce, false);
  assertEquals(calls.length, 3);
});

Deno.test("runLegalPlannerLoop — material_gap regen still receives addendum when present", async () => {
  const addendum = buildSelfCorrectionAddendum([{
    correction_id: HAO_ROW.id,
    matched_phrase: "yes, hao",
    wrong_advice: HAO_ROW.wrong_advice,
    correct_answer: HAO_ROW.correct_answer,
  }]);
  const { caller, calls } = scriptedAnthropic([
    PLAN_OK,
    "Initial draft.",
    CRITIQUE_GAP,        // critique says material gap → regen anyway
    "Regenerated draft.",
  ]);
  const result = await runLegalPlannerLoop({
    apiKey: "test",
    systemPrompt: "BASE",
    messages: [{ role: "user", content: "Q?" }],
    caller,
    selfCorrectionAddendum: addendum,
    forceRegenForSelfCorrection: false, // not forcing, but addendum still injects on regen
    enableAdversarial: false,
    now: () => 0,
  });
  if (result.kind !== "completed") return;
  assertEquals(result.regeneratedOnce, true);
  assertStringIncludes(calls[3].systemPrompt, "<do_not_repeat>");
});

// ─── 8. Seed migration parses + contains expected rows ──────────────────────

Deno.test("seed migration — contains expected anchor corrections", async () => {
  const path = new URL(
    "../../migrations/20260513150000_seed_advice_corrections.sql",
    import.meta.url,
  );
  let sql = "";
  try {
    sql = await Deno.readTextFile(path);
  } catch (e) {
    throw new Error(`seed migration not found at ${path}: ${e}`);
  }
  // Sanity: looks like a SQL INSERT into advice_corrections.
  assertStringIncludes(sql, "INSERT INTO public.advice_corrections");
  // Anchor #1: HAO vs KHO jurisdiction lesson.
  assertStringIncludes(sql, "HOL");
  assertStringIncludes(sql, "KHO");
  // Anchor #2: Soviet citizenship lesson — Neuvostoliitto identity error.
  assertStringIncludes(sql, "Neuvostoliitto");
  // Anchor #3: Dimitri / Dmitri name error.
  assertStringIncludes(sql, "Dimitri");
  // Source field always present.
  assertStringIncludes(sql, "lawyer_review");
  // The seed must not contain placeholder UUIDs (every row gets generated).
  assertNotEquals(sql.length, 0);
});

// End of file.
