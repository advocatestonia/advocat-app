-- ai_usage table — tracks free-tier message consumption per user per month.
-- Referenced by get_ai_usage() and increment_ai_usage() RPCs in check-ai-quota.
-- Table was missing from prod, causing check-ai-quota to error for all users
-- and fall back to AiQuota.denied — blocking even paying Pro users.

CREATE TABLE IF NOT EXISTS public.ai_usage (
  user_id    uuid        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  count      integer     NOT NULL DEFAULT 0,
  month      date        NOT NULL DEFAULT date_trunc('month', now())::date,
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.ai_usage ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'ai_usage' AND policyname = 'ai_usage_own'
  ) THEN
    CREATE POLICY ai_usage_own ON public.ai_usage FOR ALL USING (auth.uid() = user_id);
  END IF;
END$$;

GRANT SELECT, INSERT, UPDATE ON public.ai_usage TO authenticated;
