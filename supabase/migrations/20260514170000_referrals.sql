-- =============================================================================
-- 20260514170000_referrals.sql — referral program ("звать друзей" loop).
-- =============================================================================
-- Two tables backing the referral edge function + Stripe webhook integration:
--
--   referral_codes        — one row per user; holds their unique invite code
--                           and lifetime aggregate stats (denormalised — we
--                           bump from the webhook on conversion).
--   referral_attributions — one row per referred user; tracks the lifecycle
--                           attributed → converted → credited (or abuse_blocked).
--
-- Core mechanic (codified in supabase/functions/stripe-webhook):
--   * Friend signs up via /r/<code> → attribution row created (status='attributed').
--   * Friend converts to paid Pro/Premium → status='converted', friend gets a
--     30-day Stripe coupon, inviter scheduled for next-renewal credit.
--   * Credit applied to inviter → status='credited', free_month_credited_at set.
--   * Anti-abuse cap: max 12 credited rows per inviter per rolling 365 days.
--     Excess attempts land in status='abuse_blocked' (no credit issued).
--
-- Constraints enforced at the DB layer:
--   * One referral code per user (UNIQUE on user_id).
--   * One attribution row per referred user (UNIQUE on referred_user_id) —
--     self-referrals and "swap inviters after the fact" are both impossible.
--   * No self-referral (CHECK inviter_user_id != referred_user_id).
--
-- RLS posture mirrors the support_tickets shape: users can SELECT their own,
-- service_role does all writes from the edge function.
-- =============================================================================

-- ─── referral_codes ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.referral_codes (
  id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                     UUID NOT NULL UNIQUE
                              REFERENCES auth.users(id) ON DELETE CASCADE,
  code                        TEXT NOT NULL UNIQUE
                              CHECK (length(code) BETWEEN 6 AND 16
                                     AND code ~ '^[a-z0-9]+$'),
  created_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),
  total_invites_sent          INT NOT NULL DEFAULT 0,
  total_conversions           INT NOT NULL DEFAULT 0,
  total_free_months_earned    INT NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS referral_codes_code_idx
  ON public.referral_codes (code);

ALTER TABLE public.referral_codes ENABLE ROW LEVEL SECURITY;

-- A user can read their own code row (for the Invite-friends screen).
CREATE POLICY "user reads own code"
  ON public.referral_codes
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Anyone (including anon) can resolve a code → inviter for /r/<code> landing.
-- The row leaks only the code itself and aggregate stats — no PII. The
-- inviter user_id IS returned but is an opaque UUID; without a separate
-- profile join (RLS-protected) it is not actionable.
CREATE POLICY "anyone resolves code"
  ON public.referral_codes
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- Writes only from the edge function (service_role bypasses RLS, but we
-- spell it out so the policy intent is explicit in the schema).
CREATE POLICY "service writes codes"
  ON public.referral_codes
  FOR INSERT
  TO service_role
  WITH CHECK (true);

CREATE POLICY "service updates codes"
  ON public.referral_codes
  FOR UPDATE
  TO service_role
  USING (true);

GRANT SELECT ON public.referral_codes TO anon, authenticated;

COMMENT ON TABLE public.referral_codes IS
  'One invite code per user. Stats columns bumped by stripe-webhook on conversion.';


-- ─── referral_attributions ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.referral_attributions (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Who invited whom. inviter is the existing user; referred is the new one.
  -- NOT NULL — every attribution must name both sides.
  inviter_user_id          UUID NOT NULL
                           REFERENCES auth.users(id) ON DELETE CASCADE,
  referred_user_id         UUID NOT NULL
                           REFERENCES auth.users(id) ON DELETE CASCADE,

  -- The code that was used at signup. Denormalised for analytics — looking
  -- up via inviter_user_id alone is sufficient for the credit flow.
  referral_code            TEXT NOT NULL
                           REFERENCES public.referral_codes(code)
                           ON DELETE RESTRICT,

  attributed_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  converted_at             TIMESTAMPTZ,
  free_month_credited_at   TIMESTAMPTZ,

  -- Lifecycle. abuse_blocked is set when the inviter's rolling 365-day
  -- credited count is already at 12.
  status                   TEXT NOT NULL DEFAULT 'attributed'
                           CHECK (status IN
                             ('attributed', 'converted', 'credited',
                              'abuse_blocked')),

  -- Free-form metadata (Stripe coupon ids, balance txn ids, etc.).
  metadata                 JSONB NOT NULL DEFAULT '{}'::jsonb,

  CONSTRAINT no_self_referral
    CHECK (inviter_user_id <> referred_user_id),

  -- Hard guarantee: a referred user can only ever be claimed once.
  -- Subsequent /referral/attribute calls for the same user become no-ops.
  CONSTRAINT unique_referred
    UNIQUE (referred_user_id)
);

