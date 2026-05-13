-- =============================================================================
-- 20260514120000_gold_corpus.sql — Sofia Gold Corpus, Phase A.
-- =============================================================================
-- Two tables that together capture Sofia's review of AI answers into a
-- proprietary training corpus.
--
--   gold_corpus_queue  — mutable working tray. AI answers land here as 'pending'.
--                        May contain PII pre-scrub. Service-role only. Sofia
--                        reviews this table.
--   gold_corpus_pairs  — curated, immutable dataset. One row per Sofia
--                        decision (approve/edit/reject/skip). Pairs created
--                        only on approved/edited; rejected/skipped also
--                        recorded for analytics.
--
-- Phase B (not built yet) will add: pgvector embedding on user_question,
-- few-shot retrieval RPC, eval A/B gate, export endpoint.
-- =============================================================================

-- ─── Queue: mutable working tray, service-role only ─────────────────────────
CREATE TABLE IF NOT EXISTS public.gold_corpus_queue (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Provenance (raw, used pre-scrub only — no FKs because chat_messages may
  -- be GC'd before a queue row is reviewed).
  source_message_id     UUID,
  source_user_id        UUID,

  -- The pair (raw, may contain PII until pii_scrubbed=true).
  user_question         TEXT NOT NULL,
  ai_answer             TEXT NOT NULL,

  -- Best-effort classification (filled by scrubber Haiku pass).
  ai_model              TEXT,
  ai_citations          TEXT[],
  language              TEXT,
  category              TEXT,
  jurisdiction          TEXT DEFAULT 'estonia',

  -- PII pipeline state.
  pii_scrubbed          BOOLEAN NOT NULL DEFAULT false,
  scrub_attempted_at    TIMESTAMPTZ,
  scrub_error           TEXT,
  pii_replacements      JSONB,   -- {"[NAME]": 2, "[PHONE]": 1}

  -- Marked true once Sofia processes the row (any of approve/edit/reject/skip).
  added_to_pairs        BOOLEAN NOT NULL DEFAULT false
);

CREATE INDEX IF NOT EXISTS idx_queue_unscrubbed
  ON public.gold_corpus_queue(created_at)
  WHERE pii_scrubbed = false;

CREATE INDEX IF NOT EXISTS idx_queue_ready_for_review
  ON public.gold_corpus_queue(created_at DESC)
  WHERE pii_scrubbed = true AND added_to_pairs = false;

ALTER TABLE public.gold_corpus_queue ENABLE ROW LEVEL SECURITY;

-- Service-role only. The gold-review edge fn auths the caller against the
-- GOLD_REVIEWER_IDS allowlist, then escalates to service-role for writes.
DROP POLICY IF EXISTS "queue service role only" ON public.gold_corpus_queue;
CREATE POLICY "queue service role only"
  ON public.gold_corpus_queue FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- ─── Curated pairs: one row per Sofia decision ──────────────────────────────
CREATE TABLE IF NOT EXISTS public.gold_corpus_pairs (
  id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),
  reviewed_at                 TIMESTAMPTZ,
  reviewer_id                 UUID REFERENCES auth.users(id),

  source_queue_id             UUID REFERENCES public.gold_corpus_queue(id) ON DELETE SET NULL,

  user_question               TEXT NOT NULL,    -- scrubbed
  ai_answer                   TEXT NOT NULL,    -- scrubbed, model's original answer
  gold_answer                 TEXT,             -- approve: = ai_answer; edit: Sofia's text; reject/skip: NULL

  ai_model                    TEXT,
  ai_citations                TEXT[],
  language                    TEXT,
  category                    TEXT,
  jurisdiction                TEXT DEFAULT 'estonia',

  status                      TEXT NOT NULL
                              CHECK (status IN ('approved','edited','rejected','skipped')),
  rejection_reason            TEXT
                              CHECK (rejection_reason IS NULL OR rejection_reason IN
                                ('wrong_law','hallucination','wrong_tone','off_topic','outdated','other')),
  reviewer_notes              TEXT,

  ai_answer_token_count       INTEGER,
  gold_answer_token_count     INTEGER,
  edit_similarity             NUMERIC,          -- 0..1, NULL for non-edited

  UNIQUE (source_queue_id)                      -- one curated pair per queue row
);

CREATE INDEX IF NOT EXISTS idx_pairs_status_category
  ON public.gold_corpus_pairs(status, category, jurisdiction);
CREATE INDEX IF NOT EXISTS idx_pairs_reviewed_at
  ON public.gold_corpus_pairs(reviewed_at DESC);

ALTER TABLE public.gold_corpus_pairs ENABLE ROW LEVEL SECURITY;

-- Read/write only via service-role. Reviewer gating happens in the edge fn.
-- (No public/authenticated read policies — keeps the dataset locked down
-- until Phase B introduces a sanitised retrieval RPC.)
DROP POLICY IF EXISTS "pairs service role only" ON public.gold_corpus_pairs;
CREATE POLICY "pairs service role only"
  ON public.gold_corpus_pairs FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- ─── Stats view ─────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW public.gold_corpus_stats AS
SELECT
  COUNT(*) FILTER (WHERE status = 'approved')                                  AS total_approved,
  COUNT(*) FILTER (WHERE status = 'edited')                                    AS total_edited,
  COUNT(*) FILTER (WHERE status = 'rejected')                                  AS total_rejected,
  COUNT(*) FILTER (WHERE status = 'skipped')                                   AS total_skipped,
  COUNT(*) FILTER (WHERE reviewed_at > NOW() - INTERVAL '24 hours')            AS reviewed_today,
  COUNT(*) FILTER (WHERE reviewed_at > NOW() - INTERVAL '7 days')              AS reviewed_this_week,
  COUNT(*) FILTER (WHERE reviewed_at > NOW() - INTERVAL '30 days')             AS reviewed_this_month,
  AVG(edit_similarity) FILTER (WHERE status = 'edited')                        AS avg_edit_similarity,
  (SELECT COUNT(*) FROM public.gold_corpus_queue
    WHERE pii_scrubbed = true AND added_to_pairs = false)                      AS pending_review,
  (SELECT COUNT(*) FROM public.gold_corpus_queue
    WHERE pii_scrubbed = false)                                                AS pending_scrub
FROM public.gold_corpus_pairs;

GRANT SELECT ON public.gold_corpus_stats TO service_role;
