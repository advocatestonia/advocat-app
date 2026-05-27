-- =============================================================================
-- 20260527090000_vault_encryption.sql — Vault encryption-at-rest helpers.
-- =============================================================================
-- Ordering note: timestamp sorts AFTER 20260527080200_drafts_vault_link.sql
-- (the bridge migration that soft-adds vault_tags.is_system + seeds "Draft").
-- However EVERY statement here is wrapped in IF EXISTS / IF NOT EXISTS /
-- DO-block guards so re-ordering does not break replay. The next migration
-- (20260527090100_vault_tags.sql) creates the vault_tags table itself; the
-- bridge file gates on its existence so the deploy order is:
--
--   20260527080200_drafts_vault_link.sql   (bridge — no-ops if vault_tags absent)
--   20260527090000_vault_encryption.sql    (this — adds encryption columns + helpers)
--   20260527090100_vault_tags.sql          (tag tables + search RPC)
--   ... bridge replays cleanly once vault_tags exists.
--
-- =============================================================================
-- ENCRYPTION MODEL
-- -----------------------------------------------------------------------------
-- Three-tier envelope encryption:
--
--   1. MASTER KEY (server-side, never in DB)
--      Lives in `current_setting('app.vault_master_key', true)`. Set once per
--      cluster with:
--
--        ALTER DATABASE postgres SET app.vault_master_key = '<base64-32-bytes>';
--
--      Rotation: provision a new key, re-wrap every row in
--      user_encryption_keys, then flip the setting. NOT in scope for this MR.
--
--   2. USER KEY (per-user, stored encrypted)
--      Random 32-byte key generated lazily on first encrypt. Stored in
--      user_encryption_keys.encrypted_key, itself wrapped with the master via
--      pgp_sym_encrypt(). User rows can be exported / migrated without
--      exposing the master.
--
--   3. CIPHERTEXT (per-row)
--      Each encrypted column holds an ASCII-armored pgp_sym_encrypt output
--      keyed on the unwrapped user key. file_name and storage_path are the
--      only encrypted PII at the documents level — file bytes themselves are
--      not yet encrypted; that's bucket-level + RLS.
--
-- Threat model: a read-only DB leak (pg_dump, replica snapshot) cannot
-- decrypt any user data without the master key, which lives only in
-- GUC settings. A full server compromise still loses everything — this
-- is encryption-at-rest, not end-to-end.
-- =============================================================================

-- ─── 0. Prereqs ─────────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE SCHEMA IF NOT EXISTS vault;

-- ─── 1. documents — additive nullable columns ──────────────────────────────
-- Old rows keep plain file_name/storage_path. New rows (via vault-upload
-- edge fn) populate the encrypted_* columns AND set encryption_key_id. UI
-- reads plain when encrypted_file_name IS NULL, else calls decrypt path.
ALTER TABLE public.documents
  ADD COLUMN IF NOT EXISTS encrypted_file_name    TEXT,
  ADD COLUMN IF NOT EXISTS encrypted_storage_path TEXT,
  ADD COLUMN IF NOT EXISTS encryption_key_id      UUID;

-- CHECK: either plain set OR encrypted set. Both is permitted (during
-- backfill / dual-write windows). Forbidden state is "all four nullish".
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
     WHERE conrelid = 'public.documents'::regclass
       AND conname  = 'documents_filename_or_encrypted_chk'
  ) THEN
    ALTER TABLE public.documents
      ADD CONSTRAINT documents_filename_or_encrypted_chk
      CHECK (
        (file_name IS NOT NULL AND storage_path IS NOT NULL)
        OR (encrypted_file_name IS NOT NULL AND encrypted_storage_path IS NOT NULL)
      );
  END IF;
END $$;

COMMENT ON COLUMN public.documents.encrypted_file_name IS
  'pgp_sym_encrypt(file_name, user_key) ASCII-armored. NULL for legacy rows; '
  'when set, file_name should be a sentinel like "[encrypted]".';
COMMENT ON COLUMN public.documents.encrypted_storage_path IS
  'pgp_sym_encrypt(storage_path, user_key) ASCII-armored.';
COMMENT ON COLUMN public.documents.encryption_key_id IS
  'FK → user_encryption_keys.id. Tracks which key version wrapped this row, '
  'for rotation.';

-- Performance: vault list (owner + newest first). Note: schema uses
-- created_at, not uploaded_at — spec mentioned uploaded_at but the actual
-- column is created_at (see 001_complete_schema.sql).
CREATE INDEX IF NOT EXISTS documents_user_created_idx
  ON public.documents (user_id, created_at DESC);

-- ─── 2. user_encryption_keys ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_encryption_keys (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL UNIQUE
                  REFERENCES auth.users(id) ON DELETE CASCADE,
  encrypted_key BYTEA NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  rotated_at    TIMESTAMPTZ
);

COMMENT ON TABLE public.user_encryption_keys IS
  'Per-user data-encryption keys, wrapped with the cluster master key. '
  'Rows are never read by application code directly — only by the '
  'SECURITY DEFINER helpers in the vault schema.';

