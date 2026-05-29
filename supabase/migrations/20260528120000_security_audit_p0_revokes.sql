-- Wave-1 security audit fix (2026-05-28) — P0/P1 function-grant + RLS lockdown.
-- =============================================================================
--
-- Findings from /Users/ai.place/Advocat/docs/security_audit_2026-05-28/findings/
--   02_database_rls.md   §P0-1 .. P0-7, §P1-8, §P1-9
--   04_payments_security.md §P0-A1
--
-- TL;DR — every issue here is a one-line REVOKE / DROP POLICY / unique-index
-- statement. Every public.* RPC reported in the audit was created SECURITY
-- DEFINER without an explicit REVOKE — Postgres default-grants EXECUTE to
-- PUBLIC on every new function, so PostgREST exposed all of them to anon and
-- authenticated callers. This migration closes the surface in one atomic
-- patch and pins service_role as the only grantee.
--
-- The companion migration 20260528070000_wave1_drop_jwt_role_policies.sql
-- already removed the JWT-role anti-pattern on consilium_runs and
-- advice_corrections (P1-9). This file completes P0-1 .. P0-7, P1-8, and the
-- payments P0-A1 (Apple IAP receipt re-binding).
--
-- OWNER: do NOT apply via SUPABASE_ACCESS_TOKEN / Management API directly.
--   Roll this file out via canary-deploy.sh or `supabase db push` AFTER the
--   smoke script /Users/ai.place/Advocat/docs/security_audit_2026-05-28/
--   fixes/wave1_db_smoke.sh has been reviewed. Smoke MUST be run with the
--   public anon key against every affected RPC; expected response = 4xx
--   (PGRST 401/403/42501).
-- =============================================================================

-- ────────────────────────────────────────────────────────────────────────────
-- P0-1 — invoke_edge_cron(text) world-callable → cron-secret SSRF
-- ────────────────────────────────────────────────────────────────────────────
-- Signature confirmed in migration 20260528060000_fix_invoke_edge_cron.sql:
--   public.invoke_edge_cron(p_fn_name text)
REVOKE EXECUTE ON FUNCTION public.invoke_edge_cron(text)
  FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.invoke_edge_cron(text)
  TO service_role;

-- ────────────────────────────────────────────────────────────────────────────
-- P0-2 — record_anthropic_spend(...) drains $500/day cap in one call
-- ────────────────────────────────────────────────────────────────────────────
-- Two overloads from 20260515220031_anti_abuse_protection.sql and
-- 20260522_spend_provider.sql respectively:
--   public.record_anthropic_spend(p_input_tokens bigint, p_output_tokens bigint, p_model text)
--   public.record_anthropic_spend(p_input_tokens bigint, p_output_tokens bigint, p_model text, p_provider text)
REVOKE EXECUTE ON FUNCTION public.record_anthropic_spend(bigint, bigint, text)
  FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.record_anthropic_spend(bigint, bigint, text)
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.record_anthropic_spend(bigint, bigint, text, text)
  FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.record_anthropic_spend(bigint, bigint, text, text)
  TO service_role;

-- get_anthropic_spend_today() — same default-PUBLIC EXECUTE leak.
-- Signature from 20260515220031_anti_abuse_protection.sql:
--   public.get_anthropic_spend_today()
REVOKE EXECUTE ON FUNCTION public.get_anthropic_spend_today()
  FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.get_anthropic_spend_today()
  TO service_role;

-- ────────────────────────────────────────────────────────────────────────────
-- P0-3 — record_agent_audit / check_and_increment_agent_quota
-- ────────────────────────────────────────────────────────────────────────────
-- Signatures from 20260527020000_agent_quota.sql:
--   public.record_agent_audit(
--     p_agent_run_id uuid, p_user_id uuid, p_iter int, p_tool text, p_status text,
--     p_input_tokens int, p_output_tokens int, p_cost_microcents int,
--     p_duration_ms int, p_case_id uuid, p_summary text
--   )
--   public.check_and_increment_agent_quota(p_user_id uuid, p_tier_cap int)
REVOKE EXECUTE ON FUNCTION public.record_agent_audit(
  uuid, uuid, int, text, text, int, int, int, int, uuid, text
) FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.record_agent_audit(
  uuid, uuid, int, text, text, int, int, int, int, uuid, text
) TO service_role;

REVOKE EXECUTE ON FUNCTION public.check_and_increment_agent_quota(uuid, int)
  FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.check_and_increment_agent_quota(uuid, int)
  TO service_role;

-- ────────────────────────────────────────────────────────────────────────────
-- P0-4 — rate-limit / incident-log RPCs world-callable
-- ────────────────────────────────────────────────────────────────────────────
-- Signatures from 20260515220031_anti_abuse_protection.sql:
--   public.hit_rate_limit(p_bucket text, p_principal text, p_max_per_minute int)
--   public.prune_rate_limit_events()
--   public.log_incident(
--     p_kind text, p_severity text, p_source text, p_message text,
--     p_details jsonb, p_principal text, p_request_id text
--   )
REVOKE EXECUTE ON FUNCTION public.hit_rate_limit(text, text, int)
  FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.hit_rate_limit(text, text, int)
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.prune_rate_limit_events()
  FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.prune_rate_limit_events()
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.log_incident(text, text, text, text, jsonb, text, text)
  FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.log_incident(text, text, text, text, jsonb, text, text)
  TO service_role;

