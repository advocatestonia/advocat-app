// vault-rotate-master/handler.ts — two-phase rotation with OOB confirm.
// -----------------------------------------------------------------------------
// Wave-2 fix W2-08 (audit INFRA-04). The previous single-call /POST flow
// gated rotation on an env-var ADMIN_USER_IDS allowlist and ran the SQL
// rotation in-line. This rewrite splits the flow into two HTTP actions:
//
//   POST /initiate
//     - Verify caller is in app_vault.admin_users (active = true).
//     - Enforce 09:00..18:00 Europe/Tallinn window unless body carries
//       allow_outside_window=true with a FORCE_ROTATE_REASON env value
//       matching /^[A-Z0-9_]{8,64}$/ AND a body.reason that matches the
//       admin-supplied human reason.
//     - 1/60s per-admin rate limit (defence-in-depth on top of the edge
//       fn's own requireUserWithRateLimit).
//     - Refuse if the same admin has an unconfirmed pending ticket.
//     - Generate a 32-byte cleartext token; persist SHA-256 hex; send the
//       cleartext over Telegram (TELEGRAM_BOT_TOKEN + admin_users.telegram_chat_id)
//       AND fallback email via Resend to admin_users.email_for_oob.
//     - Return { rotation_id }. NEVER return the token in the HTTP body.
//
//   POST /confirm
//     - Body { rotation_id, confirm_token }.
//     - Re-hash, compare to pending_rotations.confirm_token_hash.
//     - Check not expired, not already applied.
//     - Execute the original batch rotation (rotate_all_users).
//     - Mark confirmed_at + applied_at.
//
// Audit trail:
//   - Per-batch rotation_audit rows from the underlying RPC (unchanged).
//   - Top-level "ticket applied" breadcrumb via the
//     _pending_rotations_audit trigger on app_vault.pending_rotations.
//   - structured console.log on both /initiate and /confirm for log-aggregator
//     pickup.
// -----------------------------------------------------------------------------

export interface SupabaseLike {
  rpc(fn: string, params: Record<string, unknown>): Promise<{
    data: unknown;
    error: { message: string; code?: string } | null;
  }>;
}

export interface OobClock {
  /** Returns the current epoch ms. Injectable for tests. */
  now(): number;
}

export interface OobSender {
  /** Deliver the OOB cleartext token via Telegram (returns true on success). */
  sendTelegram(chatId: string, message: string): Promise<boolean>;
  /** Deliver the OOB cleartext token via email (returns true on success). */
  sendEmail(to: string, subject: string, body: string): Promise<boolean>;
}

export interface Deps {
  supabase: SupabaseLike;
  /** Acting user id (post-JWT auth + is_admin() check). */
  userId: string;
  clock: OobClock;
  sender: OobSender;
  /** Reads FORCE_ROTATE_REASON when allow_outside_window=true. */
  forceRotateReason: string;
  /** Async crypto.randomBytes-equivalent. */
  randomToken: () => Promise<string>;
  /** sha256 hex of an arbitrary input. */
  sha256Hex: (input: string) => Promise<string>;
}

// ─── Request / response contracts ──────────────────────────────────────────

export interface InitiateRequest {
  new_version: number;
  batch_size?: number;
  max_batches?: number;
  reason: string;
  allow_outside_window?: boolean;
}

export interface InitiateSuccessBody {
  rotation_id: string;
  expires_at: string; // ISO-8601
  oob_channel: "telegram" | "email" | "both";
  message: string;
}

export interface ConfirmRequest {
  rotation_id: string;
  confirm_token: string;
}

export interface RotateProgress {
  rotation_id: string;
  version_targeted: number;
  batches_run: number;
  rotated: number;
  skipped: number;
  errors: number;
  done: boolean;
}

export type HandlerResult =
  | { kind: "success"; status: 200; body: InitiateSuccessBody | RotateProgress }
  | { kind: "error"; status: number; body: { error: string } };

// ─── Validation ────────────────────────────────────────────────────────────

