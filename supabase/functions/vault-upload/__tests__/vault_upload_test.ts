// Deno tests for vault-upload edge fn.
// -----------------------------------------------------------------------------
// Run:
//   deno test --allow-read --allow-env \
//     supabase/functions/vault-upload/__tests__/vault_upload_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertExists,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  runVaultList,
  runVaultUpload,
  type SupabaseLike,
  validateUploadRequest,
} from "../handler.ts";

// ─── Test doubles ───────────────────────────────────────────────────────────

interface RpcCall {
  fn: string;
  params: Record<string, unknown>;
}
interface InsertCall {
  table: string;
  row: Record<string, unknown>;
}

function makeFake(opts: {
  /** Map of RPC name → returned data (or "ERROR:<msg>"). */
  rpc?: Record<string, unknown>;
  /** Map of table → row returned by insert().select().single(). */
  inserts?: Record<string, Record<string, unknown>>;
  /** Rows returned by vault_search_documents RPC (for list tests). */
  searchRows?: Array<Record<string, unknown>>;
  /** If set, all RPCs / inserts will return this error. */
  forceError?: string;
}): { client: SupabaseLike; rpcCalls: RpcCall[]; insertCalls: InsertCall[] } {
  const rpcCalls: RpcCall[] = [];
  const insertCalls: InsertCall[] = [];

  const client: SupabaseLike = {
    rpc(fn, params) {
      rpcCalls.push({ fn, params });
      if (opts.forceError) {
        return Promise.resolve({ data: null, error: { message: opts.forceError } });
      }
      if (fn === "vault_search_documents") {
        return Promise.resolve({ data: opts.searchRows ?? [], error: null });
      }
      const v = opts.rpc?.[fn];
      if (v === undefined) {
        return Promise.resolve({ data: null, error: { message: `unknown rpc ${fn}` } });
      }
      if (typeof v === "string" && v.startsWith("ERROR:")) {
        return Promise.resolve({ data: null, error: { message: v.slice(6) } });
      }
      return Promise.resolve({ data: v, error: null });
    },
    from(table) {
      return {
        insert(row) {
          insertCalls.push({ table, row });
          return {
            select(_cols) {
              return {
                single: () => {
                  if (opts.forceError) {
                    return Promise.resolve({
                      data: null,
                      error: { message: opts.forceError },
                    });
                  }
                  const data = opts.inserts?.[table] ?? { id: "fake-doc-id" };
                  return Promise.resolve({ data, error: null });
                },
              };
            },
          };
        },
        select(_cols) {
          return {
            eq(_c, _v) {
              return {
                order(_c2, _o) {
                  return { limit: (_n) => Promise.resolve({ data: [], error: null }) };
                },
              };
            },
          };
        },
      };
    },
  };
  return { client, rpcCalls, insertCalls };
}

const USER_A = "11111111-1111-1111-1111-111111111111";
const USER_B = "22222222-2222-2222-2222-222222222222";
const TAG_A  = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa";

// ─── Validation ─────────────────────────────────────────────────────────────

Deno.test("validateUploadRequest rejects empty body", () => {
  const v = validateUploadRequest({});
  assert(!("ok" in v));
});

Deno.test("validateUploadRequest rejects missing file_name", () => {
  const v = validateUploadRequest({ storage_path: "x", mime_type: "y" });
  assert(!("ok" in v));
});

Deno.test("validateUploadRequest rejects non-uuid tag_id", () => {
  const v = validateUploadRequest({
    file_name: "f", storage_path: "p", mime_type: "m", tag_id: "not-uuid",
  });
  assert(!("ok" in v));
});

Deno.test("validateUploadRequest accepts well-formed body", () => {
  const v = validateUploadRequest({
    file_name: "Contract.pdf",
    storage_path: `${USER_A}/contracts/Contract.pdf`,
    mime_type: "application/pdf",
    file_size_bytes: 1234,
    tag_id: TAG_A,
  });
  assert("ok" in v && v.ok === true);
});

