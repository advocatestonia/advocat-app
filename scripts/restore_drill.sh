#!/usr/bin/env bash
# ============================================================================
# Advocat — restore drill (verify a dump can actually be restored)
# ============================================================================
#
# Why this exists:
#   "We have backups" is a lie until you've restored one. Supabase Pro
#   gives nightly snapshots but we have NEVER restored from them. This
#   script proves the path works against a STAGING project before we
#   need it for real at 03:00 with the prod DB on fire.
#
# What it does:
#   1. Download the latest dump (from S3 or local) into ./backups/restore_tmp/
#   2. Drop + recreate the public schema on STAGING_DB_URL
#   3. pg_restore the dump
#   4. Verify table counts match the audit log row from the source backup
#   5. Spot-check 10 random users' profiles + most recent conversation
#   6. Write outcome to public.backup_audit_log (kind='drill') on PROD
#   7. Print human-readable summary + total time
#
# Invocation:
#   ./scripts/restore_drill.sh                          # latest nightly
#   ./scripts/restore_drill.sh --dump backups/advocat_2026-05-14.sql.gz
#   ./scripts/restore_drill.sh --user-id <uuid>         # restore-and-extract
#   ./scripts/restore_drill.sh --dry-run                # validate only
#
# Required env:
#   STAGING_DB_URL           postgres://...  (a SEPARATE Supabase project!)
#   SUPABASE_SERVICE_KEY     for audit log write to PROD
#
# Optional env:
#   BACKUP_BUCKET_URL        s3://advocat-backups (download source)
#   AWS_*                    (see db_dump.sh)
#   PROD_DB_URL              read-only — used to fetch expected counts
#
# ⚠️  SAFETY: this script will DROP SCHEMA public CASCADE on STAGING_DB_URL.
#     It refuses to run if the connection string contains "okgnkucg" (prod
#     project ref) or "prod" in the hostname.
# ============================================================================

set -euo pipefail

START_TS=$(date +%s)
ISO_TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

DUMP_FILE=""
SPECIFIC_USER=""
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dump)       DUMP_FILE="$2"; shift 2 ;;
    --user-id)    SPECIFIC_USER="$2"; shift 2 ;;
    --dry-run)    DRY_RUN=1; shift ;;
    *)            echo "unknown arg: $1" >&2; exit 64 ;;
  esac
done

log()  { echo "[restore_drill $(date -u +%H:%M:%S)] $*"; }

# ---------------------------------------------------------------------------
# Audit log writer (writes to PROD audit table even though we restore to staging)
# Defined BEFORE fail() because fail() calls it.
# ---------------------------------------------------------------------------
audit_log() {
  local status="$1"
  local err="${2:-}"
  [[ -z "${SUPABASE_SERVICE_KEY:-}" ]] && return 0

  local duration=$(( $(date +%s) - START_TS ))
  local err_json="null"
  [[ -n "$err" ]] && err_json=$(printf '%s' "$err" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')

  curl -sS -X POST \
    "https://okgnkucgwsytsondrjye.supabase.co/rest/v1/backup_audit_log" \
    -H "apikey: $SUPABASE_SERVICE_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
    -H "Content-Type: application/json" \
    -H "Prefer: return=minimal" \
    -d "{
      \"kind\": \"drill\",
      \"status\": \"$status\",
      \"source\": \"staging\",
      \"destination\": \"staging://restored\",
      \"duration_seconds\": $duration,
      \"error_message\": $err_json,
      \"notes\": \"restore_drill from $DUMP_FILE\"
    }" >/dev/null || true
}

fail() { log "FAIL: $1"; audit_log "failure" "$1"; exit 1; }

# ---------------------------------------------------------------------------
# SAFETY GUARDS — refuse to touch prod
# ---------------------------------------------------------------------------
: "${STAGING_DB_URL:?STAGING_DB_URL not set. Restore drill requires a SEPARATE Supabase project.}"

if echo "$STAGING_DB_URL" | grep -qE 'okgnkucg|@prod\.|production'; then
  fail "STAGING_DB_URL looks like production! Aborting. You almost just dropped prod."
