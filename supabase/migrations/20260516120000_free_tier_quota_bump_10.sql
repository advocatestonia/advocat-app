-- =============================================================================
-- Migration: free-tier quota bump 7 → 10 (Bentley P8, 2026-05-16)
-- =============================================================================
--
-- Context (financial analyst, 2026-05-16):
--   * Avg conversation = 8 messages → old 7-cap cut users off before they
--     hit the "aha" moment, so most never converted.
--   * Conversion free → paid: 1-2% (legal AI baseline). Predicted 2-3x lift
--     by giving users two extra messages of headroom.
--
-- What ships:
--   * No schema change. The cap lives in the `check-ai-quota` Edge Function
--     (FREE_LIMIT = 10) and the mirrored Flutter constant
--     `AIService._freeTotalLimit = 10`. This migration exists so the change
--     is part of the canonical migration history and so a reviewer reading
--     `supabase/migrations/` can see the launch decision.
--   * The `public.ai_usage.count` column is per-month and already enforces
--     whatever ceiling the edge fn applies — no row change needed.
--
-- What stays at 7 (intentional):
--   * `supabase/functions/_shared/refund_policy.ts` MESSAGE_CAP — the
--     14-day OR 7-AI-responses refund window is a legal/financial promise
--     to PAYING users. Decoupling it from the free-tier UX cap is the
--     whole point of this migration.
--
-- Rollback:
--   * Set FREE_LIMIT back to 7 in
--     `supabase/functions/check-ai-quota/index.ts` and redeploy. Update
--     `lib/services/ai_service.dart::_freeTotalLimit` to match. No DB
--     work required.
-- =============================================================================

-- Optional: stamp the launch decision into the migrations audit log so we
-- can grep for it later. Safe to no-op if the comment column already
-- exists at the table level.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'ai_usage'
  ) THEN
    COMMENT ON TABLE public.ai_usage IS
      'Free-tier AI message counter. Cap is 10/month as of 2026-05-16 '
      '(Bentley P8 conversion bump). Enforced by check-ai-quota Edge Fn.';
  END IF;
END$$;
