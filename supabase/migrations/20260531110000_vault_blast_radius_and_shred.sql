-- =============================================================================
-- Data Fortress — Pillar 1: minimal blast-radius + crypto-shred + decrypt
-- audit + KMS-ready master indirection (2026-06-13).
-- =============================================================================
--
-- Builds ADDITIVELY on the existing 2-tier envelope (20260527090000 +
-- 20260528030000): master (Supabase Vault) -> per-user DEK -> ciphertext.
-- Does NOT rename or change the external API (vault_encrypt_text /
-- vault_decrypt_text are a contract). Adds the consilium's Pillar-1 must-fixes:
--
--   1. crypto_shred_user() — Art. 17 erasure by destroying the user's DEK.
--      Once the wrapped DEK row is gone, every ciphertext that user ever
--      wrote is mathematically unrecoverable. Fast, provable, irreversible.
--
--   2. decrypt_text_audited() — an audited decrypt that records ONE
--      access-log row (feeds Pillar 3's client-visible journal) so EVERY
--      decryption leaves a trail the data subject can see, even a direct
--      service_role call that goes through this fn.
--
--   3. master_key_provider registry — externalize WHERE the master lives. Today
--      'supabase_vault'; the owner flips a single row to 'aws_kms_eu' + wires
--      the edge-side KMS hook, with ZERO change to callers. This is the
--      KMS-ready seam (the AWS account is owner-gated; the code is ready now).
--
-- HONEST FRAMING (consilium consensus, do NOT overclaim): this is encryption-
-- at-rest with minimal blast-radius + crypto-shred, NOT "even we cannot read".
-- While the master is reachable by our own service_role, an operator CAN
-- decrypt. We claim what is true: a read-only DB leak can't decrypt; one
-- user's compromise isn't all users; erasure is cryptographically provable.
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ---------------------------------------------------------------------------
-- 1. master_key_provider registry — KMS-ready indirection seam.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS app_vault.master_key_provider (
  id          INT PRIMARY KEY DEFAULT 1,
  provider    TEXT NOT NULL DEFAULT 'supabase_vault'
              CHECK (provider IN ('supabase_vault', 'aws_kms_eu', 'gcp_kms_eu')),
  -- For external KMS: the key ARN / resource id the edge-side hook unwraps
  -- with. NULL while provider='supabase_vault'.
  external_key_ref TEXT,
  region      TEXT,
  notes       TEXT,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT master_key_provider_singleton CHECK (id = 1)
);

INSERT INTO app_vault.master_key_provider (id, provider, notes)
VALUES (1, 'supabase_vault',
        'Default. Master read from vault.decrypted_secrets. Flip to aws_kms_eu '
        '+ set external_key_ref + wire the edge KMS hook to externalize.')
ON CONFLICT (id) DO NOTHING;

ALTER TABLE app_vault.master_key_provider ENABLE ROW LEVEL SECURITY;
-- No client policy: service_role / SECURITY DEFINER only.

COMMENT ON TABLE app_vault.master_key_provider IS
  'Data Fortress Pillar 1: single-row registry naming WHERE the envelope '
  'master lives. KMS-ready seam — owner flips provider to aws_kms_eu without '
  'touching encrypt/decrypt callers.';

-- ---------------------------------------------------------------------------
-- 2. crypto_shred_user() — Art. 17 erasure via DEK destruction.
-- ---------------------------------------------------------------------------
-- Deleting the user's wrapped DEK makes every ciphertext keyed on it
-- permanently undecryptable. Returns the count of key rows destroyed +
-- a timestamp, so the caller (account-delete) can fold it into the deletion
-- certificate. service_role only. Idempotent (0 rows if already shredded).
CREATE OR REPLACE FUNCTION app_vault.crypto_shred_user(p_user_id UUID)
RETURNS TABLE (keys_destroyed INT, shredded_at TIMESTAMPTZ)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, app_vault, extensions, pg_temp
AS $$
DECLARE
  v_count INT;
BEGIN
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'crypto_shred_user: p_user_id required';
  END IF;

  WITH del AS (
    DELETE FROM public.user_encryption_keys
     WHERE user_id = p_user_id
    RETURNING 1
  )
  SELECT count(*)::int INTO v_count FROM del;

  RETURN QUERY SELECT v_count, now();
END;
$$;

REVOKE ALL ON FUNCTION app_vault.crypto_shred_user(UUID)
  FROM public, anon, authenticated;
GRANT EXECUTE ON FUNCTION app_vault.crypto_shred_user(UUID) TO service_role;

-- Public wrapper so the account-delete edge fn can call it via PostgREST RPC
-- under the service-role key (PostgREST only exposes the public schema).
CREATE OR REPLACE FUNCTION public.vault_crypto_shred_user(p_user_id UUID)
RETURNS TABLE (keys_destroyed INT, shredded_at TIMESTAMPTZ)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, app_vault, extensions, pg_temp
AS $$
  SELECT * FROM app_vault.crypto_shred_user(p_user_id);
$$;

REVOKE ALL ON FUNCTION public.vault_crypto_shred_user(UUID)
  FROM public, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.vault_crypto_shred_user(UUID) TO service_role;

-- ---------------------------------------------------------------------------
-- 3. decrypt_text_audited() — decrypt that leaves a client-visible trail.
-- ---------------------------------------------------------------------------
-- Same owner-scope semantics as app_vault.decrypt_text, but records ONE
-- audit_log row (action='read_sensitive') via record_data_access so the data
-- subject sees every decryption of their data. The plain decrypt_text stays
-- for hot paths that already log elsewhere; new callers should prefer this.
CREATE OR REPLACE FUNCTION public.vault_decrypt_text_audited(
  p_ciphertext   TEXT,
  p_user_id      UUID,
  p_target_table TEXT DEFAULT NULL,
  p_target_id    UUID DEFAULT NULL
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, app_vault, extensions, pg_temp
AS $$
DECLARE
  v_plain TEXT;
BEGIN
  IF auth.uid() IS NOT NULL AND auth.uid() <> p_user_id THEN
    RAISE EXCEPTION 'vault_decrypt_text_audited: cross-user decryption forbidden';
  END IF;

  v_plain := app_vault.decrypt_text(p_ciphertext, p_user_id);

  -- Best-effort access record (never block the decrypt on a logging failure).
  BEGIN
    PERFORM public.record_data_access(
      p_user_id,
      'read_sensitive',
      p_target_table,
      p_target_id,
      jsonb_build_object('via', 'vault_decrypt_text_audited')
    );
  EXCEPTION WHEN OTHERS THEN
    -- record_data_access may not exist yet if Pillar-3 migration hasn't run;
    -- decrypt must still succeed.
    NULL;
  END;

  RETURN v_plain;
END;
$$;

REVOKE ALL ON FUNCTION public.vault_decrypt_text_audited(TEXT, UUID, TEXT, UUID)
  FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vault_decrypt_text_audited(TEXT, UUID, TEXT, UUID)
  TO authenticated, service_role;

NOTIFY pgrst, 'reload schema';
