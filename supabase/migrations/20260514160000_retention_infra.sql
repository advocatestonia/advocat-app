-- =====================================================================
-- Retention infrastructure — three loops:
--   1. Weekly digest email (Mondays 08:00 Europe/Tallinn)
--   2. Smart push notifications (FCM, when GOOGLE_APPLICATION_CREDENTIALS
--      is configured)
--   3. Win-back emails at day 3 / 7 / 14 inactive
--
-- Adds four tables + helper RPCs. All RLS-locked (owner-only). Pure DDL,
-- safe to re-run.
--
-- Filename slot 160000 (HHMMSS): bumped from 130000 because three parallel
-- agents simultaneously claimed that slot (drafting_studio, referrals,
-- and this file). Per lesson_migration_version_collision.md two migrations
-- with the same timestamp are dangerous — Supabase orders them
-- alphabetically by filename, which is non-obvious to debug. 160000 lives
-- safely after the existing 140000/150000 slots used today.
-- =====================================================================

create extension if not exists pgcrypto;

-- ── 1. notification_preferences ────────────────────────────────────────
-- Per-user opt-ins. Defaults are conservative: digest + deadline push on,
-- everything else (marketing, winback) is opt-in (GDPR posture). A row is
-- created lazily; absence of a row means "all defaults", which the digest
-- and winback workers treat as opted-in for transactional (digest, deadline)
-- and opted-out for marketing (winback day 14 promo code only — day 3/7
-- are transactional under "your account" engagement).
create table if not exists public.notification_preferences (
    user_id              uuid primary key references auth.users(id) on delete cascade,
    -- Email channels
    email_digest_enabled boolean not null default true,
    email_winback_enabled boolean not null default true,
    email_deadline_enabled boolean not null default true,
    email_insights_enabled boolean not null default true,
    -- Push channel
    push_enabled         boolean not null default true,
    push_deadline_enabled boolean not null default true,
    push_insights_enabled boolean not null default true,
    push_counterparty_enabled boolean not null default true,
    -- Frequency / scheduling
    digest_frequency     text not null default 'weekly'
                         check (digest_frequency in ('weekly','biweekly','off')),
    digest_day_of_week   smallint not null default 1
                         check (digest_day_of_week between 0 and 6),  -- 0=Sun, 1=Mon
    -- Hard kill-switch (one-click unsubscribe link)
    all_email_disabled   boolean not null default false,
    -- FCM
    fcm_token            text,
    fcm_token_updated_at timestamptz,
    -- Tracking
    unsubscribe_token    uuid not null default gen_random_uuid(),
    created_at           timestamptz not null default now(),
    updated_at           timestamptz not null default now()
);

create index if not exists notification_preferences_unsub_token_idx
    on public.notification_preferences (unsubscribe_token);

create or replace function public.touch_notification_preferences_updated_at()
returns trigger language plpgsql as $$
begin
    new.updated_at := now();
    return new;
end;
$$;

drop trigger if exists notification_preferences_updated_at
    on public.notification_preferences;
create trigger notification_preferences_updated_at
    before update on public.notification_preferences
    for each row execute function public.touch_notification_preferences_updated_at();

alter table public.notification_preferences enable row level security;

drop policy if exists notification_preferences_owner_all
    on public.notification_preferences;
create policy notification_preferences_owner_all
    on public.notification_preferences for all
    to authenticated
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

-- ── 2. user_engagement ─────────────────────────────────────────────────
-- Per-user engagement counters. Updated on each chat turn, login, key
-- action. The winback worker reads `last_active_at` to bucket users
-- into day-3 / day-7 / day-14 cohorts.
--
-- All counters are best-effort; they are NEVER the source of truth for
-- billing or quotas (see ai_usage / user_quotas for that).
create table if not exists public.user_engagement (
    user_id              uuid primary key references auth.users(id) on delete cascade,
    last_active_at       timestamptz not null default now(),
    sessions_count       integer not null default 0,
    chat_turns_count     integer not null default 0,
    cases_count          integer not null default 0,
    last_digest_sent_at  timestamptz,
    last_push_sent_at    timestamptz,
    last_winback_sent_at timestamptz,
    winback_sent_count   integer not null default 0,
    -- Track which winback steps were sent so we never repeat
    winback_d3_sent_at   timestamptz,
    winback_d7_sent_at   timestamptz,
    winback_d14_sent_at  timestamptz,
    -- Soft churn flag (winback gave up after day 14)
    churned              boolean not null default false,
    created_at           timestamptz not null default now(),
    updated_at           timestamptz not null default now()
);

