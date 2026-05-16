// consilium_v3_test.ts — Deno TDD for the v3 adversarial consilium engine.
// -----------------------------------------------------------------------------
// The Anthropic caller is injected via the AnthropicCaller seam so every round
// can be scripted deterministically without a network round-trip.
//
// Run with:
//   deno test --allow-net=api.anthropic.com --allow-read --allow-env \
//     supabase/functions/_shared/__tests__/consilium_v3_test.ts
//
// Coverage:
//   • Round 2 fires and parses ≥3 attacks
//   • Round 3 fires for top-attacked roles
//   • Disagreement >20pp surfaces in synthesis user message
//   • Verifier catches missing probability range and triggers retry
//   • Verifier catches dropped disagreement
//   • Sycophancy phrases without nearby % rejected
//   • Banned phrases with nearby % accepted
//   • SSE events fire in correct order
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  type AnthropicCaller,
  type Attack,
  type AttackerSpec,
  buildAttackerUserMessage,
  buildDefenderUserMessage,
  buildSynthesisV3UserMessage,
  type ConsiliumV3SSEEvent,
  DEFAULT_ATTACKERS,
  detectDisagreement,
  DISAGREEMENT_THRESHOLD_PP,
  extractHighProbability,
  extractJson,
  parseAttackerOutput,
  parseDefenderOutput,
  pickTopAttackedRoles,
  type RevisedOpinion,
  runConsiliumV3,
  runLocalVerifierChecks,
  runRound2Adversarial,
  runRound3Defense,
  runVerifier,
} from "../consilium_v3.ts";

// ─── Test helpers ────────────────────────────────────────────────────────────

interface ScriptedCall {
  /** Substring or "*" to match the system prompt. */
  match: string | "*";
  response: string;
}

/** Build a deterministic caller. Each call returns the first response whose
 *  match-substring appears in the system prompt. Streaming caller chunks the
 *  response into 8-char deltas. */
function makeCaller(scripts: ScriptedCall[]): AnthropicCaller & {
  log: Array<{ system: string; userMessage: string; model: string }>;
} {
  const log: Array<{ system: string; userMessage: string; model: string }> = [];
  const used = new Set<number>();
  const find = (system: string): string => {
    for (let i = 0; i < scripts.length; i++) {
      if (used.has(i)) continue;
      const s = scripts[i];
      if (s.match === "*" || system.includes(s.match)) {
        used.add(i);
        return s.response;
      }
    }
    // Fall back to wildcard scripts even if used.
    for (let i = 0; i < scripts.length; i++) {
      if (scripts[i].match === "*") return scripts[i].response;
    }
    throw new Error(
      `No scripted response matched for system: ${system.slice(0, 120)}…`,
    );
  };
  return {
    log,
    async blocking(opts) {
      log.push({
        system: opts.system,
        userMessage: opts.userMessage,
        model: opts.model,
      });
      return find(opts.system);
    },
    async streaming(opts) {
      log.push({
        system: opts.system,
        userMessage: opts.userMessage,
        model: opts.model,
      });
      const text = find(opts.system);
      // Emit in 16-char chunks to mimic streaming.
      for (let i = 0; i < text.length; i += 16) {
        opts.onDelta(text.slice(i, i + 16));
      }
      return text;
    },
  };
}

// ─── Pure helper tests ───────────────────────────────────────────────────────

Deno.test("extractJson — strips markdown fences", () => {
  const raw = '```json\n{"a": 1, "b": 2}\n```';
  const out = extractJson(raw);
  assertEquals(out, { a: 1, b: 2 });
});

Deno.test("extractJson — finds first balanced object", () => {
  const raw = 'Some preamble {"x": 5} and more text';
  const out = extractJson(raw);
  assertEquals(out, { x: 5 });
});

Deno.test("extractJson — returns null on garbage", () => {
  assertEquals(extractJson("no json here"), null);
});

