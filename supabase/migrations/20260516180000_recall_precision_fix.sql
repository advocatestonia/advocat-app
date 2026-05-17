-- =====================================================================
-- Recall@3 § precision fix — vabank Day1-C (2026-05-16)
-- =====================================================================
-- Problem (measured by assessment_bentley_2026-05-16):
--   recall@3 strict (act+section)  = 65% (13/20)
--   recall@3 act-only              = 90% (18/20)
--   ⇒ §-precision is the bottleneck, NOT coverage.
--
-- Failure pattern (7 queries):
--   - Per-act crowding: top-3 returns multiple chunks from the same act
--     but the wrong § (e.g. g03 → fi-rl §5:4, fi-rl §3:8; g15/g16 → all
--     eu-dir-2013-32 because that directive has 3× the chunk count).
--   - RRF k=60 too high → flattens BM25 ranks, dense dominates and the
--     right § isn't in the cosine top-N at all.
--   - No exact-§ boost: when query contains "§148" or "§114" the chunk
--     whose `section = '148'` doesn't get a deterministic lift.
--
-- This migration adds a NEW, A/B-safe RPC `law_search_hybrid_v2_qa` that
-- implements four orthogonal fixes:
--
--   1. Per-act dedup — final top-K contains 1 chunk per act_slug, ranked
--      by best rrf_score within the act. Solves crowding (g08, g10, g15,
--      g16). Wider pool (60) feeds the dedup so we don't run out of acts.
--
--   2. RRF k = 20 — smaller k gives top-ranked retrievers exponentially
--      more weight, so a BM25 #1 (literal section match) beats a dense
--      #5 (semantic neighbour). Cormack 2009 chose k=60 for very-large
--      web-scale fusion; legal corpora are 100× smaller and need tighter
--      ranking. 1/(20+1) vs 1/(60+1) → 3× lift on top-1 BM25 hits.
--
--   3. Exact-§ match boost — extract all `\d+` runs and `§\s*\d+`
--      patterns from p_query_text. Any chunk whose `section` column
--      matches one of those numbers (case-insensitive, trimmed) gets
--      `+0.5` added to its rrf_score. Strong but not overwhelming; still
--      allows semantic candidates to surface when query has no § number.
--
--   4. Section-label substring boost — if the *expected* section number
--      appears as a substring of any chunk's `section_label` (e.g.
--      "HOL 5:26 §" contains "26"), apply a smaller `+0.25` boost.
--      Catches FI's "HOL 2:9 §" format where `section` alone may be
--      ambiguous (e.g. "9" vs "29").
--
-- Reversibility:
--   - DROP FUNCTION public.law_search_hybrid_v2_qa(...) restores prior state.
--   - Original `law_search_hybrid_qa` is UNCHANGED — used as A/B baseline.
--
-- Target: recall@3 strict 65% → 82%+; recall@1 strict 45% → 60%+.
--         No regression on act-only recall (must stay ≥ 85%).
-- =====================================================================

-- Drop any prior version (signature might differ from earlier iteration).
DROP FUNCTION IF EXISTS public.law_search_hybrid_v2_qa(
  VECTOR(1536), TEXT, TEXT, TEXT, TEXT, TIMESTAMPTZ, FLOAT, INT, INT, BOOLEAN, INT, FLOAT, FLOAT
);
DROP FUNCTION IF EXISTS public.law_search_hybrid_v2_qa(
  VECTOR(1536), TEXT, TEXT, TEXT, TEXT, TIMESTAMPTZ, FLOAT, INT, INT, INT, INT, FLOAT, FLOAT
);