create index if not exists user_engagement_last_active_idx
    on public.user_engagement (last_active_at desc);
create index if not exists user_engagement_winback_target_idx
    on public.user_engagement (last_active_at)
    where churned = false;

create or replace function public.touch_user_engagement_updated_at()
returns trigger language plpgsql as $$
begin
    new.updated_at := now();
    return new;
end;
$$;

drop trigger if exists user_engagement_updated_at on public.user_engagement;
create trigger user_engagement_updated_at
    before update on public.user_engagement
    for each row execute function public.touch_user_engagement_updated_at();

alter table public.user_engagement enable row level security;

drop policy if exists user_engagement_owner_select on public.user_engagement;
create policy user_engagement_owner_select
    on public.user_engagement for select
    to authenticated
    using (auth.uid() = user_id);

-- Writes are server-side only (cron + edge fns via service-role).
-- We deliberately do NOT give users a permissive write policy here.

-- ── 3. email_events ────────────────────────────────────────────────────
-- Outbound email audit + open/click tracking. Sibling of `correspondence`
-- but for transactional emails Advocat sends ON ITS OWN behalf
-- (digest, winback) rather than on the user's behalf.
--
-- One row per send. Open / click pixels and links carry the row id.
do $$ begin
  if not exists (select 1 from pg_type where typname = 'retention_email_kind') then
    create type retention_email_kind as enum
      ('weekly_digest','winback_d3','winback_d7','winback_d14','insight_alert');
  end if;
end $$;

create table if not exists public.email_events (
    id                  uuid primary key default gen_random_uuid(),
    user_id             uuid not null references auth.users(id) on delete cascade,
    kind                retention_email_kind not null,
    recipient_email     text not null,
    subject             text not null,
    body_excerpt        text,                  -- first 500 chars, for audit
    provider            text not null default 'resend',
    provider_message_id text,
    sent_at             timestamptz not null default now(),
    opened_at           timestamptz,
    clicked_at          timestamptz,
    bounce_at           timestamptz,
    bounce_reason       text,
    unsubscribed_at     timestamptz,
    error               text
);

create index if not exists email_events_user_idx
    on public.email_events (user_id, sent_at desc);
create index if not exists email_events_kind_idx
    on public.email_events (kind, sent_at desc);
-- Prevent double-send of the same winback step within 1 day
create unique index if not exists email_events_user_kind_day_idx
    on public.email_events (user_id, kind, (sent_at::date))
    where kind in ('winback_d3','winback_d7','winback_d14','weekly_digest');

alter table public.email_events enable row level security;

drop policy if exists email_events_owner_select on public.email_events;
create policy email_events_owner_select
    on public.email_events for select
    to authenticated
    using (auth.uid() = user_id);

-- ── 4. push_events ─────────────────────────────────────────────────────
-- Outbound FCM audit. Mirrors email_events. Used to throttle re-engagement
-- pushes (cap 1/day non-deadline) and to debug FCM delivery.
do $$ begin
  if not exists (select 1 from pg_type where typname = 'retention_push_kind') then
    create type retention_push_kind as enum
      ('deadline_reminder','insight_ready','counterparty_reply','reengagement');
  end if;
end $$;

create table if not exists public.push_events (
    id              uuid primary key default gen_random_uuid(),
    user_id         uuid not null references auth.users(id) on delete cascade,
    kind            retention_push_kind not null,
    title           text,
    body            text,
    fcm_message_id  text,
    sent_at         timestamptz not null default now(),
    delivered       boolean not null default false,
    error           text
);

create index if not exists push_events_user_idx
    on public.push_events (user_id, sent_at desc);

alter table public.push_events enable row level security;

drop policy if exists push_events_owner_select on public.push_events;
create policy push_events_owner_select
    on public.push_events for select
    to authenticated
    using (auth.uid() = user_id);

-- ── 5. RPCs ────────────────────────────────────────────────────────────