Deno.test("parseAttackerOutput — accepts valid 3-attack JSON", () => {
  const raw = JSON.stringify({
    attacks: [
      {
        target_role: "Реалист",
        weak_point: "no base rate",
        counter_evidence: "KHO 2024 stats show 8% not 25%",
      },
      {
        target_role: "Процессуалист",
        weak_point: "ignores §115",
        counter_evidence: "HOL §115 narrows §114 scope",
      },
      {
        target_role: "Материальный юрист",
        weak_point: "wrong directive",
        counter_evidence: "Directive 2008/115 Art. 5 controls",
      },
    ],
  });
  const out = parseAttackerOutput("Devil's Advocate", raw);
  assertEquals(out.length, 3);
  assertEquals(out[0].attacker, "Devil's Advocate");
  assertEquals(out[0].target_role, "Реалист");
});

Deno.test("parseAttackerOutput — drops malformed entries but keeps valid", () => {
  const raw = JSON.stringify({
    attacks: [
      { target_role: "X", weak_point: "y", counter_evidence: "z" },
      { target_role: "" }, // invalid (empty target)
      "garbage",
      { target_role: "B", weak_point: "w", counter_evidence: "e" },
    ],
  });
  const out = parseAttackerOutput("A", raw);
  assertEquals(out.length, 2);
});

Deno.test("parseAttackerOutput — returns [] on no JSON", () => {
  assertEquals(parseAttackerOutput("A", "I refuse to attack."), []);
});

Deno.test("parseDefenderOutput — accepts valid stance", () => {
  const raw = JSON.stringify({
    stance: "revise",
    new_opinion: "After the attack I revise to 12%.",
  });
  const out = parseDefenderOutput("Реалист", raw);
  assert(out);
  assertEquals(out!.stance, "revise");
  assertStringIncludes(out!.new_opinion, "12%");
});

Deno.test("parseDefenderOutput — rejects invalid stance", () => {
  const raw = JSON.stringify({
    stance: "ignore",
    new_opinion: "lol",
  });
  assertEquals(parseDefenderOutput("X", raw), null);
});

Deno.test("extractHighProbability — handles ranges and singles", () => {
  assertEquals(extractHighProbability("Шанс 15–25%."), 25);
  assertEquals(extractHighProbability("около 30 %"), 30);
  assertEquals(extractHighProbability("no number"), null);
});

Deno.test("detectDisagreement — returns null for narrow spread", () => {
  const out = detectDisagreement([
    { name: "A", opinion: "20-30%" },
    { name: "B", opinion: "25-35%" },
  ]);
  assertEquals(out, null);
});

Deno.test("detectDisagreement — finds >20pp gap", () => {
  const out = detectDisagreement([
    { name: "Реалист", opinion: "ставка 10-15%" },
    { name: "Поисковик", opinion: "альтернатива 50-60%" },
  ]);
  assert(out);
  // Higher bound: 15 vs 60 → 45pp > 20pp.
  assertEquals(out!.a.prob, 15);
  assertEquals(out!.b.prob, 60);
});

Deno.test("pickTopAttackedRoles — sorts by attack count", () => {
  const attacks: Attack[] = [
    { attacker: "A", target_role: "X", weak_point: "1", counter_evidence: "e" },
    { attacker: "A", target_role: "Y", weak_point: "2", counter_evidence: "e" },
    { attacker: "B", target_role: "Y", weak_point: "3", counter_evidence: "e" },
    { attacker: "B", target_role: "Y", weak_point: "4", counter_evidence: "e" },
    { attacker: "C", target_role: "Z", weak_point: "5", counter_evidence: "e" },
  ];
  const out = pickTopAttackedRoles(attacks, 3);
  assertEquals(out[0], "Y"); // 3 attacks
  // X and Z both have 1; order between them is implementation-defined.
  assert(out.includes("X"));
  assert(out.includes("Z"));
});

// ─── runLocalVerifierChecks ───────────────────────────────────────────────────

Deno.test("runLocalVerifierChecks — passes on probability + no disagreement", () => {
  const out = runLocalVerifierChecks({
    synthesis: "Реалистичный шанс: 15-25%. Конкретные шаги: …",
    disagreement: null,
    attacks: [],
    round3: [],
  });
  assertEquals(out.ok, true);
});

