-- Correspondence audit log: GDPR-required record of every outbound and inbound
-- email routed through the send-email / email-inbox-sync edge functions.
-- See supabase/functions/send-email/index.ts:447-464 (insert site).

CREATE TABLE IF NOT EXISTS public.correspondence (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  case_id uuid REFERENCES public.cases(id) ON DELETE SET NULL,
  direction text NOT NULL CHECK (direction IN ('outbound','inbound')),
  from_address text NOT NULL,
  to_address text NOT NULL,
  cc_address text,
  subject text NOT NULL,
  body text NOT NULL,
  provider text NOT NULL CHECK (provider IN ('gmail_user','resend_fallback','gmail_inbound')),
  provider_message_id text,
  sent_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.correspondence ENABLE ROW LEVEL SECURITY;

-- Users can read their own correspondence.
DROP POLICY IF EXISTS "Users read own correspondence" ON public.correspondence;
CREATE POLICY "Users read own correspondence"
  ON public.correspondence FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Authenticated users cannot insert directly — only service-role (used by the
-- send-email and email-inbox-sync edge functions) bypasses RLS for INSERT.
-- No INSERT policy for authenticated/anon is defined on purpose.

CREATE INDEX IF NOT EXISTS idx_correspondence_user_sent
  ON public.correspondence (user_id, sent_at DESC);

CREATE INDEX IF NOT EXISTS idx_correspondence_case_sent
  ON public.correspondence (case_id, sent_at DESC)
  WHERE case_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_correspondence_provider_msg_id
  ON public.correspondence (provider_message_id)
  WHERE provider_message_id IS NOT NULL;

COMMENT ON TABLE public.correspondence IS
  'GDPR audit log of all outbound and inbound emails routed through send-email/email-inbox-sync edge fns. Required for compliance — every email sent on behalf of a user MUST be logged here.';
