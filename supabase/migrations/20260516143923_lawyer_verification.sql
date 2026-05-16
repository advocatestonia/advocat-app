-- =============================================================================
-- 20260516143923_lawyer_verification.sql
--   "AI for verified attorneys — free forever" program (P12 of Bentley+ batch).
--
-- Adds five columns to public.profiles and a full audit-log table so that
-- every verification attempt — auto-approved, queued, or rejected — leaves
-- a forensic trail. The audit log is the source of truth for revocation
-- review (e.g. a lawyer removed from the bar association list).
--
-- Backwards-compatible. All new columns are nullable; no existing row is
-- touched. The auto-approval flow is gated by `lawyer_verified_at IS NOT
-- NULL` which is the explicit "verified attorney" signal Edge Functions
-- consume to grant unlimited quota.
--
-- Schema decisions:
--   * `lawyer_bar_country` is a CHAR(2) checked against ('FI','EE') rather
--     than a free-form TEXT. Adding new jurisdictions later requires
--     loosening the CHECK, which is the desired friction.
--   * `lawyer_verified_at` doubles as a tri-state flag:
--       NULL              → not verified
--       TIMESTAMPTZ value → verified at that moment
--     There is no separate boolean; the timestamp is the boolean. A
--     revocation sets the column back to NULL and writes a 'revoked'
--     audit row.
--   * `lawyer_verification_status` carries the lifecycle state for the
--     queued/pending case, where verified_at is still NULL but the user
--     has submitted an application. Values: 'pending', 'auto_approved',
--     'manually_approved', 'rejected', 'revoked'.
--   * `lawyer_practice_url` is captured for traceability — when a name
--     match is borderline, the owner reviews this URL during the manual
--     queue review.
--
-- RLS: profiles already has policies from 20260422005000_schema_drift_fix.
-- We add policies for the new audit table mirroring the support_tickets
-- shape (user reads own rows, service_role writes).
-- =============================================================================

-- ─── profiles.lawyer_* columns ──────────────────────────────────────────────
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS lawyer_verified_at         TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS lawyer_bar_country         CHAR(2),
  ADD COLUMN IF NOT EXISTS lawyer_bar_id              TEXT,
  ADD COLUMN IF NOT EXISTS lawyer_full_name           TEXT,
  ADD COLUMN IF NOT EXISTS lawyer_practice_url        TEXT,
  ADD COLUMN IF NOT EXISTS lawyer_verification_status TEXT;

-- Defensive: a pre-existing column might lack the CHECK we want. We
-- attach a NOT VALID constraint (so backfills don't fail) and validate
-- on a clean install.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'profiles_lawyer_bar_country_chk'
  ) THEN
    ALTER TABLE public.profiles
      ADD CONSTRAINT profiles_lawyer_bar_country_chk
      CHECK (lawyer_bar_country IS NULL OR lawyer_bar_country IN ('FI','EE'))
      NOT VALID;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'profiles_lawyer_status_chk'
  ) THEN
    ALTER TABLE public.profiles
      ADD CONSTRAINT profiles_lawyer_status_chk
      CHECK (lawyer_verification_status IS NULL OR lawyer_verification_status IN
             ('pending','auto_approved','manually_approved','rejected','revoked'))
      NOT VALID;
  END IF;
END$$;

-- Cap raw input sizes so a hostile payload can't bloat the row. The Edge
-- Function already truncates, but we belt-and-suspenders at the DB layer.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'profiles_lawyer_bar_id_len_chk'
  ) THEN
    ALTER TABLE public.profiles
      ADD CONSTRAINT profiles_lawyer_bar_id_len_chk
      CHECK (lawyer_bar_id IS NULL OR length(lawyer_bar_id) BETWEEN 1 AND 64)
      NOT VALID;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'profiles_lawyer_name_len_chk'
  ) THEN
    ALTER TABLE public.profiles
      ADD CONSTRAINT profiles_lawyer_name_len_chk
      CHECK (lawyer_full_name IS NULL OR length(lawyer_full_name) BETWEEN 1 AND 200)
      NOT VALID;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'profiles_lawyer_url_len_chk'
  ) THEN
    ALTER TABLE public.profiles
      ADD CONSTRAINT profiles_lawyer_url_len_chk
      CHECK (lawyer_practice_url IS NULL OR length(lawyer_practice_url) BETWEEN 1 AND 500)
      NOT VALID;
  END IF;
