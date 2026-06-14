// account-delete/handler.ts — pure logic for hard account deletion.
// -----------------------------------------------------------------------------
// App Store Guideline 5.1.1(v) (hard requirement since 2022) + GDPR Art. 17
// ("right to erasure / right to be forgotten"): a user who created an account
// in-app must be able to delete that account in-app, without contacting
// support and without a soft-delete-with-restore window. We do an actual
// hard delete across:
//
//   1. all user-owned application rows (RLS-scoped, service-role cascade)
//   2. all storage objects under <userId>/ in every user-scoped bucket
//      (case-documents, contract-reviews — see STORAGE_BUCKETS)
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
//
// ── 2026-05-28 WAVE 1 GDPR FIX ───────────────────────────────────────────────
// Source of truth for this table list:
//   docs/security_audit_2026-05-28/findings/02_database_rls.md §5
//   docs/security_audit_2026-05-28/findings/01_edge_functions_security.md P0-03
// Removed non-existent tables (cases_v2, ai_memory, drafts, draft_revisions,
// share_results, referrals, payments, case_correspondence, feedback_buttons).
// Added ~30 real tables that previously retained personal data after delete.
// New DELETE_STRICT env var: when set to "1", undefined_table/column errors
// FAIL the run instead of silently passing — prevents future drift.
// CI coverage_test.ts asserts every public.* table with user_id/owner_id/
// created_by column is either in USER_DATA_TABLES or EXCLUDED_TABLES (with
// reason). Adding a new user-data table without listing it here will fail CI.
// -----------------------------------------------------------------------------

/**
 * When DELETE_STRICT=1 the handler throws on undefined_table / undefined_column
 * (codes 42P01 / 42703) instead of silently skipping. Default-on in prod via
 * `supabase secrets set DELETE_STRICT=1`. The silent-skip behaviour was the
 * root cause of the audit P0-7 GDPR Art. 17 catastrophe — every misnamed
 * table simply vanished from the sweep with no signal.
 *
 * Default LOOSE in tests so CI envs without every table still run.
 */
const DELETE_STRICT = (Deno?.env?.get?.("DELETE_STRICT") ?? "0") === "1";

/**
 * Tables we sweep on account delete. Order is FK-safe (children → parents).
 *
 * Canonical source: docs/security_audit_2026-05-28/findings/02_database_rls.md §5
 * + 01_edge_functions_security.md P0-03.
 *
 * Keep this list in sync with `dsar-export` (Art. 15 read mirror). If you
 * add a personal-data table without listing it here, you violate Art. 17.
 * The `coverage_test.ts` CI assertion will fail the build on orphan tables.
 */
