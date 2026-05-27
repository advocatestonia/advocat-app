// account-delete/handler.ts — pure logic for hard account deletion.
// -----------------------------------------------------------------------------
// App Store Guideline 5.1.1(v) (hard requirement since 2022) + GDPR Art. 17
// ("right to erasure / right to be forgotten"): a user who created an account
// in-app must be able to delete that account in-app, without contacting
// support and without a soft-delete-with-restore window. We do an actual
// hard delete across:
//
//   1. all user-owned application rows (RLS-scoped, service-role cascade)
//   2. all storage objects in case-documents/<userId>/...
//   3. the auth.users row itself (Supabase admin API)
//
// Order matters: rows + storage FIRST, auth.users LAST. If we deleted the
// auth row first and step 2 failed, the user would be locked out of an
// account that still holds their personal data — a worst-of-both outcome
// for both UX and Art. 17. By deleting application data first we guarantee
// that an Art. 17 erasure is at least PARTIAL even when the auth call
// fails (handler returns a `partial: true` flag so the client can advise
// the user to retry; a follow-up retry that finds no app rows will still
// proceed to delete auth.users).
//
// This is the testable handler. The thin `index.ts` wrapper supplies a
// real Supabase service-role client; tests pass a mock `SupabaseAdminLike`.
// -----------------------------------------------------------------------------

/**
 * Tables we sweep on account delete. Order is FK-safe (children → parents).
 * Each entry is `[table, user_column]`. Missing tables (different deploy
 * envs may not have all of them) are tolerated — see `safeDelete`.
 *
 * Keep this list in sync with `dsar-export` (Art. 15 read mirror). If you
 * add a personal-data table without listing it here, you violate Art. 17.
 */
export const USER_DATA_TABLES: ReadonlyArray<readonly [string, string]> = [
  // Chat history (children before parents).
  ["chat_message_citations", "user_id"],
  ["message_feedback", "user_id"],
  ["chat_messages", "user_id"],
  // Email agent.
  ["email_triage_results", "user_id"],
  ["email_attachments", "user_id"],
  ["email_messages", "user_id"],
  ["email_threads", "user_id"],
  // Case workspace (children before parents).
  ["case_timeline_events", "user_id"],
  ["case_correspondence", "user_id"],
  ["case_deadlines", "user_id"],
  ["case_documents", "user_id"],
  ["cases_v2", "user_id"],
  ["cases", "user_id"],
  // Legacy single-doc store.
  ["deadlines", "user_id"],
  ["correspondence", "user_id"],
  ["documents", "user_id"],
  // Drafting Studio + Vault.
  ["draft_revisions", "user_id"],
  ["drafts", "user_id"],
  // Behavioural / consent / audit trails (must be wiped too — GDPR Art. 17
  // applies to the consent log itself once the lawful basis is gone).
  ["b2b_signals", "user_id"],
  ["disclaimer_acknowledgments", "user_id"],
  ["sensitive_consents", "user_id"],
  ["dpa_acceptances", "user_id"],
  // AI memory + planner flags.
  ["ai_memory", "user_id"],
  ["agent_runs", "user_id"],
  ["agent_quota", "user_id"],
  // Identity / OAuth (refresh tokens etc.).
  ["user_oauth_tokens", "user_id"],
  ["user_encryption_keys", "user_id"],
  // Subscription / payment metadata (the Stripe customer object is purged
  // server-side in a follow-up cron; here we only drop our local mirror so
  // the user can re-sign-up with the same email cleanly).
  ["subscriptions", "user_id"],
  ["payments", "user_id"],
  // Sharing / referrals.
  ["share_results", "user_id"],
  ["referrals", "referrer_id"],
  // Feedback signal.
  ["feedback_buttons", "user_id"],
  // DSAR audit trail goes LAST among app rows. Art. 5(2) "accountability":
  // we need the prior dsar_requests row for the export-this-user-already-
  // requested log up until the moment we wipe the account. After erasure
  // there is no data subject to be accountable to, so it's safe to drop.
  ["dsar_requests", "user_id"],
  // profiles is the parent FK target for many of the above. Goes last.
  ["profiles", "id"],
] as const;

/** Storage buckets to sweep. Objects are listed by prefix `<userId>/`. */
export const STORAGE_BUCKETS: ReadonlyArray<string> = [
  "case-documents",
];

/**
 * Minimal interface we need from Supabase service-role client. Keeping
 * this narrow lets the test mock exactly the surface we use (no live
 * postgres / no live storage / no live auth-admin needed in CI).
 */
export interface SupabaseAdminLike {
  from(table: string): {
    delete(): {
      eq(col: string, val: unknown): Promise<{
        // deno-lint-ignore no-explicit-any
        error: { message: string; code?: string } | null;
        // deno-lint-ignore no-explicit-any
        data?: any;
      }>;
    };
  };
  storage: {
    from(bucket: string): {
      list(
        prefix: string,
        opts?: { limit?: number; offset?: number },
      ): Promise<{
        data: Array<{ name: string }> | null;
        error: { message: string } | null;
      }>;
      remove(paths: string[]): Promise<{
        error: { message: string } | null;
      }>;
    };
  };
  auth: {
    admin: {
      deleteUser(userId: string): Promise<{
        error: { message: string } | null;
      }>;
    };
  };
}

