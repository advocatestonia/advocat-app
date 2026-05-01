-- =============================================================================
-- Migration: subscriptions.intro_type column (Early Access founder program)
-- Date: 2026-05-01
-- Task: pre-launch — €14.99 lifetime for first 100 paying users
-- =============================================================================
--
-- Why a free-form text column instead of an enum:
--   The intro programs we run will change. "early-access-100" is the launch
--   one. We may add "first-month-trial", "halloween-2026", etc. without a
--   schema migration each time.
--
-- Allowed values (informal contract — enforced in code, not DB):
--   'early-access-100'    Lifetime €14.99/mo guarantee for first 100 paying.
--                         Slot is released back to the pool when status moves
--                         out of {active, trialing} (cancellation, payment
--                         failure final-state). New users can claim freed
--                         slots until total active+trialing = 100.
--   'first-month-trial'   Reserved for future use.
--   NULL                  Regular pricing — no intro guarantee.
--
-- Index strategy:
--   Partial index on intro_type IS NOT NULL — the founder count query
--   (SELECT count(*) WHERE intro_type='early-access-100' AND status IN ...)
--   is the hot path; without an index it would full-scan subscriptions on
--   every checkout request and on every public counter fetch.
-- =============================================================================

alter table public.subscriptions
  add column if not exists intro_type text;

create index if not exists idx_subscriptions_intro_type
  on public.subscriptions (intro_type)
  where intro_type is not null;

comment on column public.subscriptions.intro_type is
  'Introductory pricing program identifier. ''early-access-100'' = lifetime '
  '€14.99/mo for first 100 paying users; NULL = regular pricing. See '
  'supabase/functions/founder-spots for the cap accounting.';

-- PostgREST schema cache reload — without this, brand-new column is invisible
-- to PostgREST until the next pool restart, which manifests as PGRST204
-- "Could not find the 'intro_type' column" in production.
notify pgrst, 'reload schema';
