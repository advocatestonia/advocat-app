-- =============================================================================
-- 20260527090100_vault_tags.sql — Vault tagging + owner-scoped search RPC.
-- =============================================================================
-- Pairs with 20260527090000_vault_encryption.sql (encryption helpers) and
-- 20260527080200_drafts_vault_link.sql (the bridge that soft-adds is_system
-- + seeds a per-user "Draft" tag).
--
-- This file:
--   1. Creates vault_tags + vault_document_tags (the join).
--   2. Seeds 6 GLOBAL default tags (user_id IS NULL, is_system TRUE):
--      contract, receipt, email, evidence, id_passport, other. Labels are
--      English; the Flutter side i18n-maps by slug.
--   3. Defines vault_search_documents(query) — owner-scoped, decrypts
--      file_name server-side, joins primary tag. Returns the shape the UI
--      already calls (note: PUBLIC schema, underscore-named — PostgREST
--      does not expose vault.* RPCs to anon/auth clients).
--
-- Idempotent throughout. Safe to replay before or after the bridge.
-- =============================================================================

-- ─── 1. vault_tags ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.vault_tags (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID
               REFERENCES auth.users(id) ON DELETE CASCADE,
  slug       TEXT NOT NULL,
  label      TEXT NOT NULL,
  is_system  BOOLEAN NOT NULL DEFAULT FALSE,
  color      TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Bridge migration may have added is_system on a pre-existing vault_tags.
-- If that ran before this one, the column is already there — CREATE TABLE
-- IF NOT EXISTS skipped, and we should make sure all columns exist.
ALTER TABLE public.vault_tags
  ADD COLUMN IF NOT EXISTS is_system  BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS color      TEXT,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now();

-- UNIQUE(user_id, slug). Treats NULL user_id (globals) as distinct via
-- partial unique indexes — Postgres NULL-comparison would otherwise allow
-- duplicate global slugs.
CREATE UNIQUE INDEX IF NOT EXISTS vault_tags_user_slug_uniq
  ON public.vault_tags (user_id, slug)
  WHERE user_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS vault_tags_global_slug_uniq
  ON public.vault_tags (slug)
  WHERE user_id IS NULL;

CREATE INDEX IF NOT EXISTS vault_tags_user_idx
  ON public.vault_tags (user_id);

-- ─── 2. vault_document_tags (join) ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.vault_document_tags (
  document_id UUID NOT NULL
                REFERENCES public.documents(id) ON DELETE CASCADE,
  tag_id      UUID NOT NULL
                REFERENCES public.vault_tags(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (document_id, tag_id)
);

CREATE INDEX IF NOT EXISTS vault_document_tags_tag_idx
  ON public.vault_document_tags (tag_id);
CREATE INDEX IF NOT EXISTS vault_document_tags_doc_idx
  ON public.vault_document_tags (document_id);

-- ─── 3. RLS ─────────────────────────────────────────────────────────────────
ALTER TABLE public.vault_tags          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vault_document_tags ENABLE ROW LEVEL SECURITY;

-- vault_tags: read globals + own; write only own (non-system). System tags
-- and globals are managed by the migrations / SECURITY DEFINER triggers.
DROP POLICY IF EXISTS vault_tags_select_global_or_own ON public.vault_tags;
CREATE POLICY vault_tags_select_global_or_own
  ON public.vault_tags
  FOR SELECT
  USING (user_id IS NULL OR auth.uid() = user_id);

DROP POLICY IF EXISTS vault_tags_insert_own ON public.vault_tags;
CREATE POLICY vault_tags_insert_own
  ON public.vault_tags
  FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    -- Users may create their own tags (including the system "Draft" tag
    -- on-demand, as VaultService.ensureDraftSystemTag() does).
  );

DROP POLICY IF EXISTS vault_tags_update_own_non_system ON public.vault_tags;
CREATE POLICY vault_tags_update_own_non_system
  ON public.vault_tags
  FOR UPDATE
  USING (auth.uid() = user_id AND is_system = FALSE)
  WITH CHECK (auth.uid() = user_id AND is_system = FALSE);

DROP POLICY IF EXISTS vault_tags_delete_own_non_system ON public.vault_tags;
CREATE POLICY vault_tags_delete_own_non_system
  ON public.vault_tags
  FOR DELETE
  USING (auth.uid() = user_id AND is_system = FALSE);

-- vault_document_tags: only document owners can read/write.
DROP POLICY IF EXISTS vault_document_tags_select_own ON public.vault_document_tags;
CREATE POLICY vault_document_tags_select_own
  ON public.vault_document_tags
  FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.documents d
     WHERE d.id = vault_document_tags.document_id
       AND d.user_id = auth.uid()
  ));

DROP POLICY IF EXISTS vault_document_tags_insert_own ON public.vault_document_tags;
CREATE POLICY vault_document_tags_insert_own
  ON public.vault_document_tags
  FOR INSERT
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.documents d
     WHERE d.id = vault_document_tags.document_id
       AND d.user_id = auth.uid()
  ));

DROP POLICY IF EXISTS vault_document_tags_delete_own ON public.vault_document_tags;
CREATE POLICY vault_document_tags_delete_own
  ON public.vault_document_tags
  FOR DELETE
  USING (EXISTS (
    SELECT 1 FROM public.documents d
     WHERE d.id = vault_document_tags.document_id
       AND d.user_id = auth.uid()
  ));

