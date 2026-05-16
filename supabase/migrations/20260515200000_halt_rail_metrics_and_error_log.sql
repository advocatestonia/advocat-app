-- =====================================================================
-- P5 of Bentley batch (2026-05-15) — halt-rail metrics + edge-fn error log
-- =====================================================================
-- Purpose
--   Two thin operational tables wired into the existing claude-proxy /
--   halt-rail pipeline so the owner can answer two questions from the
--   Supabase SQL Editor without paying for an APM SaaS:
--
--   1. "Is the halt-rail actually firing in production, and for which
--      categories / languages?"
--        → public.halt_rail_triggers
--   2. "What edge-fn errors / 5xx responses happened in the last hour?"
--        → public.error_log
--
-- Design notes
--   • Both tables are append-only, service-role-only writes, no PII.
--   • halt_rail_triggers stores `user_id` only when the caller was an
--     authenticated end-user (anon callers store NULL). The pseudo-id
--     `anon:<ip-hash>` from claude-proxy is normalised to NULL here so
--     we never persist even hashed IPs.
--   • error_log is a separate table from public.app_errors (which is the
--     Flutter Sentry-lite sink) because edge-fn errors have a different
--     shape (no `route`, no Flutter `platform`, but they DO have
--     `fn_name` and a `request_id`). Reusing app_errors would have meant
--     adding nullable columns that don't apply to client errors and vice
--     versa — easier to read with two tables.
--   • TTL is manual. Both tables get a `occurred_at` index so the owner
--     can run:
--       DELETE FROM halt_rail_triggers WHERE occurred_at < now() - interval '90 days';
--       DELETE FROM error_log         WHERE occurred_at < now() - interval '30 days';
-- =====================================================================

-- ─── halt_rail_triggers ──────────────────────────────────────────────────
create table if not exists public.halt_rail_triggers (
  id            uuid primary key default gen_random_uuid(),
  occurred_at   timestamptz not null default now(),
  category      text not null check (category in (
    'deportation', 'custody', 'criminal', 'big_claim', 'echr'
  )),
  language      text null check (language is null or language in (
    'ru', 'fi', 'et', 'en'
  )),
  -- Auth user id when available, NULL for anon callers. We never persist
  -- the anon:<hash> pseudo-id — see migration header notes.
  user_id       uuid null,
  -- Optional debug fields. `reason` mirrors HaltDetection.reason. `amount_eur`
  -- is the matched euro amount for big_claim, NULL otherwise.
  reason        text null,
  amount_eur    integer null
);

comment on table public.halt_rail_triggers is
  'P5 (2026-05-15): one row per halt-rail trigger in claude-proxy. '
  'Service-role write only. Owner queries via SQL Editor. 90-day manual TTL.';

create index if not exists idx_halt_rail_triggers_recent
  on public.halt_rail_triggers (occurred_at desc);

create index if not exists idx_halt_rail_triggers_category
  on public.halt_rail_triggers (category, occurred_at desc);

alter table public.halt_rail_triggers enable row level security;

drop policy if exists "halt_rail_triggers: deny all client access"
  on public.halt_rail_triggers;
create policy "halt_rail_triggers: deny all client access"
  on public.halt_rail_triggers
  for all
  to anon, authenticated
  using (false)
  with check (false);

-- ─── error_log ────────────────────────────────────────────────────────────
create table if not exists public.error_log (
  id            uuid primary key default gen_random_uuid(),
  occurred_at   timestamptz not null default now(),
  fn_name       text not null,
  severity      text not null default 'error' check (severity in (
    'debug', 'info', 'warn', 'error', 'critical'
  )),
  -- HTTP status returned to the caller, if applicable. NULL for non-HTTP
  -- failures (e.g. background tasks).
  status_code   integer null,
  message       text null,    -- truncated to 1000 chars at write time
  stack         text null,    -- truncated to 2048 chars at write time
  -- Optional caller correlation. user_id NULL for anon; request_id is
  -- the function's per-request UUID if it generated one.
  user_id       uuid null,
  request_id    uuid null,
  -- Sampling hint: 'full' = always logged (5xx, criticals); 'sampled' =
  -- only 10% of normal errors. Lets the owner filter for "all serious
  -- events" without scanning a noisy table.
  sample_mode   text not null default 'full' check (sample_mode in (
    'full', 'sampled'
  ))
);

comment on table public.error_log is
  'P5 (2026-05-15): edge-fn error sink. 100%% of 5xx, 10%% of normal errors. '
  'Service-role write only. 30-day manual TTL.';

create index if not exists idx_error_log_recent
  on public.error_log (occurred_at desc);

create index if not exists idx_error_log_fn_severity
  on public.error_log (fn_name, severity, occurred_at desc);

alter table public.error_log enable row level security;

drop policy if exists "error_log: deny all client access" on public.error_log;
create policy "error_log: deny all client access"
  on public.error_log
  for all
  to anon, authenticated
  using (false)
  with check (false);

-- ─── Owner-facing helper view ────────────────────────────────────────────
-- "Last 24h halt-rail summary": one row per category × language.
create or replace view public.v_halt_rail_24h as
  select
    category,
    language,
    count(*)::int as fires,
    min(occurred_at) as first_seen,
    max(occurred_at) as last_seen
  from public.halt_rail_triggers
  where occurred_at >= now() - interval '24 hours'
  group by category, language
  order by fires desc;

comment on view public.v_halt_rail_24h is
  'Halt-rail firing rate by category × language for the last 24 hours. '
  'Owner query: SELECT * FROM v_halt_rail_24h;';

-- "Last 1h error spike": top fn × severity combos.
create or replace view public.v_error_log_1h as
  select
    fn_name,
    severity,
    count(*)::int as events,
    min(occurred_at) as first_seen,
    max(occurred_at) as last_seen
  from public.error_log
  where occurred_at >= now() - interval '1 hour'
  group by fn_name, severity
  order by events desc;

comment on view public.v_error_log_1h is
  'Edge-fn error volume by fn × severity for the last hour. '
  'Owner query: SELECT * FROM v_error_log_1h;';
