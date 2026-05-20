-- GDPR Article 9 — special-category personal data explicit consent audit table.
--
-- Art. 9(1) prohibits processing of health records, criminal-conviction data,
-- biometric data, racial/ethnic origin, religion, political opinions,
-- trade-union membership and sexual orientation UNLESS one of the Art. 9(2)
-- exceptions applies. For Advocat the relevant ground is Art. 9(2)(a):
-- "explicit consent of the data subject". We record one row per (user, version)
-- the FIRST time the user uploads ANY document (court ruling, medical
-- certificate, criminal record, police report) — these are de-facto special
-- category until parsed otherwise.
--
-- Row lifecycle:
--   * INSERT on first consent (granted_at set, withdrawn_at NULL).
--   * UPDATE withdrawn_at when the user revokes from Settings.
--   * NEVER DELETE — the audit trail must outlive the consent (supervisory
--     authority can request proof we had a lawful basis at the time data was
--     processed). ON DELETE CASCADE from auth.users is the only purge.
--
-- The Flutter `ensureSensitiveConsent()` gate keys off
-- `withdrawn_at IS NULL` to decide whether a new dialog is required.

CREATE TABLE IF NOT EXISTS public.sensitive_consents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  consent_version text NOT NULL DEFAULT 'v1.0-2026-05-20',
  granted_at timestamptz NOT NULL DEFAULT now(),
  -- NULL while consent is active; set to revocation timestamp on withdraw.
  withdrawn_at timestamptz,
  ip_address inet,
  user_agent text,
  categories text[] NOT NULL DEFAULT ARRAY[
    'health',
    'criminal',
    'biometric',
    'racial',
    'religious',
    'political',
    'trade_union',
    'sexual'
  ],
  legal_basis text NOT NULL DEFAULT 'gdpr_art_9_2_a_explicit_consent'
);

ALTER TABLE public.sensitive_consents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users read own sensitive consent" ON public.sensitive_consents;
CREATE POLICY "Users read own sensitive consent"
  ON public.sensitive_consents
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users insert own sensitive consent" ON public.sensitive_consents;
CREATE POLICY "Users insert own sensitive consent"
  ON public.sensitive_consents
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users withdraw own sensitive consent" ON public.sensitive_consents;
CREATE POLICY "Users withdraw own sensitive consent"
  ON public.sensitive_consents
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Fast lookup of the "is there an active consent for this user?" gate.
CREATE INDEX IF NOT EXISTS idx_sensitive_consents_user_active
  ON public.sensitive_consents (user_id)
  WHERE withdrawn_at IS NULL;

COMMENT ON TABLE public.sensitive_consents IS
  'GDPR Art. 9(2)(a) explicit consent audit trail for processing special-category personal data (health, criminal, biometric, racial, religious, political, trade-union, sexual). One active row (withdrawn_at IS NULL) gates upload UI in the Flutter app.';
