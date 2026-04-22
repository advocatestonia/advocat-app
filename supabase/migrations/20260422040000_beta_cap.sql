-- =============================================================================
-- Migration: app_config table + Founder's Beta 25-user cap
-- Date: 2026-04-22
-- Task: feature/founder-beta-pricing
-- =============================================================================
--
-- Runtime-tweakable key/value store for simple toggles (feature flags, caps).
-- Read by create-checkout to enforce the 25-user Founder's Beta cap without
-- needing a code deploy when the cap changes.
--
-- Why not env vars: owner wants to flip `active: false` from the Supabase
-- dashboard the moment we hit 25 paid users, without touching env/CI.
--
-- Safety:
--   - Readable by authenticated + anon (so landing.html can show "full"
--     state without auth). Writes are service-role only.
--   - Single INSERT guarded by ON CONFLICT DO NOTHING so re-running the
--     migration never overwrites the live value.
-- =============================================================================

create table if not exists public.app_config (
  key         text primary key,
  value       jsonb not null,
  updated_at  timestamptz not null default now()
);

comment on table public.app_config is
  'Runtime-tweakable key/value store. Edit via Supabase dashboard, never via migrations after seed.';

alter table public.app_config enable row level security;

-- Everyone (including unauthenticated) may read. This is intentional — the
-- landing page needs to show "Founder's Beta full" to visitors before they
-- sign in. Writes are service-role only (no insert/update/delete policy).
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename  = 'app_config'
      and policyname = 'app_config_public_read'
  ) then
    create policy "app_config_public_read"
      on public.app_config
      for select
      using (true);
  end if;
end$$;

-- Seed the beta_cap entry on first run. ON CONFLICT DO NOTHING so
-- re-applying the migration doesn't clobber a value the owner already
-- tweaked from the dashboard (e.g. bumping the cap to 50).

insert into public.app_config (key, value)
values (
  'beta_cap',
  jsonb_build_object(
    'max_paying_users', 25,
    'active',           true,
    'badge_text',       'Founder''s Beta v1.0'
  )
)
on conflict (key) do nothing;
