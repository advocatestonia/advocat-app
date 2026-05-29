-- 20260530150000_revoke_client_execute_definer_idor.sql
-- ---------------------------------------------------------------------------
-- CRITICAL SECURITY (cross-user write via SECURITY DEFINER RPC) — LIVE.
--
-- These SECURITY DEFINER functions run as the owner role and BYPASS RLS. They
-- each take a caller-supplied id (case_id, org id, or user_id) and write
-- WITHOUT verifying that the authenticated caller owns that target. Because
-- they hold EXECUTE for both `anon` and `authenticated`, ANY client can call
-- them directly via PostgREST RPC and mutate ANOTHER user's / org's data.
-- Verified live 2026-05-30 (prosecdef=t, EXECUTE granted to {anon,authenticated},
-- bodies do `WHERE id = p_case_id` / arbitrary p_user_id with no auth.uid() check).
--
-- The LEGITIMATE callers are all server-side edge functions invoking these
-- RPCs with the SERVICE_ROLE key (verified in the codebase):
--   patch_case_facts        <- _shared/fact_extractor.ts (serviceRoleKey)
--   append_advice_digest    <- _shared/advice_digest.ts (serviceRoleKey)
--   record_case_event       <- send-email, case-auto-patch, email-inbox-sync,
--                              deadline-extractor, email-triage (admin client)
--   org_increment_seats     <- accept-invitation, remove-member (admin client,
--                              post verified claim)
--   org_audit_log_write     <- no edge or DB caller found (unused / future)
--   bump_engagement, record_digest_sent, record_winback_sent,
--   record_b2b_signal, compute_b2b_score
--                           <- winback-send, weekly-digest-send, b2b-signal,
--                              claude-proxy crons (admin client)
-- The service role bypasses EXECUTE grants, so revoking client EXECUTE closes
-- the direct-RPC exploit with ZERO impact on the server call paths.
--
-- P0 (cross-user content write):
--   patch_case_facts      — overwrite key_dates/parties/claims on ANY case
--   append_advice_digest  — inject advice-digest entries into ANY case
--   record_case_event     — plant timeline events in ANY case (owner is
--                           resolved only as an existence check, not authz)
--   org_audit_log_write   — forge/tamper org forensic audit entries
--   org_increment_seats   — manipulate seat counts / billing for ANY org
-- P1 (cross-user signal/state write — server/cron-driven only):
--   record_b2b_signal     — writes profiles (b2b_score, modal flags) for any uid
--   bump_engagement, record_digest_sent, record_winback_sent — forge
--                           engagement / "sent" state for any uid
--   compute_b2b_score     — read-only but arbitrary-uid; revoke for surface
--
-- Pattern matches the deferred 20260528120000_security_audit_p0_revokes set
-- (same class: privileged definer fns must be service_role-only). Idempotent.
-- ---------------------------------------------------------------------------

-- P0 — cross-user content / org writes.
revoke execute on function public.patch_case_facts(uuid, jsonb, jsonb, text[], text[], text[], text[]) from anon, authenticated;
revoke execute on function public.append_advice_digest(uuid, jsonb) from anon, authenticated;
revoke execute on function public.record_case_event(uuid, text, text, text, jsonb, timestamptz) from anon, authenticated;
revoke execute on function public.org_audit_log_write(uuid, uuid, text, uuid, text, uuid, jsonb, inet, text) from anon, authenticated;
revoke execute on function public.org_increment_seats(uuid, integer) from anon, authenticated;

-- P1 — cross-user signal / engagement state (cron/server-driven only).
revoke execute on function public.record_b2b_signal(uuid, text, integer, jsonb) from anon, authenticated;
revoke execute on function public.bump_engagement(uuid, text) from anon, authenticated;
revoke execute on function public.record_digest_sent(uuid) from anon, authenticated;
revoke execute on function public.record_winback_sent(uuid, text) from anon, authenticated;
revoke execute on function public.compute_b2b_score(uuid) from anon, authenticated;
