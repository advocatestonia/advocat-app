-- =====================================================================
-- launch/wave1 — Agent 1-6: Error telemetry (Sentry-lite, self-hosted)
-- =====================================================================
-- Purpose
--   Give the Advocat error boundary a place to persist non-fatal
--   exceptions so the owner can see production issues without
--   subscribing to a paid error-tracking SaaS.
--
-- Design decisions
--   * One flat, append-only table — no joins, no retention tracking.
--   * Stores NO user_id and NO request body. We deliberately avoid PII
--     because the boundary runs before we know whether the user has
--     opted into telemetry. Rotating UUIDs identify sessions; they die
--     on app restart.
--   * Writes are service_role only. A regular authenticated client
--     cannot read OR write this table. Read is also service_role only,
--     so the owner inspects it via the Supabase Dashboard SQL Editor.
--   * TTL is manual: the owner should periodically run
--       DELETE FROM app_errors WHERE occurred_at < now() - interval '30 days';
--     We do NOT install a pg_cron job here because the Advocat project
--     does not currently use pg_cron.
-- =====================================================================

create table if not exists public.app_errors (
  id             uuid primary key default gen_random_uuid(),
  occurred_at    timestamptz not null default now(),
  session_uuid   uuid null,
  route          text null,           -- go_router path at error time
  hint           text null,           -- 'widget-build' / 'zone-uncaught' etc
  error_type     text null,           -- runtimeType of the exception
  error_message  text null,           -- truncated to 500 chars at write time
  stack_snippet  text null,           -- first ~2 KB of stack trace
  app_version    text null,
  platform       text null,           -- 'web' / 'ios' / 'android'
  locale         text null
);

comment on table public.app_errors is
  'launch/wave1 Sentry-lite sink. Written by the Flutter error boundary '
  'via the service_role key only. No PII. 30-day manual TTL.';

-- Helpful index for the owner's "what broke today?" query.
create index if not exists idx_app_errors_recent
  on public.app_errors (occurred_at desc);

-- RLS: lock down completely. Only service_role reads/writes.
alter table public.app_errors enable row level security;

-- Explicit deny-all policy for anon + authenticated. Postgres + Supabase
-- treat "no policy" as deny already, but naming it makes intent obvious
-- to a future reviewer.
drop policy if exists "app_errors: deny all client access" on public.app_errors;
create policy "app_errors: deny all client access"
  on public.app_errors
  for all
  to anon, authenticated
  using (false)
  with check (false);
