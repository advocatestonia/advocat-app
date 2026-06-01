// vault-rotate-master/__tests__/vault_rotate_master_test.ts
// -----------------------------------------------------------------------------
// Pure-logic + CAS-gate tests for the two-phase master-key rotation handler.
//
//   * validateInitiate / validateConfirm — input contracts (version, batch
//     caps, reason shape, UUID, 64-hex token).
//   * inAllowedWindow — Europe/Tallinn 09:00..18:00 gate (DST-correct via Intl).
//   * timingSafeStringEqual — constant-time equality, length-mismatch → false.
//   * runConfirm CAS regression — TWO concurrent /confirm calls carrying the
//     same valid token MUST NOT both execute vault_rotate_all_users. The loser
//     of vault_mark_rotation_confirmed (data === false) is refused 409 BEFORE
//     any rotation runs. This guards the double-execution hazard called out in
//     handler.ts:441-448.
//
// Run:
//   deno test --allow-net --allow-env --allow-read \
//     supabase/functions/vault-rotate-master/__tests__/vault_rotate_master_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  type Deps,
  inAllowedWindow,
  runConfirm,
  type SupabaseLike,
  timingSafeStringEqual,
  validateConfirm,
  validateInitiate,
} from "../handler.ts";

const UUID = "22222222-2222-2222-2222-222222222222";
const TOKEN = "a".repeat(64); // 64-char lowercase hex
const ADMIN = "11111111-1111-1111-1111-111111111111";

// ─── validateInitiate ──────────────────────────────────────────────────────

Deno.test("INIT-01 — minimal valid body fills defaults", () => {
  const v = validateInitiate({ new_version: 2, reason: "scheduled rotation" });
  assert("ok" in v);
  assertEquals(v.req.batch_size, 100);
  assertEquals(v.req.max_batches, 10);
  assertEquals(v.req.allow_outside_window, false);
});

Deno.test("INIT-02 — non-integer / non-positive new_version rejected", () => {
  assert("kind" in validateInitiate({ new_version: 0, reason: "abcd" }));
  assert("kind" in validateInitiate({ new_version: 1.5, reason: "abcd" }));
  assert("kind" in validateInitiate({ reason: "abcd" }));
});

Deno.test("INIT-03 — batch_size / max_batches over the hard caps rejected", () => {
  assert("kind" in validateInitiate({ new_version: 2, reason: "abcd", batch_size: 1001 }));
  assert("kind" in validateInitiate({ new_version: 2, reason: "abcd", max_batches: 101 }));
  assert("kind" in validateInitiate({ new_version: 2, reason: "abcd", batch_size: 0 }));
});

Deno.test("INIT-04 — reason shape enforced", () => {
  assert("kind" in validateInitiate({ new_version: 2, reason: "ab" })); // too short
  assert("kind" in validateInitiate({ new_version: 2, reason: "bad;rm -rf" })); // illegal chars
  assert("ok" in validateInitiate({ new_version: 2, reason: "rotate-Q2_2026 . ok" }));
});

Deno.test("INIT-05 — non-object body rejected", () => {
  assert("kind" in validateInitiate(null));
  assert("kind" in validateInitiate("nope"));
});

// ─── validateConfirm ─────────────────────────────────────────────────────────

Deno.test("CONF-01 — valid uuid + 64-hex token accepted", () => {
  const v = validateConfirm({ rotation_id: UUID, confirm_token: TOKEN });
  assert("ok" in v);
});

Deno.test("CONF-02 — bad UUID rejected", () => {
  assert("kind" in validateConfirm({ rotation_id: "not-a-uuid", confirm_token: TOKEN }));
});

Deno.test("CONF-03 — token must be 64-char lowercase hex", () => {
  assert("kind" in validateConfirm({ rotation_id: UUID, confirm_token: "AAAA" }));
  // Uppercase hex rejected (token is emitted lowercase).
  assert("kind" in validateConfirm({ rotation_id: UUID, confirm_token: "A".repeat(64) }));
});

// ─── inAllowedWindow ─────────────────────────────────────────────────────────

Deno.test("WIN-01 — midday Tallinn is inside the window", () => {
  // 2026-06-01 12:00 UTC = 15:00 Europe/Tallinn (EEST, UTC+3).
  assert(inAllowedWindow(Date.UTC(2026, 5, 1, 12, 0, 0)));
});

Deno.test("WIN-02 — 03:00 UTC (06:00 Tallinn) is outside the window", () => {
  assert(!inAllowedWindow(Date.UTC(2026, 5, 1, 3, 0, 0)));
});

Deno.test("WIN-03 — 16:00 UTC (19:00 Tallinn) is outside the window", () => {
  assert(!inAllowedWindow(Date.UTC(2026, 5, 1, 16, 0, 0)));
});

// ─── timingSafeStringEqual ───────────────────────────────────────────────────

Deno.test("TS-01 — equal strings → true", () => {
  assert(timingSafeStringEqual("abc123", "abc123"));
});

