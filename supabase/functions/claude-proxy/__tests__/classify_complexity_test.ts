// Deno tests for claude-proxy complexity classifier (Reasoning Trail v1).
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-read \
//     supabase/functions/claude-proxy/__tests__/classify_complexity_test.ts
// -----------------------------------------------------------------------------

import {
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  BUDGET_COMPLEX,
  BUDGET_MEDIUM,
  classifyComplexity,
} from "../classify_complexity.ts";

// ---- Anon caller --------------------------------------------------

Deno.test("anon caller never gets thinking (max_tokens clamped to 500)", () => {
  // Even on a long legal message, anon stays at null.
  const result = classifyComplexity(
    [{ role: "user", content: "I got a deportation notice. What's my appeal window?" }],
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
