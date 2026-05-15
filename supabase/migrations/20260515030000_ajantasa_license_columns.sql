-- ============================================================================
-- ajantasa license columns — Option B from finlex_licensing_decision_2026-05-14
-- ============================================================================
-- DECISION (business/legal/finlex_licensing_decision_2026-05-14.md):
--   Tekijänoikeuslaki §9 puts statute TEXT in the public domain. Finlex's
--   CC-BY-NC label can at best cover the HTML/CSS presentation layer of
--   /ajantasa/ pages and the sui-generis database compilation right.
--
--   To stay well within market norm — never reprint > 200 chars of full-text
--   from consolidated ajantasa without a license — we add per-chunk metadata:
--
--     license         — license tag for the chunk SOURCE
--                       'public-domain'     (default; alkup statute text)
--                       'CC-BY-4.0'         (Finlex alkup, original-as-enacted)
--                       'CC-BY-NC-4.0'      (Finlex ajantasa, consolidated)
--                       'CC-BY-EUR-LEX'     (EU directives via EUR-Lex)
--
--     display_policy  — UI / model display constraint
--                       'full'              (default; quote/display freely)
--                       'snippet_only'      (truncate to 200 chars + link out)
--                       'citation_only'     (cite reference + link, no body)
--
-- All EXISTING rows remain `license='public-domain'`, `display_policy='full'`.
-- Backfill is the DEFAULT clause on ALTER TABLE plus an explicit UPDATE for
-- any NULL stragglers (defence-in-depth; CHECK constraint forbids NULL going
-- forward).
--
-- The law_search_v2 RPC return signature gains the two new columns so the
-- runtime tool layer can enforce the snippet-only display policy without a
-- second round-trip.
--
-- IMPORTANT: This migration is data-safe. No existing chunk text is mutated;
-- only metadata columns are added. The new columns default values match the
-- legal stance for the alkup corpus already on production.
-- ============================================================================

-- ── Schema additions ────────────────────────────────────────────────────────
ALTER TABLE public.law_chunks_v2
  ADD COLUMN IF NOT EXISTS license TEXT DEFAULT 'public-domain';

ALTER TABLE public.law_chunks_v2
  ADD COLUMN IF NOT EXISTS display_policy TEXT DEFAULT 'full'
    CHECK (display_policy IN ('full', 'snippet_only', 'citation_only'));

-- Defence-in-depth backfill: any existing rows where the DEFAULT clause did
-- not fire (extremely unlikely, but cheap to guarantee) get the safe values.
UPDATE public.law_chunks_v2
  SET license = 'public-domain'
  WHERE license IS NULL;

UPDATE public.law_chunks_v2
  SET display_policy = 'full'
  WHERE display_policy IS NULL;

-- Index — display_policy is read on every snippet decision in legal_lookup.
-- Partial index on snippet_only rows only — full-display rows are the common
-- path and don't need an extra index lookup.
CREATE INDEX IF NOT EXISTS law_chunks_v2_snippet_only_idx
  ON public.law_chunks_v2 (display_policy)
  WHERE display_policy = 'snippet_only';

-- ── Updated law_search_v2 RPC — surface license + display_policy ────────────
-- The runtime tool layer (legal_lookup.ts) reads display_policy to decide
-- between full-text and 200-char snippet display. Returning it here keeps
-- the snippet decision a single RPC call instead of a second SELECT.
--
-- This redefinition preserves all behaviour from
-- 20260515020000_law_search_v2_probes_fix.sql (ivfflat.probes=25, same WHERE
-- clauses, same ordering). Only the RETURNS TABLE adds two columns.
--
-- DROP is required because PostgreSQL forbids changing the return type of an
-- existing function via CREATE OR REPLACE. We don't touch data — only the
-- function signature.
DROP FUNCTION IF EXISTS public.law_search_v2(
  VECTOR(1536), TEXT, TEXT, TEXT, TIMESTAMPTZ, FLOAT, INT
);

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
  source_url TEXT,
  license TEXT,
  display_policy TEXT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM set_config('ivfflat.probes', '25', true);

  RETURN QUERY
  SELECT
    c.id,
    c.act_slug,
    c.section_label,
    c.text,
    (1 - (c.embedding <=> query_embedding))::FLOAT AS similarity,
    c.source_url,
    COALESCE(c.license, 'public-domain') AS license,
    COALESCE(c.display_policy, 'full') AS display_policy
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
  IS 'Version-aware semantic search over law_chunks_v2. Sets ivfflat.probes=25. Returns license + display_policy so legal_lookup can apply Option B snippet limits to CC-BY-NC ajantasa rows.';

COMMENT ON COLUMN public.law_chunks_v2.license
  IS 'License tag for the chunk source. public-domain (alkup Tekijänoikeuslaki §9) | CC-BY-4.0 (Finlex alkup) | CC-BY-NC-4.0 (Finlex ajantasa) | CC-BY-EUR-LEX (EUR-Lex directives).';

COMMENT ON COLUMN public.law_chunks_v2.display_policy
  IS 'UI/model display constraint. full=quote freely | snippet_only=≤200 chars + Finlex link | citation_only=cite reference + link, no body. Option B per finlex_licensing_decision_2026-05-14.md.';
