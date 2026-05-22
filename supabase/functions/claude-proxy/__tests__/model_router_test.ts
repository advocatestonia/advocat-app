// Deno tests for claude-proxy smart model router (2026-05-11).
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-read --allow-net \
//     supabase/functions/claude-proxy/__tests__/model_router_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertNotEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  applyOverrideRules,
  classifyQuery,
  countStrongLegalKeywords,
  deriveRecommendation,
  estimateCostCents,
  extractUserText,
  formatTelemetry,
  HAIKU_MODEL,
  heuristicFallback,
  parseClassifierResponse,
  ROUTER_MAX_TOKENS,
  ROUTER_MODEL,
  SONNET_MODEL,
  type RouterClassification,
} from "../model_router.ts";

// ───────────────────────────────────────────────────────────────────────
// Routing matrix
// ───────────────────────────────────────────────────────────────────────

Deno.test("matrix: general_chat → Haiku + 200 max_tokens", () => {
  const rec = deriveRecommendation("general_chat", "simple");
  assertEquals(rec.model, "haiku");
  assertEquals(rec.max_tokens, 200);
});

Deno.test("matrix: off_topic → Haiku + 200 max_tokens (short refusal)", () => {
  const rec = deriveRecommendation("off_topic", "simple");
  assertEquals(rec.model, "haiku");
  assertEquals(rec.max_tokens, 200);
});

Deno.test("matrix: simple legal_question → Haiku + 2000 max_tokens", () => {
  const rec = deriveRecommendation("legal_question", "simple");
  assertEquals(rec.model, "haiku");
  assertEquals(rec.max_tokens, 2000);
});

Deno.test("matrix: medium legal_question → Haiku + 4096 max_tokens", () => {
  const rec = deriveRecommendation("legal_question", "medium");
  assertEquals(rec.model, "haiku");
  assertEquals(rec.max_tokens, 4096);
});

Deno.test("matrix: complex legal_question → Sonnet + 8000 max_tokens", () => {
  const rec = deriveRecommendation("legal_question", "complex");
  assertEquals(rec.model, "sonnet");
  assertEquals(rec.max_tokens, 8000);
});

Deno.test("matrix: clarification → Haiku default (2000)", () => {
  const rec = deriveRecommendation("clarification", "simple");
  assertEquals(rec.model, "haiku");
  assertEquals(rec.max_tokens, 2000);
});

// ───────────────────────────────────────────────────────────────────────
// Strong-legal keyword counter
// ───────────────────────────────────────────────────────────────────────

Deno.test("keyword counter: counts EN/RU/ET/FI hits", () => {
  assert(countStrongLegalKeywords("deportation appeal court") >= 3);
  assert(countStrongLegalKeywords("депортация апелляция иск") >= 3);
  assert(countStrongLegalKeywords("kohus kaebus väljasaatmine") >= 3);
  assert(countStrongLegalKeywords("tuomioistuin valituslupa kho") >= 3);
});

Deno.test("keyword counter: returns 0 for non-legal text", () => {
  assertEquals(countStrongLegalKeywords("hello, what's the weather like"), 0);
});

// ───────────────────────────────────────────────────────────────────────
// Classifier response parser
// ───────────────────────────────────────────────────────────────────────

Deno.test("parser: accepts plain JSON", () => {
  const r = parseClassifierResponse(
    '{"intent":"legal_question","complexity":"complex","language":"en"}',
  );
  assertEquals(r?.intent, "legal_question");
  assertEquals(r?.complexity, "complex");
  assertEquals(r?.language, "en");
});

Deno.test("parser: strips markdown code fences", () => {
  const r = parseClassifierResponse(
    '```json\n{"intent":"general_chat","complexity":"simple","language":"et"}\n```',
  );
  assertEquals(r?.intent, "general_chat");
});

Deno.test("parser: rejects invalid intent", () => {
  const r = parseClassifierResponse(
    '{"intent":"random","complexity":"simple","language":"en"}',
  );
  assertEquals(r, null);
});

Deno.test("parser: rejects missing fields", () => {
  const r = parseClassifierResponse('{"intent":"legal_question"}');
  assertEquals(r, null);
});

