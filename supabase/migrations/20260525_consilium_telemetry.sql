-- 20260525_consilium_telemetry.sql
-- =====================================================================
-- CONSILIUM TELEMETRY + Pro-tier cost-protection quota.
--
-- Three pieces:
--   1) consilium_runs        — append-only log row per consilium invocation.
--      Captures user, query hash (sha256 — never raw query), language,
--      case_type, jurisdiction set, expert roster, round count, latency,
--      cost, model/fallback-chain, disagreement flag. Powers cost
--      analytics + per-user quota.
--   2) RLS policies          — owner reads only own rows; service role
--      (edge fn writes) bypasses RLS.
--   3) RPC get_user_consilium_count_this_month — month-to-date count
--      used by claude-proxy BEFORE consilium dispatch to enforce
--      PRO_CONSILIUM_QUOTA (env-tunable, default 30).
--
-- Cost protection math:
--   Pro €29.99/mo, consilium ~$0.05–0.20/run. 30 × $0.20 = $6/mo
--   ceiling → 80% margin. Beyond cap → degrade to single-call.
--
-- Author: ops | Date: 2026-05-25
-- =====================================================================

CREATE TABLE IF NOT EXISTS public.consilium_runs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  is_anon BOOLEAN NOT NULL DEFAULT false,
  query_hash TEXT NOT NULL,            -- sha256(query) — enables dedup analysis without storing PII
  query_language TEXT,
  case_type TEXT,
  jurisdictions TEXT[],
  experts_invoked TEXT[],
  experts_count INT NOT NULL,
  rounds_executed INT DEFAULT 1,
  total_latency_ms INT,
  total_cost_cents INT,
  model_used TEXT,
  fallback_chain TEXT[],
  disagreement_detected BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Hot path: month-to-date count per user (RPC below).
-- `created_at::date` is STABLE (TZ-dependent), not IMMUTABLE, and Postgres
-- refuses to index it. Use a plain composite (user_id, created_at) — the
-- planner range-scans the month window with this just as efficiently.
CREATE INDEX IF NOT EXISTS idx_consilium_runs_user_created
  ON public.consilium_runs (user_id, created_at DESC);

-- Latest activity feed (admin dashboard).
CREATE INDEX IF NOT EXISTS idx_consilium_runs_created
  ON public.consilium_runs (created_at DESC);

-- Case-type breakdown for product analytics.
CREATE INDEX IF NOT EXISTS idx_consilium_runs_case_type
  ON public.consilium_runs (case_type);

ALTER TABLE public.consilium_runs ENABLE ROW LEVEL SECURITY;

-- Users see only their own runs.
DROP POLICY IF EXISTS "Users see own consilium runs" ON public.consilium_runs;
CREATE POLICY "Users see own consilium runs"
  ON public.consilium_runs FOR SELECT
  USING (auth.uid() = user_id);

-- Service role full access (writes from edge fn — anon key/service role bypass).
DROP POLICY IF EXISTS "Service role full access" ON public.consilium_runs;
CREATE POLICY "Service role full access"
  ON public.consilium_runs FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role');

-- RPC: month-to-date consilium count for a user.
-- SECURITY DEFINER so the RPC bypasses RLS (the count itself is metadata,
-- not PII — caller needs to know their own count to enforce the cap).
CREATE OR REPLACE FUNCTION public.get_user_consilium_count_this_month(p_user_id UUID)
RETURNS INT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COUNT(*)::INT
  FROM public.consilium_runs
  WHERE user_id = p_user_id
    AND created_at >= date_trunc('month', now())
    AND created_at <  date_trunc('month', now()) + interval '1 month';
$$;

GRANT EXECUTE ON FUNCTION public.get_user_consilium_count_this_month(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_consilium_count_this_month(UUID) TO service_role;

COMMENT ON TABLE  public.consilium_runs IS 'Append-only telemetry: every consilium invocation. RLS: owner sees own rows.';
COMMENT ON COLUMN public.consilium_runs.query_hash IS 'sha256(query) hex — never store raw query (privilege).';
COMMENT ON COLUMN public.consilium_runs.total_cost_cents IS 'Estimated Anthropic spend for this run, integer cents.';
COMMENT ON FUNCTION public.get_user_consilium_count_this_month(UUID) IS
  'Powers PRO_CONSILIUM_QUOTA gate in claude-proxy. SECURITY DEFINER — bypasses RLS for count-only metadata.';
