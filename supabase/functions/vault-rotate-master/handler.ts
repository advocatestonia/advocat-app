// vault-rotate-master/handler.ts — pure logic for admin-driven master rotation.
// -----------------------------------------------------------------------------
// Operation:
//   POST /vault-rotate-master { new_version: 2, batch_size?: 100, max_batches?: 50 }
//
// Loops up to `max_batches` calls of the SQL bulk-rotation RPC, aggregating
// counts. Each batch is its own transaction so a single bad row only fails
// THAT user (audited as outcome='error') without rolling back peers.
//
// Admin gate: a user is "admin" if their auth.users.id appears in the env
// var ADMIN_USER_IDS (comma-separated UUIDs). We do NOT introduce a new DB
// table — the env-var allowlist is the simplest defensible model for an
// owner-driven operation that should fire <1×/year.
//
// Pure handler — no Deno-global IO. The thin server wrapper in index.ts
// injects Deps so tests can mock Supabase + env.
// -----------------------------------------------------------------------------

export interface SupabaseLike {
  rpc(fn: string, params: Record<string, unknown>): Promise<{
    data: unknown;
    error: { message: string; code?: string } | null;
  }>;
}

export interface Deps {
  supabase: SupabaseLike;
  /** Acting user id (post-JWT auth + admin allowlist check). */
  userId: string;
}

// ─── Request / response contracts ──────────────────────────────────────────

export interface RotateRequest {
  new_version: number;
  batch_size?: number;   // 1..1000, default 100
  max_batches?: number;  // 1..100, default 10 (cap one HTTP call's blast radius)
}

export interface RotateProgress {
  version_targeted: number;
  batches_run: number;
  rotated: number;
  skipped: number;
  errors: number;
  done: boolean; // true if the final batch returned <batch_size rotations
}

export interface RotateSuccess {
  kind: "success";
  status: 200;
  body: RotateProgress;
}

export interface RotateError {
  kind: "error";
  status: number;
  body: { error: string };
}

export type RotateResult = RotateSuccess | RotateError;

// ─── Validation ────────────────────────────────────────────────────────────

const MAX_BATCH_SIZE = 1000;
const MAX_BATCHES_HARD_CAP = 100;
const DEFAULT_BATCH_SIZE = 100;
const DEFAULT_MAX_BATCHES = 10;

export function validateRotateRequest(
  body: unknown,
): { ok: true; req: Required<RotateRequest> } | RotateError {
  if (!body || typeof body !== "object") {
    return {
      kind: "error",
      status: 400,
      body: { error: "body must be JSON object" },
    };
  }
  const b = body as Record<string, unknown>;
  if (typeof b.new_version !== "number" || !Number.isInteger(b.new_version) ||
      b.new_version < 1) {
    return {
      kind: "error",
      status: 400,
      body: { error: "new_version must be positive integer" },
    };
  }
  const batchSize = b.batch_size === undefined
    ? DEFAULT_BATCH_SIZE
    : (typeof b.batch_size === "number" ? b.batch_size : NaN);
  if (!Number.isInteger(batchSize) || batchSize < 1 || batchSize > MAX_BATCH_SIZE) {
    return {
      kind: "error",
      status: 400,
      body: { error: `batch_size must be 1..${MAX_BATCH_SIZE}` },
    };
  }
  const maxBatches = b.max_batches === undefined
    ? DEFAULT_MAX_BATCHES
    : (typeof b.max_batches === "number" ? b.max_batches : NaN);
  if (!Number.isInteger(maxBatches) || maxBatches < 1 || maxBatches > MAX_BATCHES_HARD_CAP) {
    return {
      kind: "error",
      status: 400,
      body: { error: `max_batches must be 1..${MAX_BATCHES_HARD_CAP}` },
    };
  }
  return {
    ok: true,
    req: {
      new_version: b.new_version,
      batch_size: batchSize,
      max_batches: maxBatches,
    },
  };
}

/**
 * Parse comma-separated UUIDs from an env var. Robust to whitespace + empty
 * entries. Returns lowercased values for case-insensitive comparison.
 */
export function parseAdminIds(raw: string | undefined | null): Set<string> {
  if (!raw) return new Set();
  return new Set(
    raw.split(",")
      .map((s) => s.trim().toLowerCase())
      .filter((s) => s.length > 0),
  );
}

export function isAdmin(userId: string, adminIds: Set<string>): boolean {
  if (!userId) return false;
  return adminIds.has(userId.toLowerCase());
}

// ─── Run (POST) ────────────────────────────────────────────────────────────

export async function runRotateMaster(
  rawBody: unknown,
  deps: Deps,
): Promise<RotateResult> {
  const v = validateRotateRequest(rawBody);
  if (!("ok" in v)) return v;
  const req = v.req;

  let rotated = 0;
  let skipped = 0;
  let errors = 0;
  let batchesRun = 0;
  let done = false;

  for (let i = 0; i < req.max_batches; i++) {
    const r = await deps.supabase.rpc("vault_rotate_all_users", {
      p_new_master_version: req.new_version,
      p_batch_size: req.batch_size,
      p_triggered_by: deps.userId,
    });
    if (r.error) {
      return {
        kind: "error",
        status: 500,
        body: {
          error: `vault_rotate_all_users batch ${i + 1} failed: ${r.error.message}`,
        },
      };
    }
    batchesRun++;
    // RPC returns array of rows (RETURNS TABLE) — postgrest yields a single
    // row in a 1-element array.
    const rows = (r.data as Array<Record<string, number>> | null) ?? [];
    if (rows.length === 0) {
      done = true;
      break;
    }
    const row = rows[0];
    const batchRotated = Number(row.rotated ?? 0);
    const batchSkipped = Number(row.skipped ?? 0);
    const batchErrors  = Number(row.errors ?? 0);
    rotated += batchRotated;
    skipped += batchSkipped;
    errors  += batchErrors;

    // If a batch returned fewer touches than batch_size, we drained the
    // outstanding-rotation queue.
    if (batchRotated + batchSkipped + batchErrors < req.batch_size) {
      done = true;
      break;
    }
  }

  return {
    kind: "success",
    status: 200,
    body: {
      version_targeted: req.new_version,
      batches_run: batchesRun,
      rotated,
      skipped,
      errors,
      done,
    },
  };
}