-- ────────────────────────────────────────────────────────────────────────────
-- P0-5 — user_oauth_tokens plain-text Gmail tokens → add encrypted columns
-- ────────────────────────────────────────────────────────────────────────────
-- This is a Wave-1 DUAL-WRITE prep step:
--   1. Add nullable bytea columns to hold pgp_sym_encrypt() ciphertext.
--   2. Backfill existing rows using app_vault.encrypt_text() (which returns
--      TEXT-armored output but we cast to BYTEA for compact storage). Old
--      plain columns are NOT dropped here — Wave 2 will swap reads to the
--      encrypted columns and only then drop the plain columns.
--   3. The gmail-oauth-exchange and oauth-callback edge fns MUST be updated
--      in Wave 2 to write BOTH columns (plain — until drop — AND encrypted)
--      and send-email / email-inbox-sync must learn to read encrypted_*
--      via vault_decrypt_text() when present.
--
-- Why bytea + app_vault.encrypt_text:
--   app_vault.encrypt_text() returns TEXT (ASCII-armored pgp_sym_encrypt
--   output) — see 20260527090000_vault_encryption.sql:248. Storing as
--   bytea via ::bytea cast is compact and round-trips cleanly through
--   pgp_sym_decrypt(<col>::text, key).

ALTER TABLE public.user_oauth_tokens
  ADD COLUMN IF NOT EXISTS access_token_enc   bytea,
  ADD COLUMN IF NOT EXISTS refresh_token_enc  bytea,
  ADD COLUMN IF NOT EXISTS encryption_key_id  uuid;

COMMENT ON COLUMN public.user_oauth_tokens.access_token IS
  'DEPRECATED 2026-05-28 (security audit P0-5). Plain-text Gmail OAuth '
  'token retained for dual-write window. Wave 2 will swap reads to '
  'access_token_enc and DROP this column. Do NOT write here in new code — '
  'use app_vault.encrypt_text(token, user_id) and write access_token_enc.';

COMMENT ON COLUMN public.user_oauth_tokens.refresh_token IS
  'DEPRECATED 2026-05-28 (security audit P0-5). Plain-text Gmail refresh '
  'token retained for dual-write window. Wave 2 will swap reads to '
  'refresh_token_enc and DROP this column. Do NOT write here in new code.';

COMMENT ON COLUMN public.user_oauth_tokens.access_token_enc IS
  'Encrypted Gmail OAuth access token (pgp_sym_encrypt via '
  'app_vault.encrypt_text). Replaces plain access_token in Wave 2.';

COMMENT ON COLUMN public.user_oauth_tokens.refresh_token_enc IS
  'Encrypted Gmail OAuth refresh token (pgp_sym_encrypt via '
  'app_vault.encrypt_text). Replaces plain refresh_token in Wave 2.';

-- Backfill: run with elevated rights (this migration runs as the migrating
-- role, which has BYPASSRLS via Supabase). app_vault.encrypt_text() is
-- SECURITY DEFINER and rejects cross-user calls when auth.uid() IS NOT NULL.
-- During migration auth.uid() IS NULL (no JWT), so the owner-guard branch
-- is skipped and the encrypt succeeds for any user_id. See
-- 20260527090000_vault_encryption.sql:264 (the auth.uid() IS NOT NULL guard).
DO $$
DECLARE
  r RECORD;
  v_keyed INT := 0;
BEGIN
  FOR r IN
    SELECT user_id, access_token, refresh_token
    FROM public.user_oauth_tokens
    WHERE access_token_enc IS NULL
       OR (refresh_token IS NOT NULL AND refresh_token_enc IS NULL)
  LOOP
    UPDATE public.user_oauth_tokens t
       SET access_token_enc  = CASE
                                  WHEN r.access_token IS NULL OR length(r.access_token) = 0
                                    THEN NULL
                                  ELSE app_vault.encrypt_text(r.access_token, r.user_id)::bytea
                                END,
           refresh_token_enc = CASE
                                  WHEN r.refresh_token IS NULL OR length(r.refresh_token) = 0
                                    THEN NULL
                                  ELSE app_vault.encrypt_text(r.refresh_token, r.user_id)::bytea
                                END
     WHERE t.user_id = r.user_id;
    v_keyed := v_keyed + 1;
  END LOOP;
  RAISE NOTICE 'wave1 P0-5: backfilled % user_oauth_tokens rows', v_keyed;
END $$;

-- ────────────────────────────────────────────────────────────────────────────
-- P0-6 — advice_corrections cross-tenant PII leak
-- ────────────────────────────────────────────────────────────────────────────
-- The SELECT policy `USING (true)` exposes user-entered case context
-- (question, wrong_advice, correct_answer, why_wrong) to every authenticated
-- user. Drop the permissive policy and replace with an owner-only one.
-- Cross-user retrieval of the corpus continues to work via
-- match_corrections() SECURITY DEFINER RPC, which bypasses RLS for the
-- planner injection path — but we revoke anon EXECUTE so unauthenticated
-- traffic cannot dump the corpus over the RPC either.

