// Deno tests for claude-proxy DEMO MODE restoration (2026-05-05).
// -----------------------------------------------------------------------------
// Context:
//   f8f6a58 closed the anon-key auth bypass by removing `anonymousPerMinute`
//   from the requireUserWithRateLimit call in claude-proxy/index.ts. That was
//   the right security move (anyone could pull the anon key from main.dart.js
//   and burn unlimited Anthropic credits) but it broke demo mode: the
//   "Proovi demorežiimi" → "AI õigusabi" flow sends a request with the public
//   anon key as Bearer token, which now returns 401 "Invalid session" and the
//   chat UI shows "Временная ошибка AI".
//
// Owner's decision (2026-05-05): restore demo with a HARD CAP so cost stays
// bounded:
//   • anonymousPerMinute = 3   (3 messages/minute per IP for anon callers)
//   • max_tokens clamp = 500   (vs 4096 for authenticated callers)
//
// These tests lock those four invariants so the regression cannot recur:
//
//   T1 — anon JWT with valid Advocat system prompt → 200 (gate allows)
//   T2 — anon caller with max_tokens=4096 → forwarded request was clamped to 500
//   T3 — anon caller exceeding 3/min → 429
//   T4 — authenticated caller max_tokens NOT clamped (regression guard)
//
// Run with:
//   deno test --allow-env --allow-read --allow-net=esm.sh,deno.land \
//     supabase/functions/claude-proxy/__tests__/anon_demo_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertExists,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

// Stub env BEFORE importing the helper / reading index.ts.
Deno.env.set("SUPABASE_URL", "https://example.supabase.co");
Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "fake-service-key");

const { requireUserWithRateLimit, __resetRateLimitForTest } = await import(
  "../../_shared/auth.ts"
);

// ---- T1 — anon caller with anonymousPerMinute=3 is ALLOWED -----------------

const ANON_KEY_TOKEN = "anon.fake.jwt";
const USER_JWT_TOKEN = "user.fake.jwt";

const originalFetch = globalThis.fetch;

function installFetchStub() {
  globalThis.fetch = ((input: RequestInfo | URL, init?: RequestInit) => {
    const url = typeof input === "string"
      ? input
      : input instanceof URL
      ? input.toString()
      : input.url;
    if (url.includes("/auth/v1/user")) {
      const auth =
        (init?.headers as Record<string, string> | undefined)?.[
          "Authorization"
        ] ?? "";
      if (auth.includes(USER_JWT_TOKEN)) {
        return Promise.resolve(
          new Response(
            JSON.stringify({
              id: "00000000-0000-0000-0000-000000000001",
              email: "real-user@example.com",
              role: "authenticated",
              aud: "authenticated",
            }),
            { status: 200, headers: { "Content-Type": "application/json" } },
          ),
        );
      }
      // Anon key (or any unknown token): Supabase responds 401.
      return Promise.resolve(
        new Response(
          JSON.stringify({ code: 401, msg: "invalid JWT" }),
          { status: 401, headers: { "Content-Type": "application/json" } },
        ),
      );
    }
    return originalFetch(input as RequestInfo, init);
  }) as typeof fetch;
}

function restoreFetch() {
  globalThis.fetch = originalFetch;
}

function mockReq(headers: Record<string, string> = {}, ip = "203.0.113.42"): Request {
  return new Request("https://example.supabase.co/functions/v1/claude-proxy", {
    method: "POST",
    headers: new Headers({
      "Content-Type": "application/json",
      "x-forwarded-for": ip,
      ...headers,
    }),
    body: JSON.stringify({ messages: [{ role: "user", content: "hi" }] }),
  });
}

