// Deno-runtime tests for vault-rotate-master/handler.ts
// -----------------------------------------------------------------------------
// Wave-2 W2-08 rewrite (audit INFRA-04). The previous single-call rotation
// gated on ADMIN_USER_IDS env var is gone. New flow is two-phase:
//   POST /initiate → emits OOB token, persists pending_rotations row
//   POST /confirm  → re-hashes token, executes rotation
//
// Run:
//   deno test --allow-env --allow-read --allow-net=esm.sh,deno.land \
//     supabase/functions/_tests/vault_rotation_test.ts
//
// Coverage:
//   V01  validateInitiate rejects missing / non-numeric new_version
//   V02  validateInitiate rejects out-of-range batch_size + max_batches
//   V03  validateInitiate enforces reason shape
//   V04  validateInitiate fills defaults
//   V05  validateConfirm enforces rotation_id UUID + 64-hex token shape
//   V06  inAllowedWindow: midday Tallinn = true, midnight = false
//   V07  runInitiate: 403 when admin not in app_vault.admin_users
//   V08  runInitiate: 423 outside window without override
//   V09  runInitiate: 423 outside window with override but no FORCE_ROTATE_REASON
//   V10  runInitiate: 409 when prior unconfirmed ticket exists
//   V11  runInitiate: happy path emits token via both Telegram + email,
//        does NOT leak the cleartext in the HTTP response, persists
//        SHA-256 hash to pending row
//   V12  runInitiate: 502 when both OOB channels fail
//   V13  runConfirm: 403 when confirmer not in admin_users
//   V14  runConfirm: 404 ticket not found
//   V15  runConfirm: 409 ticket already applied
//   V16  runConfirm: 410 ticket expired
//   V17  runConfirm: 401 invalid token (hash mismatch)
//   V18  runConfirm: happy path runs batches + marks confirmed/applied,
//        forwards triggered_by for audit
//   V19  timingSafeStringEqual constant-time semantics
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertFalse,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  type Deps,
  inAllowedWindow,
  runConfirm,
  runInitiate,
  type SupabaseLike,
  timingSafeStringEqual,
  validateConfirm,
  validateInitiate,
} from "../vault-rotate-master/handler.ts";

// ─── Fixtures ──────────────────────────────────────────────────────────────

const FIXED_TOKEN = "0".repeat(64);
const FIXED_TOKEN_HASH = "fixed-hash-of-token";
const ADMIN_UUID = "11111111-2222-3333-4444-555555555555";
const OTHER_UUID = "99999999-aaaa-bbbb-cccc-dddddddddddd";
const TICKET_UUID = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee";

function deps(overrides: Partial<Deps> = {}): {
  d: Deps;
  rpcCalls: Array<{ fn: string; params: Record<string, unknown> }>;
  telegramCalls: Array<{ chatId: string; message: string }>;
  emailCalls: Array<{ to: string; subject: string; body: string }>;
  rpcQueue: Array<{ data: unknown; error: { message: string; code?: string } | null }>;
} {
  const rpcCalls: Array<{ fn: string; params: Record<string, unknown> }> = [];
  const telegramCalls: Array<{ chatId: string; message: string }> = [];
  const emailCalls: Array<{ to: string; subject: string; body: string }> = [];
  const rpcQueue: Array<
    { data: unknown; error: { message: string; code?: string } | null }
  > = [];

  const supabase: SupabaseLike = {
    rpc(fn, params) {
      rpcCalls.push({ fn, params });
      const next = rpcQueue.shift();
      if (!next) return Promise.resolve({ data: null, error: null });
      return Promise.resolve(next);
    },
  };

  const d: Deps = {
    supabase,
    userId: ADMIN_UUID,
    clock: { now: () => 1_700_000_000_000 }, // Mon 2023-11-14 ~22:13 UTC — overridden per-test
    sender: {
      sendTelegram(chatId, message) {
        telegramCalls.push({ chatId, message });
        return Promise.resolve(true);
      },
      sendEmail(to, subject, body) {
        emailCalls.push({ to, subject, body });
        return Promise.resolve(true);
      },
    },
    forceRotateReason: "",
    randomToken: () => Promise.resolve(FIXED_TOKEN),
    sha256Hex: (input) =>
      Promise.resolve(input === FIXED_TOKEN ? FIXED_TOKEN_HASH : `hash:${input}`),
    ...overrides,
  };
  return { d, rpcCalls, telegramCalls, emailCalls, rpcQueue };
}

