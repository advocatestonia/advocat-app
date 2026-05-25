-- ============================================================================
-- 20260523040000_org_billing.sql
-- Migration 34/37 — Per-seat billing infrastructure.
--
-- Adds:
--   * org_seat_change_log  — append-only audit of seat deltas (forensic).
--   * org_increment_seats  — atomic SELECT FOR UPDATE seat counter RPC.
--
-- Concurrency: org_increment_seats uses FOR UPDATE on the organizations row,
-- so two concurrent invite calls cannot overshoot seat_limit.
-- ============================================================================

create table if not exists public.org_seat_change_log (
  id                     uuid primary key default gen_random_uuid(),
  org_id                 uuid not null references public.organizations(id) on delete cascade,
  actor_user_id          uuid references auth.users(id) on delete set null,
  delta                  int not null,
  seats_before           int not null,
  seats_after            int not null,
  stripe_event_id        text,
  proration_amount_cents int,
  created_at             timestamptz not null default now()
);

create index if not exists idx_org_seat_change_org_ts
  on public.org_seat_change_log (org_id, created_at desc);

alter table public.org_seat_change_log enable row level security;

drop policy if exists org_seat_change_select_billing on public.org_seat_change_log;
create policy org_seat_change_select_billing
  on public.org_seat_change_log for select to authenticated
  using (
    org_id in (select public.current_user_org_ids())
    and public.current_user_org_role(org_id) in ('owner','admin','billing')
  );

grant select on public.org_seat_change_log to authenticated;

-- ── RPC: atomic seat increment with row lock + bounds check ──────────────────
create or replace function public.org_increment_seats(
  p_org    uuid,
  p_delta  int
) returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_before int;
  v_limit  int;
  v_after  int;
begin
  -- Lock the org row so concurrent invite calls serialize here.
  select seat_count, seat_limit
    into v_before, v_limit
  from public.organizations
  where id = p_org
  for update;

  if v_before is null then
    raise exception 'org_not_found' using errcode = 'P0002';
  end if;

  v_after := v_before + p_delta;

  if v_after < 0 then
    raise exception 'seats_negative' using errcode = '23514';
  end if;

  if v_after > v_limit then
    raise exception 'seat_limit_exceeded' using errcode = '23514';
  end if;

  update public.organizations
    set seat_count = v_after
    where id = p_org;

  -- Append-only forensic log (actor + proration filled by edge function via
  -- a second INSERT with stripe_event_id if available).
  insert into public.org_seat_change_log (org_id, delta, seats_before, seats_after)
  values (p_org, p_delta, v_before, v_after);

  return v_after;
end
$$;

revoke all on function public.org_increment_seats(uuid, int) from public;
-- service_role only (edge functions). Do NOT grant to authenticated.

notify pgrst, 'reload schema';

-- ROLLBACK:
-- drop function if exists public.org_increment_seats(uuid, int);
-- drop policy if exists org_seat_change_select_billing on public.org_seat_change_log;
-- drop table if exists public.org_seat_change_log;
