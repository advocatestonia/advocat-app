// legal_lookup_v3_test.ts — вабанк A2 (2026-05-15)
// -----------------------------------------------------------------------------
// Pure-module tests for legalLookupV3 (query rewriter + Cohere rerank
// pipeline). All sub-systems are stubbed via dependency injection. No
// network. No env vars required beyond LEGAL_LOOKUP_V3_ENABLED for the
// flag tests.
//
// Run:
//   deno test --allow-env \
//     supabase/functions/_shared/__tests__/legal_lookup_v3_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  type EmbedQueryFn,
  type LawSearchRpcFn,
  type LawSearchRpcRow,
  legalLookupV3,
  LEGAL_LOOKUP_V3_FINAL_TOP_N,
  LEGAL_LOOKUP_V3_RETRIEVAL_BUFFER,
  mergeRpcRows,
} from "../legal_lookup.ts";
import { _resetQueryRewriterCache, type HaikuJsonCaller } from "../query_rewriter.ts";
import type { CohereCaller } from "../cohere_rerank.ts";

// ─── Fixtures ───────────────────────────────────────────────────────────────

const FROZEN_NOW = new Date("2026-05-15T12:00:00Z");

function dummyEmbedding(): number[] {
  return Array(1536).fill(0);
}

const okEmbed: EmbedQueryFn = async (q) => ({
  embedding: dummyEmbedding(),
  tokens: q.length,
});

function makeRow(
  id: string,
  actSlug: string,
  paragraph: string,
  similarity: number,
  body: string = `Body of ${actSlug} §${paragraph}.`,
): LawSearchRpcRow {
  return {
    id,
    act_slug: actSlug,
    act_name: actSlug.toUpperCase(),
    paragraph,
    title: `Section ${paragraph}`,
    body,
    source_url: `https://example.org/${actSlug}/${paragraph}`,
    jurisdiction: "FI",
    similarity,
  };
}

function rpcReturning(rows: LawSearchRpcRow[]): LawSearchRpcFn {
  return async () => rows;
}

function rpcByQuery(
  byEmbed: (params: { match_count: number }) => LawSearchRpcRow[],
): LawSearchRpcFn {
  return async (params) => byEmbed(params);
}

function haikuStub(json: unknown): HaikuJsonCaller {
  return async () => JSON.stringify(json);
}

function cohereStub(indices: number[]): CohereCaller {
  return async () => ({
    results: indices.map((idx, i) => ({
      index: idx,
      relevance_score: 1 - i * 0.1,
    })),
  });
}

// ─── V3-T01 — feature flag off bypasses the whole pipeline ──────────────────

Deno.test("V3-T01 — v3Enabled=false delegates to legalLookup v2", async () => {
  _resetQueryRewriterCache();
  let rewriteCalled = false;
  const haiku: HaikuJsonCaller = async () => {
    rewriteCalled = true;
    return JSON.stringify({ rewritten: "x", originalLang: "ru", augmented: [] });
  };

  const rows = [makeRow("a", "hol", "114", 0.9)];
  const result = await legalLookupV3(
    "что делать если меня депортируют",
    "fi",
    { embed: okEmbed, lawSearch: rpcReturning(rows) },
    {
      v3Enabled: false,
      callHaiku: haiku,
      now: () => FROZEN_NOW,
    },
  );

  assertEquals(result.chunks.length, 1);
  assertEquals(rewriteCalled, false, "rewriter not called when flag is off");
  // v3_trace absent when bypassed.
  assertEquals((result as any).v3_trace, undefined);
});

// ─── V3-T02 — happy path: rewrite + rerank both fire ────────────────────────

