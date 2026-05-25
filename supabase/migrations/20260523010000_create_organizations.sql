-- ============================================================================
-- 20260523010000_create_organizations.sql
-- Migration 31/37 — B2B multi-tenant core.
-- See business/build/B2B_ARCHITECTURE.md §2 and business/build/MIGRATIONS_PLAN.md.
--
-- Creates 8 core B2B tables. NO retrofit of existing tables here (that lives
-- in migration 33). Strictly additive + idempotent. B2C semantics untouched.
-- ============================================================================

create extension if not exists pgcrypto;
create extension if not exists "uuid-ossp";

-- ── enums (idempotent guards) ────────────────────────────────────────────────
do $$ begin
  if not exists (select 1 from pg_type where typname = 'org_plan') then
    create type public.org_plan as enum ('starter','firm','enterprise');
  end if;
end $$;

do $$ begin
  if not exists (select 1 from pg_type where typname = 'org_status') then
    create type public.org_status as enum ('trial','active','past_due','canceled','suspended');
  end if;
end $$;

do $$ begin
  if not exists (select 1 from pg_type where typname = 'org_role') then
    create type public.org_role as enum ('owner','admin','member','viewer','billing');
  end if;
end $$;

-- ── 1. organizations ─────────────────────────────────────────────────────────
create table if not exists public.organizations (
  id                     uuid primary key default gen_random_uuid(),
  slug                   text not null unique check (slug ~ '^[a-z0-9-]{3,40}$'),
  name                   text not null check (length(name) between 1 and 120),
  legal_name             text check (legal_name is null or length(legal_name) <= 200),
  vat_id                 text check (vat_id is null or length(vat_id) <= 32),
  country                char(2) check (country is null or country ~ '^[A-Z]{2}$'),
  billing_email          text check (billing_email is null or length(billing_email) between 3 and 254),
  plan                   public.org_plan not null default 'starter',
  seat_count             int not null default 1 check (seat_count >= 0),
  seat_limit             int not null default 5 check (seat_limit > 0),
  stripe_customer_id     text,
  stripe_subscription_id text,
  trial_ends_at          timestamptz,
  status                 public.org_status not null default 'trial',
  created_by             uuid references auth.users(id) on delete set null,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now(),
  deleted_at             timestamptz
);

create index if not exists idx_organizations_status
  on public.organizations (status) where deleted_at is null;
create index if not exists idx_organizations_created_by
  on public.organizations (created_by);
create index if not exists idx_organizations_stripe_cust
  on public.organizations (stripe_customer_id) where stripe_customer_id is not null;
create index if not exists idx_organizations_stripe_sub
  on public.organizations (stripe_subscription_id) where stripe_subscription_id is not null;

drop trigger if exists organizations_updated_at on public.organizations;
create trigger organizations_updated_at
  before update on public.organizations
  for each row execute function public.set_updated_at();

-- ── 2. org_members ───────────────────────────────────────────────────────────
create table if not exists public.org_members (
  id          uuid primary key default gen_random_uuid(),
  org_id      uuid not null references public.organizations(id) on delete cascade,
  user_id     uuid not null references auth.users(id) on delete cascade,
  role        public.org_role not null default 'member',
  invited_by  uuid references auth.users(id) on delete set null,
  joined_at   timestamptz not null default now(),
  removed_at  timestamptz,
  unique (org_id, user_id)
);

create index if not exists idx_org_members_user_active
  on public.org_members (user_id) where removed_at is null;
create index if not exists idx_org_members_org_active
  on public.org_members (org_id) where removed_at is null;
create index if not exists idx_org_members_role
  on public.org_members (org_id, role) where removed_at is null;

-- ── 3. org_invitations ───────────────────────────────────────────────────────
create table if not exists public.org_invitations (
  id          uuid primary key default gen_random_uuid(),
  org_id      uuid not null references public.organizations(id) on delete cascade,
  email       text not null check (length(email) between 3 and 254),
  role        public.org_role not null default 'member',
  invited_by  uuid not null references auth.users(id) on delete cascade,
  token_hash  text not null,
  expires_at  timestamptz not null default (now() + interval '7 days'),
  accepted_at timestamptz,
  accepted_by uuid references auth.users(id) on delete set null,
  revoked_at  timestamptz,
  created_at  timestamptz not null default now()
);

create unique index if not exists uniq_org_invitations_token_hash
  on public.org_invitations (token_hash);
create index if not exists idx_org_invitations_email_pending
  on public.org_invitations (lower(email))
  where accepted_at is null and revoked_at is null;
create index if not exists idx_org_invitations_org_pending
  on public.org_invitations (org_id, created_at desc)
  where accepted_at is null and revoked_at is null;

