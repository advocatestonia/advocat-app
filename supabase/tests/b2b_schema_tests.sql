-- ============================================================================
-- supabase/tests/b2b_schema_tests.sql
-- B2B schema integrity tests — tables, columns, indexes, constraints, FKs.
--
-- Read-only assertions. Run via:
--   psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/b2b_schema_tests.sql
-- ============================================================================

begin;

create or replace function pg_temp.assert_true(p_cond boolean, p_label text)
returns void language plpgsql as $$
begin
  if not p_cond then
    raise exception 'SCHEMA TEST FAIL [%]', p_label;
  end if;
end $$;

-- ── S1: all 8 core B2B tables exist ──────────────────────────────────────────
do $s1$
declare
  v_missing text[];
  v_tables text[] := array[
    'organizations','org_members','org_invitations','org_subscriptions',
    'org_api_keys','org_branding','org_audit_log','org_usage_counters',
    'org_seat_change_log','org_api_rate_counters'
  ];
  v_t text;
begin
  v_missing := array[]::text[];
  foreach v_t in array v_tables loop
    if not exists (
      select 1 from information_schema.tables
      where table_schema = 'public' and table_name = v_t
    ) then
      v_missing := v_missing || v_t;
    end if;
  end loop;
  perform pg_temp.assert_true(array_length(v_missing,1) is null,
    'S1: missing tables: ' || coalesce(array_to_string(v_missing, ','), ''));
end
$s1$;

-- ── S2: all 3 enums exist ────────────────────────────────────────────────────
do $s2$
declare
  v_t text;
  v_missing text[] := array[]::text[];
begin
  foreach v_t in array array['org_plan','org_status','org_role'] loop
    if not exists (select 1 from pg_type where typname = v_t) then
      v_missing := v_missing || v_t;
    end if;
  end loop;
  perform pg_temp.assert_true(array_length(v_missing,1) is null,
    'S2: missing enums: ' || coalesce(array_to_string(v_missing, ','), ''));
end
$s2$;

-- ── S3: helper functions exist ───────────────────────────────────────────────
do $s3$
begin
  perform pg_temp.assert_true(
    exists (select 1 from pg_proc where proname = 'current_user_org_ids'),
    'S3: current_user_org_ids missing');
  perform pg_temp.assert_true(
    exists (select 1 from pg_proc where proname = 'current_user_org_role'),
    'S3: current_user_org_role missing');
  perform pg_temp.assert_true(
    exists (select 1 from pg_proc where proname = 'org_increment_seats'),
    'S3: org_increment_seats missing');
  perform pg_temp.assert_true(
    exists (select 1 from pg_proc where proname = 'org_api_key_consume'),
    'S3: org_api_key_consume missing');
  perform pg_temp.assert_true(
    exists (select 1 from pg_proc where proname = 'org_audit_log_write'),
    'S3: org_audit_log_write missing');
  perform pg_temp.assert_true(
    exists (select 1 from pg_proc where proname = 'org_audit_log_export'),
    'S3: org_audit_log_export missing');
  perform pg_temp.assert_true(
    exists (select 1 from pg_proc where proname = 'resolve_org_brand_by_slug'),
    'S3: resolve_org_brand_by_slug missing');
end
$s3$;

-- ── S4: RLS is enabled on all B2B tables ─────────────────────────────────────
do $s4$
declare
  v_t text;
  v_missing text[] := array[]::text[];
begin
  for v_t in
    select unnest(array[
      'organizations','org_members','org_invitations','org_subscriptions',
      'org_api_keys','org_branding','org_audit_log','org_usage_counters',
      'org_seat_change_log','org_api_rate_counters'
    ])
  loop
    if not exists (
      select 1 from pg_class c
      join pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public' and c.relname = v_t and c.relrowsecurity = true
    ) then
      v_missing := v_missing || v_t;
    end if;
  end loop;
  perform pg_temp.assert_true(array_length(v_missing,1) is null,
    'S4: RLS disabled on: ' || coalesce(array_to_string(v_missing, ','), ''));
end
$s4$;

