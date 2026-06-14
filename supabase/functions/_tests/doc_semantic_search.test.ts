// doc_semantic_search.test.ts — doc-semantic-search handler tests (Feature #4).
// -----------------------------------------------------------------------------
// Run:
//   deno test --allow-all supabase/functions/_tests/doc_semantic_search.test.ts
//
// Scope:
//   T01 parseSearchRequest rejects junk / too-short query
//   T02 parseSearchRequest clamps match_count + threshold
//   T03 parseSearchRequest passes through valid scope filters
//   T04 parseSearchRequest drops non-UUID org_id / source_id
//   T05 buildSnippet: short chunk returned whole, highlight on term
//   T06 buildSnippet: long chunk centred on term, ellipses, highlight in bounds
//   T07 buildSnippet: semantic-only (no lexical hit) → head, null highlight
//   T08 searchDocuments 400 on bad query (no embed/match)
//   T09 searchDocuments happy path maps rows + snippets
//   T10 searchDocuments forwards scope args to match
//   T11 searchDocuments 502 when embed fails
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  buildSnippet,
  type MatchRow,
  parseSearchRequest,
  type SearchDeps,
  searchDocuments,
} from "../doc-semantic-search/handler.ts";
import { EMBED_DIM } from "../_shared/doc_chunker.ts";

const UUID = "33333333-3333-3333-3333-333333333333";

function vec(): number[] {
  return new Array(EMBED_DIM).fill(0.02);
}

Deno.test("T01 parseSearchRequest rejects junk / short", () => {
  assertEquals(parseSearchRequest(null).ok, false);
  assertEquals(parseSearchRequest({}).ok, false);
  assertEquals(parseSearchRequest({ query: "a" }).ok, false);
  assertEquals(parseSearchRequest({ query: "  " }).ok, false);
});

Deno.test("T02 parseSearchRequest clamps count + threshold", () => {
  const r = parseSearchRequest({
    query: "deposit",
    match_count: 999,
    threshold: 5,
  });
  assert(r.ok);
  if (r.ok) {
    assertEquals(r.value.matchCount, 25);
    assertEquals(r.value.threshold, 0.99);
  }
  const r2 = parseSearchRequest({ query: "deposit", match_count: -3 });
  assert(r2.ok);
  if (r2.ok) assertEquals(r2.value.matchCount, 1);
});

Deno.test("T03 parseSearchRequest valid scope filters", () => {
  const r = parseSearchRequest({
    query: "termination clause",
    org_id: UUID,
    source_kind: "vault_document",
    source_id: UUID,
  });
  assert(r.ok);
  if (r.ok) {
    assertEquals(r.value.orgId, UUID);
    assertEquals(r.value.sourceKind, "vault_document");
    assertEquals(r.value.sourceId, UUID);
  }
});

Deno.test("T04 parseSearchRequest drops bad uuids / kind", () => {
  const r = parseSearchRequest({
    query: "deposit",
    org_id: "nope",
    source_kind: "law",
    source_id: "nope",
  });
  assert(r.ok);
  if (r.ok) {
    assertEquals(r.value.orgId, null);
    assertEquals(r.value.sourceKind, null);
    assertEquals(r.value.sourceId, null);
  }
});

Deno.test("T05 buildSnippet short chunk whole + highlight", () => {
  const { snippet, highlight } = buildSnippet(
    "The deposit shall be returned within 30 days.",
    "deposit"
  );
  assertStringIncludes(snippet, "deposit");
  assert(highlight !== null);
  if (highlight) {
    assertEquals(
      snippet.slice(highlight.start, highlight.end).toLowerCase(),
      "deposit"
    );
  }
});

Deno.test("T06 buildSnippet long chunk centred + highlight bounded", () => {
  const filler = "lorem ipsum dolor sit amet ".repeat(60);
  const chunk = filler + "THE TERMINATION CLAUSE here " + filler;
  const { snippet, highlight } = buildSnippet(chunk, "termination");
  assert(snippet.length <= 322, `snippet too long: ${snippet.length}`);
  assertStringIncludes(snippet.toLowerCase(), "termination");
  assert(highlight !== null);
  if (highlight) {
    assert(highlight.start >= 0 && highlight.end <= snippet.length);
    assertEquals(
      snippet.slice(highlight.start, highlight.end).toLowerCase(),
      "termination"
    );
  }
});

Deno.test("T07 buildSnippet semantic-only → head, null highlight", () => {
  const chunk = "x ".repeat(400); // 800 chars, no query term
  const { snippet, highlight } = buildSnippet(chunk, "deposit refund clause");
  assertEquals(highlight, null);
  assert(snippet.endsWith("…"));
});

// ── searchDocuments ────────────────────────────────────────────────────────────

function makeDeps(
  rows: MatchRow[],
  opts: { embedThrows?: boolean } = {}
): {
  deps: SearchDeps;
  matchArgs: { value: unknown };
} {
  const matchArgs = { value: null as unknown };
  const deps: SearchDeps = {
    embed(_texts) {
      if (opts.embedThrows) return Promise.reject(new Error("openai down"));
      return Promise.resolve({ embeddings: [vec()], tokens: 3 });
    },
    match(args) {
      matchArgs.value = args;
      return Promise.resolve(rows);
    },
  };
  return { deps, matchArgs };
}

Deno.test("T08 searchDocuments 400 on bad query", async () => {
  let embedCalled = false;
  const deps: SearchDeps = {
    embed() {
      embedCalled = true;
      return Promise.resolve({ embeddings: [vec()], tokens: 0 });
    },
    match() {
      return Promise.resolve([]);
    },
  };
  const res = await searchDocuments({ query: "x" }, deps);
  assertEquals(res.status, 400);
  assertEquals(embedCalled, false);
});

Deno.test("T09 searchDocuments happy path maps rows", async () => {
  const rows: MatchRow[] = [
    {
      id: "c1",
      source_kind: "case_document",
      source_id: UUID,
      doc_title: "lease.pdf",
      chunk_index: 2,
      text: "The deposit of 5000 EUR is held in escrow.",
      char_start: 100,
      char_end: 142,
      similarity: 0.8123,
    },
  ];
  const { deps } = makeDeps(rows);
  const res = await searchDocuments({ query: "deposit escrow" }, deps);
  assertEquals(res.status, 200);
  assertEquals(res.body.count, 1);
  // deno-lint-ignore no-explicit-any
  const item = (res.body.results as any[])[0];
  assertEquals(item.chunk_id, "c1");
  assertEquals(item.doc_title, "lease.pdf");
  assertEquals(item.similarity, 0.8123);
  assertStringIncludes(item.snippet, "deposit");
  assert(item.highlight !== null);
});

Deno.test("T10 searchDocuments forwards scope args to match", async () => {
  const { deps, matchArgs } = makeDeps([]);
  await searchDocuments(
    {
      query: "termination",
      org_id: UUID,
      source_kind: "vault_document",
      source_id: UUID,
      match_count: 5,
    },
    deps
  );
  // deno-lint-ignore no-explicit-any
  const a = matchArgs.value as any;
  assertEquals(a.orgId, UUID);
  assertEquals(a.sourceKind, "vault_document");
  assertEquals(a.sourceId, UUID);
  assertEquals(a.matchCount, 5);
  assertEquals(a.embedding.length, EMBED_DIM);
});

Deno.test("T11 searchDocuments 502 when embed fails", async () => {
  const { deps } = makeDeps([], { embedThrows: true });
  const res = await searchDocuments({ query: "deposit" }, deps);
  assertEquals(res.status, 502);
});