Deno.test("runLocalVerifierChecks — fails on missing probability", () => {
  const out = runLocalVerifierChecks({
    synthesis: "У вас хорошая ситуация, обращайтесь к юристу.",
    disagreement: null,
    attacks: [],
    round3: [],
  });
  assertEquals(out.ok, false);
  assertStringIncludes(out.reason, "probability");
  assert(out.retryHint);
});

Deno.test("runLocalVerifierChecks — fails when disagreement dropped", () => {
  const out = runLocalVerifierChecks({
    synthesis: "Шанс примерно 17%. Шаги: 1) …",
    disagreement: {
      a: { name: "Реалист", prob: 10 },
      b: { name: "Поисковик", prob: 50 },
    },
    attacks: [],
    round3: [],
  });
  assertEquals(out.ok, false);
  assertStringIncludes(out.reason, "disagreement");
  assert(out.retryHint);
  assertStringIncludes(out.retryHint!, "10%");
  assertStringIncludes(out.retryHint!, "50%");
});

Deno.test("runLocalVerifierChecks — passes when disagreement surfaced", () => {
  const out = runLocalVerifierChecks({
    synthesis:
      "Эксперты расходятся: Реалист даёт 10%, Поисковик 50%. Рекомендация: попробовать альтернативу.",
    disagreement: {
      a: { name: "Реалист", prob: 10 },
      b: { name: "Поисковик", prob: 50 },
    },
    attacks: [],
    round3: [],
  });
  assertEquals(out.ok, true);
});

Deno.test("runLocalVerifierChecks — rejects sycophancy without number", () => {
  const out = runLocalVerifierChecks({
    synthesis: "У вас сильное дело, всё будет хорошо. Шаги: 1) подайте заявление.",
    disagreement: null,
    attacks: [],
    round3: [],
  });
  // Phrase "сильное дело" without nearby % must fail. But the regex needs
  // *no* probability anywhere in synthesis to fail rule 1 first; here we have
  // none, so it actually fails rule 1. Let's add a number elsewhere far away.
  assertEquals(out.ok, false);
});

Deno.test("runLocalVerifierChecks — rejects sycophancy when % is far away", () => {
  const out = runLocalVerifierChecks({
    synthesis:
      "У вас сильное дело. " + // banned phrase here
      "X".repeat(200) + // 200 chars of padding so % is >80 chars away
      "Шанс: 25%.",
    disagreement: null,
    attacks: [],
    round3: [],
  });
  assertEquals(out.ok, false);
  assertStringIncludes(out.reason, "sycophancy");
});

Deno.test("runLocalVerifierChecks — accepts banned phrase if % nearby", () => {
  const out = runLocalVerifierChecks({
    synthesis: "У вас сильное дело — реалистичный шанс 35-45%. Шаги: …",
    disagreement: null,
    attacks: [],
    round3: [],
  });
  assertEquals(out.ok, true);
});

// ─── runRound2Adversarial integration ────────────────────────────────────────

Deno.test("runRound2Adversarial — collects attacks from 3 attackers", async () => {
  const attackJson = (target: string, n: number) =>
    JSON.stringify({
      attacks: Array.from({ length: n }, (_, i) => ({
        target_role: target,
        weak_point: `wp${i}`,
        counter_evidence: `ce${i}`,
      })),
    });

  const caller = makeCaller([
    { match: "Devil's Advocate", response: attackJson("Реалист", 3) },
    { match: "атакующий по нормам", response: attackJson("Процессуалист", 3) },
    {
      match: "атакующий по вероятностям",
      response: attackJson("Реалист", 3),
    },
  ]);

  const captured: Attack[] = [];
  const result = await runRound2Adversarial({
    originalQuestion: "Q",
    round1: [
      { name: "Реалист", opinion: "10-15%" },
      { name: "Процессуалист", opinion: "§114 ok" },
    ],
    caller,
    onAttack: (a) => captured.push(a),
  });

  assertEquals(result.length, 9);
  assertEquals(captured.length, 9);
  assertEquals(caller.log.length, 3);
});

