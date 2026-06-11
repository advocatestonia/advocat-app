// Deno tests for claude-proxy complexity classifier (Reasoning Trail v1).
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-read \
//     supabase/functions/claude-proxy/__tests__/classify_complexity_test.ts
// -----------------------------------------------------------------------------

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  BUDGET_COMPLEX,
  BUDGET_MEDIUM,
  classifyComplexity,
} from "../classify_complexity.ts";

// ---- Anon caller --------------------------------------------------

Deno.test("anon caller never gets thinking (max_tokens clamped to 500)", () => {
  // Even on a long legal message, anon stays at null.
  const result = classifyComplexity(
    [{
      role: "user",
      content: "I got a deportation notice. What's my appeal window?",
    }],
    /* userIsAnon */ true,
  );
  assertEquals(result, null);
});

// ---- Short / greeting messages ------------------------------------

Deno.test("short greeting → no thinking", () => {
  const result = classifyComplexity(
    [{ role: "user", content: "привет" }],
    false,
  );
  assertEquals(result, null);
});

Deno.test("ok / thanks / hi → no thinking", () => {
  for (const greet of ["hi", "ok", "thanks", "hello", "tere", "kiitos"]) {
    const r = classifyComplexity([{ role: "user", content: greet }], false);
    assertEquals(r, null, `greeting "${greet}" should be null`);
  }
});

// ---- Long / legal messages ----------------------------------------

Deno.test("long legal message → 6144 budget", () => {
  const msg =
    "I got a deportation notice from the Ministry of the Interior and I need help understanding my appeal options before the deadline runs out next week";
  const result = classifyComplexity([{ role: "user", content: msg }], false);
  assertEquals(result?.budget_tokens, BUDGET_COMPLEX);
  assertEquals(result?.display, "summarized");
  assertEquals(result?.type, "enabled");
});

Deno.test("short message with legal keyword → 6144", () => {
  // Even short, a legal keyword (deport) lifts it to complex.
  const result = classifyComplexity(
    [{ role: "user", content: "deportation help?" }],
    false,
  );
  assertEquals(result?.budget_tokens, BUDGET_COMPLEX);
});

Deno.test("Russian legal keyword (жалоба) → 6144", () => {
  const result = classifyComplexity(
    [{ role: "user", content: "хочу подать жалобу на работодателя" }],
    false,
  );
  assertEquals(result?.budget_tokens, BUDGET_COMPLEX);
});

Deno.test("Estonian legal keyword (kohus) → 6144", () => {
  const result = classifyComplexity(
    [{ role: "user", content: "kuidas kohtusse pöörduda?" }],
    false,
  );
  assertEquals(result?.budget_tokens, BUDGET_COMPLEX);
});

// ---- Medium messages ----------------------------------------------

Deno.test("medium-length non-legal message → 2048 budget", () => {
  // No legal keyword, ~50 chars — gets medium.
  const result = classifyComplexity(
    [{ role: "user", content: "can you help me understand a document I have" }],
    false,
  );
  assertEquals(result?.budget_tokens, BUDGET_MEDIUM);
});

// ---- Pre-existing body.thinking honoured --------------------------

Deno.test("display field is always 'summarized' (security: never verbatim CoT)", () => {
  // Several different inputs should all return display:summarized.
  const inputs = [
    "I need to file an appeal with the court",
    "Can you draft a letter to my landlord about repairs",
    "x".repeat(300),
  ];
  for (const msg of inputs) {
    const r = classifyComplexity([{ role: "user", content: msg }], false);
    if (r !== null) {
      assertEquals(
        r.display,
        "summarized",
        `display must always be summarized for "${msg.slice(0, 30)}…"`,
      );
    }
  }
});

// ---- Defensive: malformed input -----------------------------------

Deno.test("empty messages array → null", () => {
  assertEquals(classifyComplexity([], false), null);
});

Deno.test("last message is from assistant → null", () => {
  const result = classifyComplexity(
    [
      { role: "user", content: "hello" },
      { role: "assistant", content: "hi there" },
    ],
    false,
  );
  assertEquals(result, null);
});

Deno.test("array-shaped content extracted correctly", () => {
  const result = classifyComplexity(
    [{
      role: "user",
      content: [
        { type: "text", text: "I need to file a deportation appeal urgently" },
      ],
    }],
    false,
  );
  assertEquals(result?.budget_tokens, BUDGET_COMPLEX);
});

Deno.test("non-string non-array content → null (defensive)", () => {
  const result = classifyComplexity(
    [{ role: "user", content: 42 as unknown as string }],
    false,
  );
  assertEquals(result, null);
});

// ---- Tool eligibility ---------------------------------------------

Deno.test("medium message with tools → still medium (not bumped)", () => {
  const result = classifyComplexity(
    [{ role: "user", content: "is this a fair offer for me to sign" }],
    false,
    { hasTools: true },
  );
  // hasTools doesn't degrade — still medium.
  assertEquals(result?.budget_tokens, BUDGET_MEDIUM);
});

// ---- Wave-1 fix (2026-06-11): per-model thinking compatibility ------
//
// Deployed-bug pin: the proxy routed "complex" turns to claude-opus-4-8
// while body.thinking still carried {type:"enabled", budget_tokens:6144}
// (and the Flutter client's temperature) → Anthropic 400 on every complex
// turn. Opus 4.7+ is adaptive-only: budget_tokens AND temperature/top_p/
// top_k are removed params. applyModelThinkingCompat reconciles the body
// with the FINAL model and is called in index.ts right after the signal
// router assigns body.model.

import {
  applyModelThinkingCompat,
  isAdaptiveOnlyThinkingModel,
} from "../classify_complexity.ts";
import { assert } from "https://deno.land/std@0.224.0/assert/mod.ts";

