-- ============================================================================
-- 20260523030000_add_org_id_to_existing.sql
-- Migration 33/37 — Retrofit existing user-scoped tables with nullable org_id,
-- partial indexes, and v2 RLS policies that preserve B2C semantics.
--
-- Critical invariants:
--   * org_id is NULLABLE on every retrofitted table. B2C rows stay NULL.
--   * Partial indexes WHERE org_id IS NOT NULL keep B2C performance unchanged.
--   * RLS policies allow:
--       (org_id IS NULL AND user_id = auth.uid())  -- pure B2C
--       OR org_id IN (current_user_org_ids())      -- org-member access
--   * UPDATE and DELETE on org rows require role >= member / admin respectively.
--
-- Tables retrofitted (18):
--   cases, documents, correspondence, deadlines, chat_messages,
--   checker_reports, case_memory, case_file, case_facts, case_phase,
--   case_deadlines, message_citations, message_feedback, contract_reviews,
--   advice_corrections, shareable_results, support_tickets, ai_usage
--
-- A helper PL/pgSQL block applies the retrofit only to tables that:
--   (a) actually exist in this schema, and
--   (b) carry a user_id column. This keeps the migration idempotent and
--   forward-safe across slightly diverged environments.
-- ============================================================================

-- ── retrofit helper ──────────────────────────────────────────────────────────
do $migration$
declare
  v_table        text;
  v_has_user_id  boolean;
  v_tables       text[] := array[
    'cases',
    'documents',
    'correspondence',
    'deadlines',
    'chat_messages',
    'checker_reports',
    'case_memory',
    'case_file',
    'case_facts',
    'case_phase',
    'case_deadlines',
    'message_citations',
    'message_feedback',
    'contract_reviews',
    'advice_corrections',
    'shareable_results',
    'support_tickets',
    'ai_usage'
  ];