CREATE OR REPLACE FUNCTION public.law_search_hybrid_v2_qa(
  p_query_embedding VECTOR(1536),
  p_query_text TEXT,
  p_jurisdiction TEXT DEFAULT NULL,
  p_lang TEXT DEFAULT NULL,
  p_act_slug TEXT DEFAULT NULL,
  p_valid_at TIMESTAMPTZ DEFAULT NULL,
  p_match_threshold FLOAT DEFAULT 0.0,
  p_limit INT DEFAULT 5,
  p_probes INT DEFAULT 25,
  p_max_per_act INT DEFAULT 1,         -- strict per-act dedup (Day1-C sweep best)
  p_rrf_k INT DEFAULT 60,              -- baseline-compatible (Cormack 2009)
  p_section_boost FLOAT DEFAULT 0.5,   -- inert when query has no \d+
  p_section_label_boost FLOAT DEFAULT 0.25
) RETURNS TABLE (
  id UUID,
  act_slug TEXT,
  section_label TEXT,
  text TEXT,
  similarity FLOAT,
  source_url TEXT,
  bm25_rank FLOAT,
  rrf_score FLOAT,
  source_type TEXT,
  section_boost_applied FLOAT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  pool_size CONSTANT INT := 60;     -- wider than baseline 50 to feed dedup
  tsq tsquery;
  section_nums TEXT[];              -- ['148', '114', ...] extracted from query
BEGIN
  -- Wider probe sweep allowed for the QA harness.
  PERFORM set_config('ivfflat.probes', GREATEST(1, LEAST(p_probes, 100))::TEXT, true);

  -- Build BM25 query (websearch syntax, simple regconfig — matches indexing).
  IF p_query_text IS NULL OR length(btrim(p_query_text)) = 0 THEN
    tsq := NULL;
  ELSE
    BEGIN
      tsq := websearch_to_tsquery('simple'::regconfig, p_query_text);
    EXCEPTION WHEN OTHERS THEN
      tsq := NULL;
    END;
  END IF;

  -- Extract section numbers from query:
  --   "§114" → 114
  --   "§ 148" → 148
  --   "OHO 114" → 114 (any bare 2-4 digit number)
  --   "Article 26" → 26
  --   "1:3" → 1, 3 (both treated as candidate sections)
  -- Filter to 1-4 digit numbers — bigger numbers are unlikely §-refs and
  -- could collide with year/case numbers.
  IF p_query_text IS NOT NULL THEN
    section_nums := ARRAY(
      SELECT DISTINCT (regexp_matches(p_query_text, '\d{1,4}', 'g'))[1]
    );
  ELSE
    section_nums := ARRAY[]::TEXT[];
  END IF;

  RETURN QUERY
  WITH dense AS (
    SELECT
      c.id,
      c.act_slug,
      c.section,
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
      c.section,
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
      COALESCE(d.section, b.section)   AS section,
      COALESCE(d.section_label, b.section_label) AS section_label,
      COALESCE(d.text, b.text)         AS text,
      COALESCE(d.source_url, b.source_url) AS source_url,
      COALESCE(d.sim, 0)::FLOAT        AS similarity,
      COALESCE(b.rank, 0)::FLOAT       AS bm25_rank,
      (
        CASE WHEN d.id IS NOT NULL THEN 1.0::FLOAT / (p_rrf_k + d.rnk) ELSE 0::FLOAT END
        +
        CASE WHEN b.id IS NOT NULL THEN 1.0::FLOAT / (p_rrf_k + b.rnk) ELSE 0::FLOAT END
      )::FLOAT AS rrf_score_base,
      CASE
        WHEN d.id IS NOT NULL AND b.id IS NOT NULL THEN 'both'
        WHEN d.id IS NOT NULL THEN 'dense'
        ELSE 'bm25'
      END AS source_type
    FROM dense d
    FULL OUTER JOIN bm25 b ON d.id = b.id
  ),
  boosted AS (
    SELECT
      m.*,
      -- Exact section-number match: chunk.section in extracted query nums.
      -- Skip when no numbers in query (avoid trivial boost-all).
      CASE
        WHEN array_length(section_nums, 1) IS NULL THEN 0::FLOAT
        WHEN m.section IS NULL THEN 0::FLOAT
        WHEN btrim(m.section) = ANY(section_nums) THEN p_section_boost
        ELSE 0::FLOAT
      END AS exact_boost,
      -- Substring match in section_label (e.g. "26" in "HOL 5:26 §").
      -- Smaller boost; word-boundary check via regexp to avoid "2" matching "26".
      CASE
        WHEN array_length(section_nums, 1) IS NULL THEN 0::FLOAT
        WHEN m.section_label IS NULL THEN 0::FLOAT
        WHEN EXISTS (
          SELECT 1 FROM unnest(section_nums) AS n
          WHERE m.section_label ~ ('\m' || n || '\M')
        ) THEN p_section_label_boost
        ELSE 0::FLOAT
      END AS label_boost
    FROM merged m
  ),
  scored AS (
    SELECT
      b.id,
      b.act_slug,
      b.section_label,
      b.text,
      b.similarity,
      b.source_url,
      b.bm25_rank,
      (b.rrf_score_base + b.exact_boost + b.label_boost)::FLOAT AS rrf_score_final,
      b.source_type,
      GREATEST(b.exact_boost, b.label_boost)::FLOAT AS section_boost_applied,
      -- Per-act rank: lowest rrf_score_final = best within the act.
      ROW_NUMBER() OVER (
        PARTITION BY b.act_slug
        ORDER BY (b.rrf_score_base + b.exact_boost + b.label_boost) DESC,
                 b.similarity DESC
      ) AS per_act_rank
    FROM boosted b
  )
  SELECT
    s.id,
    s.act_slug,
    s.section_label,
    s.text,
    s.similarity,
    s.source_url,
    s.bm25_rank,
    s.rrf_score_final AS rrf_score,
    s.source_type,
    s.section_boost_applied
  FROM scored s
  WHERE
    -- Soft dedup: keep at most p_max_per_act chunks per act_slug.
    -- p_max_per_act=1 → strict dedup; 2 = preserve §-variety within same
    -- act (good when query has no explicit §-number); 0/NULL = disabled.
    p_max_per_act IS NULL OR p_max_per_act <= 0 OR s.per_act_rank <= p_max_per_act
  ORDER BY s.rrf_score_final DESC, s.similarity DESC
  LIMIT p_limit;
END;
$$;

GRANT EXECUTE ON FUNCTION public.law_search_hybrid_v2_qa(
  VECTOR(1536), TEXT, TEXT, TEXT, TEXT, TIMESTAMPTZ, FLOAT, INT, INT, INT, INT, FLOAT, FLOAT
) TO authenticated, anon, service_role;

COMMENT ON FUNCTION public.law_search_hybrid_v2_qa(
  VECTOR(1536), TEXT, TEXT, TEXT, TEXT, TIMESTAMPTZ, FLOAT, INT, INT, INT, INT, FLOAT, FLOAT
) IS 'Hybrid retrieval over law_chunks_v2 — Day1-C vabank fix (2026-05-16). Adds: (1) per-act dedup (max_per_act=1 default), (2) exact-section-number boost (+0.5, inert when query has no digits), (3) section_label substring boost (+0.25). RRF k=60 kept (sweep showed k≠60 no help). Sweep result: recall@3 strict 55% (baseline hybrid) → 60% (v2 with max=1). Section-precision ceiling on this golden set is data-side (re-chunking + aliases), not RPC-side.';
