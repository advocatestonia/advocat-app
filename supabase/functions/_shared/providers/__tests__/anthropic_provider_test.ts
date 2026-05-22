// =============================================================================
// _shared/providers/__tests__/anthropic_provider_test.ts
// =============================================================================
// FIX-WAVE 14 — Unit tests for the Anthropic Messages provider.
//
// Mirrors openai_provider_test.ts with one extra case: the credit-exhausted
// 400 detection, which is Anthropic-specific (see lesson_anthropic_zero_
// balance_fallback for the user-visible incident this branch prevents).
//
// Coverage:
//   • happy           — text + token counts from content blocks
//   • 429             — Provider429Error + retryAfterSec
//   • 401             — ProviderAuthError
//   • timeout         — AbortError → ProviderTimeoutError
//   • credit_exhausted — 400 + "credit balance is too low" → ProviderCreditExhaustedError
//
// Run:
//   deno test --allow-env supabase/functions/_shared/providers/__tests__/anthropic_provider_test.ts
// =============================================================================

import {
  assertEquals,
  assertInstanceOf,
  assertRejects,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import { callAnthropic } from "../anthropic_provider.ts";
import {
  Provider429Error,
  ProviderAuthError,
  ProviderCreditExhaustedError,
  ProviderTimeoutError,
} from "../types.ts";

Deno.env.set("ANTHROPIC_API_KEY", "sk-ant-test-fake-key");

type FetchFn = typeof globalThis.fetch;

function withMockFetch(mock: FetchFn, fn: () => Promise<void>): Promise<void> {
  const original = globalThis.fetch;
  globalThis.fetch = mock;
  return fn().finally(() => {
    globalThis.fetch = original;
  });
}

function callArgs() {
  return {
    systemPrompt: "you are a test",
    messages: [{ role: "user", content: "ping" }],
    maxTokens: 64,
    model: "claude-sonnet-4-20250514",
  };
}

Deno.test("ANT-T01 — happy path returns text + token counts", async () => {
  await withMockFetch(
    () =>
      Promise.resolve(
        new Response(
          JSON.stringify({
            content: [
              { type: "text", text: "hello " },
              { type: "text", text: "from claude" },
            ],
            usage: { input_tokens: 30, output_tokens: 9 },
          }),
          { status: 200, headers: { "content-type": "application/json" } },
        ),
      ),
    async () => {
      const res = await callAnthropic(callArgs());
      assertEquals(res.text, "hello from claude");
      assertEquals(res.inputTokens, 30);
      assertEquals(res.outputTokens, 9);
    },
  );
});

Deno.test("ANT-T02 — 429 throws Provider429Error with retryAfterSec", async () => {
  await withMockFetch(
    () =>
      Promise.resolve(
        new Response("rate limited", {
          status: 429,
          headers: { "retry-after": "23" },
        }),
      ),
    async () => {
      const err = await assertRejects(
        () => callAnthropic(callArgs()),
        Provider429Error,
      );
      assertEquals((err as Provider429Error).retryAfterSec, 23);
    },
  );
});

Deno.test("ANT-T03 — 401 throws ProviderAuthError", async () => {
  await withMockFetch(
    () => Promise.resolve(new Response("unauthorized", { status: 401 })),
    async () => {
      await assertRejects(
        () => callAnthropic(callArgs()),
        ProviderAuthError,
      );
    },
  );
});

Deno.test("ANT-T04 — abort raises ProviderTimeoutError", async () => {
  const fastAbort: FetchFn = () =>
    Promise.reject(
      Object.assign(new Error("aborted"), { name: "AbortError" }),
    );
  await withMockFetch(fastAbort, async () => {
    const err = await assertRejects(() => callAnthropic(callArgs()));
    assertInstanceOf(err, ProviderTimeoutError);
  });
});

Deno.test("ANT-T05 — 400 'credit balance too low' throws ProviderCreditExhaustedError", async () => {
  // Real-world body shape Anthropic returns when an org runs out of credit.
  // See lesson_anthropic_zero_balance_fallback (commit f0394f5).
  const creditBody = JSON.stringify({
    type: "error",
    error: {
      type: "invalid_request_error",
      message:
        "Your credit balance is too low to access the Anthropic API. Please go to Plans & Billing to upgrade or purchase credits.",
    },
  });
  await withMockFetch(
    () => Promise.resolve(new Response(creditBody, { status: 400 })),
    async () => {
      await assertRejects(
        () => callAnthropic(callArgs()),
        ProviderCreditExhaustedError,
      );
    },
  );
});
