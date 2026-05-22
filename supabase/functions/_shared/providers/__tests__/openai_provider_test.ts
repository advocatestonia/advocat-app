// =============================================================================
// _shared/providers/__tests__/openai_provider_test.ts
// =============================================================================
// FIX-WAVE 14 — Unit tests for the OpenAI Chat Completions provider.
//
// Strategy: stub `globalThis.fetch` so we can drive every error path without a
// network. Each test restores the original fetch via a try/finally guard so a
// failure in one case can't leak state into the next.
//
// Coverage:
//   • happy  — 200 with usage block → ProviderResponse shape
//   • 429    — Provider429Error with retryAfterSec parsed from header
//   • 401    — ProviderAuthError
//   • timeout — AbortController fires → ProviderTimeoutError
//
// Run:
//   deno test --allow-env supabase/functions/_shared/providers/__tests__/openai_provider_test.ts
// =============================================================================

import {
  assertEquals,
  assertInstanceOf,
  assertRejects,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import { callOpenAI } from "../openai_provider.ts";
import {
  Provider429Error,
  ProviderAuthError,
  ProviderTimeoutError,
} from "../types.ts";

// Ensure the auth-missing branch never fires for these tests.
Deno.env.set("OPENAI_API_KEY", "sk-test-fake-key");

type FetchFn = typeof globalThis.fetch;

function withMockFetch(mock: FetchFn, fn: () => Promise<void>): Promise<void> {
  const original = globalThis.fetch;
  globalThis.fetch = mock;
  return fn().finally(() => {
    globalThis.fetch = original;
  });
}

Deno.test("OAI-T01 — happy path returns text + token counts", async () => {
  await withMockFetch(
    () =>
      Promise.resolve(
        new Response(
          JSON.stringify({
            choices: [{ message: { content: "hello from gpt" } }],
            usage: { prompt_tokens: 12, completion_tokens: 7 },
          }),
          { status: 200, headers: { "content-type": "application/json" } },
        ),
      ),
    async () => {
      const res = await callOpenAI({
        systemPrompt: "you are a test",
        messages: [{ role: "user", content: "ping" }],
        maxTokens: 64,
      });
      assertEquals(res.text, "hello from gpt");
      assertEquals(res.inputTokens, 12);
      assertEquals(res.outputTokens, 7);
    },
  );
});

Deno.test("OAI-T02 — 429 throws Provider429Error with retryAfterSec", async () => {
  await withMockFetch(
    () =>
      Promise.resolve(
        new Response("rate limited", {
          status: 429,
          headers: { "retry-after": "17" },
        }),
      ),
    async () => {
      const err = await assertRejects(
        () =>
          callOpenAI({
            systemPrompt: "s",
            messages: [{ role: "user", content: "u" }],
            maxTokens: 8,
          }),
        Provider429Error,
      );
      assertEquals((err as Provider429Error).retryAfterSec, 17);
    },
  );
});

Deno.test("OAI-T03 — 401 throws ProviderAuthError", async () => {
  await withMockFetch(
    () =>
      Promise.resolve(
        new Response("unauthorized", { status: 401 }),
      ),
    async () => {
      await assertRejects(
        () =>
          callOpenAI({
            systemPrompt: "s",
            messages: [{ role: "user", content: "u" }],
            maxTokens: 8,
          }),
        ProviderAuthError,
      );
    },
  );
});

Deno.test("OAI-T04 — abort signal raises ProviderTimeoutError", async () => {
  // Simulate the AbortController firing by rejecting fetch with an
  // AbortError-named exception — that's exactly what Deno's fetch raises
  // when `signal.abort()` is called.  The provider must catch this branch
  // and re-throw as ProviderTimeoutError so the chain layer can classify it.
  const fastAbort: FetchFn = () =>
    Promise.reject(
      Object.assign(new Error("aborted"), { name: "AbortError" }),
    );

  await withMockFetch(fastAbort, async () => {
    const err = await assertRejects(
      () =>
        callOpenAI({
          systemPrompt: "s",
          messages: [{ role: "user", content: "u" }],
          maxTokens: 8,
        }),
    );
    assertInstanceOf(err, ProviderTimeoutError);
  });
});
