-- =====================================================================
-- Hybrid search (BM25 + dense) for law_chunks_v2 / case_chunks / travaux
-- =====================================================================
-- A1 of vabank roadmap (2026-05-15).
--
-- Problem: pgvector ivfflat works only on dense embeddings. Finnish/Estonian
-- queries are terminology-heavy ("menetetyn määräajan palauttaminen",
-- "asianomistaja", "OHO §114"). Dense embeddings smear those rare-token
-- signals. BM25 over PostgreSQL tsvector recovers exact-term recall.
--
-- Approach: Reciprocal Rank Fusion (RRF) of two retrievers.
--   1. dense:    cosine over law_chunks_v2.embedding  (existing law_search_v2)
--   2. bm25:     ts_rank_cd over chunk_tsv            (new, this migration)
--   merge:       score = sum_i 1 / (k + rank_i)  with k = 60
--
-- Generated-column constraint: PG STORED generated columns require an
-- IMMUTABLE expression. `to_tsvector(regconfig, text)` is IMMUTABLE only
-- when the regconfig is a literal constant — so we cannot branch on the
-- `lang` column inside the generation expression. We index using the
-- `simple` config (no stemming, lemma = exact word form) which is the
-- right default for §-lookups where the win is rare terminology overlap,
-- not query expansion. At search time `websearch_to_tsquery('simple', q)`
-- matches exact forms — sufficient for "§114", "asianomistaja",
-- "menetetyn määräajan palauttaminen" etc. A future per-lang stemmer pass
-- can be added via triggers if recall plateaus.
--
-- Target: recall@3 50% → 70% on golden_corpus_queries.jsonl.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. law_chunks_v2 — tsvector + GIN index
-- ---------------------------------------------------------------------
ALTER TABLE public.law_chunks_v2
  ADD COLUMN IF NOT EXISTS chunk_tsv tsvector
  GENERATED ALWAYS AS (
    setweight(
      to_tsvector(
        'simple'::regconfig,
        coalesce(act_slug, '') || ' ' ||
        coalesce(section, '') || ' ' ||
        coalesce(section_label, '')
      ),
      'A'
    ) ||
    setweight(
      to_tsvector('simple'::regconfig, coalesce(text, '')),
      'B'
    )
  ) STORED;

CREATE INDEX IF NOT EXISTS law_chunks_v2_tsv_idx
  ON public.law_chunks_v2 USING gin (chunk_tsv);

-- ---------------------------------------------------------------------
-- 2. case_chunks — tsvector + GIN index
-- ---------------------------------------------------------------------
ALTER TABLE public.case_chunks
  ADD COLUMN IF NOT EXISTS chunk_tsv tsvector
  GENERATED ALWAYS AS (
    setweight(
      to_tsvector(
        'simple'::regconfig,
        coalesce(case_number, '') || ' ' ||
        coalesce(paragraph_no, '') || ' ' ||
        coalesce(parties_redacted, '')
      ),
      'A'
    ) ||
    setweight(
      to_tsvector('simple'::regconfig, coalesce(text, '')),
      'B'
    )
  ) STORED;

CREATE INDEX IF NOT EXISTS case_chunks_tsv_idx
  ON public.case_chunks USING gin (chunk_tsv);

-- ---------------------------------------------------------------------
-- 3. travaux — tsvector + GIN index
-- ---------------------------------------------------------------------
ALTER TABLE public.travaux
  ADD COLUMN IF NOT EXISTS chunk_tsv tsvector
  GENERATED ALWAYS AS (
    setweight(
      to_tsvector(
        'simple'::regconfig,
        coalesce(doc_number, '') || ' ' ||
        coalesce(section_ref, '') || ' ' ||
        coalesce(related_act_slug, '') || ' ' ||
        coalesce(title, '')
      ),
      'A'
    ) ||
    setweight(
      to_tsvector('simple'::regconfig, coalesce(text, '')),
      'B'
    )
  ) STORED;

CREATE INDEX IF NOT EXISTS travaux_tsv_idx
  ON public.travaux USING gin (chunk_tsv);