-- bump_engagement: called from chat / case / login paths to record an
-- active session. SECURITY DEFINER so it can write across users (cron
-- and the chat edge fn already run as service_role; we still keep the
-- RPC so the client can call it without service-role).
create or replace function public.bump_engagement(
    p_user_id uuid,
    p_event   text default 'session'
) returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into user_engagement (user_id, last_active_at, sessions_count, churned)
    values (p_user_id, now(), 1, false)
    on conflict (user_id) do update
        set last_active_at = now(),
            sessions_count = case
                when p_event in ('session','login') then user_engagement.sessions_count + 1
                else user_engagement.sessions_count
            end,
            chat_turns_count = case
                when p_event = 'chat_turn' then user_engagement.chat_turns_count + 1
                else user_engagement.chat_turns_count
            end,
            churned = false;
end;
$$;

revoke all on function public.bump_engagement(uuid, text) from public;
grant execute on function public.bump_engagement(uuid, text)
    to authenticated, service_role;

-- digest_candidates: rows the weekly-digest worker should email.
-- Server-only — invoked from edge fn with service-role key.
-- Returns user_id + email + last_digest_sent_at + active case count.
create or replace function public.digest_candidates(
    p_max_rows integer default 1000
) returns table (
    user_id              uuid,
    email                text,
    full_name            text,
    preferred_language   text,
    last_digest_sent_at  timestamptz,
    active_case_count    bigint
)
language sql
security definer
set search_path = public
as $$
    select
        u.id as user_id,
        u.email,
        coalesce(u.full_name, '') as full_name,
        coalesce(u.preferred_language, 'en') as preferred_language,
        e.last_digest_sent_at,
        (
            select count(*) from user_cases c
            where c.user_id = u.id and c.status = 'active'
        ) as active_case_count
    from public.users u
    left join public.notification_preferences np on np.user_id = u.id
    left join public.user_engagement e on e.user_id = u.id
    where coalesce(np.all_email_disabled, false) = false
      and coalesce(np.email_digest_enabled, true) = true
      and coalesce(np.digest_frequency, 'weekly') <> 'off'
      and (
          e.last_digest_sent_at is null
          or e.last_digest_sent_at < (now() - interval '6 days')
      )
      and exists (
          select 1 from user_cases c
          where c.user_id = u.id and c.status = 'active'
      )
    order by coalesce(e.last_digest_sent_at, '1970-01-01'::timestamptz) asc
    limit p_max_rows;
$$;

revoke all on function public.digest_candidates(integer) from public;
grant execute on function public.digest_candidates(integer) to service_role;

-- winback_candidates: rows the winback worker should email. Returns
-- user_id, email, target_step (d3/d7/d14), last_active_at, preferred_language.
-- Strict eligibility: never re-send same step, cap 3 winbacks per user
-- lifetime, never message a user with no recorded engagement (means
-- onboarding never recorded a session — winback would be premature).
create or replace function public.winback_candidates(
    p_max_rows integer default 500,
    p_now timestamptz default now()
) returns table (
    user_id              uuid,
    email                text,
    full_name            text,
    preferred_language   text,
    last_active_at       timestamptz,
    target_step          text,
    winback_sent_count   integer
)
language sql
security definer
set search_path = public
as $$
    with eligible as (
        select
            u.id as user_id,
            u.email,
            coalesce(u.full_name, '') as full_name,
            coalesce(u.preferred_language, 'en') as preferred_language,
            e.last_active_at,
            e.winback_sent_count,
            e.winback_d3_sent_at,
            e.winback_d7_sent_at,
            e.winback_d14_sent_at,
            case
                when e.winback_d14_sent_at is null
                     and e.last_active_at < (p_now - interval '14 days') then 'd14'
                when e.winback_d7_sent_at is null
                     and e.last_active_at < (p_now - interval '7 days')
                     and e.last_active_at >= (p_now - interval '14 days') then 'd7'
                when e.winback_d3_sent_at is null
                     and e.last_active_at < (p_now - interval '3 days')
                     and e.last_active_at >= (p_now - interval '7 days') then 'd3'
                else null
            end as target_step
        from public.users u
        join public.user_engagement e on e.user_id = u.id
        left join public.notification_preferences np on np.user_id = u.id
        where coalesce(np.all_email_disabled, false) = false
          and coalesce(np.email_winback_enabled, true) = true
          and coalesce(e.churned, false) = false
          and coalesce(e.winback_sent_count, 0) < 3
    )
    select user_id, email, full_name, preferred_language,
           last_active_at, target_step, winback_sent_count
    from eligible
    where target_step is not null
    order by last_active_at asc
    limit p_max_rows;
$$;