CREATE INDEX IF NOT EXISTS referral_attributions_inviter_idx
  ON public.referral_attributions (inviter_user_id);

CREATE INDEX IF NOT EXISTS referral_attributions_status_idx
  ON public.referral_attributions (status);

-- Supports the anti-abuse "12 credited per 365 days" query (filters on
-- inviter + status='credited' + window on free_month_credited_at).
CREATE INDEX IF NOT EXISTS referral_attributions_credit_window_idx
  ON public.referral_attributions (inviter_user_id, free_month_credited_at)
  WHERE status = 'credited';

ALTER TABLE public.referral_attributions ENABLE ROW LEVEL SECURITY;

-- A user can read attributions where they are either side.
CREATE POLICY "user reads own attributions"
  ON public.referral_attributions
  FOR SELECT
  TO authenticated
  USING (auth.uid() = inviter_user_id OR auth.uid() = referred_user_id);

CREATE POLICY "service writes attributions"
  ON public.referral_attributions
  FOR INSERT
  TO service_role
  WITH CHECK (true);

CREATE POLICY "service updates attributions"
  ON public.referral_attributions
  FOR UPDATE
  TO service_role
  USING (true);

GRANT SELECT ON public.referral_attributions TO authenticated;

COMMENT ON TABLE public.referral_attributions IS
  'Per-referred-user lifecycle row. Stripe-webhook flips status on conversion.';


-- ─── get_or_create_referral_code(p_user_id) ─────────────────────────────────
-- Idempotent helper used by /referral/code. Generates an 8-char lowercase
-- alphanumeric on first call; returns the existing code thereafter.
--
-- Collision handling: md5(random()) collisions on 8 hex chars are
-- ~1 in 4 billion, but a retry loop is cheap insurance. We give up after
-- 5 attempts; the caller can retry the whole RPC if that ever happens.
-- =============================================================================
CREATE OR REPLACE FUNCTION public.get_or_create_referral_code(p_user_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_code     TEXT;
  v_attempt  INT := 0;
BEGIN
  -- Fast path: existing code.
  SELECT code INTO v_code
    FROM public.referral_codes
   WHERE user_id = p_user_id;

  IF v_code IS NOT NULL THEN
    RETURN v_code;
  END IF;

  -- Generate. Retry on collision (extremely unlikely; see header comment).
  WHILE v_attempt < 5 LOOP
    v_code := lower(substring(
                md5(random()::text || p_user_id::text || clock_timestamp()::text)
              FROM 1 FOR 8));
    BEGIN
      INSERT INTO public.referral_codes (user_id, code)
        VALUES (p_user_id, v_code);
      RETURN v_code;
    EXCEPTION
      WHEN unique_violation THEN
        -- Either user_id race (another worker inserted simultaneously) or
        -- code collision. Re-read user_id first; if that won, return it.
        SELECT code INTO v_code
          FROM public.referral_codes
         WHERE user_id = p_user_id;
        IF v_code IS NOT NULL THEN
          RETURN v_code;
        END IF;
        v_attempt := v_attempt + 1;
    END;
  END LOOP;

  RAISE EXCEPTION
    'get_or_create_referral_code: 5 collisions for user %', p_user_id
    USING ERRCODE = 'unique_violation';
END;
$$;

REVOKE ALL ON FUNCTION public.get_or_create_referral_code(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_or_create_referral_code(UUID)
  TO service_role;

COMMENT ON FUNCTION public.get_or_create_referral_code(UUID) IS
  'Returns the user''s referral code, generating one on first call. Service-role only.';
