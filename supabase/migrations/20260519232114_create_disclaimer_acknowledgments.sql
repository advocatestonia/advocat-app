-- UPL / Bar Act §41 audit table — records every dismissal of the
-- chat "not your lawyer / not legal advice" banner.
--
-- One row per (user, disclaimer_version, UTC-day) so we can prove that
-- the user was informed on the day they used the product. The Bar Act
-- (advokatuuriseadus) §41 prohibits holding out as an advokaat without
-- a licence; the EU Consumer Rights Directive + Estonian Consumer
-- Protection Act require clarity about what the user is paying for.
-- A defensible record means: if a regulator (or a disgruntled user)
-- ever asks, we can point to a timestamped row per active day.
--
-- The `disclaimer_version` lets us roll forward without losing history
-- when the legal text changes (e.g. v1.0-2026-05-20 → v1.1-2026-09-01).

CREATE TABLE IF NOT EXISTS public.disclaimer_acknowledgments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  disclaimer_version text NOT NULL DEFAULT 'v1.0-2026-05-20',
  acknowledged_at timestamptz NOT NULL DEFAULT now(),
  ip_address inet,
  user_agent text
);

-- Day-bucketed uniqueness: one ack per (user, version, calendar day in UTC).
-- We use a UNIQUE INDEX on a DATE() expression because PostgreSQL does not
-- allow function calls inside an inline UNIQUE constraint.
CREATE UNIQUE INDEX IF NOT EXISTS uq_disclaimer_acks_user_version_day
  ON public.disclaimer_acknowledgments (
    user_id,
    disclaimer_version,
    (DATE(acknowledged_at AT TIME ZONE 'UTC'))
  );

CREATE INDEX IF NOT EXISTS idx_disclaimer_acks_user_recent
  ON public.disclaimer_acknowledgments (user_id, acknowledged_at DESC);

ALTER TABLE public.disclaimer_acknowledgments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users read own ack" ON public.disclaimer_acknowledgments;
CREATE POLICY "Users read own ack"
  ON public.disclaimer_acknowledgments
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users insert own ack" ON public.disclaimer_acknowledgments;
CREATE POLICY "Users insert own ack"
  ON public.disclaimer_acknowledgments
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

COMMENT ON TABLE public.disclaimer_acknowledgments IS
  'UPL / Estonian Bar Act §41 audit log: one row per user/disclaimer_version/UTC-day when the "not your lawyer / not legal advice" chat banner is dismissed.';
