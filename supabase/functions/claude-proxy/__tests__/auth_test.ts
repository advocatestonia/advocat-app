// Deno tests for claude-proxy auth gate (SECURITY 2026-05-04 U1+U2+U3).
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-env --allow-read --allow-net=esm.sh,deno.land \
//     supabase/functions/claude-proxy/__tests__/auth_test.ts
//
// These tests cover the SHARED auth gate (`requireUserWithRateLimit`) that
// claude-proxy now delegates to, exercising the three cases the security
// audit called out:
//
//   U1-A — POST with no Authorization header           → 401
//   U1-B — POST with the public anon-key Bearer token  → 401
//   U1-C — POST with a real authenticated user JWT     → allow (200 mock)
//
// We don't spin up the full handler here (that would need a live Anthropic
// key + a real Supabase project); instead we verify the gate behaviour at
// the helper level — which is the actual security boundary — and then add
// a static check on claude-proxy/index.ts to confirm the gate is wired
// before any forward to Anthropic.
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

// Stub env BEFORE importing the helper.
Deno.env.set("SUPABASE_URL", "https://example.supabase.co");
Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "fake-service-key");

const { requireUserWithRateLimit, __resetRateLimitForTest } = await import(
  "../../_shared/auth.ts"
);

// Stub the supabase-js auth.getUser call by monkey-patching globalThis.fetch.
// requireUserWithRateLimit ultimately calls supabase.auth.getUser(token),
// which under the hood calls /auth/v1/user. We intercept that.
//
// Returning shape:
//   anon-key  → { data: { user: null }, error: { message: "..." } }
//             → supabase-js surfaces this as { user: null, error }
//   user-jwt  → { id, email, role: "authenticated", aud: "authenticated" }
//
// The supabase-js client wraps the bare HTTP response, so what we need to
// return from /auth/v1/user is just the User row, NOT the wrapper.

const ANON_KEY_TOKEN = "anon.fake.jwt"; // sentinel — real anon JWT shape doesn't matter
const USER_JWT_TOKEN = "user.fake.jwt";
const SERVICE_ROLE_TOKEN = "service.fake.jwt";

const originalFetch = globalThis.fetch;

function installFetchStub() {
  globalThis.fetch = ((input: RequestInfo | URL, init?: RequestInit) => {
    const url = typeof input === "string"
      ? input
      : input instanceof URL
      ? input.toString()
      : input.url;
    if (url.includes("/auth/v1/user")) {
      const auth = (init?.headers as Record<string, string> | undefined)?.[
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
      if (auth.includes(SERVICE_ROLE_TOKEN)) {
        // Service-role JWT — getUser would return a synthetic principal
        // with role: "service_role". The hardened gate must reject this.
        return Promise.resolve(
          new Response(
            JSON.stringify({
              id: "00000000-0000-0000-0000-000000000002",
              email: undefined,
              role: "service_role",
              aud: "authenticated",
            }),
            { status: 200, headers: { "Content-Type": "application/json" } },
          ),
        );
      }
      // Anon key (or any other unknown token): Supabase responds 401
      // with { code, message } — supabase-js surfaces this as
      // { user: null, error }.
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

function mockReq(headers: Record<string, string> = {}): Request {
  return new Request("https://example.supabase.co/functions/v1/claude-proxy", {
    method: "POST",
    headers: new Headers({ "Content-Type": "application/json", ...headers }),
    body: JSON.stringify({ messages: [{ role: "user", content: "hi" }] }),
  });
}

// ---- U1-A — no Authorization header → 401 ----------------------------------

Deno.test("U1-A — POST with NO Authorization header returns 401", async () => {
  __resetRateLimitForTest();
  installFetchStub();
  try {
    const res = await requireUserWithRateLimit(mockReq(), {
      bucket: "claude-proxy",
      maxPerMinute: 10,
    });
    assertEquals(res.kind, "deny");
    if (res.kind === "deny") {
      assertEquals(res.response.status, 401);
      const body = await res.response.text();
      assertStringIncludes(body, "Unauthorized");
    }
  } finally {
    restoreFetch();
  }
});

// ---- U1-B — anon-key Bearer token → 401 ------------------------------------

Deno.test({
  name: "U1-B — POST with anon-key Bearer token returns 401 (no anonymousPerMinute)",
  // supabase-js startAutoRefresh starts a timer+interval internally; disable
  // leak sanitizers so the test doesn't fail due to that external behaviour.
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
          // ⚠️ NO anonymousPerMinute — this is the security contract.
        },
      );
      assertEquals(res.kind, "deny");
      if (res.kind === "deny") {
        assertEquals(res.response.status, 401);
        const body = await res.response.text();
        assertStringIncludes(body, "Invalid session");
      }
    } finally {
      restoreFetch();
    }
  },
});

// ---- U1-B-bis — service-role JWT also rejected -----------------------------

Deno.test({
  name: "U1-B-bis — POST with service-role JWT returns 401 (defence-in-depth)",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    __resetRateLimitForTest();
    installFetchStub();
    try {
      const res = await requireUserWithRateLimit(
        mockReq({ Authorization: `Bearer ${SERVICE_ROLE_TOKEN}` }),
        {
          bucket: "claude-proxy",
          maxPerMinute: 10,
        },
      );
      assertEquals(res.kind, "deny");
      if (res.kind === "deny") {
        assertEquals(res.response.status, 401);
      }
    } finally {
      restoreFetch();
    }
  },
});