END$$;

-- Quick lookup for the bar registry cross-reference and for analytics.
CREATE INDEX IF NOT EXISTS idx_profiles_lawyer_verified
  ON public.profiles (lawyer_verified_at)
  WHERE lawyer_verified_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_profiles_lawyer_country_status
  ON public.profiles (lawyer_bar_country, lawyer_verification_status)
  WHERE lawyer_verification_status IS NOT NULL;

COMMENT ON COLUMN public.profiles.lawyer_verified_at IS
  'When the user was approved as a verified attorney. NULL = not verified.';
COMMENT ON COLUMN public.profiles.lawyer_bar_country IS
  'Two-letter country code of the bar association (FI / EE).';
COMMENT ON COLUMN public.profiles.lawyer_bar_id IS
  'Member ID at the bar association (e.g. Asianajajaliitto member number).';
COMMENT ON COLUMN public.profiles.lawyer_verification_status IS
  'Lifecycle state: pending | auto_approved | manually_approved | rejected | revoked.';


-- ─── lawyer_verification_audit ──────────────────────────────────────────────
-- Append-only audit log of every verification attempt. One row per
-- POST /verify-lawyer call (success or failure). The owner reviews
-- 'pending' rows in the manual queue.
--
-- Why a separate table:
--   * Profiles is small and hot; we don't want a verification history
--     blob on every row.
--   * Audit logs benefit from append-only semantics — no UPDATE policy.
--   * Revocations are also rows here, so the full timeline is queryable.
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.lawyer_verification_audit (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Snapshot of submitted form data (the registry result may diverge
  -- later if the lawyer changes practice). Capped at the same lengths
  -- as the profile columns.
  bar_country         CHAR(2) NOT NULL CHECK (bar_country IN ('FI','EE')),
  bar_id              TEXT NOT NULL CHECK (length(bar_id) BETWEEN 1 AND 64),
  full_name           TEXT NOT NULL CHECK (length(full_name) BETWEEN 1 AND 200),
  submitted_email     TEXT NOT NULL CHECK (length(submitted_email) BETWEEN 3 AND 254),
  practice_url        TEXT CHECK (practice_url IS NULL OR length(practice_url) BETWEEN 1 AND 500),

  -- Outcome of this submission.
  result              TEXT NOT NULL CHECK (result IN
                        ('auto_approved','queued','manually_approved',
                         'rejected','revoked')),

  -- Free-form context: registry response snippet, match score, reviewer
  -- notes for manual approvals. Capped at ~4 KB by application code.
  details             JSONB NOT NULL DEFAULT '{}'::jsonb,

  -- Network metadata for abuse correlation. Mirrors support_tickets.
  ip_address          TEXT,
  user_agent          TEXT CHECK (user_agent IS NULL OR length(user_agent) <= 500),

  created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS lawyer_audit_user_idx
  ON public.lawyer_verification_audit (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS lawyer_audit_result_idx
  ON public.lawyer_verification_audit (result, created_at DESC);

-- Manual review queue: the owner pulls open 'queued' rows.
CREATE INDEX IF NOT EXISTS lawyer_audit_queue_idx
  ON public.lawyer_verification_audit (created_at DESC)
  WHERE result = 'queued';

ALTER TABLE public.lawyer_verification_audit ENABLE ROW LEVEL SECURITY;

-- A user can read their own audit history (drives a "verification status"
-- panel in Settings).
CREATE POLICY "user reads own audit"
  ON public.lawyer_verification_audit
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- All writes go through the edge function as service_role.
CREATE POLICY "service writes audit"
  ON public.lawyer_verification_audit
  FOR INSERT
  TO service_role
  WITH CHECK (true);

GRANT SELECT ON public.lawyer_verification_audit TO authenticated;

COMMENT ON TABLE public.lawyer_verification_audit IS
  'Append-only audit log of every lawyer verification attempt. See migration header for lifecycle.';
