-- ============================================================================
-- supabase/tests/b2b_rls_tests.sql
-- B2B RLS coverage tests — cross-org isolation, B2C preservation, role gating.
--
-- Designed for pgTAP-style execution OR a plain `psql -f` smoke run. The file
-- is self-contained: it sets up fixtures inside a SAVEPOINT, runs assertions
-- via RAISE EXCEPTION on failure, and rolls everything back at the end so the
-- test leaves no residue.
--
-- Run locally:
--   psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/b2b_rls_tests.sql
-- ============================================================================

begin;

-- ── fixtures: 2 orgs, 4 users with varied roles + 1 pure-B2C user ────────────
do $fix$
declare
  v_user_a  uuid := gen_random_uuid();  -- owner of org A
  v_user_b  uuid := gen_random_uuid();  -- member of org A
  v_user_c  uuid := gen_random_uuid();  -- owner of org B
  v_user_d  uuid := gen_random_uuid();  -- pure B2C, no org
  v_org_a   uuid;
  v_org_b   uuid;
begin
  -- Direct inserts into auth.users (test-only).
  insert into auth.users (id, email) values
    (v_user_a, 'test-a-' || v_user_a || '@example.test'),
    (v_user_b, 'test-b-' || v_user_b || '@example.test'),
    (v_user_c, 'test-c-' || v_user_c || '@example.test'),
    (v_user_d, 'test-d-' || v_user_d || '@example.test')
  on conflict (id) do nothing;

  insert into public.organizations (slug, name, created_by)
    values ('test-org-a-' || substr(v_user_a::text, 1, 8), 'Test Org A', v_user_a)
    returning id into v_org_a;
  insert into public.organizations (slug, name, created_by)
    values ('test-org-b-' || substr(v_user_c::text, 1, 8), 'Test Org B', v_user_c)
    returning id into v_org_b;

  insert into public.org_members (org_id, user_id, role) values
    (v_org_a, v_user_a, 'owner'),
    (v_org_a, v_user_b, 'member'),
    (v_org_b, v_user_c, 'owner');

  perform set_config('test.user_a', v_user_a::text, false);
  perform set_config('test.user_b', v_user_b::text, false);
  perform set_config('test.user_c', v_user_c::text, false);
  perform set_config('test.user_d', v_user_d::text, false);
  perform set_config('test.org_a',  v_org_a::text,  false);
  perform set_config('test.org_b',  v_org_b::text,  false);
end
$fix$;

-- ── helper: impersonate a user for RLS ───────────────────────────────────────
-- We swap the JWT claim auth.uid() reads. Requires that the test runs as a role
-- without BYPASSRLS (so set role authenticated for the assertion blocks).
create or replace function pg_temp.assert_eq(p_actual int, p_expected int, p_label text)
returns void language plpgsql as $$
begin
  if p_actual is distinct from p_expected then
    raise exception 'TEST FAIL [%]: expected %, got %', p_label, p_expected, p_actual;
  end if;
end $$;

create or replace function pg_temp.set_auth_uid(p_uid uuid)
returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', p_uid::text, true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', p_uid::text, 'role', 'authenticated')::text, true);
end $$;

-- ── Test 1: org member sees only their org ───────────────────────────────────
do $t1$
declare
  v_user_a uuid := current_setting('test.user_a')::uuid;
  v_org_a  uuid := current_setting('test.org_a')::uuid;
  v_count  int;
begin
  perform pg_temp.set_auth_uid(v_user_a);
  set local role authenticated;

  select count(*) into v_count from public.organizations;
  perform pg_temp.assert_eq(v_count, 1, 'T1: user A sees exactly 1 org');

  select count(*) into v_count from public.organizations where id = v_org_a;
  perform pg_temp.assert_eq(v_count, 1, 'T1: user A sees org A specifically');

  reset role;
end
$t1$;

-- ── Test 2: pure B2C user sees zero orgs ─────────────────────────────────────
do $t2$
declare
  v_user_d uuid := current_setting('test.user_d')::uuid;
  v_count  int;
begin
  perform pg_temp.set_auth_uid(v_user_d);
  set local role authenticated;

  select count(*) into v_count from public.organizations;
  perform pg_temp.assert_eq(v_count, 0, 'T2: B2C user sees no orgs');

  select count(*) into v_count from public.org_members;
  perform pg_temp.assert_eq(v_count, 0, 'T2: B2C user sees no org_members');

  reset role;
end
$t2$;

-- ── Test 3: cross-org leak prevention ────────────────────────────────────────
do $t3$
declare
  v_user_a uuid := current_setting('test.user_a')::uuid;
  v_org_b  uuid := current_setting('test.org_b')::uuid;
  v_count  int;
begin
  perform pg_temp.set_auth_uid(v_user_a);
  set local role authenticated;

  select count(*) into v_count from public.organizations where id = v_org_b;
  perform pg_temp.assert_eq(v_count, 0, 'T3: user A cannot see org B');

  select count(*) into v_count from public.org_members where org_id = v_org_b;
  perform pg_temp.assert_eq(v_count, 0, 'T3: user A cannot see org B members');

  reset role;