Deno.test("runRound2Adversarial — empty result on all-failed parses", async () => {
  const caller = makeCaller([
    { match: "*", response: "I refuse to attack." },
  ]);
  const result = await runRound2Adversarial({
    originalQuestion: "Q",
    round1: [{ name: "R", opinion: "x" }],
    caller,
  });
  assertEquals(result.length, 0);
});

// ─── runRound3Defense integration ────────────────────────────────────────────

Deno.test("runRound3Defense — defenders revise based on attacks", async () => {
  const attacks: Attack[] = [
    {
      attacker: "Devil's Advocate",
      target_role: "Реалист",
      weak_point: "no base rate",
      counter_evidence: "KHO stats: 8%",
    },
    {
      attacker: "Devil's Advocate",
      target_role: "Реалист",
      weak_point: "ignores §115",
      counter_evidence: "§115 narrows",
    },
  ];

  const caller = makeCaller([
    {
      match: "REVISE",
      response: JSON.stringify({
        stance: "revise",
        new_opinion: "Updated estimate is 8-12% based on KHO stats.",
      }),
    },
  ]);

  const captured: RevisedOpinion[] = [];
  const result = await runRound3Defense({
    originalQuestion: "Q",
    round1: [
      { name: "Реалист", opinion: "I estimate 20-25%." },
      { name: "Other", opinion: "x" },
    ],
    attacks,
    caller,
    onDefense: (d) => captured.push(d),
  });

  assertEquals(result.length, 1);
  assertEquals(result[0].name, "Реалист");
  assertEquals(result[0].stance, "revise");
  assertEquals(captured.length, 1);
});

Deno.test("runRound3Defense — no attacks → no defenders run", async () => {
  const caller = makeCaller([]);
  const result = await runRound3Defense({
    originalQuestion: "Q",
    round1: [{ name: "R", opinion: "x" }],
    attacks: [],
    caller,
  });
  assertEquals(result, []);
  assertEquals(caller.log.length, 0);
});

// ─── buildSynthesisV3UserMessage ─────────────────────────────────────────────

Deno.test("buildSynthesisV3UserMessage — surfaces disagreement block", () => {
  const msg = buildSynthesisV3UserMessage({
    originalQuestion: "Q",
    round1: [
      { name: "A", opinion: "10-15%" },
      { name: "B", opinion: "50-60%" },
    ],
    attacks: [],
    round3: [],
    deadEnd: false,
    disagreement: {
      a: { name: "A", prob: 15 },
      b: { name: "B", prob: 60 },
    },
  });
  assertStringIncludes(msg, "ОБНАРУЖЕНО РАЗНОГЛАСИЕ");
  assertStringIncludes(msg, "A даёт 15%");
  assertStringIncludes(msg, "B даёт 60%");
});

Deno.test("buildSynthesisV3UserMessage — adds retry hint when given", () => {
  const msg = buildSynthesisV3UserMessage({
    originalQuestion: "Q",
    round1: [],
    attacks: [],
    round3: [],
    deadEnd: false,
    disagreement: null,
    retryHint: "Add probability range",
  });
  assertStringIncludes(msg, "VERIFIER");
  assertStringIncludes(msg, "Add probability range");
});

// ─── Verifier integration ────────────────────────────────────────────────────

Deno.test("runVerifier — local check rejects before Haiku is called", async () => {
  let haikuCalled = false;
  const caller: AnthropicCaller = {
    async blocking(_opts) {
      haikuCalled = true;
      return JSON.stringify({ ok: true, reason: "ok" });
    },
    async streaming() {
      throw new Error("not used");
    },
  };
  const out = await runVerifier({
    synthesis: "No probability anywhere.",
    disagreement: null,
    attacks: [],
    round3: [],
    caller,
  });
  assertEquals(out.ok, false);
  assertEquals(haikuCalled, false);
});