Deno.test("parser: rejects garbage", () => {
  assertEquals(parseClassifierResponse("not json"), null);
  assertEquals(parseClassifierResponse(""), null);
});

// ───────────────────────────────────────────────────────────────────────
// Override rules
// ───────────────────────────────────────────────────────────────────────

Deno.test("override: simple+3 strong keywords → upgrade to complex", () => {
  const cls = applyOverrideRules(
    { intent: "legal_question", complexity: "simple", language: "en" },
    "I have a deportation appeal and need to file a court complaint",
  );
  assertEquals(cls.complexity, "complex");
  assertEquals(cls.overridden, true);
});

Deno.test("override: general_chat + long+legal-keywords → legal_question", () => {
  const cls = applyOverrideRules(
    { intent: "general_chat", complexity: "simple", language: "ru" },
    "I got a deportation notice yesterday and I need to appeal it in court before the deadline next week",
  );
  assertEquals(cls.intent, "legal_question");
  assertEquals(cls.overridden, true);
});

Deno.test("override: pure greeting stays general_chat", () => {
  const cls = applyOverrideRules(
    { intent: "general_chat", complexity: "simple", language: "en" },
    "hello",
  );
  assertEquals(cls.intent, "general_chat");
  assertEquals(cls.overridden, false);
});

// ───────────────────────────────────────────────────────────────────────
// Heuristic fallback (used when classifier fails)
// ───────────────────────────────────────────────────────────────────────

Deno.test("fallback: 'hi' → general_chat", () => {
  const r = heuristicFallback("hi");
  assertEquals(r.intent, "general_chat");
  assertEquals(r.recommended_model, "haiku");
  assertEquals(r.source, "fallback");
});

Deno.test("fallback: short non-legal → simple legal_question (safe default)", () => {
  const r = heuristicFallback("can you help me");
  assertEquals(r.recommended_model, "haiku");
});

Deno.test("fallback: long message with 2+ legal kw → complex", () => {
  const r = heuristicFallback(
    "I received a deportation notice and want to file an appeal in court",
  );
  assertEquals(r.intent, "legal_question");
  assertEquals(r.complexity, "complex");
  assertEquals(r.recommended_model, "sonnet");
});

Deno.test("fallback: Russian Cyrillic detection", () => {
  const r = heuristicFallback("привет, у меня вопрос про депортацию");
  assertEquals(r.language, "ru");
});

// ───────────────────────────────────────────────────────────────────────
// extractUserText
// ───────────────────────────────────────────────────────────────────────

Deno.test("extractUserText: handles string content", () => {
  assertEquals(extractUserText("hello"), "hello");
});

Deno.test("extractUserText: handles block content", () => {
  assertEquals(
    extractUserText([{ type: "text", text: "hi" }, { type: "text", text: "there" }]),
    "hi there",
  );
});

Deno.test("extractUserText: handles non-string defensively", () => {
  assertEquals(extractUserText(42), "");
  assertEquals(extractUserText(null), "");
});

// ───────────────────────────────────────────────────────────────────────
// classifyQuery — integration with mocked Haiku
// ───────────────────────────────────────────────────────────────────────

