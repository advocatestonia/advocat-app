// =============================================================================
// claude-proxy — Llama fallback unit tests (2026-05-11)
// =============================================================================
//
// Tests cover:
//   L1 — shouldFallback() decides correctly for 200/4xx/429/5xx
//   L2 — fallbackReasonFromStatus() classifies correctly
//   L3 — convertToOpenAIMessages() Anthropic→OpenAI conversion (incl. system)
//   L4 — convertToOpenAIMessages() handles content-block arrays
//   L5 — convertToAnthropicResponse() shape + disclosure prepended
//   L6 — convertToAnthropicResponse() empty content fallback
//   L7 — callLlamaFallback() success path with fetch mock
//   L8 — callLlamaFallback() HTTP 500 path returns ok:false
//   L9 — callLlamaFallback() timeout (AbortError) → ok:false
//   L10 — callLlamaFallback() no API key → ok:false
//   L11 — forceFallbackEnabled() honours env var ADVOCAT_FORCE_FALLBACK
//   L12 — index.ts wires the fallback module (source-grep contract)
//
// Run:
//   deno test --allow-env --allow-read --allow-net=esm.sh,deno.land \
//     supabase/functions/claude-proxy/__tests__/llama_fallback_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  callLlamaFallback,
  convertToAnthropicResponse,
  convertToOpenAIMessages,
  fallbackReasonFromStatus,
  FALLBACK_DISCLOSURE,
  forceFallbackEnabled,
  LLAMA_MODEL_ID,
  shouldFallback,
} from "../llama_fallback.ts";

// ────────────────────────────────────────────────────────────────────────────
// L1 — shouldFallback() activation matrix
// ────────────────────────────────────────────────────────────────────────────

Deno.test("L1 — shouldFallback: 200 OK does NOT trigger fallback", () => {
  assertEquals(shouldFallback(200), false);
});

Deno.test("L1 — shouldFallback: 400 Bad Request does NOT trigger", () => {
  assertEquals(shouldFallback(400), false);
});

Deno.test("L1 — shouldFallback: 401 Unauthorized does NOT trigger", () => {
  assertEquals(shouldFallback(401), false);
});

Deno.test("L1 — shouldFallback: 429 rate-limited DOES trigger", () => {
  assertEquals(shouldFallback(429), true);
});

Deno.test("L1 — shouldFallback: 500 Internal Server Error DOES trigger", () => {
  assertEquals(shouldFallback(500), true);
});

Deno.test("L1 — shouldFallback: 502 Bad Gateway DOES trigger", () => {
  assertEquals(shouldFallback(502), true);
});

Deno.test("L1 — shouldFallback: 503 Service Unavailable DOES trigger", () => {
  assertEquals(shouldFallback(503), true);
});

Deno.test("L1 — shouldFallback: 529 Anthropic overloaded DOES trigger", () => {
  assertEquals(shouldFallback(529), true);
});

// ────────────────────────────────────────────────────────────────────────────
// L2 — fallbackReasonFromStatus()
// ────────────────────────────────────────────────────────────────────────────

Deno.test("L2 — fallbackReasonFromStatus: 429 → claude_429", () => {
  assertEquals(fallbackReasonFromStatus(429), "claude_429");
});

Deno.test("L2 — fallbackReasonFromStatus: 500 → claude_5xx", () => {
  assertEquals(fallbackReasonFromStatus(500), "claude_5xx");
});

Deno.test("L2 — fallbackReasonFromStatus: 529 → claude_5xx", () => {
  assertEquals(fallbackReasonFromStatus(529), "claude_5xx");
});

// ────────────────────────────────────────────────────────────────────────────
// L3 — convertToOpenAIMessages: basic system + messages
// ────────────────────────────────────────────────────────────────────────────

Deno.test("L3 — convertToOpenAIMessages: prepends system message", () => {
  const out = convertToOpenAIMessages("You are Advocat.", [
    { role: "user", content: "Tere" },
  ]);
  assertEquals(out.length, 2);
  assertEquals(out[0], { role: "system", content: "You are Advocat." });
  assertEquals(out[1], { role: "user", content: "Tere" });
});

Deno.test("L3 — convertToOpenAIMessages: no system when systemPrompt empty", () => {
  const out = convertToOpenAIMessages("", [{ role: "user", content: "hi" }]);
  assertEquals(out.length, 1);
  assertEquals(out[0].role, "user");
});

Deno.test("L3 — convertToOpenAIMessages: preserves assistant turn", () => {
  const out = convertToOpenAIMessages("sys", [
    { role: "user", content: "Q?" },
    { role: "assistant", content: "A." },
    { role: "user", content: "Q2?" },
  ]);
  assertEquals(out.length, 4);
  assertEquals(out[1].role, "user");
  assertEquals(out[2].role, "assistant");
  assertEquals(out[3].content, "Q2?");
});

// ────────────────────────────────────────────────────────────────────────────
// L4 — convertToOpenAIMessages: content-block arrays
// ────────────────────────────────────────────────────────────────────────────