// ---- U1-C — real authenticated user JWT → allow ----------------------------

Deno.test({
  name: "U1-C — POST with real authenticated user JWT is allowed",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    __resetRateLimitForTest();
    installFetchStub();
    try {
      const res = await requireUserWithRateLimit(
        mockReq({ Authorization: `Bearer ${USER_JWT_TOKEN}` }),
        {
          bucket: "claude-proxy",
          maxPerMinute: 10,
        },
      );
      assertEquals(res.kind, "allow");
      if (res.kind === "allow") {
        assertEquals(res.user.id, "00000000-0000-0000-0000-000000000001");
        assertEquals(res.user.email, "real-user@example.com");
      }
    } finally {
      restoreFetch();
    }
  },
});

// ---- Static contract — handler wires the gate BEFORE Anthropic forward -----

Deno.test(
  "U1-D — handler calls requireUserWithRateLimit BEFORE any Anthropic fetch",
  () => {
    const src = Deno.readTextFileSync(
      new URL("../index.ts", import.meta.url),
    );
    const stripped = src
      .replace(/\/\*[\s\S]*?\*\//g, "")
      .replace(/^\s*\/\/.*$/gm, "");
    const gateIdx = stripped.indexOf("requireUserWithRateLimit(");
    const anthropicIdx = stripped.indexOf("api.anthropic.com");
    assert(
      gateIdx !== -1,
      "claude-proxy must call requireUserWithRateLimit",
    );
    assert(
      anthropicIdx !== -1,
      "claude-proxy must reference api.anthropic.com",
    );
    assert(
      gateIdx < anthropicIdx,
      "auth gate must run BEFORE the Anthropic forward (gate at " +
        `${gateIdx}, anthropic at ${anthropicIdx})`,
    );
  },
);

Deno.test(
  "U3 — handler calls check-ai-quota BEFORE any Anthropic fetch",
  () => {
    const src = Deno.readTextFileSync(
      new URL("../index.ts", import.meta.url),
    );
    const stripped = src
      .replace(/\/\*[\s\S]*?\*\//g, "")
      .replace(/^\s*\/\/.*$/gm, "");
    // The "check-ai-quota" string appears in both the call-site URL (inside
    // checkQuota's fetch) and in the function definition, which is declared
    // after the Anthropic fetch helpers in source order. Instead, look for the
    // checkQuota() call-site in the request handler, which must appear before
    // any forward to api.anthropic.com.
    const quotaCallIdx = stripped.indexOf("checkQuota(");
    const anthropicIdx = stripped.indexOf("api.anthropic.com");
    assert(quotaCallIdx !== -1, "claude-proxy must call checkQuota()");
    assert(anthropicIdx !== -1, "claude-proxy must reference api.anthropic.com");
    assert(
      quotaCallIdx < anthropicIdx,
      "quota probe (checkQuota call) must run BEFORE the Anthropic forward " +
        `(checkQuota at ${quotaCallIdx}, anthropic at ${anthropicIdx})`,
    );
  },
);