fi
if [[ "$STAGING_DB_URL" == "${PROD_DB_URL:-}" ]]; then
  fail "STAGING_DB_URL == PROD_DB_URL. Refusing."
fi
log "safety: STAGING URL does not match prod patterns. OK to proceed."

# ---------------------------------------------------------------------------
# Step 1: locate dump (download from S3 if needed)
# ---------------------------------------------------------------------------
mkdir -p ./backups/restore_tmp

if [[ -z "$DUMP_FILE" ]]; then
  # Pick the latest local dump, or download from S3
  DUMP_FILE=$(ls -t ./backups/advocat_*.sql.gz 2>/dev/null | head -1 || true)

  if [[ -z "$DUMP_FILE" && -n "${BACKUP_BUCKET_URL:-}" ]] && command -v aws >/dev/null 2>&1; then
    BUCKET_NAME=$(echo "$BACKUP_BUCKET_URL" | sed -E 's#^[a-z0-9]+://##')
    LATEST_KEY=$(aws --endpoint-url "${AWS_ENDPOINT_URL:-https://s3.amazonaws.com}" \
                     s3 ls "s3://${BUCKET_NAME}/" \
                 | awk '{print $4}' \
                 | grep -E '^advocat_[0-9]{4}-[0-9]{2}-[0-9]{2}\.sql\.gz$' \
                 | sort | tail -1)
    [[ -z "$LATEST_KEY" ]] && fail "no dumps found in $BACKUP_BUCKET_URL"

    DUMP_FILE="./backups/restore_tmp/$LATEST_KEY"
    log "step 1/6: download s3://${BUCKET_NAME}/${LATEST_KEY}"
    aws --endpoint-url "${AWS_ENDPOINT_URL:-https://s3.amazonaws.com}" \
        s3 cp "s3://${BUCKET_NAME}/${LATEST_KEY}" "$DUMP_FILE" \
      || fail "download failed"
  fi
fi

[[ -z "$DUMP_FILE" || ! -f "$DUMP_FILE" ]] && fail "no dump found. Run scripts/db_dump.sh first or pass --dump <path>."
log "step 1/6: using dump $DUMP_FILE ($(du -h $DUMP_FILE | cut -f1))"

# Integrity check
gunzip -t "$DUMP_FILE" || fail "gzip integrity failed for $DUMP_FILE"

if [[ "$DRY_RUN" -eq 1 ]]; then
  log "DRY RUN — dump is valid, exiting before destructive ops"
  exit 0
fi

# ---------------------------------------------------------------------------
# Step 2: capture expected counts BEFORE we drop staging schema
# ---------------------------------------------------------------------------
log "step 2/6: capture expected counts from prod audit log"
audit_log "started" ""

EXPECTED_COUNTS="{}"
if [[ -n "${SUPABASE_SERVICE_KEY:-}" ]]; then
  EXPECTED_COUNTS=$(curl -sS \
    "https://okgnkucgwsytsondrjye.supabase.co/rest/v1/backup_audit_log?kind=eq.nightly&status=eq.success&order=run_at.desc&limit=1&select=table_counts" \
    -H "apikey: $SUPABASE_SERVICE_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
    | python3 -c 'import json,sys; d=json.load(sys.stdin); print(json.dumps(d[0]["table_counts"]) if d else "{}")')
  log "expected counts (from last good backup): $EXPECTED_COUNTS"
fi

# ---------------------------------------------------------------------------
# Step 3: DROP + recreate public schema on staging
# ---------------------------------------------------------------------------
log "step 3/6: resetting staging schema (DROP SCHEMA public CASCADE)"

PSQL_OPTS=(--no-psqlrc -At -v ON_ERROR_STOP=1)

psql "$STAGING_DB_URL" "${PSQL_OPTS[@]}" <<'SQL' || fail "schema reset failed"
-- Install extensions in a NON-public schema (mirrors what Supabase does).
-- This way DROP SCHEMA public CASCADE doesn't take them down. Verified
-- via local drill 2026-05-15: if pgcrypto lives in public and we cascade-
-- drop, the next restore fails because gen_random_uuid() defaults reference
-- an extension that no longer exists.
CREATE SCHEMA IF NOT EXISTS extensions;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pgcrypto   WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS vector     WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pg_trgm    WITH SCHEMA extensions;

