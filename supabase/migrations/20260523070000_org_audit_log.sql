-- ============================================================================
-- 20260523070000_org_audit_log.sql
-- Migration 37/37 — GDPR Art. 30 audit-log writers + DSAR exporter.
--
-- The org_audit_log table itself is created in migration 31. This migration
-- adds:
--   * org_audit_log_write       — append-only writer RPC (called by every
--                                  org-scoped edge function for major actions)
--   * org_audit_log_export      — owner-only DSAR export of the org trail
--   * org_audit_log_retention_purge — 7-year retention cleanup function
-- ============================================================================

-- ── writer RPC ───────────────────────────────────────────────────────────────
create or replace function public.org_audit_log_write(
  p_org                  uuid,
  p_actor                uuid,
  p_action               text,
  p_target_user          uuid default null,
  p_target_resource_type text default null,
  p_target_resource_id   uuid default null,
  p_details              jsonb default '{}'::jsonb,
  p_ip                   inet default null,
  p_user_agent           text default null
) returns uuid
language sql
security definer
set search_path = public
as $$
  insert into public.org_audit_log (
    org_id, actor_user_id, action,
    target_user_id, target_resource_type, target_resource_id,
    details, ip, user_agent
  )
  values (
    p_org, p_actor, p_action,
    p_target_user, p_target_resource_type, p_target_resource_id,
    p_details, p_ip, p_user_agent
  )
  returning id
$$;

revoke all on function public.org_audit_log_write(uuid, uuid, text, uuid, text, uuid, jsonb, inet, text) from public;
-- service_role only.

-- ── DSAR export RPC (owner-only) ─────────────────────────────────────────────
-- Returns the entire audit trail for the org but only if the caller is the
-- 'owner' of that org. Admins are intentionally excluded — owner is the legal
-- data controller of record.
create or replace function public.org_audit_log_export(p_org uuid)
returns setof public.org_audit_log
language sql
stable
security definer
set search_path = public
as $$
  select l.*
  from public.org_audit_log l
  where l.org_id = p_org
    and public.current_user_org_role(p_org) = 'owner'
  order by l.created_at desc
$$;

grant execute on function public.org_audit_log_export(uuid) to authenticated;

-- ── retention purge (7 years for legal-industry compliance) ──────────────────
create or replace function public.org_audit_log_retention_purge()
returns int
language sql
security definer
set search_path = public
as $$
  with d as (
    delete from public.org_audit_log
    where created_at < now() - interval '7 years'
    returning 1
  )
  select count(*)::int from d
$$;

revoke all on function public.org_audit_log_retention_purge() from public;

notify pgrst, 'reload schema';

-- ROLLBACK:
-- drop function if exists public.org_audit_log_retention_purge();
-- drop function if exists public.org_audit_log_export(uuid);
-- drop function if exists public.org_audit_log_write(uuid, uuid, text, uuid, text, uuid, jsonb, inet, text);
