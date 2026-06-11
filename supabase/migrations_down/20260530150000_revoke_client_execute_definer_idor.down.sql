-- ROLLBACK for 20260530150000_revoke_client_execute_definer_idor.sql
-- Restores client EXECUTE on the SECURITY DEFINER RPCs this migration revoked.
-- Safe textual inverse (re-grant exactly what was revoked).
-- WARNING: this re-opens the cross-user / cross-org write IDOR via direct
-- PostgREST RPC. The legitimate callers all use the service_role key (which
-- bypasses EXECUTE grants), so rolling back has NO upside — only use if a
-- client genuinely needs direct RPC access (none known).
grant execute on function public.patch_case_facts(uuid, jsonb, jsonb, text[], text[], text[], text[]) to anon, authenticated;
grant execute on function public.append_advice_digest(uuid, jsonb) to anon, authenticated;
grant execute on function public.record_case_event(uuid, text, text, text, jsonb, timestamptz) to anon, authenticated;
grant execute on function public.org_audit_log_write(uuid, uuid, text, uuid, text, uuid, jsonb, inet, text) to anon, authenticated;
grant execute on function public.org_increment_seats(uuid, integer) to anon, authenticated;
grant execute on function public.record_b2b_signal(uuid, text, integer, jsonb) to anon, authenticated;
grant execute on function public.bump_engagement(uuid, text) to anon, authenticated;
grant execute on function public.record_digest_sent(uuid) to anon, authenticated;
grant execute on function public.record_winback_sent(uuid, text) to anon, authenticated;
grant execute on function public.compute_b2b_score(uuid) to anon, authenticated;
