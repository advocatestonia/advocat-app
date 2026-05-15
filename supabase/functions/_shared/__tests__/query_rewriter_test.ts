// query_rewriter_test.ts — вабанк A2 (2026-05-15)
// -----------------------------------------------------------------------------
// Pure-module tests for query_rewriter.ts. The Haiku call is injected via the
// `callHaiku` dep so every test is deterministic + offline.
//
// Run:
//   deno test --allow-env \
//     supabase/functions/_shared/__tests__/query_rewriter_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  _queryRewriterCacheSize,
  _resetQueryRewriterCache,
  type HaikuJsonCaller,
  QUERY_REWRITER_CACHE_MAX,
  QUERY_REWRITER_MODEL,
  QUERY_REWRITER_SYSTEM,
  rewriteQueryForRetrieval,
} from "../query_rewriter.ts";

// ─── Fixtures ───────────────────────────────────────────────────────────────

function jsonCaller(out: unknown): HaikuJsonCaller {
  return async () => JSON.stringify(out);
}

function spyCaller(out: unknown): {
  caller: HaikuJsonCaller;
  calls: number;
  lastArgs: Parameters<HaikuJsonCaller>[0] | null;
} {
  const spy = {
    calls: 0,
    lastArgs: null as Parameters<HaikuJsonCaller>[0] | null,
    caller: (async (args) => {
      spy.calls += 1;
      spy.lastArgs = args;
      return JSON.stringify(out);
    }) as HaikuJsonCaller,
  };
  return spy;
}

// ─── QR-T01 — happy path: RU question → FI statute terms ───────────────────

Deno.test("QR-T01 — RU deportation query rewrites to FI Ulkomaalaislaki", async () => {
  _resetQueryRewriterCache();
  const caller = jsonCaller({
    rewritten: "karkottaminen Ulkomaalaislaki §149",
    originalLang: "ru",
    augmented: [
      "что делать если меня депортируют из Финляндии",
      "depriving residence permit Finland deportation",
    ],
  });

  const result = await rewriteQueryForRetrieval(
    "что делать если меня депортируют из Финляндии",
    "fi",
    { callHaiku: caller },
  );

  assertEquals(result.rewritten, "karkottaminen Ulkomaalaislaki §149");
  assertEquals(result.originalLang, "ru");
  assert(result.augmented.length >= 2);
  // The original query is always in augmented[0].
  assertEquals(
    result.augmented[0],
    "что делать если меня депортируют из Финляндии",
  );
});

// ─── QR-T02 — empty query short-circuits ────────────────────────────────────

Deno.test("QR-T02 — empty query returns degenerate result without calling Haiku", async () => {
  _resetQueryRewriterCache();
  const spy = spyCaller({ rewritten: "X", originalLang: "ru", augmented: [] });

  const result = await rewriteQueryForRetrieval("   ", "fi", {
    callHaiku: spy.caller,
  });

  assertEquals(result.rewritten, "");
  assertEquals(result.augmented.length, 0);
  assertEquals(spy.calls, 0, "Haiku not called for empty query");
});

// ─── QR-T03 — cache hit avoids the second Haiku call ────────────────────────

Deno.test("QR-T03 — second identical call is served from cache", async () => {
  _resetQueryRewriterCache();
  const spy = spyCaller({
    rewritten: "karkottaminen Ulkomaalaislaki §149",
    originalLang: "ru",
    augmented: ["question1", "question2"],
  });

  await rewriteQueryForRetrieval("депортация", "fi", { callHaiku: spy.caller });
  await rewriteQueryForRetrieval("депортация", "fi", { callHaiku: spy.caller });
  await rewriteQueryForRetrieval("депортация", "fi", { callHaiku: spy.caller });

  assertEquals(spy.calls, 1, "Haiku called only once for identical inputs");
});

// ─── QR-T04 — different jurisdiction = different cache slot ─────────────────

Deno.test("QR-T04 — distinct jurisdictions cache independently", async () => {
  _resetQueryRewriterCache();
  const spy = spyCaller({
    rewritten: "Q",
    originalLang: "ru",
    augmented: ["q"],
  });

  await rewriteQueryForRetrieval("aliment", "fi", { callHaiku: spy.caller });
  await rewriteQueryForRetrieval("aliment", "ee", { callHaiku: spy.caller });
  await rewriteQueryForRetrieval("aliment", "eu", { callHaiku: spy.caller });

  assertEquals(spy.calls, 3, "each jurisdiction triggers its own Haiku call");
});

// ─── QR-T05 — Haiku throws → degraded result, no cache pollution ───────────

Deno.test("QR-T05 — Haiku failure falls back to original query, no cache", async () => {
  _resetQueryRewriterCache();
  const before = _queryRewriterCacheSize();
  const failing: HaikuJsonCaller = async () => {
    throw new Error("network down");
  };

  const result = await rewriteQueryForRetrieval(
    "kuidas korterit jagada",
    "ee",
    { callHaiku: failing },
  );

  assertEquals(result.rewritten, "kuidas korterit jagada");
  assertEquals(result.originalLang, "unknown");
  assertEquals(result.augmented, ["kuidas korterit jagada"]);
  // Failure must NOT cache — retry on next call.
  assertEquals(_queryRewriterCacheSize(), before);
});

