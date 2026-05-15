// cohere_rerank_test.ts — вабанк A2 (2026-05-15)
// -----------------------------------------------------------------------------
// Pure-module tests for cohere_rerank.ts. The Cohere call is injected via the
// `callCohere` dep so every test is deterministic + offline.
//
// Run:
//   deno test --allow-env \
//     supabase/functions/_shared/__tests__/cohere_rerank_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  COHERE_RERANK_MAX_DOC_CHARS,
  COHERE_RERANK_MODEL,
  COHERE_RERANK_URL,
  type CohereCaller,
  type CohereRerankApiResponse,
  type RerankCandidate,
  rerankResults,
} from "../cohere_rerank.ts";

// ─── Fixtures ───────────────────────────────────────────────────────────────

interface LegalCandidate extends RerankCandidate {
  statute: string;
  text: string;
}

function makeCandidates(n: number): LegalCandidate[] {
  const out: LegalCandidate[] = [];
  for (let i = 0; i < n; i++) {
    out.push({
      statute: `Act-${i}`,
      text: `Body of section ${i}.`,
    });
  }
  return out;
}

function staticCaller(api: CohereRerankApiResponse): {
  caller: CohereCaller;
  calls: number;
  lastBody: Parameters<CohereCaller>[0] | null;
} {
  const spy = {
    calls: 0,
    lastBody: null as Parameters<CohereCaller>[0] | null,
    caller: (async (body) => {
      spy.calls += 1;
      spy.lastBody = body;
      return api;
    }) as CohereCaller,
  };
  return spy;
}

// ─── CR-T01 — happy path: top-3 reorder ─────────────────────────────────────

Deno.test("CR-T01 — Cohere reorders to picked indices", async () => {
  const cands = makeCandidates(5);
  const spy = staticCaller({
    results: [
      { index: 3, relevance_score: 0.95 },
      { index: 0, relevance_score: 0.71 },
      { index: 2, relevance_score: 0.55 },
    ],
  });

  const result = await rerankResults("query about §114", cands, 3, {
    callCohere: spy.caller,
  });

  assert(result.reranked);
  assertEquals(result.candidates.length, 3);
  assertEquals(result.candidates[0].statute, "Act-3");
  assertEquals(result.candidates[1].statute, "Act-0");
  assertEquals(result.candidates[2].statute, "Act-2");
  assertEquals(result.considered, 5);
});

// ─── CR-T02 — empty input ───────────────────────────────────────────────────

Deno.test("CR-T02 — empty input → empty output without calling API", async () => {
  const spy = staticCaller({ results: [] });
  const result = await rerankResults("q", [], 5, { callCohere: spy.caller });

  assertEquals(result.candidates.length, 0);
  assertEquals(result.reranked, false);
  assertEquals(result.fallback_reason, "empty_input");
  assertEquals(spy.calls, 0);
});

// ─── CR-T03 — API error → input order preserved ─────────────────────────────

Deno.test("CR-T03 — API error falls back to input order", async () => {
  const cands = makeCandidates(5);
  const failing: CohereCaller = async () => {
    throw new Error("cohere_rerank 503: temporarily unavailable");
  };

  const result = await rerankResults("q", cands, 3, { callCohere: failing });

  assertEquals(result.reranked, false);
  assertEquals(result.fallback_reason, "http_error");
  assertEquals(result.candidates.length, 3);
  assertEquals(result.candidates[0].statute, "Act-0");
  assertEquals(result.candidates[2].statute, "Act-2");
});

// ─── CR-T04 — timeout (AbortError) maps to "timeout" reason ────────────────

Deno.test("CR-T04 — abort error mapped to timeout reason", async () => {
  const cands = makeCandidates(3);
  const aborting: CohereCaller = async () => {
    throw new Error("The operation was aborted");
  };

  const result = await rerankResults("q", cands, 2, { callCohere: aborting });

  assertEquals(result.fallback_reason, "timeout");
  assertEquals(result.candidates.length, 2);
});

// ─── CR-T05 — Cohere returns no results → fallback ──────────────────────────

Deno.test("CR-T05 — empty results from Cohere → input order fallback", async () => {
  const cands = makeCandidates(4);
  const empty: CohereCaller = async () => ({ results: [] });

  const result = await rerankResults("q", cands, 3, { callCohere: empty });

  assertEquals(result.reranked, false);
  assertEquals(result.fallback_reason, "parse_error");
  assertEquals(result.candidates.length, 3);
  assertEquals(result.candidates[0].statute, "Act-0");
});

// ─── CR-T06 — long text truncated before being sent ─────────────────────────