/**
 * Pick a UTC epoch-ms timestamp that falls inside 09:00..18:00 Europe/Tallinn.
 * Tallinn is UTC+2 (EET) or UTC+3 (EEST). Picking 12:00 UTC on 2024-06-15
 * (summer = EEST = UTC+3) → 15:00 Tallinn local. Safely inside the window.
 */
const TALLINN_MIDDAY_UTC = Date.UTC(2024, 5, 15, 12, 0, 0); // 15:00 Tallinn

/**
 * Pick a UTC epoch-ms timestamp that falls OUTSIDE 09:00..18:00 Tallinn.
 * 2024-06-15 03:00 UTC → 06:00 Tallinn local — outside window.
 */
const TALLINN_NIGHT_UTC = Date.UTC(2024, 5, 15, 3, 0, 0); // 06:00 Tallinn

// ─── V01 ───────────────────────────────────────────────────────────────────
Deno.test("V01 — validateInitiate rejects missing/non-int new_version", () => {
  const cases: unknown[] = [
    null, {},
    { new_version: "2", reason: "test reason" },
    { new_version: 0, reason: "test reason" },
    { new_version: 2.5, reason: "test reason" },
  ];
  for (const body of cases) {
    const r = validateInitiate(body);
    assertFalse("ok" in r, `should reject ${JSON.stringify(body)}`);
    if (!("ok" in r)) assertEquals(r.status, 400);
  }
});

// ─── V02 ───────────────────────────────────────────────────────────────────
Deno.test("V02 — validateInitiate rejects out-of-range batch_size/max_batches", () => {
  const cases: unknown[] = [
    { new_version: 2, reason: "valid reason", batch_size: 0 },
    { new_version: 2, reason: "valid reason", batch_size: 9999 },
    { new_version: 2, reason: "valid reason", max_batches: 0 },
    { new_version: 2, reason: "valid reason", max_batches: 999 },
  ];
  for (const body of cases) {
    const r = validateInitiate(body);
    assertFalse("ok" in r);
  }
});

// ─── V03 ───────────────────────────────────────────────────────────────────
Deno.test("V03 — validateInitiate enforces reason pattern", () => {
  // Too short
  assertFalse("ok" in validateInitiate({ new_version: 2, reason: "abc" }));
  // Disallowed character
  assertFalse(
    "ok" in validateInitiate({ new_version: 2, reason: "<script>alert(1)</script>" }),
  );
  // Valid
  assert("ok" in validateInitiate({
    new_version: 2,
    reason: "Quarterly key rotation 2026-Q3",
  }));
});

// ─── V04 ───────────────────────────────────────────────────────────────────
Deno.test("V04 — validateInitiate fills defaults", () => {
  const r = validateInitiate({ new_version: 2, reason: "Quarterly rotation" });
  assert("ok" in r);
  if ("ok" in r) {
    assertEquals(r.req.batch_size, 100);
    assertEquals(r.req.max_batches, 10);
    assertFalse(r.req.allow_outside_window);
  }
});

// ─── V05 ───────────────────────────────────────────────────────────────────
Deno.test("V05 — validateConfirm enforces rotation_id UUID + 64-hex token shape", () => {
  assertFalse("ok" in validateConfirm({}));
  assertFalse(
    "ok" in validateConfirm({ rotation_id: "not-a-uuid", confirm_token: FIXED_TOKEN }),
  );
  assertFalse(
    "ok" in validateConfirm({ rotation_id: TICKET_UUID, confirm_token: "too-short" }),
  );
  assertFalse(
    "ok" in validateConfirm({ rotation_id: TICKET_UUID, confirm_token: "G".repeat(64) }),
  );
  assert(
    "ok" in validateConfirm({ rotation_id: TICKET_UUID, confirm_token: FIXED_TOKEN }),
  );
});

// ─── V06 ───────────────────────────────────────────────────────────────────
Deno.test("V06 — inAllowedWindow: midday Tallinn true, midnight false", () => {
  assert(inAllowedWindow(TALLINN_MIDDAY_UTC));
  assertFalse(inAllowedWindow(TALLINN_NIGHT_UTC));
});

// ─── V07 ───────────────────────────────────────────────────────────────────
Deno.test("V07 — runInitiate 403 when admin row not found", async () => {
  const ctx = deps({ clock: { now: () => TALLINN_MIDDAY_UTC } });
  // vault_get_admin → empty array
  ctx.rpcQueue.push({ data: [], error: null });
  const r = await runInitiate(
    { new_version: 2, reason: "Quarterly rotation" }, ctx.d,
  );
  assertEquals(r.kind, "error");
  if (r.kind === "error") {
    assertEquals(r.status, 403);
    assertStringIncludes(r.body.error, "not an active admin");
  }
});

