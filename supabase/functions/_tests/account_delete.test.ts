// Deno-runtime tests for account-delete/handler.ts
// -----------------------------------------------------------------------------
// Run:
//   deno test --allow-env --allow-read --allow-net=esm.sh,deno.land \
//     supabase/functions/_tests/account_delete.test.ts
//
// Coverage:
//   A01  USER_DATA_TABLES contains every personal-data table we sweep
//        (regression guard — adding a personal-data table without listing
//        here would violate GDPR Art. 17)
//   A02  runAccountDelete happy path → all tables wiped, storage swept,
//        auth.users deleted, ok=true, partial=undefined
//   A03  runAccountDelete tolerates 42P01 (missing table) — does NOT mark
//        the table as failed
//   A04  runAccountDelete tolerates 42703 (missing column) — does NOT mark
//        the table as failed
//   A05  runAccountDelete continues after a table error, still proceeds to
//        storage + auth, returns partial=true
//   A06  runAccountDelete returns partial when auth.users delete fails but
//        application data was wiped successfully
//   A07  runAccountDelete returns partial when storage delete fails
//   A08  sweepStorageBucket paginates correctly (>1 page of objects)
//   A09  idempotency: running twice on the same user is safe (second call
//        finds empty tables/storage and still attempts auth delete)
//   A10  GDPR Art. 17 documentation comment present in handler.ts (source
//        contract: lawyer-reviewable code-as-policy)
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

Deno.env.set("SUPABASE_URL", "https://example.supabase.co");
Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "fake-service-key");

import {
  runAccountDelete,
  STORAGE_BUCKETS,
  type SupabaseAdminLike,
  USER_DATA_TABLES,
} from "../account-delete/handler.ts";

interface FakeState {
  // table -> userId -> rowCount (so we can verify the delete actually happened)
  tables: Map<string, Map<string, number>>;
  // bucket -> userPrefix -> object names
  storage: Map<string, Map<string, string[]>>;
  // user IDs successfully deleted from auth.users
  authDeleted: Set<string>;
  // forced errors
  tableErrorFor?: { table: string; message: string; code?: string };
  storageListError?: string;
  storageRemoveError?: string;
  authDeleteError?: string;
}

function makeFakeSb(state: FakeState): SupabaseAdminLike {
  return {
    from(table: string) {
      return {
        delete() {
          return {
            eq(_col: string, val: unknown) {
              if (state.tableErrorFor && state.tableErrorFor.table === table) {
                return Promise.resolve({
                  data: null,
                  error: {
                    message: state.tableErrorFor.message,
                    code: state.tableErrorFor.code,
                  },
                });
              }
              const rows = state.tables.get(table);
              if (rows) rows.delete(String(val));
              return Promise.resolve({ data: null, error: null });
            },
          };
        },
      };
    },
    storage: {
      from(bucket: string) {
        return {
          list(prefix: string, opts?: { limit?: number; offset?: number }) {
            if (state.storageListError) {
              return Promise.resolve({
                data: null,
                error: { message: state.storageListError },
              });
            }
            const objs = state.storage.get(bucket)?.get(prefix) ?? [];
            const offset = opts?.offset ?? 0;
            const limit = opts?.limit ?? 1000;
            const page = objs.slice(offset, offset + limit)
              .map((name) => ({ name }));
            return Promise.resolve({ data: page, error: null });
          },
          remove(paths: string[]) {
            if (state.storageRemoveError) {
              return Promise.resolve({
                error: { message: state.storageRemoveError },
              });
            }
            // Mutate the underlying lists so subsequent list() returns empty.
            for (const p of paths) {
              const [prefix, ...rest] = p.split("/");
              const name = rest.join("/");
              const userBucket = state.storage.get(bucket);
              if (!userBucket) continue;
              const arr = userBucket.get(prefix);
              if (!arr) continue;
              userBucket.set(prefix, arr.filter((n) => n !== name));
            }
            return Promise.resolve({ error: null });
          },
        };
      },
    },
    auth: {
      admin: {
        deleteUser(userId: string) {
          if (state.authDeleteError) {
            return Promise.resolve({
              error: { message: state.authDeleteError },
            });
          }
          state.authDeleted.add(userId);
          return Promise.resolve({ error: null });
        },
      },
    },
  };
}

