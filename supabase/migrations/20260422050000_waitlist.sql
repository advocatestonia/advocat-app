-- =============================================================================
-- Migration: waitlist table for Founder's Beta overflow
-- Date: 2026-04-22
-- Task: feature/founder-beta-pricing
-- =============================================================================
--
-- Email collection for users blocked by the 25-user Founder's Beta cap
-- (see 20260422_beta_cap.sql). Edge Function join-waitlist is the only
-- writer. No PII beyond email + source is stored.
--
-- GDPR: one-click unsubscribe honoured via DELETE on the row (service-role
-- from a custom Edge Function triggered by an unsubscribe link in the
-- invite email).
-- =============================================================================

create table if not exists public.waitlist (
  id            uuid        primary key default gen_random_uuid(),
  email         text        not null unique,
  source        text,                    -- 'beta_cap_full' | 'landing' | ...
  created_at    timestamptz not null default now(),
  notified_at   timestamptz
);

create index if not exists idx_waitlist_created
  on public.waitlist (created_at asc);

alter table public.waitlist enable row level security;

-- No end-user policy at all: the Edge Function uses service_role. Owner
-- lists the waitlist via the Supabase dashboard. A user querying their
-- own position hits the /join-waitlist endpoint, which returns the
-- position server-side without requiring a SELECT grant on the table.

comment on table public.waitlist is
  'Founder''s Beta overflow waitlist. Email-only, service-role writes (join-waitlist). No end-user RLS policy.';
