-- 20260520_user_oauth_tokens_rls.sql
-- ----------------------------------------------------------------------------
-- DEPT 6 security audit (2026-05-20): user_oauth_tokens RLS hardening
--
-- Context: user_oauth_tokens stores Gmail OAuth bearer tokens. Migration
-- 20260422005000_schema_drift_fix.sql enabled RLS and added owner-only
-- policies for SELECT and DELETE, but NOT for INSERT and UPDATE. Without
-- those, an authenticated user could in principle craft anon-key calls to
-- insert/update OAuth rows directly (the OAuth callback flow runs with
-- service_role and bypasses RLS regardless, so this only restricts the
-- public client surface — service_role is intentionally untouched).
--
-- This migration:
--   * Re-asserts `enable row level security` (idempotent).
--   * Ensures all four owner-only policies exist (select / insert /
--     update / delete), each guarded by `auth.uid() = user_id`.
--   * Re-creates any existing policy with the same name only if the
--     definition is missing — never drops a service_role policy.
--
-- The previous migration's two policies (user_oauth_tokens_select_own,
-- user_oauth_tokens_delete_own) keep their names; we just guarantee their
-- presence here.  New: user_oauth_tokens_insert_own, user_oauth_tokens_update_own.
-- ----------------------------------------------------------------------------

alter table if exists public.user_oauth_tokens enable row level security;

do $$
begin
  -- SELECT: owner only
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename  = 'user_oauth_tokens'
      and policyname = 'user_oauth_tokens_select_own'
  ) then
    create policy "user_oauth_tokens_select_own"
      on public.user_oauth_tokens
      for select
      using (auth.uid() = user_id);
  end if;

  -- INSERT: owner only.  Service-role inserts (OAuth callback) bypass RLS
  -- entirely, so this does NOT block the server-side write path.
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename  = 'user_oauth_tokens'
      and policyname = 'user_oauth_tokens_insert_own'
  ) then
    create policy "user_oauth_tokens_insert_own"
      on public.user_oauth_tokens
      for insert
      with check (auth.uid() = user_id);
  end if;

  -- UPDATE: owner only.  Service-role token-refresh writes bypass RLS.
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename  = 'user_oauth_tokens'
      and policyname = 'user_oauth_tokens_update_own'
  ) then
    create policy "user_oauth_tokens_update_own"
      on public.user_oauth_tokens
      for update
      using (auth.uid() = user_id)
      with check (auth.uid() = user_id);
  end if;

  -- DELETE: owner only
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename  = 'user_oauth_tokens'
      and policyname = 'user_oauth_tokens_delete_own'
  ) then
    create policy "user_oauth_tokens_delete_own"
      on public.user_oauth_tokens
      for delete
      using (auth.uid() = user_id);
  end if;
end$$;