function mockHaikuFetch(replyJson: string) {
  return (): Promise<Response> => {
    return Promise.resolve(
      new Response(
        JSON.stringify({
          content: [{ type: "text", text: replyJson }],
        }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      ),
    );
  };
}

Deno.test("classifyQuery: anon caller bypasses live classifier", async () => {
  let called = false;
  const fetchImpl = (): Promise<Response> => {
    called = true;
    return Promise.resolve(new Response("nope", { status: 500 }));
  };
  const result = await classifyQuery(
    [{ role: "user", content: "anything goes here" }],
    /* userIsAnon */ true,
    { apiKey: "fake", fetchImpl },
  );
  assertEquals(called, false);
  assertEquals(result.recommended_model, "haiku");
  assertEquals(result.recommended_max_tokens, 500);
  assertEquals(result.source, "override");
});

Deno.test("classifyQuery: 'tere' tiny-greeting bypasses classifier (cost savings)", async () => {
  let called = false;
  const fetchImpl = (): Promise<Response> => {
    called = true;
    return Promise.resolve(new Response("", { status: 500 }));
  };
  const result = await classifyQuery(
    [{ role: "user", content: "tere" }],
    false,
    { apiKey: "fake", fetchImpl },
  );
  assertEquals(called, false, "tiny greetings should not call the router");
  assertEquals(result.recommended_model, "haiku");
  assertEquals(result.intent, "general_chat");
});

Deno.test("classifyQuery: simple legal Q routes to Haiku via mocked classifier", async () => {
  const fetchImpl = mockHaikuFetch(
    '{"intent":"legal_question","complexity":"simple","language":"en"}',
  );
  const result = await classifyQuery(
    [{ role: "user", content: "what is the deadline to appeal a fine?" }],
    false,
    { apiKey: "fake", fetchImpl },
  );
  assertEquals(result.recommended_model, "haiku");
  assertEquals(result.recommended_max_tokens, 2000);
  assertEquals(result.source, "classifier");
});

Deno.test("classifyQuery: complex legal Q routes to Sonnet", async () => {
  const fetchImpl = mockHaikuFetch(
    '{"intent":"legal_question","complexity":"complex","language":"ru"}',
  );
  const result = await classifyQuery(
    [{
      role: "user",
      content:
        "Помогите мне составить договор аренды коммерческой недвижимости с учётом эстонского законодательства, защиты от незаконного выселения и cross-border налоговых последствий для нерезидента",
    }],
    false,
    { apiKey: "fake", fetchImpl },
  );
  assertEquals(result.recommended_model, "sonnet");
  assertEquals(result.recommended_max_tokens, 8000);
});

Deno.test("classifyQuery: HTTP 500 → falls back to heuristic, never throws", async () => {
  const fetchImpl = (): Promise<Response> =>
    Promise.resolve(new Response("server error", { status: 500 }));
  const result = await classifyQuery(
    [{ role: "user", content: "I have a court hearing about my deportation appeal next week and need to know what evidence to bring" }],
    false,
    { apiKey: "fake", fetchImpl },
  );
  assertEquals(result.source, "fallback");
  // 2+ strong-legal keywords (court, deportation, appeal) → fallback complex.
  assertEquals(result.recommended_model, "sonnet");
});

Deno.test("classifyQuery: malformed JSON from classifier → fallback", async () => {
  const fetchImpl = mockHaikuFetch("not json at all");
  const result = await classifyQuery(
    [{ role: "user", content: "hello there" }],
    false,
    { apiKey: "fake", fetchImpl },
  );
  assertEquals(result.source, "fallback");
});

Deno.test("classifyQuery: network timeout → fallback (never throws)", async () => {
  const fetchImpl = (): Promise<Response> => {
    return new Promise((_, reject) => {
      setTimeout(() => reject(new Error("network down")), 5);
    });
  };
  const result = await classifyQuery(
    [{ role: "user", content: "help me understand my rights" }],
    false,
    { apiKey: "fake", fetchImpl, timeoutMs: 50 },
  );
  assertEquals(result.source, "fallback");
});

Deno.test("classifyQuery: classifier-says-simple but 3+ keywords → forced complex", async () => {
  // Router under-classifies; override rule must catch it.
  const fetchImpl = mockHaikuFetch(
    '{"intent":"legal_question","complexity":"simple","language":"en"}',
  );
  const result = await classifyQuery(
    [{
      role: "user",
      content: "deportation court appeal subpoena custody",
    }],
    false,
    { apiKey: "fake", fetchImpl },
  );
  assertEquals(result.complexity, "complex");
  assertEquals(result.recommended_model, "sonnet");
  assertEquals(result.source, "override");
});

Deno.test("classifyQuery: empty messages → fallback (no throw)", async () => {
  const fetchImpl = mockHaikuFetch("ignored");
  const result = await classifyQuery([], false, { apiKey: "fake", fetchImpl });
  assertEquals(result.source, "fallback");
});

Deno.test("classifyQuery: last message is assistant → fallback (no router call)", async () => {
  let called = false;
  const fetchImpl = (): Promise<Response> => {
    called = true;
    return Promise.resolve(new Response("", { status: 200 }));
  };
  const result = await classifyQuery(
    [
      { role: "user", content: "hi" },
      { role: "assistant", content: "hi back" },
    ],
    false,
    { apiKey: "fake", fetchImpl },
  );
  assertEquals(called, false);
  assertEquals(result.source, "fallback");
});

// ───────────────────────────────────────────────────────────────────────
// Cost estimation + telemetry
// ───────────────────────────────────────────────────────────────────────

Deno.test("cost: Haiku is ~3x cheaper input than Sonnet", () => {
  const haikuCost = estimateCostCents(HAIKU_MODEL, 1000, 1000);
  const sonnetCost = estimateCostCents(SONNET_MODEL, 1000, 1000);
  assert(
    sonnetCost > haikuCost * 2.5,
    `Sonnet ${sonnetCost}¢ should be >2.5x Haiku ${haikuCost}¢`,
  );
});

Deno.test("telemetry: JSON-shaped log line", () => {
  const cls: RouterClassification = {
    intent: "legal_question",
    complexity: "simple",
    language: "et",
    recommended_model: "haiku",
    recommended_max_tokens: 2000,
    source: "classifier",
    latency_ms: 234,
  };
  const line = formatTelemetry(cls, HAIKU_MODEL, 0.5);
  const parsed = JSON.parse(line);
  assertEquals(parsed.event, "model_router");
  assertEquals(parsed.intent, "legal_question");
  assertEquals(parsed.chosen_model, HAIKU_MODEL);
  assertEquals(parsed.router_latency_ms, 234);
});

// ───────────────────────────────────────────────────────────────────────
// Integration: "tere" routes to Haiku end-to-end
// ───────────────────────────────────────────────────────────────────────

Deno.test("integration: 'tere' routes to Haiku (cost-savings invariant)", async () => {
  // No fetchImpl call expected — tiny-greeting bypass.
  const result = await classifyQuery(
    [{ role: "user", content: "tere" }],
    false,
    { apiKey: "fake" },
  );
  assertEquals(result.recommended_model, "haiku");
  assertNotEquals(result.recommended_model, "sonnet");
});

Deno.test("integration: complex contract Q routes to Sonnet via classifier", async () => {
  const fetchImpl = mockHaikuFetch(
    '{"intent":"legal_question","complexity":"complex","language":"et"}',
  );
  const result = await classifyQuery(
    [{
      role: "user",
      content:
        "Palun koosta mulle töölepingu lõpetamise hagi tööandja vastu, sealhulgas kahjuhüvitise nõue, viited töölepingu seaduse § 88-91, ja võimalik kassatsioonkaebus Riigikohtule",
    }],
    false,
    { apiKey: "fake", fetchImpl },
  );
  assertEquals(result.recommended_model, "sonnet");
  assertEquals(result.recommended_max_tokens, 8000);
});

// ───────────────────────────────────────────────────────────────────────
// Constants sanity
// ───────────────────────────────────────────────────────────────────────

Deno.test("constants: router uses Haiku 4.5 (cheap)", () => {
  assertEquals(ROUTER_MODEL, "claude-haiku-4-5-20251001");
});

Deno.test("constants: router output is tiny (≤100 tokens)", () => {
  assert(ROUTER_MAX_TOKENS <= 100, "router output should be tiny");
});

// ═════════════════════════════════════════════════════════════════════════
// FIX-WAVE 13 (2026-05-20) — signal-based selectModel() tests
// ═════════════════════════════════════════════════════════════════════════
//
// Covers the deterministic rule chain in `selectModel(signals)`:
//   FORCE_SONNET / FORCE_HAIKU env → advice_correction → halt_rail →
//   planner → long_contract → pro_with_chunks → adversarial → anon_default →
//   free_simple → pro_simple → default
//
// Tests use `Deno.env.set/delete` to flip the FORCE_* overrides. All other
// tests build a `RoutingSignals` baseline and toggle one bit at a time.
// ═════════════════════════════════════════════════════════════════════════

import {
  HAIKU_MODEL_ID,
  logRoutingDecision,
  modelIdFor,
  type RoutingLogContext,
  type RoutingSignals,
  selectModel,
  SONNET_MODEL_ID,
} from "../model_router.ts";

/** Baseline signals — everything off, anon=false, free tier, short input.
 *  Used as the starting point for each rule test so each test only toggles
 *  the one bit it cares about. */
function baseline(): RoutingSignals {
  return {
    isAnon: false,
    userTier: "free",
    inputTokens: 100,
    isLegalPlanner: false,
    isContractReview: false,
    haltRailTriggered: false,
    adviceCorrectionFired: false,
    adversarialFlag: false,
    hasCitationChunks: false,
  };
}

/** Guarantee the FORCE_* env vars are unset around a test body so we don't
 *  pollute siblings. Some test runners reuse the same OS env between
 *  Deno.test() bodies in the same process. */
function withCleanEnv<T>(fn: () => T): T {
  const sonnet = Deno.env.get("FORCE_SONNET_ALL");
  const haiku = Deno.env.get("FORCE_HAIKU_ALL");
  Deno.env.delete("FORCE_SONNET_ALL");
  Deno.env.delete("FORCE_HAIKU_ALL");
  try {
    return fn();
  } finally {
    if (sonnet !== undefined) Deno.env.set("FORCE_SONNET_ALL", sonnet);
    else Deno.env.delete("FORCE_SONNET_ALL");
    if (haiku !== undefined) Deno.env.set("FORCE_HAIKU_ALL", haiku);
    else Deno.env.delete("FORCE_HAIKU_ALL");
  }
}

// ───────────────────────────────────────────────────────────────────────
// Rule 1+2: FORCE_* env overrides (highest precedence)
// ───────────────────────────────────────────────────────────────────────

Deno.test("selectModel: FORCE_SONNET_ALL forces sonnet over every rule", () => {
  withCleanEnv(() => {
    Deno.env.set("FORCE_SONNET_ALL", "1");
    // Even with anon + free tier + tiny query → still Sonnet.
    const r = selectModel({ ...baseline(), isAnon: true });
    assertEquals(r.model, "sonnet");
    assertEquals(r.reason, "force_sonnet_env");
  });
});

Deno.test("selectModel: FORCE_HAIKU_ALL forces haiku even on halt-rail", () => {
  withCleanEnv(() => {
    Deno.env.set("FORCE_HAIKU_ALL", "true");
    // Halt-rail would normally upgrade to Sonnet; FORCE_HAIKU overrides.
    const r = selectModel({ ...baseline(), haltRailTriggered: true });
    assertEquals(r.model, "haiku");
    assertEquals(r.reason, "force_haiku_env");
  });
});

Deno.test("selectModel: FORCE_SONNET wins when both env flags are set", () => {
  withCleanEnv(() => {
    Deno.env.set("FORCE_SONNET_ALL", "1");
    Deno.env.set("FORCE_HAIKU_ALL", "1");
    const r = selectModel(baseline());
    assertEquals(r.model, "sonnet");
    assertEquals(r.reason, "force_sonnet_env");
  });
});

// ───────────────────────────────────────────────────────────────────────
// Rule 3: advice-correction fired → Sonnet
// ───────────────────────────────────────────────────────────────────────

Deno.test("selectModel: advice_correction fired → sonnet", () => {
  withCleanEnv(() => {
    const r = selectModel({ ...baseline(), adviceCorrectionFired: true });
    assertEquals(r.model, "sonnet");
    assertEquals(r.reason, "advice_correction");
  });
});

// ───────────────────────────────────────────────────────────────────────
// Rule 4: halt-rail triggered → Sonnet
// ───────────────────────────────────────────────────────────────────────

Deno.test("selectModel: halt-rail triggered → sonnet", () => {
  withCleanEnv(() => {
    const r = selectModel({ ...baseline(), haltRailTriggered: true });
    assertEquals(r.model, "sonnet");
    assertEquals(r.reason, "halt_rail");
  });
});

// ───────────────────────────────────────────────────────────────────────
// Rule 5: planner branch active → Sonnet
// ───────────────────────────────────────────────────────────────────────

Deno.test("selectModel: legal_planner active → sonnet", () => {
  withCleanEnv(() => {
    const r = selectModel({ ...baseline(), isLegalPlanner: true });
    assertEquals(r.model, "sonnet");
    assertEquals(r.reason, "planner");
  });
});

// ───────────────────────────────────────────────────────────────────────
// Rule 6: contract review / long context → Sonnet
// ───────────────────────────────────────────────────────────────────────

Deno.test("selectModel: contract_review mode → sonnet", () => {
  withCleanEnv(() => {
    const r = selectModel({
      ...baseline(),
      isContractReview: true,
      mode: "contract_review",
    });
    assertEquals(r.model, "sonnet");
    assertEquals(r.reason, "long_contract");
  });
});

Deno.test("selectModel: long context (>5K tokens) → sonnet", () => {
  withCleanEnv(() => {
    const r = selectModel({ ...baseline(), inputTokens: 8000 });
    assertEquals(r.model, "sonnet");
    assertEquals(r.reason, "long_contract");
  });
});

// ───────────────────────────────────────────────────────────────────────
// Rule 7: citation chunks for paid users → Sonnet
// ───────────────────────────────────────────────────────────────────────

Deno.test("selectModel: pro user + citation chunks → sonnet", () => {
  withCleanEnv(() => {
    const r = selectModel({
      ...baseline(),
      userTier: "pro",
      hasCitationChunks: true,
    });
    assertEquals(r.model, "sonnet");
    assertEquals(r.reason, "pro_with_chunks");
  });
});

Deno.test("selectModel: counsel user + citation chunks → sonnet", () => {
  withCleanEnv(() => {
    const r = selectModel({
      ...baseline(),
      userTier: "counsel",
      hasCitationChunks: true,
    });
    assertEquals(r.model, "sonnet");
    assertEquals(r.reason, "pro_with_chunks");
  });
});

Deno.test("selectModel: free user + citation chunks → NOT pro_with_chunks", () => {
  withCleanEnv(() => {
    const r = selectModel({
      ...baseline(),
      userTier: "free",
      hasCitationChunks: true,
    });
    // Free + chunks falls through to default (haiku) — they don't pay
    // for grounded Sonnet quality.
    assertEquals(r.model, "haiku");
    assertNotEquals(r.reason, "pro_with_chunks");
  });
});

// ───────────────────────────────────────────────────────────────────────
// Rule 8: adversarial pipeline → Sonnet
// ───────────────────────────────────────────────────────────────────────

Deno.test("selectModel: adversarialFlag → sonnet", () => {
  withCleanEnv(() => {
    const r = selectModel({ ...baseline(), adversarialFlag: true });
    assertEquals(r.model, "sonnet");
    assertEquals(r.reason, "adversarial");
  });
});

// ───────────────────────────────────────────────────────────────────────
// Rule 9: anon caller → Haiku
// ───────────────────────────────────────────────────────────────────────

Deno.test("selectModel: anon caller → haiku (anon_default)", () => {
  withCleanEnv(() => {
    const r = selectModel({ ...baseline(), isAnon: true });
    assertEquals(r.model, "haiku");
    assertEquals(r.reason, "anon_default");
  });
});

// ───────────────────────────────────────────────────────────────────────
// Rule 10: free + simple query → Haiku
// ───────────────────────────────────────────────────────────────────────

Deno.test("selectModel: free tier + short query → haiku (free_simple)", () => {
  withCleanEnv(() => {
    const r = selectModel({
      ...baseline(),
      userTier: "free",
      inputTokens: 200,
    });
    assertEquals(r.model, "haiku");
    assertEquals(r.reason, "free_simple");
  });
});

// ───────────────────────────────────────────────────────────────────────
// Rule 11: pro + simple, no citations → Haiku
// ───────────────────────────────────────────────────────────────────────

Deno.test("selectModel: pro user + simple query (no chunks) → haiku (pro_simple)", () => {
  withCleanEnv(() => {
    const r = selectModel({
      ...baseline(),
      userTier: "pro",
      inputTokens: 200,
      hasCitationChunks: false,
    });
    assertEquals(r.model, "haiku");
    assertEquals(r.reason, "pro_simple");
  });
});

// ───────────────────────────────────────────────────────────────────────
// Rule 12: default fallthrough → Haiku
// ───────────────────────────────────────────────────────────────────────

Deno.test("selectModel: default fallthrough → haiku", () => {
  withCleanEnv(() => {
    // Pro user, mid-length (≥500-token) query, no chunks, no special flags:
    // doesn't match free_simple or pro_simple (input too long), no other
    // rule applies → fall through to default.
    const r = selectModel({
      ...baseline(),
      userTier: "pro",
      inputTokens: 1500,
    });
    assertEquals(r.model, "haiku");
    assertEquals(r.reason, "default");
  });
});

// ───────────────────────────────────────────────────────────────────────
// Precedence: stacked signals — first matching rule wins
// ───────────────────────────────────────────────────────────────────────

Deno.test("selectModel: advice_correction beats halt_rail beats planner", () => {
  withCleanEnv(() => {
    const r = selectModel({
      ...baseline(),
      adviceCorrectionFired: true,
      haltRailTriggered: true,
      isLegalPlanner: true,
    });
    assertEquals(r.model, "sonnet");
    assertEquals(r.reason, "advice_correction");
  });
});

Deno.test("selectModel: anon + halt_rail → halt_rail wins (safety)", () => {
  withCleanEnv(() => {
    // Anon should NOT bypass halt-rail upgrade. Rule order puts halt above
    // anon_default for a reason: safety > cost.
    const r = selectModel({
      ...baseline(),
      isAnon: true,
      haltRailTriggered: true,
    });
    assertEquals(r.model, "sonnet");
    assertEquals(r.reason, "halt_rail");
  });
});

// ───────────────────────────────────────────────────────────────────────
// Constants & model-id mapping
// ───────────────────────────────────────────────────────────────────────

Deno.test("constants: HAIKU_MODEL_ID matches Haiku 4.5", () => {
  assertEquals(HAIKU_MODEL_ID, "claude-haiku-4-5-20251001");
});

Deno.test("constants: SONNET_MODEL_ID matches Sonnet 4 (current prod ID)", () => {
  // Must stay in lockstep with ALLOWED_MODELS in claude-proxy/index.ts.
  // Drift here = body.model rejected → request 400s.
  assertEquals(SONNET_MODEL_ID, "claude-sonnet-4-20250514");
});

Deno.test("modelIdFor: haiku → HAIKU_MODEL_ID, sonnet → SONNET_MODEL_ID", () => {
  assertEquals(modelIdFor("haiku"), HAIKU_MODEL_ID);
  assertEquals(modelIdFor("sonnet"), SONNET_MODEL_ID);
});

// ───────────────────────────────────────────────────────────────────────
// logRoutingDecision — structured JSON shape
// ───────────────────────────────────────────────────────────────────────

Deno.test("logRoutingDecision: emits stable JSON shape with model_id + reason", () => {
  // Silence console.log for the duration of the test so it doesn't pollute
  // test output. We re-read the returned line instead.
  const originalLog = console.log;
  console.log = () => {};
  try {
    const ctx: RoutingLogContext = {
      requestId: "req_123",
      userIdHash: "abc",
      userTier: "pro",
      inputTokens: 250,
      mode: "chat",
      route: "claude-proxy",
    };
    const line = logRoutingDecision(
      { model: "sonnet", reason: "halt_rail" },
      ctx,
    );
    const parsed = JSON.parse(line);
    assertEquals(parsed.event, "selectModel");
    assertEquals(parsed.model, "sonnet");
    assertEquals(parsed.model_id, SONNET_MODEL_ID);
    assertEquals(parsed.reason, "halt_rail");
    assertEquals(parsed.request_id, "req_123");
    assertEquals(parsed.user_id_hash, "abc");
    assertEquals(parsed.user_tier, "pro");
    assertEquals(parsed.input_tokens, 250);
    assertEquals(parsed.mode, "chat");
    assertEquals(parsed.route, "claude-proxy");
    assert(typeof parsed.ts === "string" && parsed.ts.includes("T"));
  } finally {
    console.log = originalLog;
  }
});

Deno.test("logRoutingDecision: omits undefined ctx fields cleanly", () => {
  const originalLog = console.log;
  console.log = () => {};
  try {
    const line = logRoutingDecision({ model: "haiku", reason: "default" });
    const parsed = JSON.parse(line);
    assertEquals(parsed.event, "selectModel");
    assertEquals(parsed.model, "haiku");
    assertEquals(parsed.model_id, HAIKU_MODEL_ID);
    assertEquals(parsed.reason, "default");
    assertEquals(parsed.request_id, undefined);
    assertEquals(parsed.user_tier, undefined);
  } finally {
    console.log = originalLog;
  }
});