Deno.test("V3-T02 — rewrite + rerank pipeline produces top-N reranked chunks", async () => {
  _resetQueryRewriterCache();

  // Original query returns rows a, b. Rewritten query returns rows c, d.
  const rowsByEmbed = new Map<string, LawSearchRpcRow[]>();
  let callIdx = 0;
  const embedSpy: EmbedQueryFn = async (q) => {
    callIdx += 1;
    // Mark which "embed call" this is by encoding into tokens
    return { embedding: dummyEmbedding(), tokens: q.length };
  };

  // The retrieval RPC is called twice — once per embed call. We can't
  // distinguish them at the RPC level, but we CAN return a different set
  // on each call by stateful counter. We need pool size > FINAL_TOP_N (=5)
  // for the rerank step to actually fire.
  let rpcCallCount = 0;
  const rpc: LawSearchRpcFn = async () => {
    rpcCallCount += 1;
    if (rpcCallCount === 1) {
      return [
        makeRow("a", "ukl", "5", 0.55),
        makeRow("b", "ukl", "7", 0.50),
        makeRow("e", "ukl", "10", 0.48),
      ];
    }
    return [
      makeRow("c", "ukl", "149", 0.85),
      makeRow("d", "ukl", "150", 0.80),
      makeRow("f", "ukl", "151", 0.78),
      makeRow("g", "ukl", "152", 0.76),
    ];
  };

  const haiku = haikuStub({
    rewritten: "karkottaminen Ulkomaalaislaki §149",
    originalLang: "ru",
    augmented: ["original", "karkottaminen UKL §149"],
  });

  // Pool after merge: 7 rows sorted desc — [c(0.85), d(0.80), f(0.78), g(0.76), a(0.55), b(0.50), e(0.48)].
  // Cohere picks index 0 then 4 → [c (paragraph 149), a (paragraph 5)].
  const cohere = cohereStub([0, 4]);

  const result = await legalLookupV3(
    "что делать если меня депортируют",
    "fi",
    { embed: embedSpy, lawSearch: rpc },
    {
      callHaiku: haiku,
      callCohere: cohere,
      v3Enabled: true,
      now: () => FROZEN_NOW,
    },
  );

  assertEquals(rpcCallCount, 2, "two RPC calls — original + rewritten");
  assert(result.v3_trace);
  assertEquals(result.v3_trace!.rewrite_used, true);
  assertEquals(result.v3_trace!.rewritten_query, "karkottaminen Ulkomaalaislaki §149");
  assertEquals(result.v3_trace!.rerank_used, true);
  assertEquals(result.chunks.length, 2);
  assertEquals(result.chunks[0].paragraph, "149");
  assertEquals(result.chunks[1].paragraph, "5");
});

// ─── V3-T03 — rewriter degraded → only one retrieval, no rerank trace ──────

Deno.test("V3-T03 — failing rewriter falls back to single retrieval", async () => {
  _resetQueryRewriterCache();
  const failingHaiku: HaikuJsonCaller = async () => {
    throw new Error("anthropic 429");
  };

  let rpcCalls = 0;
  const rpc: LawSearchRpcFn = async () => {
    rpcCalls += 1;
    return [makeRow("a", "hol", "114", 0.9)];
  };

  const result = await legalLookupV3(
    "menetetyn määräajan palauttaminen",
    "fi",
    { embed: okEmbed, lawSearch: rpc },
    {
      callHaiku: failingHaiku,
      v3Enabled: true,
      now: () => FROZEN_NOW,
    },
  );

  // Only the original query was retrieved.
  assertEquals(rpcCalls, 1);
  assertEquals(result.v3_trace!.rewrite_used, false);
  // No rerank because pool size (1) ≤ topN (5).
  assertEquals(result.v3_trace!.rerank_used, false);
  assertEquals(result.chunks.length, 1);
});

// ─── V3-T04 — Cohere failure falls back to merged order ────────────────────

Deno.test("V3-T04 — Cohere failure preserves pgvector order", async () => {
  _resetQueryRewriterCache();
  // Pool with > FINAL_TOP_N rows so rerank actually fires.
  let rpcCalls = 0;
  const rpc: LawSearchRpcFn = async () => {
    rpcCalls += 1;
    if (rpcCalls === 1) {
      return [
        makeRow("a", "hol", "114", 0.95),
        makeRow("b", "hol", "115", 0.85),
        makeRow("c", "hol", "116", 0.80),
        makeRow("d", "hol", "117", 0.75),
        makeRow("e", "hol", "118", 0.70),
        makeRow("f", "hol", "119", 0.65),
      ];
    }
    return [];
  };

  const failingCohere: CohereCaller = async () => {
    throw new Error("cohere_rerank 503: upstream unavailable");
  };

  const haiku = haikuStub({
    rewritten: "alt query",
    originalLang: "ru",
    augmented: ["q"],
  });

  const result = await legalLookupV3(
    "HOL 114",
    "fi",
    { embed: okEmbed, lawSearch: rpc },
    {
      callHaiku: haiku,
      callCohere: failingCohere,
      v3Enabled: true,
      now: () => FROZEN_NOW,
    },
  );

  assertEquals(result.v3_trace!.rerank_used, false);
  assertEquals(result.v3_trace!.rerank_fallback, "http_error");
  // Order preserved by similarity desc (pgvector merge).
  assertEquals(result.chunks[0].paragraph, "114");
  assertEquals(result.chunks[1].paragraph, "115");
});

// ─── V3-T05 — empty query short-circuits ───────────────────────────────────

