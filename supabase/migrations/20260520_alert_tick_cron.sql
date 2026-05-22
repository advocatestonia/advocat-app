-- 20260520_alert_tick_cron.sql
-- =====================================================================
-- DEPT 7 — Observability & On-call: alert-tick wiring.
--
-- Three pieces:
--   1) spend_hourly_snapshot  — hourly aggregation of anthropic_daily_spend
--      so alert B (>$20.83/h) can compute a per-hour delta. The /5min check
--      reads `latest - prev` from this table; the :00 cron writes a fresh
--      row each hour.
--   2) recent_alerts          — 10-minute de-dup ledger so the same condition
--      doesn't spam Slack on every 60s tick. Keyed by `alert_key`.
--   3) public.invoke_edge_cron(text) RPC + cron schedules — fires alert-tick
--      every minute and rolls the hourly spend snapshot at :00. The RPC is
--      idempotent: it no-ops gracefully if the project URL / cron secret
--      vault entries are missing (so this migration is safe to run before
--      ops finishes the secret rotation).
--
-- Author: Dept 7 lead | Date: 2026-05-20
-- =====================================================================

-- Required extensions. Both are enabled at the Supabase project level by
-- support; we just reference them. The CREATE EXTENSION IF NOT EXISTS is
-- a no-op on production but lets local supabase-cli replicate the env.
create extension if not exists pg_cron;
create extension if not exists pg_net;

-- ─── 1. spend_hourly_snapshot ──────────────────────────────────────────
create table if not exists public.spend_hourly_snapshot (
  hour              timestamptz primary key,
  cumulative_cents  bigint not null,
  request_count     bigint not null default 0,
  recorded_at       timestamptz not null default now()
);

comment on table public.spend_hourly_snapshot is
  'DEPT 7 alert B: hourly snapshot of anthropic_daily_spend.cents_spent. '
  'Delta(latest - prev) = $/hour burn. Rolls every hour via pg_cron.';

create index if not exists idx_spend_hourly_recent
  on public.spend_hourly_snapshot (hour desc);

alter table public.spend_hourly_snapshot enable row level security;

drop policy if exists "spend_hourly_snapshot: deny client" on public.spend_hourly_snapshot;
create policy "spend_hourly_snapshot: deny client"
  on public.spend_hourly_snapshot
  for all
  to anon, authenticated
  using (false)
  with check (false);

-- Convenience: take the current snapshot from anthropic_daily_spend.
-- Called by the :00 cron job. Idempotent: ON CONFLICT DO NOTHING so two
-- jobs firing at the same minute can't double-write.
create or replace function public.snapshot_anthropic_hourly()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_hour  timestamptz := date_trunc('hour', now());
  v_cents bigint;
  v_count bigint;
begin
  select coalesce(cents_spent, 0), coalesce(request_count, 0)
    into v_cents, v_count
  from public.anthropic_daily_spend
  where spend_date = current_date;

  insert into public.spend_hourly_snapshot (hour, cumulative_cents, request_count)
  values (v_hour, coalesce(v_cents, 0), coalesce(v_count, 0))
  on conflict (hour) do nothing;
end;
$$;

revoke all on function public.snapshot_anthropic_hourly() from public;
grant execute on function public.snapshot_anthropic_hourly() to service_role;

-- ─── 2. recent_alerts (10-min de-dup ledger) ───────────────────────────
create table if not exists public.recent_alerts (
  alert_key   text primary key,        -- e.g. 'alert_A_proxy_5xx'
  fired_at    timestamptz not null default now(),
  payload     jsonb null
);

comment on table public.recent_alerts is
  'DEPT 7 alert-tick: de-dup ledger. alert-tick UPSERTs (alert_key) on fire; '
  'skips POST if the row already exists AND fired_at > now()-interval ''10 minutes''. '
  'Older rows are overwritten on the next fire.';

create index if not exists idx_recent_alerts_fired
  on public.recent_alerts (fired_at desc);

alter table public.recent_alerts enable row level security;

drop policy if exists "recent_alerts: deny client" on public.recent_alerts;
create policy "recent_alerts: deny client"
  on public.recent_alerts
  for all
  to anon, authenticated
  using (false)
  with check (false);

-- ─── 3. invoke_edge_cron RPC ───────────────────────────────────────────
-- Posts to /functions/v1/<fn_name> with the x-cron-secret header. Reads
-- the project URL and cron secret from vault.decrypted_secrets (set by
-- ops via `select vault.create_secret(...)`).
--
-- No-ops with a NOTICE if either vault entry is missing — lets us land
-- this migration before ops finishes the secret rotation. The cron jobs
-- below will simply log the NOTICE and move on.
create or replace function public.invoke_edge_cron(p_fn_name text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_url     text;
  v_secret  text;
  v_req_id  bigint;
begin
  begin
    select decrypted_secret into v_url
      from vault.decrypted_secrets
     where name = 'project_url'
     limit 1;
  exception when others then
    v_url := null;
  end;

  begin
    select decrypted_secret into v_secret
      from vault.decrypted_secrets
     where name = 'cron_secret'
     limit 1;
  exception when others then
    v_secret := null;
  end;

  if v_url is null or v_secret is null then
    raise notice 'invoke_edge_cron(%): vault entries missing, skipping', p_fn_name;
    return;
  end if;

  select net.http_post(
    url := v_url || '/functions/v1/' || p_fn_name,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-cron-secret', v_secret
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 8000
  ) into v_req_id;
end;
$$;

revoke all on function public.invoke_edge_cron(text) from public;
grant execute on function public.invoke_edge_cron(text) to service_role;

comment on function public.invoke_edge_cron(text) is
  'DEPT 7: helper RPC for pg_cron → edge fn invocation. Reads project_url '
  'and cron_secret from vault.decrypted_secrets. No-ops if missing.';

-- ─── 4. cron schedules ─────────────────────────────────────────────────
-- Drop-then-schedule so re-running the migration replaces the job entry
-- (cron.schedule errors on duplicate job names).
do $$
declare
  jid bigint;
begin
  for jid in select jobid from cron.job where jobname = 'alert-tick-every-minute' loop
    perform cron.unschedule(jid);
  end loop;
  for jid in select jobid from cron.job where jobname = 'spend-snapshot-hourly' loop
    perform cron.unschedule(jid);
  end loop;
end$$;

-- Alert-tick: every minute. Worst-case detection latency ≈ 60s + ~500ms
-- HTTP + ~1-3s Slack push → owner phone alert within 65s.
select cron.schedule(
  'alert-tick-every-minute',
  '* * * * *',
  $$select public.invoke_edge_cron('alert-tick');$$
);

-- Anthropic spend snapshot: top of every hour (cron drift tolerated by the
-- :00 alignment in snapshot_anthropic_hourly via date_trunc('hour', ...)).
select cron.schedule(
  'spend-snapshot-hourly',
  '0 * * * *',
  $$select public.snapshot_anthropic_hourly();$$
);

-- ─── 5. Backfill the current hour ──────────────────────────────────────
-- So the first /5min alert-tick after this migration has a `prev` row to
-- diff against. Without this, alert B would silently no-op for up to 60min
-- after deploy.
select public.snapshot_anthropic_hourly();