Deno.test("L4 — convertToOpenAIMessages: flattens content-block array", () => {
  const out = convertToOpenAIMessages(
    [
      { type: "text", text: "Block 1." },
      { type: "text", text: "Block 2." },
    ],
    [{ role: "user", content: "hi" }],
  );
  assertEquals(out[0].role, "system");
  assertStringIncludes(out[0].content, "Block 1.");
  assertStringIncludes(out[0].content, "Block 2.");
});

Deno.test("L4 — convertToOpenAIMessages: handles message with block content", () => {
  const out = convertToOpenAIMessages("sys", [
    {
      role: "user",
      content: [{ type: "text", text: "hello" }],
    },
  ]);
  assertEquals(out[1].content, "hello");
});

// ────────────────────────────────────────────────────────────────────────────
// L5/L6 — convertToAnthropicResponse: shape + disclosure
// ────────────────────────────────────────────────────────────────────────────

Deno.test("L5 — convertToAnthropicResponse: prepends bilingual disclosure", () => {
  const openai = {
    id: "deepinfra-id-123",
    choices: [
      { index: 0, message: { role: "assistant", content: "Vastus." }, finish_reason: "stop" },
    ],
    usage: { prompt_tokens: 10, completion_tokens: 5, total_tokens: 15 },
  };
  const r = convertToAnthropicResponse(openai, "claude_5xx");
  assertEquals(r.type, "message");
  assertEquals(r.role, "assistant");
  assertEquals(r.model, LLAMA_MODEL_ID);
  assertEquals(r.stop_reason, "end_turn");
  // Disclosure is at the front of the first text block.
  const text = r.content[0].text;
  assertStringIncludes(text, FALLBACK_DISCLOSURE.trim());
  assertStringIncludes(text, "Vastus.");
  // Disclosure precedes the LLM reply.
  const idxDisclosure = text.indexOf("varuv");
  const idxReply = text.indexOf("Vastus.");
  assert(idxDisclosure < idxReply, "disclosure must precede reply");
  // Usage mapped.
  assertEquals(r.usage.input_tokens, 10);
  assertEquals(r.usage.output_tokens, 5);
  // Fallback metadata.
  assertEquals(r.advocat_fallback.used, true);
  assertEquals(r.advocat_fallback.reason, "claude_5xx");
});

Deno.test("L6 — convertToAnthropicResponse: empty choices yields disclosure-only text", () => {
  const r = convertToAnthropicResponse({ choices: [] }, "claude_429");
  // Only the disclosure remains.
  assertStringIncludes(r.content[0].text, "varuv");
  assertEquals(r.advocat_fallback.reason, "claude_429");
});

// ────────────────────────────────────────────────────────────────────────────
// L7-L10 — callLlamaFallback() with fetch stub
// ────────────────────────────────────────────────────────────────────────────

const originalFetch = globalThis.fetch;

function installDeepinfraFetchStub(handler: (req: Request) => Promise<Response> | Response) {
  globalThis.fetch = ((input: RequestInfo | URL, init?: RequestInit) => {
    const req = new Request(
      typeof input === "string" ? input : input instanceof URL ? input.toString() : input.url,
      init,
    );
    return Promise.resolve(handler(req));
  }) as typeof fetch;
}

function restoreFetch() {
  globalThis.fetch = originalFetch;
}

Deno.test("L7 — callLlamaFallback: success path returns Anthropic-shaped response", async () => {
  installDeepinfraFetchStub(async (req) => {
    const body = await req.json() as Record<string, unknown>;
    // Sanity: we send OpenAI-shape, with messages[].
    assertEquals(typeof body.model, "string");
    assert(Array.isArray(body.messages));
    return new Response(
      JSON.stringify({
        id: "di-abc",
        choices: [
          {
            index: 0,
            message: { role: "assistant", content: "Tere, see on test." },
            finish_reason: "stop",
          },
        ],
        usage: { prompt_tokens: 12, completion_tokens: 4 },
      }),
      { status: 200, headers: { "content-type": "application/json" } },
    );
  });
  try {
    const out = await callLlamaFallback({
      systemPrompt: "You are Advocat.",
      messages: [{ role: "user", content: "Tere?" }],
      maxTokens: 500,
      reason: "claude_5xx",
      apiKey: "fake-deepinfra-key",
    });
    assertEquals(out.ok, true);
    assert(out.response !== undefined);
    const r = out.response!;
    assertEquals(r.model, LLAMA_MODEL_ID);
    assertStringIncludes(r.content[0].text, "Tere, see on test.");
    assertStringIncludes(r.content[0].text, "varuv");
  } finally {
    restoreFetch();
  }
});

Deno.test("L8 — callLlamaFallback: HTTP 500 returns ok:false with status", async () => {
  installDeepinfraFetchStub(() =>
    new Response("upstream boom", {
      status: 500,
      headers: { "content-type": "text/plain" },
    })
  );
  try {
    const out = await callLlamaFallback({
      systemPrompt: "sys",
      messages: [{ role: "user", content: "?" }],
      maxTokens: 100,
      reason: "claude_5xx",
      apiKey: "fake",
    });
    assertEquals(out.ok, false);
    assertEquals(out.status, 500);
    assertStringIncludes(String(out.error), "Deepinfra HTTP 500");
  } finally {
    restoreFetch();
  }
});