Deno.test("validateUploadRequest rejects oversize file_name", () => {
  const v = validateUploadRequest({
    file_name: "x".repeat(513),
    storage_path: "p",
    mime_type: "m",
  });
  assert(!("ok" in v));
});

// ─── Upload happy path ──────────────────────────────────────────────────────

Deno.test("runVaultUpload happy path encrypts + inserts + tags", async () => {
  const { client, rpcCalls, insertCalls } = makeFake({
    rpc: { vault_encrypt_text: "<ENCRYPTED-BLOB>" },
    inserts: {
      documents: { id: "doc-123" },
      vault_document_tags: { document_id: "doc-123" },
    },
  });

  const r = await runVaultUpload(
    {
      file_name: "Contract.pdf",
      storage_path: `${USER_A}/contracts/Contract.pdf`,
      mime_type: "application/pdf",
      tag_id: TAG_A,
    },
    { supabase: client, userId: USER_A },
  );

  assertEquals(r.kind, "success");
  if (r.kind !== "success") return;
  assertEquals(r.body.document_id, "doc-123");
  assertEquals(r.body.encrypted, true);

  // Two encrypts: file_name + storage_path
  const encs = rpcCalls.filter((c) => c.fn === "vault_encrypt_text");
  assertEquals(encs.length, 2);
  // Encrypts ran under the CALLER's user id (not anyone else's).
  for (const e of encs) {
    assertEquals(e.params["p_user_id"], USER_A);
  }

  // Inserted documents row references caller user_id and encrypted columns
  const docInsert = insertCalls.find((c) => c.table === "documents");
  assertExists(docInsert);
  assertEquals(docInsert!.row["user_id"], USER_A);
  assertEquals(docInsert!.row["encrypted_file_name"], "<ENCRYPTED-BLOB>");
  assertEquals(docInsert!.row["encrypted_storage_path"], "<ENCRYPTED-BLOB>");
  assertEquals(docInsert!.row["file_name"], "[encrypted]");

  // Tag join row created
  const tagInsert = insertCalls.find((c) => c.table === "vault_document_tags");
  assertExists(tagInsert);
  assertEquals(tagInsert!.row["document_id"], "doc-123");
  assertEquals(tagInsert!.row["tag_id"], TAG_A);
});

Deno.test("runVaultUpload without tag skips tag insert", async () => {
  const { client, insertCalls } = makeFake({
    rpc: { vault_encrypt_text: "<ENC>" },
    inserts: { documents: { id: "doc-456" } },
  });
  const r = await runVaultUpload(
    {
      file_name: "Receipt.jpg",
      storage_path: `${USER_A}/receipts/Receipt.jpg`,
      mime_type: "image/jpeg",
    },
    { supabase: client, userId: USER_A },
  );
  assertEquals(r.kind, "success");
  assertEquals(insertCalls.filter((c) => c.table === "vault_document_tags").length, 0);
});

// ─── Cross-user encryption guard ────────────────────────────────────────────

Deno.test("runVaultUpload never encrypts under a different user id", async () => {
  // Even if the request body claimed user_id, the handler ALWAYS uses
  // deps.userId (post-JWT). This test confirms that contract.
  const { client, rpcCalls } = makeFake({
    rpc: { vault_encrypt_text: "<ENC>" },
    inserts: { documents: { id: "doc-789" } },
  });
  await runVaultUpload(
    {
      file_name: "x.pdf",
      storage_path: "p",
      mime_type: "application/pdf",
      // Even if a malicious client tried to slip user_id through, it's
      // discarded by validateUploadRequest (not in schema).
      ...({ user_id: USER_B } as Record<string, unknown>),
    },
    { supabase: client, userId: USER_A },
  );
  const encs = rpcCalls.filter((c) => c.fn === "vault_encrypt_text");
  for (const e of encs) {
    assertEquals(e.params["p_user_id"], USER_A);
  }
});

// ─── Error propagation ─────────────────────────────────────────────────────

