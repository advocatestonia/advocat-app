-- =============================================================================
-- Migration: refund-eligibility tracking on public.subscriptions
-- Date: 2026-04-22
-- Task: feature/founder-beta-pricing
-- =============================================================================
--
-- Adds four columns to the existing subscriptions table so check-refund-
-- eligibility (new Edge Function) and stripe-webhook can report whether a
-- user is still within the "14 days OR 7 AI responses" window.
--
-- Policy (owner-confirmed 2026-04-21):
--   Refund available IFF now <= subscribedAt + 14 days AND messagesUsed < 7.
--
-- Legal: EU CRD 2011/83/EU Art. 9 + Art. 16(m) waiver (consent modal).
--
-- SAFETY:
--   - ALL column additions use ADD COLUMN IF NOT EXISTS (idempotent).
--   - UPDATE backfill is guarded by `where refund_deadline is null` so
--     re-running never overwrites real data.
--   - No column drops, no RLS changes.
-- =============================================================================

-- 1) Refund-tracking columns --------------------------------------------------

alter table public.subscriptions
  add column if not exists refund_eligible boolean not null default true;

alter table public.subscriptions
  add column if not exists refund_deadline timestamptz;

alter table public.subscriptions
  add column if not exists messages_used_count integer not null default 0;

alter table public.subscriptions
  add column if not exists first_message_at timestamptz;

-- Nonneg constraint so a bad RPC can never underflow the counter.
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'subscriptions_messages_used_nonneg'
  ) then
    alter table public.subscriptions
      add constraint subscriptions_messages_used_nonneg
      check (messages_used_count >= 0);
  end if;
end$$;

-- 2) Backfill refund_deadline for existing rows -------------------------------
-- Existing subscriptions predate this feature — assume 14 days from created_at.
-- Never overwrites a non-null value (idempotent).

update public.subscriptions
   set refund_deadline = created_at + interval '14 days'
 where refund_deadline is null
   and created_at is not null;

-- 3) Index for the "active + within refund window" predicate ------------------
-- check-refund-eligibility filters by user_id + status; the existing
-- idx_subscriptions_user_active already covers that. No new index needed.

-- 4) Helper comment -----------------------------------------------------------

comment on column public.subscriptions.refund_eligible is
  'Denormalised snapshot: true while both (a) refund_deadline > now() and (b) messages_used_count < 7. Maintained by increment_message_count() RPC and check-refund-eligibility. Eventually-consistent with the policy evaluator in _shared/refund_policy.ts.';

comment on column public.subscriptions.refund_deadline is
  'Absolute 14-day cutoff (created_at + 14 days). Set by stripe-webhook on customer.subscription.created; never recomputed.';

comment on column public.subscriptions.messages_used_count is
  'AI responses delivered on this subscription. Incremented by RPC increment_message_count(); never decremented.';

comment on column public.subscriptions.first_message_at is
  'Set to now() by increment_message_count() on the first call. Used by the client to show the refund-consent modal only once.';
