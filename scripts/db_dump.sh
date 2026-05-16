#!/usr/bin/env bash
# ============================================================================
# Advocat — nightly DB dump (additional layer on top of Supabase auto-backups)
# ============================================================================
#
# Why this exists:
#   Supabase Pro gives you daily PITR + 7-day retention. That is one provider's
#   word. This script gives us a second, independent copy on cloud object
#   storage that survives "Supabase deletes our project by mistake" / billing
#   lapse / region outage. RPO = 24h, RTO = 4h. See docs/DISASTER_RECOVERY.md.
#
# What it does:
#   1. supabase db dump  →  ./backups/advocat_YYYY-MM-DD.sql.gz
#   2. Upload to S3-compatible bucket (R2 / B2 / S3 — set BACKUP_BUCKET_URL)
#   3. Write a row into public.backup_audit_log (table_counts, size, duration)
#   4. Prune local + remote copies older than 14 days
#   5. Telegram alert on failure (optional — needs TELEGRAM_BOT_TOKEN)
#
# Invocation:
#   ./scripts/db_dump.sh                       # nightly
#   ./scripts/db_dump.sh --kind pre_migration  # before risky migration
#   ./scripts/db_dump.sh --local-only          # skip cloud upload (MVP mode)
#
# Required env:
#   SUPABASE_DB_URL          postgres://...   (with password)
#   SUPABASE_PROJECT_REF     okgnkucgwsytsondrjye
#   SUPABASE_SERVICE_KEY     for audit log write
#
# Optional env (cloud upload):
#   BACKUP_BUCKET_URL        s3://advocat-backups | r2://... | b2://...
#   AWS_ACCESS_KEY_ID        (works for R2/B2 in S3-compat mode too)
#   AWS_SECRET_ACCESS_KEY
#   AWS_ENDPOINT_URL         R2: https://<acct>.r2.cloudflarestorage.com
#                            B2: https://s3.<region>.backblazeb2.com
#
# Optional env (alerts):
#   TELEGRAM_BOT_TOKEN
#   TELEGRAM_CHAT_ID
# ============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Args
# ---------------------------------------------------------------------------
KIND="nightly"
LOCAL_ONLY=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --kind)        KIND="$2"; shift 2 ;;
    --local-only)  LOCAL_ONLY=1; shift ;;
    *)             echo "unknown arg: $1" >&2; exit 64 ;;
  esac
done

# ---------------------------------------------------------------------------
# Env validation — fail-loud, not silent
# ---------------------------------------------------------------------------
: "${SUPABASE_DB_URL:?SUPABASE_DB_URL not set}"
: "${SUPABASE_PROJECT_REF:=okgnkucgwsytsondrjye}"

START_TS=$(date +%s)
ISO_TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
DATE_TAG=$(date -u +%Y-%m-%d)
BACKUP_DIR="${BACKUP_DIR:-./backups}"
mkdir -p "$BACKUP_DIR"

DUMP_FILE="$BACKUP_DIR/advocat_${DATE_TAG}.sql.gz"
TABLE_COUNTS_FILE="$BACKUP_DIR/.counts_${DATE_TAG}.json"
GIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

log()  { echo "[db_dump $(date -u +%H:%M:%S)] $*"; }
fail() {
  local msg="$1"
  log "FAIL: $msg"
  audit_log "failure" "$msg" 0
  telegram_alert "Advocat backup FAILED: $msg"
  exit 1
}

