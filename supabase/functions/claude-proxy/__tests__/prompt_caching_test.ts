// Deno tests for claude-proxy prompt caching (Sprint 0 — FIX-1).
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-read \
//     supabase/functions/claude-proxy/__tests__/prompt_caching_test.ts
//
// Ref: docs/performance/05-cost.md §2.4-2.5 — flips unit economics from
// −€0.11/user to +€2.39/user. Saves 30-45% of input tokens per message.
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  applyPromptCaching,
  buildAnthropicHeaders,
  CACHE_MIN_CHARS,
  CACHE_TTL,
} from "../prompt_caching.ts";

// ---- applyPromptCaching --------------------------------------------------

Deno.test("F1-T01 — string system prompt is wrapped in cached block", () => {
  const legit = "You are Advocat. " + "legal corpus text ".repeat(200);
  // Ensure we're over the threshold so it's worth caching.
  assert(legit.length > CACHE_MIN_CHARS);
  const body = { system: legit, model: "x" };
  const out = applyPromptCaching(body);
  assert(Array.isArray(out.system));
  const arr = out.system as Array<
    { type: string; text: string; cache_control?: { type: string; ttl?: string } }
  >;
  assertEquals(arr.length, 1);
  assertEquals(arr[0].type, "text");
  assertEquals(arr[0].text, legit);
  assertEquals(arr[0].cache_control?.type, "ephemeral");
  // TTL pinned to 1h — guards against Anthropic's March 2026 default
  // regression from 1h to 5m.
  assertEquals(arr[0].cache_control?.ttl, "1h");
  assertEquals(arr[0].cache_control?.ttl, CACHE_TTL);
});

Deno.test("F1-T02 — short string system prompt is left as string (not worth caching)", () => {
  // Light prompts are < 1024 chars — caching adds 1.25x write overhead
  // for almost no hit benefit. Leave them alone.
  const light = "You are Advocat.";
  assert(light.length < CACHE_MIN_CHARS);
  const body = { system: light };
  const out = applyPromptCaching(body);
  assertEquals(typeof out.system, "string");
  assertEquals(out.system, light);
});

Deno.test("F1-T03 — empty string system is dropped (or left as-is)", () => {
  const body = { system: "" };
  const out = applyPromptCaching(body);
  // We accept either "preserve as empty string" or "drop entirely"; what
  // matters is that no cache_control is added to empty content.
  if (typeof out.system === "string") {
    assertEquals(out.system, "");
  }
});

Deno.test("F1-T04 — undefined system is left alone", () => {
  const body: { system?: unknown } = {};
  const out = applyPromptCaching(body);
  assertEquals(out.system, undefined);
});

Deno.test("F1-T05 — array form with large block gets cache_control added", () => {
  const bigText = "You are Advocat. " + "x".repeat(CACHE_MIN_CHARS + 100);
  const body = {
    system: [
      { type: "text" as const, text: bigText },
      { type: "text" as const, text: "short dynamic context" },
    ],
  };
  const out = applyPromptCaching(body);
  const arr = out.system as Array<
    { type: string; text: string; cache_control?: { type: string; ttl?: string } }
  >;
  assertEquals(arr[0].cache_control?.type, "ephemeral");
  // New cache_control markers always carry the explicit 1h TTL.
  assertEquals(arr[0].cache_control?.ttl, "1h");
  // Second block is too small — must NOT be cached.
  assertEquals(arr[1].cache_control, undefined);
});

Deno.test("F1-T06 — array form preserves existing cache_control markers", () => {
  const bigText = "You are Advocat. " + "x".repeat(CACHE_MIN_CHARS + 100);
  const body = {
    system: [
      {
        type: "text" as const,
        text: bigText,
        cache_control: { type: "ephemeral" as const, ttl: "1h" as const },
      },
    ],
  };
  const out = applyPromptCaching(body);
  const arr = out.system as Array<
    { type: string; cache_control?: { type: string; ttl?: string } }
  >;
  // Idempotent — still exactly one marker.
  assertEquals(arr[0].cache_control?.type, "ephemeral");
  // Existing TTL is preserved verbatim — caller's choice wins.
  assertEquals(arr[0].cache_control?.ttl, "1h");
});

Deno.test("F1-T06b — caller's cache_control without ttl is upgraded to 1h", () => {
  // Guards the March 2026 regression: a caller-supplied marker without an
  // explicit ttl would inherit Anthropic's new 5m default. We force-pin it
  // to CACHE_TTL so the whole request body has uniform TTL policy.
  const bigText = "You are Advocat. " + "x".repeat(CACHE_MIN_CHARS + 100);
  const body = {
    system: [
      {
        type: "text" as const,
        text: bigText,
        cache_control: { type: "ephemeral" as const },
      },
    ],
  };
  const out = applyPromptCaching(body);
  const arr = out.system as Array<
    { type: string; cache_control?: { type: string; ttl?: string } }
  >;
  assertEquals(arr[0].cache_control?.type, "ephemeral");
  assertEquals(arr[0].cache_control?.ttl, "1h");
});

