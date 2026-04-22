-- =============================================================================
-- Migration: increment_message_count RPC
-- Date: 2026-04-22
-- Task: feature/founder-beta-pricing
-- =============================================================================
--
-- Atomic increment of subscriptions.messages_used_count + lazy init of
-- first_message_at + auto-flip of refund_eligible once the 7-message cap is
-- reached.
--
-- Why SECURITY DEFINER: no end-user policy grants INSERT/UPDATE on
-- subscriptions; writes are service-role only (like increment_ai_usage in
-- 20260417_ai_usage.sql). SECURITY DEFINER lets the function mutate the
-- table on behalf of the caller without broadening RLS.
--
-- Safety:
--   - Operates strictly on auth.uid() — caller cannot spoof another user.
--   - Guard: only active or trialing subscriptions are touched. A cancelled
--     or past_due subscription cannot accumulate messages.
--   - idempotent DDL — uses CREATE OR REPLACE.
-- =============================================================================

create or replace function public.increment_message_count()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid;
  v_new_count integer;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'authentication required';
  end if;

  -- Atomic UPDATE ... RETURNING. Postgres row lock guarantees strictly
  -- monotonic counts even under concurrent calls from the same user
  -- (e.g. double-tap on the send button on flaky networks).
  --
  -- The refund_eligible flip is expressed inline so a single write does
  -- both: increment and (conditionally) close the refund window.
  update public.subscriptions
     set messages_used_count = messages_used_count + 1,
         first_message_at    = coalesce(first_message_at, now()),
         refund_eligible     = case
                                 when messages_used_count + 1 >= 7
                                   then false
                                 else refund_eligible
                               end,
         updated_at          = now()
   where user_id = v_uid
     and status in ('active', 'trialing')
  returning messages_used_count into v_new_count;

  -- No active subscription row — caller is a free-tier user or a cancelled
  -- subscriber. Return 0 rather than raising so the client-side hook can
  -- call this RPC unconditionally without branching on tier.
  if v_new_count is null then
    return 0;
  end if;

  return v_new_count;
end;
$$;

comment on function public.increment_message_count() is
  'Atomically increments the current user''s AI message counter on their active/trialing subscription, initialises first_message_at on first call, and flips refund_eligible=false when the 7-message cap is reached. Returns new count, or 0 if no active subscription exists.';

grant execute on function public.increment_message_count() to authenticated;