export const USER_DATA_TABLES: ReadonlyArray<readonly [string, string]> = [
  // ── Chat history (children before parents). ──────────────────────────────
  //   chat_planner_traces is NOT listed: it has no user_id column and is
  //   erased via FK message_id → chat_messages(id) ON DELETE CASCADE. See
  //   EXCLUDED_TABLES. (Listing it with a non-existent user_id column produced
  //   a false strictFailure under DELETE_STRICT=1.)
  ["chat_message_citations", "user_id"],
  ["message_feedback", "user_id"],
  ["chat_messages", "user_id"],
  ["case_chat_sessions", "user_id"],

  // ── Email agent (children before parents). ───────────────────────────────
  //   Removed dead entries that do not exist in the live schema and only
  //   produced false strictFailures: email_triage_lawyer_opinions,
  //   triage_proposed_actions, email_retry_queue, email_connections,
  //   email_user_settings.
  ["email_triage_results", "user_id"],
  ["email_attachments", "user_id"],
  ["email_messages", "user_id"],
  ["email_threads", "user_id"],

  // ── Case workspace (children before parents). ────────────────────────────
  //   Removed dead entries (no such table in live schema): case_file,
  //   case_facts, case_phase, checker_reports.
  ["case_timeline_events", "user_id"],
  ["case_file_deadlines", "user_id"],
  ["case_file_parties", "user_id"],
  ["case_file_events", "user_id"],
  ["case_deadlines", "user_id"],
  ["case_documents", "user_id"],
  ["user_cases", "user_id"],
  ["cases", "user_id"],

  // ── Legacy single-doc store + correspondence. ────────────────────────────
  //   Removed dead entry: correspondence_audit (no such table).
  ["deadlines", "user_id"],
  ["correspondence", "user_id"],
  ["documents", "user_id"],

  // ── Drafting Studio + Vault. ─────────────────────────────────────────────
  //   draft_versions (FK draft_id → user_drafts CASCADE) and
  //   vault_document_tags (FK document_id → documents CASCADE) are erased by
  //   cascade and have no user_id column — see EXCLUDED_TABLES.
  ["user_drafts", "user_id"],
  ["vault_tags", "user_id"],

  // ── New feature tables (product-expansion 2026-06-14). All hold user-PII
  //    and must be wiped on erasure (Art. 17). ───────────────────────────────
  ["case_followups", "user_id"], // soft next-step tasks per case
  ["checklist_progress", "user_id"], // per-user checklist completion state
  ["user_doc_chunks", "user_id"], // semantic-search embeddings of own docs

  // ── B2B silent signals. ──────────────────────────────────────────────────
  ["b2b_signals", "user_id"],

  // ── Behavioural / consent / audit trails. GDPR Art. 17 applies to the
  //    consent log itself once the lawful basis is gone. We keep
  //    `attorney_privilege_acceptance` because retaining proof of consent
  //    AT THE TIME OF SERVICE survives erasure under Art. 17(3)(b)/(e)
  //    legitimate-interest carve-out — see EXCLUDED_TABLES rationale.
  ["disclaimer_acknowledgments", "user_id"],
  ["sensitive_consents", "user_id"],
  ["dpa_acceptances", "user_id"],
  ["consent_log", "user_id"],

  // ── AI memory + agent loop state. ────────────────────────────────────────
  ["conversation_summaries", "user_id"],
  ["user_ai_memory", "user_id"],
  ["agent_audit_log", "user_id"],
  ["agent_intentions", "user_id"],
  ["agent_runs", "user_id"],
  ["agent_quota", "user_id"],

  // ── Notifications / push. ────────────────────────────────────────────────
  ["deadline_notification_log", "user_id"],
  ["push_events", "user_id"],
  ["notification_preferences", "user_id"],
  ["notifications", "user_id"],

  // ── Account settings + usage telemetry. ──────────────────────────────────
  ["user_settings", "user_id"],
  ["user_engagement", "user_id"],
  ["user_quotas", "user_id"],
  ["voice_usage", "user_id"],
  ["ai_usage", "user_id"],

  // ── Consilium + contract review. ─────────────────────────────────────────
  //   Removed dead entry: lawyer_bookings (no such table in live schema).
  ["consilium_runs", "user_id"],
  ["contract_analysis_jobs", "user_id"],
  ["contract_reviews", "user_id"],

  // ── Adversarial corpus. ──────────────────────────────────────────────────
  //   Removed dead entry: advice_digest (no such table in live schema).
  ["advice_corrections", "user_id"],

  // ── Gold-corpus training queue. Raw, possibly-unscrubbed user question +
  //    AI answer keyed on source_user_id, with NO FK cascade to auth.users.
  //    Must be wiped on erasure (Art. 17). Curated `gold_corpus_pairs` rows
  //    derived from this queue keep only source_queue_id (SET NULL on delete);
  //    see EXCLUDED_TABLES for that derived-corpus rationale.
  ["gold_corpus_queue", "source_user_id"],

  // ── Sharing / referrals. ─────────────────────────────────────────────────
  ["shared_results", "user_id"],
  ["referral_attributions", "referred_user_id"],
  ["referral_attributions", "inviter_user_id"],
  ["referral_codes", "user_id"],

  // ── Support. ─────────────────────────────────────────────────────────────
  ["support_tickets", "user_id"],

  // ── A/B testing assignment + events. ─────────────────────────────────────
  ["ab_events", "user_id"],
  ["ab_assignments", "user_id"],

  // ── Identity / OAuth (refresh tokens etc.). ──────────────────────────────
  ["user_oauth_tokens", "user_id"],
  ["user_encryption_keys", "user_id"],

  // ── Subscription / payment metadata. The Stripe customer object is purged
  //    server-side in a follow-up cron; here we only drop our local mirrors
  //    so the user can re-sign-up with the same email cleanly.
  //    `apple_iap_transactions` cascades from auth.users via FK ON DELETE
  //    CASCADE (see EXCLUDED_TABLES) so it's not listed here — the auth.users
  //    delete in step 3 takes care of it.
  ["subscriptions", "user_id"],

  // ── DSAR audit trail goes LAST among app rows. Art. 5(2) "accountability":
  //    we need the prior dsar_requests row for the export-this-user-already-
  //    requested log up until the moment we wipe the account. After erasure
  //    there is no data subject to be accountable to, so it's safe to drop.
  ["dsar_requests", "user_id"],

  // ── profiles is the parent FK target for many of the above. Goes last.
  ["profiles", "id"],
] as const;