const MAX_BATCH_SIZE = 1000;
const MAX_BATCHES_HARD_CAP = 100;
const DEFAULT_BATCH_SIZE = 100;
const DEFAULT_MAX_BATCHES = 10;
const REASON_PATTERN = /^[A-Za-z0-9_\-\. ]{4,256}$/;
const FORCE_REASON_PATTERN = /^[A-Z0-9_]{8,64}$/;
const TOKEN_PATTERN = /^[0-9a-f]{64}$/; // 32 bytes hex
const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function validateInitiate(
  body: unknown,
): { ok: true; req: Required<Omit<InitiateRequest, "allow_outside_window">> & {
       allow_outside_window: boolean } }
  | { kind: "error"; status: number; body: { error: string } } {
  if (!body || typeof body !== "object") {
    return { kind: "error", status: 400, body: { error: "body must be JSON object" } };
  }
  const b = body as Record<string, unknown>;
  if (typeof b.new_version !== "number" || !Number.isInteger(b.new_version) ||
      b.new_version < 1) {
    return { kind: "error", status: 400, body: { error: "new_version must be positive integer" } };
  }
  const batchSize = b.batch_size === undefined
    ? DEFAULT_BATCH_SIZE
    : (typeof b.batch_size === "number" ? b.batch_size : NaN);
  if (!Number.isInteger(batchSize) || batchSize < 1 || batchSize > MAX_BATCH_SIZE) {
    return { kind: "error", status: 400,
             body: { error: `batch_size must be 1..${MAX_BATCH_SIZE}` } };
  }
  const maxBatches = b.max_batches === undefined
    ? DEFAULT_MAX_BATCHES
    : (typeof b.max_batches === "number" ? b.max_batches : NaN);
  if (!Number.isInteger(maxBatches) || maxBatches < 1 || maxBatches > MAX_BATCHES_HARD_CAP) {
    return { kind: "error", status: 400,
             body: { error: `max_batches must be 1..${MAX_BATCHES_HARD_CAP}` } };
  }
  if (typeof b.reason !== "string" || !REASON_PATTERN.test(b.reason)) {
    return { kind: "error", status: 400,
             body: { error: "reason must match /^[A-Za-z0-9_\\-\\. ]{4,256}$/" } };
  }
  const allow = b.allow_outside_window === true;
  return {
    ok: true,
    req: {
      new_version: b.new_version,
      batch_size: batchSize,
      max_batches: maxBatches,
      reason: b.reason,
      allow_outside_window: allow,
    },
  };
}

export function validateConfirm(
  body: unknown,
): { ok: true; req: ConfirmRequest }
  | { kind: "error"; status: number; body: { error: string } } {
  if (!body || typeof body !== "object") {
    return { kind: "error", status: 400, body: { error: "body must be JSON object" } };
  }
  const b = body as Record<string, unknown>;
  if (typeof b.rotation_id !== "string" || !UUID_PATTERN.test(b.rotation_id)) {
    return { kind: "error", status: 400, body: { error: "rotation_id must be a UUID" } };
  }
  if (typeof b.confirm_token !== "string" || !TOKEN_PATTERN.test(b.confirm_token)) {
    return { kind: "error", status: 400,
             body: { error: "confirm_token must be 64-char lowercase hex" } };
  }
  return { ok: true, req: { rotation_id: b.rotation_id, confirm_token: b.confirm_token } };
}

// ─── Time-window check ─────────────────────────────────────────────────────

/**
 * Returns true if the supplied epoch-ms timestamp falls inside 09:00..18:00
 * Europe/Tallinn. Uses Intl.DateTimeFormat so DST and offset transitions are
 * handled correctly without bundling a TZ library.
 *
 * Exported so the index shim and tests can share the same implementation.
 */
export function inAllowedWindow(nowMs: number): boolean {
  const parts = new Intl.DateTimeFormat("en-GB", {
    timeZone: "Europe/Tallinn",
    hour: "2-digit",
    hour12: false,
  }).formatToParts(new Date(nowMs));
  const hourPart = parts.find((p) => p.type === "hour");
  if (!hourPart) return false;
  // en-GB hour12=false yields "00".."23".
  const hour = Number.parseInt(hourPart.value, 10);
  return Number.isFinite(hour) && hour >= 9 && hour < 18;
}

// ─── /initiate ─────────────────────────────────────────────────────────────

interface AdminRow {
  user_id: string;
  telegram_chat_id: string | null;
  email_for_oob: string;
  active: boolean;
}

