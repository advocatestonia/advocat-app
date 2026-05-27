-- rate_limit_buckets — postgres-backed rate limiter
-- ---------------------------------------------------------------------------
-- Replaces the in-process Map<string, {count, windowStart}> rate limiter in
-- _shared/auth.ts. The old implementation stored counters in a Deno isolate's
-- memory; because Supabase Edge runs N isolates behind a load balancer, the
-- effective rate cap was N × maxPerMinute (5-10× the documented value).
--
-- This table is the per-(principal, function) per-minute bucket. The
-- consume_rate_limit RPC does an atomic UPSERT + check under an advisory
-- xact lock keyed on bucket_key, so N concurrent edge-fn callers cannot
-- race past the cap.
--
-- Bucket key format (chosen by caller via rateLimitKey helper):
--   "<bucket-name>:<user-uuid>"            for authenticated principals
--   "<bucket-name>:ip:<client-ip>"         for anonymous principals
-- The window_start column is truncated to the minute, so a single
-- (bucket_key, window_start) row IS the per-minute counter. Rows roll over
-- naturally when the minute changes; cleanup_rate_limit_buckets() prunes
-- rows older than 5 minutes on a cron tick.
-- ---------------------------------------------------------------------------

create schema if not exists app;

create table if not exists app.rate_limit_buckets (
  bucket_key text not null,
  window_start timestamptz not null,
  count int not null default 0,
  primary key (bucket_key, window_start)
);

create index if not exists rate_limit_buckets_window_idx
  on app.rate_limit_buckets (window_start);

-- RLS deny-all. Only the SECURITY DEFINER RPC below (running as the
-- function owner = postgres) reads/writes this table. Client JWTs never
-- see it.
alter table app.rate_limit_buckets enable row level security;

drop policy if exists "rate_limit_buckets no client read" on app.rate_limit_buckets;
create policy "rate_limit_buckets no client read"
  on app.rate_limit_buckets
  for select
  using (false);

drop policy if exists "rate_limit_buckets no client write" on app.rate_limit_buckets;
create policy "rate_limit_buckets no client write"
  on app.rate_limit_buckets
  for insert
  with check (false);

drop policy if exists "rate_limit_buckets no client update" on app.rate_limit_buckets;
create policy "rate_limit_buckets no client update"
  on app.rate_limit_buckets
  for update
  using (false);

-- ---------------------------------------------------------------------------
-- consume_rate_limit(bucket_key, max_per_minute) RETURNS BOOLEAN
--
-- Returns TRUE if the call is admitted (under the cap, counter incremented),
-- FALSE if the cap is exhausted for the current minute.
--
-- Concurrency: pg_advisory_xact_lock(hashtext(bucket_key)) serialises
-- callers with the same bucket_key; rows fall out of scope at COMMIT, so
-- the lock is short-lived. Different bucket_keys hash to different slots
-- (modulo collisions), so unrelated users do not block each other.
-- ---------------------------------------------------------------------------
create or replace function public.consume_rate_limit(
  p_bucket_key text,
  p_max_per_minute int
) returns boolean
language plpgsql
security definer
set search_path = 'public', 'app'
as $function$
declare
  v_window timestamptz := date_trunc('minute', now());
  v_count int;
begin
  -- Short-lived xact-scoped lock keyed on the bucket. Two concurrent
  -- requests against the SAME (principal, function) serialise; everything
  -- else stays parallel. Released automatically at COMMIT/ROLLBACK.
  perform pg_advisory_xact_lock(hashtext(p_bucket_key));

  insert into app.rate_limit_buckets (bucket_key, window_start, count)
  values (p_bucket_key, v_window, 1)
  on conflict (bucket_key, window_start) do update
    set count = app.rate_limit_buckets.count + 1
  returning count into v_count;

  if v_count > p_max_per_minute then
    -- We already incremented; the caller is OVER the cap. Decrement back
    -- so the recorded count reflects the genuine in-window admissions and
    -- can be used for telemetry.
    update app.rate_limit_buckets
       set count = greatest(0, count - 1)
     where bucket_key = p_bucket_key
       and window_start = v_window;
    return false;
  end if;

  return true;
end;
$function$;

revoke all on function public.consume_rate_limit(text, int) from public, anon, authenticated;
grant execute on function public.consume_rate_limit(text, int) to service_role;

-- ---------------------------------------------------------------------------
-- cleanup_rate_limit_buckets() — prune rows older than 5 minutes.
--
-- The window is 1 minute, but we retain 5 minutes' worth of rows so an
-- operator can SELECT recent admission counts for forensics (e.g. "did the
-- attacker actually hit 429?"). Beyond 5 minutes the row is dead weight.
-- ---------------------------------------------------------------------------
create or replace function public.cleanup_rate_limit_buckets()
returns int
language plpgsql
security definer
set search_path = 'public', 'app'
as $function$
declare
  v_deleted int;
begin
  delete from app.rate_limit_buckets
   where window_start < (now() - interval '5 minutes');
  get diagnostics v_deleted = row_count;
  return v_deleted;
end;
$function$;

revoke all on function public.cleanup_rate_limit_buckets() from public, anon, authenticated;
grant execute on function public.cleanup_rate_limit_buckets() to service_role;

comment on table app.rate_limit_buckets is
  'Postgres-backed per-minute rate limit counters (2026-05-28). Replaces in-isolate Map in _shared/auth.ts. Pruned by cleanup_rate_limit_buckets() — rows >5min are deleted.';
comment on function public.consume_rate_limit(text, int) is
  'Atomic UPSERT + cap check under advisory xact lock. Returns TRUE if admitted, FALSE if over cap. Called by _shared/auth.ts on every billable edge fn invocation.';
comment on function public.cleanup_rate_limit_buckets() is
  'Prune rate_limit_buckets rows >5min old. Invoke from cron tick (e.g. alert-tick) or pg_cron if installed.';