Deno.test("CR-T06 — overlong text is truncated to MAX_DOC_CHARS", async () => {
  const longText = "x".repeat(COHERE_RERANK_MAX_DOC_CHARS + 500);
  const cands: LegalCandidate[] = [
    { statute: "A", text: longText },
    { statute: "B", text: "short" },
  ];
  const spy = staticCaller({
    results: [{ index: 1, relevance_score: 0.9 }, { index: 0, relevance_score: 0.5 }],
  });

  await rerankResults("q", cands, 2, { callCohere: spy.caller });

  assert(spy.lastBody);
  assertEquals(
    spy.lastBody!.documents[0].length,
    COHERE_RERANK_MAX_DOC_CHARS,
    "long doc clamped to char cap before transmission",
  );
  assertEquals(spy.lastBody!.documents[1], "short");
});

// ─── CR-T07 — empty text replaced with space ────────────────────────────────

Deno.test("CR-T07 — empty doc text replaced with space placeholder", async () => {
  const cands: LegalCandidate[] = [
    { statute: "Empty", text: "" },
    { statute: "Real", text: "hello" },
  ];
  const spy = staticCaller({
    results: [{ index: 1, relevance_score: 0.9 }],
  });

  await rerankResults("q", cands, 1, { callCohere: spy.caller });

  assertEquals(spy.lastBody!.documents[0], " ", "empty doc → space placeholder");
});

// ─── CR-T08 — no API key dep AND no env → fallback ──────────────────────────

Deno.test("CR-T08 — missing api key falls back gracefully", async () => {
  // Don't pass a caller; rely on env. Env var is NOT set in test mode →
  // resolveCohereApiKey returns null → fallback with no_api_key reason.
  const cands = makeCandidates(3);
  // Ensure env doesn't accidentally have a key by reading & temporarily
  // overriding. We can't unset Deno env in test reliably, but if a key is
  // present this test will silently call the network. Skip in that case.
  const hasKey = !!Deno.env.get("COHERE_API_KEY");
  if (hasKey) return;

  const result = await rerankResults("q", cands, 2);
  assertEquals(result.reranked, false);
  assertEquals(result.fallback_reason, "no_api_key");
  assertEquals(result.candidates.length, 2);
  assertEquals(result.candidates[0].statute, "Act-0");
});

// ─── CR-T09 — request body shape ────────────────────────────────────────────

Deno.test("CR-T09 — body shape matches Cohere v2 contract", async () => {
  const cands = makeCandidates(2);
  const spy = staticCaller({ results: [{ index: 0, relevance_score: 0.5 }] });

  await rerankResults("my query", cands, 1, { callCohere: spy.caller });

  assert(spy.lastBody);
  assertEquals(spy.lastBody!.model, "rerank-v3.5");
  assertEquals(spy.lastBody!.query, "my query");
  assertEquals(spy.lastBody!.documents.length, 2);
  assertEquals(spy.lastBody!.top_n, 1);
});

// ─── CR-T10 — out-of-range indices skipped, no crash ────────────────────────

Deno.test("CR-T10 — invalid Cohere indices ignored", async () => {
  const cands = makeCandidates(3);
  const evil = staticCaller({
    results: [
      { index: 99, relevance_score: 0.99 },
      { index: -1, relevance_score: 0.88 },
      { index: 1, relevance_score: 0.50 },
    ],
  });

  const result = await rerankResults("q", cands, 3, { callCohere: evil.caller });

  // Only index 1 is valid; should yield one candidate.
  assertEquals(result.candidates.length, 1);
  assertEquals(result.candidates[0].statute, "Act-1");
});

// ─── CR-T11 — duplicate indices dedupe ──────────────────────────────────────

Deno.test("CR-T11 — duplicate indices in Cohere response are deduped", async () => {
  const cands = makeCandidates(4);
  const dups = staticCaller({
    results: [
      { index: 2, relevance_score: 0.9 },
      { index: 2, relevance_score: 0.8 },
      { index: 3, relevance_score: 0.7 },
    ],
  });

  const result = await rerankResults("q", cands, 5, { callCohere: dups.caller });

  assertEquals(result.candidates.length, 2);
  assertEquals(result.candidates[0].statute, "Act-2");
  assertEquals(result.candidates[1].statute, "Act-3");
});

// ─── CR-T12 — constants pinned (drift guard) ────────────────────────────────

Deno.test("CR-T12 — Cohere URL + model constants pinned", () => {
  assertEquals(COHERE_RERANK_URL, "https://api.cohere.com/v2/rerank");
  assertEquals(COHERE_RERANK_MODEL, "rerank-v3.5");
});

// ─── CR-T13 — topN larger than pool returns whole pool ──────────────────────

Deno.test("CR-T13 — topN > pool returns up to pool size", async () => {
  const cands = makeCandidates(2);
  const spy = staticCaller({
    results: [
      { index: 1, relevance_score: 0.9 },
      { index: 0, relevance_score: 0.5 },
    ],
  });

  const result = await rerankResults("q", cands, 10, { callCohere: spy.caller });

  assertEquals(result.candidates.length, 2);
  assertEquals(result.candidates[0].statute, "Act-1");
});
