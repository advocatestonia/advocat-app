-- Wave 1 Payments Security Hardening (2026-05-28)
-- ---------------------------------------------------------------------------
-- Backs five P0 fixes in supabase/functions/{apple-iap-verify, stripe-webhook,
-- check-ai-quota, reconcile-subscriptions, create-checkout}.
--
-- Covers:
--   P0-A1  — Apple IAP receipt re-binding belt-and-braces unique index.
--   P0-RC5 — reconcile_unmatched audit table (logs Stripe customers/subs we
--            could NOT match to a canonical user_id, so a human can
--            triage instead of falling back to the email-match exploit).
-- ---------------------------------------------------------------------------

-- ── P0-A1 — Apple IAP receipt re-binding (belt-and-braces) ─────────────────
--
-- The application-level check in apple-iap-verify/index.ts rejects re-binds
-- by SELECT-before-upsert, but a concurrent race (Bob's and Alice's restore
-- arriving in the same millisecond) could in theory slip past. This UNIQUE
-- INDEX on (original_transaction_id, user_id) closes the race: the second
-- upsert (Bob's, with original_transaction_id=Alice's but user_id=Bob)
-- crashes on the index rather than silently overwriting.
--
-- Combined with the existing PK on transaction_id, the invariant becomes:
--   For every Apple original_transaction_id chain, there is at most one
--   user_id (across all renewal transaction_ids in the chain).
create unique index if not exists apple_iap_transactions_original_user_uniq
  on public.apple_iap_transactions (original_transaction_id, user_id);

comment on index public.apple_iap_transactions_original_user_uniq is
  'Wave 1 fix P0-A1 (2026-05-28): prevents the same Apple receipt chain '
  'from being re-bound to a different user_id under concurrent upserts. '
  'Application-level SELECT-then-check in apple-iap-verify is the primary '
  'gate; this index is the race-safety net.';

-- ── P0-RC5 — reconcile_unmatched audit table ───────────────────────────────
--
-- Wave 1 removes the email-fallback branch in reconcile_logic.matchProfile.
-- Stripe subscriptions whose customer cannot be linked to a canonical
-- profile via stripe_customer_id OR metadata.user_id now get logged here
-- for human review instead of silently upgrading whoever's profile email
-- happens to match (P0-RC5 exploit).
--
-- The reconcile cron INSERTs one row per (stripe_subscription_id, run_at)
-- pair that fails to match. A daily ops query SELECTs rows where
-- resolved_at IS NULL and triages by hand.
create table if not exists public.reconcile_unmatched (
  id                       uuid primary key default gen_random_uuid(),

  -- The Stripe ids we could not resolve.
  stripe_subscription_id   text not null,
  stripe_customer_id       text not null,

  -- Email on the Stripe customer (PII-bearing — protected by RLS).
  -- Stored so an ops human can manually reconcile via Stripe Dashboard
  -- + Supabase Studio without re-fetching from Stripe.
  customer_email           text,

  -- Stripe sub status + tier metadata so triage doesn't need an extra
  -- Stripe API call.
  stripe_status            text,
  metadata_user_id         text,

  -- Free-form reason from formatFixLog (e.g. "no profile for stripe sub
  -- status=active").
  reason                   text not null,

  -- When the reconcile cron observed the drift. Multiple runs can produce
  -- multiple rows per (subscription_id, customer_id) if the unmatched state
  -- persists; the dedup is by ops, not by uniq constraint, so we keep the
  -- history visible.
  observed_at              timestamptz not null default now(),

  -- Set when an ops human (or a corrective edge fn call) reconciles the row.
  resolved_at              timestamptz,
  resolution_note          text,
  resolved_by_user_id      uuid references auth.users(id) on delete set null
);

create index if not exists idx_reconcile_unmatched_open
  on public.reconcile_unmatched (observed_at desc)
  where resolved_at is null;

create index if not exists idx_reconcile_unmatched_sub
  on public.reconcile_unmatched (stripe_subscription_id, observed_at desc);

comment on table public.reconcile_unmatched is
  'Wave 1 fix P0-RC5 (2026-05-28): rows the reconcile-subscriptions cron '
  'could not match to a canonical profile by stripe_customer_id or '
  'metadata.user_id. Replaces the email-fallback branch that was '
  'exploitable for free Pro. Triaged manually by ops.';

-- ── RLS: service-role only ─────────────────────────────────────────────────
alter table public.reconcile_unmatched enable row level security;

drop policy if exists "reconcile_unmatched no client read"
  on public.reconcile_unmatched;
create policy "reconcile_unmatched no client read"
  on public.reconcile_unmatched
  for select
  using (false);

drop policy if exists "reconcile_unmatched no client insert"
  on public.reconcile_unmatched;
create policy "reconcile_unmatched no client insert"
  on public.reconcile_unmatched
  for insert
  with check (false);

drop policy if exists "reconcile_unmatched no client update"
  on public.reconcile_unmatched;
create policy "reconcile_unmatched no client update"
  on public.reconcile_unmatched
  for update
  using (false);

drop policy if exists "reconcile_unmatched no client delete"
  on public.reconcile_unmatched;
create policy "reconcile_unmatched no client delete"
  on public.reconcile_unmatched
  for delete
  using (false);
