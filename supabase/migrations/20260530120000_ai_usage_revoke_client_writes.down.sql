-- ROLLBACK for 20260530120000_ai_usage_revoke_client_writes.sql
-- Restores the blanket client write grants on public.ai_usage. Safe inverse.
-- WARNING: re-opens the quota-reset / free-tier-bypass exploit. Roll back only
-- if some client path unexpectedly depended on a direct ai_usage write.
grant insert, update, delete on public.ai_usage to authenticated;
grant insert, update, delete on public.ai_usage to anon;
