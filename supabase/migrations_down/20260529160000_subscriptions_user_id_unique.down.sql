-- ROLLBACK for 20260529160000_subscriptions_user_id_unique.sql
-- Drops the UNIQUE constraint added on subscriptions.user_id. Safe inverse.
-- NOTE: dropping this re-exposes the latent ON CONFLICT (user_id) breakage in
-- stripe-webhook and re-permits duplicate subscription rows per user — only
-- roll back if the constraint install itself caused a problem.
alter table public.subscriptions
  drop constraint if exists subscriptions_user_id_key;