-- =====================================================================
-- 4. law_search_hybrid — Reciprocal Rank Fusion over law_chunks_v2
-- =====================================================================
-- Returns rows ordered by RRF score. RRF is parameter-light (one constant
-- k=60, standard from Cormack et al. 2009) and robust to score scaling
-- mismatches between cosine and BM25.
--
-- Contract mirrors law_search_v2 output columns (id, act_slug,
-- section_label, text, similarity, source_url) so callers can swap RPCs
-- with zero adapter changes. Three extra columns are appended:
--   bm25_rank   — ts_rank_cd raw score (0 when no BM25 hit)
--   rrf_score   — sum of fused reciprocal ranks (0 < x ≤ 2/(k+1))
--   source_type — 'dense' | 'bm25' | 'both'  (debug / instrumentation)
--
-- IMPORTANT: BM25 candidate pool is capped at 50 to prevent slow scans on
-- very common query terms (e.g. "laki", "the"). Dense pool likewise capped
-- at 50. Final LIMIT applied after merge.
-- =====================================================================

CREATE OR REPLACE FUNCTION public.law_search_hybrid(
  p_query_embedding VECTOR(1536),
  p_query_text TEXT,
  p_jurisdiction TEXT DEFAULT NULL,
  p_lang TEXT DEFAULT NULL,
  p_act_slug TEXT DEFAULT NULL,
  p_valid_at TIMESTAMPTZ DEFAULT NULL,
  p_match_threshold FLOAT DEFAULT 0.40,
  p_limit INT DEFAULT 10
) RETURNS TABLE (
  id UUID,
  act_slug TEXT,
  section_label TEXT,
  text TEXT,
  similarity FLOAT,
  source_url TEXT,
  bm25_rank FLOAT,
  rrf_score FLOAT,
  source_type TEXT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  k CONSTANT INT := 60;       -- RRF constant (Cormack 2009)
  pool_size CONSTANT INT := 50;
  tsq tsquery;
BEGIN
  -- Bump ivfflat.probes to 25 (matches law_search_v2 fix). Transaction-
  -- local so the GUC never leaks between pooler connections.
  PERFORM set_config('ivfflat.probes', '25', true);

  -- Build the BM25 query. websearch_to_tsquery handles user-style input
  -- (quoted phrases, OR, -negation). Returns NULL on empty/whitespace
  -- input — guard so the bm25 CTE simply matches nothing in that case.
  IF p_query_text IS NULL OR length(btrim(p_query_text)) = 0 THEN
    tsq := NULL;
  ELSE
    BEGIN
      tsq := websearch_to_tsquery('simple'::regconfig, p_query_text);
    EXCEPTION WHEN OTHERS THEN
      -- Pathological input (control chars etc.) — degrade to dense-only.
      tsq := NULL;
    END;
  END IF;

  RETURN QUERY
  WITH dense AS (
    SELECT
      c.id,
      c.act_slug,
      c.section_label,
      c.text,
      c.source_url,
      (1 - (c.embedding <=> p_query_embedding))::FLOAT AS sim,
      ROW_NUMBER() OVER (ORDER BY c.embedding <=> p_query_embedding ASC) AS rnk
    FROM public.law_chunks_v2 c
    WHERE c.embedding IS NOT NULL
      AND (p_jurisdiction IS NULL OR c.jurisdiction = p_jurisdiction)
      AND (p_lang IS NULL OR c.lang = p_lang)
      AND (p_act_slug IS NULL OR c.act_slug = p_act_slug)
      AND (p_valid_at IS NULL OR (
        c.redaktsioon_valid_from <= p_valid_at
        AND (c.redaktsioon_valid_to IS NULL OR c.redaktsioon_valid_to > p_valid_at)
      ))
      AND (1 - (c.embedding <=> p_query_embedding)) > p_match_threshold
    ORDER BY c.embedding <=> p_query_embedding ASC
    LIMIT pool_size
  ),
  bm25 AS (
    SELECT
      c.id,
      c.act_slug,
      c.section_label,
      c.text,
      c.source_url,
      ts_rank_cd(c.chunk_tsv, tsq)::FLOAT AS rank,
      ROW_NUMBER() OVER (ORDER BY ts_rank_cd(c.chunk_tsv, tsq) DESC) AS rnk
    FROM public.law_chunks_v2 c
    WHERE tsq IS NOT NULL
      AND c.chunk_tsv @@ tsq
      AND (p_jurisdiction IS NULL OR c.jurisdiction = p_jurisdiction)
      AND (p_lang IS NULL OR c.lang = p_lang)
      AND (p_act_slug IS NULL OR c.act_slug = p_act_slug)
      AND (p_valid_at IS NULL OR (
        c.redaktsioon_valid_from <= p_valid_at
        AND (c.redaktsioon_valid_to IS NULL OR c.redaktsioon_valid_to > p_valid_at)
      ))
    ORDER BY ts_rank_cd(c.chunk_tsv, tsq) DESC
    LIMIT pool_size
  ),
  merged AS (
    SELECT
      COALESCE(d.id, b.id)            AS id,
      COALESCE(d.act_slug, b.act_slug) AS act_slug,
      COALESCE(d.section_label, b.section_label) AS section_label,
      COALESCE(d.text, b.text)         AS text,
      COALESCE(d.source_url, b.source_url) AS source_url,
      COALESCE(d.sim, 0)::FLOAT        AS similarity,
      COALESCE(b.rank, 0)::FLOAT       AS bm25_rank,
      (
        CASE WHEN d.id IS NOT NULL THEN 1.0::FLOAT / (k + d.rnk) ELSE 0::FLOAT END
        +
        CASE WHEN b.id IS NOT NULL THEN 1.0::FLOAT / (k + b.rnk) ELSE 0::FLOAT END
      )::FLOAT AS rrf_score,
      CASE
        WHEN d.id IS NOT NULL AND b.id IS NOT NULL THEN 'both'
        WHEN d.id IS NOT NULL THEN 'dense'
        ELSE 'bm25'
      END AS source_type
    FROM dense d
    FULL OUTER JOIN bm25 b ON d.id = b.id
  )
  SELECT
    m.id,
    m.act_slug,
    m.section_label,
    m.text,
    m.similarity,
    m.source_url,
    m.bm25_rank,
    m.rrf_score,
    m.source_type
  FROM merged m
  ORDER BY m.rrf_score DESC, m.similarity DESC
  LIMIT p_limit;
END;
$$;

GRANT EXECUTE ON FUNCTION public.law_search_hybrid(
  VECTOR(1536), TEXT, TEXT, TEXT, TEXT, TIMESTAMPTZ, FLOAT, INT
) TO authenticated, anon, service_role;

COMMENT ON FUNCTION public.law_search_hybrid(
  VECTOR(1536), TEXT, TEXT, TEXT, TEXT, TIMESTAMPTZ, FLOAT, INT
) IS 'Hybrid retrieval over law_chunks_v2 — Reciprocal Rank Fusion of cosine (dense) + ts_rank_cd (BM25/simple). Target: recall@3 50% → 70% on terminology-heavy FI/EE/EU queries (vabank A1, 2026-05-15).';

-- =====================================================================
-- 5. law_search_hybrid_qa — QA harness wrapper with tunable probes
-- =====================================================================
-- Mirrors law_search_v2_qa. Lets the eval runner sweep recall against
-- different ivfflat.probes values without redeploying the production RPC.
-- =====================================================================

CREATE OR REPLACE FUNCTION public.law_search_hybrid_qa(
  p_query_embedding VECTOR(1536),
  p_query_text TEXT,
  p_jurisdiction TEXT DEFAULT NULL,
  p_lang TEXT DEFAULT NULL,
  p_act_slug TEXT DEFAULT NULL,
  p_valid_at TIMESTAMPTZ DEFAULT NULL,
  p_match_threshold FLOAT DEFAULT 0.0,
  p_limit INT DEFAULT 5,
  p_probes INT DEFAULT 25
) RETURNS TABLE (
  id UUID,
  act_slug TEXT,
  section_label TEXT,
  text TEXT,
  similarity FLOAT,
  source_url TEXT,
  bm25_rank FLOAT,
  rrf_score FLOAT,
  source_type TEXT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  k CONSTANT INT := 60;
  pool_size CONSTANT INT := 50;
  tsq tsquery;
BEGIN
  -- Wider probe sweep allowed for the QA harness.
  PERFORM set_config('ivfflat.probes', GREATEST(1, LEAST(p_probes, 100))::TEXT, true);

  IF p_query_text IS NULL OR length(btrim(p_query_text)) = 0 THEN
    tsq := NULL;
  ELSE
    BEGIN
      tsq := websearch_to_tsquery('simple'::regconfig, p_query_text);
    EXCEPTION WHEN OTHERS THEN
      tsq := NULL;
    END;
  END IF;

  RETURN QUERY
  WITH dense AS (
    SELECT
      c.id,
      c.act_slug,
      c.section_label,
      c.text,
      c.source_url,
      (1 - (c.embedding <=> p_query_embedding))::FLOAT AS sim,
      ROW_NUMBER() OVER (ORDER BY c.embedding <=> p_query_embedding ASC) AS rnk
    FROM public.law_chunks_v2 c
    WHERE c.embedding IS NOT NULL
      AND (p_jurisdiction IS NULL OR c.jurisdiction = p_jurisdiction)
      AND (p_lang IS NULL OR c.lang = p_lang)
      AND (p_act_slug IS NULL OR c.act_slug = p_act_slug)
      AND (p_valid_at IS NULL OR (
        c.redaktsioon_valid_from <= p_valid_at
        AND (c.redaktsioon_valid_to IS NULL OR c.redaktsioon_valid_to > p_valid_at)
      ))
      AND (1 - (c.embedding <=> p_query_embedding)) > p_match_threshold
    ORDER BY c.embedding <=> p_query_embedding ASC
    LIMIT pool_size
  ),
  bm25 AS (
    SELECT
      c.id,
      c.act_slug,
      c.section_label,
      c.text,
      c.source_url,
      ts_rank_cd(c.chunk_tsv, tsq)::FLOAT AS rank,
      ROW_NUMBER() OVER (ORDER BY ts_rank_cd(c.chunk_tsv, tsq) DESC) AS rnk
    FROM public.law_chunks_v2 c
    WHERE tsq IS NOT NULL
      AND c.chunk_tsv @@ tsq
      AND (p_jurisdiction IS NULL OR c.jurisdiction = p_jurisdiction)
      AND (p_lang IS NULL OR c.lang = p_lang)
      AND (p_act_slug IS NULL OR c.act_slug = p_act_slug)
      AND (p_valid_at IS NULL OR (
        c.redaktsioon_valid_from <= p_valid_at
        AND (c.redaktsioon_valid_to IS NULL OR c.redaktsioon_valid_to > p_valid_at)
      ))
    ORDER BY ts_rank_cd(c.chunk_tsv, tsq) DESC
    LIMIT pool_size
  ),
  merged AS (
    SELECT
      COALESCE(d.id, b.id)            AS id,
      COALESCE(d.act_slug, b.act_slug) AS act_slug,
      COALESCE(d.section_label, b.section_label) AS section_label,
      COALESCE(d.text, b.text)         AS text,
      COALESCE(d.source_url, b.source_url) AS source_url,
      COALESCE(d.sim, 0)::FLOAT        AS similarity,
      COALESCE(b.rank, 0)::FLOAT       AS bm25_rank,
      (
        CASE WHEN d.id IS NOT NULL THEN 1.0::FLOAT / (k + d.rnk) ELSE 0::FLOAT END
        +
        CASE WHEN b.id IS NOT NULL THEN 1.0::FLOAT / (k + b.rnk) ELSE 0::FLOAT END
      )::FLOAT AS rrf_score,
      CASE
        WHEN d.id IS NOT NULL AND b.id IS NOT NULL THEN 'both'
        WHEN d.id IS NOT NULL THEN 'dense'
        ELSE 'bm25'
      END AS source_type
    FROM dense d
    FULL OUTER JOIN bm25 b ON d.id = b.id
  )
  SELECT
    m.id,
    m.act_slug,
    m.section_label,
    m.text,
    m.similarity,
    m.source_url,
    m.bm25_rank,
    m.rrf_score,
    m.source_type
  FROM merged m
  ORDER BY m.rrf_score DESC, m.similarity DESC
  LIMIT p_limit;
END;
$$;

GRANT EXECUTE ON FUNCTION public.law_search_hybrid_qa(
  VECTOR(1536), TEXT, TEXT, TEXT, TEXT, TIMESTAMPTZ, FLOAT, INT, INT
) TO authenticated, anon, service_role;

COMMENT ON FUNCTION public.law_search_hybrid_qa(
  VECTOR(1536), TEXT, TEXT, TEXT, TEXT, TIMESTAMPTZ, FLOAT, INT, INT
) IS 'QA-only wrapper of law_search_hybrid exposing tunable ivfflat.probes (1..100). Used by eval/golden_corpus_qa_via_edge.ts in hybrid mode.';
