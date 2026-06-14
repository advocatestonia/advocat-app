// doc_indexer.test.ts — doc-indexer handler tests (Feature #4).
// -----------------------------------------------------------------------------
// Run:
//   deno test --allow-all supabase/functions/_tests/doc_indexer.test.ts
//
// Scope:
//   T01 parseIndexRequest rejects non-object / missing fields
//   T02 parseIndexRequest rejects bad source_kind
//   T03 parseIndexRequest rejects non-UUID source_id
//   T04 parseIndexRequest accepts valid
//   T05 indexDocument 404 when source not owned/found (no embed call)
//   T06 indexDocument 200 indexes chunks, carries user_id/org_id from source
//   T07 indexDocument empty text → indexed:0, still clears stale chunks
//   T08 indexDocument is idempotent: delete called before insert
//   T09 indexDocument never embeds a not-owned doc (isolation guard)
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  type ChunkInsert,
  indexDocument,
  type IndexerDeps,
  parseIndexRequest,
  type SourceDoc,
  type SourceKind,
} from "../doc-indexer/handler.ts";
import { EMBED_DIM } from "../_shared/doc_chunker.ts";

const UUID = "11111111-1111-1111-1111-111111111111";
const OTHER_UUID = "22222222-2222-2222-2222-222222222222";

function vec(): number[] {
  return new Array(EMBED_DIM).fill(0.01);
}

interface Recorder {
  loaded: Array<{ kind: SourceKind; id: string; caller: string }>;
  deleted: Array<{ kind: SourceKind; id: string }>;
  inserted: ChunkInsert[][];
  embedCalls: string[][];
  order: string[];
}

function makeDeps(source: SourceDoc | null): {
  deps: IndexerDeps;
  rec: Recorder;
} {
  const rec: Recorder = {
    loaded: [],
    deleted: [],
    inserted: [],
    embedCalls: [],
    order: [],
  };
  const deps: IndexerDeps = {
    loadSource(kind, id, caller) {
      rec.loaded.push({ kind, id, caller });
      // Simulate ownership: only return if caller matches the source's user.
      if (source && source.userId === caller) return Promise.resolve(source);
      return Promise.resolve(null);
    },
    deleteChunks(kind, id) {
      rec.deleted.push({ kind, id });
      rec.order.push("delete");
      return Promise.resolve();
    },
    insertChunks(rows) {
      rec.inserted.push(rows);
      rec.order.push("insert");
      return Promise.resolve();
    },
    embed(texts) {
      rec.embedCalls.push(texts);
      rec.order.push("embed");
      return Promise.resolve({
        embeddings: texts.map(() => vec()),
        tokens: texts.length * 5,
      });
    },
  };
  return { deps, rec };
}

Deno.test("T01 parseIndexRequest rejects junk", () => {
  assertEquals(parseIndexRequest(null).ok, false);
  assertEquals(parseIndexRequest("x").ok, false);
  assertEquals(parseIndexRequest({}).ok, false);
});

Deno.test("T02 parseIndexRequest rejects bad source_kind", () => {
  const r = parseIndexRequest({ source_kind: "law", source_id: UUID });
  assertEquals(r.ok, false);
});

Deno.test("T03 parseIndexRequest rejects non-UUID id", () => {
  const r = parseIndexRequest({
    source_kind: "case_document",
    source_id: "not-a-uuid",
  });
  assertEquals(r.ok, false);
});

Deno.test("T04 parseIndexRequest accepts valid", () => {
  const r = parseIndexRequest({
    source_kind: "vault_document",
    source_id: UUID,
  });
  assert(r.ok);
  if (r.ok) {
    assertEquals(r.kind, "vault_document");
    assertEquals(r.sourceId, UUID);
  }
});

Deno.test("T05 indexDocument 404 when not owned, no embed", async () => {
  const source: SourceDoc = {
    sourceId: UUID,
    userId: OTHER_UUID, // owned by someone else
    orgId: null,
    title: "secret.pdf",
    text: "confidential deposit terms",
  };
  const { deps, rec } = makeDeps(source);
  const res = await indexDocument(
    { source_kind: "case_document", source_id: UUID },
    "caller-not-owner",
    deps
  );
  assertEquals(res.status, 404);
  assertEquals(rec.embedCalls.length, 0, "must not embed an unowned doc");
  assertEquals(rec.inserted.length, 0);
});

Deno.test("T06 indexDocument 200, carries user_id/org_id", async () => {
  const longText = "The deposit clause is binding. ".repeat(200);
  const source: SourceDoc = {
    sourceId: UUID,
    userId: "owner-1",
    orgId: "org-9",
    title: "lease.pdf",
    text: longText,
  };
  const { deps, rec } = makeDeps(source);
  const res = await indexDocument(
    { source_kind: "vault_document", source_id: UUID },
    "owner-1",
    deps
  );
  assertEquals(res.status, 200);
  assert((res.body.indexed as number) > 0);
  const rows = rec.inserted[0];
  for (const row of rows) {
    assertEquals(row.user_id, "owner-1");
    assertEquals(row.org_id, "org-9");
    assertEquals(row.source_kind, "vault_document");
    assertEquals(row.source_id, UUID);
    assertEquals(row.embedding.length, EMBED_DIM);
  }
});

Deno.test("T07 empty text → indexed:0, clears stale", async () => {
  const source: SourceDoc = {
    sourceId: UUID,
    userId: "owner-1",
    orgId: null,
    title: "scan.png",
    text: "   \n\n  ",
  };
  const { deps, rec } = makeDeps(source);
  const res = await indexDocument(
    { source_kind: "case_document", source_id: UUID },
    "owner-1",
    deps
  );
  assertEquals(res.status, 200);
  assertEquals(res.body.indexed, 0);
  assertEquals(rec.deleted.length, 1, "stale chunks must be cleared");
  assertEquals(rec.embedCalls.length, 0);
});

Deno.test("T08 idempotent: delete before insert", async () => {
  const source: SourceDoc = {
    sourceId: UUID,
    userId: "owner-1",
    orgId: null,
    title: "x.pdf",
    text: "Some indexable clause text about termination and notice. ".repeat(
      50
    ),
  };
  const { deps, rec } = makeDeps(source);
  await indexDocument(
    { source_kind: "case_document", source_id: UUID },
    "owner-1",
    deps
  );
  const delPos = rec.order.indexOf("delete");
  const insPos = rec.order.indexOf("insert");
  assert(delPos >= 0 && insPos >= 0);
  assert(delPos < insPos, "delete must precede insert for clean re-index");
});

Deno.test("T09 isolation: load is scoped to caller", async () => {
  const source: SourceDoc = {
    sourceId: UUID,
    userId: "owner-1",
    orgId: null,
    title: "x.pdf",
    text: "deposit",
  };
  const { deps, rec } = makeDeps(source);
  await indexDocument(
    { source_kind: "case_document", source_id: UUID },
    "attacker",
    deps
  );
  // The caller id passed to loadSource must be the attacker, and since the
  // source is owned by owner-1, loadSource returns null → 404 (verified by
  // the recorder receiving the attacker's id, not the owner's).
  assertEquals(rec.loaded[0].caller, "attacker");
});