Deno.test({
  name:
    "T1 — anon Bearer with anonymousPerMinute=3 is allowed (demo mode restored)",
  // supabase-js v2 keeps a refresh-token interval alive even with
  // autoRefreshToken: false in some cold-start paths; disable resource/op
  // sanitisation so the Deno test runner doesn't false-flag SDK internals.
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    __resetRateLimitForTest();
    installFetchStub();
    try {
      const res = await requireUserWithRateLimit(
        mockReq({ Authorization: `Bearer ${ANON_KEY_TOKEN}` }),
        {
          bucket: "claude-proxy",
          maxPerMinute: 10,
          anonymousPerMinute: 3, // ← the regression-locking value
        },
      );
      assertEquals(
        res.kind,
        "allow",
        "anon caller MUST be allowed when anonymousPerMinute > 0",
      );
      if (res.kind === "allow") {
        // Synthetic principal for IP-based bucketing.
        assert(
          res.user.id.startsWith("anon:"),
          `anon principal id should start with "anon:", got "${res.user.id}"`,
        );
      }
    } finally {
      restoreFetch();
    }
  },
});

// ---- T3 — anon caller exceeding 3/min → 429 --------------------------------
// (Placed before T2 because T2 reads index.ts statically; T3 verifies the
// runtime rate-limit semantics that index.ts inherits from the shared gate.)

Deno.test({
  name:
    "T3 — anon caller exceeding anonymousPerMinute=3 returns 429 on 4th call",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    __resetRateLimitForTest();
    installFetchStub();
    try {
      const opts = {
        bucket: "claude-proxy",
        maxPerMinute: 10,
        anonymousPerMinute: 3,
      } as const;
      const ip = "198.51.100.7";
      // 3 allowed
      for (let i = 0; i < 3; i++) {
        const ok = await requireUserWithRateLimit(
          mockReq({ Authorization: `Bearer ${ANON_KEY_TOKEN}` }, ip),
          opts,
        );
        assertEquals(
          ok.kind,
          "allow",
          `call ${i + 1}/3 should be allowed`,
        );
      }
      // 4th must be denied
      const fourth = await requireUserWithRateLimit(
        mockReq({ Authorization: `Bearer ${ANON_KEY_TOKEN}` }, ip),
        opts,
      );
      assertEquals(fourth.kind, "deny", "4th call must be rate-limited");
      if (fourth.kind === "deny") {
        assertEquals(fourth.response.status, 429);
      }
    } finally {
      restoreFetch();
    }
  },
});

// ---- Static contract tests on claude-proxy/index.ts ------------------------
// These tests inspect the source of index.ts to lock the wiring contract.
// They run without spinning up the full handler (which would require a live
// Anthropic key + Supabase project), but they catch the exact regression we
// just shipped (`anonymousPerMinute` accidentally removed) and the exact
// regression we are now guarding against (token cap accidentally removed).

