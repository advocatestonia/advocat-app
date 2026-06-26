-- SECURITY: lock down server-only SECURITY DEFINER functions that were
-- client-callable via the PUBLIC default grant.
-- -----------------------------------------------------------------------------
-- Found in the 2026-06-26 full audit. The earlier lockdown (20260530150000)
-- used `revoke execute ... from anon, authenticated`, which is a NO-OP when a
-- function's EXECUTE privilege flows via the PUBLIC default grant (ACL leading
-- `=X/postgres`). Revoking from anon/authenticated leaves the PUBLIC grant
-- intact, so the functions stayed callable by any client.
--
-- A sweep of all public SECURITY DEFINER functions found 23 that are genuinely
-- server-only (service-role / cron callers, no internal auth.uid() check) yet
-- remained client-executable. The combined `from public, anon, authenticated`
-- form below closes BOTH grant paths idempotently; service_role + postgres keep
-- EXECUTE so every edge-function caller continues to work.
--
-- Highest-risk closed:
--   * invoke_edge_cron        — any logged-in user could trigger ANY edge cron
--   * digest_candidates       — full user-base email+name PII dump
--   * winback_candidates      — full user-base email+name PII dump
--   * record_anthropic_spend  — spend-ledger forgery (both overloads)
--   * claim_webhook_event     — Stripe webhook replay
--
-- The 33 functions that DO scope to auth.uid() internally (unredact,
-- read_sensitive_doc, apply_deadline_extraction, mark_deadline_complete,
-- vault_*, law_search*, the consent/usage RPCs, …) are deliberately LEFT
-- client-callable — revoking them would break drafts/vault/deadlines/chat.
--
-- Idempotent. Wrapped so an absent function (schema drift) is skipped.
-- -----------------------------------------------------------------------------
do $$
begin
  revoke execute on function public.invoke_edge_cron(text) from public, anon, authenticated;
  revoke execute on function public.digest_candidates(integer) from public, anon, authenticated;
  revoke execute on function public.winback_candidates(integer, timestamp with time zone) from public, anon, authenticated;
  revoke execute on function public.record_anthropic_spend(bigint, bigint, text) from public, anon, authenticated;
  revoke execute on function public.record_anthropic_spend(bigint, bigint, text, text) from public, anon, authenticated;
  revoke execute on function public.check_and_increment_agent_quota(uuid, integer) from public, anon, authenticated;
  revoke execute on function public.record_agent_audit(uuid, uuid, integer, text, text, integer, integer, integer, integer, uuid, text) from public, anon, authenticated;
  revoke execute on function public.claim_webhook_event(text, text, integer) from public, anon, authenticated;
  revoke execute on function public.hit_rate_limit(text, text, integer) from public, anon, authenticated;
  revoke execute on function public.org_api_key_consume(text, integer) from public, anon, authenticated;
  revoke execute on function public.org_audit_log_retention_purge() from public, anon, authenticated;
  revoke execute on function public.backfill_case_timeline_events(integer) from public, anon, authenticated;
  revoke execute on function public.handle_new_user() from public, anon, authenticated;
  revoke execute on function public.rls_auto_enable() from public, anon, authenticated;
  revoke execute on function public.get_anthropic_spend_today() from public, anon, authenticated;
  revoke execute on function public.get_user_consilium_count_this_month(uuid) from public, anon, authenticated;
  revoke execute on function public.get_or_create_referral_code(uuid) from public, anon, authenticated;
  revoke execute on function public.increment_webhook_retry_count(text) from public, anon, authenticated;
  revoke execute on function public.log_incident(text, text, text, text, jsonb, text, text) from public, anon, authenticated;
  revoke execute on function public.prune_rate_limit_events() from public, anon, authenticated;
  revoke execute on function public.snapshot_anthropic_hourly() from public, anon, authenticated;
  revoke execute on function public.org_api_rate_counters_cleanup() from public, anon, authenticated;
  revoke execute on function public.dispatch_ingest_job(text, integer) from public, anon, authenticated;
  -- Re-close the two P0 case-content IDORs whose original revoke missed PUBLIC.
  revoke execute on function public.append_advice_digest(uuid, jsonb) from public, anon, authenticated;
  revoke execute on function public.patch_case_facts(uuid, jsonb, jsonb, text[], text[], text[], text[]) from public, anon, authenticated;
exception when undefined_function then
  raise notice 'one or more functions absent — skipping (idempotent)';
end $$;
