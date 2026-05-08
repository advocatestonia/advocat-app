-- Add staleness tracking to law_chunks.
-- valid_from: the date from which this version of the law text is effective.
-- corpus_refreshed_at: timestamp of the last ingest run that touched this row.
--   Used by citation_grounder.ts to warn when citing potentially stale corpus.
--   Threshold: 90 days (STALE_THRESHOLD_DAYS in citation_grounder.ts).

ALTER TABLE public.law_chunks
  ADD COLUMN IF NOT EXISTS valid_from DATE,
  ADD COLUMN IF NOT EXISTS corpus_refreshed_at TIMESTAMPTZ DEFAULT NOW();

-- Back-fill existing rows so they have a baseline refreshed_at rather than NULL.
-- The grounder treats NULL as stale, so this prevents spurious warnings on the
-- current corpus immediately after migration.
UPDATE public.law_chunks
  SET corpus_refreshed_at = NOW()
  WHERE corpus_refreshed_at IS NULL;

-- Index for freshness queries (e.g. "find all chunks older than 90 days").
CREATE INDEX IF NOT EXISTS idx_law_chunks_refreshed
  ON public.law_chunks (corpus_refreshed_at);