-- ── S5: org_members has UNIQUE (org_id, user_id) ─────────────────────────────
do $s5$
begin
  perform pg_temp.assert_true(
    exists (
      select 1
      from pg_constraint c
      join pg_class t on t.oid = c.conrelid
      where t.relname = 'org_members'
        and c.contype = 'u'
        and (
          select array_agg(a.attname::text order by k.k)
          from unnest(c.conkey) with ordinality as k(attnum, k)
          join pg_attribute a on a.attrelid = c.conrelid and a.attnum = k.attnum
        ) <@ array['org_id','user_id']::text[]
    ),
    'S5: org_members UNIQUE(org_id, user_id) missing');
end
$s5$;

-- ── S6: partial indexes exist on retrofitted tables ──────────────────────────
do $s6$
declare
  v_t text;
  v_idx text;
  v_missing text[] := array[]::text[];
begin
  for v_t in
    select unnest(array[
      'cases','documents','correspondence','deadlines','chat_messages',
      'checker_reports','case_memory','case_file','case_facts','case_phase',
      'case_deadlines','message_citations','message_feedback',
      'contract_reviews','advice_corrections','shareable_results',
      'support_tickets','ai_usage'
    ])
  loop
    if not exists (
      select 1 from information_schema.tables
      where table_schema='public' and table_name = v_t
    ) then
      continue;  -- table doesn't exist in this env; skip
    end if;

    -- org_id column exists?
    if not exists (
      select 1 from information_schema.columns
      where table_schema='public' and table_name=v_t and column_name='org_id'
    ) then
      v_missing := v_missing || (v_t || '.org_id-column');
      continue;
    end if;

    -- partial index exists?
    v_idx := 'idx_' || v_t || '_org_id';
    if not exists (
      select 1 from pg_indexes
      where schemaname='public' and tablename=v_t and indexname=v_idx
    ) then
      v_missing := v_missing || v_idx;
    end if;
  end loop;
  perform pg_temp.assert_true(array_length(v_missing,1) is null,
    'S6: missing org_id retrofit elements: ' || coalesce(array_to_string(v_missing,','),''));
end
$s6$;

-- ── S7: FK from org_members.org_id → organizations.id has ON DELETE CASCADE ──
do $s7$
declare
  v_action char;
begin
  select c.confdeltype into v_action
  from pg_constraint c
  join pg_class t on t.oid = c.conrelid
  join pg_class rt on rt.oid = c.confrelid
  where t.relname = 'org_members'
    and rt.relname = 'organizations'
    and c.contype = 'f'
  limit 1;

  perform pg_temp.assert_true(v_action = 'c', 'S7: org_members FK should CASCADE');
end
$s7$;

-- ── S8: FK from retrofit org_id → organizations.id is SET NULL ───────────────
do $s8$
declare
  v_action char;
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='cases' and column_name='org_id'
  ) then
    select c.confdeltype into v_action
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_class rt on rt.oid = c.confrelid
    join pg_attribute a on a.attrelid = c.conrelid
                       and a.attnum = c.conkey[1]
    where t.relname = 'cases'
      and rt.relname = 'organizations'
      and c.contype = 'f'
      and a.attname = 'org_id'
    limit 1;

    perform pg_temp.assert_true(v_action = 'n', 'S8: cases.org_id FK should SET NULL on org delete');
  end if;
end
$s8$;

-- ── S9: slug constraint regex ────────────────────────────────────────────────
do $s9$
declare
  v_blocked boolean := false;
begin
  begin
    insert into public.organizations (slug, name) values ('Bad Slug With Spaces', 'X');
  exception when check_violation then
    v_blocked := true;
  end;
  perform pg_temp.assert_true(v_blocked, 'S9: invalid slug must violate CHECK');
end
$s9$;

-- ── S10: storage bucket exists ───────────────────────────────────────────────
do $s10$
begin
  perform pg_temp.assert_true(
    exists (select 1 from storage.buckets where id = 'org-branding'),
    'S10: org-branding bucket missing');
end
$s10$;

do $$ begin raise notice 'b2b_schema_tests: ALL TESTS PASSED'; end $$;

rollback;
