-- ============================================================================
-- 20260523060000_org_api_keys.sql
-- Migration 36/37 — API key authentication: rate-counter table + consume RPC.
--
-- The org_api_keys table is created in migration 31. This migration adds:
--   * org_api_rate_counters  — daily-bucket counter per key
--   * org_api_key_consume    — atomic validate + increment + rate-check RPC
--   * org_api_rate_counters_cleanup — nightly retention purge
--
-- All RPCs are security definer / service_role only; the edge function
-- _shared/api_key_auth.ts is the sole caller.
-- ============================================================================

create table if not exists public.org_api_rate_counters (
  api_key_id    uuid not null references public.org_api_keys(id) on delete cascade,
  bucket_date   date not null,
  request_count int not null default 0,
  primary key (api_key_id, bucket_date)
);

create index if not exists idx_org_api_rate_counters_date
  on public.org_api_rate_counters (bucket_date);

-- Counters table holds no PII but we still want RLS to disallow direct reads.
alter table public.org_api_rate_counters enable row level security;
-- No policies → only service_role can access (RLS denies authenticated by default).

-- ── consume RPC: atomic validate-and-increment ───────────────────────────────
create or replace function public.org_api_key_consume(
  p_key_hash text,
  p_limit    int
) returns table (
  api_key_id    uuid,
  org_id        uuid,
  scopes        text[],
  request_count int
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id      uuid;
  v_org     uuid;
  v_scopes  text[];
  v_revoked timestamptz;
  v_expires timestamptz;
  v_count   int;
begin
  select k.id, k.org_id, k.scopes, k.revoked_at, k.expires_at
    into v_id, v_org, v_scopes, v_revoked, v_expires
  from public.org_api_keys k
  where k.key_hash = p_key_hash;

  if v_id is null then
    raise exception 'api_key_unknown' using errcode = '28000';
  end if;
  if v_revoked is not null then
    raise exception 'api_key_revoked' using errcode = '28000';
  end if;
  if v_expires is not null and v_expires < now() then
    raise exception 'api_key_expired' using errcode = '28000';
  end if;

  -- Atomic upsert + increment; returning gives the NEW count.
  insert into public.org_api_rate_counters as r (api_key_id, bucket_date, request_count)
  values (v_id, current_date, 1)
  on conflict (api_key_id, bucket_date)
    do update set request_count = r.request_count + 1
  returning r.request_count into v_count;

  if v_count > p_limit then
    raise exception 'rate_limit_exceeded' using errcode = '54000';
  end if;

  -- Best-effort last_used_at update.
  update public.org_api_keys set last_used_at = now() where id = v_id;

  return query select v_id, v_org, v_scopes, v_count;
end
$$;

revoke all on function public.org_api_key_consume(text, int) from public;
-- service_role only.

-- ── nightly retention purge ──────────────────────────────────────────────────
create or replace function public.org_api_rate_counters_cleanup()
returns int
language sql
security definer
set search_path = public
as $$
  with d as (
    delete from public.org_api_rate_counters
    where bucket_date < current_date - interval '30 days'
    returning 1
  )
  select count(*)::int from d
$$;

revoke all on function public.org_api_rate_counters_cleanup() from public;

notify pgrst, 'reload schema';

-- ROLLBACK:
-- drop function if exists public.org_api_rate_counters_cleanup();
-- drop function if exists public.org_api_key_consume(text, int);
-- drop table if exists public.org_api_rate_counters;
