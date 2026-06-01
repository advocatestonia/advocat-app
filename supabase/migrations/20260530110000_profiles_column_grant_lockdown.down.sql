-- ROLLBACK for 20260530110000_profiles_column_grant_lockdown.sql
-- Restores the blanket table-level UPDATE grant on public.profiles for the
-- authenticated role (the pre-migration state). Safe textual inverse of the
-- REVOKE + column-level GRANT.
-- WARNING: this re-opens the payment-bypass / privilege-escalation exploit
-- (a user can self-set is_pro/subscription_tier). Roll back only if the
-- column-level grant broke a legitimate client write path.
revoke update on public.profiles from authenticated;  -- drop the column-level grant first
grant update on public.profiles to authenticated;     -- restore blanket grant
-- anon had no UPDATE grant before this migration; intentionally not re-granted.
