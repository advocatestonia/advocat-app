-- =====================================================================
-- Smart Case Follow-ups (Feature #2) — case_followups table + RLS + RPCs.
-- =====================================================================
-- The Deadline Radar (Pkg 9, public.case_deadlines) tracks HARD legal
-- deadlines extracted from documents (kaebus deadlines, ECHR windows,
-- statutory anchors). It deliberately does NOT track the "soft" next-steps
-- an AI-lawyer hands a user mid-conversation:
--
--     "send a records request to the police"
--     "collect your receipts for the compensation claim"
--     "call your landlord again in a week"
--
-- Miss one of those and you still miss a right — but no document carries a
-- date the radar can parse. This table is the persistent home for those
-- user-facing follow-up tasks, with an optional `due_at` so the
-- followup-tick cron can nudge the user one day before.
--
-- Relationship to existing tables:
--   * case_followups : SOFT, user/AI-authored next-steps (this file).
--   * case_deadlines : HARD, statutory deadlines from documents (Pkg 9).
--   * The two never share rows. A followup may *reference* a case but is
--     intentionally separate so the radar's strict holiday-shift logic and
--     the soft task list don't contaminate each other.
--
-- FK target is public.user_cases(id) — the Case Memory case row — mirroring
-- public.case_deadlines so RLS and cascade behaviour are identical.
--
-- Idempotency: every statement is `if not exists` / `or replace` so
-- `supabase db push` is safe to re-run.
-- =====================================================================

create extension if not exists "uuid-ossp";
create extension if not exists pgcrypto;

-- ── 1. enums ──────────────────────────────────────────────────────────
do $$ begin
  if not exists (select 1 from pg_type where typname = 'case_followup_status') then
    create type case_followup_status as enum ('open', 'done', 'snoozed', 'dismissed');
  end if;
end $$;

do $$ begin
  if not exists (select 1 from pg_type where typname = 'case_followup_source') then
    -- 'suggested' = proposed by Haiku, not yet confirmed by the user.
    -- 'ai'        = a suggestion the user accepted (kept the AI provenance).
    -- 'manual'    = the user typed it themselves.
    create type case_followup_source as enum ('suggested', 'ai', 'manual');
  end if;
end $$;

-- ── 2. case_followups table ───────────────────────────────────────────
-- Per-task row. RLS owner-only. The cron sweeps `status='open'` rows with a
-- `due_at` inside the reminder window.
create table if not exists public.case_followups (
    id            uuid primary key default gen_random_uuid(),
    case_id       uuid not null references public.user_cases(id) on delete cascade,
    user_id       uuid not null references auth.users(id) on delete cascade,
    title         text not null,
    -- Optional one-line elaboration (why this step matters / what to attach).
    detail        text,
    -- Soft due date. NULL = "someday" task (no reminder, just a checklist item).
    due_at        timestamptz,
    status        case_followup_status not null default 'open',
    source        case_followup_source not null default 'manual',
    -- Set by followup-tick when it has dispatched the T-1day reminder, so the
    -- cron never double-nudges the same task.
    reminded_at   timestamptz,
    -- When the user snoozes, the new due_at is written and status flips back
    -- to 'open'; we keep a count for telemetry / runaway-snooze detection.
    snooze_count  int not null default 0,
    completed_at  timestamptz,
    created_at    timestamptz not null default now(),
    updated_at    timestamptz not null default now(),
    -- Guard rails: a non-empty, bounded title.
    constraint case_followups_title_len check (char_length(title) between 1 and 280)
);

-- Per-case ordered list (the widget query).
create index if not exists case_followups_case_idx
    on public.case_followups (case_id, status, due_at);

create index if not exists case_followups_user_idx
    on public.case_followups (user_id);

-- Cron scan: only open rows that carry a due date and haven't been reminded.
create index if not exists case_followups_cron_scan_idx
    on public.case_followups (due_at)
    where status = 'open' and reminded_at is null and due_at is not null;

-- ── 3. updated_at trigger ─────────────────────────────────────────────
create or replace function public.touch_case_followups_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at := now();
    return new;
end;
$$;

drop trigger if exists case_followups_updated_at on public.case_followups;
create trigger case_followups_updated_at
    before update on public.case_followups
    for each row execute function public.touch_case_followups_updated_at();

-- ── 4. RLS — owner-only ───────────────────────────────────────────────
alter table public.case_followups enable row level security;

drop policy if exists "own case followups" on public.case_followups;
create policy "own case followups" on public.case_followups
    for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

-- ── 5. RPC: case_followups_for_case ───────────────────────────────────
-- Ordered list for a single case's "Next steps" widget. security invoker →
-- RLS confines results to the caller's rows; a non-owner gets an empty set.
-- Dismissed rows are hidden; done rows are kept (struck-through in the UI).
create or replace function public.case_followups_for_case(p_case_id uuid)
returns table (
    id           uuid,
    case_id      uuid,
    title        text,
    detail       text,
    due_at       timestamptz,
    status       case_followup_status,
    source       case_followup_source,
    snooze_count int,
    created_at   timestamptz
)
language sql stable security invoker
set search_path = public
as $$
    select
        f.id, f.case_id, f.title, f.detail, f.due_at,
        f.status, f.source, f.snooze_count, f.created_at
    from public.case_followups f
    where f.case_id = p_case_id
      and f.status <> 'dismissed'
    order by
        -- open first, then done; within open, soonest due_at first
        (f.status = 'done')::int,
        f.due_at asc nulls last,
        f.created_at asc;
$$;

grant execute on function public.case_followups_for_case(uuid) to authenticated;

-- ── 6. RPC: complete_case_followup ────────────────────────────────────
-- Idempotent toggle to 'done'. security invoker so RLS proves ownership; a
-- non-owner's update touches zero rows and we report changed=false.
create or replace function public.complete_case_followup(p_followup_id uuid)
returns jsonb
language plpgsql security invoker
set search_path = public
as $$
declare
    v_count int;
begin
    update public.case_followups
       set status = 'done',
           completed_at = now()
     where id = p_followup_id
       and status <> 'done';
    get diagnostics v_count = row_count;
    return jsonb_build_object('changed', v_count > 0);
end;
$$;

grant execute on function public.complete_case_followup(uuid) to authenticated;

-- ── 7. RPC: snooze_case_followup ──────────────────────────────────────
-- Pushes due_at forward, flips status back to 'open', clears reminded_at so
-- the cron can nudge again, and bumps snooze_count. RLS via security invoker.
create or replace function public.snooze_case_followup(
    p_followup_id uuid,
    p_new_due_at  timestamptz
)
returns jsonb
language plpgsql security invoker
set search_path = public
as $$
declare
    v_count int;
begin
    update public.case_followups
       set due_at = p_new_due_at,
           status = 'open',
           reminded_at = null,
           snooze_count = snooze_count + 1
     where id = p_followup_id;
    get diagnostics v_count = row_count;
    return jsonb_build_object('changed', v_count > 0);
end;
$$;

grant execute on function public.snooze_case_followup(uuid, timestamptz) to authenticated;

-- =====================================================================
-- End of Smart Case Follow-ups migration.
-- =====================================================================
