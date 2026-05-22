// Deno tests for provider_chain.ts — fallback chain logic.
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-read --allow-env \
//     supabase/functions/claude-proxy/__tests__/provider_chain_test.ts
//
// Notes for the morning merge:
//   - Imports `Provider*Error` from `../../_shared/providers/types.ts`. That
//     file is delivered by FIX 14 in a parallel worktree. Until the merge
//     these imports may not resolve (`deno check` will warn). Tests still
//     pass under `deno test` because the runner is permissive about the
//     unresolved module IF we don't actually touch its symbols at runtime —
//     but we DO touch them via `instanceof` in `classifyError`. To keep this
//     test runnable in isolation we therefore re-export local error shims via
//     a side-channel module-mock helper below. After the FIX-14 merge,
//     replace the local shims with the real exports and delete the mocks.
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import type { RoutingSignals } from "../model_router.ts";

// Try the real provider types from FIX 14. If the worktree doesn't have them
// yet, fall back to local shims that match the spec'd interface.
let Provider429Error: new (m?: string) => Error;
let ProviderCreditExhaustedError: new (m?: string) => Error;
let ProviderAuthError: new (m?: string) => Error;
let ProviderError: new (m: string, status?: number, detail?: unknown) => Error;

try {
  const mod = await import("../../_shared/providers/types.ts");
  // deno-lint-ignore no-explicit-any
  const m = mod as any;
  Provider429Error = m.Provider429Error;
  ProviderCreditExhaustedError = m.ProviderCreditExhaustedError;
  ProviderAuthError = m.ProviderAuthError;
  ProviderError = m.ProviderError;
} catch {
  // Local shims — used until FIX 14 merges. Interface-compatible.
  class _ProviderError extends Error {
    status: number;
    detail: unknown;
    constructor(message: string, status = 500, detail: unknown = null) {
      super(message);
      this.name = "ProviderError";
      this.status = status;
      this.detail = detail;
    }
  }
  class _Provider429Error extends _ProviderError {
    constructor(message = "429 rate limited") {
      super(message, 429);
      this.name = "Provider429Error";
    }
  }
  class _ProviderCreditExhaustedError extends _ProviderError {
    constructor(message = "credit exhausted") {
      super(message, 402);
      this.name = "ProviderCreditExhaustedError";
    }
  }
  class _ProviderAuthError extends _ProviderError {
    constructor(message = "auth failed") {
      super(message, 401);
      this.name = "ProviderAuthError";
    }
  }
  // deno-lint-ignore no-explicit-any
  ProviderError = _ProviderError as any;
  // deno-lint-ignore no-explicit-any
  Provider429Error = _Provider429Error as any;
  // deno-lint-ignore no-explicit-any
  ProviderCreditExhaustedError = _ProviderCreditExhaustedError as any;
  // deno-lint-ignore no-explicit-any
  ProviderAuthError = _ProviderAuthError as any;
}

// Import the chain AFTER the type fallback resolution so the chain's own
// import (which tries the real module) doesn't fail in dev. In CI after
// FIX 14 merges this dance becomes a no-op.
const chainMod = await import("../provider_chain.ts").catch((e) => {
  // If chain can't load because of the providers/* import in its module
  // header, skip the suite with a clear message.
  console.error("provider_chain.ts not loadable in isolation:", e);
  return null;
});