Deno.test("runVerifier — Haiku ok response passes through", async () => {
  const caller = makeCaller([
    { match: "*", response: JSON.stringify({ ok: true, reason: "looks good" }) },
  ]);
  const out = await runVerifier({
    synthesis: "Шанс 15-25%. Шаги: …",
    disagreement: null,
    attacks: [],
    round3: [],
    caller,
  });
  assertEquals(out.ok, true);
});

Deno.test("runVerifier — Haiku error allowed (tolerant)", async () => {
  const caller: AnthropicCaller = {
    async blocking() {
      throw new Error("Anthropic 503");
    },
    async streaming() {
      throw new Error("not used");
    },
  };
  const out = await runVerifier({
    synthesis: "Шанс 15-25%.",
    disagreement: null,
    attacks: [],
    round3: [],
    caller,
  });
  // Tolerant: error → ok:true so consilium doesn't loop on flaky Haiku.
  assertEquals(out.ok, true);
});

// ─── Full runConsiliumV3 — end-to-end SSE order ──────────────────────────────

Deno.test("runConsiliumV3 — full SSE event order, no retry", async () => {
  // Build a scripted caller that handles all 4 model interactions:
  //   1. Round 2 — 3 attackers
  //   2. Round 3 — defender(s)
  //   3. Synthesis streaming
  //   4. Verifier
  // Note: Round 1 uses runRole() which calls the REAL Anthropic API via
  // callAnthropicBlocking. We don't have a seam there, so this test stubs
  // global fetch to return canned role opinions.

  const scriptedFetchResponses = new Map<string, string>();

  // Set up Round 1 responses via fetch stub.
  const originalFetch = globalThis.fetch;
  globalThis.fetch = (input: Request | URL | string, init?: RequestInit) => {
    // All Round 1 calls go through callAnthropicBlocking → fetch.
    const body = typeof init?.body === "string" ? init.body : "";
    // Distinguish role by inspecting the system prompt in the body.
    let opinion = "Generic opinion 25%.";
    if (body.includes("Реалист")) opinion = "Оценка: 10-15%."; // low
    if (body.includes("Поисковик альтернатив")) {
      opinion = "Альтернатива: 50-60%."; // high → disagreement
    }
    if (body.includes("Дедлайн-стратег")) opinion = "Дедлайн через 21 день.";
    if (body.includes("Risk Auditor")) opinion = "Упущено: §115.";
    if (body.includes("Процессуалист")) opinion = "§114 HOL применим.";
    if (body.includes("Материальный")) {
      opinion = "Сильная норма: [[ref:hol:114]].";
    }
    return Promise.resolve(
      new Response(
        JSON.stringify({
          content: [{ type: "text", text: opinion }],
        }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      ),
    );
  };
  void scriptedFetchResponses;

  try {
    const caller = makeCaller([
      // Round 2 — 3 attackers, each with valid JSON. Devil's Advocate hits
      // Реалист twice so it becomes most-attacked → enters Round 3.
      {
        match: "Devil's Advocate",
        response: JSON.stringify({
          attacks: [
            {
              target_role: "Реалист",
              weak_point: "no base rate",
              counter_evidence: "KHO 2024: 8%",
            },
            {
              target_role: "Реалист",
              weak_point: "ignores variance",
              counter_evidence: "variance 5pp std",
            },
            {
              target_role: "Процессуалист",
              weak_point: "no §115 check",
              counter_evidence: "§115 narrows",
            },
          ],
        }),
      },
      {
        match: "атакующий по нормам",
        response: JSON.stringify({
          attacks: [
            {
              target_role: "Реалист",
              weak_point: "wrong base rate",
              counter_evidence: "stats show 5%",
            },
            {
              target_role: "Материальный юрист",
              weak_point: "wrong norm",
              counter_evidence: "should cite §116",
            },
            {
              target_role: "Процессуалист",
              weak_point: "missed dir",
              counter_evidence: "Dir 2008/115",
            },
          ],
        }),
      },
      {
        match: "атакующий по вероятностям",
        response: JSON.stringify({
          attacks: [
            {
              target_role: "Реалист",
              weak_point: "too optimistic",
              counter_evidence: "real rate 5-8%",
            },
            {
              target_role: "Поисковик альтернатив",
              weak_point: "too optimistic alt",
              counter_evidence: "alt also <30%",
            },
            {
              target_role: "Дедлайн-стратег",
              weak_point: "too tight",
              counter_evidence: "need 28d not 21d",
            },
          ],
        }),
      },
      // Round 3 — defenders. All three "defend" stance with NO numeric change,
      // so disagreement detection still sees Реалист=15% vs Поисковик=60%.
      // We supply 4 scripts in case top-attacked picks 3 distinct roles
      // (the find() helper consumes one REVISE script per defender call).
      {
        match: "REVISE",
        response: JSON.stringify({
          stance: "defend",
          new_opinion: "Stand by my analysis with reinforced citation.",
        }),
      },
      {
        match: "REVISE",
        response: JSON.stringify({
          stance: "defend",
          new_opinion: "§114 still controls, §115 doesn't apply here.",
        }),
      },
      {
        match: "REVISE",
        response: JSON.stringify({
          stance: "defend",
          new_opinion: "My norm citation remains correct.",
        }),
      },
      // Synthesis — must include the disagreement (Реалист=15% from Round 1
      // since "defend" preserves it, Поисковик=60%). Local verifier checks
      // for substring "15%" and "60%" in synthesis.
      {
        match: "председатель адверсариального",
        response:
          "Эксперты расходятся: Реалист даёт верхнюю границу 15%, Поисковик альтернатив 60%. Рекомендация: попробовать альтернативу — шанс ~50%.",
      },
      // Verifier — ok.
      {
        match: "verifier",
        response: JSON.stringify({ ok: true, reason: "good" }),
      },
    ]);

    const events: ConsiliumV3SSEEvent[] = [];
    const synthesis = await runConsiliumV3({
      userMessage: "Test question",
      systemPrompt: "Base prompt",
      ragContext: "",
      caseContext: "",
      anthropicApiKey: "test-key",
      onEvent: (e) => events.push(e),
      caller,
    });

    assert(synthesis.length > 0);
    // Check event order has all required milestones.
    const types = events.map((e) => e.type);
    assert(types.includes("consilium_start"));
    assert(types.includes("round_1_done"));
    assert(types.includes("round_2_done"));
    assert(types.includes("round_3_done"));
    assert(types.includes("synthesis_start"));
    assert(types.includes("synthesis_done"));
    assert(types.includes("done"));

    // Must have at least one round_2_attack event.
    const attackEvents = events.filter((e) => e.type === "round_2_attack");
    assert(
      attackEvents.length >= 3,
      `expected ≥3 attack events, got ${attackEvents.length}`,
    );

    // Must have at least one round_3_defense event.
    const defenseEvents = events.filter((e) => e.type === "round_3_defense");
    assert(
      defenseEvents.length >= 1,
      `expected ≥1 defense, got ${defenseEvents.length}`,
    );

    // synthesis_done must come AFTER all round_3_defense events.
    const lastDefenseIdx = events.reduce(
      (acc, e, i) => (e.type === "round_3_defense" ? i : acc),
      -1,
    );
    const synthDoneIdx = events.findIndex((e) => e.type === "synthesis_done");
    assert(synthDoneIdx > lastDefenseIdx);

    // Verifier must have passed (ok event), no retry.
    assert(
      events.some((e) => e.type === "verifier_ok"),
      "expected verifier_ok event",
    );
    assert(
      !events.some((e) => e.type === "verifier_retry"),
      "expected no verifier_retry",
    );
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("runConsiliumV3 — verifier failure triggers single retry", async () => {
  // Set up Round 1 stub.
  const originalFetch = globalThis.fetch;
  globalThis.fetch = (_input: Request | URL | string, init?: RequestInit) => {
    const body = typeof init?.body === "string" ? init.body : "";
    let opinion = "Generic 20%.";
    if (body.includes("Реалист")) opinion = "Шанс 20-25%.";
    return Promise.resolve(
      new Response(
        JSON.stringify({
          content: [{ type: "text", text: opinion }],
        }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      ),
    );
  };

  try {
    let synthesisCallCount = 0;
    const caller: AnthropicCaller = {
      log: [] as Array<{ system: string }>,
      async blocking(opts) {
        // Attackers — return empty (no attacks)
        if (opts.system.includes("Devil's Advocate")) {
          return JSON.stringify({ attacks: [] });
        }
        if (opts.system.includes("атакующий")) {
          return JSON.stringify({ attacks: [] });
        }
        // Verifier — semantic check. Local check will fail anyway on retry 0
        // because we return synthesis without probability range. So this won't
        // be reached on round 0. On round 1, we'll have a corrected synthesis.
        if (opts.system.includes("verifier")) {
          return JSON.stringify({ ok: true, reason: "good" });
        }
        // Blocking synthesis fallback — not used.
        return "";
      },
      async streaming(opts) {
        synthesisCallCount++;
        const text = synthesisCallCount === 1
          ? "Без процентов." // Triggers local-check failure.
          : "Шанс 15-25%. Шаги: …"; // Passes on retry.
        for (let i = 0; i < text.length; i += 16) {
          opts.onDelta(text.slice(i, i + 16));
        }
        return text;
      },
    } as AnthropicCaller;

    const events: ConsiliumV3SSEEvent[] = [];
    const result = await runConsiliumV3({
      userMessage: "Test",
      systemPrompt: "",
      ragContext: "",
      caseContext: "",
      anthropicApiKey: "k",
      onEvent: (e) => events.push(e),
      caller,
    });

    assertEquals(synthesisCallCount, 2, "expected one retry");
    assertStringIncludes(result, "15-25%");
    assert(events.some((e) => e.type === "verifier_retry"));
    assert(events.some((e) => e.type === "verifier_ok"));
  } finally {
    globalThis.fetch = originalFetch;
  }
});

// ─── buildAttackerUserMessage / buildDefenderUserMessage ─────────────────────

Deno.test("buildAttackerUserMessage — embeds all Round-1 opinions", () => {
  const msg = buildAttackerUserMessage("What's my chance?", [
    { name: "A", opinion: "10%" },
    { name: "B", opinion: "50%" },
  ]);
  assertStringIncludes(msg, "What's my chance?");
  assertStringIncludes(msg, "### A");
  assertStringIncludes(msg, "### B");
  assertStringIncludes(msg, "Минимум 3 атаки");
});

Deno.test("buildDefenderUserMessage — embeds attacker counter-evidence", () => {
  const msg = buildDefenderUserMessage("Q", "Реалист", "I say 25%.", [
    {
      attacker: "Devil's Advocate",
      target_role: "Реалист",
      weak_point: "no base rate",
      counter_evidence: "KHO says 8%",
    },
  ]);
  assertStringIncludes(msg, "Devil's Advocate");
  assertStringIncludes(msg, "no base rate");
  assertStringIncludes(msg, "KHO says 8%");
  assertStringIncludes(msg, "REVISE или CONCEDE");
});

// ─── DEFAULT_ATTACKERS shape ─────────────────────────────────────────────────

Deno.test("DEFAULT_ATTACKERS — exactly 3, distinct names", () => {
  assertEquals(DEFAULT_ATTACKERS.length, 3);
  const names = new Set(DEFAULT_ATTACKERS.map((a) => a.name));
  assertEquals(names.size, 3);
  assert(DEFAULT_ATTACKERS.every((a) => a.systemPersona.length > 50));
});

Deno.test("DISAGREEMENT_THRESHOLD_PP — 20pp constant", () => {
  assertEquals(DISAGREEMENT_THRESHOLD_PP, 20);
});

// Re-export check — make sure callers can import AttackerSpec type.
const _typeCheck: AttackerSpec = { name: "x", systemPersona: "y" };
void _typeCheck;