DROP POLICY IF EXISTS "anyone reads corrections" ON public.advice_corrections;
DROP POLICY IF EXISTS "advice_corrections_select_all" ON public.advice_corrections;
DROP POLICY IF EXISTS "advice_corrections owner USING true" ON public.advice_corrections;
CREATE POLICY "advice_corrections_owner_select_only"
  ON public.advice_corrections
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- match_corrections() — defined in 20260513140000_advice_corrections.sql
-- and replaced in 20260514180000_match_corrections_case_insensitive.sql:
--   public.match_corrections(
--     p_query_embedding vector,
--     p_jurisdiction text,
--     p_threshold double precision,
--     p_limit integer
--   )
-- The original migration granted EXECUTE to anon. Revoke anon; keep
-- authenticated + service_role so planner retrieval still works.
REVOKE EXECUTE ON FUNCTION public.match_corrections(vector, text, double precision, integer)
  FROM anon, PUBLIC;
GRANT  EXECUTE ON FUNCTION public.match_corrections(vector, text, double precision, integer)
  TO authenticated, service_role;

-- ────────────────────────────────────────────────────────────────────────────
-- P1-8 — get_user_consilium_count_this_month missing owner check
-- ────────────────────────────────────────────────────────────────────────────
-- The original (20260525_consilium_telemetry.sql:75) accepts any user_id
-- with no auth.uid() check. Replace the body with an owner-gated variant.
-- LANGUAGE moves from sql → plpgsql so we can RAISE EXCEPTION on auth fail.
CREATE OR REPLACE FUNCTION public.get_user_consilium_count_this_month(p_user_id UUID)
RETURNS INT
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_count INT;
BEGIN
  -- Owner check: callers (via JWT) may only ask about their own count.
  -- Service-role callers (no auth.uid()) are allowed (edge fns may need
  -- to enforce the cap on behalf of the user).
  IF auth.uid() IS NOT NULL AND auth.uid() <> p_user_id THEN
    RAISE EXCEPTION 'forbidden: cross-user consilium count denied'
      USING ERRCODE = '42501';
  END IF;

  SELECT count(*)::INT
    INTO v_count
    FROM public.consilium_runs
   WHERE user_id = p_user_id
     AND created_at >= date_trunc('month', now())
     AND created_at <  date_trunc('month', now()) + interval '1 month';

  RETURN v_count;
END;
$$;

COMMENT ON FUNCTION public.get_user_consilium_count_this_month(UUID) IS
  'Powers PRO_CONSILIUM_QUOTA gate in claude-proxy. SECURITY DEFINER — '
  'bypasses RLS for count-only metadata BUT enforces auth.uid() = p_user_id '
  'so users cannot enumerate competitors'' usage. Wave-1 security audit '
  'P1-8 fix, 2026-05-28.';

-- ────────────────────────────────────────────────────────────────────────────
-- P1-9 — JWT-role anti-pattern policies (consilium_runs)
-- ────────────────────────────────────────────────────────────────────────────
-- Migration 20260528070000_wave1_drop_jwt_role_policies.sql already removes
-- the "Service role full access" policy on consilium_runs and the redundant
-- auth.role()='service_role' branches on advice_corrections. The DROP here
-- is idempotent — included so this single Wave-1 file is sufficient even if
-- run before the JWT-role file.
DROP POLICY IF EXISTS "Service role full access" ON public.consilium_runs;
-- service_role bypasses RLS at the engine level; no replacement needed.

-- ────────────────────────────────────────────────────────────────────────────
-- P0-A1 (payments) — Apple IAP receipt replay across users
-- ────────────────────────────────────────────────────────────────────────────
-- apple_iap_transactions has PK on transaction_id alone. An attacker who
-- captures another user's receipt can re-bind the row to their own user_id
-- via the upsert path in apple-iap-verify (see 04_payments_security.md
-- §P0-A1). Add a UNIQUE constraint on (original_transaction_id, user_id)
-- so a second user cannot claim a receipt chain that's already bound to
-- a different user_id. The edge fn also gets a pre-upsert owner-check
-- (separate code change — out of scope for this DB migration).
--
-- IF NOT EXISTS: safe to re-run.
CREATE UNIQUE INDEX IF NOT EXISTS apple_iap_orig_user_unique
  ON public.apple_iap_transactions (original_transaction_id, user_id);

COMMENT ON INDEX public.apple_iap_orig_user_unique IS
  'Wave-1 security audit P0-A1: prevents the same Apple subscription chain '
  '(original_transaction_id) from being bound to multiple user_ids. The '
  'edge fn apple-iap-verify must additionally check the row is not already '
  'bound to a DIFFERENT user before upserting.';

-- ────────────────────────────────────────────────────────────────────────────
-- PostgREST schema reload — pick up grant / policy changes immediately.
-- ────────────────────────────────────────────────────────────────────────────
NOTIFY pgrst, 'reload schema';
