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
