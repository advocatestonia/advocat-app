#!/usr/bin/env bash
# =============================================================================
# migration_history_repair.sh — repair supabase_migrations.schema_migrations
# so that `supabase db push --linked` works again.
#
# Context (verified 2026-06-11 against `supabase migration list --linked`,
# CLI v2.84.2, project okgnkucgwsytsondrjye):
#
#   * Remote history ends at 20260528050000, but 36 local migrations in the
#     20260515..20260527 range ARE applied on prod (each verified via
#     read-only probes — table/column/function existence via
#     information_schema/pg_proc, 2026-06-11) while being UNRECORDED in
#     remote history.  -> repair --status applied
#     Incl. 20260515040000 (ajantasa seed): probes confirmed the 5 seed rows
#     are still in ingest_jobs (count=23 for source_id LIKE '%:ajantasa') AND
#     law_chunks_v2 has 71 fi-hol chunks — ON CONFLICT DO NOTHING re-run
#     would be a no-op, and the seed was demonstrably processed.
#   * 4 versions are NOT actually applied on prod (information_schema probes
#     2026-06-11 = object missing): 20260515090000 backup_audit_log,
#     20260515200000 halt_rail_triggers, 20260516143923 lawyer verification
#     columns, 20260516200000 partner_lawyers/lawyer_bookings.
#     They are intentionally NOT repaired — `db push` must apply them.
#     All four are idempotent (IF NOT EXISTS / drop-policy-if-exists).
#     NOTE: 20260515200000 was NOT originally safe against prod — prod's
#     error_log was created by 20260515220031 with a different shape (kind/
#     source, no fn_name), so its fn_name index + v_error_log_1h view would
#     have failed with 42703. Fixed in-place 2026-06-11 with column-existence
#     guards (safe on both fresh DB and current prod).
#   * 1 orphan remote row `20260509` (truncated version of the legacy file
#     20260509_01_patch_case_facts.sql, now in supabase/migrations_applied_legacy/)
#     has no local file and blocks push.  -> repair --status reverted
#
# Prereqs: run from repo root or scripts/; project linked (supabase/config.toml);
#          7 *.down.sql moved to supabase/migrations_down/ and 5 legacy files
#          moved to supabase/migrations_applied_legacy/ (done 2026-06-11).
#
# Usage:
#   ./scripts/migration_history_repair.sh                # repairs + dry-run push
#   DRY_RUN=1 ./scripts/migration_history_repair.sh      # print commands only
#
# This script NEVER runs `db push` for real — the final step is --dry-run.
# =============================================================================
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v supabase >/dev/null 2>&1; then
  echo "ERROR: supabase CLI not found in PATH" >&2
  exit 1
fi

run() {
  if [ "${DRY_RUN:-0}" = "1" ]; then
    echo "[dry-run] $*"
  else
    echo "+ $*"
    "$@"
  fi
}

# -----------------------------------------------------------------------------
# 1. Applied-but-unrecorded versions (36) — each verified on prod 2026-06-11
#    via read-only probe (object listed in the comment).
# -----------------------------------------------------------------------------
APPLIED_VERIFIED=(
  20260515020000  # fn law_search_v2 exists (pg_proc probe)
  20260515030000  # column law_chunks_v2.license (information_schema)
  20260515040000  # ajantasa seed: 23 ingest_jobs '%:ajantasa' rows + 71 fi-hol chunks
  20260515080000  # column law_chunks_v2.chunk_tsv (information_schema)
  20260515220031  # table anthropic_daily_spend (HTTP 200)
  20260516120000  # doc-only migration, zero schema change (content-inspected)
  20260516180000  # fn law_search_hybrid_v2_qa exists (rpc probe -> 22000)
  20260517100000  # column law_chunks_v2.chunk_text_augmented (HTTP 200)
  20260519221553  # table correspondence (HTTP 200)
  20260519223000  # table dpa_acceptances (HTTP 200)
  20260519232114  # table disclaimer_acknowledgments (HTTP 200)
  20260520022058  # table sensitive_consents (HTTP 200)
  20260520031500  # table dsar_requests (HTTP 200 + beta audit)
  20260520121540  # column user_oauth_tokens.last_sync_at (HTTP 200)
  20260523010000  # table organizations (HTTP 200 + beta audit)
  20260523020000  # fn current_user_org_ids (rpc GET HTTP 200)
  20260523030000  # column case_deadlines.org_id (HTTP 200)
  20260523040000  # table org_seat_change_log (HTTP 200)
  20260523050000  # fn resolve_org_brand_by_slug (rpc GET HTTP 200)
  20260523060000  # table org_api_rate_counters (HTTP 200)
  20260523070000  # fn org_audit_log_export (rpc GET HTTP 200)
  20260525154500  # table case_timeline_events (HTTP 200 + beta audit)
  20260525190000  # column email_triage_results.sent_at (HTTP 200)
  20260525200000  # column email_triage_results.lawyer_opinions (HTTP 200)
  20260525210000  # column email_triage_results.proposed_actions (HTTP 200)
  20260525220000  # column user_cases.is_soft_shell (HTTP 200)
  20260525223000  # table b2b_signals (HTTP 200 + beta audit)
  20260525233000  # fn mark_b2b_modal_shown (rpc GET -> 25006 read-only-tx = exists)
  20260525234500  # column profiles.b2b_modal_retrigger_count (HTTP 200)
  20260526010000  # table holiday_calendars (HTTP 200)
  20260526100000  # table email_attachments (HTTP 200 + beta audit)
  20260527010000  # table agent_runs (HTTP 200 + beta audit)
  20260527020000  # table agent_quota (HTTP 200)
  20260527080200  # column user_drafts.vault_copy_id (HTTP 200)
  20260527090000  # column documents.encryption_key_id (HTTP 200)
  20260527090100  # table vault_tags (HTTP 200)
)

