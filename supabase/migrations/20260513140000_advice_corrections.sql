-- ============================================================================
-- 20260513140000_advice_corrections.sql
-- "Memory of Wrong Answers" — Advocat's asymmetric value upgrade.
-- ----------------------------------------------------------------------------
-- advice_digest remembers what we SAID.
-- advice_corrections remembers what we GOT WRONG.
--
-- Each correction permanently raises the floor: on every subsequent planner
-- pass we retrieve top-N corrections semantically similar to the current
-- question and inject them as a <learned_corrections> block in the system
-- prompt, so the model is told NOT to repeat past mistakes.
--
-- Multi-tenant model:
--   * READ: any authenticated user can read every correction.
--     This is the collective knowledge that compounds over time and beats
--     stateless competitor models on Estonian / Finnish edge cases.
--   * WRITE: only the row owner (or service_role) can insert.
--     Prevents poisoning the corpus from arbitrary accounts.
--
-- Correction sources:
--   user_explicit   — user said "that's wrong" / "actually X". Detected by
--                     correction_detector.ts (Haiku 4.5) on each user turn.
--   fact_extractor  — fact_extractor.ts found a new fact that contradicts
--                     previously stated advice in the same case.
--   eval_failure    — eval harness flagged a wrong answer in regression.
--   lawyer_review   — human attorney marked the response wrong via the
--                     admin-add-correction edge function (service_role).
--
-- Severity:
--   factual    — wrong fact / date / number / law citation.
--   procedural — right substance, wrong court / wrong filing / wrong order.
--   strategic  — answer was technically correct but missed a better option.
--   citation   — [[ref:...]] marker pointed at the wrong act or paragraph.
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS public.advice_corrections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  conversation_id UUID,
  question TEXT NOT NULL,
  wrong_advice TEXT NOT NULL,
  correct_answer TEXT NOT NULL,
  why_wrong TEXT NOT NULL,
  correction_source TEXT NOT NULL CHECK (correction_source IN (
    'user_explicit', 'fact_extractor', 'lawyer_review', 'eval_failure'
  )),
  jurisdiction TEXT,
  case_type TEXT,
  -- OpenAI text-embedding-3-small produces 1536-dim vectors.
  embedding VECTOR(1536),
  severity TEXT CHECK (severity IN (
    'factual', 'procedural', 'strategic', 'citation'
  )),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  metadata JSONB DEFAULT '{}'::jsonb
);

-- ivfflat with cosine distance. 100 lists is the docs default for <1M rows;
-- the table will rebuild itself fine once we hit the threshold.
CREATE INDEX IF NOT EXISTS advice_corrections_embedding_idx
  ON public.advice_corrections
  USING ivfflat (embedding vector_cosine_ops)
  WITH (lists = 100);

CREATE INDEX IF NOT EXISTS advice_corrections_user_idx
  ON public.advice_corrections(user_id);

CREATE INDEX IF NOT EXISTS advice_corrections_jurisdiction_idx
  ON public.advice_corrections(jurisdiction);

CREATE INDEX IF NOT EXISTS advice_corrections_source_idx
  ON public.advice_corrections(correction_source);

ALTER TABLE public.advice_corrections ENABLE ROW LEVEL SECURITY;

-- Anyone authenticated can read — the corpus is shared knowledge.
DROP POLICY IF EXISTS "anyone reads corrections" ON public.advice_corrections;
CREATE POLICY "anyone reads corrections"
  ON public.advice_corrections
  FOR SELECT
  USING (true);

-- Only the owner (or service_role via JWT role claim) can insert.
DROP POLICY IF EXISTS "owner writes corrections" ON public.advice_corrections;
CREATE POLICY "owner writes corrections"
  ON public.advice_corrections
  FOR INSERT
  WITH CHECK (auth.uid() = user_id OR auth.role() = 'service_role');

-- Only service_role can update / delete — corrections are append-mostly.
DROP POLICY IF EXISTS "service updates corrections" ON public.advice_corrections;
CREATE POLICY "service updates corrections"
  ON public.advice_corrections
  FOR UPDATE
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

DROP POLICY IF EXISTS "service deletes corrections" ON public.advice_corrections;
CREATE POLICY "service deletes corrections"
  ON public.advice_corrections
  FOR DELETE
  USING (auth.role() = 'service_role');

-- ----------------------------------------------------------------------------
-- RPC: match_corrections — semantic similarity retrieval.
-- ----------------------------------------------------------------------------
-- Called by corrections_retriever.ts on every planner pass. Returns up to
-- p_limit corrections whose embedding cosine-similarity to p_query_embedding
-- exceeds p_threshold, filtered by jurisdiction when provided.
--
-- Cosine similarity = 1 - cosine_distance. pgvector exposes the `<=>`
-- distance operator; we project it to similarity in the SELECT.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.match_corrections(
  p_query_embedding VECTOR(1536),
  p_jurisdiction TEXT DEFAULT NULL,
  p_threshold FLOAT DEFAULT 0.75,
  p_limit INT DEFAULT 3
) RETURNS TABLE (
  id UUID,
  question TEXT,
  wrong_advice TEXT,
  correct_answer TEXT,
  why_wrong TEXT,
  jurisdiction TEXT,
  case_type TEXT,
  severity TEXT,
  similarity FLOAT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    c.id,
    c.question,
    c.wrong_advice,
    c.correct_answer,
    c.why_wrong,
    c.jurisdiction,
    c.case_type,
    c.severity,
    (1.0 - (c.embedding <=> p_query_embedding))::FLOAT AS similarity
  FROM public.advice_corrections c
  WHERE c.embedding IS NOT NULL
    AND (p_jurisdiction IS NULL OR c.jurisdiction IS NULL OR c.jurisdiction = p_jurisdiction)
    AND (1.0 - (c.embedding <=> p_query_embedding)) >= p_threshold
  ORDER BY c.embedding <=> p_query_embedding ASC
  LIMIT p_limit;
$$;

GRANT EXECUTE ON FUNCTION public.match_corrections(VECTOR(1536), TEXT, FLOAT, INT)
  TO authenticated, anon, service_role;

COMMENT ON TABLE public.advice_corrections IS
  'Memory of Wrong Answers. Shared corpus injected as <learned_corrections> into planner prompts.';

COMMENT ON FUNCTION public.match_corrections IS
  'Retrieve corrections semantically similar to a query embedding. Used by corrections_retriever.ts.';
