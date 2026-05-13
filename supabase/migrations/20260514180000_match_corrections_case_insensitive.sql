-- 20260514180000_match_corrections_case_insensitive.sql
-- ============================================================================
-- Defensive normalization for advice_corrections jurisdiction matching.
--
-- Root issue (lesson_corrections_retrieval_debug.md):
--   The seed migration 20260513150000_seed_advice_corrections.sql contains
--   both 'FI' (uppercase, 4 rows) and 'fi' (lowercase, 1 row) for the same
--   Finnish jurisdiction. The original match_corrections RPC used literal
--   equality on jurisdiction, so callers that passed 'fi' missed half the
--   FI rows and callers that passed 'FI' missed the rest. The fix below:
--     1. Normalize stored values to lowercase (one-time UPDATE).
--     2. Compare via LOWER() on both sides so future inserts stay tolerant.
--
-- The retrieval path in claude-proxy currently passes NULL (no filter), so
-- this migration is defensive — it eliminates a latent bug rather than
-- fixing user-visible behaviour today. Combined with the threshold fix in
-- corrections_retriever.ts (0.75 → 0.45) this closes both the cross-language
-- recall gap and the jurisdiction-case mismatch.
--
-- Note: this migration was originally written with timestamp 140000 but
-- collided alphabetically with same-day deploys; renamed to 180000 to
-- preserve topological order. The DB changes were applied to prod via
-- Management API on 2026-05-14 before this file was committed; re-running
-- the migration locally is a no-op (UPDATE is idempotent, CREATE OR REPLACE
-- is also idempotent).
-- ============================================================================

-- 1. Normalize the existing seed rows. Idempotent: re-running is a no-op.
UPDATE public.advice_corrections
SET jurisdiction = LOWER(jurisdiction)
WHERE jurisdiction IS NOT NULL
  AND jurisdiction <> LOWER(jurisdiction);

-- 2. Replace the RPC with a case-insensitive variant. CREATE OR REPLACE
--    keeps the function OID stable so existing REST callers continue to
--    resolve it unchanged.
CREATE OR REPLACE FUNCTION public.match_corrections(
  p_query_embedding vector,
  p_jurisdiction text DEFAULT NULL::text,
  p_threshold double precision DEFAULT 0.45,
  p_limit integer DEFAULT 3
)
RETURNS TABLE(
  id uuid,
  question text,
  wrong_advice text,
  correct_answer text,
  why_wrong text,
  jurisdiction text,
  case_type text,
  severity text,
  similarity double precision
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
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
    AND (
      p_jurisdiction IS NULL
      OR c.jurisdiction IS NULL
      OR LOWER(c.jurisdiction) = LOWER(p_jurisdiction)
    )
    AND (1.0 - (c.embedding <=> p_query_embedding)) >= p_threshold
  ORDER BY c.embedding <=> p_query_embedding ASC
  LIMIT p_limit;
$function$;

COMMENT ON FUNCTION public.match_corrections(vector, text, double precision, integer)
IS 'Returns top-N corrections similar to query embedding. Jurisdiction match is case-insensitive (defensive: seed had mixed FI/fi). Default threshold 0.45 supports cross-language retrieval — see lesson_corrections_retrieval_debug.md.';
