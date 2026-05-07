-- =====================================================================
-- Phase 2 Pkg 9 — Deadline Radar (case_deadlines table + RPCs)
--
-- Sibling of public.case_documents / public.case_chat_sessions (Pkg 1.A,
-- 20260506). New table because jsonb-on-user_cases lacks per-row primary
-- key, RLS granularity, and pg_cron foreign-key targets the radar needs.
--
-- Migration filename slot _10 (NOT _09): Pkg 2 closeout took _09 with
-- 20260507090000_citations_position_idempotency.sql.
--
-- Spec source of truth: docs/architecture/phase2-pkg9-deadline-radar.md.
--
-- Idempotency: every DDL statement is `if not exists` — `supabase db push`
-- is safe to re-run.
-- =====================================================================

create extension if not exists "uuid-ossp";
create extension if not exists pgcrypto;

-- ── 1. enums ──────────────────────────────────────────────────────────
do $$ begin
  if not exists (select 1 from pg_type where typname = 'case_deadline_status') then
    create type case_deadline_status as enum
      ('active','completed','missed','archived');
  end if;
end $$;

do $$ begin
  if not exists (select 1 from pg_type where typname = 'case_deadline_priority') then
    create type case_deadline_priority as enum
      ('critical','high','medium','low');
  end if;
end $$;

do $$ begin
  if not exists (select 1 from pg_type where typname = 'case_deadline_source') then
    create type case_deadline_source as enum
      ('pdf','intake','manual','email','haiku_extract','statutory_template');
  end if;
end $$;

-- ── 2. case_deadlines table ───────────────────────────────────────────
-- Per-deadline row. RLS owner-only. Cron sweeps `status='active'` rows.
create table if not exists public.case_deadlines (
    id                  uuid primary key default gen_random_uuid(),
    case_id             uuid not null references public.user_cases(id) on delete cascade,
    user_id             uuid not null references auth.users(id) on delete cascade,
    title               text not null,
    description         text,
    statute_basis       text,                   -- e.g. 'HKMS §46', 'ECHR Protocol 15'
    anchor_key          text,                   -- statutory_anchors.ts key
    service_date        date,
    service_basis       text,
    deadline_at         timestamptz not null,
    holiday_shifted     boolean not null default false,
    holiday_shift_note  text,
    source              case_deadline_source not null default 'manual',
    source_doc_id       uuid references public.case_documents(id) on delete set null,
    status              case_deadline_status not null default 'active',
    priority            case_deadline_priority not null default 'high',
    completed_at        timestamptz,
    completed_note      text,
    created_at          timestamptz not null default now(),
    updated_at          timestamptz not null default now(),
    -- Risk #1 (architect §11): never auto-create a `priority='critical'`
    -- deadline from `source='haiku_extract'`. Critical priority requires a
    -- triggering document or human input.
    constraint case_deadlines_critical_source_check
        check (
            priority <> 'critical'
            or source in ('pdf','intake','manual','email','statutory_template')
        )
);

-- Partial index for the radar query: active rows ordered by deadline.
create index if not exists case_deadlines_user_active_idx
    on public.case_deadlines (user_id, deadline_at)
    where status = 'active';

create index if not exists case_deadlines_case_idx
    on public.case_deadlines (case_id);

create index if not exists case_deadlines_status_idx
    on public.case_deadlines (status);

-- Partial index for cron scan: only active rows.
create index if not exists case_deadlines_cron_scan_idx
    on public.case_deadlines (deadline_at)
    where status = 'active';

-- Dedupe index — the natural key for upsert (architect §5):
-- (case_id, anchor_key, deadline_at::date). Two extractions of the same
-- kaebus deadline from the päätös PDF and from the intake wizard must NOT
-- create two rows. nullable anchor_key means we partial-index only when
-- anchor_key is set; manual rows without an anchor are user's own list and
-- intentionally allow duplicates.
create unique index if not exists case_deadlines_anchor_dedupe_idx
    on public.case_deadlines (case_id, anchor_key, ((deadline_at AT TIME ZONE 'UTC')::date))
    where anchor_key is not null;

-- ── 3. updated_at trigger ─────────────────────────────────────────────
create or replace function public.touch_case_deadlines_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at := now();
    return new;
end;
$$;

drop trigger if exists case_deadlines_updated_at on public.case_deadlines;
create trigger case_deadlines_updated_at
    before update on public.case_deadlines
    for each row execute function public.touch_case_deadlines_updated_at();

-- ── 4. RLS — owner-only ───────────────────────────────────────────────
alter table public.case_deadlines enable row level security;

drop policy if exists "own case deadlines" on public.case_deadlines;
create policy "own case deadlines" on public.case_deadlines
    for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

-- ── 5. RPC: active_deadlines (radar widget) ───────────────────────────
-- Top-N upcoming actives across all of the caller's active cases. Returns
-- joined case title for the UI label. security invoker → RLS confines
-- results to the caller's rows.
create or replace function public.active_deadlines(p_limit int default 10)
returns table (
    id                 uuid,
    case_id            uuid,
    case_title         text,
    title              text,
    statute_basis      text,
    anchor_key         text,
    deadline_at        timestamptz,
    priority           case_deadline_priority,
    delta_days         int,
    holiday_shifted    boolean,
    holiday_shift_note text,
    source             case_deadline_source
)
language sql stable security invoker
set search_path = public
as $$
    select
        d.id,
        d.case_id,
        c.title as case_title,
        d.title,
        d.statute_basis,
        d.anchor_key,
        d.deadline_at,
        d.priority,
        greatest(
            0,
            ceil(extract(epoch from (d.deadline_at - now())) / 86400)
        )::int as delta_days,
        d.holiday_shifted,
        d.holiday_shift_note,
        d.source
    from public.case_deadlines d
    join public.user_cases c on c.id = d.case_id
    where d.status = 'active'
      and c.status = 'active'
    order by d.deadline_at asc
    limit greatest(1, least(p_limit, 50))
$$;

-- ── 6. RPC: case_deadlines_for (per-case list) ────────────────────────
-- security invoker → RLS confines to the caller's case.
create or replace function public.case_deadlines_for(p_case_id uuid)
returns setof public.case_deadlines
language sql stable security invoker
set search_path = public
as $$
    select *
    from public.case_deadlines
    where case_id = p_case_id
    order by
        case status
            when 'active'    then 0
            when 'missed'    then 1
            when 'completed' then 2
            else 3
        end,
        deadline_at asc
$$;

-- ── 7. RPC: mark_deadline_complete ────────────────────────────────────
-- Owner-only mutation via SECURITY DEFINER + ownership pre-check. Pattern
-- mirrors public.unredact (20260507050000_pii_redaction_map.sql).
create or replace function public.mark_deadline_complete(
    p_deadline_id uuid,
    p_note        text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_owner uuid;
begin
    if auth.uid() is null then
        raise exception 'unauthorized' using errcode = '42501';
    end if;

    select user_id into v_owner
      from public.case_deadlines
     where id = p_deadline_id;

    if v_owner is null then
        raise exception 'not_found' using errcode = '02000';
    end if;
    if v_owner <> auth.uid() then
        raise exception 'forbidden' using errcode = '42501';
    end if;

    update public.case_deadlines
       set status = 'completed',
           completed_at = now(),
           completed_note = p_note
     where id = p_deadline_id;
end;
$$;

alter function public.mark_deadline_complete(uuid, text)
    owner to postgres;

-- Reload the PostgREST schema cache so the new RPCs are reachable
-- without a manual restart. (memory: reference_pitfalls_chat_infra.)
notify pgrst, 'reload schema';
