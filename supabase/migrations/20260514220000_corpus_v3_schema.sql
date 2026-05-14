-- =====================================================================
-- Corpus v3 schema — lawyer-grade FI+EE legal corpus foundation
-- =====================================================================
-- Per consilium (Legal Architect + Engineering Lead 2026-05-14):
--   law_chunks_v2          : version-aware §-paragraph chunks (redaktsioon)
--   case_chunks            : court decisions (ratio paragraphs, topics, citations)
--   statute_aliases        : 'HOL §114' / 'hallintolaki 114 §' resolver (pg_trgm)
--   case_statute_citations : cross-ref graph (cases citing a §)
--   travaux                : HE / eelnõud / seletuskirjad (legislative intent)
--   ingest_jobs            : SKIP LOCKED worker queue
--   unresolved_refs        : citation extraction misses (manual review)
--
-- 4 RPCs:
--   law_search_v2          : version-aware semantic search
--   cases_citing           : reverse-lookup cases citing a §
--   travaux_for            : HE/eelnõud injection for a §  (FI killer feature)
--   dispatch_ingest_job    : worker queue dispatcher (FOR UPDATE SKIP LOCKED)
--
-- IMPORTANT: Does NOT touch existing law_chunks table (Phase 2 legal_lookup).
-- =====================================================================

