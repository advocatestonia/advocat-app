-- =====================================================================
-- Phase 2 Pkg 9 — Deadline Notification Log
--
-- Idempotency for the cron pusher: each (deadline_id, threshold, channel)
-- fires exactly once. service_role-only insert; user can read their own
-- log so the UI can show "we notified you 3 days ago at 14:02".
--
-- Spec source of truth: docs/architecture/phase2-pkg9-deadline-radar.md §6.
--
-- Idempotency: every DDL statement is `if not exists` — `supabase db push`
-- is safe to re-run.
-- =====================================================================

create extension if not exists "uuid-ossp";
create extension if not exists pgcrypto;

-- ── 1. table ──────────────────────────────────────────────────────────
create table if not exists public.deadline_notification_log (
    id              uuid primary key default gen_random_uuid(),
    deadline_id     uuid not null references public.case_deadlines(id) on delete cascade,
    user_id         uuid not null references auth.users(id) on delete cascade,
    -- threshold semantics from architect §6:
    --   '30d', '7d', '3d', '1d', 'morning_of'
    threshold       text not null check (threshold in
        ('30d','7d','3d','1d','morning_of')),
    -- delivery channel; multi-row per threshold for fan-out.
    channel         text not null check (channel in
        ('push','email','in_app')),
    fired_at        timestamptz not null default now(),
    delivered       boolean not null default false,
    delivery_error  text,
    -- Architect §6.4 + Risk #3: unique per (deadline, threshold, channel)
    -- guarantees we never re-fire even when cron drifts and the same tick
    -- runs twice.
    unique (deadline_id, threshold, channel)
);

create index if not exists deadline_notification_log_deadline_idx
    on public.deadline_notification_log (deadline_id);
create index if not exists deadline_notification_log_user_idx
    on public.deadline_notification_log (user_id);
create index if not exists deadline_notification_log_fired_at_idx
    on public.deadline_notification_log (fired_at desc);

-- ── 2. RLS ────────────────────────────────────────────────────────────
alter table public.deadline_notification_log enable row level security;

-- Read-only for the owner; no insert/update/delete policy, so service-role
-- (the cron pusher) is the only writer. Mirrors audit_log semantics:
-- service-only writes via SECURITY DEFINER pathways.
drop policy if exists "own notification log" on public.deadline_notification_log;
create policy "own notification log" on public.deadline_notification_log
    for select
    using (auth.uid() = user_id);

-- Reload the PostgREST schema cache so the new table is reachable
-- without a manual restart. (memory: reference_pitfalls_chat_infra.)
notify pgrst, 'reload schema';