ALTER TABLE public.user_encryption_keys ENABLE ROW LEVEL SECURITY;

-- Owner can see its row exists (id only) — but the encrypted_key bytes are
-- gated by column privileges below. SELECT policy is intentionally narrow.
DROP POLICY IF EXISTS user_encryption_keys_select_own
  ON public.user_encryption_keys;
CREATE POLICY user_encryption_keys_select_own
  ON public.user_encryption_keys
  FOR SELECT
  USING (auth.uid() = user_id);

-- No INSERT / UPDATE / DELETE policies for authenticated users — all writes
-- must go through vault.get_or_create_user_key() (SECURITY DEFINER).
-- Service role bypasses RLS, so the edge fn can still operate.

REVOKE INSERT, UPDATE, DELETE ON public.user_encryption_keys FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.user_encryption_keys FROM anon;

-- ─── 3. Helpers ────────────────────────────────────────────────────────────

-- 3a. Resolve master key from GUC. Raises if not set.
CREATE OR REPLACE FUNCTION vault.master_key()
RETURNS TEXT
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  k TEXT;
BEGIN
  k := current_setting('app.vault_master_key', true);
  IF k IS NULL OR length(k) = 0 THEN
    RAISE EXCEPTION 'vault: app.vault_master_key is not set. '
                    'Run: ALTER DATABASE postgres SET app.vault_master_key = ''<base64-32-bytes>'';';
  END IF;
  RETURN k;
END;
$$;