/**
 * User-data tables living in the NON-public `app` schema. These need an
 * explicit `.schema("app")` on the client — a plain `.from(table)` targets
 * `public` and would 42P01 (and under DELETE_STRICT=1 would FAIL the run).
 *
 * `app.email_triage_queue` (migration 20260528040000) holds user_id +
 * thread_id + a `payload` jsonb of triage content, with NO FK cascade to
 * auth.users — so deleting the auth row does NOT erase it. Left unswept, a
 * deleted user's user_id↔thread_id linkage + payload survived indefinitely
 * (GDPR Art. 17 erasure gap; also missing from the Art. 15 dsar-export
 * mirror — fix both together). The `public.*` coverage_test CI guard does
 * not see `app.*` tables, so this escaped the canary too.
 */
export const APP_SCHEMA_USER_DATA_TABLES: ReadonlyArray<
  readonly [string, string]
> = [["email_triage_queue", "user_id"]] as const;

/**
 * Tables intentionally EXCLUDED from the Art. 17 sweep. Every entry MUST
 * carry a justification — the CI assertion in `coverage_test.ts` checks
 * that every `user_id`/`owner_id`/`created_by` table in `information_schema`
 * appears in either USER_DATA_TABLES or this list.
 *
 * If you're tempted to add a new table here just to silence CI, STOP and ask
 * privacy review first. The GDPR Art. 17(3) exemptions are narrow.
 */
