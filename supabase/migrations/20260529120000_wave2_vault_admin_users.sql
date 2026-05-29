-- =============================================================================
-- 20260529120000_wave2_vault_admin_users.sql
-- Wave-2 fix W2-08 (audit INFRA-04): move vault-rotation admin gate from a
-- plaintext env var into a vault-resident table + add OOB confirm flow.
-- =============================================================================
-- Audit reference: docs/security_audit_2026-05-28/findings/06_infra_security.md
-- (INFRA-04 — Vault rotation: single-env-var admin gate, no co-sign, no MFA)
--
-- Threat model closed:
--   Today the admin gate for vault-rotate-master is `ADMIN_USER_IDS` — a
--   comma-separated env var. Anyone who can edit Supabase project env vars
--   (i.e. anyone with Supabase Dashboard write) can append their own user_id
--   and then trigger a master-key re-wrap that touches every user's DEK.
--   This migration moves the admin allowlist into `app_vault.admin_users` and
--   introduces `app_vault.pending_rotations` so the edge fn can require an
--   out-of-band confirmation token before the actual rotation executes.
--
-- Design notes:
--   - `app_vault` schema chosen to keep all encryption-control-plane state
--     under the same RLS-locked perimeter as `master_key_versions` and
--     `rotation_audit`.
--   - RLS lets authenticated users read THEIR OWN row only (so admins can
--     see if they're enrolled / check their telegram_chat_id), and blocks
--     everything else. INSERT/UPDATE goes through service_role only.
--   - `pending_rotations.confirm_token_hash` is `digest(token, 'sha256')`
--     hex — the cleartext token is sent OOB (Telegram + email) and never
--     stored. 15-min TTL via `expires_at`; the confirm path verifies hash
--     equality + not-expired in SQL.
--   - We do NOT auto-insert any admin rows. The owner backfills manually
--     post-deploy from the current ADMIN_USER_IDS value (see TODO at end).
-- =============================================================================

-- ─── 1. admin_users — vault-resident allowlist ─────────────────────────────
CREATE TABLE IF NOT EXISTS app_vault.admin_users (
  user_id            UUID PRIMARY KEY,
  added_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  added_by           UUID REFERENCES auth.users(id),
  last_rotation_at   TIMESTAMPTZ,
  telegram_chat_id   TEXT,                  -- OOB primary channel; NULL = fall back to email only
  email_for_oob      TEXT NOT NULL,         -- fallback channel; required
  active             BOOLEAN NOT NULL DEFAULT true,
  notes              TEXT,
  CONSTRAINT admin_users_email_shape
    CHECK (email_for_oob ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$')
);

COMMENT ON TABLE app_vault.admin_users IS
  'Wave-2 W2-08 (audit INFRA-04). Replaces the ADMIN_USER_IDS env var as the '
  'source of truth for vault-rotate-master admin gating. Service-role-only '
  'writes; authenticated users may read only their own row (so an admin can '
  'verify enrollment + telegram channel). Active=false soft-revokes.';

COMMENT ON COLUMN app_vault.admin_users.telegram_chat_id IS
  'Telegram chat id (numeric string) used by the edge fn to deliver the OOB '
  'confirmation token via TELEGRAM_BOT_TOKEN bot. NULL = no Telegram channel '
  '(falls back to email only).';

COMMENT ON COLUMN app_vault.admin_users.email_for_oob IS
  'Required fallback channel. Receives the OOB confirm token via Resend if '
  'Telegram is absent or fails. Validated against a basic email shape.';

-- RLS: deny-by-default + self-read for an enrolled admin.
ALTER TABLE app_vault.admin_users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS admin_users_read_self ON app_vault.admin_users;
CREATE POLICY admin_users_read_self ON app_vault.admin_users
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

-- Lock down all default grants — service_role gets explicit SELECT/INSERT.
REVOKE ALL ON TABLE app_vault.admin_users FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE app_vault.admin_users TO service_role;

CREATE INDEX IF NOT EXISTS admin_users_active_idx
  ON app_vault.admin_users (active) WHERE active = true;

-- ─── 2. pending_rotations — OOB confirm ticket ledger ──────────────────────
-- Each /initiate call creates a row with a SHA-256 hash of the cleartext
-- token. The /confirm call re-hashes the supplied token and compares.
-- Append-only by convention (no UPDATE policy); the edge fn does set
-- confirmed_at + applied_at via service_role.
CREATE TABLE IF NOT EXISTS app_vault.pending_rotations (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  initiator_user_id      UUID NOT NULL,
  confirm_token_hash     TEXT NOT NULL,    -- hex of digest(token, 'sha256')
  created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at             TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '15 minutes'),
  confirmed_at           TIMESTAMPTZ,
  applied_at             TIMESTAMPTZ,
  reason                 TEXT NOT NULL,
  allow_outside_window   BOOLEAN NOT NULL DEFAULT false,
  -- Forwarded args from /initiate so the /confirm call cannot redirect the
  -- rotation to a different target version after the token has already been
  -- emitted to the admin's OOB channel.
  new_version            INT NOT NULL,
  batch_size             INT NOT NULL DEFAULT 100,
  max_batches            INT NOT NULL DEFAULT 10,
  -- Channel hint for forensics; not used in the confirm decision.
  oob_channel            TEXT NOT NULL CHECK (oob_channel IN ('telegram','email','both')),
  -- Header context captured at /initiate time for the audit ledger.
  initiator_ip           TEXT,
  initiator_ua           TEXT,
  CONSTRAINT pending_rotations_reason_shape
    CHECK (reason ~ '^[A-Za-z0-9_\-\. ]{4,256}$'),
  CONSTRAINT pending_rotations_expires_future
    CHECK (expires_at > created_at)
);

COMMENT ON TABLE app_vault.pending_rotations IS
  'OOB-confirm ticket ledger for vault-rotate-master (Wave-2 W2-08, audit '
  'INFRA-04). /initiate writes the row + emits cleartext token OOB. /confirm '
  're-hashes the supplied token and matches against confirm_token_hash. '
  '15-min TTL via expires_at; confirmed_at + applied_at set by service_role.';

CREATE INDEX IF NOT EXISTS pending_rotations_initiator_idx
  ON app_vault.pending_rotations (initiator_user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS pending_rotations_unapplied_idx
  ON app_vault.pending_rotations (expires_at)
  WHERE applied_at IS NULL;

ALTER TABLE app_vault.pending_rotations ENABLE ROW LEVEL SECURITY;
-- No authenticated-user policies: only service_role touches this table.
REVOKE ALL ON TABLE app_vault.pending_rotations FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE app_vault.pending_rotations TO service_role;

-- ─── 3. is_admin() helper — used by edge fn via service_role ──────────────
-- Encapsulates the "is this user an active admin" check so the edge fn does
-- not need to embed a SELECT pattern that could be regressed. STABLE so it
-- can be inlined; SECURITY DEFINER so it can read app_vault.admin_users
-- even from a service_role call without re-granting.
CREATE OR REPLACE FUNCTION app_vault.is_admin(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = app_vault, public, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1
      FROM app_vault.admin_users
     WHERE user_id = p_user_id
       AND active = true
  );
$$;

COMMENT ON FUNCTION app_vault.is_admin(UUID) IS
  'Returns true iff p_user_id is an active row in app_vault.admin_users. '
  'Replaces the ADMIN_USER_IDS env-var allowlist used by vault-rotate-master.';

REVOKE EXECUTE ON FUNCTION app_vault.is_admin(UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION app_vault.is_admin(UUID) TO service_role;

-- ─── 4. Audit trigger: surface rotation events to app_vault.rotation_audit ─
-- When /confirm marks a pending row applied_at, we want the same forensic
-- trail format used by the per-user rotation. The edge fn writes individual
-- rotation_audit rows per user; here we add a top-level "rotation initiated"
-- breadcrumb so a forensic auditor can correlate the OOB ticket to the
-- per-user rows by (triggered_by, time-window).
--
-- We do NOT emit on INSERT (the ticket existing is not a security event yet
-- — only confirmation matters).
CREATE OR REPLACE FUNCTION app_vault._pending_rotations_audit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = app_vault, public, pg_temp
AS $$
BEGIN
  IF NEW.applied_at IS NOT NULL AND OLD.applied_at IS NULL THEN
    -- Sentinel row at user_id=initiator, from_version=0, to_version=new_version.
    -- Distinguishable from per-user rows because from_version=0 + outcome='rotated'
    -- only occurs in the no-DEK-row skip branch (which sets outcome='skipped').
    INSERT INTO app_vault.rotation_audit
      (user_id, from_version, to_version, triggered_by, outcome, error_message)
    VALUES
      (NEW.initiator_user_id, 0, NEW.new_version, NEW.initiator_user_id,
       'rotated',
       format('OOB-confirmed rotation ticket %s reason=%s outside_window=%s',
              NEW.id, NEW.reason, NEW.allow_outside_window));
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS pending_rotations_audit_trg ON app_vault.pending_rotations;
CREATE TRIGGER pending_rotations_audit_trg
  AFTER UPDATE ON app_vault.pending_rotations
  FOR EACH ROW
  EXECUTE FUNCTION app_vault._pending_rotations_audit();

-- ─── 5. Rate-limit helper: initiate cap ────────────────────────────────────
-- The edge fn /initiate path is also gated by the existing
-- consume_rate_limit RPC under bucket 'vault-rotate-master-initiate' (1/min
-- per admin). The SQL-side helper below is a defence-in-depth — refuses
-- /initiate if an earlier ticket from the same admin is still pending and
-- not yet expired. Prevents a stuck admin from spamming the OOB channel.
CREATE OR REPLACE FUNCTION app_vault.has_unconfirmed_pending(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = app_vault, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1
      FROM app_vault.pending_rotations
     WHERE initiator_user_id = p_user_id
       AND applied_at IS NULL
       AND confirmed_at IS NULL
       AND expires_at > now()
  );
$$;

REVOKE EXECUTE ON FUNCTION app_vault.has_unconfirmed_pending(UUID)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION app_vault.has_unconfirmed_pending(UUID) TO service_role;

-- ─── 6. Public PostgREST wrappers ──────────────────────────────────────────
-- Supabase Edge functions access PostgREST under the `public` schema by
-- default. The wrappers below let the edge fn call the app_vault helpers and
-- mutate the admin_users / pending_rotations rows without depending on
-- app_vault being added to the project's exposed-schemas list.

-- 6a. is_admin wrapper.
CREATE OR REPLACE FUNCTION public.vault_is_admin(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, app_vault, pg_temp
AS $$
  SELECT app_vault.is_admin(p_user_id);
$$;
REVOKE EXECUTE ON FUNCTION public.vault_is_admin(UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.vault_is_admin(UUID) TO service_role;

-- 6b. has_unconfirmed_pending wrapper.
CREATE OR REPLACE FUNCTION public.vault_has_unconfirmed_pending(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, app_vault, pg_temp
AS $$
  SELECT app_vault.has_unconfirmed_pending(p_user_id);
$$;
REVOKE EXECUTE ON FUNCTION public.vault_has_unconfirmed_pending(UUID)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.vault_has_unconfirmed_pending(UUID)
  TO service_role;

-- 6c. Look up the active admin row for a user. Returns NULL if absent/inactive.
CREATE OR REPLACE FUNCTION public.vault_get_admin(p_user_id UUID)
RETURNS TABLE (
  user_id          UUID,
  telegram_chat_id TEXT,
  email_for_oob    TEXT,
  active           BOOLEAN
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, app_vault, pg_temp
AS $$
  SELECT user_id, telegram_chat_id, email_for_oob, active
    FROM app_vault.admin_users
   WHERE user_id = p_user_id
     AND active = true;
$$;
REVOKE EXECUTE ON FUNCTION public.vault_get_admin(UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.vault_get_admin(UUID) TO service_role;

-- 6d. Create a pending_rotations ticket. Returns id + expires_at.
CREATE OR REPLACE FUNCTION public.vault_create_pending_rotation(
  p_initiator_user_id    UUID,
  p_confirm_token_hash   TEXT,
  p_reason               TEXT,
  p_allow_outside_window BOOLEAN,
  p_new_version          INT,
  p_batch_size           INT,
  p_max_batches          INT,
  p_oob_channel          TEXT,
  p_initiator_ip         TEXT,
  p_initiator_ua         TEXT
)
RETURNS TABLE (id UUID, expires_at TIMESTAMPTZ)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, app_vault, pg_temp
AS $$
DECLARE
  v_id UUID;
  v_expires TIMESTAMPTZ;
BEGIN
  INSERT INTO app_vault.pending_rotations (
    initiator_user_id, confirm_token_hash, reason,
    allow_outside_window, new_version, batch_size, max_batches,
    oob_channel, initiator_ip, initiator_ua
  ) VALUES (
    p_initiator_user_id, p_confirm_token_hash, p_reason,
    p_allow_outside_window, p_new_version, p_batch_size, p_max_batches,
    p_oob_channel, p_initiator_ip, p_initiator_ua
  )
  RETURNING pending_rotations.id, pending_rotations.expires_at
    INTO v_id, v_expires;
  id := v_id;
  expires_at := v_expires;
  RETURN NEXT;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.vault_create_pending_rotation(
  UUID, TEXT, TEXT, BOOLEAN, INT, INT, INT, TEXT, TEXT, TEXT)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.vault_create_pending_rotation(
  UUID, TEXT, TEXT, BOOLEAN, INT, INT, INT, TEXT, TEXT, TEXT)
  TO service_role;

-- 6e. Fetch a pending row by id (no row-level filter on initiator —
--     the edge fn already gates by is_admin; either admin may confirm).
CREATE OR REPLACE FUNCTION public.vault_get_pending_rotation(p_id UUID)
RETURNS TABLE (
  id                   UUID,
  initiator_user_id    UUID,
  confirm_token_hash   TEXT,
  expires_at           TIMESTAMPTZ,
  confirmed_at         TIMESTAMPTZ,
  applied_at           TIMESTAMPTZ,
  new_version          INT,
  batch_size           INT,
  max_batches          INT,
  allow_outside_window BOOLEAN,
  reason               TEXT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, app_vault, pg_temp
AS $$
  SELECT id, initiator_user_id, confirm_token_hash, expires_at,
         confirmed_at, applied_at, new_version, batch_size, max_batches,
         allow_outside_window, reason
    FROM app_vault.pending_rotations
   WHERE id = p_id;
$$;
REVOKE EXECUTE ON FUNCTION public.vault_get_pending_rotation(UUID)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.vault_get_pending_rotation(UUID)
  TO service_role;

-- 6f. Mark a pending row confirmed/applied. Two distinct mutations so the
--     edge fn writes the audit timestamps in the right phase.
CREATE OR REPLACE FUNCTION public.vault_mark_rotation_confirmed(p_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, app_vault, pg_temp
AS $$
DECLARE v_rows INT;
BEGIN
  UPDATE app_vault.pending_rotations
     SET confirmed_at = now()
   WHERE id = p_id
     AND confirmed_at IS NULL;
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  RETURN v_rows > 0;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.vault_mark_rotation_confirmed(UUID)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.vault_mark_rotation_confirmed(UUID)
  TO service_role;

CREATE OR REPLACE FUNCTION public.vault_mark_rotation_applied(p_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, app_vault, pg_temp
AS $$
DECLARE v_rows INT;
BEGIN
  UPDATE app_vault.pending_rotations
     SET applied_at = now()
   WHERE id = p_id
     AND applied_at IS NULL;
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  RETURN v_rows > 0;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.vault_mark_rotation_applied(UUID)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.vault_mark_rotation_applied(UUID)
  TO service_role;

-- =============================================================================
-- TODO (owner, manual, post-deploy)
-- =============================================================================
-- Backfill the existing ADMIN_USER_IDS env-var entries into app_vault.admin_users
-- BEFORE removing the env var. The current ADMIN_USER_IDS value lives only in
-- the Supabase project's Edge Function env settings — this migration intentionally
-- does NOT read it (we don't want a migration that depends on edge-fn env state).
--
-- Owner action:
--   1. Read current ADMIN_USER_IDS from Supabase Dashboard → Project Settings
--      → Edge Functions → Environment variables.
--   2. For each UUID, decide telegram_chat_id (chat with @AdvocatVaultBot once,
--      then `GET /getUpdates` to read chat.id — see runbook).
--   3. Decide email_for_oob (an inbox you actually monitor in real time).
--   4. As service_role (via Supabase SQL Editor):
--        INSERT INTO app_vault.admin_users
--          (user_id, telegram_chat_id, email_for_oob, added_by, notes)
--        VALUES
--          ('<uuid-from-env>',
--           '<telegram chat id or NULL>',
--           '<inbox you watch>',
--           NULL,                       -- bootstrap row, no prior admin
--           'Backfilled from ADMIN_USER_IDS env var on YYYY-MM-DD');
--   5. ONLY AFTER the table is populated AND the new vault-rotate-master edge
--      fn is deployed AND a dry-run /initiate succeeds end-to-end, remove
--      ADMIN_USER_IDS from the Supabase env. The edge fn will then refuse all
--      rotations until the table is populated.
--
-- See: docs/security_audit_2026-05-28/fixes/wave2_vault_rotation_runbook.md
-- =============================================================================