begin
  foreach v_table in array v_tables loop
    -- Skip tables that don't exist in this environment.
    if not exists (
      select 1 from information_schema.tables
      where table_schema = 'public' and table_name = v_table
    ) then
      raise notice 'skip: public.% does not exist', v_table;
      continue;
    end if;

    -- 1. Add org_id column if missing
    execute format(
      'alter table public.%I add column if not exists org_id uuid references public.organizations(id) on delete set null',
      v_table
    );

    -- 2. Partial index on org_id
    execute format(
      'create index if not exists %I on public.%I (org_id) where org_id is not null',
      'idx_' || v_table || '_org_id', v_table
    );

    -- Detect user_id column for v2 RLS policy.
    select exists (
      select 1 from information_schema.columns
      where table_schema = 'public'
        and table_name = v_table
        and column_name = 'user_id'
    ) into v_has_user_id;

    -- Make sure RLS is on (it should be already, but be defensive)
    execute format('alter table public.%I enable row level security', v_table);

    -- 3. Drop legacy "_own" policies if they exist (created in 001_complete_schema.sql).
    --    Any policy name not matching is a no-op.
    execute format('drop policy if exists %I on public.%I', v_table || '_select_own', v_table);
    execute format('drop policy if exists %I on public.%I', v_table || '_insert_own', v_table);
    execute format('drop policy if exists %I on public.%I', v_table || '_update_own', v_table);
    execute format('drop policy if exists %I on public.%I', v_table || '_delete_own', v_table);

    -- 4. Drop any prior v2 policies (idempotency)
    execute format('drop policy if exists %I on public.%I', v_table || '_select_v2', v_table);
    execute format('drop policy if exists %I on public.%I', v_table || '_insert_v2', v_table);
    execute format('drop policy if exists %I on public.%I', v_table || '_update_v2', v_table);
    execute format('drop policy if exists %I on public.%I', v_table || '_delete_v2', v_table);

    -- 5. Install v2 policies. Two flavours:
    --    (a) tables with user_id   → B2C OR-branch + org branch
    --    (b) tables without user_id (rare; e.g. ai_usage indirected) → org-only
    if v_has_user_id then
      execute format($pol$
        create policy %I on public.%I for select to authenticated
        using (
          (org_id is null and user_id = auth.uid())
          or (org_id in (select public.current_user_org_ids()))
        )
      $pol$, v_table || '_select_v2', v_table);

      execute format($pol$
        create policy %I on public.%I for insert to authenticated
        with check (
          user_id = auth.uid()
          and (
            org_id is null
            or (
              org_id in (select public.current_user_org_ids())
              and public.current_user_org_role(org_id) in ('owner','admin','member')
            )
          )
        )
      $pol$, v_table || '_insert_v2', v_table);

      execute format($pol$
        create policy %I on public.%I for update to authenticated
        using (
          (org_id is null and user_id = auth.uid())
          or (
            org_id in (select public.current_user_org_ids())
            and public.current_user_org_role(org_id) in ('owner','admin','member')
          )
        )
        with check (
          (org_id is null and user_id = auth.uid())
          or (
            org_id in (select public.current_user_org_ids())
            and public.current_user_org_role(org_id) in ('owner','admin','member')
          )
        )
      $pol$, v_table || '_update_v2', v_table);

      execute format($pol$
        create policy %I on public.%I for delete to authenticated
        using (
          (org_id is null and user_id = auth.uid())
          or (
            org_id in (select public.current_user_org_ids())
            and public.current_user_org_role(org_id) in ('owner','admin')
          )
        )
      $pol$, v_table || '_delete_v2', v_table);
    else
      execute format($pol$
        create policy %I on public.%I for select to authenticated
        using (org_id in (select public.current_user_org_ids()))
      $pol$, v_table || '_select_v2', v_table);

      execute format($pol$
        create policy %I on public.%I for insert to authenticated
        with check (
          org_id in (select public.current_user_org_ids())
          and public.current_user_org_role(org_id) in ('owner','admin','member')
        )
      $pol$, v_table || '_insert_v2', v_table);

      execute format($pol$
        create policy %I on public.%I for update to authenticated
        using (
          org_id in (select public.current_user_org_ids())
          and public.current_user_org_role(org_id) in ('owner','admin','member')
        )
        with check (
          org_id in (select public.current_user_org_ids())
          and public.current_user_org_role(org_id) in ('owner','admin','member')
        )
      $pol$, v_table || '_update_v2', v_table);

      execute format($pol$
        create policy %I on public.%I for delete to authenticated
        using (
          org_id in (select public.current_user_org_ids())
          and public.current_user_org_role(org_id) in ('owner','admin')
        )
      $pol$, v_table || '_delete_v2', v_table);
    end if;

    raise notice 'retrofitted: public.%', v_table;
  end loop;
end
$migration$;

-- ── high-value composite for the org-case-list hot path ──────────────────────
-- Skipped via DO block if cases is missing status column; this is defensive.
do $$ begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'cases' and column_name = 'status'
  ) then
    execute 'create index if not exists idx_cases_org_status_created
             on public.cases (org_id, status, created_at desc)
             where org_id is not null';
  end if;
end $$;

notify pgrst, 'reload schema';

-- ROLLBACK:
-- For each retrofitted table T in {cases, documents, correspondence, deadlines,
--   chat_messages, checker_reports, case_memory, case_file, case_facts,
--   case_phase, case_deadlines, message_citations, message_feedback,
--   contract_reviews, advice_corrections, shareable_results, support_tickets,
--   ai_usage}:
--   drop policy if exists <T>_select_v2 on public.<T>;
--   drop policy if exists <T>_insert_v2 on public.<T>;
--   drop policy if exists <T>_update_v2 on public.<T>;
--   drop policy if exists <T>_delete_v2 on public.<T>;
--   drop index if exists public.idx_<T>_org_id;
--   alter table public.<T> drop column if exists org_id;
--   -- and recreate <T>_select_own / _insert_own / _update_own / _delete_own
--   -- from migration 001_complete_schema.sql.
-- drop index if exists public.idx_cases_org_status_created;