revoke all on function public.winback_candidates(integer, timestamptz) from public;
grant execute on function public.winback_candidates(integer, timestamptz)
    to service_role;

-- record_winback_sent: idempotent stamp for a winback step.
create or replace function public.record_winback_sent(
    p_user_id uuid,
    p_step    text  -- 'd3' | 'd7' | 'd14'
) returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into user_engagement (user_id) values (p_user_id)
    on conflict (user_id) do nothing;

    update user_engagement set
        winback_sent_count = winback_sent_count + 1,
        last_winback_sent_at = now(),
        winback_d3_sent_at = case
            when p_step = 'd3' then now() else winback_d3_sent_at end,
        winback_d7_sent_at = case
            when p_step = 'd7' then now() else winback_d7_sent_at end,
        winback_d14_sent_at = case
            when p_step = 'd14' then now() else winback_d14_sent_at end,
        churned = case
            when p_step = 'd14' then true else churned end
    where user_id = p_user_id;
end;
$$;

revoke all on function public.record_winback_sent(uuid, text) from public;
grant execute on function public.record_winback_sent(uuid, text) to service_role;

-- record_digest_sent: stamp last_digest_sent_at after a successful send.
create or replace function public.record_digest_sent(
    p_user_id uuid
) returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into user_engagement (user_id, last_digest_sent_at) values (p_user_id, now())
    on conflict (user_id) do update set last_digest_sent_at = now();
end;
$$;

revoke all on function public.record_digest_sent(uuid) from public;
grant execute on function public.record_digest_sent(uuid) to service_role;

-- unsubscribe_by_token: one-click unsubscribe target. Public RPC; the
-- secret is the unguessable uuid in the email link. Sets the all-email
-- killswitch and the per-kind flag if `p_kind` is provided.
create or replace function public.unsubscribe_by_token(
    p_token uuid,
    p_kind  text default null  -- 'digest' | 'winback' | null = all
) returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
    v_uid uuid;
begin
    select user_id into v_uid
    from notification_preferences
    where unsubscribe_token = p_token;

    if v_uid is null then
        return false;
    end if;

    update notification_preferences set
        all_email_disabled = case
            when p_kind is null then true else all_email_disabled end,
        email_digest_enabled = case
            when p_kind = 'digest' then false else email_digest_enabled end,
        email_winback_enabled = case
            when p_kind = 'winback' then false else email_winback_enabled end
    where user_id = v_uid;

    return true;
end;
$$;

revoke all on function public.unsubscribe_by_token(uuid, text) from public;
-- anon role can call this because the token IS the auth
grant execute on function public.unsubscribe_by_token(uuid, text)
    to anon, authenticated, service_role;

-- ── 6. Backfill helper ────────────────────────────────────────────────
-- For every existing auth user, ensure a preferences row exists with
-- defaults. Run-once; safe to re-run.
insert into public.notification_preferences (user_id)
    select id from auth.users
    on conflict (user_id) do nothing;

insert into public.user_engagement (user_id, last_active_at)
    select id, coalesce(created_at, now()) from auth.users
    on conflict (user_id) do nothing;

-- ── 7. Scheduling note (NOT executed automatically) ──────────────────
-- pg_cron is enabled at the project level by Supabase support. Once
-- enabled, the owner runs the following one-off SQL (NOT in a migration,
-- because cron secrets / URLs change per environment):
--
--   -- Mondays 08:00 Europe/Tallinn (=05:00 UTC summer / 06:00 UTC winter)
--   -- We fire 05:00 + 06:00 + 07:00 UTC so daylight saving doesn't slip
--   -- the window; the edge fn de-dupes via email_events unique index.
--   select cron.schedule('weekly-digest-05', '0 5 * * 1', $$
--     select net.http_post(
--       url := 'https://<project>.functions.supabase.co/weekly-digest-send',
--       headers := jsonb_build_object('x-cron-secret', current_setting('app.cron_secret'))
--     );
--   $$);
--   select cron.schedule('weekly-digest-06', '0 6 * * 1', $$...$$);
--
--   -- Daily 10:00 Europe/Tallinn for winback
--   select cron.schedule('winback-daily', '0 7 * * *', $$
--     select net.http_post(
--       url := 'https://<project>.functions.supabase.co/winback-send',
--       headers := jsonb_build_object('x-cron-secret', current_setting('app.cron_secret'))
--     );
--   $$);
--
-- See reference_scheduled_triggers.md for full owner playbook.