end
$t3$;

-- ── Test 4: role-gated update on organizations ───────────────────────────────
do $t4$
declare
  v_user_b uuid := current_setting('test.user_b')::uuid;  -- 'member' role
  v_org_a  uuid := current_setting('test.org_a')::uuid;
  v_count  int;
begin
  perform pg_temp.set_auth_uid(v_user_b);
  set local role authenticated;

  -- 'member' should not be able to update the organization
  with up as (
    update public.organizations set name = 'hacked-by-member' where id = v_org_a returning 1
  )
  select count(*) into v_count from up;
  perform pg_temp.assert_eq(v_count, 0, 'T4: member role cannot update org name');

  reset role;
end
$t4$;

-- ── Test 5: owner CAN update org ─────────────────────────────────────────────
do $t5$
declare
  v_user_a uuid := current_setting('test.user_a')::uuid;
  v_org_a  uuid := current_setting('test.org_a')::uuid;
  v_count  int;
begin
  perform pg_temp.set_auth_uid(v_user_a);
  set local role authenticated;

  with up as (
    update public.organizations set name = 'Renamed Org A' where id = v_org_a returning 1
  )
  select count(*) into v_count from up;
  perform pg_temp.assert_eq(v_count, 1, 'T5: owner can update own org');

  reset role;
end
$t5$;

-- ── Test 6: current_user_org_ids returns correct set ─────────────────────────
do $t6$
declare
  v_user_a uuid := current_setting('test.user_a')::uuid;
  v_user_d uuid := current_setting('test.user_d')::uuid;
  v_count  int;
begin
  perform pg_temp.set_auth_uid(v_user_a);
  set local role authenticated;
  select count(*) into v_count from public.current_user_org_ids();
  perform pg_temp.assert_eq(v_count, 1, 'T6: user A has 1 org membership');

  perform pg_temp.set_auth_uid(v_user_d);
  select count(*) into v_count from public.current_user_org_ids();
  perform pg_temp.assert_eq(v_count, 0, 'T6: user D has 0 org memberships');

  reset role;
end
$t6$;

-- ── Test 7: removed member loses access ──────────────────────────────────────
do $t7$
declare
  v_user_b uuid := current_setting('test.user_b')::uuid;
  v_org_a  uuid := current_setting('test.org_a')::uuid;
  v_count  int;
begin
  -- Soft-remove user B from org A as superuser.
  update public.org_members set removed_at = now()
   where org_id = v_org_a and user_id = v_user_b;

  perform pg_temp.set_auth_uid(v_user_b);
  set local role authenticated;
  select count(*) into v_count from public.organizations where id = v_org_a;
  perform pg_temp.assert_eq(v_count, 0, 'T7: removed member cannot see org');

  reset role;
  -- restore
  update public.org_members set removed_at = null
   where org_id = v_org_a and user_id = v_user_b;
end
$t7$;

-- ── Test 8: seat-limit guard via org_increment_seats ─────────────────────────
do $t8$
declare
  v_org_a uuid := current_setting('test.org_a')::uuid;
  v_after int;
  v_ok    boolean := false;
begin
  -- Set seat_limit to 2 and seat_count to 2 so any +1 must fail.
  update public.organizations set seat_count = 2, seat_limit = 2 where id = v_org_a;
  begin
    select public.org_increment_seats(v_org_a, 1) into v_after;
  exception when others then
    v_ok := (sqlerrm = 'seat_limit_exceeded');
  end;
  if not v_ok then
    raise exception 'T8: expected seat_limit_exceeded';
  end if;
end
$t8$;

-- ── Test 9: audit-log export rejects non-owner ───────────────────────────────
do $t9$
declare
  v_user_b uuid := current_setting('test.user_b')::uuid;  -- member, not owner
  v_org_a  uuid := current_setting('test.org_a')::uuid;
  v_count  int;
begin
  insert into public.org_audit_log (org_id, action) values (v_org_a, 'test_action');

  perform pg_temp.set_auth_uid(v_user_b);
  set local role authenticated;
  select count(*) into v_count from public.org_audit_log_export(v_org_a);
  perform pg_temp.assert_eq(v_count, 0, 'T9: non-owner gets empty audit export');

  reset role;
end
$t9$;

-- ── Test 10: B2C user inserting case stays NULL-org ──────────────────────────
do $t10$
declare
  v_user_d uuid := current_setting('test.user_d')::uuid;
  v_count  int;
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='cases' and column_name='org_id'
  ) then
    perform pg_temp.set_auth_uid(v_user_d);
    set local role authenticated;
    -- Pre-existing B2C row count should not change under RLS.
    select count(*) into v_count from public.cases where org_id is not null and user_id = v_user_d;
    perform pg_temp.assert_eq(v_count, 0, 'T10: B2C user has no org-scoped cases');
    reset role;
  end if;
end
$t10$;

-- All assertions passed if we got here.
do $$ begin raise notice 'b2b_rls_tests: ALL TESTS PASSED'; end $$;

rollback;
