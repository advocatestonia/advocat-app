// Deno tests for claude-proxy interleaved thinking + tool-turn budget.
// -----------------------------------------------------------------------------
// 2026-05-05 — Anthropic engineer (consilium) Gap: with extended thinking +
// tools, the model needs `interleaved-thinking-2025-05-14` in `anthropic-beta`
// AND it needs `body.thinking` allowed in the proxy whitelist for authenticated
// callers. This file pins:
//
//   1. buildAnthropicHeaders includes BOTH
//      - prompt-caching-2024-07-31
//      - interleaved-thinking-2025-05-14
//
//   2. classifyComplexity contract (already shipped, regression pin):
//      - anon caller never gets thinking
//      - authenticated caller with non-trivial message gets thinking
//      - authenticated caller with `hasTools: true` gets at least medium
//
//   3. Source-code contract pins on index.ts:
//      - body.thinking is honoured when set by client (`??=` semantics)
//      - the auto-injection branch passes `hasTools` through so the
//        classifier can lift the budget for tool turns
//
// Run with:
//   deno test --allow-read \
//     supabase/functions/claude-proxy/__tests__/interleaved_thinking_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import { buildAnthropicHeaders } from "../prompt_caching.ts";
import {
  BUDGET_COMPLEX,
  BUDGET_MEDIUM,
  classifyComplexity,
} from "../classify_complexity.ts";

// ---- Beta headers --------------------------------------------------------

Deno.test("IT-T01 — anthropic-beta includes interleaved-thinking-2025-05-14", () => {
  const h = buildAnthropicHeaders("sk-ant-test");
  assertStringIncludes(
    h["anthropic-beta"] ?? "",
    "interleaved-thinking-2025-05-14",
    "Required so the model can interleave thinking blocks with tool_use " +
      "blocks within a single turn — without this beta the agentic loop " +
      "(SmartAgent v2) cannot think between tool calls.",
  );
});

Deno.test("IT-T02 — anthropic-beta still includes prompt-caching-2024-07-31", () => {
  // Regression pin: adding interleaved-thinking must NOT drop the caching
  // beta. Caching is the cost backbone (€2.39/user vs −€0.11 without).
  const h = buildAnthropicHeaders("sk-ant-test");
  assertStringIncludes(h["anthropic-beta"] ?? "", "prompt-caching-2024-07-31");
});

Deno.test("IT-T03 — anthropic-beta is comma-separated (single header line)", () => {
  // Anthropic accepts comma-separated betas in one header. We pack both in
  // a single line so the proxy stays a single fetch with one header dict.
  const h = buildAnthropicHeaders("sk-ant-test");
  const beta = h["anthropic-beta"] ?? "";
  assert(
    beta.includes(",") || beta.split(/\s+/).length >= 2,
    "Expected multiple betas in a single comma-separated header, got: " + beta,
  );
});

// ---- Anon vs authenticated ----------------------------------------------

Deno.test("IT-T04 — anon caller never gets thinking (cost ceiling)", () => {
  // Critical invariant: anon body.max_tokens is clamped to 500. Thinking
  // budget > max_tokens is an Anthropic API error. Plus thinking on free
  // tier turns demos into a Sonnet cost burn.
  const messages = [
    { role: "user", content: "I got a deportation notice from the Ministry" },
  ];
  const result = classifyComplexity(
    messages,
    /* userIsAnon */ true,
    { hasTools: true },
  );
  assertEquals(
    result,
    null,
    "Anon must never receive a thinking config — even with tools[].",
  );
});

Deno.test("IT-T05 — authenticated + legal + tools → thinking enabled", () => {
  const messages = [
    { role: "user", content: "I got a deportation notice. What's my appeal window?" },
  ];
  const result = classifyComplexity(
    messages,
    /* userIsAnon */ false,
    { hasTools: true },
  );
  assert(result !== null, "Expected thinking config for authenticated tool turn");
  assertEquals(result.type, "enabled");
  assertEquals(result.display, "summarized");
  assertEquals(result.budget_tokens, BUDGET_COMPLEX);
});

