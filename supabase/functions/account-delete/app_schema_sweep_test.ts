// account-delete/app_schema_sweep_test.ts
// -----------------------------------------------------------------------------
// Regression guard for the GDPR Art. 17 gap found 2026-05-31: the account
// deletion sweep only touched `public.*` tables, so `app.email_triage_queue`
// (user_id + thread_id + payload jsonb, NO FK cascade to auth.users) survived
// account deletion forever. The fix adds an `app`-schema sweep via
// `.schema("app")`. These tests assert:
//   1. the app-schema delete is issued against the `app` schema (not public),
//      scoped to the deleted user_id, and
//   2. the result surfaces the table under its `app.` qualified name.
//
// Run:
//   deno test --allow-env supabase/functions/account-delete/app_schema_sweep_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.177.0/testing/asserts.ts";
import {
  APP_SCHEMA_USER_DATA_TABLES,
  runAccountDelete,
  type SupabaseAdminLike,
} from "./handler.ts";

const UID = "11111111-1111-1111-1111-111111111111";

interface DeleteRecord {
  schema: string;
  table: string;
  col: string;
  val: unknown;
}

/** A fake admin client that records every delete with the schema it targeted. */
function makeRecordingAdmin(): {
  sb: SupabaseAdminLike;
  deletes: DeleteRecord[];
} {
  const deletes: DeleteRecord[] = [];

  const makeFrom = (schema: string) => (table: string) => ({
    delete() {
      return {
        eq(col: string, val: unknown) {
          deletes.push({ schema, table, col, val });
          return Promise.resolve({ error: null, data: null });
        },
      };
    },
  });

  const sb: SupabaseAdminLike = {
    from: makeFrom("public"),
    schema(name: string) {
      return { from: makeFrom(name) };
    },
    storage: {
      from(_bucket: string) {
        return {
          list(_prefix: string, _opts?: { limit?: number; offset?: number }) {
            return Promise.resolve({ data: [], error: null });
          },
          remove(_paths: string[]) {
            return Promise.resolve({ error: null });
          },
        };
      },
    } as SupabaseAdminLike["storage"],
    auth: {
      admin: {
        deleteUser(_userId: string) {
          return Promise.resolve({ error: null });
        },
      },
    },
  };
  return { sb, deletes };
}

Deno.test("APP-17-01 — email_triage_queue is deleted on the app schema, scoped to the user", async () => {
  const { sb, deletes } = makeRecordingAdmin();

  await runAccountDelete(sb, UID);

  const appDeletes = deletes.filter((d) => d.schema === "app");
  // Every configured app-schema table must be swept against schema 'app'.
  for (const [table, col] of APP_SCHEMA_USER_DATA_TABLES) {
    const hit = appDeletes.find((d) => d.table === table);
    assert(hit, `expected an app-schema delete for ${table}`);
    assertEquals(hit!.col, col, `wrong column for ${table}`);
    assertEquals(hit!.val, UID, `delete must be scoped to the deleted user`);
  }
  // email_triage_queue specifically (the table the gap was about).
  assert(
    appDeletes.some((d) => d.table === "email_triage_queue"),
    "Art.17: app.email_triage_queue must be erased on account delete",
  );
});

Deno.test("APP-17-02 — the public sweep does NOT issue the app-table delete against public", async () => {
  const { sb, deletes } = makeRecordingAdmin();

  await runAccountDelete(sb, UID);

  // email_triage_queue must never be deleted against the public schema —
  // there is no public.email_triage_queue and a public-targeted delete would
  // 42P01 (and FAIL under DELETE_STRICT=1).
  const publicHit = deletes.find(
    (d) => d.schema === "public" && d.table === "email_triage_queue",
  );
  assertEquals(
    publicHit,
    undefined,
    "email_triage_queue must be swept on the app schema, not public",
  );
});

Deno.test("APP-17-03 — result surfaces the app-qualified table name", async () => {
  const { sb } = makeRecordingAdmin();

  const result = await runAccountDelete(sb, UID);

  const qualified = result.table_results.find(
    (r) => r.table === "app.email_triage_queue",
  );
  assert(
    qualified,
    "table_results must report the app-qualified name app.email_triage_queue",
  );
  assertEquals(qualified!.ok, true);
});