Deno.test("TC-01 — adaptive-only model detection", () => {
  assertEquals(isAdaptiveOnlyThinkingModel("claude-opus-4-8"), true);
  assertEquals(isAdaptiveOnlyThinkingModel("claude-opus-4-7"), true);
  assertEquals(isAdaptiveOnlyThinkingModel("claude-fable-5"), true);
  assertEquals(isAdaptiveOnlyThinkingModel("claude-haiku-4-5-20251001"), false);
  assertEquals(isAdaptiveOnlyThinkingModel("claude-sonnet-4-20250514"), false);
  assertEquals(isAdaptiveOnlyThinkingModel("claude-sonnet-4-6"), false);
});

Deno.test("TC-02 — Opus 4.8 + enabled/budget → adaptive, NEVER budget_tokens", () => {
  const body: Record<string, unknown> = {
    model: "claude-opus-4-8",
    max_tokens: 32000,
    thinking: {
      type: "enabled",
      budget_tokens: BUDGET_COMPLEX,
      display: "summarized",
    },
  };
  applyModelThinkingCompat(body);
  assertEquals(body.thinking, { type: "adaptive", display: "summarized" });
  // The exact 400 trigger: budget_tokens must NOT appear in the payload.
  assert(!JSON.stringify(body).includes("budget_tokens"));
});

Deno.test("TC-03 — Opus 4.8 strips temperature/top_p/top_k (removed params)", () => {
  // The Flutter client sends temperature on every turn (claude_service.dart),
  // which alone 400s an Opus 4.8 call even without thinking.
  const body: Record<string, unknown> = {
    model: "claude-opus-4-8",
    temperature: 0.3,
    top_p: 0.9,
    top_k: 40,
  };
  applyModelThinkingCompat(body);
  assertEquals("temperature" in body, false);
  assertEquals("top_p" in body, false);
  assertEquals("top_k" in body, false);
});

Deno.test("TC-04 — Opus 4.8 + already-adaptive / absent thinking → untouched", () => {
  const adaptive: Record<string, unknown> = {
    model: "claude-opus-4-8",
    thinking: { type: "adaptive", display: "summarized" },
  };
  applyModelThinkingCompat(adaptive);
  assertEquals(adaptive.thinking, { type: "adaptive", display: "summarized" });

  const absent: Record<string, unknown> = { model: "claude-opus-4-8" };
  applyModelThinkingCompat(absent);
  assertEquals("thinking" in absent, false);
});

Deno.test("TC-05 — classifyComplexity output fed to Opus body ends up adaptive (e2e shape)", () => {
  // Mirrors the production sequence: classifier attaches the budget shape,
  // signal router later picks Opus, compat translates it.
  const inferred = classifyComplexity(
    [{
      role: "user",
      content: "I got a deportation notice. What's my appeal window?",
    }],
    false,
  );
  assertEquals(inferred?.type, "enabled");
  const body: Record<string, unknown> = {
    model: "claude-opus-4-8",
    max_tokens: 32000,
    thinking: inferred,
    temperature: 0.3,
  };
  applyModelThinkingCompat(body);
  const payload = JSON.stringify(body);
  assert(!payload.includes("budget_tokens"));
  assert(!payload.includes("temperature"));
  assertEquals((body.thinking as { type: string }).type, "adaptive");
});

Deno.test("TC-06 — Haiku 4.5 keeps the enabled/budget shape (supported there)", () => {
  const thinking = {
    type: "enabled",
    budget_tokens: BUDGET_MEDIUM,
    display: "summarized",
  };
  const body: Record<string, unknown> = {
    model: "claude-haiku-4-5-20251001",
    max_tokens: 32000,
    thinking,
    temperature: 0.3,
  };
  applyModelThinkingCompat(body);
  assertEquals(body.thinking, thinking);
  // Sampling params are still valid on Haiku 4.5 — must NOT be stripped.
  assertEquals(body.temperature, 0.3);
});

Deno.test("TC-07 — budget model + adaptive → translated to enabled/budget", () => {
  const body: Record<string, unknown> = {
    model: "claude-haiku-4-5-20251001",
    max_tokens: 32000,
    thinking: { type: "adaptive" },
  };
  applyModelThinkingCompat(body);
  assertEquals(body.thinking, {
    type: "enabled",
    budget_tokens: BUDGET_COMPLEX,
    display: "summarized",
  });
});

Deno.test("TC-08 — budget model + adaptive clamps under small max_tokens", () => {
  // budget must be < max_tokens (API contract). 4096 < BUDGET_COMPLEX → medium.
  const medium: Record<string, unknown> = {
    model: "claude-haiku-4-5-20251001",
    max_tokens: 4096,
    thinking: { type: "adaptive" },
  };
  applyModelThinkingCompat(medium);
  assertEquals(
    (medium.thinking as { budget_tokens: number }).budget_tokens,
    BUDGET_MEDIUM,
  );

  // 500-token cap leaves no usable budget (min 1024) → thinking dropped.
  const tiny: Record<string, unknown> = {
    model: "claude-haiku-4-5-20251001",
    max_tokens: 500,
    thinking: { type: "adaptive" },
  };
  applyModelThinkingCompat(tiny);
  assertEquals("thinking" in tiny, false);
});

Deno.test("TC-09 — non-string model → no-op (defensive)", () => {
  const body: Record<string, unknown> = {
    thinking: {
      type: "enabled",
      budget_tokens: BUDGET_COMPLEX,
      display: "summarized",
    },
    temperature: 0.3,
  };
  applyModelThinkingCompat(body);
  assertEquals((body.thinking as { type: string }).type, "enabled");
  assertEquals(body.temperature, 0.3);
});
