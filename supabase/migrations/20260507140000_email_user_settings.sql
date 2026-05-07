-- =====================================================================
-- Email Agent — per-user settings for memory block (carry-over D4)
--
-- Spec ref:
--   business/email_agent_handoff_2026-05-06/09_INTEGRATION_INTO_ADVOCAT.md
--   email_agent_SYSTEM_PROMPT v1.1-final §3.7  (MemoryBlock shape)
--
-- Adds the `user_settings` table that backs the email-triage MemoryBlock:
--   * own_counsel_emails        text[]   — Rule 16.bis own_counsel_advisory
--   * dead_address_corrections  jsonb    — Rule 9 auto-send recipient gate
--
-- Migration filename slot _14: max preceding _NN this day is _13
-- (`20260507130000_email_inbox.sql`). Per
-- `lesson_migration_alphabetical_order.md`, the `_NN_` prefix enforces
-- topological dep order when multiple migrations land on the same day.
--
-- Idempotency: every DDL is `if not exists` / `do $$`-guarded; safe to
-- re-run.
-- =====================================================================

create extension if not exists pgcrypto;

create table if not exists public.user_settings (
    user_id                    uuid primary key
                               references auth.users(id) on delete cascade,
    own_counsel_emails         text[] not null default '{}'::text[],
    dead_address_corrections   jsonb  not null default '{}'::jsonb,
    created_at                 timestamptz not null default now(),
    updated_at                 timestamptz not null default now()
);

create or replace function public.touch_user_settings_updated_at()
returns trigger language plpgsql as $$
begin
    new.updated_at := now();
    return new;
end;
$$;

drop trigger if exists user_settings_updated_at on public.user_settings;
create trigger user_settings_updated_at
    before update on public.user_settings
    for each row execute function public.touch_user_settings_updated_at();

alter table public.user_settings enable row level security;

do $$
begin
    if not exists (
        select 1 from pg_policies
        where schemaname = 'public' and tablename = 'user_settings'
          and policyname = 'user_settings_owner_select'
    ) then
        create policy user_settings_owner_select on public.user_settings
            for select to authenticated using (auth.uid() = user_id);
    end if;
end$$;

do $$
begin
    if not exists (
        select 1 from pg_policies
        where schemaname = 'public' and tablename = 'user_settings'
          and policyname = 'user_settings_owner_insert'
    ) then
        create policy user_settings_owner_insert on public.user_settings
            for insert to authenticated with check (auth.uid() = user_id);
    end if;
end$$;

do $$
begin
    if not exists (
        select 1 from pg_policies
        where schemaname = 'public' and tablename = 'user_settings'
          and policyname = 'user_settings_owner_update'
    ) then
        create policy user_settings_owner_update on public.user_settings
            for update to authenticated
            using (auth.uid() = user_id) with check (auth.uid() = user_id);
    end if;
end$$;

comment on table public.user_settings is
    'Per-user settings for the Email Agent MemoryBlock. Owner-only RLS; '
    'service-role writes from email-triage memory_update loop.';
comment on column public.user_settings.own_counsel_emails is
    'Confirmed own-counsel email addresses. Drives Rule 16.bis '
    'own_counsel_advisory routing in the triage prompt.';
comment on column public.user_settings.dead_address_corrections is
    'JSONB map {dead_email: preferred_email}. Used by Rule 9 auto-send '
    'gate to avoid known-bad recipients. Default empty object.';