-- ── 4. org_subscriptions ─────────────────────────────────────────────────────
create table if not exists public.org_subscriptions (
  id                      uuid primary key default gen_random_uuid(),
  org_id                  uuid not null unique references public.organizations(id) on delete cascade,
  stripe_subscription_id  text not null unique,
  stripe_customer_id      text not null,
  plan                    public.org_plan not null,
  billing_period          text not null check (billing_period in ('monthly','yearly')),
  seats_paid              int not null check (seats_paid > 0),
  unit_amount_cents       int not null check (unit_amount_cents > 0),
  currency                text not null default 'eur' check (currency = lower(currency)),
  status                  text not null,
  current_period_start    timestamptz,
  current_period_end      timestamptz,
  trial_end               timestamptz,
  cancel_at_period_end    boolean not null default false,
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now()
);

drop trigger if exists org_subscriptions_updated_at on public.org_subscriptions;
create trigger org_subscriptions_updated_at
  before update on public.org_subscriptions
  for each row execute function public.set_updated_at();

-- ── 5. org_api_keys ──────────────────────────────────────────────────────────
create table if not exists public.org_api_keys (
  id           uuid primary key default gen_random_uuid(),
  org_id       uuid not null references public.organizations(id) on delete cascade,
  name         text not null check (length(name) between 1 and 80),
  prefix       text not null,
  key_hash     text not null unique,
  scopes       text[] not null default '{}'::text[],
  created_by   uuid not null references auth.users(id),
  last_used_at timestamptz,
  expires_at   timestamptz,
  revoked_at   timestamptz,
  created_at   timestamptz not null default now()
);

create index if not exists idx_org_api_keys_org_active
  on public.org_api_keys (org_id) where revoked_at is null;
create index if not exists idx_org_api_keys_prefix
  on public.org_api_keys (prefix);

-- ── 6. org_branding ──────────────────────────────────────────────────────────
create table if not exists public.org_branding (
  org_id          uuid primary key references public.organizations(id) on delete cascade,
  logo_url        text,
  primary_color   text check (primary_color is null or primary_color ~ '^#[0-9A-Fa-f]{6}$'),
  accent_color    text check (accent_color is null or accent_color ~ '^#[0-9A-Fa-f]{6}$'),
  custom_domain   text unique,
  support_email   text,
  footer_html     text check (footer_html is null or length(footer_html) <= 2000),
  updated_at      timestamptz not null default now()
);

drop trigger if exists org_branding_updated_at on public.org_branding;
create trigger org_branding_updated_at
  before update on public.org_branding
  for each row execute function public.set_updated_at();

-- ── 7. org_audit_log ─────────────────────────────────────────────────────────
create table if not exists public.org_audit_log (
  id                    uuid primary key default gen_random_uuid(),
  org_id                uuid not null references public.organizations(id) on delete cascade,
  actor_user_id         uuid references auth.users(id) on delete set null,
  action                text not null,
  target_user_id        uuid references auth.users(id) on delete set null,
  target_resource_type  text,
  target_resource_id    uuid,
  details               jsonb not null default '{}'::jsonb,
  ip                    inet,
  user_agent            text check (user_agent is null or length(user_agent) <= 500),
  created_at            timestamptz not null default now()
);

create index if not exists idx_org_audit_log_org_ts
  on public.org_audit_log (org_id, created_at desc);
create index if not exists idx_org_audit_log_actor
  on public.org_audit_log (actor_user_id, created_at desc);
create index if not exists idx_org_audit_log_action
  on public.org_audit_log (org_id, action, created_at desc);

-- ── 8. org_usage_counters ────────────────────────────────────────────────────
create table if not exists public.org_usage_counters (
  org_id              uuid not null references public.organizations(id) on delete cascade,
  period_start        timestamptz not null,
  period_end          timestamptz not null,
  messages_sent       int not null default 0,
  documents_uploaded  int not null default 0,
  cases_created       int not null default 0,
  api_calls           int not null default 0,
  primary key (org_id, period_start)
);

create index if not exists idx_org_usage_org_recent
  on public.org_usage_counters (org_id, period_start desc);

-- ── grants (RLS still gates row visibility; this just opens the API surface) ─
grant select on public.organizations      to authenticated;
grant select on public.org_members        to authenticated;
grant select on public.org_invitations    to authenticated;
grant select on public.org_subscriptions  to authenticated;
grant select on public.org_api_keys       to authenticated;
grant select on public.org_branding       to authenticated;
grant select on public.org_audit_log      to authenticated;
grant select on public.org_usage_counters to authenticated;
grant update (name, legal_name, vat_id, country, billing_email)
  on public.organizations to authenticated;
grant update on public.org_branding to authenticated;

notify pgrst, 'reload schema';

-- ROLLBACK:
-- drop table if exists public.org_usage_counters cascade;
-- drop table if exists public.org_audit_log cascade;
-- drop table if exists public.org_branding cascade;
-- drop table if exists public.org_api_keys cascade;
-- drop table if exists public.org_subscriptions cascade;
-- drop table if exists public.org_invitations cascade;
-- drop table if exists public.org_members cascade;
-- drop table if exists public.organizations cascade;
-- drop type if exists public.org_role;
-- drop type if exists public.org_status;
-- drop type if exists public.org_plan;
