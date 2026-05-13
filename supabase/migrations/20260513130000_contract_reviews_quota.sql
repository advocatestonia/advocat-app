-- 20260513130000_contract_reviews_quota.sql
-- -----------------------------------------------------------------------------
-- Per-user quota state + async job tracking for Contract Review mode.
--
-- Two columns on a `user_quotas` row + two new tables:
--   1. user_quotas.contract_reviews_used      INT   — counter
--   2. user_quotas.contract_reviews_period_start TIMESTAMPTZ — billing window
--   3. public.contract_analysis_jobs          — async multi-doc job queue
--   4. public.contract_reviews                — finalized review record
--
-- Quota rules (enforced in the edge function, not via CHECK constraints so the
-- product team can re-tune without a schema bump):
--   free    : 1 lifetime contract review
--   basic   : 5 per 30-day rolling window
--   premium : 20 per 30-day rolling window
--
-- The 30-day window is anchored at `contract_reviews_period_start`. The edge
-- function resets the counter when (now() - period_start) > interval '30 days'.
--
-- Idempotency: every `IF NOT EXISTS`. Re-running this migration is a no-op.
-- -----------------------------------------------------------------------------

-- ── 1. user_quotas (create only if missing — keeps in sync with any earlier
--      partial deploys that already added the row) ───────────────────────────
CREATE TABLE IF NOT EXISTS public.user_quotas (
  user_id                        uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  contract_reviews_used          INT  NOT NULL DEFAULT 0,
  contract_reviews_period_start  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at                     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Defensive ALTERs so the migration is forward-compatible with any future
-- "user_quotas" table that already exists from another package.
ALTER TABLE public.user_quotas
  ADD COLUMN IF NOT EXISTS contract_reviews_used         INT         NOT NULL DEFAULT 0;
ALTER TABLE public.user_quotas
  ADD COLUMN IF NOT EXISTS contract_reviews_period_start TIMESTAMPTZ NOT NULL DEFAULT now();

ALTER TABLE public.user_quotas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "own quota row" ON public.user_quotas;
CREATE POLICY "own quota row" ON public.user_quotas
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ── 2. contract_reviews — finalized review records ─────────────────────────
CREATE TABLE IF NOT EXISTS public.contract_reviews (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id            uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  case_id            uuid REFERENCES public.user_cases(id) ON DELETE SET NULL,
  document_ids       uuid[] NOT NULL,
  output_language    text NOT NULL,
  jurisdiction_hint  text,
  industry_hint      text,
  client_name        text,
  client_company     text,
  score              INT,
  critical_risk_count INT NOT NULL DEFAULT 0,
  summary            text,
  email_md           text,
  pdf_storage_path   text,
  pdf_status         text NOT NULL DEFAULT 'pending'
                     CHECK (pdf_status IN ('ready','pending','worker_not_configured','failed')),
  raw_output         jsonb,
  created_at         timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_contract_reviews_user
  ON public.contract_reviews (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_contract_reviews_case
  ON public.contract_reviews (case_id) WHERE case_id IS NOT NULL;

ALTER TABLE public.contract_reviews ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "own contract reviews" ON public.contract_reviews;
CREATE POLICY "own contract reviews" ON public.contract_reviews
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ── 3. contract_analysis_jobs — async multi-doc queue (4-10 docs) ──────────
CREATE TABLE IF NOT EXISTS public.contract_analysis_jobs (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id            uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  document_ids       uuid[] NOT NULL,
  output_language    text NOT NULL,
  jurisdiction_hint  text,
  industry_hint      text,
  client_name        text,
  client_company     text,
  status             text NOT NULL DEFAULT 'queued'
                     CHECK (status IN ('queued','running','completed','failed')),
  contract_review_id uuid REFERENCES public.contract_reviews(id) ON DELETE SET NULL,
  error_message      text,
  created_at         timestamptz NOT NULL DEFAULT now(),
  started_at         timestamptz,
  finished_at        timestamptz
);

CREATE INDEX IF NOT EXISTS idx_contract_jobs_user_status
  ON public.contract_analysis_jobs (user_id, status, created_at DESC);

ALTER TABLE public.contract_analysis_jobs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "own contract jobs" ON public.contract_analysis_jobs;
CREATE POLICY "own contract jobs" ON public.contract_analysis_jobs
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

GRANT SELECT, INSERT, UPDATE ON public.user_quotas             TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.contract_reviews        TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.contract_analysis_jobs  TO authenticated;

COMMENT ON COLUMN public.user_quotas.contract_reviews_used IS
  'Counter incremented by contract-review edge function on success. Reset by the function when the 30-day window rolls over (basic/premium) or never (free).';
COMMENT ON TABLE public.contract_analysis_jobs IS
  'Async job queue for Contract Review runs spanning 4-10 documents. Returned to the client as 202 + job_id; a worker (TBD) drains the queue.';
COMMENT ON TABLE public.contract_reviews IS
  'Finalized Contract Review outputs. The pdf_storage_path + signed URL TTL is owned by the edge function — this row only records the path.';

-- PGRST schema cache reload — memory: reference_pitfalls_chat_infra.
NOTIFY pgrst, 'reload schema';
