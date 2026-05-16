-- =====================================================================
-- Backup audit log — track every backup run (success, failure, size)
-- =====================================================================
-- Why:
--   Supabase Pro daily auto-backups exist but are opaque (no easy way
--   to verify "did last night's backup succeed?"). This table is written
--   by our nightly GitHub Actions cron (scripts/db_dump.sh) and by
--   restore drills (scripts/restore_drill.sh) so the owner can answer
--   the only question that matters at 03:00 in a disaster:
--     "When is the most recent KNOWN-GOOD backup?"
--
-- Written by: db_dump.sh (kind='nightly'), restore_drill.sh (kind='drill')
-- Read by:    docs/DISASTER_RECOVERY.md runbook + Telegram alert script
-- =====================================================================

CREATE TABLE IF NOT EXISTS public.backup_audit_log (
  id                BIGSERIAL PRIMARY KEY,
  run_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  kind              TEXT NOT NULL CHECK (kind IN ('nightly', 'manual', 'drill', 'pre_migration')),
  status            TEXT NOT NULL CHECK (status IN ('started', 'success', 'failure', 'partial')),
  source            TEXT NOT NULL DEFAULT 'github_actions',       -- 'github_actions' | 'local' | 'staging'
  destination       TEXT,                                          -- 'r2://bucket/key' | 's3://...' | 'local:/path'
  dump_bytes        BIGINT,                                        -- file size, NULL on failure
  duration_seconds  INTEGER,                                       -- wall-clock
  table_counts      JSONB,                                         -- {"profiles": 1234, "conversations": 5678, ...}
  error_message     TEXT,                                          -- non-null when status='failure'
  git_sha           TEXT,                                          -- commit that ran the backup
  notes             TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS backup_audit_log_run_at_idx
  ON public.backup_audit_log (run_at DESC);

CREATE INDEX IF NOT EXISTS backup_audit_log_kind_status_idx
  ON public.backup_audit_log (kind, status, run_at DESC);

-- ---------------------------------------------------------------------
-- RLS: nobody reads except service_role. This table contains zero PII
-- but we don't want anon users probing backup cadence.
-- ---------------------------------------------------------------------
ALTER TABLE public.backup_audit_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS backup_audit_log_service_only ON public.backup_audit_log;
CREATE POLICY backup_audit_log_service_only
  ON public.backup_audit_log
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- ---------------------------------------------------------------------
-- Convenience view: latest 30 days, owner-readable via service_role
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW public.backup_audit_recent AS
SELECT
  id,
  run_at,
  kind,
  status,
  destination,
  pg_size_pretty(dump_bytes) AS dump_size,
  duration_seconds,
  (table_counts->>'profiles')::INTEGER AS profiles_count,
  (table_counts->>'conversations')::INTEGER AS conversations_count,
  (table_counts->>'ai_usage')::INTEGER AS ai_usage_count,
  error_message
FROM public.backup_audit_log
WHERE run_at > NOW() - INTERVAL '30 days'
ORDER BY run_at DESC;

GRANT SELECT ON public.backup_audit_recent TO service_role;

-- ---------------------------------------------------------------------
-- Sanity-check helper: returns hours since last successful nightly.
-- If > 30 hours, you have a problem. The DR runbook reads this.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.hours_since_last_good_backup()
RETURNS NUMERIC
LANGUAGE sql
STABLE
AS $$
  SELECT EXTRACT(EPOCH FROM (NOW() - MAX(run_at))) / 3600
  FROM public.backup_audit_log
  WHERE kind = 'nightly'
    AND status = 'success';
$$;

GRANT EXECUTE ON FUNCTION public.hours_since_last_good_backup() TO service_role;

COMMENT ON TABLE public.backup_audit_log IS
  'Append-only log of every DB backup run. Written by scripts/db_dump.sh + scripts/restore_drill.sh. See docs/DISASTER_RECOVERY.md.';
