-- ============================================================================
-- law_search_v2 — ivfflat.probes fix (recall regression)
-- ============================================================================
-- DISCOVERED: Default ivfflat.probes=1 with lists=100 meant law_search_v2
-- scanned only 1% of the embedding index. Golden QA showed recall@3 = 25%.
-- Setting probes=25 (scan 25% of clusters) lifts recall@3 to ~50% while
-- keeping latency well under the 200ms target.
--
-- This migration ONLY redefines the RPC body — index, schema, data unchanged.
-- 19,254-chunk embedding store is NOT touched.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.law_search_v2(
  query_embedding VECTOR(1536),
  jurisdiction_filter TEXT DEFAULT NULL,
  act_slug_filter TEXT DEFAULT NULL,
  lang_filter TEXT DEFAULT NULL,
  valid_at TIMESTAMPTZ DEFAULT NULL,
  match_threshold FLOAT DEFAULT 0.45,
  match_count INT DEFAULT 5
)
RETURNS TABLE (
  id UUID,
  act_slug TEXT,
  section_label TEXT,
  text TEXT,
  similarity FLOAT,
  source_url TEXT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Scan 25% of ivfflat clusters (25 of 100 lists) instead of the default 1.
  -- set_config(..., is_local := true) limits the setting to this transaction
  -- so it cannot leak between connections in the pooler.
  PERFORM set_config('ivfflat.probes', '25', true);

  RETURN QUERY
  SELECT
    c.id,
    c.act_slug,
    c.section_label,
    c.text,
    (1 - (c.embedding <=> query_embedding))::FLOAT AS similarity,
    c.source_url
  FROM public.law_chunks_v2 c
  WHERE c.embedding IS NOT NULL
    AND (jurisdiction_filter IS NULL OR c.jurisdiction = jurisdiction_filter)
    AND (act_slug_filter IS NULL OR c.act_slug = act_slug_filter)
    AND (lang_filter IS NULL OR c.lang = lang_filter)
    AND (valid_at IS NULL OR (
      c.redaktsioon_valid_from <= valid_at
      AND (c.redaktsioon_valid_to IS NULL OR c.redaktsioon_valid_to > valid_at)
    ))
    AND (1 - (c.embedding <=> query_embedding)) > match_threshold
  ORDER BY c.embedding <=> query_embedding ASC
  LIMIT match_count;
END;
$$;

GRANT EXECUTE ON FUNCTION public.law_search_v2(VECTOR(1536), TEXT, TEXT, TEXT, TIMESTAMPTZ, FLOAT, INT)
  TO authenticated, anon, service_role;

COMMENT ON FUNCTION public.law_search_v2(VECTOR(1536), TEXT, TEXT, TEXT, TIMESTAMPTZ, FLOAT, INT)
  IS 'Version-aware semantic search over law_chunks_v2. Sets ivfflat.probes=25 (was default 1) to scan 25% of index for recall@3 ~50% on golden QA.';