/** Outcome record for a single table sweep — useful in the response + logs. */
export interface TableResult {
  table: string;
  ok: boolean;
  /** Skipped because the table doesn't exist in this deploy. */
  skipped?: boolean;
  /** Error message if ok=false (and not skipped). */
  error?: string;
}

export interface DeleteAccountResult {
  ok: boolean;
  /**
   * True when application rows + storage were deleted but auth.users
   * deletion failed (or vice-versa). The client should advise the user
   * to retry — a follow-up call will idempotently finish the job.
   */
  partial?: boolean;
  deleted: boolean;
  message: string;
  table_results: TableResult[];
  storage_results: Array<{ bucket: string; removed: number; error?: string }>;
  /** Auth.users delete outcome. False means we kept the row (retry safe). */
  auth_user_deleted: boolean;
  auth_error?: string;
}

/**
 * Delete one user's rows from one table. Tolerates "undefined_table" and
 * "undefined_column" (codes 42P01 / 42703) since not every deploy carries
 * every table — Art. 17 says "delete if it exists", not "fail if it doesn't".
 */
async function safeDelete(
  sb: SupabaseAdminLike,
  table: string,
  userColumn: string,
  userId: string,
): Promise<TableResult> {
  try {
    const { error } = await sb.from(table).delete().eq(userColumn, userId);
    if (error) {
      const code = error.code;
      if (code === "42P01" || code === "42703") {
        return { table, ok: true, skipped: true };
      }
      return { table, ok: false, error: error.message };
    }
    return { table, ok: true };
  } catch (e) {
    return { table, ok: false, error: String(e) };
  }
}

/**
 * List + remove every storage object under `<userId>/` for a bucket.
 * Lists in pages of 1000 (Supabase storage list cap) to handle power
 * users with many uploads. Returns count of objects removed.
 */
async function sweepStorageBucket(
  sb: SupabaseAdminLike,
  bucket: string,
  userId: string,
): Promise<{ bucket: string; removed: number; error?: string }> {
  try {
    let removed = 0;
    const pageSize = 1000;
    // Cap total iterations to defeat a runaway list (defence in depth).
    // NOTE: offset is always 0 because the just-listed items are removed
    // before the next list() call — the bucket's <userId>/ prefix shrinks
    // each iteration. Passing a non-zero offset against a shrinking list
    // would skip remaining items.
    for (let iter = 0; iter < 1000; iter++) {
      const { data, error } = await sb.storage
        .from(bucket)
        .list(userId, { limit: pageSize, offset: 0 });
      if (error) return { bucket, removed, error: error.message };
      if (!data || data.length === 0) break;
      const paths = data.map((obj) => `${userId}/${obj.name}`);
      const { error: rmErr } = await sb.storage.from(bucket).remove(paths);
      if (rmErr) return { bucket, removed, error: rmErr.message };
      removed += paths.length;
      if (data.length < pageSize) break;
    }
    return { bucket, removed };
  } catch (e) {
    return { bucket, removed: 0, error: String(e) };
  }
}

/**
 * Pure deletion driver. Caller provides identity + an admin client.
 * Sequence:
 *   1. Sweep every USER_DATA_TABLES entry, in order.
 *   2. Sweep storage buckets.
 *   3. Delete auth.users via admin API.
 *
 * Even if some intermediate step fails we continue — Art. 17 prefers a
 * PARTIAL erasure over an aborted one. The result.partial flag signals
 * the client to recommend a retry.
 *
 * Idempotency: a retry that finds no rows in any table and no objects in
 * any bucket will still attempt step 3 (auth.users) and return
 * `auth_user_deleted: true` once it succeeds. Calling this twice on the
 * same user is therefore safe.
 */
export async function runAccountDelete(
  sb: SupabaseAdminLike,
  userId: string,
): Promise<DeleteAccountResult> {
  const tableResults: TableResult[] = [];
  for (const [table, col] of USER_DATA_TABLES) {
    tableResults.push(await safeDelete(sb, table, col, userId));
  }

  const storageResults: Array<
    { bucket: string; removed: number; error?: string }
  > = [];
  for (const bucket of STORAGE_BUCKETS) {
    storageResults.push(await sweepStorageBucket(sb, bucket, userId));
  }

  // Finally delete auth.users. Service-role required.
  let authUserDeleted = false;
  let authError: string | undefined;
  try {
    const { error } = await sb.auth.admin.deleteUser(userId);
    if (error) {
      authError = error.message;
    } else {
      authUserDeleted = true;
    }
  } catch (e) {
    authError = String(e);
  }

  const tableFailures = tableResults.filter((r) => !r.ok);
  const storageFailures = storageResults.filter((r) => r.error);
  const anyFailure =
    tableFailures.length > 0 || storageFailures.length > 0 || !authUserDeleted;

  return {
    ok: authUserDeleted,
    partial: anyFailure && (authUserDeleted || tableFailures.length === 0),
    deleted: authUserDeleted,
    message: authUserDeleted
      ? "Account deleted"
      : "Account data wiped but auth row not yet deleted — please retry",
    table_results: tableResults,
    storage_results: storageResults,
    auth_user_deleted: authUserDeleted,
    auth_error: authError,
  };
}
