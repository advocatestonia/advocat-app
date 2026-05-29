-- 20260530140000_drop_legacy_null_check_update_policies.sql
-- ---------------------------------------------------------------------------
-- SECURITY (org-scoping bypass via cross-org write) — LIVE.
--
-- cases, documents, deadlines and message_feedback each carry TWO permissive
-- UPDATE policies:
--   * a legacy policy ("Users can update own cases" etc.) — role {public},
--     USING (auth.uid() = user_id), and WITH CHECK = NULL.
--   * a hardened v2 policy (cases_update_v2 etc.) — role {authenticated},
--     USING/WITH CHECK that enforces the org-membership rule:
--       (org_id IS NULL AND user_id = auth.uid())
--       OR (org_id IN current_user_org_ids()
--           AND current_user_org_role(org_id) IN ('owner','admin','member'))
--
-- Postgres ORs permissive policies together for UPDATE. A policy with WITH
-- CHECK NULL uses its USING expression as the post-image check, so the legacy
-- policy's effective WITH CHECK is just `auth.uid() = user_id`. Because the
-- policies OR, satisfying the WEAKER legacy check is sufficient — the v2
-- org-membership constraint on the post-image is defeated.
--
-- Exploit: a user PATCHes their OWN row and sets org_id to an org they do not
-- belong to:
--   PATCH /rest/v1/documents?id=eq.<own-doc> {"org_id":"<victim-org-uuid>"}
-- The legacy policy passes (row is still theirs by user_id), injecting the
-- row into another org's data scope (org-shared views, counters, listings).
-- Verified live 2026-05-30: both policies present on all four tables.
--
-- FIX: drop the four legacy null-WITH-CHECK UPDATE policies. The v2 policies
-- already cover the legitimate path (personal rows with org_id NULL, or rows
-- in an org the caller is a member of) with a correct WITH CHECK, and are
-- scoped to {authenticated} (anon has no business updating these rows). The
-- legacy policies are pure pre-v2 leftovers that only weaken the hardening.
--
-- Idempotent (IF EXISTS).
-- ---------------------------------------------------------------------------

drop policy if exists "Users can update own cases" on public.cases;
drop policy if exists "Users can update own documents" on public.documents;
drop policy if exists "Users can update own deadlines" on public.deadlines;
drop policy if exists "Users can update their own feedback" on public.message_feedback;
