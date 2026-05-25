-- ============================================================================
-- 20260523020000_org_rls_policies.sql
-- Migration 32/37 — RLS helper functions + policies for B2B core tables.
--
-- Helper functions: current_user_org_ids(), current_user_org_role(uuid).
-- All writes flow through service_role edge functions; this migration only
-- exposes safe read paths to authenticated users.
-- ============================================================================

-- ── helper: current_user_org_ids ─────────────────────────────────────────────
create or replace function public.current_user_org_ids()
returns setof uuid
language sql
stable
security definer
set search_path = public
as $$
  select org_id
  from public.org_members
  where user_id = auth.uid()
    and removed_at is null
$$;

revoke all on function public.current_user_org_ids() from public;
grant execute on function public.current_user_org_ids() to authenticated;

-- ── helper: current_user_org_role(p_org) ─────────────────────────────────────
create or replace function public.current_user_org_role(p_org uuid)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role::text
  from public.org_members
  where user_id = auth.uid()
    and org_id = p_org
    and removed_at is null
  limit 1
$$;

revoke all on function public.current_user_org_role(uuid) from public;
grant execute on function public.current_user_org_role(uuid) to authenticated;

-- ── organizations ────────────────────────────────────────────────────────────
alter table public.organizations enable row level security;

drop policy if exists organizations_select_member on public.organizations;
create policy organizations_select_member
  on public.organizations for select to authenticated
  using (id in (select public.current_user_org_ids()) and deleted_at is null);

drop policy if exists organizations_update_admin on public.organizations;
create policy organizations_update_admin
  on public.organizations for update to authenticated
  using (
    id in (select public.current_user_org_ids())
    and public.current_user_org_role(id) in ('owner','admin','billing')
  )
  with check (
    id in (select public.current_user_org_ids())
    and public.current_user_org_role(id) in ('owner','admin','billing')
  );
-- INSERT and DELETE flow through service_role edge functions only.

-- ── org_members ──────────────────────────────────────────────────────────────
alter table public.org_members enable row level security;

drop policy if exists org_members_select_in_org on public.org_members;
create policy org_members_select_in_org
  on public.org_members for select to authenticated
  using (
    org_id in (select public.current_user_org_ids())
    and removed_at is null
  );
-- All mutations: service_role only.

-- ── org_invitations ──────────────────────────────────────────────────────────
alter table public.org_invitations enable row level security;

drop policy if exists org_invitations_select_admins on public.org_invitations;
create policy org_invitations_select_admins
  on public.org_invitations for select to authenticated
  using (
    org_id in (select public.current_user_org_ids())
    and public.current_user_org_role(org_id) in ('owner','admin')
  );
-- Invited user discovers their pending invite via SECURITY DEFINER RPC, not direct read.

-- ── org_subscriptions ────────────────────────────────────────────────────────
alter table public.org_subscriptions enable row level security;

drop policy if exists org_subscriptions_select_billing on public.org_subscriptions;
create policy org_subscriptions_select_billing
  on public.org_subscriptions for select to authenticated
  using (
    org_id in (select public.current_user_org_ids())
    and public.current_user_org_role(org_id) in ('owner','admin','billing')
  );

-- ── org_api_keys ─────────────────────────────────────────────────────────────
alter table public.org_api_keys enable row level security;

drop policy if exists org_api_keys_select_admin on public.org_api_keys;
create policy org_api_keys_select_admin
  on public.org_api_keys for select to authenticated
  using (
    org_id in (select public.current_user_org_ids())
    and public.current_user_org_role(org_id) in ('owner','admin')
    and revoked_at is null
  );

-- ── org_branding ─────────────────────────────────────────────────────────────
alter table public.org_branding enable row level security;

drop policy if exists org_branding_select_member on public.org_branding;
create policy org_branding_select_member
  on public.org_branding for select to authenticated
  using (org_id in (select public.current_user_org_ids()));

drop policy if exists org_branding_update_admin on public.org_branding;
create policy org_branding_update_admin
  on public.org_branding for update to authenticated
  using (
    org_id in (select public.current_user_org_ids())
    and public.current_user_org_role(org_id) in ('owner','admin')
  )
  with check (
    org_id in (select public.current_user_org_ids())
    and public.current_user_org_role(org_id) in ('owner','admin')
  );

drop policy if exists org_branding_insert_admin on public.org_branding;
create policy org_branding_insert_admin
  on public.org_branding for insert to authenticated
  with check (
    org_id in (select public.current_user_org_ids())
    and public.current_user_org_role(org_id) in ('owner','admin')
  );

-- ── org_audit_log ────────────────────────────────────────────────────────────
alter table public.org_audit_log enable row level security;

drop policy if exists org_audit_log_select_admin on public.org_audit_log;
create policy org_audit_log_select_admin
  on public.org_audit_log for select to authenticated
  using (
    org_id in (select public.current_user_org_ids())
    and public.current_user_org_role(org_id) in ('owner','admin')
  );
-- Writes are service_role only.

-- ── org_usage_counters ───────────────────────────────────────────────────────
alter table public.org_usage_counters enable row level security;

drop policy if exists org_usage_counters_select_billing on public.org_usage_counters;
create policy org_usage_counters_select_billing
  on public.org_usage_counters for select to authenticated
  using (
    org_id in (select public.current_user_org_ids())
    and public.current_user_org_role(org_id) in ('owner','admin','billing')
  );

notify pgrst, 'reload schema';

-- ROLLBACK:
-- drop policy if exists organizations_select_member        on public.organizations;
-- drop policy if exists organizations_update_admin         on public.organizations;
-- drop policy if exists org_members_select_in_org          on public.org_members;
-- drop policy if exists org_invitations_select_admins      on public.org_invitations;
-- drop policy if exists org_subscriptions_select_billing   on public.org_subscriptions;
-- drop policy if exists org_api_keys_select_admin          on public.org_api_keys;
-- drop policy if exists org_branding_select_member         on public.org_branding;
-- drop policy if exists org_branding_update_admin          on public.org_branding;
-- drop policy if exists org_branding_insert_admin          on public.org_branding;
-- drop policy if exists org_audit_log_select_admin         on public.org_audit_log;
-- drop policy if exists org_usage_counters_select_billing  on public.org_usage_counters;
-- alter table public.organizations      disable row level security;
-- alter table public.org_members        disable row level security;
-- alter table public.org_invitations    disable row level security;
-- alter table public.org_subscriptions  disable row level security;
-- alter table public.org_api_keys       disable row level security;
-- alter table public.org_branding       disable row level security;
-- alter table public.org_audit_log      disable row level security;
-- alter table public.org_usage_counters disable row level security;
-- drop function if exists public.current_user_org_role(uuid);
-- drop function if exists public.current_user_org_ids();