export const EXCLUDED_TABLES: ReadonlyArray<{ table: string; reason: string }> =
  [
    // Art. 17(3)(b): compliance with a legal obligation. The audit log is the
    // mechanism by which the controller proves it complied with Art. 5(2)
    // accountability — wiping it would defeat the legal obligation that justifies
    // its existence. Anonymise instead in a future migration (replace user_id
    // with a one-way hash after 90 days).
    {
      table: "audit_log",
      reason: "Art. 17(3)(b) accountability — legal obligation to retain",
    },
    {
      table: "backup_audit_log",
      reason: "Art. 17(3)(b) accountability — backup integrity log",
    },
    // The deletion certificate is the cryptographic PROOF that this user's data
    // was erased — deleting it would destroy the evidence of compliance. It
    // holds only user_id + email + counts + hash (no case content). Append-only
    // by trigger; the user receives the signed receipt in the delete response.
    {
      table: "deletion_certificates",
      reason:
        "Art. 17(3)(b) accountability — proof-of-erasure receipt, must survive erasure",
    },

    // Art. 17(3)(e): defence of legal claims. Attorney-privilege acceptance
    // is the proof of consent that a paying user reviewed the privilege
    // disclaimer at the time advice was given — if a future malpractice claim
    // arises after deletion, this row is the only proof that the disclaimer
    // was shown. Retained until the claim limitation period (FI 3 yrs, EE 3 yrs).
    {
      table: "attorney_privilege_acceptance",
      reason: "Art. 17(3)(e) defence of legal claims — proof of disclaimer",
    },

    // Cascade from auth.users via ON DELETE CASCADE. The auth.admin.deleteUser
    // step in this handler triggers the cascade. Listing it here too would
    // attempt a delete that always returns 0 rows (RLS service-role on a
    // table whose rows are about to be cascade-deleted by auth.users delete).
    {
      table: "apple_iap_transactions",
      reason: "Cascades from auth.users via FK ON DELETE CASCADE",
    },

    // Retention/lifecycle email log (weekly digest, win-back, insight alerts).
    // `email_events.user_id REFERENCES auth.users(id) ON DELETE CASCADE`
    // (migration 20260514160000_retention_infra.sql) — the auth.users delete in
    // step 3 of this handler wipes it automatically. Listing it in
    // USER_DATA_TABLES would only attempt a redundant delete that races the
    // cascade. Same rationale as apple_iap_transactions above.
    {
      table: "email_events",
      reason:
        "Cascades from auth.users via FK ON DELETE CASCADE (retention email log)",
    },

    // Stripe payload archive. RLS deny-all to clients. Retained for fraud
    // investigation under Art. 6(1)(f) legitimate interest; user_id appears
    // only inside the embedded Stripe JSON, not as a column.
    {
      table: "webhook_events",
      reason:
        "Stripe payload archive — Art. 6(1)(f) fraud defence; user_id is nested JSON not a column",
    },

    // Lawyer partnership tables. `partner_lawyers.lawyer_id` is the auth.users
    // ID of the LAWYER (not a regular user). Deleting a user account does
    // not delete their lawyer profile; that's a separate flow. Same for
    // lawyer_verification_audit.
    {
      table: "partner_lawyers",
      reason: "Lawyer onboarding — separate partner-offboarding flow",
    },
    {
      table: "lawyer_verification_audit",
      reason: "Tied to partner_lawyers; separate offboarding flow",
    },

    // Org tables. Deleting a user account does NOT delete their orgs (an org
    // can have other members). Org deletion is a separate flow keyed on org_id.
    {
      table: "org_members",
      reason: "Org-scoped — removed via leave-org flow, not account-delete",
    },
    {
      table: "org_audit_log",
      reason:
        "Org-scoped accountability log — survives individual member deletion",
    },
    { table: "org_invitations", reason: "Org-scoped" },
    { table: "org_subscriptions", reason: "Org-scoped" },
    { table: "org_branding", reason: "Org-scoped" },
    { table: "org_usage_counters", reason: "Org-scoped" },
    { table: "org_api_keys", reason: "Org-scoped" },
    { table: "org_api_rate_counters", reason: "Org-scoped" },
    { table: "organizations", reason: "Org-scoped" },

    // System tables with no PII.
    { table: "ingest_jobs", reason: "Internal queue — no user PII" },
    { table: "unresolved_refs", reason: "Internal queue — no user PII" },
    {
      table: "anthropic_daily_spend",
      reason: "Aggregate spend counter — no user PII",
    },
    {
      table: "rate_limit_events",
      reason: "Aggregate counter; pruned via cron",
    },
    { table: "error_log", reason: "System error log — Art. 17(3)(b)" },
    { table: "halt_rail_triggers", reason: "Internal anti-abuse log" },
    { table: "recent_alerts", reason: "Internal anti-abuse log" },
    { table: "spend_hourly_snapshot", reason: "Aggregate spend counter" },
    { table: "app_errors", reason: "System error log" },
    { table: "app_config", reason: "System config — no per-user data" },

    // Sensitive schema — cascades from public.case_documents.
    {
      table: "case_documents_sensitive",
      reason: "Cascades from public.case_documents via FK",
    },
    {
      table: "pii_redaction_map",
      reason:
        "Sensitive schema — service-role only; cascades from owner tables",
    },

    // Refund tracking (subscriptions cascade handles user link).
    {
      table: "refund_consents",
      reason:
        "Cascades via subscriptions delete; row retained for refund audit if any",
    },

    // ── FK-cascade children with NO user_id column. Listing these with a
    //    "user_id" column produced false strictFailures (42703) under
    //    DELETE_STRICT=1. The actual data IS erased via ON DELETE CASCADE when
    //    the parent row is deleted in USER_DATA_TABLES above.
    {
      table: "chat_planner_traces",
      reason:
        "Cascades from chat_messages via FK message_id ON DELETE CASCADE (no user_id column)",
    },
    {
      table: "draft_versions",
      reason:
        "Cascades from user_drafts via FK draft_id ON DELETE CASCADE (no user_id column)",
    },
    {
      table: "vault_document_tags",
      reason:
        "Cascades from documents via FK document_id ON DELETE CASCADE (no user_id column)",
    },

    // Derived training corpus. Promoted from gold_corpus_queue (which IS wiped).
    // source_queue_id FK is SET NULL on delete, severing the user link; rows hold
    // only a PII-scrubbed question/answer pair used as curated eval/training data.
    // Retained under Art. 17(3)(d) scientific-research / Art. 89 safeguards
    // (pseudonymised). If unscrubbed PII is ever found here, treat as a P0.
    {
      table: "gold_corpus_pairs",
      reason:
        "Art. 17(3)(d)/Art. 89 pseudonymised training corpus; user link SET NULL via source_queue_id",
    },

    // ── Declared in migration SQL but NOT present in the live prod schema
    //    (verified absent in information_schema 2026-05-29). They hold no data
    //    because they do not exist. The coverage_test migrations-fallback parser
    //    still sees their CREATE TABLE statements, so they are listed here to
    //    keep the canary honest. ⚠️ OWNER GATE: if the lawyer-partnership /
    //    legacy-baseline migrations are ever applied to prod, MOVE these into
    //    USER_DATA_TABLES — they carry user_id and would then retain PII.
    {
      table: "lawyer_bookings",
      reason:
        "Declared in migration 20260516200000 but NOT deployed to prod (no live table). Re-classify into USER_DATA_TABLES if the partner-booking feature is migrated.",
    },
    {
      table: "checker_reports",
      reason:
        "Declared in baseline 001 but NOT in live prod schema. Re-classify into USER_DATA_TABLES if ever deployed.",
    },
    {
      table: "email_connections",
      reason:
        "Declared in baseline 001 but NOT in live prod schema (superseded by email_threads/email_messages). Re-classify if ever deployed.",
    },
  ];

