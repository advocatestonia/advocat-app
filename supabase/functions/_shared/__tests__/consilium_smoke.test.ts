// consilium_smoke.test.ts — Phase 1 end-to-end smoke test.
// -----------------------------------------------------------------------------
// Validates the FULL consilium dispatch pipeline that the claude-proxy edge
// function will exercise on every Pro-tier legal turn:
//
//   1. lawyer_router picks the right specialised lawyers for a query.
//   2. consilium_lawyer_bridge converts the decision to ConsiliumRole[].
//   3. runConsilium emits the SSE events the Flutter UI subscribes to
//      (consilium_start → role_done × N → role_opinion × N → synthesis_start
//      → delta × M → done).
//   4. Anon callers are blocked at the integration boundary so the bridge
//      cost is never paid for free traffic.
//
// All LLM calls are stubbed via globalThis.fetch — zero network, fully
// deterministic, runs in <1s.
//
// Run with:
//   deno test --allow-env --allow-net=api.anthropic.com \
//     supabase/functions/_shared/__tests__/consilium_smoke.test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertExists,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  type ConsiliumSSEEvent,
  runConsilium,
} from "../consilium.ts";
import {
  ALL_LAWYERS,
  isLawyerRouterEnabled,
  LAWYER_ROUTER_FLAG_ENV,
  selectRolesFromLawyerDept,
} from "../consilium_lawyer_bridge.ts";
import { routeToLawyers } from "../lawyer_router.ts";

// ─── fetch stub helper ───────────────────────────────────────────────────────

/**
 * Install a stub `globalThis.fetch` that responds to Anthropic message calls.
 *
 * - For NON-streaming POSTs (role calls): returns a JSON envelope shaped like
 *   Anthropic's `/v1/messages` response with a single text block.
 * - For STREAMING POSTs (synthesis): returns an SSE body with two
 *   `content_block_delta` frames followed by `[DONE]`.
 *
 * The `pickOpinion` callback receives the parsed body so the test can
 * tailor the response per role (system prompt substring matching).
 */