Deno.test("runVaultUpload 500 when encrypt RPC fails", async () => {
  const { client } = makeFake({
    rpc: { vault_encrypt_text: "ERROR:master key not set" },
  });
  const r = await runVaultUpload(
    {
      file_name: "x.pdf",
      storage_path: "p",
      mime_type: "application/pdf",
    },
    { supabase: client, userId: USER_A },
  );
  assertEquals(r.kind, "error");
  assertEquals(r.status, 500);
});

Deno.test("runVaultUpload 500 when insert fails (RLS denial simulated)", async () => {
  const { client } = makeFake({
    rpc: { vault_encrypt_text: "<ENC>" },
    forceError: undefined,  // we'll override after
  });
  // Re-wrap: forceError flips behaviour AFTER the rpc returns. Use a
  // dedicated fake for the insert-fail path.
  const failingClient: SupabaseLike = {
    rpc: client.rpc,
    from(table) {
      return {
        insert(_row) {
          return {
            select(_c) {
              return {
                single: () =>
                  Promise.resolve({
                    data: null,
                    error: { message: "new row violates row-level security policy" },
                  }),
              };
            },
          };
        },
        select(_c) {
          return {
            eq(_c2, _v) {
              return {
                order(_c3, _o) {
                  return { limit: (_n) => Promise.resolve({ data: [], error: null }) };
                },
              };
            },
          };
        },
      };
    },
  };
  const r = await runVaultUpload(
    { file_name: "x.pdf", storage_path: "p", mime_type: "application/pdf" },
    { supabase: failingClient, userId: USER_A },
  );
  assertEquals(r.kind, "error");
  assertEquals(r.status, 500);
  if (r.kind === "error") {
    assert(r.body.error.includes("documents.insert"));
  }
});

// ─── List + decrypt round-trip ──────────────────────────────────────────────

Deno.test("runVaultList passes through decrypted rows from search RPC", async () => {
  const { client, rpcCalls } = makeFake({
    searchRows: [
      {
        id: "d1",
        file_name: "Contract.pdf",  // server already decrypted
        storage_path: `${USER_A}/contracts/Contract.pdf`,
        mime_type: "application/pdf",
        file_size_bytes: 4096,
        created_at: "2026-05-27T10:00:00Z",
        case_id: null,
        tag_id: TAG_A,
        tag_slug: "contract",
        tag_label: "Contract",
        encrypted: true,
      },
    ],
  });
  const r = await runVaultList({}, { supabase: client, userId: USER_A });
  assertEquals(r.kind, "success");
  if (r.kind !== "success") return;
  assertEquals(r.body.documents.length, 1);
  assertEquals(r.body.documents[0].file_name, "Contract.pdf");
  assertEquals(r.body.documents[0].encrypted, true);
  // Called the search RPC exactly once with empty query.
  const calls = rpcCalls.filter((c) => c.fn === "vault_search_documents");
  assertEquals(calls.length, 1);
  assertEquals(calls[0].params["query"], "");
});

Deno.test("runVaultList filters by tag_id when provided", async () => {
  const TAG_OTHER = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb";
  const { client } = makeFake({
    searchRows: [
      { id: "d1", file_name: "a", storage_path: "x", mime_type: "m",
        file_size_bytes: 1, created_at: "2026-05-27T10:00:00Z",
        case_id: null, tag_id: TAG_A, tag_slug: "contract", tag_label: "C",
        encrypted: true },
      { id: "d2", file_name: "b", storage_path: "y", mime_type: "m",
        file_size_bytes: 1, created_at: "2026-05-27T10:00:00Z",
        case_id: null, tag_id: TAG_OTHER, tag_slug: "other", tag_label: "O",
        encrypted: true },
    ],
  });
  const r = await runVaultList({ tagId: TAG_A }, { supabase: client, userId: USER_A });
  assertEquals(r.kind, "success");
  if (r.kind !== "success") return;
  assertEquals(r.body.documents.length, 1);
  assertEquals(r.body.documents[0].id, "d1");
});

Deno.test("runVaultList 500 when search RPC fails", async () => {
  const { client } = makeFake({ forceError: "vault.search broke" });
  const r = await runVaultList({}, { supabase: client, userId: USER_A });
  assertEquals(r.kind, "error");
  assertEquals(r.status, 500);
});