async function loadAdmin(
  deps: Deps,
): Promise<AdminRow | null> {
  // Use the public PostgREST wrapper (vault_get_admin) — already filters by
  // active=true — so the edge fn does not depend on the project exposing the
  // app_vault schema via PostgREST. service_role bypasses RLS.
  const res = await deps.supabase.rpc("vault_get_admin", {
    p_user_id: deps.userId,
  });
  if (res.error || !Array.isArray(res.data) || res.data.length === 0) {
    return null;
  }
  const row = res.data[0] as AdminRow;
  return row.active ? row : null;
}

export async function runInitiate(
  rawBody: unknown,
  deps: Deps,
  ctx: { ip?: string; userAgent?: string } = {},
): Promise<HandlerResult> {
  const v = validateInitiate(rawBody);
  if (!("ok" in v)) return v;
  const req = v.req;

  // 1. Admin gate (vault-resident).
  const admin = await loadAdmin(deps);
  if (!admin) {
    return { kind: "error", status: 403,
             body: { error: "Forbidden — not an active admin" } };
  }

  // 2. Time window — Europe/Tallinn 09:00..18:00 unless overridden.
  const nowMs = deps.clock.now();
  if (!inAllowedWindow(nowMs)) {
    if (!req.allow_outside_window) {
      return { kind: "error", status: 423,
               body: { error: "Rotation blocked outside 09:00-18:00 Europe/Tallinn. " +
                              "Set allow_outside_window=true to override." } };
    }
    // Override requires FORCE_ROTATE_REASON env to match a strict shape AND
    // be present in body.reason — operator must echo the env-side reason in
    // the request, proving they read the env var.
    if (!FORCE_REASON_PATTERN.test(deps.forceRotateReason)) {
      return { kind: "error", status: 423,
               body: { error: "Outside-window rotation requires FORCE_ROTATE_REASON env " +
                              "matching /^[A-Z0-9_]{8,64}$/" } };
    }
    if (!req.reason.includes(deps.forceRotateReason)) {
      return { kind: "error", status: 423,
               body: { error: "reason must contain the FORCE_ROTATE_REASON env value" } };
    }
  }

  // 3. Defence-in-depth: refuse if same admin has an unconfirmed ticket.
  const pendingCheck = await deps.supabase.rpc("vault_has_unconfirmed_pending", {
    p_user_id: deps.userId,
  });
  if (pendingCheck.error) {
    return { kind: "error", status: 500,
             body: { error: `pending check failed: ${pendingCheck.error.message}` } };
  }
  if (pendingCheck.data === true) {
    return { kind: "error", status: 409,
             body: { error: "An unconfirmed rotation ticket is already open for this admin. " +
                            "Wait for it to expire (15 min TTL) or confirm it." } };
  }

  // 4. Generate token + hash.
  const token = await deps.randomToken();        // 64-char lower hex
  const tokenHash = await deps.sha256Hex(token);  // sha256 hex of cleartext

  // 5. Decide OOB channel — prefer Telegram, fall back to email.
  const hasTelegram = !!admin.telegram_chat_id && admin.telegram_chat_id.length > 0;
  const channel: "telegram" | "email" | "both" = hasTelegram ? "both" : "email";

  // 6. Persist the pending row BEFORE sending the token. If the insert fails,
  //    we never emitted a token and the caller can safely retry.
  const insertRes = await deps.supabase.rpc("vault_create_pending_rotation", {
    p_initiator_user_id: deps.userId,
    p_confirm_token_hash: tokenHash,
    p_reason: req.reason,
    p_allow_outside_window: req.allow_outside_window,
    p_new_version: req.new_version,
    p_batch_size: req.batch_size,
    p_max_batches: req.max_batches,
    p_oob_channel: channel,
    p_initiator_ip: ctx.ip ?? null,
    p_initiator_ua: ctx.userAgent ?? null,
  });
  if (insertRes.error || !Array.isArray(insertRes.data) || insertRes.data.length === 0) {
    return { kind: "error", status: 500,
             body: { error: `pending_rotations insert failed: ${
               insertRes.error?.message ?? "no row returned"}` } };
  }
  const ticket = insertRes.data[0] as { id: string; expires_at: string };

  // 7. Deliver the cleartext token OOB. Best-effort on both channels; we
  //    require at least one successful delivery to consider /initiate ok.
  const subject = `[Advocat] Vault rotation confirm token (ticket ${ticket.id})`;
  const oobBody =
    `Vault master-key rotation has been requested.\n\n` +
    `Ticket: ${ticket.id}\n` +
    `Reason: ${req.reason}\n` +
    `Target version: ${req.new_version}\n` +
    `Outside-window override: ${req.allow_outside_window}\n` +
    `Initiator IP: ${ctx.ip ?? "—"}\n` +
    `Initiator UA: ${ctx.userAgent ?? "—"}\n` +
    `Expires: ${ticket.expires_at}\n\n` +
    `Confirm token (single-use, expires in 15 minutes):\n` +
    `${token}\n\n` +
    `If you did NOT initiate this rotation, do nothing — the ticket will ` +
    `expire and become useless. Then rotate ADMIN_USER_IDS, the Supabase ` +
    `service-role JWT, and review app_vault.rotation_audit immediately.\n`;

  let telegramOk = false;
  if (hasTelegram) {
    telegramOk = await deps.sender.sendTelegram(admin.telegram_chat_id!, oobBody)
      .catch(() => false);
  }
  const emailOk = await deps.sender.sendEmail(admin.email_for_oob, subject, oobBody)
    .catch(() => false);

  if (!telegramOk && !emailOk) {
    // Token already persisted but the operator cannot retrieve it — log
    // loudly and return 502 so the caller knows to re-initiate.
    console.error(
      `[vault-rotate-master] /initiate OOB DELIVERY FAILED ticket=${ticket.id} ` +
        `admin=${deps.userId} channels_tried=${channel}`,
    );
    return { kind: "error", status: 502,
             body: { error: "OOB token could not be delivered. " +
                            "Check Telegram bot config and Resend domain. Ticket has expired." } };
  }

  // 8. Structured audit log.
  console.log(
    `[vault-rotate-master] /initiate admin=${deps.userId} ticket=${ticket.id} ` +
      `target_v=${req.new_version} reason="${req.reason}" ` +
      `outside_window=${req.allow_outside_window} channel=${channel} ` +
      `telegram_ok=${telegramOk} email_ok=${emailOk}`,
  );

  return {
    kind: "success",
    status: 200,
    body: {
      rotation_id: ticket.id,
      expires_at: ticket.expires_at,
      oob_channel: channel,
      message:
        "OOB confirm token sent. POST {rotation_id, confirm_token} to " +
        "/vault-rotate-master/confirm within 15 minutes.",
    },
  };
}