// ─── V08 ───────────────────────────────────────────────────────────────────
Deno.test("V08 — runInitiate 423 outside window without override", async () => {
  const ctx = deps({ clock: { now: () => TALLINN_NIGHT_UTC } });
  // vault_get_admin → admin row
  ctx.rpcQueue.push({
    data: [{ user_id: ADMIN_UUID, telegram_chat_id: "123", email_for_oob: "a@b.c", active: true }],
    error: null,
  });
  const r = await runInitiate(
    { new_version: 2, reason: "Quarterly rotation" }, ctx.d,
  );
  assertEquals(r.kind, "error");
  if (r.kind === "error") {
    assertEquals(r.status, 423);
    assertStringIncludes(r.body.error, "outside 09:00-18:00");
  }
});

// ─── V09 ───────────────────────────────────────────────────────────────────
Deno.test("V09 — runInitiate 423 outside window with override but no FORCE_ROTATE_REASON", async () => {
  const ctx = deps({
    clock: { now: () => TALLINN_NIGHT_UTC },
    forceRotateReason: "", // unset
  });
  ctx.rpcQueue.push({
    data: [{ user_id: ADMIN_UUID, telegram_chat_id: "123", email_for_oob: "a@b.c", active: true }],
    error: null,
  });
  const r = await runInitiate(
    {
      new_version: 2,
      reason: "Emergency rotation",
      allow_outside_window: true,
    },
    ctx.d,
  );
  assertEquals(r.kind, "error");
  if (r.kind === "error") {
    assertEquals(r.status, 423);
    assertStringIncludes(r.body.error, "FORCE_ROTATE_REASON");
  }
});

// ─── V10 ───────────────────────────────────────────────────────────────────
Deno.test("V10 — runInitiate 409 when unconfirmed ticket exists", async () => {
  const ctx = deps({ clock: { now: () => TALLINN_MIDDAY_UTC } });
  // vault_get_admin
  ctx.rpcQueue.push({
    data: [{ user_id: ADMIN_UUID, telegram_chat_id: "123", email_for_oob: "a@b.c", active: true }],
    error: null,
  });
  // vault_has_unconfirmed_pending → true
  ctx.rpcQueue.push({ data: true, error: null });
  const r = await runInitiate(
    { new_version: 2, reason: "Quarterly rotation" }, ctx.d,
  );
  assertEquals(r.kind, "error");
  if (r.kind === "error") {
    assertEquals(r.status, 409);
    assertStringIncludes(r.body.error, "unconfirmed rotation ticket");
  }
});

// ─── V11 ───────────────────────────────────────────────────────────────────
Deno.test("V11 — runInitiate happy path: token sent OOB, hash persisted, cleartext NOT in HTTP response", async () => {
  const ctx = deps({ clock: { now: () => TALLINN_MIDDAY_UTC } });
  // 1. vault_get_admin
  ctx.rpcQueue.push({
    data: [{ user_id: ADMIN_UUID, telegram_chat_id: "tg-555", email_for_oob: "admin@example.com", active: true }],
    error: null,
  });
  // 2. vault_has_unconfirmed_pending → false
  ctx.rpcQueue.push({ data: false, error: null });
  // 3. vault_create_pending_rotation → { id, expires_at }
  ctx.rpcQueue.push({
    data: [{ id: TICKET_UUID, expires_at: "2024-06-15T12:15:00Z" }],
    error: null,
  });
  const r = await runInitiate(
    { new_version: 2, reason: "Quarterly rotation" },
    ctx.d,
    { ip: "1.2.3.4", userAgent: "test-runner" },
  );
  assertEquals(r.kind, "success");
  if (r.kind === "success" && "oob_channel" in r.body) {
    assertEquals(r.body.rotation_id, TICKET_UUID);
    assertEquals(r.body.oob_channel, "both");
    // Cleartext token MUST NOT appear in the HTTP response body.
    const json = JSON.stringify(r.body);
    assertFalse(json.includes(FIXED_TOKEN), "token leaked into HTTP response");
  }
  // OOB channels both fired.
  assertEquals(ctx.telegramCalls.length, 1);
  assertEquals(ctx.telegramCalls[0].chatId, "tg-555");
  assertStringIncludes(ctx.telegramCalls[0].message, FIXED_TOKEN);
  assertEquals(ctx.emailCalls.length, 1);
  assertEquals(ctx.emailCalls[0].to, "admin@example.com");
  assertStringIncludes(ctx.emailCalls[0].body, FIXED_TOKEN);
  // Persisted row used SHA-256 hash, not cleartext.
  const insertCall = ctx.rpcCalls.find((c) =>
    c.fn === "vault_create_pending_rotation"
  );
  assert(insertCall);
  assertEquals(insertCall!.params.p_confirm_token_hash, FIXED_TOKEN_HASH);
  assertEquals(insertCall!.params.p_initiator_ip, "1.2.3.4");
});