function emptyState(): FakeState {
  return {
    tables: new Map(),
    storage: new Map(),
    authDeleted: new Set(),
  };
}

const UID = "user-aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee";

// -----------------------------------------------------------------------------

Deno.test("A01 — USER_DATA_TABLES covers core personal-data surfaces", () => {
  const tables = USER_DATA_TABLES.map(([t]) => t);
  // Spot-check the load-bearing tables. If any of these gets removed by a
  // refactor, a reviewer must rewrite the test consciously.
  for (
    const required of [
      "chat_messages",
      "documents",
      "cases",
      "deadlines",
      "user_drafts",
      "email_threads",
      "user_oauth_tokens",
      "user_encryption_keys",
      "profiles",
      "dsar_requests",
      "b2b_signals",
    ]
  ) {
    assert(
      tables.includes(required),
      `USER_DATA_TABLES must list ${required} (GDPR Art. 17)`,
    );
  }
  // profiles must be last (FK parent → cascade-safe ordering).
  assertEquals(
    tables[tables.length - 1],
    "profiles",
    "profiles should be last so FK children are wiped first",
  );
});

Deno.test("A02 — happy path: tables wiped, storage swept, auth deleted", async () => {
  const state = emptyState();
  // Seed a row in every table.
  for (const [t] of USER_DATA_TABLES) {
    state.tables.set(t, new Map([[UID, 1]]));
  }
  // Seed storage with 3 objects under <UID>/.
  for (const b of STORAGE_BUCKETS) {
    state.storage.set(b, new Map([[UID, ["a.pdf", "b.pdf", "c.pdf"]]]));
  }
  const sb = makeFakeSb(state);

  const result = await runAccountDelete(sb, UID);

  assert(result.ok, "expected ok=true");
  assert(result.deleted, "expected deleted=true");
  assertEquals(result.auth_user_deleted, true);
  assertEquals(result.partial, false, "no partial when everything succeeded");
  assertEquals(result.table_results.filter((r) => !r.ok).length, 0);
  assertEquals(result.storage_results.filter((r) => r.error).length, 0);
  // Every table emptied.
  for (const [t] of USER_DATA_TABLES) {
    assert(
      !state.tables.get(t)?.has(UID),
      `row in ${t} should be deleted`,
    );
  }
  // Storage emptied.
  for (const b of STORAGE_BUCKETS) {
    assertEquals(state.storage.get(b)?.get(UID)?.length, 0);
  }
  // Auth row gone.
  assert(state.authDeleted.has(UID));
  assertStringIncludes(result.message, "Account deleted");
});

Deno.test("A03 — tolerates 42P01 missing-table without failure", async () => {
  const state = emptyState();
  // Force one of the tables to be missing.
  state.tableErrorFor = {
    table: "chat_messages",
    message: 'relation "chat_messages" does not exist',
    code: "42P01",
  };
  const sb = makeFakeSb(state);
  const result = await runAccountDelete(sb, UID);

  const chat = result.table_results.find((r) => r.table === "chat_messages");
  assert(chat, "must have chat_messages result");
  assert(chat!.ok, "missing-table is OK (skipped)");
  assert(chat!.skipped, "should be marked skipped");
  // Auth delete still proceeds.
  assert(result.auth_user_deleted);
});

Deno.test("A04 — tolerates 42703 missing-column", async () => {
  const state = emptyState();
  state.tableErrorFor = {
    table: "profiles",
    message: 'column "id" does not exist',
    code: "42703",
  };
  const sb = makeFakeSb(state);
  const result = await runAccountDelete(sb, UID);
  const profiles = result.table_results.find((r) => r.table === "profiles");
  assert(profiles!.ok);
  assert(profiles!.skipped);
});

