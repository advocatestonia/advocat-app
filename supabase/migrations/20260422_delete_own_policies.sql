-- ============================================================================
-- Sprint 0 — FIX-2 — GDPR Article 17 (Right to Erasure)
-- Date: 2026-04-22
-- Ref: docs/performance/04-database.md P0, docs/security/02-auth-authz.md
--
-- PROBLEM: chat_messages and conversation_summaries have SELECT+INSERT RLS
-- policies but NO DELETE policy. Client code in supabase_service.dart:351
-- calls `.from('chat_messages').delete().eq('user_id', uid)` as part of
-- deleteAllUserData() — this silently returns 0 rows because RLS rejects
-- the delete without a policy. Account purge therefore leaves chat history
-- behind → GDPR Art. 17 right-to-erasure silently failing.
--
-- FIX: Add `for delete using (auth.uid() = user_id)` policies on every
-- user-scoped table where client code performs a direct delete.
--
-- This migration is IDEMPOTENT — uses `if not exists` semantics via a
-- DO block that checks pg_policies first. Safe to apply multiple times.
-- ============================================================================

-- chat_messages: append-only by design, but required for account purge.
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename  = 'chat_messages'
      and policyname = 'chat_messages_delete_own'
  ) then
    create policy "chat_messages_delete_own"
      on public.chat_messages
      for delete
      using (auth.uid() = user_id);
  end if;
end$$;

-- conversation_summaries: not in migration 001 (schema drift — see FIX-3),
-- but guard the policy creation so this migration doesn't fail if the
-- table doesn't exist yet on a fresh local DB.
do $$
begin
  if exists (
    select 1 from pg_tables
    where schemaname = 'public' and tablename = 'conversation_summaries'
  ) and not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename  = 'conversation_summaries'
      and policyname = 'conversation_summaries_delete_own'
  ) then
    execute $policy$
      create policy "conversation_summaries_delete_own"
        on public.conversation_summaries
        for delete
        using (auth.uid() = user_id)
    $policy$;
  end if;
end$$;

-- checker_reports: append-only per app design but included for symmetry
-- with the supabase_service.dart purge flow. If owner decides reports
-- should NOT be user-deletable, drop this policy — quota enforcement and
-- the append-only invariant come from the app layer, not RLS.
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename  = 'checker_reports'
      and policyname = 'checker_reports_delete_own'
  ) then
    create policy "checker_reports_delete_own"
      on public.checker_reports
      for delete
      using (auth.uid() = user_id);
  end if;
end$$;

-- ============================================================================
-- Idempotency self-check: running this file a second time MUST be a no-op.
-- The DO blocks above only create policies that don't exist, so second run
-- is safe.
-- ============================================================================
