-- =============================================================================
-- Migration: reload ai_usage RPCs (PGRST schema cache fix)
-- =============================================================================
--
-- Incident 2026-04-23: check-ai-quota Edge Function returns 500 on every
-- authenticated request. Root cause: `get_ai_usage` / `increment_ai_usage`
-- were dropped or never registered in the PostgREST schema cache, even though
-- migration 20260417_ai_usage.sql was applied (supabase migration list shows
-- it). Calling /rest/v1/rpc/get_ai_usage returns:
--   PGRST202: "Could not find the function public.get_ai_usage ... in the
--   schema cache"
--
-- This migration:
--   1. Drops-and-recreates both functions with the same body to force a
--      fresh entry in pg_proc.
--   2. NOTIFY's pgrst to reload its schema cache immediately.
-- =============================================================================

drop function if exists public.increment_ai_usage();
drop function if exists public.get_ai_usage();

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

grant execute on function public.increment_ai_usage() to authenticated;

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

-- Force PostgREST to reload its schema cache so /rest/v1/rpc/* sees both
-- functions immediately.
notify pgrst, 'reload schema';
