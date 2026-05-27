-- =============================================================================
-- 20260528030000_vault_key_rotation.sql — master-key rotation infrastructure.
-- =============================================================================
-- Builds on 20260527090000_vault_encryption.sql. Sentinel risk #3:
-- `app_vault_master_key` is a single secret — if it leaks, every wrapped
-- user DEK is unwrappable. The previous migration explicitly noted "Rotation:
-- NOT in scope" — this migration adds the infra to rotate without breaking
-- existing rows. Actual rotation is a separate owner-driven event:
--
--   1. Owner provisions a NEW secret in Supabase Vault (e.g. v2):
--        SELECT vault.create_secret(
--          '<new-base64-32-bytes>',
--          'app_vault_master_key_v2',
--          'Advocat app_vault master key — version 2'
--        );
--
--   2. Owner registers the version row:
--        INSERT INTO app_vault.master_key_versions
--          (version, vault_secret_name, status)
--        VALUES (2, 'app_vault_master_key_v2', 'active');
--        UPDATE app_vault.master_key_versions
--           SET status='retired', rotated_at=now()
--         WHERE version=1;
--
--   3. Owner calls the vault-rotate-master edge fn (admin-only) with
--      { new_version: 2 } — that re-wraps every user_encryption_keys row.
--
--   4. Optionally (after grace window) revoke the v1 secret from Vault.
--
-- Backward compat: rows with master_key_version=1 continue to read using the
-- ORIGINAL 'app_vault_master_key' secret. The legacy app_vault.get_master_key()
-- behaviour is preserved via a CASE branch keyed on version=1.
-- =============================================================================

-- ─── 1. master_key_versions registry ───────────────────────────────────────
-- Single source of truth for "which vault secret name backs version N".
-- Tiny table, rarely written, frequently read inside SECURITY DEFINER calls.
CREATE TABLE IF NOT EXISTS app_vault.master_key_versions (
  version           INT PRIMARY KEY,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  vault_secret_name TEXT NOT NULL,
  rotated_at        TIMESTAMPTZ,
  status            TEXT NOT NULL
                      CHECK (status IN ('active', 'retired', 'compromised')),
  notes             TEXT
);

COMMENT ON TABLE app_vault.master_key_versions IS
  'Master-key version registry. Each row maps an INT version to a name in '
  'vault.decrypted_secrets. status=active means new rotations target this '
  'version; status=retired means historical (still readable); '
  'status=compromised means owner has declared the secret leaked — read '
  'paths still work but the rotation cron MUST treat it as urgent.';

-- Seed v1 mapping to the existing secret. Idempotent on replay.
INSERT INTO app_vault.master_key_versions (version, vault_secret_name, status, notes)
VALUES (1, 'app_vault_master_key', 'active',
        'Initial master key created with 20260527090000_vault_encryption.sql')
ON CONFLICT (version) DO NOTHING;

-- ─── 2. user_encryption_keys.master_key_version column ─────────────────────
-- All existing rows are wrapped against v1. New rotations bump this.
ALTER TABLE public.user_encryption_keys
  ADD COLUMN IF NOT EXISTS master_key_version INT NOT NULL DEFAULT 1;

COMMENT ON COLUMN public.user_encryption_keys.master_key_version IS
  'Which master key version wraps encrypted_key. Lookup app_vault.'
  'master_key_versions.vault_secret_name for the corresponding Vault secret '
  'name. Default 1 = legacy app_vault_master_key.';

-- Index for the bulk-rotation query path (find users still on old version).
CREATE INDEX IF NOT EXISTS user_encryption_keys_master_version_idx
  ON public.user_encryption_keys (master_key_version);

-- ─── 3. rotation_audit table ───────────────────────────────────────────────
-- Append-only ledger of rotation events. Lets owner verify "did the rotation
-- actually re-wrap every row" without parsing edge-fn logs.
CREATE TABLE IF NOT EXISTS app_vault.rotation_audit (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id            UUID NOT NULL,
  from_version       INT NOT NULL,
  to_version         INT NOT NULL,
  rotated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  triggered_by       UUID,                -- admin user id, NULL for cron
  outcome            TEXT NOT NULL
                       CHECK (outcome IN ('rotated', 'skipped', 'error')),
  error_message      TEXT
);

COMMENT ON TABLE app_vault.rotation_audit IS
  'Append-only audit ledger of master-key rotation events. One row per '
  'user_encryption_keys row touched (or skipped, or errored). Service-role '
  'only — no authenticated user ever reads this directly.';

