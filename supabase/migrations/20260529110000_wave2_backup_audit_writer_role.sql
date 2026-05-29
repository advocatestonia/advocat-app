-- =====================================================================
-- Wave 2 INFRA-08 remediation — least-privilege role for CI backup audit
-- =====================================================================
-- Audit ref: docs/security_audit_2026-05-28/findings/06_infra_security.md
--            INFRA-08 — db_backup.yml uses SUPABASE_SERVICE_KEY (full
--            DB bypass-RLS) just to POST one row to backup_audit_log.
--            Blast radius if the runner is compromised = whole database.
--
-- Strategy: create a NOLOGIN role with INSERT-only on backup_audit_log
-- and nothing else. Wave 3 follow-up: replace SUPABASE_SERVICE_KEY in
-- the workflow with a JWT signed for this role (sub=backup_audit_writer,
-- role=backup_audit_writer, exp=24h, rotated quarterly).
--
-- This migration is INFRASTRUCTURE-ONLY — it does not switch the workflow
-- yet. It establishes the target role so the Wave 3 workflow change is
-- one PR away.
-- =====================================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'backup_audit_writer') THEN
    CREATE ROLE backup_audit_writer NOLOGIN;
  END IF;
END $$;

-- ---------------------------------------------------------------------
-- Belt-and-braces: revoke everything the role may have inherited from
-- a public grant on schema public. We re-grant only what is needed.
-- ---------------------------------------------------------------------
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM backup_audit_writer;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM backup_audit_writer;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM backup_audit_writer;
REVOKE ALL ON SCHEMA public FROM backup_audit_writer;

-- ---------------------------------------------------------------------
-- Grant the minimum needed for the workflow to POST a row:
--   - USAGE on schema public (so the role can resolve table names)
--   - INSERT on backup_audit_log (the only write)
--   - SELECT (id) on backup_audit_log (so RETURNING id works after INSERT;
--     no read of other columns, no read of other rows).
--   - USAGE on the BIGSERIAL sequence so DEFAULT nextval works.
-- ---------------------------------------------------------------------
GRANT USAGE ON SCHEMA public TO backup_audit_writer;
GRANT INSERT ON TABLE public.backup_audit_log TO backup_audit_writer;
GRANT SELECT (id) ON TABLE public.backup_audit_log TO backup_audit_writer;
GRANT USAGE ON SEQUENCE public.backup_audit_log_id_seq TO backup_audit_writer;

-- ---------------------------------------------------------------------
-- Explicit deny on everything else this role might be tempted to touch.
-- Postgres doesn't have explicit DENY, but REVOKE on PUBLIC + no GRANT
-- to this role = effective deny.
-- ---------------------------------------------------------------------
-- (No-op assertion: role must not have BYPASSRLS.)
DO $$
DECLARE v_bypass BOOLEAN;
BEGIN
  SELECT rolbypassrls INTO v_bypass FROM pg_roles WHERE rolname = 'backup_audit_writer';
  IF v_bypass THEN
    RAISE EXCEPTION 'backup_audit_writer must NOT have BYPASSRLS';
  END IF;
END $$;

COMMENT ON ROLE backup_audit_writer IS
  'Least-privilege role for CI db_backup.yml. INSERT-only on backup_audit_log. '
  'Replace SUPABASE_SERVICE_KEY in workflow with a JWT signed for this role. '
  'Audit ref: docs/security_audit_2026-05-28/findings/06_infra_security.md INFRA-08.';
