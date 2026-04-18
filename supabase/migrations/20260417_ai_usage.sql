-- =============================================================================
-- Migration: ai_usage table + atomic quota RPC (P0-3)
-- =============================================================================
--
-- Server-side free-tier enforcement for the AI chat. Replaces the easily
-- bypassed client-side SharedPreferences counter in `ai_service.dart`.
--
-- Data model:
--   ai_usage (
--     user_id   uuid PK
--     month     date      -- first day of the current calendar month (UTC)
--     count     int       -- messages used this month
--     updated_at timestamptz
--   )
--
-- Concurrency:
--   The `increment_ai_usage` RPC does an UPSERT ... RETURNING so two
--   concurrent calls from the same user always see a strictly monotonic
--   count (Postgres row locks handle the race). Tested in
--   test/services/ai_quota_test.dart.
-- =============================================================================

-- Table --------------------------------------------------------------------

create table if not exists public.ai_usage (
  user_id uuid primary key references auth.users(id) on delete cascade,
  month date not null default date_trunc('month', now())::date,
  count integer not null default 0,
  updated_at timestamptz not null default now(),
  constraint ai_usage_count_nonneg check (count >= 0)
);

comment on table public.ai_usage is
  'Server-side enforcement of the free-tier AI message quota. One row per user, reset monthly.';

create index if not exists idx_ai_usage_month on public.ai_usage(month);

-- Row-Level Security -------------------------------------------------------

alter table public.ai_usage enable row level security;

-- Users can read their own row only.
drop policy if exists ai_usage_read_own on public.ai_usage;
create policy ai_usage_read_own
  on public.ai_usage
  for select
  using (auth.uid() = user_id);

-- NO direct insert/update/delete policies on purpose — writes go via the
-- SECURITY DEFINER functions below.

-- RPC: increment_ai_usage --------------------------------------------------
--
-- Atomically:
--   1. Ensures the row exists for the current calendar month.
--   2. Increments count.
--   3. Returns the new count.
--
-- The function is SECURITY DEFINER so it can write to the table even though
-- no end-user policy allows it. It always operates on auth.uid() — the
-- caller cannot spoof another user's row.

create or replace function public.increment_ai_usage()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid;
  v_month date := date_trunc('month', now())::date;
  v_count integer;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'authentication required';
  end if;

  insert into public.ai_usage (user_id, month, count, updated_at)
  values (v_uid, v_month, 1, now())
  on conflict (user_id) do update
    set count      = case
                       when public.ai_usage.month = v_month
                       then public.ai_usage.count + 1
                       else 1
                     end,
        month      = v_month,
        updated_at = now()
  returning count into v_count;

  return v_count;
end;
$$;

comment on function public.increment_ai_usage is
  'Atomically increments the current user''s AI usage counter and returns the new value. Resets at month boundary.';

grant execute on function public.increment_ai_usage() to authenticated;

-- RPC: get_ai_usage --------------------------------------------------------
--
-- Returns the current month's count without mutating it, for the quota
-- preview endpoint.

create or replace function public.get_ai_usage()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid;
  v_month date := date_trunc('month', now())::date;
  v_count integer;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'authentication required';
  end if;

  select count into v_count
    from public.ai_usage
   where user_id = v_uid
     and month = v_month;

  return coalesce(v_count, 0);
end;
$$;

grant execute on function public.get_ai_usage() to authenticated;

-- Helper view for admin auditing (not exposed via API by default) ----------

create or replace view public.ai_usage_current_month as
  select user_id, count, updated_at
    from public.ai_usage
   where month = date_trunc('month', now())::date;