# ---------------------------------------------------------------------------
# Audit log writer — best-effort, never blocks the dump itself
# ---------------------------------------------------------------------------
audit_log() {
  local status="$1"
  local err="${2:-}"
  local size="${3:-0}"
  local duration=$(( $(date +%s) - START_TS ))

  if [[ -z "${SUPABASE_SERVICE_KEY:-}" ]]; then
    log "no SUPABASE_SERVICE_KEY → skipping audit log row"
    return 0
  fi

  local counts_json="{}"
  if [[ -f "$TABLE_COUNTS_FILE" ]]; then
    counts_json=$(cat "$TABLE_COUNTS_FILE")
  fi

  local err_json="null"
  if [[ -n "$err" ]]; then
    err_json=$(printf '%s' "$err" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')
  fi

  local destination="local:$DUMP_FILE"
  [[ -n "${BACKUP_BUCKET_URL:-}" && "$LOCAL_ONLY" -eq 0 ]] && destination="${BACKUP_BUCKET_URL}/advocat_${DATE_TAG}.sql.gz"

  local body
  body=$(cat <<EOF
{
  "kind": "$KIND",
  "status": "$status",
  "source": "github_actions",
  "destination": "$destination",
  "dump_bytes": $size,
  "duration_seconds": $duration,
  "table_counts": $counts_json,
  "error_message": $err_json,
  "git_sha": "$GIT_SHA",
  "notes": "advocat_${DATE_TAG}.sql.gz"
}
EOF
)

  curl -sS -X POST \
    "https://${SUPABASE_PROJECT_REF}.supabase.co/rest/v1/backup_audit_log" \
    -H "apikey: $SUPABASE_SERVICE_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
    -H "Content-Type: application/json" \
    -H "Prefer: return=minimal" \
    -d "$body" || log "audit_log POST failed (non-fatal)"
}

telegram_alert() {
  [[ -z "${TELEGRAM_BOT_TOKEN:-}" || -z "${TELEGRAM_CHAT_ID:-}" ]] && return 0
  curl -sS -X POST \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}" \
    -d "text=$1" >/dev/null || true
}

# ---------------------------------------------------------------------------
# Step 1: pre-flight table counts (for audit row + post-restore verification)
# ---------------------------------------------------------------------------
log "kind=$KIND  date=$DATE_TAG  git=$GIT_SHA"
log "step 1/5: counting critical tables…"

PSQL_OPTS=(--no-psqlrc -At -v ON_ERROR_STOP=1)

count_table() {
  local table="$1"
  PGCONNECT_TIMEOUT=10 psql "$SUPABASE_DB_URL" "${PSQL_OPTS[@]}" \
    -c "SELECT COUNT(*) FROM public.${table};" 2>/dev/null || echo "0"
}

cat > "$TABLE_COUNTS_FILE" <<EOF
{
  "profiles": $(count_table profiles),
  "conversations": $(count_table conversations),
  "messages": $(count_table messages),
  "contracts": $(count_table contracts),
  "ai_usage": $(count_table ai_usage),
  "anthropic_daily_spend": $(count_table anthropic_daily_spend),
  "halt_rail_triggers": $(count_table halt_rail_triggers),
  "case_memory": $(count_table case_memory),
  "law_chunks_v2": $(count_table law_chunks_v2)
}
EOF
log "counts captured: $(cat $TABLE_COUNTS_FILE | tr -d '\n' | tr -s ' ')"

audit_log "started" "" 0

# ---------------------------------------------------------------------------
# Step 2: pg_dump (public schema, no owner, data + DDL, gzip)
# ---------------------------------------------------------------------------
log "step 2/5: pg_dump → $DUMP_FILE"

# We dump only the public schema (auth/storage are managed by Supabase
# and can be restored from their auto-backups). --no-owner because we
# restore into a fresh staging project with different roles.
# IMPORTANT: this is run from CI without TTY — explicitly pipe stderr.
if ! pg_dump "$SUPABASE_DB_URL" \
       --schema=public \
       --no-owner \
       --no-privileges \
       --format=plain \
       --quote-all-identifiers \
       --exclude-table-data='public.law_chunks*' \
       --exclude-table-data='public.case_chunks' \
       --exclude-table-data='public.statute_aliases' \
       2>"$BACKUP_DIR/.dump_stderr_${DATE_TAG}.log" \
     | gzip -9 > "$DUMP_FILE"; then
  fail "pg_dump exited non-zero. stderr: $(tail -c 500 $BACKUP_DIR/.dump_stderr_${DATE_TAG}.log)"
fi

# Note on --exclude-table-data: the 36K corpus chunks are reproducible
# from the ingest scripts (scripts/ingest_law_corpus.ts) and would bloat
# the nightly dump by ~400MB. Schema is dumped, data is rebuilt on restore.
# See docs/DISASTER_RECOVERY.md "Corpus restore path".

DUMP_SIZE=$(stat -f%z "$DUMP_FILE" 2>/dev/null || stat -c%s "$DUMP_FILE")
log "dump complete: $(du -h $DUMP_FILE | cut -f1) ($DUMP_SIZE bytes)"

if [[ "$DUMP_SIZE" -lt 10240 ]]; then
  fail "dump suspiciously small ($DUMP_SIZE bytes) — refusing to upload"
