-- GDPR Article 28 — DPA acceptance audit table.
-- One row per (user, dpa_version) records that the customer signed the
-- clickwrap DPA. The create-checkout edge function refuses to mint a
-- Stripe session unless a matching row exists for the current version
-- string (see supabase/functions/create-checkout/index.ts CURRENT_DPA_VERSION).

CREATE TABLE IF NOT EXISTS public.dpa_acceptances (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  dpa_version text NOT NULL,
  accepted_at timestamptz NOT NULL DEFAULT now(),
  ip_address inet,
  user_agent text,
  accepted_via text NOT NULL DEFAULT 'checkout'
    CHECK (accepted_via IN ('checkout', 'reupgrade', 'admin')),
  UNIQUE (user_id, dpa_version)
);

ALTER TABLE public.dpa_acceptances ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users read own dpa acceptances" ON public.dpa_acceptances;
CREATE POLICY "Users read own dpa acceptances"
  ON public.dpa_acceptances
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users insert own dpa acceptance" ON public.dpa_acceptances;
CREATE POLICY "Users insert own dpa acceptance"
  ON public.dpa_acceptances
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_dpa_acceptances_user_version
  ON public.dpa_acceptances (user_id, dpa_version);

COMMENT ON TABLE public.dpa_acceptances IS
  'GDPR Art. 28 record of customer DPA acceptances. Must have a row per (user, current_dpa_version) BEFORE allowing paid checkout.';