echo "== Step 1: mark ${#APPLIED_VERIFIED[@]} verified versions as applied =="
for ver in "${APPLIED_VERIFIED[@]}"; do
  run supabase migration repair --status applied "$ver" --linked
done

# -----------------------------------------------------------------------------
# 2. VERIFY_FIRST — resolved 2026-06-11, section kept for the audit trail.
#    20260515040000_seed_ajantasa_phase1.sql was the only version that needed
#    a SQL-editor probe (risk: re-queuing 5 ingest jobs if ingest_jobs had
#    been cleared). Probes run 2026-06-11 (read-only):
#      SELECT count(*) FROM public.ingest_jobs
#       WHERE source='finlex' AND source_id LIKE '%:ajantasa';   -- = 23 (>0)
#      SELECT count(*) FROM public.law_chunks_v2
#       WHERE act_slug='fi-hol';                                 -- = 71 (>0)
#    Seed rows still present AND processed -> moved to APPLIED_VERIFIED above.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# 3. Orphan remote history rows with no local file -> mark reverted.
#    20260509 = truncated version of legacy 20260509_01_patch_case_facts.sql
#    (file now lives in supabase/migrations_applied_legacy/; the function
#    patch_case_facts it created stays on prod — this only cleans history).
# -----------------------------------------------------------------------------
ORPHAN_REMOTE=(
  20260509
)

echo "== Step 3: mark ${#ORPHAN_REMOTE[@]} orphan remote rows as reverted =="
for ver in "${ORPHAN_REMOTE[@]}"; do
  run supabase migration repair --status reverted "$ver" --linked
done

# -----------------------------------------------------------------------------
# 4. Show resulting state + dry-run push (NO real push from this script).
# -----------------------------------------------------------------------------
echo "== Step 4: resulting migration state =="
run supabase migration list --linked

echo "== Step 5: dry-run push =="
run supabase db push --linked --dry-run

cat <<'EOF'
== EXPECTED OUTCOME ==
The dry-run must list EXACTLY 23 pending migrations:

  4 recovered (verified MISSING on prod 2026-06-11; all idempotent —
  20260515200000 was patched 2026-06-11 with fn_name column guards):
    20260515090000_backup_audit_log.sql
    20260515200000_halt_rail_metrics_and_error_log.sql
    20260516143923_lawyer_verification.sql
    20260516200000_lawyer_partnership.sql

  19 new (Wave 1/2 + hardening, 20260528060000 .. 20260530160000):
    20260528060000 20260528070000 20260528100000 20260528120000 20260528200000
    20260529100000 20260529110000 20260529120000 20260529130000 20260529140000
    20260529150000 20260529160000
    20260530100000 20260530110000 20260530120000 20260530130000 20260530140000
    20260530150000 20260530160000

Anything else pending / any "Remote migration versions not found locally" error
means the repair did not converge — STOP and re-run `supabase migration list
--linked` before pushing.
EOF
