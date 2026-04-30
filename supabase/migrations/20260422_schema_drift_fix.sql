-- ============================================================================
-- Sprint 0 — FIX-3 — Schema drift tracking (idempotent, owner-applied)
-- Date: 2026-04-22
-- Ref: docs/security/02-auth-authz.md H1
--
-- PROBLEM: Edge Functions reference four tables that are NOT declared in any
-- migration in the repo: profiles, subscriptions, notifications,
-- user_oauth_tokens. Most likely these were created manually via the
-- Supabase Dashboard at some point. The RLS status on them is UNKNOWN from
-- the code alone — if any table has rowsecurity=false, it's a critical
-- security hole (a user with just the anon key could write
-- subscriptions.status='active' for themselves).
--
-- THIS MIGRATION: adds the declarative schema for all four tables in an
-- idempotent, additive way:
--   - CREATE TABLE ... IF NOT EXISTS   (never ALTERs existing tables)
--   - ENABLE ROW LEVEL SECURITY IF NOT ALREADY ENABLED
--   - CREATE POLICY ... only when pg_policies shows the policy is missing
--
-- After applying, the repo matches production. Owner may need to run the
-- verification query from docs/security/FINAL.md §Action 3 first to check
-- what's actually in prod, and tweak column lists to match before pushing.
--
-- SAFETY GATES:
--   - This migration never DROPs or ALTERs anything
--   - Columns used below are the SMALLEST SET the Edge Functions read/write
--     (see docs/security/02-auth-authz.md H1 table). Owner should compare
--     the column names here against `pg_attribute` on prod; if prod has
--     extra columns the migration leaves them alone because CREATE TABLE
--     IF NOT EXISTS is a no-op on existing tables.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------------
-- Used by: check-ai-quota, customer-portal, deadline-reminder, send-email,
--          stripe-webhook, supabase_service.dart (exportUserData,
--          deleteAllUserData).
-- Columns read/written: id, email, full_name, preferred_language, is_pro,
--          stripe_customer_id, subscription_tier, subscription_expires_at,
--          subscription_status.
-- FK: id -> auth.users(id) on delete cascade — mirrors public.users from 001.

create table if not exists public.profiles (
  id                       uuid primary key references auth.users(id) on delete cascade,
  email                    text,
  full_name                text,
  preferred_language       varchar(5),
  is_pro                   boolean not null default false,
  stripe_customer_id       text,
  subscription_tier        text not null default 'free',
  subscription_expires_at  timestamptz,
  subscription_status      text,
  created_at               timestamptz not null default now(),
  updated_at               timestamptz
);

-- ALTER TABLE ADD COLUMN IF NOT EXISTS for pre-existing profiles tables
-- (dashboard-created tables may lack some of these columns).
alter table public.profiles add column if not exists email text;
alter table public.profiles add column if not exists full_name text;
alter table public.profiles add column if not exists preferred_language varchar(5);
alter table public.profiles add column if not exists is_pro boolean not null default false;
alter table public.profiles add column if not exists stripe_customer_id text;
alter table public.profiles add column if not exists subscription_tier text not null default 'free';
alter table public.profiles add column if not exists subscription_expires_at timestamptz;
alter table public.profiles add column if not exists subscription_status text;
alter table public.profiles add column if not exists created_at timestamptz not null default now();
alter table public.profiles add column if not exists updated_at timestamptz;

create index if not exists idx_profiles_stripe_customer
  on public.profiles (stripe_customer_id)
  where stripe_customer_id is not null;

create index if not exists idx_profiles_email on public.profiles (lower(email));

-- ---------------------------------------------------------------------------
-- subscriptions
-- ---------------------------------------------------------------------------
-- Used by: check-ai-quota.
-- A denormalised "is this user currently paying?" table. Many apps keep
-- this data on profiles, but the query in check-ai-quota expects a separate
-- row, so we declare it here to match prod.

create table if not exists public.subscriptions (
  id                       uuid primary key default gen_random_uuid(),
  user_id                  uuid not null references auth.users(id) on delete cascade,
  status                   text not null default 'inactive',
  stripe_subscription_id   text,
  tier                     text,
  current_period_end       timestamptz,
  created_at               timestamptz not null default now(),
  updated_at               timestamptz
);

alter table public.subscriptions add column if not exists user_id uuid references auth.users(id) on delete cascade;
alter table public.subscriptions add column if not exists status text not null default 'inactive';
alter table public.subscriptions add column if not exists stripe_subscription_id text;
alter table public.subscriptions add column if not exists tier text;
alter table public.subscriptions add column if not exists current_period_end timestamptz;
alter table public.subscriptions add column if not exists created_at timestamptz not null default now();
alter table public.subscriptions add column if not exists updated_at timestamptz;

create index if not exists idx_subscriptions_user_active
  on public.subscriptions (user_id, status);

-- ---------------------------------------------------------------------------
-- notifications
-- ---------------------------------------------------------------------------
-- Used by: deadline-reminder (insert-only).
-- User-scoped notification feed for in-app delivery.

create table if not exists public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  type       text not null default 'info',
  title      text,
  body       text,
  read       boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.notifications add column if not exists user_id uuid references auth.users(id) on delete cascade;