Deno.test("F1-T07 — only blocks with type='text' get cache_control", () => {
  // Image blocks and other future block types must not accidentally be
  // marked (Anthropic may not support cache_control on them).
  const bigText = "You are Advocat. " + "x".repeat(CACHE_MIN_CHARS + 100);
  const body = {
    system: [
      { type: "text" as const, text: bigText },
      // Deliberately use an unknown type — must be left alone.
      { type: "unsupported", foo: "bar" } as unknown as { type: "text"; text: string },
    ],
  };
  const out = applyPromptCaching(body);
  const arr = out.system as Array<
    { type: string; cache_control?: { type: string; ttl?: string } }
  >;
  assertEquals(arr[0].cache_control?.type, "ephemeral");
  assertEquals(arr[0].cache_control?.ttl, "1h");
  assertEquals(arr[1].cache_control, undefined);
});

Deno.test("F1-T07b — CACHE_TTL constant is pinned to 1h", () => {
  // Anthropic silently regressed the cache_control default from 1h to 5m
  // in March 2026. Long Advocat sessions (median 30 min for free tier,
  // 75 min for premium) need the 1h tier to keep hit rates above 0.9.
  // Lock the constant so a refactor can't quietly drop the TTL.
  assertEquals(CACHE_TTL, "1h");
});

Deno.test("F1-T08 — applyPromptCaching is idempotent (run twice == run once)", () => {
  const bigText = "You are Advocat. " + "x".repeat(CACHE_MIN_CHARS + 100);
  const body = { system: bigText };
  const once = applyPromptCaching({ ...body });
  const twice = applyPromptCaching(applyPromptCaching({ ...body }));
  assertEquals(JSON.stringify(once), JSON.stringify(twice));
});

// ---- buildAnthropicHeaders -----------------------------------------------

Deno.test("F1-T09 — headers include anthropic-version 2023-06-01", () => {
  const h = buildAnthropicHeaders("sk-ant-test");
  assertEquals(h["anthropic-version"], "2023-06-01");
});

Deno.test("F1-T10 — headers include anthropic-beta for prompt caching", () => {
  const h = buildAnthropicHeaders("sk-ant-test");
  assertStringIncludes(h["anthropic-beta"] ?? "", "prompt-caching");
  assertStringIncludes(h["anthropic-beta"] ?? "", "2024-07-31");
});

Deno.test("F1-T11 — headers include x-api-key (not Authorization)", () => {
  const h = buildAnthropicHeaders("sk-ant-test");
  assertEquals(h["x-api-key"], "sk-ant-test");
  // Anthropic historically rejects Bearer — must not send.
  assertEquals(h["Authorization"], undefined);
});

Deno.test("F1-T12 — headers include Content-Type application/json", () => {
  const h = buildAnthropicHeaders("sk-ant-test");
  assertEquals(h["Content-Type"], "application/json");
});

// ---- Source-code contract: index.ts wires it in ---------------------------

Deno.test("F1-T13 — claude-proxy imports applyPromptCaching", async () => {
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  assertStringIncludes(source, "applyPromptCaching");
  assertStringIncludes(source, "prompt_caching.ts");
});

Deno.test("F1-T14 — claude-proxy imports buildAnthropicHeaders", async () => {
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  assertStringIncludes(source, "buildAnthropicHeaders");
});

Deno.test("F1-T15 — both streaming and non-streaming fetch use buildAnthropicHeaders", async () => {
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  // We must not ship a path that forgets the cache beta header.
  const strippedForFetchCount = source
    .replace(/\/\*[\s\S]*?\*\//g, "")
    .replace(/^\s*\/\/.*$/gm, "");
  const fetchCount = [
    ...strippedForFetchCount.matchAll(/api\.anthropic\.com/g),
  ].length;
  const buildHeadersCount = [
    ...strippedForFetchCount.matchAll(/buildAnthropicHeaders\(/g),
  ].length;
  // Each Anthropic fetch call must be paired with a buildAnthropicHeaders.
  assertEquals(
    fetchCount,
    buildHeadersCount,
    `Every api.anthropic.com call must use buildAnthropicHeaders. ` +
      `Found ${fetchCount} fetches vs ${buildHeadersCount} header builds.`,
  );
});

Deno.test("F1-T16 — applyPromptCaching runs BEFORE the Anthropic fetch", async () => {
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  const stripped = source
    .replace(/\/\*[\s\S]*?\*\//g, "")
    .replace(/^\s*\/\/.*$/gm, "");
  const applyIdx = stripped.indexOf("applyPromptCaching(");
  const anthropicFetchIdx = stripped.indexOf("api.anthropic.com");
  assert(
    applyIdx !== -1 && anthropicFetchIdx !== -1,
    "Both applyPromptCaching and api.anthropic.com must appear",
  );
  assert(
    applyIdx < anthropicFetchIdx,
    "applyPromptCaching must run before the Anthropic fetch — otherwise " +
      "the cache_control fields are never sent",
  );
});