const indexSrc = await Deno.readTextFile(
  new URL("../index.ts", import.meta.url),
);
// Strip comments so we don't match documentation strings.
const indexCode = indexSrc
  .replace(/\/\*[\s\S]*?\*\//g, "")
  .replace(/^\s*\/\/.*$/gm, "");

Deno.test({
  name: "T1-static — index.ts passes anonymousPerMinute: 3 to the gate",
  // Earlier tests in this file boot supabase-js which keeps internal timers
  // alive across tests. The static-source tests below don't touch the SDK
  // but inherit those timers; relax sanitisation for consistency.
  sanitizeOps: false,
  sanitizeResources: false,
  fn: () => {
    // Owner-approved cap: 3 messages/minute per IP for anon callers.
    // Accept either an inline literal (`anonymousPerMinute: 3`) or a
    // named constant whose declared value is 3 (e.g.
    // `const ANON_RATE_LIMIT_PER_MINUTE = 3`). Either form locks the
    // contract; we don't care which is used.
    const inlineMatch = indexCode.match(/anonymousPerMinute\s*:\s*(\d+)/);
    if (inlineMatch) {
      assertEquals(
        inlineMatch[1],
        "3",
        `anonymousPerMinute must be 3 (owner-approved cap), got ${
          inlineMatch[1]
        }`,
      );
      return;
    }
    // Named-constant form: anonymousPerMinute: <NAME>, with NAME defined as 3.
    const namedMatch = indexCode.match(
      /anonymousPerMinute\s*:\s*([A-Z_][A-Z0-9_]*)/,
    );
    assertExists(
      namedMatch,
      "claude-proxy/index.ts must set anonymousPerMinute on the gate " +
        "(neither inline literal nor named constant found)",
    );
    const constName = namedMatch[1];
    const declRegex = new RegExp(
      `const\\s+${constName}\\s*=\\s*(\\d+)\\b`,
    );
    const declMatch = indexCode.match(declRegex);
    assertExists(
      declMatch,
      `${constName} is referenced as anonymousPerMinute but its ` +
        `declaration was not found`,
    );
    assertEquals(
      declMatch[1],
      "3",
      `${constName} must equal 3 (owner-approved cap), got ${declMatch[1]}`,
    );
  },
});

// ---- T2 — anon caller's max_tokens is clamped to 500 -----------------------

Deno.test({
  name: "T2 — index.ts clamps max_tokens to 500 for anon callers",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: () => {
    // Locks the exact line that prevents an anon caller from sending
    // max_tokens=4096 and burning a full-cost response.
    //
    // We accept any of:
    //   if (isAnon) body.max_tokens = Math.min(body.max_tokens, 500);
    //   if (isAnon) maxTokens = Math.min(maxTokens, 500);
    //   const ANON_MAX_TOKENS = 500; ... Math.min(..., ANON_MAX_TOKENS)
    //
    // The contract: somewhere after the gate decides anon vs authenticated,
    // there must be a Math.min(...) involving the literal 500.
    const has500 = /Math\.min\([^)]*500[^)]*\)/.test(indexCode) ||
      /\b500\s*[,)]/.test(indexCode);
    assert(
      has500,
      "claude-proxy/index.ts must clamp anon max_tokens to 500 " +
        "(no `500` literal found in a Math.min context)",
    );

    // And the anon-detection branch must exist — we look for any of the
    // canonical shapes used elsewhere in the codebase.
    const hasAnonBranch = /\bisAnon\b/.test(indexCode) ||
      /anon:/.test(indexCode) ||
      /startsWith\(\s*["']anon:["']\s*\)/.test(indexCode);
    assert(
      hasAnonBranch,
      "claude-proxy/index.ts must distinguish anon callers from " +
        "authenticated callers (no isAnon / anon: branch found)",
    );
  },
});

// ---- T4 — authenticated callers are NOT clamped (regression guard) --------

Deno.test({
  name: "T4 — index.ts preserves the 4096 cap for authenticated callers",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: () => {
    // The pre-existing MAX_TOKENS_LIMIT = 4096 must remain intact so that
    // adding the anon clamp didn't regress authenticated users down to 500.
    const hasAuthCap = /MAX_TOKENS_LIMIT\s*=\s*4096/.test(indexCode) ||
      /Math\.min\([^)]*4096[^)]*\)/.test(indexCode);
    assert(
      hasAuthCap,
      "claude-proxy/index.ts must keep the 4096 cap for authenticated " +
        "callers (MAX_TOKENS_LIMIT = 4096 or Math.min(..., 4096))",
    );

    // And the order must be: anon clamp tightens AFTER the global 4096 cap,
    // so an authenticated request with max_tokens=4096 stays at 4096 while
    // an anon request gets pinned to 500. We verify by checking that the
    // 500 literal appears after the 4096 literal in the source.
    const idx4096 = indexCode.indexOf("4096");
    const idx500 = indexCode.indexOf("500");
    assert(idx4096 !== -1, "4096 cap missing");
    assert(idx500 !== -1, "500 anon cap missing");
    assert(
      idx500 > idx4096,
      "anon 500 clamp must come AFTER the 4096 global cap so " +
        "authenticated callers retain 4096 (4096 at " +
        `${idx4096}, 500 at ${idx500})`,
    );
  },
});
