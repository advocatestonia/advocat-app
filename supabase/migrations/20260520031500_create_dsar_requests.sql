-- GDPR Art. 15 / 17 / 16 / 21 / 20 / 18 — Data Subject Access Request audit log.
-- One row per request (export, erasure, rectification, objection, portability,
-- restriction). Required by Art. 12(3): controller must keep records and reply
-- within 30 days. The dsar-export edge function inserts a row before/after
-- every export so we have a tamper-evident audit trail.
--
-- Read access is RLS-scoped to the requesting user — the user must be able to
-- see their own DSAR history (Art. 15(1)(c)). Inserts are also user-scoped:
-- the edge fn passes the auth-context UID via service-role but the policy
-- still validates `auth.uid() = user_id` to make manual / DB-direct misuse
-- impossible. Updates (status flip from `pending` → `completed`) happen via
-- service-role inside the edge fn — no UPDATE policy for authenticated.

CREATE TABLE IF NOT EXISTS public.dsar_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  request_type text NOT NULL
    CHECK (request_type IN ('export','erasure','rectification','objection','portability','restriction')),
  status text NOT NULL
    CHECK (status IN ('pending','completed','partial','denied'))
    DEFAULT 'pending',
  requested_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz,
  notes text,
  ip_address inet,
  user_agent text
);

ALTER TABLE public.dsar_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users read own dsar requests" ON public.dsar_requests;
CREATE POLICY "Users read own dsar requests"
  ON public.dsar_requests
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users insert own dsar request" ON public.dsar_requests;
CREATE POLICY "Users insert own dsar request"
  ON public.dsar_requests
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_dsar_user_requested
  ON public.dsar_requests (user_id, requested_at DESC);

COMMENT ON TABLE public.dsar_requests IS
  'GDPR Art. 12(3) audit log of Data Subject Access Requests (export, erasure, rectification, objection, portability, restriction). Inserted by dsar-export and related self-service edge functions. Required for compliance — Art. 12(3) mandates a 30-day response and a tamper-evident record.';