// ─── V12 ───────────────────────────────────────────────────────────────────
Deno.test("V12 — runInitiate 502 when both OOB channels fail", async () => {
  const ctx = deps({
    clock: { now: () => TALLINN_MIDDAY_UTC },
    sender: {
      sendTelegram: () => Promise.resolve(false),
      sendEmail: () => Promise.resolve(false),
    },
  });
  ctx.rpcQueue.push({
    data: [{ user_id: ADMIN_UUID, telegram_chat_id: "tg-555", email_for_oob: "a@b.c", active: true }],
    error: null,
  });
  ctx.rpcQueue.push({ data: false, error: null });
  ctx.rpcQueue.push({
    data: [{ id: TICKET_UUID, expires_at: "2024-06-15T12:15:00Z" }],
    error: null,
  });
  const r = await runInitiate(
    { new_version: 2, reason: "Quarterly rotation" }, ctx.d,
  );
  assertEquals(r.kind, "error");
  if (r.kind === "error") {
    assertEquals(r.status, 502);
    assertStringIncludes(r.body.error, "could not be delivered");
  }
});

// ─── V13 ───────────────────────────────────────────────────────────────────
Deno.test("V13 — runConfirm 403 when confirmer not admin", async () => {
  const ctx = deps();
  ctx.rpcQueue.push({ data: [], error: null });
  const r = await runConfirm(
    { rotation_id: TICKET_UUID, confirm_token: FIXED_TOKEN },
    ctx.d,
  );
  assertEquals(r.kind, "error");
  if (r.kind === "error") assertEquals(r.status, 403);
});

// ─── V14 ───────────────────────────────────────────────────────────────────
Deno.test("V14 — runConfirm 404 ticket not found", async () => {
  const ctx = deps();
  ctx.rpcQueue.push({
    data: [{ user_id: ADMIN_UUID, telegram_chat_id: null, email_for_oob: "a@b.c", active: true }],
    error: null,
  });
  ctx.rpcQueue.push({ data: [], error: null });
  const r = await runConfirm(
    { rotation_id: TICKET_UUID, confirm_token: FIXED_TOKEN },
    ctx.d,
  );
  assertEquals(r.kind, "error");
  if (r.kind === "error") assertEquals(r.status, 404);
});

// ─── V15 ───────────────────────────────────────────────────────────────────
Deno.test("V15 — runConfirm 409 ticket already applied", async () => {
  const ctx = deps();
  ctx.rpcQueue.push({
    data: [{ user_id: ADMIN_UUID, telegram_chat_id: null, email_for_oob: "a@b.c", active: true }],
    error: null,
  });
  ctx.rpcQueue.push({
    data: [{
      id: TICKET_UUID, initiator_user_id: ADMIN_UUID,
      confirm_token_hash: FIXED_TOKEN_HASH,
      expires_at: new Date(ctx.d.clock.now() + 60_000).toISOString(),
      confirmed_at: new Date().toISOString(),
      applied_at: new Date().toISOString(),
      new_version: 2, batch_size: 100, max_batches: 10,
      allow_outside_window: false, reason: "Quarterly rotation",
    }],
    error: null,
  });
  const r = await runConfirm(
    { rotation_id: TICKET_UUID, confirm_token: FIXED_TOKEN },
    ctx.d,
  );
  assertEquals(r.kind, "error");
  if (r.kind === "error") assertEquals(r.status, 409);
});

// ─── V16 ───────────────────────────────────────────────────────────────────
Deno.test("V16 — runConfirm 410 ticket expired", async () => {
  const now = 1_700_000_000_000;
  const ctx = deps({ clock: { now: () => now } });
  ctx.rpcQueue.push({
    data: [{ user_id: ADMIN_UUID, telegram_chat_id: null, email_for_oob: "a@b.c", active: true }],
    error: null,
  });
  ctx.rpcQueue.push({
    data: [{
      id: TICKET_UUID, initiator_user_id: ADMIN_UUID,
      confirm_token_hash: FIXED_TOKEN_HASH,
      expires_at: new Date(now - 1000).toISOString(),
      confirmed_at: null, applied_at: null,
      new_version: 2, batch_size: 100, max_batches: 10,
      allow_outside_window: false, reason: "Quarterly rotation",
    }],
    error: null,
  });
  const r = await runConfirm(
    { rotation_id: TICKET_UUID, confirm_token: FIXED_TOKEN },
    ctx.d,
  );
  assertEquals(r.kind, "error");
  if (r.kind === "error") {
    assertEquals(r.status, 410);
    assertStringIncludes(r.body.error, "expired");
  }
});