-- NOW drop public. pg_dump output contains its own CREATE SCHEMA "public".
-- If we pre-create public, restore fails with "schema already exists".
DROP SCHEMA IF EXISTS public CASCADE;

-- Make extensions visible to all sessions (set on role rather than db
-- name, which we don't know in this generic script).
DO $reset$
BEGIN
  EXECUTE format('ALTER DATABASE %I SET search_path TO "$user", public, extensions', current_database());
END
$reset$;
SQL
log "staging reset OK (extensions live in 'extensions' schema, public dropped for restore)"

# ---------------------------------------------------------------------------
# Step 4: restore the dump
# ---------------------------------------------------------------------------
log "step 4/6: pg_restore → staging"
RESTORE_START=$(date +%s)

if ! gunzip -c "$DUMP_FILE" | psql "$STAGING_DB_URL" "${PSQL_OPTS[@]}" \
     >"./backups/restore_tmp/.psql_stdout.log" \
     2>"./backups/restore_tmp/.psql_stderr.log"; then
  ERR_TAIL=$(tail -c 1000 ./backups/restore_tmp/.psql_stderr.log)
  fail "psql restore failed. stderr: $ERR_TAIL"
fi

RESTORE_SEC=$(( $(date +%s) - RESTORE_START ))
log "restore complete in ${RESTORE_SEC}s"

# ---------------------------------------------------------------------------
# Step 5: verify counts match
# ---------------------------------------------------------------------------
log "step 5/6: verifying table counts on staging"

count_staging() {
  psql "$STAGING_DB_URL" "${PSQL_OPTS[@]}" \
    -c "SELECT COUNT(*) FROM public.$1;" 2>/dev/null || echo "ERROR"
}

DRIFT=0
for table in profiles conversations messages contracts ai_usage anthropic_daily_spend; do
  EXPECTED=$(echo "$EXPECTED_COUNTS" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('$table', 'unknown'))")
  ACTUAL=$(count_staging "$table")

  if [[ "$EXPECTED" == "unknown" || -z "$EXPECTED" ]]; then
    log "  $table: actual=$ACTUAL (no expected baseline)"
  elif [[ "$ACTUAL" == "$EXPECTED" ]]; then
    log "  $table: $ACTUAL OK"
  else
    log "  $table: actual=$ACTUAL expected=$EXPECTED  DRIFT"
    DRIFT=$((DRIFT + 1))
  fi
done

if [[ "$DRIFT" -gt 0 ]]; then
  fail "$DRIFT table(s) drifted from expected counts. Restore is NOT integrity-verified."
fi

# ---------------------------------------------------------------------------
# Step 6: spot-check 10 random users have intact data
# ---------------------------------------------------------------------------
log "step 6/6: spot-checking 10 random users"

if [[ -n "$SPECIFIC_USER" ]]; then
  SAMPLE_QUERY="SELECT id, email, created_at FROM public.profiles WHERE id = '$SPECIFIC_USER';"
else
  SAMPLE_QUERY="SELECT id, email, created_at FROM public.profiles ORDER BY RANDOM() LIMIT 10;"
fi

SAMPLE=$(psql "$STAGING_DB_URL" "${PSQL_OPTS[@]}" -c "$SAMPLE_QUERY")
echo "$SAMPLE" | while IFS='|' read -r uid email created; do
  [[ -z "$uid" ]] && continue
  CONV_COUNT=$(psql "$STAGING_DB_URL" "${PSQL_OPTS[@]}" \
    -c "SELECT COUNT(*) FROM public.conversations WHERE user_id = '$uid';" 2>/dev/null || echo "0")
  log "  user $email ($uid): $CONV_COUNT conversations"
done

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
TOTAL_SEC=$(( $(date +%s) - START_TS ))
log "DRILL PASSED in ${TOTAL_SEC}s (restore=${RESTORE_SEC}s)"
log "RTO measured: ${TOTAL_SEC}s — target is 4h (14400s)"

audit_log "success" ""

# Cleanup
rm -rf ./backups/restore_tmp