Deno.test("L9 — callLlamaFallback: AbortError surfaces as timeout", async () => {
  // Stub returns a promise that never resolves until aborted, so the
  // AbortController inside callLlamaFallback fires.
  globalThis.fetch = ((_input: RequestInfo | URL, init?: RequestInit) => {
    return new Promise<Response>((_resolve, reject) => {
      const signal = init?.signal;
      if (signal?.aborted) {
        const err = new DOMException("aborted", "AbortError");
        reject(err);
        return;
      }
      signal?.addEventListener("abort", () => {
        const err = new DOMException("aborted", "AbortError");
        reject(err);
      });
      // Otherwise hang forever.
    });
  }) as typeof fetch;
  try {
    const out = await callLlamaFallback({
      systemPrompt: "sys",
      messages: [{ role: "user", content: "?" }],
      maxTokens: 100,
      reason: "claude_timeout",
      apiKey: "fake",
      timeoutMs: 50, // trip fast for the test
    });
    assertEquals(out.ok, false);
    assertStringIncludes(String(out.error), "timeout");
  } finally {
    restoreFetch();
  }
});

Deno.test("L10 — callLlamaFallback: no API key returns ok:false (no fetch)", async () => {
  let fetchCalled = false;
  installDeepinfraFetchStub(() => {
    fetchCalled = true;
    return new Response("nope", { status: 500 });
  });
  // Ensure env is unset for this test, and pass empty override.
  const prev = Deno.env.get("DEEPINFRA_API_KEY");
  Deno.env.delete("DEEPINFRA_API_KEY");
  try {
    const out = await callLlamaFallback({
      systemPrompt: "sys",
      messages: [{ role: "user", content: "?" }],
      maxTokens: 100,
      reason: "claude_5xx",
      apiKey: "", // explicit override to empty
    });
    assertEquals(out.ok, false);
    assertStringIncludes(String(out.error), "DEEPINFRA_API_KEY");
    assertEquals(fetchCalled, false, "fetch must NOT be called without an API key");
  } finally {
    restoreFetch();
    if (prev !== undefined) Deno.env.set("DEEPINFRA_API_KEY", prev);
  }
});

// ────────────────────────────────────────────────────────────────────────────
// L11 — forceFallbackEnabled() honours env var
// ────────────────────────────────────────────────────────────────────────────

Deno.test("L11 — forceFallbackEnabled: 'true' returns true", () => {
  const prev = Deno.env.get("ADVOCAT_FORCE_FALLBACK");
  try {
    Deno.env.set("ADVOCAT_FORCE_FALLBACK", "true");
    assertEquals(forceFallbackEnabled(), true);
    Deno.env.set("ADVOCAT_FORCE_FALLBACK", "TRUE");
    assertEquals(forceFallbackEnabled(), true);
  } finally {
    if (prev !== undefined) Deno.env.set("ADVOCAT_FORCE_FALLBACK", prev);
    else Deno.env.delete("ADVOCAT_FORCE_FALLBACK");
  }
});

Deno.test("L11 — forceFallbackEnabled: unset returns false", () => {
  const prev = Deno.env.get("ADVOCAT_FORCE_FALLBACK");
  try {
    Deno.env.delete("ADVOCAT_FORCE_FALLBACK");
    assertEquals(forceFallbackEnabled(), false);
    Deno.env.set("ADVOCAT_FORCE_FALLBACK", "false");
    assertEquals(forceFallbackEnabled(), false);
    Deno.env.set("ADVOCAT_FORCE_FALLBACK", "1");
    // Only the literal "true" (case-insensitive) is honoured — "1" is NOT.
    assertEquals(forceFallbackEnabled(), false);
  } finally {
    if (prev !== undefined) Deno.env.set("ADVOCAT_FORCE_FALLBACK", prev);
    else Deno.env.delete("ADVOCAT_FORCE_FALLBACK");
  }
});

// ────────────────────────────────────────────────────────────────────────────
// L12 — source-code contract: index.ts wires the fallback
// ────────────────────────────────────────────────────────────────────────────

Deno.test("L12 — claude-proxy/index.ts imports llama_fallback helpers", async () => {
  const src = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  assertStringIncludes(src, "llama_fallback.ts");
  assertStringIncludes(src, "callLlamaFallback");
  assertStringIncludes(src, "shouldFallback");
  assertStringIncludes(src, "forceFallbackEnabled");
});

Deno.test("L12 — claude-proxy/index.ts wires fallback in streaming AND non-streaming paths", async () => {
  const src = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  assertStringIncludes(src, "runLlamaFallbackForStream");
  assertStringIncludes(src, "runLlamaFallbackForJson");
  // X-Advocat-Model-Used header must be set somewhere.
  assertStringIncludes(src, "X-Advocat-Model-Used");
});