// ─── QR-T06 — invalid JSON output → degraded result ─────────────────────────

Deno.test("QR-T06 — Haiku returns garbage → original query preserved", async () => {
  _resetQueryRewriterCache();
  const garbage: HaikuJsonCaller = async () => "I am sorry I cannot help with that.";

  const result = await rewriteQueryForRetrieval(
    "trahv vaide",
    "ee",
    { callHaiku: garbage },
  );

  assertEquals(result.rewritten, "trahv vaide");
  assertEquals(result.originalLang, "unknown");
});

// ─── QR-T07 — Haiku JSON wrapped in ```json fences is parsed ────────────────

Deno.test("QR-T07 — Haiku markdown-fenced JSON is unwrapped", async () => {
  _resetQueryRewriterCache();
  const fenced: HaikuJsonCaller = async () => (
    "```json\n" +
    JSON.stringify({
      rewritten: "ühisvara jagamine PKS § 36",
      originalLang: "ru",
      augmented: ["x", "y"],
    }) +
    "\n```"
  );

  const result = await rewriteQueryForRetrieval(
    "как поделить квартиру в браке",
    "ee",
    { callHaiku: fenced },
  );

  assertEquals(result.rewritten, "ühisvara jagamine PKS § 36");
});

// ─── QR-T08 — system prompt and model identity are stable ───────────────────

Deno.test("QR-T08 — system prompt mentions statute-grade rewriting rules", () => {
  // Sanity: contract test on the prompt content. Drifting these is fine but
  // requires a deliberate edit (caught here).
  assertStringIncludes(QUERY_REWRITER_SYSTEM, "karkottaminen");
  assertStringIncludes(QUERY_REWRITER_SYSTEM, "ühisvara");
  assertStringIncludes(QUERY_REWRITER_SYSTEM, "STRICT JSON");
  assertStringIncludes(QUERY_REWRITER_SYSTEM, "augmented");
});

Deno.test("QR-T09 — model id pinned to Haiku 4.5", () => {
  assertEquals(QUERY_REWRITER_MODEL, "claude-haiku-4-5-20251001");
});

// ─── QR-T10 — call args carry jurisdiction and query ────────────────────────

Deno.test("QR-T10 — call args expose jurisdiction + query to Haiku", async () => {
  _resetQueryRewriterCache();
  const spy = spyCaller({
    rewritten: "X",
    originalLang: "ru",
    augmented: ["x"],
  });

  await rewriteQueryForRetrieval("депортация", "fi", { callHaiku: spy.caller });

  assert(spy.lastArgs);
  assertEquals(spy.lastArgs!.model, "claude-haiku-4-5-20251001");
  assert(spy.lastArgs!.system.length > 100);
  assertStringIncludes(spy.lastArgs!.userMessage, "fi");
  assertStringIncludes(spy.lastArgs!.userMessage, "депортация");
});

// ─── QR-T11 — cache LRU eviction at cap ─────────────────────────────────────

Deno.test("QR-T11 — cache evicts oldest at MAX size", async () => {
  _resetQueryRewriterCache();
  const caller = jsonCaller({
    rewritten: "X",
    originalLang: "ru",
    augmented: ["x"],
  });

  // Fill 5 past the cap.
  for (let i = 0; i < QUERY_REWRITER_CACHE_MAX + 5; i++) {
    await rewriteQueryForRetrieval(`query-${i}`, "fi", { callHaiku: caller });
  }
  assertEquals(_queryRewriterCacheSize(), QUERY_REWRITER_CACHE_MAX);
});

// ─── QR-T12 — augmented array always includes original first ────────────────

Deno.test("QR-T12 — augmented always begins with original query", async () => {
  _resetQueryRewriterCache();
  // Haiku forgets to include the original. Module must still include it.
  const caller = jsonCaller({
    rewritten: "Y",
    originalLang: "ru",
    augmented: ["only-the-paraphrase"],
  });

  const result = await rewriteQueryForRetrieval("original-q", "fi", {
    callHaiku: caller,
  });

  assertEquals(result.augmented[0], "original-q");
  assert(result.augmented.includes("only-the-paraphrase"));
});

// ─── QR-T13 — DE/RU jurisdictions are coerced upstream, not here ────────────
// The rewriter type only allows fi|ee|eu. DE/RU coercion lives in legal_lookup
// (projectRewriterJurisdiction). This test just locks down that the rewriter
// itself does not silently accept arbitrary strings via the typed API. The
// runtime is permissive (Deno is JS at runtime); we rely on the type fence
// during compile.

// ─── QR-T14 — augmented dedupes identical entries ───────────────────────────

Deno.test("QR-T14 — duplicate augmented entries are removed", async () => {
  _resetQueryRewriterCache();
  const caller = jsonCaller({
    rewritten: "X",
    originalLang: "ru",
    augmented: ["original-q", "original-q", "different"],
  });

  const result = await rewriteQueryForRetrieval("original-q", "fi", {
    callHaiku: caller,
  });

  // Original goes in at index 0; the explicit "original-q" from Haiku must dedupe.
  const occurrences = result.augmented.filter((a) => a === "original-q").length;
  assertEquals(occurrences, 1);
  assert(result.augmented.includes("different"));
});