-- ---------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ---------------------------------------------------------------------
-- Table 1: law_chunks_v2 — versioned statute paragraphs
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.law_chunks_v2 (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  jurisdiction TEXT NOT NULL CHECK (jurisdiction IN ('fi','ee','eu')),
  act_slug TEXT NOT NULL,
  act_full_name TEXT NOT NULL,
  act_number TEXT,
  chapter TEXT,
  section TEXT,
  subsection TEXT,
  section_label TEXT,
  text TEXT NOT NULL,
  lang TEXT NOT NULL CHECK (lang IN ('fi','sv','et','en')),
  redaktsioon_valid_from TIMESTAMPTZ,
  redaktsioon_valid_to TIMESTAMPTZ,
  version_hash TEXT,
  parent_chunk_id UUID REFERENCES public.law_chunks_v2(id),
  embedding VECTOR(1536),
  source_url TEXT NOT NULL,
  ingested_at TIMESTAMPTZ DEFAULT NOW(),
  last_verified_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS law_chunks_v2_embedding_ivfflat_idx
  ON public.law_chunks_v2
  USING ivfflat (embedding vector_cosine_ops)
  WITH (lists = 100);

CREATE INDEX IF NOT EXISTS law_chunks_v2_act_section_idx
  ON public.law_chunks_v2 (act_slug, section);

CREATE INDEX IF NOT EXISTS law_chunks_v2_jur_lang_idx
  ON public.law_chunks_v2 (jurisdiction, lang);

CREATE INDEX IF NOT EXISTS law_chunks_v2_redaktsioon_gist_idx
  ON public.law_chunks_v2
  USING gist (
    tstzrange(redaktsioon_valid_from, redaktsioon_valid_to)
  );

-- ---------------------------------------------------------------------
-- Table 2: case_chunks — court decision paragraphs
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.case_chunks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  jurisdiction TEXT CHECK (jurisdiction IN ('fi','ee','eu','echr')),
  court TEXT NOT NULL CHECK (court IN ('KKO','KHO','Riigikohus','HAO','HoO','HKK','RKHK','RKTK','RKKK','CJEU','ECtHR')),
  case_number TEXT NOT NULL,
  decided_at DATE NOT NULL,
  year INT GENERATED ALWAYS AS (EXTRACT(YEAR FROM decided_at)::INT) STORED,
  parties_redacted TEXT,
  paragraph_no TEXT,
  text TEXT NOT NULL,
  text_type TEXT CHECK (text_type IN ('facts','ratio','obiter','dispositive')),
  legal_topics TEXT[],
  statutes_cited TEXT[],
  key_holding TEXT,
  outcome TEXT,
  lang TEXT,
  embedding VECTOR(1536),
  source_url TEXT,
  ingested_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS case_chunks_embedding_ivfflat_idx
  ON public.case_chunks
  USING ivfflat (embedding vector_cosine_ops)
  WITH (lists = 100);

CREATE INDEX IF NOT EXISTS case_chunks_legal_topics_gin_idx
  ON public.case_chunks
  USING gin (legal_topics);

CREATE INDEX IF NOT EXISTS case_chunks_statutes_cited_gin_idx
  ON public.case_chunks
  USING gin (statutes_cited);

CREATE INDEX IF NOT EXISTS case_chunks_court_year_idx
  ON public.case_chunks (court, year);

CREATE INDEX IF NOT EXISTS case_chunks_case_number_idx
  ON public.case_chunks (case_number);

-- ---------------------------------------------------------------------
-- Table 3: statute_aliases — citation resolver
-- ---------------------------------------------------------------------
-- NOTE: act_slug here is NOT an FK to law_chunks_v2.act_slug because
-- act_slug in law_chunks_v2 is not unique (many chunks per act). Aliases
-- map alias -> act_slug + section; resolution happens at query time.
CREATE TABLE IF NOT EXISTS public.statute_aliases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alias TEXT NOT NULL,
  act_slug TEXT NOT NULL,
  section TEXT,
  subsection TEXT,
  pattern_kind TEXT CHECK (pattern_kind IN ('exact','regex','common_misspelling')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- pg_trgm fuzzy index for misspellings / variant forms
CREATE INDEX IF NOT EXISTS statute_aliases_alias_trgm_idx
  ON public.statute_aliases
  USING gin (alias gin_trgm_ops);

CREATE UNIQUE INDEX IF NOT EXISTS statute_aliases_unique_idx
  ON public.statute_aliases (alias, act_slug, COALESCE(section, ''));

-- ---------------------------------------------------------------------
-- Table 4: case_statute_citations — cross-ref graph
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.case_statute_citations (
  case_chunk_id UUID NOT NULL REFERENCES public.case_chunks(id) ON DELETE CASCADE,
  statute_chunk_id UUID NOT NULL REFERENCES public.law_chunks_v2(id) ON DELETE CASCADE,
  citation_text TEXT,
  citation_kind TEXT CHECK (citation_kind IN ('held','distinguished','applied','overruled','followed','cited')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (case_chunk_id, statute_chunk_id)
);

CREATE INDEX IF NOT EXISTS case_statute_citations_statute_idx
  ON public.case_statute_citations (statute_chunk_id);

CREATE INDEX IF NOT EXISTS case_statute_citations_case_idx
  ON public.case_statute_citations (case_chunk_id);

-- ---------------------------------------------------------------------
-- Table 5: ingest_jobs — worker queue
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.ingest_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source TEXT NOT NULL CHECK (source IN ('finlex','rt','eur-lex','hudoc','kko','kho','riigikohus','he','eelnõu')),
  source_id TEXT NOT NULL,
  target_table TEXT CHECK (target_table IN ('law_chunks_v2','case_chunks','travaux')),
  status TEXT CHECK (status IN ('queued','fetching','chunking','embedding','done','failed')) DEFAULT 'queued',
  priority INT DEFAULT 5,
  attempts INT DEFAULT 0,
  last_error TEXT,
  payload JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  locked_until TIMESTAMPTZ,
  worker_id TEXT,
  UNIQUE (source, source_id, target_table)
);

CREATE INDEX IF NOT EXISTS ingest_jobs_dispatch_idx
  ON public.ingest_jobs (status, priority, created_at);

CREATE INDEX IF NOT EXISTS ingest_jobs_lease_idx
  ON public.ingest_jobs (locked_until);

-- ---------------------------------------------------------------------
-- Table 6: travaux — HE / eelnõud / seletuskirjad (legislative intent)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.travaux (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doc_kind TEXT CHECK (doc_kind IN ('HE','VN','eelnõu','seletuskiri')),
  doc_number TEXT NOT NULL,
  title TEXT,
  jurisdiction TEXT,
  related_act_slug TEXT,
  section_ref TEXT,
  text TEXT,
  embedding VECTOR(1536),
  source_url TEXT,
  year INT
);

CREATE INDEX IF NOT EXISTS travaux_act_section_idx
  ON public.travaux (related_act_slug, section_ref);

CREATE INDEX IF NOT EXISTS travaux_embedding_ivfflat_idx
  ON public.travaux
  USING ivfflat (embedding vector_cosine_ops)
  WITH (lists = 100);

-- ---------------------------------------------------------------------
-- Table 7: unresolved_refs — citation extraction misses
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.unresolved_refs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  raw_citation TEXT NOT NULL,
  found_in_case_id UUID REFERENCES public.case_chunks(id),
  found_count INT DEFAULT 1,
  last_seen TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================================
-- RLS — Row Level Security
-- =====================================================================
ALTER TABLE public.law_chunks_v2 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.case_chunks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.statute_aliases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.case_statute_citations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.travaux ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ingest_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.unresolved_refs ENABLE ROW LEVEL SECURITY;

-- Public-read tables (FOR SELECT USING true)
DROP POLICY IF EXISTS law_chunks_v2_public_read ON public.law_chunks_v2;
CREATE POLICY law_chunks_v2_public_read ON public.law_chunks_v2
  FOR SELECT USING (true);

DROP POLICY IF EXISTS case_chunks_public_read ON public.case_chunks;
CREATE POLICY case_chunks_public_read ON public.case_chunks
  FOR SELECT USING (true);

DROP POLICY IF EXISTS statute_aliases_public_read ON public.statute_aliases;
CREATE POLICY statute_aliases_public_read ON public.statute_aliases
  FOR SELECT USING (true);

DROP POLICY IF EXISTS case_statute_citations_public_read ON public.case_statute_citations;
CREATE POLICY case_statute_citations_public_read ON public.case_statute_citations
  FOR SELECT USING (true);

DROP POLICY IF EXISTS travaux_public_read ON public.travaux;
CREATE POLICY travaux_public_read ON public.travaux
  FOR SELECT USING (true);

-- ingest_jobs + unresolved_refs: service-role only — no public policy.
-- (service_role bypasses RLS automatically; anon/authenticated have no
--  policy → denied by default.)

-- =====================================================================
-- RPCs
-- =====================================================================

-- ---------------------------------------------------------------------
-- law_search_v2 — version-aware semantic search
-- ---------------------------------------------------------------------
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

-- ---------------------------------------------------------------------
-- cases_citing — reverse lookup: cases citing a given statute §
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.cases_citing(p_act_slug TEXT, p_section TEXT)
RETURNS TABLE (
  case_number TEXT,
  court TEXT,
  decided_at DATE,
  key_holding TEXT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT
    c.case_number,
    c.court,
    c.decided_at,
    c.key_holding
  FROM public.case_chunks c
  WHERE (p_act_slug || '-' || p_section) = ANY(c.statutes_cited)
  ORDER BY c.decided_at DESC;
END;
$$;

-- ---------------------------------------------------------------------
-- travaux_for — HE / eelnõud for a § (FI killer feature)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.travaux_for(p_act_slug TEXT, p_section TEXT)
RETURNS TABLE (
  doc_number TEXT,
  title TEXT,
  text TEXT,
  source_url TEXT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT
    t.doc_number,
    t.title,
    t.text,
    t.source_url
  FROM public.travaux t
  WHERE t.related_act_slug = p_act_slug
    AND (t.section_ref IS NULL OR t.section_ref = p_section);
END;
$$;

-- ---------------------------------------------------------------------
-- dispatch_ingest_job — worker queue dispatcher
-- (FOR UPDATE SKIP LOCKED — safe for many parallel workers)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.dispatch_ingest_job(
  p_worker_id TEXT,
  p_lease_seconds INT DEFAULT 120
)
RETURNS TABLE (
  id UUID,
  source TEXT,
  source_id TEXT,
  target_table TEXT,
  payload JSONB
)
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  UPDATE public.ingest_jobs ij
  SET
    status = 'fetching',
    worker_id = p_worker_id,
    locked_until = NOW() + make_interval(secs => p_lease_seconds),
    attempts = ij.attempts + 1,
    updated_at = NOW()
  WHERE ij.id = (
    SELECT inner_ij.id
    FROM public.ingest_jobs inner_ij
    WHERE inner_ij.status = 'queued'
       OR (inner_ij.status = 'fetching' AND inner_ij.locked_until < NOW())
    ORDER BY inner_ij.priority ASC, inner_ij.created_at ASC
    LIMIT 1
    FOR UPDATE SKIP LOCKED
  )
  RETURNING ij.id, ij.source, ij.source_id, ij.target_table, ij.payload;
END;
$$;

-- ---------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------
GRANT EXECUTE ON FUNCTION public.law_search_v2(VECTOR(1536), TEXT, TEXT, TEXT, TIMESTAMPTZ, FLOAT, INT)
  TO authenticated, anon, service_role;
GRANT EXECUTE ON FUNCTION public.cases_citing(TEXT, TEXT)
  TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.travaux_for(TEXT, TEXT)
  TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.dispatch_ingest_job(TEXT, INT)
  TO service_role;

-- =====================================================================
-- END corpus v3 schema
-- =====================================================================
