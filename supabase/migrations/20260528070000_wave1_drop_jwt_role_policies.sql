-- Wave-1 security audit fix (2026-05-28) — drop JWT-role anti-pattern policies.
-- =============================================================================
--
-- Findings from /Users/ai.place/Advocat/docs/security_audit_2026-05-28/findings/
--   02_database_rls.md §P1-9
--
-- Pattern under fix:
--   CREATE POLICY ... FOR ALL USING (auth.jwt() ->> 'role' = 'service_role')
--   CREATE POLICY ... FOR INSERT WITH CHECK (auth.role() = 'service_role')
--
-- Why this is wrong:
--   The Postgres engine ALREADY bypasses RLS entirely when the connection
--   carries the service_role grant. A policy that re-checks `auth.jwt() ->>
--   'role' = 'service_role'` adds zero security AND opens the same primitive
--   that produced the f8f6a58 anon-JWT bypass (lesson_anon_jwt_bypass.md):
--   any token whose `role` claim is forged or replayed slips through. The
--   policy is brittle to JWT replay and contributes nothing.
--
-- This migration removes the redundant service_role-by-JWT-claim policies.
-- Service-role connections continue to bypass RLS at the engine level
-- (Postgres BYPASSRLS grant); the client-facing surface keeps only owner-
-- gated policies.
-- =============================================================================

-- ── 1. public.consilium_runs ────────────────────────────────────────────────
-- Migration 20260525_consilium_telemetry.sql:67 created a
-- `Service role full access` policy on consilium_runs that uses the JWT
-- role-claim anti-pattern. Drop it — service_role bypasses RLS regardless.
-- The remaining "Users can read own consilium runs" policy is enough for
-- the client-facing read path.
DROP POLICY IF EXISTS "Service role full access" ON public.consilium_runs;

-- ── 2. public.advice_corrections ───────────────────────────────────────────
-- Migration 20260513140000_advice_corrections.sql:87 ships an INSERT
-- policy whose WITH CHECK accepts EITHER `auth.uid() = user_id` (legit
-- owner write) OR `auth.role() = 'service_role'` (the JWT-claim
-- anti-pattern). The second branch is redundant — server-side inserts
-- from edge fns already use the service-role client, which bypasses RLS
-- engine-side. Drop and re-create with the owner-only check.
--
-- (Note: the `service updates corrections` / `service deletes corrections`
-- policies use `auth.role() = 'service_role'` similarly, but since
-- service_role bypasses RLS, those policies effectively block ALL client
-- write traffic and admit ONLY service-role traffic — which is the desired
-- posture. We drop them anyway and keep the table closed to clients; this
-- removes the JWT-claim surface without changing observed behaviour.)
DROP POLICY IF EXISTS "owner writes corrections" ON public.advice_corrections;
CREATE POLICY "owner writes corrections"
  ON public.advice_corrections
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "service updates corrections" ON public.advice_corrections;
-- No replacement: service-role bypasses RLS; the column is append-mostly.
-- Clients (authenticated/anon) cannot UPDATE without a policy permitting it.

DROP POLICY IF EXISTS "service deletes corrections" ON public.advice_corrections;
-- Same rationale — service-role bypasses, clients cannot DELETE without a policy.

COMMENT ON TABLE public.advice_corrections IS
  'User-derived corrections corpus. SELECT is owner-only (see audit P0-6 fix '
  'in a separate migration). INSERT is owner-only via the policy above. '
  'UPDATE/DELETE are server-side only (service_role bypasses RLS).';

NOTIFY pgrst, 'reload schema';
