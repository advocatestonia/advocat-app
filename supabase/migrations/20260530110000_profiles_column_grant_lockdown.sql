-- 20260530110000_profiles_column_grant_lockdown.sql
-- ---------------------------------------------------------------------------
-- CRITICAL SECURITY (payment bypass / privilege escalation) — LIVE & EXPLOITABLE.
--
-- The RLS policy `profiles_update_own` (migration 20260422005000:193) is
--   FOR UPDATE USING (auth.uid() = id)
-- with NO `WITH CHECK` and NO column restriction, and the `authenticated`
-- role holds a blanket table-level UPDATE grant on public.profiles. RLS
-- cannot compare OLD vs NEW per column, so a user can update ANY column of
-- their own row — including the entitlement columns that gate paid features.
--
-- Entitlement readers trust profiles.is_pro / subscription_tier:
--   check-ai-quota/index.ts:255      -> unlimited AI + Anthropic spend
--   whisper-stt/cost_control.ts:113  -> voice quota
--   lawyer-booking/index.ts:155      -> pro pricing
--
-- Exploit (verified on prod in a rolled-back tx as the authenticated role
-- with the user's own sub): a free user sends
--   PATCH /rest/v1/profiles?id=eq.<own-uid>  {"is_pro":true,"subscription_tier":"premium"}
-- -> rows_updated=1, is_pro_now=t. Full Pro, zero payment.
--
-- FIX: RLS can't do per-column checks, so we use PostgreSQL COLUMN-LEVEL
-- GRANTS. Revoke the blanket UPDATE and re-grant UPDATE only on the columns
-- the client legitimately edits. Entitlement + billing columns stay writable
-- ONLY by the service-role (stripe-webhook / apple-iap-verify /
-- reconcile-subscriptions, which bypass grants).
--
-- Client-editable columns (verified against the Flutter write paths):
--   full_name, phone, avatar_url, preferred_language   (edit_profile_screen, supabase_service)
--   email                                              (auth_provider register flow)
--   gdpr_consent_at                                    (gdpr_consent_dialog)
-- b2b_modal_* are written via the mark_b2b_modal_shown RPC (SECURITY DEFINER),
-- NOT a direct client UPDATE, so they are intentionally NOT granted here.
--
-- WITHHELD (service-role only): is_pro, subscription_tier, subscription_status,
--   subscription_expires_at, stripe_customer_id, b2b_score, b2b_modal_pending,
--   b2b_modal_shown_at, b2b_modal_retrigger_count, email_domain, id,
--   created_at, updated_at.
--
-- The `profiles_update_own` RLS policy stays as-is (still restricts WHICH row
-- a user can touch to their own); the column grant restricts WHICH columns.
-- Idempotent.
-- ---------------------------------------------------------------------------

revoke update on public.profiles from authenticated;
revoke update on public.profiles from anon;

grant update (full_name, phone, avatar_url, preferred_language, email, gdpr_consent_at)
  on public.profiles to authenticated;

-- anon does not edit profiles; intentionally left without an UPDATE grant.
