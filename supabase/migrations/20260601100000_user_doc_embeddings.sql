-- 20260601100000_user_doc_embeddings.sql
-- =============================================================================
-- Feature #4 — Semantic Search over the user's OWN documents
-- (Vault / case-document content search).
--
-- Problem:
--   Users (and B2B firms with hundreds of files) accumulate dozens of
--   documents in their vault and cases. Finding "where the deposit was
--   mentioned" or "the termination clause" is impossible today — there is
--   only filename search, not content search.
--
-- Design:
--   A DEDICATED chunk table `public.user_doc_chunks`, completely separate from
--   the law corpus (law_chunks_v2 / case_chunks). This isolation is the core
--   security property: a tenant's private document text can NEVER leak into
--   the shared legal corpus, and a vector search over user_doc_chunks can
--   ONLY ever return the caller's own (or their org's) chunks.
--
--   Reuses the existing embedding infra: text-embedding-3-small, 1536-dim,
--   pgvector cosine, ivfflat — identical to law_search_v2 so we share the
--   same OpenAI model and the same proven index shape.
--
-- Ownership model (mirrors case_documents / vault `documents`):
--   * Every chunk carries user_id (the uploader/owner) — always set.
--   * org_id is OPTIONAL. When set, every active member of that org can search
--     the chunk (B2B shared-firm search). When NULL, only user_id sees it.
--
-- RLS:
--   * Direct table access (authenticated role) is locked to own user_id OR a
--     row whose org_id is one of the caller's active org memberships.
--   * The match RPC is SECURITY DEFINER but re-applies the SAME owner/org
--     filter internally using auth.uid(), so a definer-bypass cannot leak
--     cross-tenant rows. Defence in depth: even if the table RLS were dropped,
--     the RPC still filters.
--
-- Cost discipline:
--   Embedding cost grows with corpus size, so doc-indexer indexes ON DEMAND
--   (per document), not a blanket backfill. text-embedding-3-small is
--   $0.02 / 1M tokens — a 50-page document (~30K tokens) ≈ $0.0006.
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS vector;