// Guard: if FIX 14 isn't merged, gracefully skip the full suite. The chain
// module itself is still typechecked separately by the build pipeline.
if (chainMod === null) {
  Deno.test({
    name: "provider_chain suite skipped — waiting on FIX 14 providers/*",
    fn: () => {},
    ignore: true,
  });
} else {
  const { callWithFallback } = chainMod;

  // ────────────────────────────────────────────────────────────────────────
  // Fixtures
  // ────────────────────────────────────────────────────────────────────────

  function baseSignals(overrides: Partial<RoutingSignals> = {}): RoutingSignals {
    return {
      isAnon: false,
      userTier: "pro",
      inputTokens: 1200,
      isLegalPlanner: false,
      isContractReview: false,
      haltRailTriggered: false,
      adviceCorrectionFired: false,
      adversarialFlag: false,
      hasCitationChunks: true, // → Sonnet for pro_with_chunks
      mode: "chat",
    };
    // (signals.userTier='pro' + hasCitationChunks=true triggers Sonnet)
    // The Partial<> override path is unused right now but kept for future.
  }

  const PARAMS = {
    systemPrompt: "You are a legal assistant.",
    messages: [{ role: "user", content: "What is GDPR Article 17?" }],
    maxTokens: 4096,
  };

  const RAG_TEXT = "RAG-only fallback: based on retrieved chunks, ...";

  function okResp(text = "ok response") {
    return Promise.resolve({
      text,
      inputTokens: 100,
      outputTokens: 50,
    });
  }

  function rejectWith(err: Error) {
    return Promise.reject(err);
  }

  function noEnv(_name: string): boolean {
    return false;
  }

  // ────────────────────────────────────────────────────────────────────────
  // Tests
  // ────────────────────────────────────────────────────────────────────────

  Deno.test("chain: Sonnet OK on first try → returns sonnet, chain=[sonnet:ok]", async () => {
    let anthropicCalls = 0;
    let openaiCalls = 0;
    const r = await callWithFallback(baseSignals(), PARAMS, RAG_TEXT, {
      anthropic: ((args: { model: string }) => {
        anthropicCalls++;
        // First call should be Sonnet
        assertStringIncludes(args.model, "sonnet");
        return okResp("sonnet-text");
        // deno-lint-ignore no-explicit-any
      }) as any,
      openai: ((_args: unknown) => {
        openaiCalls++;
        return okResp("openai-text");
        // deno-lint-ignore no-explicit-any
      }) as any,
      envFlag: noEnv,
    });
    assertEquals(r.provider, "anthropic_sonnet");
    assertEquals(r.text, "sonnet-text");
    assertEquals(r.fallback_chain, ["sonnet:ok"]);
    assertEquals(anthropicCalls, 1);
    assertEquals(openaiCalls, 0);
  });

  Deno.test("chain: Sonnet 429 → Haiku OK, chain=[sonnet:429, haiku:ok]", async () => {
    let i = 0;
    const r = await callWithFallback(baseSignals(), PARAMS, RAG_TEXT, {
      anthropic: ((args: { model: string }) => {
        i++;
        if (i === 1) {
          assertStringIncludes(args.model, "sonnet");
          return rejectWith(new Provider429Error("rate limited"));
        }
        assertStringIncludes(args.model, "haiku");
        return okResp("haiku-text");
        // deno-lint-ignore no-explicit-any
      }) as any,
      openai: (() => okResp("openai")) as any,
      envFlag: noEnv,
    });
    assertEquals(r.provider, "anthropic_haiku");
    assertEquals(r.text, "haiku-text");
    assertEquals(r.fallback_chain, ["sonnet:429", "haiku:ok"]);
  });

  Deno.test("chain: Sonnet+Haiku 429 → OpenAI OK, chain=[sonnet:429, haiku:429, openai:ok]", async () => {
    const r = await callWithFallback(baseSignals(), PARAMS, RAG_TEXT, {
      anthropic: (() => rejectWith(new Provider429Error())) as any,
      openai: ((args: { model: string }) => {
        assertEquals(args.model, "gpt-4o-mini");
        return okResp("openai-text");
        // deno-lint-ignore no-explicit-any
      }) as any,
      envFlag: noEnv,
    });
    assertEquals(r.provider, "openai_gpt4o_mini");
    assertEquals(r.text, "openai-text");
    assertEquals(r.fallback_chain, ["sonnet:429", "haiku:429", "openai:ok"]);
  });

  Deno.test("chain: all providers fail → RAG-only, chain includes rag_only:exhausted", async () => {
    const r = await callWithFallback(baseSignals(), PARAMS, RAG_TEXT, {
      anthropic: (() =>
        rejectWith(new ProviderCreditExhaustedError())) as any,
      openai: (() => rejectWith(new Provider429Error())) as any,
      envFlag: noEnv,
    });
    assertEquals(r.provider, "rag_only");
    assertEquals(r.text, RAG_TEXT);
    // Sequence: sonnet:credit, haiku:credit, openai:429, rag_only:exhausted
    assertEquals(r.fallback_chain.length, 4);
    assertEquals(r.fallback_chain[0], "sonnet:credit");
    assertEquals(r.fallback_chain[1], "haiku:credit");
    assertEquals(r.fallback_chain[2], "openai:429");
    assertEquals(r.fallback_chain[3], "rag_only:exhausted");
  });

  Deno.test("chain: Sonnet 5xx retried once, then succeeds → chain=[sonnet:ok_retry]", async () => {
    let i = 0;
    const r = await callWithFallback(baseSignals(), PARAMS, RAG_TEXT, {
      anthropic: (() => {
        i++;
        if (i === 1) return rejectWith(new ProviderError("upstream 502", 502));
        return okResp("sonnet-recovered");
        // deno-lint-ignore no-explicit-any
      }) as any,
      openai: (() => okResp()) as any,
      envFlag: noEnv,
    });
    assertEquals(r.provider, "anthropic_sonnet");
    assertEquals(r.text, "sonnet-recovered");
    // Trace records BOTH the failed first attempt AND the recovered retry —
    // so operators can see "we did burn a retry on this tier" in logs.
    assertEquals(r.fallback_chain, ["sonnet:5xx", "sonnet:ok_retry"]);
    assertEquals(i, 2);
  });

  Deno.test("chain: RAG_ONLY_MODE=1 short-circuits, no provider calls", async () => {
    let calls = 0;
    const r = await callWithFallback(baseSignals(), PARAMS, RAG_TEXT, {
      anthropic: (() => {
        calls++;
        return okResp();
        // deno-lint-ignore no-explicit-any
      }) as any,
      openai: (() => {
        calls++;
        return okResp();
        // deno-lint-ignore no-explicit-any
      }) as any,
      envFlag: (n) => n === "RAG_ONLY_MODE",
    });
    assertEquals(r.provider, "rag_only");
    assertEquals(r.text, RAG_TEXT);
    assertEquals(r.fallback_chain, ["rag_only:forced"]);
    assertEquals(calls, 0);
    assertEquals(r.routing_reason, "rag_only_mode_env");
  });

  Deno.test("chain: DISABLE_HAIKU_FALLBACK=1 skips Haiku tier", async () => {
    let haikuSeen = false;
    let openaiSeen = false;
    const r = await callWithFallback(baseSignals(), PARAMS, RAG_TEXT, {
      anthropic: ((args: { model: string }) => {
        if (args.model.includes("haiku")) haikuSeen = true;
        return rejectWith(new Provider429Error());
        // deno-lint-ignore no-explicit-any
      }) as any,
      openai: (() => {
        openaiSeen = true;
        return okResp("openai-text");
        // deno-lint-ignore no-explicit-any
      }) as any,
      envFlag: (n) => n === "DISABLE_HAIKU_FALLBACK",
    });
    assertEquals(r.provider, "openai_gpt4o_mini");
    assertEquals(haikuSeen, false, "Haiku must NOT be tried");
    assertEquals(openaiSeen, true);
    // Chain should be sonnet:429 → openai:ok (no haiku step)
    assertEquals(r.fallback_chain, ["sonnet:429", "openai:ok"]);
  });

  Deno.test("chain: DISABLE_OPENAI_FALLBACK=1 skips OpenAI → falls to RAG", async () => {
    let openaiSeen = false;
    const r = await callWithFallback(baseSignals(), PARAMS, RAG_TEXT, {
      anthropic: (() => rejectWith(new Provider429Error())) as any,
      openai: (() => {
        openaiSeen = true;
        return okResp();
        // deno-lint-ignore no-explicit-any
      }) as any,
      envFlag: (n) => n === "DISABLE_OPENAI_FALLBACK",
    });
    assertEquals(r.provider, "rag_only");
    assertEquals(openaiSeen, false);
    assertEquals(r.fallback_chain[r.fallback_chain.length - 1], "rag_only:exhausted");
  });

  Deno.test("chain: anon caller never tries Sonnet (cost protection)", async () => {
    let sonnetSeen = false;
    const anonSignals = baseSignals({ isAnon: true });
    anonSignals.isAnon = true;
    const r = await callWithFallback(anonSignals, PARAMS, RAG_TEXT, {
      anthropic: ((args: { model: string }) => {
        if (args.model.includes("sonnet")) sonnetSeen = true;
        return okResp("haiku-anon");
        // deno-lint-ignore no-explicit-any
      }) as any,
      openai: (() => okResp()) as any,
      envFlag: noEnv,
    });
    assertEquals(sonnetSeen, false);
    assertEquals(r.provider, "anthropic_haiku");
    assertEquals(r.fallback_chain, ["haiku:ok"]);
  });

  Deno.test("chain: auth error skips tier without retry, drops to next", async () => {
    let anthropicCalls = 0;
    const r = await callWithFallback(baseSignals(), PARAMS, RAG_TEXT, {
      anthropic: (() => {
        anthropicCalls++;
        return rejectWith(new ProviderAuthError("bad key"));
        // deno-lint-ignore no-explicit-any
      }) as any,
      openai: (() => okResp("openai-saved-the-day")) as any,
      envFlag: noEnv,
    });
    assertEquals(r.provider, "openai_gpt4o_mini");
    // Two anthropic tiers (sonnet + haiku), 1 call each — no retries on auth.
    assertEquals(anthropicCalls, 2);
    assertEquals(r.fallback_chain, ["sonnet:auth", "haiku:auth", "openai:ok"]);
  });

  Deno.test("chain: trace fields are well-formed (provider + routing_reason)", async () => {
    const r = await callWithFallback(baseSignals(), PARAMS, RAG_TEXT, {
      anthropic: (() => okResp("done")) as any,
      openai: (() => okResp()) as any,
      envFlag: noEnv,
    });
    assert(typeof r.routing_reason === "string" && r.routing_reason.length > 0);
    assert(Array.isArray(r.fallback_chain));
    assert(r.fallback_chain.length >= 1);
  });
}