function installFetchStub(
  pickOpinion: (body: string) => string,
  synthesisText: string = "Синтез: основной путь даёт 20%. Шаг 1: подать valituslupa.",
): () => void {
  const original = globalThis.fetch;
  let stubCalls = 0;

  globalThis.fetch = ((
    _input: Request | URL | string,
    init?: RequestInit,
  ): Promise<Response> => {
    stubCalls++;
    const body = typeof init?.body === "string" ? init.body : "";
    const wantsStream = body.includes('"stream":true');

    if (wantsStream) {
      // Synthesis path — return SSE body with text_delta frames.
      const frame1 =
        `data: ${JSON.stringify({
          type: "content_block_delta",
          delta: { type: "text_delta", text: synthesisText.slice(0, 32) },
        })}\n\n`;
      const frame2 =
        `data: ${JSON.stringify({
          type: "content_block_delta",
          delta: { type: "text_delta", text: synthesisText.slice(32) },
        })}\n\n`;
      const sseBody = frame1 + frame2 + "data: [DONE]\n\n";
      return Promise.resolve(
        new Response(sseBody, {
          status: 200,
          headers: { "Content-Type": "text/event-stream" },
        }),
      );
    }

    const opinion = pickOpinion(body);
    return Promise.resolve(
      new Response(
        JSON.stringify({
          content: [{ type: "text", text: opinion }],
        }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      ),
    );
  }) as typeof fetch;

  return () => {
    void stubCalls;
    globalThis.fetch = original;
  };
}

// ─── Scenario 1: roster selection (lawyer_router) ────────────────────────────

Deno.test(
  "smoke 1 — FI immigration query selects asianajaja + immigration + strategist",
  () => {
    const query =
      "Mind on käännytetty Soomest, KHO andis valituslupa-hakemus tagasi, mida teha?";
    const decision = routeToLawyers(query, "ru", {
      jurisdiction: "FI",
      caseType: "immigration",
      complexity: 8,
      hasHardDeadline: true,
    });

    const ids = new Set(decision.agents.map((a) => a.id));

    assert(
      ids.has("senior-asianajaja"),
      `expected senior-asianajaja, got [${[...ids].join(",")}]`,
    );
    assert(
      ids.has("immigration-lawyer"),
      `expected immigration-lawyer, got [${[...ids].join(",")}]`,
    );
    assert(ids.has("strategist"), "strategist must always appear");
    assert(decision.highStakes, "FI deportation must be high-stakes");
    assert(
      decision.agents.length >= 3 && decision.agents.length <= 5,
      `roster size ${decision.agents.length} out of 3-5 range`,
    );
  },
);

Deno.test(
  "smoke 1b — bridge returns ConsiliumRole[] with correct ids + LawyerAgent passthrough",
  () => {
    const result = selectRolesFromLawyerDept(
      "Mind on käännytetty Soomest, mida teha?",
      { jurisdiction: "FI", caseType: "immigration", language: "ru" },
    );

    assertExists(result, "bridge must produce a roster for FI immigration");
    assert(result.roles.length >= 3, "≥3 roles");
    assert(result.agents.length === result.roles.length);
    // Each ConsiliumRole carries the agent name + a non-empty compiled focus.
    for (const r of result.roles) {
      assert(r.name.length > 0);
      assert(r.focus.length > 100, `role ${r.name} has empty focus`);
      assertEquals(r.isCompiled, true);
    }
    // Trace must mention the general counsel pick.
    assert(
      result.trace.some((t) => t.startsWith("general_counsel=")),
      "trace must include general_counsel pick",
    );
  },
);

// ─── Scenario 2 + 3: full SSE event sequence + payload shape ─────────────────

Deno.test(
  "smoke 2+3 — runConsilium emits full event sequence with correct payloads",
  async () => {
    const restore = installFetchStub((body) => {
      // Match by role focus keyword. Legacy ROLES carry distinctive Russian
      // names in the system prompt.
      if (body.includes("Реалист")) return "Шанс по KHO valituslupa: 15-20%.";
      if (body.includes("Поисковик альтернатив")) {
        return "Альтернатива: подать в HAO. Шанс ~30%.";
      }
      if (body.includes("Дедлайн-стратег")) {
        return "Срок 5.6.2026, шаги: подготовка 14 дней, подача 5 дней.";
      }
      if (body.includes("Risk Auditor")) return "Упущено: §115 HOL не проверен.";
      if (body.includes("Процессуалист")) {
        return "§114 HOL применим — menetetyn määräajan palauttaminen.";
      }
      if (body.includes("Материальный")) {
        return "Сильная норма: [[ref:hol:114]] — KHO jurisdiction.";
      }
      return "Generic opinion 25%.";
    });

    try {
      const events: ConsiliumSSEEvent[] = [];
      const synthesis = await runConsilium({
        userMessage: "Mind on käännytetty Soomest, mida teha?",
        systemPrompt: "Base lawyer persona.",
        ragContext: "",
        caseContext: "",
        anthropicApiKey: "test-key",
        onEvent: (e) => events.push(e),
        // No caseClassification → uses legacy 6-role ROSTER for this smoke.
      });

      // ── 3a. Sequence order ───────────────────────────────────────────────
      const types = events.map((e) => e.type);
      assertEquals(types[0], "consilium_start", "first event = consilium_start");
      assertEquals(types[types.length - 1], "done", "last event = done");

      const synthIdx = types.indexOf("synthesis_start");
      const doneIdx = types.lastIndexOf("done");
      assert(synthIdx > 0, "synthesis_start must come after consilium_start");
      assert(doneIdx > synthIdx, "done must come after synthesis_start");

      // role_done events occur BEFORE synthesis_start.
      const roleDoneIdxs = events
        .map((e, i) => (e.type === "role_done" ? i : -1))
        .filter((i) => i !== -1);
      for (const i of roleDoneIdxs) {
        assert(i < synthIdx, "every role_done must precede synthesis_start");
      }

      // ── 3b. role_opinion appears for each role and carries flat fields ───
      // Wire-format contract (2026-05-25 Phase 1.1): fields are TOP-LEVEL on
      // the SSE frame (role_id, role_name, opinion, position, confidence,
      // key_citation) so the Flutter parser at lib/services/claude_service.dart
      // can read parsed['role_id'] etc. directly. No nested `payload`.
      const opinionEvents = events.filter((e) => e.type === "role_opinion");
      assert(
        opinionEvents.length >= 6,
        `expected ≥6 role_opinion (one per legacy role), got ${opinionEvents.length}`,
      );
      for (const e of opinionEvents) {
        assert(e.type === "role_opinion");
        // FLAT shape — no nested payload wrapper.
        // deno-lint-ignore no-explicit-any
        const ev = e as any;
        assertEquals(
          ev.payload,
          undefined,
          "role_opinion must NOT carry a nested `payload` field (flat shape)",
        );
        assert(typeof ev.role_id === "string" && ev.role_id.length > 0,
          "role_id must be a non-empty top-level string");
        assert(typeof ev.role_name === "string" && ev.role_name.length > 0,
          "role_name must be a non-empty top-level string");
        assert(typeof ev.opinion === "string" && ev.opinion.length > 0,
          "opinion must be a non-empty top-level string");
        assert(typeof ev.position === "string",
          "position must be a top-level string");
        // confidence and key_citation are nullable — just check the key exists.
        assert("confidence" in ev, "confidence key must be present (may be null)");
        assert("key_citation" in ev, "key_citation key must be present (may be null)");
      }

      // ── 3c. consilium_start payload shape ────────────────────────────────
      const start = events.find((e) => e.type === "consilium_start");
      assertExists(start);
      assert(start.type === "consilium_start");
      assert(Array.isArray(start.roles), "consilium_start.roles is array");
      assert(start.roles.length >= 6, "legacy roster has ≥6 roles");
      assertEquals(
        start.total,
        start.roles.length,
        "total must equal roles.length",
      );
      // Optional roster field with {id,name} for the new UI.
      assert(Array.isArray(start.roster), "roster must be present");
      assertEquals(start.roster?.length, start.roles.length);
      for (const r of start.roster ?? []) {
        assert(r.id.length > 0 && r.name.length > 0);
      }

      // ── 3d. Synthesis text was streamed via delta events ─────────────────
      const deltas = events.filter((e) => e.type === "delta");
      assert(deltas.length >= 1, "≥1 delta event");
      const streamedText = deltas
        .map((e) => (e.type === "delta" ? e.text : ""))
        .join("");
      assertEquals(streamedText, synthesis, "delta concat must equal synthesis");
    } finally {
      restore();
    }
  },
);

// ─── Scenario 4: flag-off behavior (legacy roster) ──────────────────────────

Deno.test(
  "smoke 4 — isLawyerRouterEnabled defaults false when env unset",
  () => {
    // Save & clear.
    const prev = Deno.env.get(LAWYER_ROUTER_FLAG_ENV);
    Deno.env.delete(LAWYER_ROUTER_FLAG_ENV);
    try {
      assertEquals(
        isLawyerRouterEnabled(),
        false,
        "default OFF when env unset",
      );
    } finally {
      if (prev !== undefined) Deno.env.set(LAWYER_ROUTER_FLAG_ENV, prev);
    }
  },
);

Deno.test(
  "smoke 4b — isLawyerRouterEnabled true when env=true / 1 / yes",
  () => {
    const prev = Deno.env.get(LAWYER_ROUTER_FLAG_ENV);
    try {
      for (const v of ["true", "1", "yes", "TRUE", " True "]) {
        Deno.env.set(LAWYER_ROUTER_FLAG_ENV, v);
        assertEquals(
          isLawyerRouterEnabled(),
          true,
          `expected true for env=${JSON.stringify(v)}`,
        );
      }
      // Anything else → false.
      for (const v of ["", "no", "0", "false"]) {
        Deno.env.set(LAWYER_ROUTER_FLAG_ENV, v);
        assertEquals(
          isLawyerRouterEnabled(),
          false,
          `expected false for env=${JSON.stringify(v)}`,
        );
      }
    } finally {
      if (prev !== undefined) {
        Deno.env.set(LAWYER_ROUTER_FLAG_ENV, prev);
      } else {
        Deno.env.delete(LAWYER_ROUTER_FLAG_ENV);
      }
    }
  },
);

Deno.test("smoke 4c — bridge returns null on empty query (safe fallback)", () => {
  assertEquals(selectRolesFromLawyerDept("", {}), null);
  assertEquals(selectRolesFromLawyerDept("   ", {}), null);
});

// ─── Scenario 5: anon protection (server-side enforcement contract) ──────────
//
// The bridge itself is pure — it does not read auth. The contract that
// guarantees anon callers don't trigger consilium lives in claude-proxy
// (`if (plannerMode && !body.stream && !isAnon) { … runConsilium }`). We
// pin that contract here by reading the source so a future refactor that
// drops the !isAnon guard is caught.

Deno.test("smoke 5 — claude-proxy gates consilium behind !isAnon", async () => {
  const proxyPath = new URL(
    "../../claude-proxy/index.ts",
    import.meta.url,
  );
  const src = await Deno.readTextFile(proxyPath);

  // The consilium upgrade block must sit inside a check that explicitly
  // requires !isAnon. We don't pin the exact AST — just verify the substring
  // pattern survives.
  const pattern = /plannerMode\s*&&\s*!body\.stream\s*&&\s*!isAnon/;
  assert(
    pattern.test(src),
    "claude-proxy must guard consilium dispatch with !isAnon",
  );

  // And the consilium runner call site must be downstream of that check.
  // We look for a CALL invocation (a `consiliumRunner({` or `runConsilium({`
  // pattern), not the import line at the top of the file.
  const checkIdx = src.search(pattern);
  const callPattern = /(?:consiliumRunner|runConsilium|runConsiliumV3)\s*\(\s*\{/;
  const callIdx = src.search(callPattern);
  assert(checkIdx > 0, "anti-anon check must exist");
  assert(
    callIdx > checkIdx,
    `consilium runner call site (${callIdx}) must be downstream of !isAnon guard (${checkIdx})`,
  );
});

// ─── Roster sanity (cross-check with router test) ────────────────────────────

Deno.test("smoke — ALL_LAWYERS has 11 distinct ids exposed via bridge", () => {
  assertEquals(ALL_LAWYERS.length, 11);
  const ids = new Set(ALL_LAWYERS.map((a) => a.id));
  assertEquals(ids.size, 11);
});
