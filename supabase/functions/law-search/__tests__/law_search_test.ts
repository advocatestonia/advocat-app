// Deno tests for law-search edge function. Lock the wire-format contract that
// lib/services/law_search_client.dart depends on, plus the validation /
// graceful-degradation behaviour required by P0-2.
//
// Run from supabase/functions/law-search/ with:
//   deno test --allow-env --allow-read --allow-net=esm.sh,deno.land,api.openai.com
//
// We do NOT boot the full serve() handler (that would need a live Supabase
// project + OpenAI key). Instead we:
//   • test embed.ts directly with a fetch stub for OpenAI;
//   • static-source-test index.ts to lock validation thresholds, fallback
//     branches, and CORS wiring (matches the claude-proxy `anon_demo_test`
//     pattern in this codebase).

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

Deno.env.set("SUPABASE_URL", "https://example.supabase.co");
Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "fake-service-key");
Deno.env.set("OPENAI_API_KEY", "fake-openai-key");

const { embedQuery } = await import("../embed.ts");

// ---- Static-source contract on index.ts ------------------------------------

const indexSrc = await Deno.readTextFile(new URL("../index.ts", import.meta.url));
const indexCode = indexSrc
  .replace(/\/\*[\s\S]*?\*\//g, "")
  .replace(/^\s*\/\/.*$/gm, "");

Deno.test("index.ts — wire format matches law_search_client.dart", () => {
  // Client posts: { query, lang, match_count, similarity_threshold }.
  // Function MUST read those exact field names.
  for (const field of ["query", "lang", "match_count", "similarity_threshold"]) {
    assertStringIncludes(
      indexCode,
      `body.${field}`,
      `index.ts must read body.${field} (client wire shape)`,
    );
  }

  // Client expects { chunks: [...] } at the top level. The function MUST
  // return that key — `data['chunks']` is the canonical parser branch in
  // law_search_client.dart.
  assertStringIncludes(
    indexCode,
    "chunks",
    "index.ts must return a `chunks` array (client wire shape)",
  );

  // Client expects per-chunk fields — act_name, paragraph, body, similarity,
  // optional source_url. We grep for each so a future refactor that drops
  // one of them trips the test.
  for (const field of ["act_name", "paragraph", "body", "similarity", "source_url"]) {
    assertStringIncludes(
      indexCode,
      field,
      `index.ts response must include '${field}'`,
    );
  }
});

Deno.test("index.ts — validates lang against supported set", () => {
  // Function must reject anything outside et/ru/en with a 400.
  assertStringIncludes(indexCode, "SUPPORTED_LANGS");
  // Confirm the set contains the three langs the client will send.
  assert(
    /SUPPORTED_LANGS\s*=\s*new Set\(\[\s*"et"\s*,\s*"ru"\s*,\s*"en"\s*\]\)/
      .test(indexCode),
    "SUPPORTED_LANGS must be exactly {et, ru, en}",
  );
  // And there is a 400 path on the lang check.
  assert(
    /Invalid 'lang'/.test(indexCode),
    "Function must return a 400 on invalid lang",
  );
});

Deno.test("index.ts — match_count cap 50, threshold range [0,1]", () => {
  assertStringIncludes(indexCode, "MAX_MATCH_COUNT = 50");
  // similarity_threshold must reject < 0 or > 1.
  assert(
    /similarity_threshold[^]*?<\s*0\s*\|\|[^]*?>\s*1/.test(indexCode),
    "similarity_threshold must be range-checked to [0, 1]",
  );
});

Deno.test("index.ts — graceful no-op returns 200 + empty chunks", () => {
  // The emptyOk helper must exist and produce the wire-shape body.
  assertStringIncludes(indexCode, "emptyOk");
  assert(
    /chunks:\s*\[\]/.test(indexCode),
    "graceful no-op must return chunks: []",
  );
  // And the embed-failure path must call emptyOk (not throw 500).
  assert(
    /if\s*\(!embed\)\s*return\s*emptyOk/.test(indexCode),
    "embed null must collapse to emptyOk (P0-3 graceful contract)",
  );
});

Deno.test("index.ts — uses the shared CORS + auth gate (no duplicated wiring)", () => {
  assertStringIncludes(indexCode, '"../_shared/auth.ts"');
  assertStringIncludes(indexCode, "corsHeaders");
  assertStringIncludes(indexCode, "requireUserWithRateLimit");
  // OPTIONS branch returns CORS-only — pre-flight contract.
  assert(
    /OPTIONS[^]*?corsHeaders/.test(indexCode),
    "OPTIONS pre-flight must return corsHeaders",
  );
});

Deno.test("index.ts — rate-limit caps match the anon-friendly pattern", () => {
  // 10/min/IP for anon, 30/min for authenticated. These are the values in
  // the production wiring. If a future refactor drops anonymousPerMinute
  // entirely, demo-mode breaks (same regression class as claude-proxy
  // f8f6a58 → demo restore).
  assert(
    /anonymousPerMinute\s*:\s*ANON_RATE_LIMIT_PER_MINUTE/.test(indexCode) ||
      /anonymousPerMinute\s*:\s*\d+/.test(indexCode),
    "anon callers must be allowed (anonymousPerMinute set)",
  );
});

// ---- embedQuery runtime tests with a fetch stub ----------------------------

const originalFetch = globalThis.fetch;
function installEmbedStub(
  handler: (req: Request) => Promise<Response> | Response,
) {
  globalThis.fetch = ((input: RequestInfo | URL, init?: RequestInit) => {
    const url = typeof input === "string"
      ? input
      : input instanceof URL
      ? input.toString()
      : input.url;
    if (url.includes("/v1/embeddings")) {
      const r = new Request(url, init);
      return Promise.resolve(handler(r));
    }
    return originalFetch(input as RequestInfo, init);
  }) as typeof fetch;
}
function restoreFetch() {
  globalThis.fetch = originalFetch;
}

Deno.test({
  name: "embedQuery — happy path returns 1536-d vector + token usage",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    installEmbedStub(() =>
      new Response(
        JSON.stringify({
          data: [{ embedding: new Array(1536).fill(0.001) }],
          usage: { total_tokens: 12 },
        }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      )
    );
    try {
      const out = await embedQuery("hello", { apiKey: "fake" });
      assert(out !== null, "happy path must return a result");
      assertEquals(out!.embedding.length, 1536);
      assertEquals(out!.tokens, 12);
    } finally {
      restoreFetch();
    }
  },
});

Deno.test({
  name: "embedQuery — OpenAI 5xx collapses to null (graceful)",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    installEmbedStub(() => new Response("upstream blew up", { status: 503 }));
    try {
      const out = await embedQuery("hello", { apiKey: "fake" });
      assertEquals(out, null);
    } finally {
      restoreFetch();
    }
  },
});

