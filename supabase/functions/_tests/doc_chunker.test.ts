// doc_chunker.test.ts — chunking + embedding helper tests for Feature #4.
// -----------------------------------------------------------------------------
// Run:
//   deno test --allow-all supabase/functions/_tests/doc_chunker.test.ts
//
// Scope:
//   T01  empty / whitespace input            → []
//   T02  short doc (< target)                → exactly one chunk, full text
//   T03  long doc                            → multiple chunks
//   T04  no chunk exceeds MAX_CHARS
//   T05  chunks overlap (recall safety net)
//   T06  chunkIndex is dense + monotonic from 0
//   T07  a phrase split across a window edge survives in some chunk
//   T08  embedTexts: empty input            → no fetch, []
//   T09  embedTexts: happy path, ordered, 1536-dim
//   T10  embedTexts: reorders out-of-order OpenAI response
//   T11  embedTexts: rejects bad dimension
//   T12  embedTexts: surfaces OpenAI non-200
//   T13  embedCostUsd math
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertRejects,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  chunkDocument,
  EMBED_DIM,
  embedCostUsd,
  embedTexts,
  MAX_CHARS,
  TARGET_CHARS,
} from "../_shared/doc_chunker.ts";

// ── chunking ──────────────────────────────────────────────────────────────────

Deno.test("T01 empty/whitespace → []", () => {
  assertEquals(chunkDocument(""), []);
  assertEquals(chunkDocument("   \n\n  \t "), []);
  // deno-lint-ignore no-explicit-any
  assertEquals(chunkDocument(null as any), []);
});

Deno.test("T02 short doc → one chunk with full text", () => {
  const doc = "The deposit of 5000 EUR shall be returned within 30 days.";
  const chunks = chunkDocument(doc);
  assertEquals(chunks.length, 1);
  assertEquals(chunks[0].chunkIndex, 0);
  assertStringIncludes(chunks[0].text, "deposit");
  assertStringIncludes(chunks[0].text, "30 days");
});

Deno.test("T03 long doc → multiple chunks", () => {
  const para = "This is a clause about termination and notice periods. ";
  const doc = para.repeat(200); // ~11K chars
  const chunks = chunkDocument(doc);
  assert(chunks.length > 1, `expected >1 chunk, got ${chunks.length}`);
});

Deno.test("T04 no chunk exceeds MAX_CHARS", () => {
  // A single giant run-on with no boundaries forces the hard-cut path.
  const doc = "word".repeat(10_000); // 40K chars, no spaces/newlines
  const chunks = chunkDocument(doc);
  assert(chunks.length > 1);
  for (const c of chunks) {
    assert(
      c.text.length <= MAX_CHARS,
      `chunk ${c.chunkIndex} len ${c.text.length} > ${MAX_CHARS}`
    );
  }
});

Deno.test("T05 chunks overlap", () => {
  const sentences = Array.from(
    { length: 60 },
    (_v, i) => `Sentence number ${i} discusses an obligation of the parties.`
  ).join(" ");
  const chunks = chunkDocument(sentences);
  assert(chunks.length >= 2);
  // Consecutive chunks should share some text region (overlap) OR at least be
  // contiguous. Verify char ranges of chunk N+1 start before chunk N ends OR
  // immediately after — never a gap that drops content.
  for (let i = 1; i < chunks.length; i++) {
    const prev = chunks[i - 1];
    const cur = chunks[i];
    assert(
      cur.charStart <= prev.charEnd,
      `gap between chunk ${i - 1} (ends ${prev.charEnd}) and ${i} (starts ${
        cur.charStart
      })`
    );
  }
});

Deno.test("T06 chunkIndex dense + monotonic from 0", () => {
  const doc = "Some legal text. ".repeat(400);
  const chunks = chunkDocument(doc);
  for (let i = 0; i < chunks.length; i++) {
    assertEquals(chunks[i].chunkIndex, i);
  }
});

Deno.test("T07 phrase across a window edge survives somewhere", () => {
  // Build a doc where the target keyphrase sits right around the first cut.
  const filler = "x ".repeat(TARGET_CHARS); // ~2*TARGET chars of filler
  const doc = filler + "the secret termination clause is here. " + filler;
  const chunks = chunkDocument(doc);
  const found = chunks.some((c) =>
    c.text.includes("secret termination clause")
  );
  assert(found, "keyphrase lost across chunk boundary");
});

// ── embedding ─────────────────────────────────────────────────────────────────

function fakeEmbeddingResponse(
  items: Array<{ embedding: number[]; index: number }>,
  tokens = 42
): typeof fetch {
  return ((_url: string | URL | Request, _init?: RequestInit) =>
    Promise.resolve(
      new Response(
        JSON.stringify({ data: items, usage: { total_tokens: tokens } }),
        {
          status: 200,
          headers: { "Content-Type": "application/json" },
        }
      )
    )) as unknown as typeof fetch;
}

function vec(fill: number): number[] {
  return new Array(EMBED_DIM).fill(fill);
}

Deno.test("T08 embedTexts empty → no fetch, []", async () => {
  let called = false;
  const spy = (() => {
    called = true;
    return Promise.resolve(new Response("{}", { status: 200 }));
  }) as unknown as typeof fetch;
  const res = await embedTexts([], "sk-test", spy);
  assertEquals(res.embeddings.length, 0);
  assertEquals(res.tokens, 0);
  assertEquals(called, false);
});

Deno.test("T09 embedTexts happy path ordered 1536-dim", async () => {
  const fetchImpl = fakeEmbeddingResponse([
    { embedding: vec(0.1), index: 0 },
    { embedding: vec(0.2), index: 1 },
  ]);
  const res = await embedTexts(["a", "b"], "sk-test", fetchImpl);
  assertEquals(res.embeddings.length, 2);
  assertEquals(res.embeddings[0].length, EMBED_DIM);
  assertEquals(res.embeddings[0][0], 0.1);
  assertEquals(res.embeddings[1][0], 0.2);
  assertEquals(res.tokens, 42);
});

Deno.test("T10 embedTexts reorders out-of-order response", async () => {
  const fetchImpl = fakeEmbeddingResponse([
    { embedding: vec(0.9), index: 1 },
    { embedding: vec(0.1), index: 0 },
  ]);
  const res = await embedTexts(["first", "second"], "sk-test", fetchImpl);
  assertEquals(res.embeddings[0][0], 0.1, "index 0 must map to first input");
  assertEquals(res.embeddings[1][0], 0.9);
});

Deno.test("T11 embedTexts rejects bad dimension", async () => {
  const fetchImpl = fakeEmbeddingResponse([{ embedding: [1, 2, 3], index: 0 }]);
  await assertRejects(
    () => embedTexts(["x"], "sk-test", fetchImpl),
    Error,
    "bad embedding"
  );
});

Deno.test("T12 embedTexts surfaces OpenAI non-200", async () => {
  const fetchImpl = (() =>
    Promise.resolve(
      new Response("rate limited", { status: 429 })
    )) as unknown as typeof fetch;
  await assertRejects(
    () => embedTexts(["x"], "sk-test", fetchImpl),
    Error,
    "OpenAI 429"
  );
});

Deno.test("T13 embedCostUsd math", () => {
  // 1M tokens = $0.02
  assertEquals(embedCostUsd(1_000_000), 0.02);
  assertEquals(embedCostUsd(0), 0);
  assert(embedCostUsd(30_000) < 0.001);
});
