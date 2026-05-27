// Deno-runtime tests for vault-rotate-master/handler.ts
// -----------------------------------------------------------------------------
// Run:
//   deno test --allow-env --allow-read --allow-net=esm.sh,deno.land \
//     supabase/functions/_tests/vault_rotation_test.ts
//
// Coverage:
//   V01  validateRotateRequest rejects missing / non-numeric new_version
//   V02  validateRotateRequest rejects out-of-range batch_size + max_batches
//   V03  validateRotateRequest fills defaults (batch_size=100, max_batches=10)
//   V04  parseAdminIds robust to whitespace, empty entries, mixed case
//   V05  isAdmin: empty allowlist denies all
//   V06  isAdmin: matches case-insensitively
//   V07  runRotateMaster happy path: one batch → rotated counts surfaced
//   V08  runRotateMaster loops up to max_batches when each batch saturates
//   V09  runRotateMaster short-circuits when a batch returns < batch_size touches (done=true)
//   V10  runRotateMaster surfaces RPC errors as 500
//   V11  runRotateMaster idempotent: empty batch (0 rows) → done=true, counts=0
//   V12  Triggered-by user_id is forwarded into each RPC call (audit attribution)
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertFalse,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  isAdmin,
  parseAdminIds,
  runRotateMaster,
  type SupabaseLike,
  validateRotateRequest,
} from "../vault-rotate-master/handler.ts";

// ─── V01 ───────────────────────────────────────────────────────────────────
Deno.test("V01 — validateRotateRequest rejects missing/non-int new_version", () => {
  const cases: unknown[] = [
    null,
    {},
    { new_version: "2" },
    { new_version: 0 },
    { new_version: -1 },
    { new_version: 2.5 },
  ];
  for (const body of cases) {
    const r = validateRotateRequest(body);
    assertEquals("ok" in r, false, `should reject ${JSON.stringify(body)}`);
    if (!("ok" in r)) {
      assertEquals(r.status, 400);
    }
  }
});

// ─── V02 ───────────────────────────────────────────────────────────────────
Deno.test("V02 — validateRotateRequest rejects out-of-range batch_size / max_batches", () => {
  let r = validateRotateRequest({ new_version: 2, batch_size: 0 });
  assertEquals("ok" in r, false);
  r = validateRotateRequest({ new_version: 2, batch_size: 9999 });
  assertEquals("ok" in r, false);
  r = validateRotateRequest({ new_version: 2, max_batches: 0 });
  assertEquals("ok" in r, false);
  r = validateRotateRequest({ new_version: 2, max_batches: 999 });
  assertEquals("ok" in r, false);
});

// ─── V03 ───────────────────────────────────────────────────────────────────
Deno.test("V03 — validateRotateRequest applies defaults", () => {
  const r = validateRotateRequest({ new_version: 2 });
  assert("ok" in r);
  if ("ok" in r) {
    assertEquals(r.req.new_version, 2);
    assertEquals(r.req.batch_size, 100);
    assertEquals(r.req.max_batches, 10);
  }
});

// ─── V04 ───────────────────────────────────────────────────────────────────
Deno.test("V04 — parseAdminIds handles whitespace + case + empty entries", () => {
  const out = parseAdminIds(" A1B2 , , C3D4,e5f6 ");
  assertEquals(out.size, 3);
  assert(out.has("a1b2"));
  assert(out.has("c3d4"));
  assert(out.has("e5f6"));

  assertEquals(parseAdminIds("").size, 0);
  assertEquals(parseAdminIds(undefined).size, 0);
  assertEquals(parseAdminIds(null).size, 0);
});

// ─── V05 ───────────────────────────────────────────────────────────────────
Deno.test("V05 — isAdmin denies when allowlist empty", () => {
  assertFalse(isAdmin("any-uuid", new Set()));
  assertFalse(isAdmin("", new Set()));
});

// ─── V06 ───────────────────────────────────────────────────────────────────
Deno.test("V06 — isAdmin matches case-insensitively", () => {
  const allow = parseAdminIds("AAA-BBB-CCC");
  assert(isAdmin("aaa-bbb-ccc", allow));
  assert(isAdmin("AAA-BBB-CCC", allow));
  assert(isAdmin("Aaa-Bbb-Ccc", allow));
  assertFalse(isAdmin("other-user", allow));
});

// Helpers for the handler tests ───────────────────────────────────────────
interface MockBatch {
  rotated: number;
  skipped: number;
  errors: number;
}

function mockSb(
  batches: MockBatch[],
  opts: { error?: string; captureParams?: Array<Record<string, unknown>> } = {},
): SupabaseLike {
  let i = 0;
  return {
    rpc(_fn: string, params: Record<string, unknown>) {
      if (opts.captureParams) opts.captureParams.push({ ...params });
      if (opts.error) {
        return Promise.resolve({
          data: null,
          error: { message: opts.error },
        });
      }
      const batch = batches[i++] ?? { rotated: 0, skipped: 0, errors: 0 };
      return Promise.resolve({ data: [batch], error: null });
    },
  };
}