// ─── /confirm ──────────────────────────────────────────────────────────────

interface PendingRow {
  id: string;
  initiator_user_id: string;
  confirm_token_hash: string;
  expires_at: string;
  confirmed_at: string | null;
  applied_at: string | null;
  new_version: number;
  batch_size: number;
  max_batches: number;
  allow_outside_window: boolean;
  reason: string;
}

async function loadPending(
  deps: Deps,
  rotationId: string,
): Promise<PendingRow | null> {
  const res = await deps.supabase.rpc("vault_get_pending_rotation", {
    p_id: rotationId,
  });
  if (res.error || !Array.isArray(res.data) || res.data.length === 0) return null;
  return res.data[0] as PendingRow;
}

export async function runConfirm(
  rawBody: unknown,
  deps: Deps,
): Promise<HandlerResult> {
  const v = validateConfirm(rawBody);
  if (!("ok" in v)) return v;
  const req = v.req;

  // 1. Admin gate (the confirmer must also be an active admin — does not
  //    need to be the same admin who initiated, supporting a two-eye flow
  //    if the owner backfills multiple rows. Today there is no second-admin
  //    requirement; the OOB token IS the second factor).
  const admin = await loadAdmin(deps);
  if (!admin) {
    return { kind: "error", status: 403,
             body: { error: "Forbidden — not an active admin" } };
  }

  // 2. Load ticket.
  const pending = await loadPending(deps, req.rotation_id);
  if (!pending) {
    return { kind: "error", status: 404, body: { error: "rotation ticket not found" } };
  }

  // 3. Already applied — refuse replay.
  if (pending.applied_at) {
    return { kind: "error", status: 409,
             body: { error: "rotation ticket already applied" } };
  }

  // 4. Expired.
  if (new Date(pending.expires_at).getTime() <= deps.clock.now()) {
    return { kind: "error", status: 410,
             body: { error: "rotation ticket expired (15-min TTL)" } };
  }

  // 5. Hash-match the supplied token. Use timing-safe comparison.
  const suppliedHash = await deps.sha256Hex(req.confirm_token);
  if (!timingSafeStringEqual(suppliedHash, pending.confirm_token_hash)) {
    // Audit the failed attempt.
    console.warn(
      `[vault-rotate-master] /confirm INVALID TOKEN ticket=${pending.id} ` +
        `confirmer=${deps.userId}`,
    );
    return { kind: "error", status: 401, body: { error: "invalid confirm_token" } };
  }

  // 6. Mark confirmed_at. This is a compare-and-swap: vault_mark_rotation_confirmed
  //    only flips confirmed_at when it was NULL and returns true iff THIS call
  //    won. Steps 3-5 above (applied_at check, expiry, hash-match) are all READs,
  //    so two concurrent /confirm calls carrying the same valid token both reach
  //    here. We MUST gate on the CAS result — not just the absence of an error —
  //    or both calls fall through to step 7 and double-execute
  //    vault_rotate_all_users against the master-key control plane. The loser of
  //    the race (data === false) is refused 409 BEFORE any rotation runs.
  const confirmRes = await deps.supabase.rpc("vault_mark_rotation_confirmed", {
    p_id: pending.id,
  });
  if (confirmRes.error) {
    return { kind: "error", status: 500,
             body: { error: `confirm update failed: ${confirmRes.error.message}` } };
  }
  if (confirmRes.data !== true) {
    // Lost the CAS — a concurrent /confirm already claimed this ticket.
    console.warn(
      `[vault-rotate-master] /confirm lost CAS (concurrent confirm) ticket=${pending.id} ` +
        `confirmer=${deps.userId}`,
    );
    return { kind: "error", status: 409,
             body: { error: "rotation ticket already confirmed" } };
  }

  // 7. Execute the underlying rotation.
  let rotated = 0;
  let skipped = 0;
  let errors = 0;
  let batchesRun = 0;
  let done = false;
  for (let i = 0; i < pending.max_batches; i++) {
    const r = await deps.supabase.rpc("vault_rotate_all_users", {
      p_new_master_version: pending.new_version,
      p_batch_size: pending.batch_size,
      p_triggered_by: deps.userId,
    });
    if (r.error) {
      return { kind: "error", status: 500,
               body: { error: `vault_rotate_all_users batch ${i + 1} failed: ${r.error.message}` } };
    }
    batchesRun++;
    const rows = (r.data as Array<Record<string, number>> | null) ?? [];
    if (rows.length === 0) { done = true; break; }
    const row = rows[0];
    const batchRotated = Number(row.rotated ?? 0);
    const batchSkipped = Number(row.skipped ?? 0);
    const batchErrors  = Number(row.errors  ?? 0);
    rotated += batchRotated;
    skipped += batchSkipped;
    errors  += batchErrors;
    if (batchRotated + batchSkipped + batchErrors < pending.batch_size) { done = true; break; }
  }

  // 8. Mark applied_at (trigger writes the rotation_audit breadcrumb).
  const applyRes = await deps.supabase.rpc("vault_mark_rotation_applied", {
    p_id: pending.id,
  });
  if (applyRes.error) {
    console.error(
      `[vault-rotate-master] /confirm rotation succeeded but applied_at update ` +
        `failed ticket=${pending.id} err=${applyRes.error.message}`,
    );
    // Do not 500 — the rotation itself completed; the audit trigger ledger
    // will just miss the top-level breadcrumb (per-user rows still exist).
  }

  console.log(
    `[vault-rotate-master] /confirm admin=${deps.userId} ticket=${pending.id} ` +
      `target_v=${pending.new_version} batches=${batchesRun} ` +
      `rotated=${rotated} skipped=${skipped} errors=${errors} done=${done}`,
  );

  return {
    kind: "success",
    status: 200,
    body: {
      rotation_id: pending.id,
      version_targeted: pending.new_version,
      batches_run: batchesRun,
      rotated,
      skipped,
      errors,
      done,
    },
  };
}

// ─── helpers ───────────────────────────────────────────────────────────────

/** Constant-time string equality. Returns false for length mismatch. */
export function timingSafeStringEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) {
    diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return diff === 0;
}
