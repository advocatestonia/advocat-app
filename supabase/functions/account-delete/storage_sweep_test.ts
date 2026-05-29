// account-delete/storage_sweep_test.ts
// -----------------------------------------------------------------------------
// Behavioural test for the RECURSIVE storage sweep (GDPR Art. 17).
//
// Regression guard for the bug found 2026-05-30: sweepStorageBucket used a
// flat, non-recursive `.list(userId)` + remove, which erased ONLY files
// sitting directly at `<userId>/<file>` and silently left every NESTED object
// behind. Real objects are nested:
//   case-documents:  <userId>/<caseId>/<file>
//                    <userId>/email_attachments/<rand>/<file>
//   contract-reviews:<userId>/<ts>_<file>.pdf
//
// This test drives runAccountDelete with a fake SupabaseAdminLike whose
// storage mock mimics Supabase's NON-recursive `.list(prefix)` semantics
// (folder rows have id===null; object rows have a string id) and asserts that
// every nested object is removed and NOTHING survives.
//
// Run:
//   deno test --allow-env supabase/functions/account-delete/storage_sweep_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.177.0/testing/asserts.ts";
import { runAccountDelete, type SupabaseAdminLike } from "./handler.ts";

const UID = "11111111-1111-1111-1111-111111111111";

/**
 * A tiny in-memory storage backend that reproduces Supabase Storage's
 * NON-recursive list semantics: `.list(prefix)` returns the immediate
 * children of `prefix` only. Folder children appear as rows with id=null.
 */
function makeFakeStorage(objectKeys: string[]) {
  const live = new Set(objectKeys);

  function listImmediateChildren(prefix: string) {
    const norm = prefix.endsWith("/") ? prefix : prefix + "/";
    const folders = new Set<string>();
    const files: string[] = [];
    for (const key of live) {
      if (!key.startsWith(norm)) continue;
      const rest = key.slice(norm.length);
      const slash = rest.indexOf("/");
      if (slash === -1) {
        files.push(rest); // direct object child
      } else {
        folders.add(rest.slice(0, slash)); // folder child
      }
    }
    const rows: Array<{ name: string; id: string | null }> = [];
    for (const f of folders) rows.push({ name: f, id: null });
    for (const f of files) rows.push({ name: f, id: `obj-${norm}${f}` });
    return rows;
  }

  return {
    storage: {
      from(_bucket: string) {
        return {
          list(
            prefix: string,
            opts?: { limit?: number; offset?: number },
          ) {
            const all = listImmediateChildren(prefix);
            const offset = opts?.offset ?? 0;
            const limit = opts?.limit ?? all.length;
            return Promise.resolve({
              data: all.slice(offset, offset + limit),
              error: null,
            });
          },
          remove(paths: string[]) {
            for (const p of paths) live.delete(p);
            return Promise.resolve({ error: null });
          },
        };
      },
    },
    _live: live,
  };
}

function makeFakeAdmin(objectKeys: string[]): {
  sb: SupabaseAdminLike;
  live: Set<string>;
} {
  const fakeStorage = makeFakeStorage(objectKeys);
  const sb: SupabaseAdminLike = {
    from(_table: string) {
      return {
        delete() {
          return {
            eq(_col: string, _val: unknown) {
              return Promise.resolve({ error: null, data: null });
            },
          };
        },
      };
    },
    storage: fakeStorage.storage as SupabaseAdminLike["storage"],
    auth: {
      admin: {
        deleteUser(_userId: string) {
          return Promise.resolve({ error: null });
        },
      },
    },
  };
  return { sb, live: fakeStorage._live };
}

Deno.test("storage sweep recurses into nested folders and erases everything", async () => {
  const keys = [
    // case-documents-style nesting
    `${UID}/case-aaaa/protocol.pdf`,
    `${UID}/case-aaaa/medical.pdf`,
    `${UID}/email_attachments/r1/scan.pdf`,
    `${UID}/email_attachments/r2/image.jpg`,
    // a file sitting directly under <userId>/ (the only case the old flat
    // sweep handled)
    `${UID}/avatar.png`,
    // contract-reviews-style flat-ish nesting
    `${UID}/1700000000_contract.pdf`,
  ];
  const { sb, live } = makeFakeAdmin([...keys]);

  const result = await runAccountDelete(sb, UID);

  // Every object for this user must be gone, at every nesting depth.
  const survivors = [...live].filter((k) => k.startsWith(`${UID}/`));
  assertEquals(
    survivors,
    [],
    `Art.17: nested objects survived deletion: ${survivors.join(", ")}`,
  );

  // Each configured bucket reports removals with no error.
  for (const r of result.storage_results) {
    assertEquals(r.error, undefined, `bucket ${r.bucket} errored: ${r.error}`);
  }
});

Deno.test("storage sweep does NOT touch a different user's objects", async () => {
  const OTHER = "22222222-2222-2222-2222-222222222222";
  const keys = [
    `${UID}/case-aaaa/mine.pdf`,
    `${OTHER}/case-bbbb/theirs.pdf`,
    `${OTHER}/email_attachments/x/theirs2.pdf`,
  ];
  const { sb, live } = makeFakeAdmin([...keys]);

  await runAccountDelete(sb, UID);

  assert(!live.has(`${UID}/case-aaaa/mine.pdf`), "own object must be erased");
  assert(
    live.has(`${OTHER}/case-bbbb/theirs.pdf`),
    "other user's object must NOT be touched",
  );
  assert(
    live.has(`${OTHER}/email_attachments/x/theirs2.pdf`),
    "other user's nested object must NOT be touched",
  );
});