// ─── V07 ───────────────────────────────────────────────────────────────────
Deno.test("V07 — runRotateMaster happy path surfaces counts", async () => {
  const sb = mockSb([{ rotated: 50, skipped: 5, errors: 0 }]);
  const r = await runRotateMaster(
    { new_version: 2, batch_size: 100, max_batches: 10 },
    { supabase: sb, userId: "admin-1" },
  );
  assertEquals(r.kind, "success");
  if (r.kind === "success") {
    assertEquals(r.body.version_targeted, 2);
    assertEquals(r.body.rotated, 50);
    assertEquals(r.body.skipped, 5);
    assertEquals(r.body.errors, 0);
    assertEquals(r.body.batches_run, 1);
    assert(r.body.done, "should be done — batch < batch_size");
  }
});

// ─── V08 ───────────────────────────────────────────────────────────────────
Deno.test("V08 — runRotateMaster loops until max_batches when each batch saturates", async () => {
  // Each batch returns exactly batch_size touches → never short-circuits.
  const sb = mockSb([
    { rotated: 100, skipped: 0, errors: 0 },
    { rotated: 100, skipped: 0, errors: 0 },
    { rotated: 100, skipped: 0, errors: 0 },
  ]);
  const r = await runRotateMaster(
    { new_version: 2, batch_size: 100, max_batches: 3 },
    { supabase: sb, userId: "admin-1" },
  );
  assertEquals(r.kind, "success");
  if (r.kind === "success") {
    assertEquals(r.body.batches_run, 3);
    assertEquals(r.body.rotated, 300);
    assertFalse(r.body.done, "ran out of batches, not done");
  }
});

// ─── V09 ───────────────────────────────────────────────────────────────────
Deno.test("V09 — runRotateMaster short-circuits when batch < batch_size", async () => {
  const sb = mockSb([
    { rotated: 100, skipped: 0, errors: 0 }, // full
    { rotated: 100, skipped: 0, errors: 0 }, // full
    { rotated: 17, skipped: 3, errors: 0 },  // partial → stop
  ]);
  const r = await runRotateMaster(
    { new_version: 2, batch_size: 100, max_batches: 10 },
    { supabase: sb, userId: "admin-1" },
  );
  assertEquals(r.kind, "success");
  if (r.kind === "success") {
    assertEquals(r.body.batches_run, 3);
    assertEquals(r.body.rotated, 217);
    assertEquals(r.body.skipped, 3);
    assert(r.body.done);
  }
});

// ─── V10 ───────────────────────────────────────────────────────────────────
Deno.test("V10 — runRotateMaster surfaces RPC errors", async () => {
  const sb = mockSb([], { error: "permission denied" });
  const r = await runRotateMaster(
    { new_version: 2, batch_size: 100, max_batches: 10 },
    { supabase: sb, userId: "admin-1" },
  );
  assertEquals(r.kind, "error");
  if (r.kind === "error") {
    assertEquals(r.status, 500);
    assertStringIncludes(r.body.error, "permission denied");
  }
});

// ─── V11 ───────────────────────────────────────────────────────────────────
Deno.test("V11 — idempotent: empty batch → done=true with zero counts", async () => {
  // Mock returns a batch with all zeroes (nothing left to rotate).
  const sb = mockSb([{ rotated: 0, skipped: 0, errors: 0 }]);
  const r = await runRotateMaster(
    { new_version: 2, batch_size: 100, max_batches: 10 },
    { supabase: sb, userId: "admin-1" },
  );
  assertEquals(r.kind, "success");
  if (r.kind === "success") {
    assertEquals(r.body.rotated, 0);
    assertEquals(r.body.skipped, 0);
    assertEquals(r.body.errors, 0);
    assertEquals(r.body.batches_run, 1);
    assert(r.body.done);
  }
});

// ─── V12 ───────────────────────────────────────────────────────────────────
Deno.test("V12 — admin userId forwarded as p_triggered_by for audit", async () => {
  const captured: Array<Record<string, unknown>> = [];
  const sb = mockSb([{ rotated: 5, skipped: 0, errors: 0 }], {
    captureParams: captured,
  });
  await runRotateMaster(
    { new_version: 7, batch_size: 100, max_batches: 10 },
    { supabase: sb, userId: "the-admin-uuid" },
  );
  assertEquals(captured.length, 1);
  assertEquals(captured[0].p_new_master_version, 7);
  assertEquals(captured[0].p_batch_size, 100);
  assertEquals(captured[0].p_triggered_by, "the-admin-uuid");
});