-- 3b. Get-or-create the user's wrapped DEK. Returns the key id.
CREATE OR REPLACE FUNCTION vault.get_or_create_user_key(p_user_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, vault, pg_temp
AS $$
DECLARE
  v_id   UUID;
  v_dek  BYTEA;
BEGIN
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'vault.get_or_create_user_key: p_user_id required';
  END IF;

  SELECT id INTO v_id
    FROM public.user_encryption_keys
   WHERE user_id = p_user_id;

  IF v_id IS NOT NULL THEN
    RETURN v_id;
  END IF;

  -- Generate fresh 32-byte DEK, wrap with master, insert. We use
  -- ON CONFLICT DO NOTHING + a follow-up SELECT so a race between two
  -- parallel callers does not silently replace the existing wrapped key
  -- (that would invalidate every prior ciphertext for the user).
  v_dek := gen_random_bytes(32);
  INSERT INTO public.user_encryption_keys (user_id, encrypted_key)
  VALUES (
    p_user_id,
    pgp_sym_encrypt(encode(v_dek, 'base64'), vault.master_key())::bytea
  )
  ON CONFLICT (user_id) DO NOTHING
  RETURNING id INTO v_id;

  -- If insert lost the race, fetch the winner's row.
  IF v_id IS NULL THEN
    SELECT id INTO v_id
      FROM public.user_encryption_keys
     WHERE user_id = p_user_id;
  END IF;

  RETURN v_id;
END;
$$;

-- 3c. Unwrap the user's DEK. Internal helper — never grant to authenticated.
CREATE OR REPLACE FUNCTION vault._unwrap_user_key(p_user_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, vault, pg_temp
AS $$
DECLARE
  v_wrapped BYTEA;
BEGIN
  SELECT encrypted_key INTO v_wrapped
    FROM public.user_encryption_keys
   WHERE user_id = p_user_id;
  IF v_wrapped IS NULL THEN
    RAISE EXCEPTION 'vault: no encryption key for user %', p_user_id;
  END IF;
  RETURN pgp_sym_decrypt(v_wrapped, vault.master_key());
END;
$$;

-- 3d. Public encrypt — owner-scoped.
CREATE OR REPLACE FUNCTION vault.encrypt_text(
  plaintext TEXT,
  p_user_id UUID
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, vault, pg_temp
AS $$
DECLARE
  v_key TEXT;
BEGIN
  IF plaintext IS NULL THEN
    RETURN NULL;
  END IF;
  -- Owner guard: callers (via JWT) may only encrypt under their own key.
  -- Service role (no auth.uid()) is allowed for edge-fn writes.
  IF auth.uid() IS NOT NULL AND auth.uid() <> p_user_id THEN
    RAISE EXCEPTION 'vault.encrypt_text: cross-user encryption forbidden';
  END IF;
  PERFORM vault.get_or_create_user_key(p_user_id);
  v_key := vault._unwrap_user_key(p_user_id);
  RETURN pgp_sym_encrypt(plaintext, v_key);
END;
$$;

-- 3e. Public decrypt — owner-scoped.
CREATE OR REPLACE FUNCTION vault.decrypt_text(
  ciphertext TEXT,
  p_user_id UUID
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, vault, pg_temp
AS $$
DECLARE
  v_key TEXT;
BEGIN
  IF ciphertext IS NULL OR length(ciphertext) = 0 THEN
    RETURN NULL;
  END IF;
  IF auth.uid() IS NOT NULL AND auth.uid() <> p_user_id THEN
    RAISE EXCEPTION 'vault.decrypt_text: cross-user decryption forbidden';
  END IF;
  v_key := vault._unwrap_user_key(p_user_id);
  RETURN pgp_sym_decrypt(ciphertext::bytea, v_key);
EXCEPTION
  WHEN OTHERS THEN
    -- Bad ciphertext / wrong key → return NULL rather than leaking the
    -- pgcrypto error message to the caller.
    RETURN NULL;
END;
$$;

-- ─── 4. Public-schema wrappers (PostgREST-callable) ────────────────────────
-- PostgREST only exposes `public` (and `graphql`) by default. Edge fns +
-- the Flutter client can both call these wrappers; the wrappers delegate
-- to vault.* helpers which enforce owner-scope.
CREATE OR REPLACE FUNCTION public.vault_encrypt_text(
  p_plaintext TEXT,
  p_user_id   UUID
)
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, vault, pg_temp
AS $$
  SELECT vault.encrypt_text(p_plaintext, p_user_id);
$$;

CREATE OR REPLACE FUNCTION public.vault_decrypt_text(
  p_ciphertext TEXT,
  p_user_id    UUID
)
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, vault, pg_temp
AS $$
  SELECT vault.decrypt_text(p_ciphertext, p_user_id);
$$;

-- ─── 5. Grants ──────────────────────────────────────────────────────────────
GRANT USAGE ON SCHEMA vault TO authenticated, service_role;

-- Authenticated users can call encrypt/decrypt (the fn itself enforces
-- owner-scope via auth.uid() check). They MUST NOT see internal helpers.
GRANT EXECUTE ON FUNCTION vault.encrypt_text(TEXT, UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION vault.decrypt_text(TEXT, UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION vault.get_or_create_user_key(UUID) TO service_role;
REVOKE EXECUTE ON FUNCTION vault.get_or_create_user_key(UUID) FROM authenticated, anon, public;
REVOKE EXECUTE ON FUNCTION vault._unwrap_user_key(UUID) FROM authenticated, anon, public;
REVOKE EXECUTE ON FUNCTION vault.master_key() FROM authenticated, anon, public;

GRANT EXECUTE ON FUNCTION public.vault_encrypt_text(TEXT, UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.vault_decrypt_text(TEXT, UUID) TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.vault_encrypt_text(TEXT, UUID) FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.vault_decrypt_text(TEXT, UUID) FROM anon, public;

-- ─── 6. case_id cleanup ────────────────────────────────────────────────────
-- The vault upload path historically wrote sentinel strings like
-- "vault-1715760000" into documents.case_id because the FK was strict but
-- vault docs have no case. Step 1: relax NOT NULL. Step 2: null out the
-- sentinels. Step 3: ensure FK still points at cases(id) with ON DELETE
-- SET NULL (was ON DELETE CASCADE in 001_complete_schema).
DO $$
DECLARE
  v_fk_name TEXT;
BEGIN
  -- 6.1 Relax NOT NULL (idempotent — IS_NULLABLE check)
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
     WHERE table_schema = 'public'
       AND table_name   = 'documents'
       AND column_name  = 'case_id'
       AND is_nullable  = 'NO'
  ) THEN
    EXECUTE 'ALTER TABLE public.documents ALTER COLUMN case_id DROP NOT NULL';
  END IF;

  -- 6.2 Wipe sentinel "vault-*" strings. case_id is uuid in schema, but
  --     deploys-before-cleanup may have widened it; cast guards both.
  EXECUTE $sql$
    UPDATE public.documents
       SET case_id = NULL
     WHERE case_id::text LIKE 'vault-%'
  $sql$;

  -- 6.3 Re-point FK to ON DELETE SET NULL (was CASCADE). Only if
  --     cases table exists and current FK is CASCADE.
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
     WHERE table_schema = 'public' AND table_name = 'cases'
  ) THEN
    SELECT conname INTO v_fk_name
      FROM pg_constraint
     WHERE conrelid = 'public.documents'::regclass
       AND contype  = 'f'
       AND conkey   = ARRAY[
             (SELECT attnum FROM pg_attribute
               WHERE attrelid = 'public.documents'::regclass
                 AND attname  = 'case_id')
           ]::smallint[];
    IF v_fk_name IS NOT NULL THEN
      EXECUTE format('ALTER TABLE public.documents DROP CONSTRAINT %I', v_fk_name);
    END IF;
    -- Re-add with SET NULL.
    EXECUTE 'ALTER TABLE public.documents
             ADD CONSTRAINT documents_case_id_fkey
             FOREIGN KEY (case_id) REFERENCES public.cases(id)
             ON DELETE SET NULL';
  END IF;
END $$;

COMMENT ON COLUMN public.documents.case_id IS
  'NULL = vault-only document (not pinned to a case). Was previously '
  'populated with sentinel "vault-<ts>" strings — cleaned up '
  '2026-05-27 in 20260527090000_vault_encryption.sql.';