Deno.test("TS-02 — differing strings of equal length → false", () => {
  assert(!timingSafeStringEqual("abc123", "abc124"));
});

Deno.test("TS-03 — length mismatch → false (no throw)", () => {
  assert(!timingSafeStringEqual("abc", "abcd"));
});

// ─── runConfirm CAS regression ───────────────────────────────────────────────

import { assertStringIncludes } from "https://deno.land/std@0.224.0/assert/mod.ts";

const NOW = Date.UTC(2026, 5, 1, 12, 0, 0);

/** sha256 hex of the cleartext TOKEN, precomputed via the real digest. */
async function tokenHash(): Promise<string> {
  const data = new TextEncoder().encode(TOKEN);
  const digest = await crypto.subtle.digest("SHA-256", data);
  const view = new Uint8Array(digest);
  let out = "";
  for (let i = 0; i < view.length; i++) {
    const h = view[i].toString(16);
    out += h.length === 1 ? "0" + h : h;
  }
  return out;
}

/** Builds a Deps whose rpc() is scripted per fn name. `confirmResult` controls
 *  the vault_mark_rotation_confirmed CAS outcome. Records every rpc call. */
function makeDeps(opts: {
  confirmResult: boolean;
  hash: string;
}): { deps: Deps; calls: string[] } {
  const calls: string[] = [];
  const supabase: SupabaseLike = {
    rpc(fn: string, _params: Record<string, unknown>) {
      calls.push(fn);
      switch (fn) {
        case "vault_get_admin":
          return Promise.resolve({
            data: [{ user_id: ADMIN, telegram_chat_id: null, email_for_oob: "a@b.c", active: true }],
            error: null,
          });
        case "vault_get_pending_rotation":
          return Promise.resolve({
            data: [{
              id: UUID,
              initiator_user_id: ADMIN,
              confirm_token_hash: opts.hash,
              expires_at: new Date(NOW + 60_000).toISOString(),
              confirmed_at: null,
              applied_at: null,
              new_version: 2,
              batch_size: 100,
              max_batches: 1,
              allow_outside_window: false,
              reason: "test",
            }],
            error: null,
          });
        case "vault_mark_rotation_confirmed":
          return Promise.resolve({ data: opts.confirmResult, error: null });
        case "vault_rotate_all_users":
          return Promise.resolve({ data: [{ rotated: 1, skipped: 0, errors: 0 }], error: null });
        case "vault_mark_rotation_applied":
          return Promise.resolve({ data: null, error: null });
        default:
          return Promise.resolve({ data: null, error: null });
      }
    },
  };
  const deps: Deps = {
    supabase,
    userId: ADMIN,
    clock: { now: () => NOW },
    sender: { sendTelegram: () => Promise.resolve(true), sendEmail: () => Promise.resolve(true) },
    forceRotateReason: "",
    randomToken: () => Promise.resolve(TOKEN),
    sha256Hex: async (input: string) => {
      const data = new TextEncoder().encode(input);
      const digest = await crypto.subtle.digest("SHA-256", data);
      const view = new Uint8Array(digest);
      let out = "";
      for (let i = 0; i < view.length; i++) {
        const h = view[i].toString(16);
        out += h.length === 1 ? "0" + h : h;
      }
      return out;
    },
  };
  return { deps, calls };
}

Deno.test("CAS-01 — winner (confirmed=true) executes rotation and succeeds", async () => {
  const hash = await tokenHash();
  const { deps, calls } = makeDeps({ confirmResult: true, hash });
  const r = await runConfirm({ rotation_id: UUID, confirm_token: TOKEN }, deps);
  assertEquals(r.kind, "success");
  assert(calls.includes("vault_rotate_all_users"), "winner must run the rotation");
});

Deno.test("CAS-02 — loser (confirmed=false) is refused 409 and NEVER rotates", async () => {
  const hash = await tokenHash();
  const { deps, calls } = makeDeps({ confirmResult: false, hash });
  const r = await runConfirm({ rotation_id: UUID, confirm_token: TOKEN }, deps);
  assertEquals(r.kind, "error");
  if (r.kind === "error") {
    assertEquals(r.status, 409);
    assertStringIncludes(r.body.error, "already confirmed");
  }
  // The critical assertion: the CAS loser must short-circuit BEFORE any
  // master-key rotation runs. Double-execution against the control plane is
  // the hazard handler.ts:441-448 guards.
  assert(!calls.includes("vault_rotate_all_users"), "CAS loser must NOT rotate");
});

Deno.test("CAS-03 — wrong token → 401 before any CAS or rotation", async () => {
  const { deps, calls } = makeDeps({ confirmResult: true, hash: "f".repeat(64) });
  const r = await runConfirm({ rotation_id: UUID, confirm_token: TOKEN }, deps);
  assertEquals(r.kind, "error");
  if (r.kind === "error") assertEquals(r.status, 401);
  assert(!calls.includes("vault_mark_rotation_confirmed"), "bad token must not reach CAS");
  assert(!calls.includes("vault_rotate_all_users"));
});
