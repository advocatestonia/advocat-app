-- 20260529140000_pin_handle_new_user_search_path.sql
-- ---------------------------------------------------------------------------
-- P1 hardening — pin search_path on handle_new_user().
--
-- handle_new_user() is a SECURITY DEFINER trigger fired on every
-- auth.users INSERT. It runs with the definer's privileges (the
-- migration/superuser role) and was the ONLY SECURITY DEFINER function in the
-- schema without an explicit `set search_path` — every other definer fn
-- already pins it.
--
-- Without the pin, the function resolves unqualified object names using the
-- *caller's* search_path. The body already schema-qualifies public.profiles,
-- so this is defence-in-depth rather than a live exploit, but it matches the
-- Supabase linter "function_search_path_mutable" warning and the project's
-- own convention. Pinning closes the search-path-hijack class for the one
-- function that touches a privileged INSERT during signup.
--
-- IMPORTANT: the body below is byte-identical to the LIVE prod definition
-- (verified 2026-05-29 via pg_get_functiondef) except for the added
-- `set search_path = public`. The live function inserts into
-- public.profiles (id, full_name, preferred_language) — NOT public.users,
-- which does not exist in this database. An earlier draft of this migration
-- targeted public.users (the original 001 schema), which would have broken
-- signup; corrected here to match prod.
--
-- Idempotent: CREATE OR REPLACE. The trigger (on_auth_user_created) keeps
-- pointing at the same function — no trigger change needed.
-- ---------------------------------------------------------------------------

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, preferred_language)
  values (
    new.id,
    new.raw_user_meta_data ->> 'full_name',
    coalesce(new.raw_user_meta_data ->> 'preferred_language', 'et')
  );
  return new;
end;
$$;
