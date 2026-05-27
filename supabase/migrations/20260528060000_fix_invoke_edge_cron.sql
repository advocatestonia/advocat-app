-- Fix invoke_edge_cron: use existing vault entry name and return request_id
-- -----------------------------------------------------------------------------
-- Bug (2026-05-27): stripe_smoke.sh [4] fails with "could not invoke
-- reconcile-subscriptions". Root cause:
--
--   1. RPC looked up vault.decrypted_secrets WHERE name = 'project_url', but
--      the actual vault entry is named 'supabase_functions_url' (and already
--      includes the '/functions/v1' suffix). The RPC took the silent
--      `raise notice 'vault entries missing'` branch and returned NULL.
--
--   2. RPC was typed RETURNS void, so `select invoke_edge_cron('x') as id`
--      always produced NULL in the smoke test, hiding the silent-skip even
--      after vault was populated.
--
-- Fix:
--   - Look up name = 'supabase_functions_url' (no '/functions/v1' suffix
--     added by the function; the secret already encodes the full base path).
--   - Return bigint so the smoke test (and any caller) sees the pg_net
--     request_id and can poll net._http_response.
--   - Keep fail-soft behaviour: if vault entries are missing, return NULL
--     rather than raising — schedulers rely on idempotent no-ops.
-- -----------------------------------------------------------------------------

-- Drop+recreate because return type changes from void -> bigint
-- (Postgres disallows CREATE OR REPLACE across return-type changes).
drop function if exists public.invoke_edge_cron(text);

create function public.invoke_edge_cron(p_fn_name text)
returns bigint
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_url     text;
  v_secret  text;
  v_req_id  bigint;
begin
  begin
    select decrypted_secret into v_url
      from vault.decrypted_secrets
     where name = 'supabase_functions_url'
     limit 1;
  exception when others then
    v_url := null;
  end;

  begin
    select decrypted_secret into v_secret
      from vault.decrypted_secrets
     where name = 'cron_secret'
     limit 1;
  exception when others then
    v_secret := null;
  end;

  if v_url is null or v_secret is null then
    raise notice 'invoke_edge_cron(%): vault entries missing, skipping', p_fn_name;
    return null;
  end if;

  -- Strip trailing slash defensively; vault entry currently ends with
  -- '/functions/v1' (no trailing slash) but be robust to either form.
  v_url := rtrim(v_url, '/');

  select net.http_post(
    url := v_url || '/' || p_fn_name,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-cron-secret', v_secret
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 8000
  ) into v_req_id;

  return v_req_id;
end;
$function$;

comment on function public.invoke_edge_cron(text) is
  'Fires an edge function via pg_net using vault-stored URL and cron secret. '
  'Returns the pg_net request_id (bigint) so callers can poll net._http_response. '
  'Used by cron schedulers (reconcile-subscriptions, deadline-reminder, etc.) '
  'and by scripts/stripe_smoke.sh section [4].';