Deno.test({
  name: "embedQuery — wrong-dim response collapses to null",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    installEmbedStub(() =>
      new Response(
        JSON.stringify({
          data: [{ embedding: new Array(3072).fill(0) }], // 3-large size
          usage: { total_tokens: 5 },
        }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      )
    );
    try {
      const out = await embedQuery("hello", { apiKey: "fake" });
      assertEquals(
        out,
        null,
        "non-1536-d embedding must be rejected (column type guard)",
      );
    } finally {
      restoreFetch();
    }
  },
});

Deno.test({
  name: "embedQuery — timeout collapses to null",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    installEmbedStub((req) =>
      new Promise<Response>((resolve, reject) => {
        // Hang until the AbortController fires.
        req.signal.addEventListener("abort", () => {
          reject(new DOMException("aborted", "AbortError"));
        });
      })
    );
    try {
      const out = await embedQuery("hello", {
        apiKey: "fake",
        timeoutMs: 30, // very short — abort before any real network.
      });
      assertEquals(out, null);
    } finally {
      restoreFetch();
    }
  },
});

Deno.test({
  name: "embedQuery — empty query returns null without calling OpenAI",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    let called = false;
    installEmbedStub(() => {
      called = true;
      return new Response("{}", { status: 200 });
    });
    try {
      const out = await embedQuery("   ", { apiKey: "fake" });
      assertEquals(out, null);
      assertEquals(called, false, "must not call OpenAI for empty query");
    } finally {
      restoreFetch();
    }
  },
});