Deno.test("IT-T06 — authenticated + non-legal + tools → at least medium budget", () => {
  // Tool turns deserve at least medium budget so the model has room to
  // pick a tool. Non-legal medium messages currently get medium even
  // without tools; pin the contract so a future refactor doesn't drop
  // budget when tools are attached.
  const messages = [
    { role: "user", content: "can you help me figure out what document I need" },
  ];
  const result = classifyComplexity(
    messages,
    /* userIsAnon */ false,
    { hasTools: true },
  );
  assert(result !== null, "Expected non-null thinking config");
  assert(
    result.budget_tokens >= BUDGET_MEDIUM,
    `Expected budget >= ${BUDGET_MEDIUM}, got ${result.budget_tokens}`,
  );
});

Deno.test("IT-T07 — authenticated + no tools + non-legal medium → medium budget", () => {
  // Same query without tools — still gets thinking, still medium.
  // The classifier already does this; pin it so the tools-aware refactor
  // doesn't change non-tool behaviour.
  const messages = [
    { role: "user", content: "can you help me understand a document i have" },
  ];
  const result = classifyComplexity(messages, false, { hasTools: false });
  assert(result !== null);
  assertEquals(result.budget_tokens, BUDGET_MEDIUM);
});

// ---- Source-code contract pins on index.ts -------------------------------

Deno.test("IT-T08 — claude-proxy honours pre-existing body.thinking (??= semantics)", async () => {
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  // The client (Reasoning Trail) sometimes pre-sets body.thinking when it
  // wants explicit control. The proxy must NOT overwrite — only fill in
  // when undefined.
  assertStringIncludes(
    source,
    "body.thinking === undefined",
    "Expected `if (body.thinking === undefined)` guard so client-supplied " +
      "thinking config is honoured unchanged.",
  );
});

Deno.test("IT-T09 — claude-proxy passes hasTools to classifyComplexity", async () => {
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  // The classifier needs the tools signal to pick budget correctly.
  // Pin the wiring so a future refactor doesn't drop the option bag.
  assertStringIncludes(
    source,
    "hasTools",
    "claude-proxy must forward hasTools to classifyComplexity so tool " +
      "turns get appropriate thinking budget.",
  );
});

Deno.test("IT-T10 — anon path explicitly disables thinking auto-injection", async () => {
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  // The classifier returns null for anon; pin that the proxy passes the
  // anon flag through. Searching for the literal `isAnon` keyword in the
  // classifyComplexity call is enough.
  const match = source.match(
    /classifyComplexity\([^)]*isAnon[^)]*\)/s,
  );
  assert(
    match !== null,
    "Expected classifyComplexity(...) call to include isAnon argument; " +
      "without it anon callers could accidentally get a thinking budget " +
      "that exceeds their 500-token clamp and error the Anthropic call.",
  );
});

Deno.test("IT-T11 — claude-proxy auto-injects thinking BEFORE the Anthropic fetch", async () => {
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  // If we move applyPromptCaching above the thinking branch, fine —
  // but BOTH must run before the wire fetch.
  const stripped = source
    .replace(/\/\*[\s\S]*?\*\//g, "")
    .replace(/^\s*\/\/.*$/gm, "");
  const thinkingIdx = stripped.indexOf("classifyComplexity(");
  const anthropicFetchIdx = stripped.indexOf("api.anthropic.com");
  assert(
    thinkingIdx !== -1 && anthropicFetchIdx !== -1,
    "Both classifyComplexity and api.anthropic.com must appear in index.ts",
  );
  assert(
    thinkingIdx < anthropicFetchIdx,
    "classifyComplexity must run before the Anthropic fetch — otherwise " +
      "body.thinking is never set and interleaved thinking is dead code.",
  );
});
