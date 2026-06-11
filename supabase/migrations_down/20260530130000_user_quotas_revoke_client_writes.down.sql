-- ROLLBACK for 20260530130000_user_quotas_revoke_client_writes.sql
-- Restores the blanket client write grants on public.user_quotas. Safe inverse.
-- WARNING: re-opens the contract-review quota-reset exploit. Roll back only if
-- some client path unexpectedly depended on a direct user_quotas write.
grant insert, update, delete on public.user_quotas to authenticated;
grant insert, update, delete on public.user_quotas to anon;