fi

# Quick smoke: make sure gzip is valid and contains expected DDL
if ! gunzip -t "$DUMP_FILE" 2>/dev/null; then
  fail "gzip integrity check failed on $DUMP_FILE"
fi
if ! gunzip -c "$DUMP_FILE" | head -c 65536 | grep -q "CREATE TABLE"; then
  fail "dump does not contain any CREATE TABLE statements (truncated?)"
fi

# ---------------------------------------------------------------------------
# Step 3: upload to S3-compatible storage (skipped in --local-only / MVP mode)
# ---------------------------------------------------------------------------
if [[ "$LOCAL_ONLY" -eq 1 ]]; then
  log "step 3/5: SKIPPED (--local-only). dump stays at $DUMP_FILE"
elif [[ -z "${BACKUP_BUCKET_URL:-}" ]]; then
  log "step 3/5: SKIPPED (BACKUP_BUCKET_URL not set). MVP mode — local dump only."
  log "  Owner action: set BACKUP_BUCKET_URL + AWS_ACCESS_KEY_ID + AWS_SECRET_ACCESS_KEY + AWS_ENDPOINT_URL"
  log "  R2 setup: https://developers.cloudflare.com/r2/api/s3/tokens/"
else
  log "step 3/5: upload to $BACKUP_BUCKET_URL"
  if ! command -v aws >/dev/null 2>&1; then
    fail "aws CLI required for upload. Install: brew install awscli (or use --local-only)"
  fi

  S3_KEY="advocat_${DATE_TAG}.sql.gz"
  # BACKUP_BUCKET_URL is "s3://bucket-name" or "r2://bucket-name"
  BUCKET_NAME=$(echo "$BACKUP_BUCKET_URL" | sed -E 's#^[a-z0-9]+://##')

  AWS_OPTS=(--endpoint-url "${AWS_ENDPOINT_URL:-https://s3.amazonaws.com}")

  if ! aws "${AWS_OPTS[@]}" s3 cp "$DUMP_FILE" "s3://${BUCKET_NAME}/${S3_KEY}" \
         --storage-class STANDARD_IA 2>&1 | tee -a "$BACKUP_DIR/.upload_${DATE_TAG}.log"; then
    fail "S3 upload failed (see $BACKUP_DIR/.upload_${DATE_TAG}.log)"
  fi
  log "uploaded: s3://${BUCKET_NAME}/${S3_KEY}"
fi

# ---------------------------------------------------------------------------
# Step 4: prune local + remote copies older than 14 days
# ---------------------------------------------------------------------------
log "step 4/5: prune local copies older than 14 days"
find "$BACKUP_DIR" -name 'advocat_*.sql.gz' -mtime +14 -print -delete || true

if [[ -n "${BACKUP_BUCKET_URL:-}" && "$LOCAL_ONLY" -eq 0 ]] && command -v aws >/dev/null 2>&1; then
  CUTOFF=$(date -u -v-14d +%Y-%m-%d 2>/dev/null || date -u -d '14 days ago' +%Y-%m-%d)
  aws "${AWS_OPTS[@]}" s3 ls "s3://${BUCKET_NAME}/" 2>/dev/null \
    | awk '{print $4}' \
    | grep -E '^advocat_[0-9]{4}-[0-9]{2}-[0-9]{2}\.sql\.gz$' \
    | while read -r key; do
        key_date=$(echo "$key" | sed -E 's/advocat_(.*)\.sql\.gz/\1/')
        if [[ "$key_date" < "$CUTOFF" ]]; then
          log "  prune remote: $key"
          aws "${AWS_OPTS[@]}" s3 rm "s3://${BUCKET_NAME}/${key}" || true
        fi
      done
fi

# ---------------------------------------------------------------------------
# Step 5: audit log success row
# ---------------------------------------------------------------------------
log "step 5/5: write audit log success"
audit_log "success" "" "$DUMP_SIZE"

DURATION=$(( $(date +%s) - START_TS ))
log "DONE in ${DURATION}s. dump=$DUMP_FILE size=$(du -h $DUMP_FILE | cut -f1)"

# Slack/Telegram success ping only on weekly (Sun) to avoid noise
if [[ "$(date -u +%u)" == "7" ]]; then
  telegram_alert "Advocat weekly backup OK: $(du -h $DUMP_FILE | cut -f1), ${DURATION}s"
fi
