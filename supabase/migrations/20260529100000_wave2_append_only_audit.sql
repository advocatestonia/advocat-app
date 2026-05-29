-- =============================================================================
-- Wave-2 security audit fix (2026-05-28) — P1-10 append-only audit tables.
-- =============================================================================
--
-- Finding source: /Users/ai.place/Advocat/docs/security_audit_2026-05-28/
--   findings/02_database_rls.md §P1-10
--
--   "audit_log, agent_audit_log, consilium_runs, agent_runs, backup_audit_log,
--    org_audit_log, correspondence_audit are RLS-protected but NOT tamper-
--    evident: no FORCE ROW LEVEL SECURITY, no append-only triggers, no
--    INSERT-only role separation. Compromised service_role key (or any
--    pg_dump rewrite) can rewrite history with no detection trail."
--
-- Threat model: a stolen service_role key bypasses RLS at the engine level,
-- so policies cannot stop a hostile insider from UPDATE/DELETE-ing audit rows.
-- Triggers DO fire under service_role connections (Postgres trigger semantics
-- are role-independent unless `session_replication_role = replica` is set).
-- So a BEFORE UPDATE/DELETE trigger that RAISES is the cheapest way to make
-- history rewrite require an explicit, auditable "drop the trigger first"
-- gesture.
--
-- Tables in scope (existence-guarded — table list cross-checked against
-- the migration tree on 2026-05-28):
--
--   1. public.audit_log              — sensitive-action trail (Pkg 0)
--   2. public.agent_audit_log        — per-iteration agent-loop log
--   3. public.consilium_runs         — multi-lawyer consilium telemetry
--   4. public.backup_audit_log       — nightly backup + restore drill record
--   5. public.org_audit_log          — B2B org actions (Art. 30 record)
--   6. public.correspondence_audit   — outbound/inbound email log
--                                      (the live table is public.correspondence;
--                                      the audit finding references it under
--                                      its functional name)
--   7. public.correspondence         — same table as #6, applied for safety
--
-- IMPORTANT CARVE-OUT: public.agent_runs is in the audit finding list but is
-- a STATE MACHINE — claude-proxy mutates status from 'in_progress' →
-- 'awaiting_approval' → 'completed' | 'rejected' | 'errored' | 'expired',
-- tail-appends audit_trail JSON, updates total_cost_cents and updated_at.
-- Append-only UPDATE blocking would break the agent loop. We block DELETE
-- only on agent_runs and rely on the row-level state machine + agent_audit_log
-- (which IS append-only) for forensic completeness.
--
-- ESCAPE HATCH: GDPR Art. 17 erasure (account-delete edge fn) MUST be able to
-- DELETE rows from audit tables that contain personal data. Postgres exposes
-- `SET LOCAL session_replication_role = replica;` to suppress triggers for
-- the duration of one transaction. The account-delete handler is documented
-- to wrap its delete loop in BEGIN ... SET LOCAL ... COMMIT for the audit
-- tables (account-delete/handler.ts comment at the DELETE call site). Any
-- other deletion path is a security ticket.
--
-- OWNER: do NOT apply via SUPABASE_ACCESS_TOKEN / Management API directly.
--   Roll this file out via canary-deploy.sh or `supabase db push` AFTER
--   running the verify script at
--   /Users/ai.place/Advocat/docs/security_audit_2026-05-28/fixes/
--   wave2_audit_append_only_verify.sql against a staging branch. Expected:
--   INSERT succeeds, UPDATE fails with ERRCODE 42501, DELETE fails with
--   ERRCODE 42501, hash chain populates on agent_audit_log.
-- =============================================================================

create extension if not exists pgcrypto;

-- ────────────────────────────────────────────────────────────────────────────
-- 1. Generic block-UPDATE/DELETE trigger function.
-- ────────────────────────────────────────────────────────────────────────────
-- Used by all seven audit tables. Reports the table name + operation in the
-- exception so a hostile or buggy caller gets a clear diagnostic. ERRCODE
-- 42501 = insufficient_privilege (treated as 403 by PostgREST).

create or replace function public.tf_block_update_delete()
returns trigger
language plpgsql
as $$
begin
  raise exception
    'audit table %.% is append-only; % blocked',
    tg_table_schema, tg_table_name, tg_op
    using errcode = '42501',
          hint    = 'Drop the trigger and log the reason to audit_log first. '
                    'For GDPR Art. 17 erasure use SET LOCAL '
                    'session_replication_role = replica in the same '
                    'transaction.';
end;
$$;

comment on function public.tf_block_update_delete() is
  'Wave-2 audit hardening (2026-05-28). BEFORE UPDATE/DELETE trigger body '
  'for append-only audit tables. Fires under every role including '
  'service_role (which bypasses RLS but NOT triggers). Suppressed only '
  'when session_replication_role = ''replica''.';