Deno.test("V3-T05 — empty query returns empty result", async () => {
  _resetQueryRewriterCache();
  let rpcCalls = 0;
  const result = await legalLookupV3(
    "   ",
    "fi",
    {
      embed: okEmbed,
      lawSearch: async () => {
        rpcCalls += 1;
        return [];
      },
    },
    { v3Enabled: true },
  );

  assertEquals(result.chunks.length, 0);
  assertEquals(rpcCalls, 0);
});

// ─── V3-T06 — invalid jurisdiction throws ──────────────────────────────────

Deno.test("V3-T06 — unsupported jurisdiction throws LegalLookupConfigError", async () => {
  _resetQueryRewriterCache();
  let threw = false;
  try {
    await legalLookupV3(
      "q",
      "xx",
      { embed: okEmbed, lawSearch: rpcReturning([]) },
      { v3Enabled: true },
    );
  } catch (e) {
    threw = true;
    assertEquals(
      String(e).includes("Unsupported jurisdiction"),
      true,
    );
  }
  assertEquals(threw, true);
});

// ─── V3-T07 — rewrite identical to original → single retrieval ─────────────

Deno.test("V3-T07 — when rewrite == original, skip dual retrieval", async () => {
  _resetQueryRewriterCache();
  let rpcCalls = 0;
  const rpc: LawSearchRpcFn = async () => {
    rpcCalls += 1;
    return [makeRow("a", "hol", "114", 0.9)];
  };

  const idemHaiku = haikuStub({
    rewritten: "HOL §114",
    originalLang: "fi",
    augmented: [],
  });

  await legalLookupV3(
    "HOL §114",
    "fi",
    { embed: okEmbed, lawSearch: rpc },
    {
      callHaiku: idemHaiku,
      v3Enabled: true,
      now: () => FROZEN_NOW,
    },
  );

  assertEquals(rpcCalls, 1, "identical rewrite skips second retrieval");
});

// ─── V3-T08 — mergeRpcRows: dedup + best-sim-wins ──────────────────────────

Deno.test("V3-T08 — mergeRpcRows dedupes by (act_slug, paragraph), keeps higher sim", () => {
  const a = [
    makeRow("x", "hol", "114", 0.55),
    makeRow("y", "tls", "88", 0.50),
  ];
  const b = [
    makeRow("z", "hol", "114", 0.82), // higher sim, same key as x → wins
    makeRow("w", "krms", "1", 0.45),
  ];
  const merged = mergeRpcRows(a, b);
  assertEquals(merged.length, 3);
  // Order is desc by similarity.
  assertEquals(merged[0].similarity, 0.82);
  assertEquals(merged[0].id, "z");
  assertEquals(merged[1].similarity, 0.5);
  assertEquals(merged[2].similarity, 0.45);
});

// ─── V3-T09 — mergeRpcRows handles empties ─────────────────────────────────

Deno.test("V3-T09 — mergeRpcRows with one empty array passes through", () => {
  const a = [makeRow("x", "hol", "114", 0.55)];
  assertEquals(mergeRpcRows(a, []).length, 1);
  assertEquals(mergeRpcRows([], a).length, 1);
  assertEquals(mergeRpcRows([], []).length, 0);
});

// ─── V3-T10 — pool size below FINAL_TOP_N skips Cohere ─────────────────────

Deno.test("V3-T10 — small pool skips Cohere call", async () => {
  _resetQueryRewriterCache();
  let cohereCalls = 0;
  const cohereSpy: CohereCaller = async (body) => {
    cohereCalls += 1;
    return { results: body.documents.map((_, i) => ({ index: i, relevance_score: 1 - i * 0.1 })) };
  };

  const rpc = rpcReturning([
    makeRow("a", "hol", "114", 0.9),
    makeRow("b", "hol", "115", 0.85),
  ]);

  const haiku = haikuStub({ rewritten: "alt", originalLang: "ru", augmented: ["q"] });

  const result = await legalLookupV3(
    "q",
    "fi",
    { embed: okEmbed, lawSearch: rpc },
    {
      callHaiku: haiku,
      callCohere: cohereSpy,
      v3Enabled: true,
      now: () => FROZEN_NOW,
    },
  );

  // Both queries return same 2 rows → merged is 2 rows ≤ FINAL_TOP_N=5 → no rerank.
  assertEquals(cohereCalls, 0);
  assertEquals(result.v3_trace!.rerank_used, false);
});

// ─── V3-T11 — buffer constant pinned ───────────────────────────────────────

Deno.test("V3-T11 — buffer + final-top-N constants are sane", () => {
  assertEquals(LEGAL_LOOKUP_V3_RETRIEVAL_BUFFER, 20);
  // top-N matches v2 (5) so callers don't have to know we're using v3.
  assertEquals(LEGAL_LOOKUP_V3_FINAL_TOP_N, 5);
});
