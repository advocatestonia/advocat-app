-- 20260616101500_case_estimates.sql
-- -----------------------------------------------------------------------------
-- Feature #6 — Case Cost & Risk Estimator.
--
-- Stores the structured output of the `estimate-case` edge function so users
-- can review their estimate history, and so we can later calibrate the model
-- against real outcomes via an opt-in feedback signal.
--
-- ⚠️  PII / GDPR Art.17: `public.case_estimates` carries `user_id`. It MUST be
--     added to the account-delete table sweep. The delete path uses an
--     ON DELETE CASCADE FK to auth.users(id), so a hard user delete removes
--     these rows automatically — no separate enumeration needed. Noted here
--     for the coordinator in case account-delete uses an explicit allowlist.
--
-- This is an *estimate*, NOT a guarantee — see the disclaimer baked into the
-- edge-function output. We never store a "% chance of winning"; the strength
-- signal is a coarse traffic-light enum only.
--
-- Idempotency: every `IF NOT EXISTS`. Re-running is a no-op.
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.case_estimates (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id            uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- ── Inputs the user supplied ──────────────────────────────────────────
  case_type          text NOT NULL,
  jurisdiction       text NOT NULL,
  dispute_amount_eur numeric,           -- nullable: not all matters are monetary
  description        text,
  b2b_mode           boolean NOT NULL DEFAULT false,

  -- ── Structured estimate the model produced ────────────────────────────
  -- Cost ranges are stored as low/high integer EUR so the UI can render a
  -- band rather than a single (false-precision) point.
  court_fee_low_eur  integer,
  court_fee_high_eur integer,
  lawyer_fee_low_eur integer,
  lawyer_fee_high_eur integer,
  total_low_eur      integer,
  total_high_eur     integer,

  duration_low_months  integer,
  duration_high_months integer,

  -- Coarse strength signal — NEVER a probability. Traffic-light only.
  strength           text NOT NULL DEFAULT 'contested'
                     CHECK (strength IN ('worth_pursuing','contested','weak')),

  factors_for        jsonb NOT NULL DEFAULT '[]'::jsonb,
  factors_against    jsonb NOT NULL DEFAULT '[]'::jsonb,
  recommendation     text,
  next_step          text,

  raw_output         jsonb,

  -- ── Calibration feedback (opt-in, set later by the user) ──────────────
  -- 'helpful' | 'too_high' | 'too_low' | 'inaccurate' — used offline to
  -- tune prompt heuristics. Nullable until the user rates the estimate.
  feedback           text
                     CHECK (feedback IS NULL OR feedback IN
                       ('helpful','too_high','too_low','inaccurate')),
  feedback_at        timestamptz,

  created_at         timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_case_estimates_user
  ON public.case_estimates (user_id, created_at DESC);

ALTER TABLE public.case_estimates ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "own case estimates" ON public.case_estimates;
CREATE POLICY "own case estimates" ON public.case_estimates
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

GRANT SELECT, INSERT, UPDATE ON public.case_estimates TO authenticated;

COMMENT ON TABLE public.case_estimates IS
  'Feature #6 Case Cost & Risk Estimator. Stores rough cost/duration bands + '
  'coarse strength signal + calibration feedback. PII (user_id) — covered by '
  'ON DELETE CASCADE for GDPR Art.17. Estimates are NOT guarantees.';
COMMENT ON COLUMN public.case_estimates.strength IS
  'Coarse traffic-light only (worth_pursuing/contested/weak). NEVER a win %.';
COMMENT ON COLUMN public.case_estimates.feedback IS
  'Opt-in calibration signal set after the user rates the estimate.';

-- PGRST schema cache reload — memory: reference_pitfalls_chat_infra.
NOTIFY pgrst, 'reload schema';
