-- 20260513120000_support_tickets.sql
-- -----------------------------------------------------------------------------
-- Support / feedback ticket store. Receives form submissions from the
-- Flutter SupportFab widget via the `support-ticket` edge function and
-- records Telegram delivery state.
--
-- Design notes:
--   * Anonymous and authenticated users can both submit (CTA visible on
--     every screen, including landing). RLS INSERT policy is permissive;
--     anti-abuse lives in the edge function (rate limit, honeypot, length).
--   * Authenticated users can SELECT only their own tickets — used by a
--     future "My support requests" settings panel.
--   * `telegram_sent` and `telegram_error` track delivery so a future cron
--     can retry failed Telegram pushes without losing the ticket.
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.support_tickets (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at      timestamptz NOT NULL DEFAULT now(),

  user_id         uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  email           text,
  category        text CHECK (category IN ('bug','payment','question','feature','other')),
  message         text NOT NULL CHECK (length(message) BETWEEN 10 AND 2000),
  contact_channel text CHECK (contact_channel IN ('in_app','whatsapp','email')),

  user_agent      text,
  page_url        text,
  app_version     text,
  language        text,
  ip_address      inet,

  telegram_sent   boolean DEFAULT false,
  telegram_error  text,

  status          text DEFAULT 'open'
                  CHECK (status IN ('open','in_progress','resolved','closed'))
);

ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;

-- Users (anon + authenticated) can insert tickets. Abuse guards live in the
-- edge function (rate limit, honeypot, length checks).
CREATE POLICY "Users can create support tickets" ON public.support_tickets
  FOR INSERT TO authenticated, anon WITH CHECK (true);

-- Authenticated users can read only their own tickets.
CREATE POLICY "Users can read own tickets" ON public.support_tickets
  FOR SELECT TO authenticated USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_support_tickets_created_at
  ON public.support_tickets (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_support_tickets_status
  ON public.support_tickets (status) WHERE status = 'open';

GRANT INSERT, SELECT ON public.support_tickets TO authenticated, anon;

COMMENT ON TABLE public.support_tickets IS
  'Inbound support / feedback tickets. Created by support-ticket edge fn. Telegram delivery tracked.';