alter table public.notifications add column if not exists type text not null default 'info';
alter table public.notifications add column if not exists title text;
alter table public.notifications add column if not exists body text;
alter table public.notifications add column if not exists read boolean not null default false;
alter table public.notifications add column if not exists created_at timestamptz not null default now();

create index if not exists idx_notifications_user_created
  on public.notifications (user_id, created_at desc);

-- ---------------------------------------------------------------------------
-- user_oauth_tokens
-- ---------------------------------------------------------------------------
-- Used by: send-email (reads Gmail OAuth access_token).
-- Sensitive — contains OAuth bearer tokens. Must have strict RLS.

create table if not exists public.user_oauth_tokens (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  provider      text not null default 'gmail',
  access_token  text not null default '',
  refresh_token text,
  email         text,
  expires_at    timestamptz,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz
);

alter table public.user_oauth_tokens add column if not exists user_id uuid references auth.users(id) on delete cascade;
alter table public.user_oauth_tokens add column if not exists provider text not null default 'gmail';
alter table public.user_oauth_tokens add column if not exists access_token text not null default '';
alter table public.user_oauth_tokens add column if not exists refresh_token text;
alter table public.user_oauth_tokens add column if not exists email text;
alter table public.user_oauth_tokens add column if not exists expires_at timestamptz;
alter table public.user_oauth_tokens add column if not exists created_at timestamptz not null default now();
alter table public.user_oauth_tokens add column if not exists updated_at timestamptz;

do $$
begin
  if not exists (select 1 from pg_constraint where conname='user_oauth_tokens_user_provider_key') then
    alter table public.user_oauth_tokens add constraint user_oauth_tokens_user_provider_key unique (user_id, provider);
  end if;
exception when others then null;
end$$;

create index if not exists idx_user_oauth_tokens_user_provider
  on public.user_oauth_tokens (user_id, provider);

-- ---------------------------------------------------------------------------
-- Row Level Security — enable on every table if not already
-- ---------------------------------------------------------------------------

alter table public.profiles          enable row level security;
alter table public.subscriptions     enable row level security;
alter table public.notifications     enable row level security;
alter table public.user_oauth_tokens enable row level security;

-- ---------------------------------------------------------------------------
-- Policies (idempotent — guarded by pg_policies lookup)
-- ---------------------------------------------------------------------------

-- profiles: users can read/update their own row only. Insert is done by a
-- trigger (mirroring the handle_new_user pattern in 001) — no INSERT policy
-- for regular auth. stripe-webhook uses service_role and bypasses RLS.
do $$
begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='profiles' and policyname='profiles_select_own') then
    create policy "profiles_select_own" on public.profiles for select using (auth.uid() = id);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='profiles' and policyname='profiles_update_own') then
    create policy "profiles_update_own" on public.profiles for update using (auth.uid() = id);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='profiles' and policyname='profiles_delete_own') then
    -- GDPR Art. 17 — required for supabase_service.dart:373 deleteAllUserData
    create policy "profiles_delete_own" on public.profiles for delete using (auth.uid() = id);
  end if;
end$$;

-- subscriptions: read-only for the owner. Inserts/updates come exclusively
-- from stripe-webhook (service_role, bypasses RLS). Deletes allowed only on
-- cascade from auth.users.
do $$
begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='subscriptions' and policyname='subscriptions_select_own') then
    create policy "subscriptions_select_own" on public.subscriptions for select using (auth.uid() = user_id);
  end if;
end$$;

-- notifications: user can read + mark-as-read own rows. Inserts come only
-- from deadline-reminder (service_role). Delete allowed for dismissal.
do $$
begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='notifications' and policyname='notifications_select_own') then
    create policy "notifications_select_own" on public.notifications for select using (auth.uid() = user_id);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='notifications' and policyname='notifications_update_own') then
    create policy "notifications_update_own" on public.notifications for update using (auth.uid() = user_id);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='notifications' and policyname='notifications_delete_own') then
    create policy "notifications_delete_own" on public.notifications for delete using (auth.uid() = user_id);
  end if;
end$$;

-- user_oauth_tokens: users can read + delete their own tokens. Inserts +
-- updates are done exclusively server-side by the OAuth callback flow
-- (service_role, bypasses RLS). Delete supports revoking Gmail/Outlook
-- access from the app settings screen.
do $$
begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='user_oauth_tokens' and policyname='user_oauth_tokens_select_own') then
    create policy "user_oauth_tokens_select_own" on public.user_oauth_tokens for select using (auth.uid() = user_id);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='user_oauth_tokens' and policyname='user_oauth_tokens_delete_own') then
    create policy "user_oauth_tokens_delete_own" on public.user_oauth_tokens for delete using (auth.uid() = user_id);
  end if;
end$$;

-- ============================================================================
-- Idempotency: run twice, second run must be a no-op. Every CREATE TABLE
-- uses IF NOT EXISTS; every CREATE POLICY is guarded by a pg_policies
-- existence check. ENABLE ROW LEVEL SECURITY is inherently idempotent.
-- ============================================================================