-- ────────────────────────────────────────────────────────────────────────────
-- 2. Apply triggers to each existing audit table.
-- ────────────────────────────────────────────────────────────────────────────
-- Existence-guarded loop. Each table gets two triggers (UPDATE + DELETE)
-- using consistent naming so the verify script can find them.
--
-- agent_runs is intentionally excluded from the UPDATE block (state-machine
-- table). DELETE-only block applied to it separately below.

do $$
declare
  t         text;
  audit_tables text[] := array[
    'audit_log',
    'agent_audit_log',
    'consilium_runs',
    'backup_audit_log',
    'org_audit_log',
    'correspondence_audit',
    'correspondence'
  ];
begin
  foreach t in array audit_tables loop
    if exists (
      select 1 from information_schema.tables
      where table_schema = 'public' and table_name = t
    ) then
      execute format('drop trigger if exists append_only_no_update_%I on public.%I', t, t);
      execute format('drop trigger if exists append_only_no_delete_%I on public.%I', t, t);

      execute format(
        'create trigger append_only_no_update_%I '
        'before update on public.%I '
        'for each row execute function public.tf_block_update_delete()',
        t, t
      );
      execute format(
        'create trigger append_only_no_delete_%I '
        'before delete on public.%I '
        'for each row execute function public.tf_block_update_delete()',
        t, t
      );
      execute format(
        'comment on trigger append_only_no_update_%I on public.%I is '
        '%L',
        t, t,
        'Wave-2 security fix (P1-10): audit tables must be append-only. '
        'service_role bypasses RLS but cannot bypass triggers. Suppressed '
        'only by SET LOCAL session_replication_role = replica (documented '
        'escape hatch for GDPR Art. 17 erasure).'
      );
      execute format(
        'comment on trigger append_only_no_delete_%I on public.%I is '
        '%L',
        t, t,
        'Wave-2 security fix (P1-10): audit tables must be append-only. '
        'service_role bypasses RLS but cannot bypass triggers. Suppressed '
        'only by SET LOCAL session_replication_role = replica (documented '
        'escape hatch for GDPR Art. 17 erasure).'
      );

      raise notice 'wave2 P1-10: append-only triggers installed on public.%', t;
    else
      raise notice 'wave2 P1-10: SKIP — public.% does not exist', t;
    end if;
  end loop;
end $$;

-- ────────────────────────────────────────────────────────────────────────────
-- 3. agent_runs: DELETE-only block (NOT UPDATE — state machine).
-- ────────────────────────────────────────────────────────────────────────────
-- claude-proxy + agent-approve mutate agent_runs.status, audit_trail,
-- total_cost_cents, updated_at, completed_at, write_pending over the
-- lifecycle. Blocking UPDATE would break the agent loop. We DO block DELETE
-- so a compromised key cannot erase a run that contains a write-tool decision.

do $$
begin
  if exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'agent_runs'
  ) then
    drop trigger if exists append_only_no_delete_agent_runs on public.agent_runs;
    create trigger append_only_no_delete_agent_runs
      before delete on public.agent_runs
      for each row execute function public.tf_block_update_delete();

    comment on trigger append_only_no_delete_agent_runs on public.agent_runs is
      'Wave-2 P1-10 partial: agent_runs is a state-machine table so UPDATE '
      'is allowed (status transitions). DELETE is blocked to preserve the '
      'forensic record of approved/declined write-tool actions. Suppressed '
      'only by SET LOCAL session_replication_role = replica for GDPR Art. 17.';

    raise notice 'wave2 P1-10: DELETE-only block installed on public.agent_runs';
  end if;
end $$;

-- ────────────────────────────────────────────────────────────────────────────
-- 4. Tamper-evident hash chain on agent_audit_log (highest forensic value).
-- ────────────────────────────────────────────────────────────────────────────
-- The agent_audit_log captures every write-tool invocation under the agent
-- loop — the highest-value audit trail for legal-liability reconstruction.
-- We chain each row to the previous one via sha256(prev_hash || row_payload).
-- An attacker who tampers with any row (even after dropping the append-only
-- trigger) breaks the chain at every subsequent row, making detection trivial.
--
-- Chain payload fields chosen from the actual schema in
-- 20260527020000_agent_quota.sql:
--   id, agent_run_id, user_id, iter, tool, status,
--   input_tokens, output_tokens, cost_microcents,
--   started_at, duration_ms, case_id, summary

alter table public.agent_audit_log
  add column if not exists row_hash  text,
  add column if not exists prev_hash text;

create or replace function public.tf_agent_audit_hash_chain()
returns trigger
language plpgsql
as $$
declare
  v_prev_hash text;
