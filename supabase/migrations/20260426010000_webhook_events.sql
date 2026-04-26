-- Webhook idempotency + audit log.
-- ----------------------------------------------------------------------------
-- Stripe webhooks have four silent-failure modes:
--   1. Webhook never reaches us           — Stripe retry queue handles this
--   2. Function 5xx                       — Stripe retries up to 3 days
--   3. 2xx returned but DB write failed   — NO RETRY, ROW LOST  (this fix)
--   4. Idempotency violated, double-write — possible with retries
--
-- This table closes #3 and #4. The webhook handler:
--   a. Looks up event.id in this table on entry; if status='ok', skips and
--      returns 200 (no-op for retries).
--   b. Inserts row with status='processing' before doing any work.
--   c. After the DB writes complete AND verification succeeds, updates to
--      status='ok'. If verification or the write itself fails, status='error'
--      and the function returns 5xx so Stripe will retry.
--
-- Service role bypasses RLS, so no SELECT/INSERT/UPDATE policies are needed
-- for the webhook function. RLS is still enabled to deny anon/authenticated
-- access by default (this table contains PII-adjacent metadata).
-- ----------------------------------------------------------------------------

create table if not exists public.webhook_events (
  event_id text primary key,                        -- Stripe event.id (evt_...)
  event_type text not null,                         -- e.g. checkout.session.completed
  received_at timestamptz not null default now(),
  status text not null default 'processing',        -- processing | ok | error
  user_id uuid,                                     -- resolved user (when applicable)
  error_message text,                               -- truncated to 500 chars
  retry_count int not null default 0,
  updated_at timestamptz not null default now()
);

create index if not exists webhook_events_status_idx
  on public.webhook_events (status, received_at desc);

create index if not exists webhook_events_event_type_idx
  on public.webhook_events (event_type, received_at desc);

alter table public.webhook_events enable row level security;
-- service-role only writes, no user-facing policy needed

-- Atomic increment helper for retry_count (used in the catch block so we
-- don't race with concurrent retries from Stripe).
create or replace function public.increment_webhook_retry_count(p_event_id text)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int;
begin
  update public.webhook_events
     set retry_count = retry_count + 1,
         updated_at  = now()
   where event_id = p_event_id
  returning retry_count into v_count;
  return coalesce(v_count, 0);
end;
$$;

revoke all on function public.increment_webhook_retry_count(text) from public;
grant execute on function public.increment_webhook_retry_count(text) to service_role;

comment on table public.webhook_events is
  'Stripe webhook idempotency + audit log. Service-role only. See migration header.';