-- ─── 4. Seed 6 global defaults ──────────────────────────────────────────────
INSERT INTO public.vault_tags (user_id, slug, label, is_system)
VALUES
  (NULL, 'contract',     'Contract',    TRUE),
  (NULL, 'receipt',      'Receipt',     TRUE),
  (NULL, 'email',        'Email',       TRUE),
  (NULL, 'evidence',     'Evidence',    TRUE),
  (NULL, 'id_passport',  'ID/Passport', TRUE),
  (NULL, 'other',        'Other',       TRUE)
ON CONFLICT DO NOTHING;

-- ─── 5. Grants ─────────────────────────────────────────────────────────────
GRANT SELECT ON public.vault_tags          TO authenticated;
GRANT INSERT, UPDATE, DELETE ON public.vault_tags          TO authenticated;
GRANT SELECT, INSERT, DELETE ON public.vault_document_tags TO authenticated;

-- ─── 6. Search RPC ─────────────────────────────────────────────────────────
-- Named vault_search_documents (in PUBLIC) because:
--   1. PostgREST does not auto-expose schemas outside public/graphql.
--   2. The Vault UI agent already wired client.rpc('vault_search_documents').
--
-- Performance trade-off (documented):
--   Encrypted file_name means we cannot index for ILIKE — every filtered
--   row gets decrypted in-memory. Acceptable for <1000 docs/user. When a
--   user crosses that bar we'll add a per-user encrypted-search index
--   (e.g. blind-indexed bigrams). Until then we hard-LIMIT 100.
DROP FUNCTION IF EXISTS public.vault_search_documents(TEXT);
CREATE OR REPLACE FUNCTION public.vault_search_documents(query TEXT)
RETURNS TABLE (
  id              UUID,
  file_name       TEXT,
  storage_path    TEXT,
  mime_type       TEXT,
  file_size_bytes INTEGER,
  created_at      TIMESTAMPTZ,
  case_id         UUID,
  tag_id          UUID,
  tag_slug        TEXT,
  tag_label       TEXT,
  encrypted       BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, vault, pg_temp
STABLE
AS $$
DECLARE
  v_uid     UUID := auth.uid();
  v_needle  TEXT;
BEGIN
  IF v_uid IS NULL THEN
    -- No anon access — return empty.
    RETURN;
  END IF;

  v_needle := COALESCE(NULLIF(trim(query), ''), '');

  RETURN QUERY
  WITH base AS (
    SELECT
      d.id,
      -- Decrypt at read time if encrypted; else fall back to plain. UI is
      -- tolerant of either via vault_document.dart.
      COALESCE(
        vault.decrypt_text(d.encrypted_file_name, d.user_id),
        d.file_name
      ) AS file_name_plain,
      COALESCE(
        vault.decrypt_text(d.encrypted_storage_path, d.user_id),
        d.storage_path
      ) AS storage_path_plain,
      d.mime_type,
      d.file_size_bytes,
      d.created_at,
      d.case_id,
      (d.encrypted_file_name IS NOT NULL) AS is_encrypted
    FROM public.documents d
    WHERE d.user_id = v_uid
  ),
  filtered AS (
    SELECT * FROM base
     WHERE v_needle = ''
        OR file_name_plain ILIKE '%' || v_needle || '%'
  ),
  -- Pick ONE tag per doc (lowest tag.created_at — stable, deterministic).
  primary_tag AS (
    SELECT DISTINCT ON (vdt.document_id)
      vdt.document_id,
      t.id        AS tag_id,
      t.slug      AS tag_slug,
      t.label     AS tag_label
    FROM public.vault_document_tags vdt
    JOIN public.vault_tags          t   ON t.id = vdt.tag_id
    ORDER BY vdt.document_id, t.created_at ASC, t.id ASC
  )
  SELECT
    f.id,
    f.file_name_plain,
    f.storage_path_plain,
    f.mime_type,
    f.file_size_bytes,
    f.created_at,
    f.case_id,
    pt.tag_id,
    pt.tag_slug,
    pt.tag_label,
    f.is_encrypted
  FROM filtered f
  LEFT JOIN primary_tag pt ON pt.document_id = f.id
  ORDER BY f.created_at DESC NULLS LAST
  LIMIT 100;
END;
$$;

GRANT EXECUTE ON FUNCTION public.vault_search_documents(TEXT) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.vault_search_documents(TEXT) FROM anon, public;

COMMENT ON FUNCTION public.vault_search_documents(TEXT) IS
  'Owner-scoped vault search. Decrypts file_name in-memory before ILIKE — '
  'O(n) per call. LIMIT 100. Replace with blind-indexed search above 1000 '
  'docs/user.';

-- 6.1 Schema-qualified alias for direct DB callers (e.g. psql, BI tools).
--     PostgREST clients should keep using public.vault_search_documents.
CREATE OR REPLACE FUNCTION vault.search_documents(query TEXT)
RETURNS TABLE (
  id              UUID,
  file_name       TEXT,
  storage_path    TEXT,
  mime_type       TEXT,
  file_size_bytes INTEGER,
  created_at      TIMESTAMPTZ,
  case_id         UUID,
  tag_id          UUID,
  tag_slug        TEXT,
  tag_label       TEXT,
  encrypted       BOOLEAN
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, vault, pg_temp
STABLE
AS $$
  SELECT * FROM public.vault_search_documents(query);
$$;

GRANT EXECUTE ON FUNCTION vault.search_documents(TEXT) TO authenticated, service_role;