begin
  -- Last row's hash, scoped globally (one chain for the whole table).
  -- ORDER BY started_at DESC, id DESC for deterministic ordering when
  -- multiple rows land in the same millisecond.
  select row_hash
    into v_prev_hash
    from public.agent_audit_log
   order by started_at desc, id desc
   limit 1;

  new.prev_hash := coalesce(v_prev_hash, '');

  new.row_hash := encode(
    digest(
      coalesce(new.prev_hash, '')                       || '|' ||
      coalesce(new.id::text, '')                        || '|' ||
      coalesce(new.agent_run_id::text, '')              || '|' ||
      coalesce(new.user_id::text, '')                   || '|' ||
      coalesce(new.iter::text, '')                      || '|' ||
      coalesce(new.tool, '')                            || '|' ||
      coalesce(new.status, '')                          || '|' ||
      coalesce(new.input_tokens::text, '')              || '|' ||
      coalesce(new.output_tokens::text, '')             || '|' ||
      coalesce(new.cost_microcents::text, '')           || '|' ||
      coalesce(new.started_at::text, now()::text)       || '|' ||
      coalesce(new.duration_ms::text, '')               || '|' ||
      coalesce(new.case_id::text, '')                   || '|' ||
      coalesce(new.summary, ''),
      'sha256'
    ),
    'hex'
  );

  return new;
end;
$$;

comment on function public.tf_agent_audit_hash_chain() is
  'Wave-2 P1-10: BEFORE INSERT hash chain for agent_audit_log. Each row '
  'binds to the previous row''s hash so post-hoc tampering breaks the '
  'chain at every subsequent row. Verify with the chain-walk query in '
  'docs/security_audit_2026-05-28/fixes/wave2_audit_append_only_verify.sql.';

drop trigger if exists agent_audit_hash_chain on public.agent_audit_log;
create trigger agent_audit_hash_chain
  before insert on public.agent_audit_log
  for each row execute function public.tf_agent_audit_hash_chain();

comment on trigger agent_audit_hash_chain on public.agent_audit_log is
  'Wave-2 P1-10: tamper-evident sha256 hash chain. Computes row_hash = '
  'sha256(prev_hash || canonical(row)) on every insert. Detection script '
  'walks the chain and reports the first break.';

-- ────────────────────────────────────────────────────────────────────────────
-- 5. PostgREST schema reload — triggers don't require it, but the comment
--    surface changes do.
-- ────────────────────────────────────────────────────────────────────────────
notify pgrst, 'reload schema';

-- =============================================================================
-- ROLLBACK (emergency only — must be paired with an audit_log row recording
-- the reason and the operator).
-- =============================================================================
-- begin;
--   insert into public.audit_log (user_id, action, target_table, details)
--   values (
--     null, 'admin_access', 'agent_audit_log',
--     jsonb_build_object(
--       'reason', 'WAVE2 ROLLBACK', 'operator', current_user,
--       'ticket', 'SEC-YYYY-NN'
--     )
--   );
--   drop trigger if exists agent_audit_hash_chain  on public.agent_audit_log;
--   drop trigger if exists append_only_no_update_audit_log              on public.audit_log;
--   drop trigger if exists append_only_no_delete_audit_log              on public.audit_log;
--   drop trigger if exists append_only_no_update_agent_audit_log        on public.agent_audit_log;
--   drop trigger if exists append_only_no_delete_agent_audit_log        on public.agent_audit_log;
--   drop trigger if exists append_only_no_update_consilium_runs         on public.consilium_runs;
--   drop trigger if exists append_only_no_delete_consilium_runs         on public.consilium_runs;
--   drop trigger if exists append_only_no_update_backup_audit_log       on public.backup_audit_log;
--   drop trigger if exists append_only_no_delete_backup_audit_log       on public.backup_audit_log;
--   drop trigger if exists append_only_no_update_org_audit_log          on public.org_audit_log;
--   drop trigger if exists append_only_no_delete_org_audit_log          on public.org_audit_log;
--   drop trigger if exists append_only_no_update_correspondence_audit   on public.correspondence_audit;
--   drop trigger if exists append_only_no_delete_correspondence_audit   on public.correspondence_audit;
--   drop trigger if exists append_only_no_update_correspondence         on public.correspondence;
--   drop trigger if exists append_only_no_delete_correspondence         on public.correspondence;
--   drop trigger if exists append_only_no_delete_agent_runs             on public.agent_runs;
--   drop function if exists public.tf_agent_audit_hash_chain();
--   drop function if exists public.tf_block_update_delete();
--   alter table public.agent_audit_log drop column if exists row_hash;
--   alter table public.agent_audit_log drop column if exists prev_hash;
--   notify pgrst, 'reload schema';
-- commit;