/** Storage buckets to sweep. Objects are listed by prefix `<userId>/`. */
export const STORAGE_BUCKETS: ReadonlyArray<string> = [
  "case-documents",
  // GDPR Art.17: holds user-uploaded contracts + generated review PDFs
  // (migration 20260514190000), path `{user_id}/{ts}_{name}.pdf` — same
  // `<userId>/` prefix sweepStorageBucket lists by. Was missing → a deleted
  // user's contracts survived erasure.
  "contract-reviews",
  // NOTE: `org-branding` is intentionally NOT swept here — it is org-scoped
  // (path `<org_id>/...`), not user-scoped, so individual account deletion
  // must not touch it. Org-asset erasure belongs to org-delete.
];

/**
 * Minimal interface we need from Supabase service-role client. Keeping
 * this narrow lets the test mock exactly the surface we use (no live
 * postgres / no live storage / no live auth-admin needed in CI).
 */
interface DeleteFrom {
  delete(): {
    eq(
      col: string,
      val: unknown
    ): Promise<{
      // deno-lint-ignore no-explicit-any
      error: { message: string; code?: string } | null;
      // deno-lint-ignore no-explicit-any
      data?: any;
    }>;
  };
}

export interface SupabaseAdminLike {
  from(table: string): DeleteFrom;
  /**
   * Scope subsequent `.from()` calls to a non-public schema (supabase-js
   * `createClient(...).schema("app")`). Optional in the mock surface; the
   * real client always provides it.
   */
  schema?(name: string): { from(table: string): DeleteFrom };
  storage: {
    from(bucket: string): {
      list(
        prefix: string,
        opts?: { limit?: number; offset?: number }
      ): Promise<{
        // `id` is null/absent for synthetic folder rows, set for real
        // objects — that's how the recursive sweep tells them apart.
        data: Array<{ name: string; id?: string | null }> | null;
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
  /** Skipped because the table doesn't exist in this deploy (LOOSE mode only). */
  skipped?: boolean;
  /** Error message if ok=false (and not skipped). */
  error?: string;
  /** True when DELETE_STRICT=1 and the table was missing — surfaced as failure. */
  strictFailure?: boolean;
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
  /** Echo of the DELETE_STRICT env at run time — useful for forensics. */
  strict_mode: boolean;
}

/**
 * Delete one user's rows from one table.
 *
 * Behaviour matrix:
 *   - undefined_table / undefined_column (42P01 / 42703):
 *       - DELETE_STRICT=1  → ok:false, strictFailure:true. This is the
 *         catastrophe-avoidance gate: if prod is missing a table that we
 *         expect to wipe, we want to know LOUDLY, not silently pass.
 *       - DELETE_STRICT=0  → ok:true, skipped:true (CI / dev envs).
 *   - Any other error      → ok:false, error:<msg>.
 *   - Success              → ok:true.
 */
async function safeDelete(
  source: { from(table: string): DeleteFrom },
  table: string,
  userColumn: string,
  userId: string
): Promise<TableResult> {
  try {
    const { error } = await source.from(table).delete().eq(userColumn, userId);
    if (error) {
      const code = error.code;
      if (code === "42P01" || code === "42703") {
        if (DELETE_STRICT) {
          // Log the raw schema error server-side; the client-facing struct
          // gets a stable code (no relation/column name disclosure).
          console.error(
            `[account-delete] DELETE_STRICT missing table/column on ${table} (${code}): ${error.message}`
          );
          return {
            table,
            ok: false,
            strictFailure: true,
            error: `delete_strict_missing_schema:${code}`,
          };
        }
        return { table, ok: true, skipped: true };
      }
      // Log the raw DB error server-side; surface only a stable code so we
      // don't disclose constraint/permission internals to the client.
      console.error(
        `[account-delete] delete failed on ${table} (${error.code ?? "?"}): ${
          error.message
        }`
      );
      return { table, ok: false, error: "delete_failed" };
    }
    return { table, ok: true };
  } catch (e) {
    console.error(`[account-delete] delete threw on ${table}: ${String(e)}`);
    return { table, ok: false, error: "delete_failed" };
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
  userId: string
): Promise<{ bucket: string; removed: number; error?: string }> {
  // ⚠️ Supabase Storage `.list(prefix)` is NON-RECURSIVE: it returns the
  // immediate children of `prefix` only. A folder child comes back as a row
  // with `id === null` (no `id`/`metadata` = a synthetic folder, not an
  // object), and `.remove(["<folder>"])` does NOT delete the files inside it.
  // Our objects are nested several levels deep:
  //   case-documents:  <userId>/<caseId>/<file>
  //                    <userId>/email_attachments/<rand>/<file>
  //   contract-reviews:<userId>/<ts>_<file>.pdf
  // A flat `.list(userId)` + remove therefore erased ONLY files sitting
  // directly at `<userId>/<file>` and silently left every nested object
  // behind — an Art.17 erasure gap (legal docs, medical PDFs, inbox
  // attachments survived deletion). We now walk the tree: BFS over folders,
  // removing real objects at each level.
  try {
    let removed = 0;
    const pageSize = 1000;
    const folders: string[] = [userId]; // prefixes still to visit
    let guard = 0;
    while (folders.length > 0) {
      if (guard++ > 100_000) {
        console.error(
          `[account-delete] storage sweep guard tripped on ${bucket}`
        );
        return { bucket, removed, error: "storage_sweep_guard" };
      }
      const prefix = folders.shift()!;
      // Page through this prefix with a DRAIN loop.
      //
      // VERIFIED on live Supabase Storage (2026-06-14): `.list(offset)`
      // reflects prior `.remove()`s IMMEDIATELY — removed objects vanish and
      // the survivors shift down. So a monotonically-advancing offset is WRONG:
      // after deleting page 1 (pageSize objects), the survivors move into
      // offset [0..pageSize), and reading offset=pageSize returns [] → the
      // loop breaks and leaves every object past the first page un-deleted.
      // That was a real GDPR Art. 17 incomplete-erasure bug for any prefix
      // with > pageSize objects.
      //
      // DRAIN instead:
      //   - had removable objects? remove them, then RE-LIST at the SAME
      //     offset (survivors shifted into this window). Do NOT advance.
      //   - page was all folders (nothing removed)? advance past them so we
      //     don't loop forever on the same synthetic folder rows.
      // An iteration guard bounds the worst case.
      let offset = 0;
      let iterations = 0;
      while (iterations++ < 1_000_000) {
        const { data, error } = await sb.storage
          .from(bucket)
          .list(prefix, { limit: pageSize, offset });
        if (error) {
          console.error(
            `[account-delete] storage list failed on ${bucket}/${prefix}: ${error.message}`
          );
          return { bucket, removed, error: "storage_list_failed" };
        }
        if (!data || data.length === 0) break;
        const objectPaths: string[] = [];
        for (const entry of data) {
          const e = entry as { name: string; id?: string | null };
          const childPath = `${prefix}/${e.name}`;
          // A null/absent `id` marks a synthetic folder, not a real object.
          if (e.id == null) {
            folders.push(childPath); // descend
          } else {
            objectPaths.push(childPath);
          }
        }
        if (objectPaths.length > 0) {
          const { error: rmErr } = await sb.storage
            .from(bucket)
            .remove(objectPaths);
          if (rmErr) {
            console.error(
              `[account-delete] storage remove failed on ${bucket}: ${rmErr.message}`
            );
            return { bucket, removed, error: "storage_remove_failed" };
          }
          removed += objectPaths.length;
          // Drained this window — survivors shift in at the same offset.
          // Re-list WITHOUT advancing offset (this is the fix).
          continue;
        }
        // Page was all folders (nothing removed): advance past them.
        if (data.length < pageSize) break;
        offset += pageSize;
      }
    }
    return { bucket, removed };
  } catch (e) {
    console.error(
      `[account-delete] storage sweep threw on ${bucket}: ${String(e)}`
    );
    return { bucket, removed: 0, error: "storage_sweep_failed" };
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
 *
 * In DELETE_STRICT=1 mode, any missing-table outcome is reported as a
 * failure (table_results[i].strictFailure=true) but the loop still
 * continues — we want as much erasure as possible AND a loud signal.
 */
export async function runAccountDelete(
  sb: SupabaseAdminLike,
  userId: string
): Promise<DeleteAccountResult> {
  const tableResults: TableResult[] = [];
  for (const [table, col] of USER_DATA_TABLES) {
    tableResults.push(await safeDelete(sb, table, col, userId));
  }

  // Non-public `app` schema sweep. Needs `.schema("app")` so the delete
  // targets app.* and not public.* (a plain .from would 42P01). When the
  // mock client omits .schema (CI), fall back to sb.from — the in-memory
  // fake ignores schema anyway and the real client always has it.
  const appSource =
    typeof sb.schema === "function"
      ? sb.schema("app")
      : { from: (t: string) => sb.from(t) };
  for (const [table, col] of APP_SCHEMA_USER_DATA_TABLES) {
    const r = await safeDelete(appSource, table, col, userId);
    tableResults.push({ ...r, table: `app.${table}` });
  }

  const storageResults: Array<{
    bucket: string;
    removed: number;
    error?: string;
  }> = [];
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
    ok: authUserDeleted && tableFailures.length === 0,
    partial: anyFailure && (authUserDeleted || tableFailures.length === 0),
    deleted: authUserDeleted,
    message: authUserDeleted
      ? tableFailures.length === 0
        ? "Account deleted"
        : "Account auth row deleted but some app rows failed — retry recommended"
      : "Account data wiped but auth row not yet deleted — please retry",
    table_results: tableResults,
    storage_results: storageResults,
    auth_user_deleted: authUserDeleted,
    auth_error: authError,
    strict_mode: DELETE_STRICT,
  };
}