-- ── 1. user_doc_chunks ──────────────────────────────────────────────────────
-- One row per (document, chunk). source_kind + source_id point back to the
-- originating record so the UI can deep-link to the document. We deliberately
-- do NOT add an FK to case_documents/documents: a doc may come from either
-- table (or future sources), and an FK to a polymorphic parent is impossible.
-- Cleanup of orphaned chunks is handled by doc-indexer re-index (delete-then-
-- insert per document) and by the account-delete cascade on user_id.
CREATE TABLE IF NOT EXISTS public.user_doc_chunks (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  org_id        UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
  -- 'case_document' = public.case_documents, 'vault_document' = public.documents
  source_kind   TEXT NOT NULL CHECK (source_kind IN ('case_document', 'vault_document')),
  source_id     UUID NOT NULL,
  -- Denormalised so search results render without a second round-trip.
  doc_title     TEXT,
  chunk_index   INT  NOT NULL DEFAULT 0,
  text          TEXT NOT NULL,
  char_start    INT,
  char_end      INT,
  embedding     VECTOR(1536),
  indexed_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- One chunk position per source document; re-index overwrites cleanly via
-- ON CONFLICT. (source_kind, source_id, chunk_index) is the natural key.
CREATE UNIQUE INDEX IF NOT EXISTS user_doc_chunks_source_chunk_uniq
  ON public.user_doc_chunks (source_kind, source_id, chunk_index);

-- Owner / org lookups (the RLS predicate columns).
CREATE INDEX IF NOT EXISTS user_doc_chunks_user_idx
  ON public.user_doc_chunks (user_id);
CREATE INDEX IF NOT EXISTS user_doc_chunks_org_idx
  ON public.user_doc_chunks (org_id) WHERE org_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS user_doc_chunks_source_idx
  ON public.user_doc_chunks (source_kind, source_id);

-- ivfflat cosine, lists=50. Per-tenant corpora are small (dozens–hundreds of
-- docs), same rationale as case_documents (lists ≈ sqrt(rows)).
CREATE INDEX IF NOT EXISTS user_doc_chunks_embedding_idx
  ON public.user_doc_chunks
  USING ivfflat (embedding vector_cosine_ops) WITH (lists = 50);

-- ── 2. RLS ──────────────────────────────────────────────────────────────────
ALTER TABLE public.user_doc_chunks ENABLE ROW LEVEL SECURITY;

-- Caller owns the row OR the row is shared with an org the caller is an active
-- member of. org_members.removed_at IS NULL gates out departed members.
DROP POLICY IF EXISTS user_doc_chunks_select_own_or_org ON public.user_doc_chunks;
CREATE POLICY user_doc_chunks_select_own_or_org
  ON public.user_doc_chunks
  FOR SELECT
  USING (
    auth.uid() = user_id
    OR (
      org_id IS NOT NULL
      AND EXISTS (
        SELECT 1 FROM public.org_members m
        WHERE m.org_id = user_doc_chunks.org_id
          AND m.user_id = auth.uid()
          AND m.removed_at IS NULL
      )
    )
  );

-- Writes are service-role only (doc-indexer runs with the service key). With
-- RLS enabled and no permissive write policy, authenticated INSERT/UPDATE/
-- DELETE are denied by default → clients can never forge an org_id row.

-- Lock table privileges: authenticated may only SELECT (further narrowed by
-- the RLS policy above). service_role bypasses RLS and does the writes.
REVOKE ALL ON public.user_doc_chunks FROM authenticated, anon;
GRANT SELECT ON public.user_doc_chunks TO authenticated;
GRANT ALL ON public.user_doc_chunks TO service_role;

-- ── 3. match RPC ─────────────────────────────────────────────────────────────
-- SECURITY DEFINER so it can run an efficient ivfflat ORDER BY, but it
-- RE-APPLIES the owner/org filter with auth.uid() so the definer rights cannot
-- leak cross-tenant rows. p_org_id, when provided, scopes results to a single
-- org the caller belongs to (B2B "search this firm's files"); when NULL the
-- caller's personal + all-their-org chunks are searched.
CREATE OR REPLACE FUNCTION public.match_user_doc_chunks(
  query_embedding VECTOR(1536),
  match_count     INT   DEFAULT 8,
  match_threshold FLOAT DEFAULT 0.20,
  p_org_id        UUID  DEFAULT NULL,
  p_source_kind   TEXT  DEFAULT NULL,
  p_source_id     UUID  DEFAULT NULL
)
RETURNS TABLE (
  id          UUID,
  source_kind TEXT,
  source_id   UUID,
  doc_title   TEXT,
  chunk_index INT,
  text        TEXT,
  char_start  INT,
  char_end    INT,
  similarity  FLOAT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  uid UUID := auth.uid();
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;

  RETURN QUERY
  SELECT
    c.id,
    c.source_kind,
    c.source_id,
    c.doc_title,
    c.chunk_index,
    c.text,
    c.char_start,
    c.char_end,
    (1 - (c.embedding <=> query_embedding))::FLOAT AS similarity
  FROM public.user_doc_chunks c
  WHERE c.embedding IS NOT NULL
    -- OWNERSHIP GATE — identical to the RLS policy, enforced inside the
    -- definer so it holds regardless of table-level RLS state.
    AND (
      c.user_id = uid
      OR (
        c.org_id IS NOT NULL
        AND EXISTS (
          SELECT 1 FROM public.org_members m
          WHERE m.org_id = c.org_id
            AND m.user_id = uid
            AND m.removed_at IS NULL
        )
      )
    )
    -- Optional narrowing filters.
    AND (p_org_id      IS NULL OR c.org_id      = p_org_id)
    AND (p_source_kind IS NULL OR c.source_kind = p_source_kind)
    AND (p_source_id   IS NULL OR c.source_id   = p_source_id)
    AND (1 - (c.embedding <=> query_embedding)) > match_threshold
  ORDER BY c.embedding <=> query_embedding ASC
  LIMIT GREATEST(1, LEAST(match_count, 50));
END;
$$;

-- anon must never call this. authenticated + service_role only.
REVOKE ALL ON FUNCTION
  public.match_user_doc_chunks(VECTOR(1536), INT, FLOAT, UUID, TEXT, UUID)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION
  public.match_user_doc_chunks(VECTOR(1536), INT, FLOAT, UUID, TEXT, UUID)
  TO authenticated, service_role;

COMMENT ON TABLE public.user_doc_chunks IS
  'Per-chunk embeddings of a user''s/org''s OWN documents for semantic content '
  'search. Strictly isolated from the shared law corpus. RLS: own user_id or '
  'active org membership. Indexed on demand by the doc-indexer edge function.';