CREATE INDEX IF NOT EXISTS rotation_audit_user_idx
  ON app_vault.rotation_audit (user_id, rotated_at DESC);
CREATE INDEX IF NOT EXISTS rotation_audit_to_version_idx
  ON app_vault.rotation_audit (to_version);

-- ─── 4. Helper: resolve any master key by version ──────────────────────────
-- Successor to app_vault.get_master_key(). The old fn stays (returns v1 for
-- compat); the new fn takes an explicit version and looks up the matching
-- secret name from master_key_versions.
CREATE OR REPLACE FUNCTION app_vault.get_master_key_version(p_version INT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = vault, app_vault, extensions, pg_temp
AS $$
DECLARE
  v_secret_name TEXT;
  v_key         TEXT;
BEGIN
  IF p_version IS NULL THEN
    RAISE EXCEPTION 'app_vault.get_master_key_version: p_version required';
  END IF;

  SELECT vault_secret_name
    INTO v_secret_name
    FROM app_vault.master_key_versions
   WHERE version = p_version;

  IF v_secret_name IS NULL THEN
    RAISE EXCEPTION 'app_vault: unknown master key version %', p_version;
  END IF;

  SELECT decrypted_secret INTO v_key
    FROM vault.decrypted_secrets
   WHERE name = v_secret_name
   LIMIT 1;

  IF v_key IS NULL OR length(v_key) = 0 THEN
    RAISE EXCEPTION 'app_vault: vault secret % missing or empty', v_secret_name;
  END IF;
  RETURN v_key;
END;
$$;

REVOKE EXECUTE ON FUNCTION app_vault.get_master_key_version(INT)
  FROM authenticated, anon, public;

-- ─── 5. Override _unwrap_user_key to honor the row's master_key_version ────
-- Reads master_key_version from the user's row, looks up the correct vault
-- secret, decrypts. Backward compat: version=1 falls through to the original
-- secret name without any DB write.
CREATE OR REPLACE FUNCTION app_vault._unwrap_user_key(p_user_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, app_vault, extensions, pg_temp
AS $$
DECLARE
  v_wrapped   BYTEA;
  v_version   INT;
  v_master    TEXT;
BEGIN
  SELECT encrypted_key, master_key_version
    INTO v_wrapped, v_version
    FROM public.user_encryption_keys
   WHERE user_id = p_user_id;

  IF v_wrapped IS NULL THEN
    RAISE EXCEPTION 'app_vault: no encryption key for user %', p_user_id;
  END IF;

  -- Default NULL → 1 (older rows pre-rotation column).
  v_version := COALESCE(v_version, 1);
  v_master  := app_vault.get_master_key_version(v_version);

  RETURN pgp_sym_decrypt(v_wrapped, v_master);
END;
$$;

REVOKE EXECUTE ON FUNCTION app_vault._unwrap_user_key(UUID)
  FROM authenticated, anon, public;

-- ─── 6. rotate_user_key — re-wrap one user's DEK against a new master ─────
-- Atomic transaction:
--   1. Read current encrypted_key + master_key_version
--   2. Unwrap with OLD master
--   3. Re-wrap with NEW master (looked up via master_key_versions)
--   4. UPDATE row with new ciphertext + new version + rotated_at
--   5. INSERT rotation_audit
-- Idempotent: if user is already at p_new_master_version, the call is a
-- no-op that returns 'skipped' (and still records the no-op in audit so the
-- owner sees the intent was attempted).
CREATE OR REPLACE FUNCTION app_vault.rotate_user_key(
  p_user_id            UUID,
  p_new_master_version INT,
  p_triggered_by       UUID DEFAULT NULL
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, app_vault, extensions, pg_temp
AS $$
DECLARE
  v_old_wrapped BYTEA;
  v_old_version INT;
  v_dek         TEXT;
  v_old_master  TEXT;
  v_new_master  TEXT;
  v_new_wrapped BYTEA;
  v_status      TEXT;
BEGIN
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'rotate_user_key: p_user_id required';
  END IF;
  IF p_new_master_version IS NULL THEN
    RAISE EXCEPTION 'rotate_user_key: p_new_master_version required';
  END IF;

  -- Look up + validate new version exists. We do this BEFORE touching the
  -- user row so a typo'd version doesn't burn an audit row + lock.
  SELECT status INTO v_status
    FROM app_vault.master_key_versions
   WHERE version = p_new_master_version;
  IF v_status IS NULL THEN
    RAISE EXCEPTION 'rotate_user_key: unknown master key version %',
                    p_new_master_version;
  END IF;
  IF v_status = 'retired' THEN
    RAISE EXCEPTION 'rotate_user_key: target version % is retired '
                    '(cannot rotate FORWARD to a retired key)',
                    p_new_master_version;
  END IF;

  -- Lock the user row to prevent concurrent rotations on the same user.
  SELECT encrypted_key, COALESCE(master_key_version, 1)
    INTO v_old_wrapped, v_old_version
    FROM public.user_encryption_keys
   WHERE user_id = p_user_id
   FOR UPDATE;

  IF v_old_wrapped IS NULL THEN
    -- User has no DEK yet — nothing to rotate. Record skip + return.
    INSERT INTO app_vault.rotation_audit
      (user_id, from_version, to_version, triggered_by, outcome, error_message)
    VALUES
      (p_user_id, 0, p_new_master_version, p_triggered_by, 'skipped',
       'no user_encryption_keys row');
    RETURN 'skipped';
  END IF;

  -- Idempotent: already at target version — no-op.
  IF v_old_version = p_new_master_version THEN
    INSERT INTO app_vault.rotation_audit
      (user_id, from_version, to_version, triggered_by, outcome)
    VALUES
      (p_user_id, v_old_version, p_new_master_version, p_triggered_by, 'skipped');
    RETURN 'skipped';
  END IF;

  -- Unwrap with OLD master, re-wrap with NEW master.
  BEGIN
    v_old_master := app_vault.get_master_key_version(v_old_version);
    v_dek        := pgp_sym_decrypt(v_old_wrapped, v_old_master);

    v_new_master := app_vault.get_master_key_version(p_new_master_version);
    v_new_wrapped := pgp_sym_encrypt(v_dek, v_new_master)::bytea;

    UPDATE public.user_encryption_keys
       SET encrypted_key      = v_new_wrapped,
           master_key_version = p_new_master_version,
           rotated_at         = now()
     WHERE user_id = p_user_id;

    INSERT INTO app_vault.rotation_audit
      (user_id, from_version, to_version, triggered_by, outcome)
    VALUES
      (p_user_id, v_old_version, p_new_master_version, p_triggered_by, 'rotated');

    RETURN 'rotated';
  EXCEPTION WHEN OTHERS THEN
    -- Capture failure into the audit ledger; re-raise so the caller sees it.
    INSERT INTO app_vault.rotation_audit
      (user_id, from_version, to_version, triggered_by, outcome, error_message)
    VALUES
      (p_user_id, v_old_version, p_new_master_version, p_triggered_by,
       'error', SQLERRM);
    RAISE;
  END;
END;
$$;

REVOKE EXECUTE ON FUNCTION app_vault.rotate_user_key(UUID, INT, UUID)
  FROM authenticated, anon, public;
GRANT EXECUTE ON FUNCTION app_vault.rotate_user_key(UUID, INT, UUID)
  TO service_role;

-- ─── 7. rotate_all_users — bulk rotation in batches ────────────────────────
-- Iterates over user_encryption_keys WHERE master_key_version <> p_new_version,
-- ordered by user_id (stable), in batches of p_batch_size. Returns counts
-- so the edge fn can stream progress. Idempotent — re-running picks up where
-- the previous run left off (because rotated rows now match p_new_version).
CREATE OR REPLACE FUNCTION app_vault.rotate_all_users(
  p_new_master_version INT,
  p_batch_size         INT DEFAULT 100,
  p_triggered_by       UUID DEFAULT NULL
)
RETURNS TABLE(rotated INT, skipped INT, errors INT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, app_vault, extensions, pg_temp
AS $$
DECLARE
  v_uid       UUID;
  v_outcome   TEXT;
  v_rotated   INT := 0;
  v_skipped   INT := 0;
  v_errors    INT := 0;
  v_seen      INT := 0;
BEGIN
  IF p_new_master_version IS NULL THEN
    RAISE EXCEPTION 'rotate_all_users: p_new_master_version required';
  END IF;
  IF p_batch_size IS NULL OR p_batch_size < 1 OR p_batch_size > 1000 THEN
    RAISE EXCEPTION 'rotate_all_users: p_batch_size must be 1..1000';
  END IF;

  FOR v_uid IN
    SELECT user_id
      FROM public.user_encryption_keys
     WHERE COALESCE(master_key_version, 1) <> p_new_master_version
     ORDER BY user_id
     LIMIT p_batch_size
  LOOP
    v_seen := v_seen + 1;
    BEGIN
      v_outcome := app_vault.rotate_user_key(
                     v_uid, p_new_master_version, p_triggered_by);
      IF v_outcome = 'rotated' THEN
        v_rotated := v_rotated + 1;
      ELSE
        v_skipped := v_skipped + 1;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      -- rotate_user_key already wrote an 'error' audit row + re-raised; we
      -- count and continue so one bad user doesn't break the whole batch.
      v_errors := v_errors + 1;
    END;
  END LOOP;

  rotated := v_rotated;
  skipped := v_skipped;
  errors  := v_errors;
  RETURN NEXT;
END;
$$;

REVOKE EXECUTE ON FUNCTION app_vault.rotate_all_users(INT, INT, UUID)
  FROM authenticated, anon, public;
GRANT EXECUTE ON FUNCTION app_vault.rotate_all_users(INT, INT, UUID)
  TO service_role;

-- ─── 8. PostgREST wrappers (service-role-only) ─────────────────────────────
-- Edge fn calls these via supabase.rpc(). Wrapper lives in public so
-- PostgREST exposes it; EXECUTE is restricted to service_role only — admin
-- edge fns use the service-role key, ordinary authenticated users get 403.
CREATE OR REPLACE FUNCTION public.vault_rotate_user_key(
  p_user_id            UUID,
  p_new_master_version INT,
  p_triggered_by       UUID DEFAULT NULL
)
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, app_vault, extensions, pg_temp
AS $$
  SELECT app_vault.rotate_user_key(p_user_id, p_new_master_version, p_triggered_by);
$$;

CREATE OR REPLACE FUNCTION public.vault_rotate_all_users(
  p_new_master_version INT,
  p_batch_size         INT DEFAULT 100,
  p_triggered_by       UUID DEFAULT NULL
)
RETURNS TABLE(rotated INT, skipped INT, errors INT)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, app_vault, extensions, pg_temp
AS $$
  SELECT * FROM app_vault.rotate_all_users(
    p_new_master_version, p_batch_size, p_triggered_by
  );
$$;

REVOKE EXECUTE ON FUNCTION public.vault_rotate_user_key(UUID, INT, UUID)
  FROM authenticated, anon, public;
GRANT EXECUTE ON FUNCTION public.vault_rotate_user_key(UUID, INT, UUID)
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.vault_rotate_all_users(INT, INT, UUID)
  FROM authenticated, anon, public;
GRANT EXECUTE ON FUNCTION public.vault_rotate_all_users(INT, INT, UUID)
  TO service_role;

-- ─── 9. Owner read-helper: rotation status snapshot ────────────────────────
-- Service-role-only summary: how many users on each version, last rotation,
-- audit error count in the last 24h. Lets the edge fn return a "progress"
-- block without N additional RPC calls.
CREATE OR REPLACE FUNCTION app_vault.rotation_status()
RETURNS TABLE(
  master_key_version INT,
  user_count         BIGINT,
  status             TEXT,
  recent_errors_24h  BIGINT
)
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public, app_vault, extensions, pg_temp
AS $$
  SELECT
    mv.version,
    COALESCE(uk.cnt, 0) AS user_count,
    mv.status,
    COALESCE(ae.err_cnt, 0) AS recent_errors_24h
  FROM app_vault.master_key_versions mv
  LEFT JOIN (
    SELECT COALESCE(master_key_version, 1) AS v, COUNT(*) AS cnt
      FROM public.user_encryption_keys
     GROUP BY 1
  ) uk ON uk.v = mv.version
  LEFT JOIN (
    SELECT to_version AS v, COUNT(*) AS err_cnt
      FROM app_vault.rotation_audit
     WHERE outcome = 'error'
       AND rotated_at > now() - interval '24 hours'
     GROUP BY 1
  ) ae ON ae.v = mv.version
  ORDER BY mv.version;
$$;

REVOKE EXECUTE ON FUNCTION app_vault.rotation_status()
  FROM authenticated, anon, public;
GRANT EXECUTE ON FUNCTION app_vault.rotation_status() TO service_role;

CREATE OR REPLACE FUNCTION public.vault_rotation_status()
RETURNS TABLE(
  master_key_version INT,
  user_count         BIGINT,
  status             TEXT,
  recent_errors_24h  BIGINT
)
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public, app_vault, extensions, pg_temp
AS $$
  SELECT * FROM app_vault.rotation_status();
$$;

REVOKE EXECUTE ON FUNCTION public.vault_rotation_status()
  FROM authenticated, anon, public;
GRANT EXECUTE ON FUNCTION public.vault_rotation_status() TO service_role;