Deno.test(
  "A05 — table error → partial=true, but flow continues to auth",
  async () => {
    const state = emptyState();
    state.tableErrorFor = {
      table: "chat_messages",
      message: "permission denied",
      code: "42501", // not a tolerated code
    };
    const sb = makeFakeSb(state);
    const result = await runAccountDelete(sb, UID);

    const chat = result.table_results.find((r) => r.table === "chat_messages");
    assert(!chat!.ok, "real error must surface");
    assert(!chat!.skipped);
    // Auth delete still ran (so the locked-out problem is avoided).
    assert(result.auth_user_deleted);
    // `ok` now means "fully clean" — a table failure makes it false so the
    // client retries; `partial` flags that auth succeeded but data lingers.
    assert(!result.ok, "ok=false when any table failed (retry semantics)");
    assertEquals(result.partial, true);
  },
);

Deno.test("A06 — auth delete fails → partial=true, app data still wiped", async () => {
  const state = emptyState();
  for (const [t] of USER_DATA_TABLES) {
    state.tables.set(t, new Map([[UID, 1]]));
  }
  state.authDeleteError = "Service unavailable";
  const sb = makeFakeSb(state);
  const result = await runAccountDelete(sb, UID);

  assert(!result.ok, "ok=false when auth row remains");
  assertEquals(result.auth_user_deleted, false);
  assertEquals(result.auth_error, "Service unavailable");
  // App data IS wiped, so client should retry safely.
  for (const [t] of USER_DATA_TABLES) {
    assert(!state.tables.get(t)?.has(UID), `${t} should still be wiped`);
  }
  assertStringIncludes(result.message, "retry");
});

Deno.test("A07 — storage remove failure surfaces as partial", async () => {
  const state = emptyState();
  for (const b of STORAGE_BUCKETS) {
    state.storage.set(b, new Map([[UID, ["x.pdf"]]]));
  }
  state.storageRemoveError = "storage offline";
  const sb = makeFakeSb(state);
  const result = await runAccountDelete(sb, UID);

  const sr = result.storage_results.find((r) => r.error);
  assert(sr, "expected at least one storage failure");
  // Auth still proceeded.
  assert(result.auth_user_deleted);
  assertEquals(result.partial, true);
});

Deno.test("A08 — storage pagination handles >1 page", async () => {
  const state = emptyState();
  // 2500 objects → forces 3 list pages (limit 1000 each).
  const many = Array.from({ length: 2500 }, (_v, i) => `f${i}.pdf`);
  state.storage.set(STORAGE_BUCKETS[0], new Map([[UID, many]]));
  const sb = makeFakeSb(state);
  const result = await runAccountDelete(sb, UID);

  const bucketResult = result.storage_results[0];
  assertEquals(bucketResult.removed, 2500, "every object should be removed");
  assertEquals(state.storage.get(STORAGE_BUCKETS[0])!.get(UID)!.length, 0);
});

Deno.test("A09 — idempotent: second call on same user is safe", async () => {
  const state = emptyState();
  for (const [t] of USER_DATA_TABLES) {
    state.tables.set(t, new Map([[UID, 1]]));
  }
  const sb = makeFakeSb(state);
  const first = await runAccountDelete(sb, UID);
  assert(first.ok);

  // Reset only the authDeleted set so we can verify the 2nd call still
  // attempts to delete auth.users (idempotency from the client's POV).
  state.authDeleted.clear();
  const second = await runAccountDelete(sb, UID);
  assert(
    state.authDeleted.has(UID),
    "second call must re-issue auth.admin.deleteUser",
  );
  assert(second.ok);
});

Deno.test("A10 — handler source documents GDPR Art. 17 + App Store 5.1.1(v)", async () => {
  const src = await Deno.readTextFile(
    new URL("../account-delete/handler.ts", import.meta.url),
  );
  assertStringIncludes(src, "Art. 17");
  assertStringIncludes(src, "5.1.1(v)");
  assertStringIncludes(
    src,
    "hard delete",
    "must NOT be a soft-delete (App Store 5.1.1(v) requires actual deletion)",
  );
});