// ─── V17 ───────────────────────────────────────────────────────────────────
Deno.test("V17 — runConfirm 401 invalid token", async () => {
  const now = 1_700_000_000_000;
  const ctx = deps({ clock: { now: () => now } });
  ctx.rpcQueue.push({
    data: [{ user_id: ADMIN_UUID, telegram_chat_id: null, email_for_oob: "a@b.c", active: true }],
    error: null,
  });
  ctx.rpcQueue.push({
    data: [{
      id: TICKET_UUID, initiator_user_id: ADMIN_UUID,
      confirm_token_hash: "different-hash",   // does not match hash of FIXED_TOKEN
      expires_at: new Date(now + 60_000).toISOString(),
      confirmed_at: null, applied_at: null,
      new_version: 2, batch_size: 100, max_batches: 10,
      allow_outside_window: false, reason: "Quarterly rotation",
    }],
    error: null,
  });
  const r = await runConfirm(
    { rotation_id: TICKET_UUID, confirm_token: FIXED_TOKEN },
    ctx.d,
  );
  assertEquals(r.kind, "error");
  if (r.kind === "error") {
    assertEquals(r.status, 401);
    assertStringIncludes(r.body.error, "invalid confirm_token");
  }
});

// ─── V18 ───────────────────────────────────────────────────────────────────
Deno.test("V18 — runConfirm happy path runs batches + forwards triggered_by", async () => {
  const now = 1_700_000_000_000;
  const ctx = deps({ clock: { now: () => now }, userId: OTHER_UUID });
  // 1. vault_get_admin (confirmer)
  ctx.rpcQueue.push({
    data: [{ user_id: OTHER_UUID, telegram_chat_id: null, email_for_oob: "b@c.d", active: true }],
    error: null,
  });
  // 2. vault_get_pending_rotation
  ctx.rpcQueue.push({
    data: [{
      id: TICKET_UUID, initiator_user_id: ADMIN_UUID,
      confirm_token_hash: FIXED_TOKEN_HASH,
      expires_at: new Date(now + 60_000).toISOString(),
      confirmed_at: null, applied_at: null,
      new_version: 7, batch_size: 100, max_batches: 2,
      allow_outside_window: false, reason: "Quarterly rotation",
    }],
    error: null,
  });
  // 3. vault_mark_rotation_confirmed
  ctx.rpcQueue.push({ data: true, error: null });
  // 4. vault_rotate_all_users → partial batch, done=true
  ctx.rpcQueue.push({
    data: [{ rotated: 17, skipped: 3, errors: 0 }],
    error: null,
  });
  // 5. vault_mark_rotation_applied
  ctx.rpcQueue.push({ data: true, error: null });

  const r = await runConfirm(
    { rotation_id: TICKET_UUID, confirm_token: FIXED_TOKEN },
    ctx.d,
  );
  assertEquals(r.kind, "success");
  if (r.kind === "success" && "batches_run" in r.body) {
    assertEquals(r.body.version_targeted, 7);
    assertEquals(r.body.rotated, 17);
    assertEquals(r.body.skipped, 3);
    assertEquals(r.body.batches_run, 1);
    assert(r.body.done);
  }
  // triggered_by forwarded to the batch RPC as the CONFIRMER's user id
  // (so the audit trail attributes per-row rotations to whoever actually
  // executed the rotation, not whoever initiated it).
  const rotateCall = ctx.rpcCalls.find((c) => c.fn === "vault_rotate_all_users");
  assert(rotateCall);
  assertEquals(rotateCall!.params.p_triggered_by, OTHER_UUID);
  assertEquals(rotateCall!.params.p_new_master_version, 7);
});

// ─── V19 ───────────────────────────────────────────────────────────────────
Deno.test("V19 — timingSafeStringEqual: equal/unequal/length mismatch", () => {
  assert(timingSafeStringEqual("abc", "abc"));
  assertFalse(timingSafeStringEqual("abc", "abd"));
  assertFalse(timingSafeStringEqual("abc", "abcd"));
  assertFalse(timingSafeStringEqual("", "x"));
  assert(timingSafeStringEqual("", ""));
});
