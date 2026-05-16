-- =====================================================================
-- 20260515220031_anti_abuse_protection.sql
-- =====================================================================
-- P3 (Bentley batch) — Anti-abuse protection layer
--
-- Three tables + their RPCs, all service_role-only (no client write):
--
-- 1. anthropic_daily_spend
--    Tracks estimated Anthropic API spend per day.  claude-proxy
--    records every successful Sonnet/Haiku response after computing
--    cost via model_router.estimateCostCents().  When the cumulative
--    spend approaches the daily cap, the proxy refuses new requests
--    with HTTP 503 "Service capacity reached, try in 1 hour".
--
-- 2. rate_limit_events
--    Persistent sliding-window rate limiter (per-user / per-IP / per
--    bucket).  Edge Function in-process Map is fine for typical
--    abuse cases (1 cold start per minute), but a determined
--    attacker can hammer enough distinct cold starts to bypass the
--    in-process counter.  The DB-backed counter is authoritative.
--    Each row is one allowed request; the RPC counts rows in the
--    last 60s and refuses when count >= limit.
--
-- 3. error_log
--    Sentry-like sink for non-fatal incidents (cap breaches, rate
--    limit triggers, 5xx upstream, halt-rail false negatives).
--    Distinct from app_errors (which is FE-only widget exceptions);
--    error_log captures BE/edge-fn state the owner needs to triage
--    "is anyone attacking us right now?" questions.
--
-- All RPCs are SECURITY DEFINER so claude-proxy can call them via
-- service-role without the caller's JWT colouring the query.
-- =====================================================================

-- =====================================================================
-- 1. anthropic_daily_spend
-- =====================================================================

create table if not exists public.anthropic_daily_spend (
  spend_date       date primary key default current_date,
  cents_spent      bigint not null default 0,
  request_count    bigint not null default 0,
  last_request_at  timestamptz null,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

comment on table public.anthropic_daily_spend is
  'P3 anti-abuse: tracks estimated Anthropic API spend in cents per UTC '
  'day. claude-proxy increments via record_anthropic_spend() after each '
  'successful response.  Cap enforced at $500/day = 50000 cents (soft).';

alter table public.anthropic_daily_spend enable row level security;

drop policy if exists "anthropic_daily_spend: deny client access"
  on public.anthropic_daily_spend;
create policy "anthropic_daily_spend: deny client access"
  on public.anthropic_daily_spend
  for all
  to anon, authenticated
  using (false)
  with check (false);

-- ---------------------------------------------------------------------
-- RPC: record_anthropic_spend(input_tokens, output_tokens, model)
-- ---------------------------------------------------------------------
-- Increment today's spend counter using model-aware pricing:
--   Haiku 4.5   $1/M input + $5/M output
--   Sonnet 4.6  $3/M input + $15/M output
-- Returns the new daily total in cents so the caller can act on
-- threshold proximity in the same round-trip.
-- ---------------------------------------------------------------------

-- The OUT params share names with the table columns (spend_date,
-- cents_spent, request_count).  Without an explicit pragma, plpgsql
-- prefers the OUT variables in any bare reference inside the INSERT
-- column list, which trips the "column reference is ambiguous" error.
-- `#variable_conflict use_column` flips the preference for the function
-- body so bare column names always resolve to table columns; we
-- explicitly use `p_*` prefixes for arguments and `v_*` for locals so
-- this pragma cannot accidentally mask a real variable.
create or replace function public.record_anthropic_spend(
  p_input_tokens  bigint,
  p_output_tokens bigint,
  p_model         text default 'haiku'
)
returns table (
  spend_date      date,
  cents_spent     bigint,
  request_count   bigint
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
#variable_conflict use_column
declare
  v_in_rate  numeric;
  v_out_rate numeric;
  v_cents    bigint;
begin
  -- Pricing rates in cents per 1M tokens (USD * 100).
  if p_model ilike '%sonnet%' then
    v_in_rate  := 300;   -- $3.00/M
    v_out_rate := 1500;  -- $15.00/M
  else
    v_in_rate  := 100;   -- $1.00/M  (haiku default)
    v_out_rate := 500;   -- $5.00/M
  end if;

  -- Cents this turn: rounded up so we never undercount.
  v_cents := ceil(
    (coalesce(p_input_tokens, 0)  * v_in_rate  +
     coalesce(p_output_tokens, 0) * v_out_rate
    ) / 1000000.0
  )::bigint;

  insert into public.anthropic_daily_spend as t
         (spend_date, cents_spent, request_count, last_request_at, updated_at)
  values (current_date, v_cents, 1, now(), now())
  on conflict (spend_date) do update set
    cents_spent      = t.cents_spent + v_cents,
    request_count    = t.request_count + 1,
    last_request_at  = now(),
    updated_at       = now();

  return query
    select s.spend_date, s.cents_spent, s.request_count
    from public.anthropic_daily_spend s
    where s.spend_date = current_date;
end;
$$;

comment on function public.record_anthropic_spend(bigint, bigint, text) is
  'P3 anti-abuse: increment today''s anthropic_daily_spend by the '
  'estimated cost of one Claude response.  Returns the new total so '
  'the caller can refuse subsequent requests when approaching cap.';

-- ---------------------------------------------------------------------
-- RPC: get_anthropic_spend_today()
-- ---------------------------------------------------------------------
-- Cheap read of today's row — used by claude-proxy on EVERY request to
-- pre-check the cap before incurring an Anthropic call.
-- ---------------------------------------------------------------------

create or replace function public.get_anthropic_spend_today()
returns table (
  spend_date     date,
  cents_spent    bigint,
  request_count  bigint
)
language sql
security definer
set search_path = public, pg_temp
as $$
  select
    coalesce(s.spend_date, current_date)   as spend_date,
    coalesce(s.cents_spent, 0)::bigint     as cents_spent,
    coalesce(s.request_count, 0)::bigint   as request_count
  from (select 1) one
  left join public.anthropic_daily_spend s
         on s.spend_date = current_date;
$$;

comment on function public.get_anthropic_spend_today() is
  'P3 anti-abuse: read-only fetch of today''s anthropic spend total.';

-- =====================================================================
-- 2. rate_limit_events (sliding window, DB-backed)
-- =====================================================================

create table if not exists public.rate_limit_events (
  id          bigserial primary key,
  bucket      text not null,                   -- 'claude-proxy', 'demo', etc.
  principal   text not null,                   -- user_id UUID or 'ip:1.2.3.4'
  occurred_at timestamptz not null default now()
);

comment on table public.rate_limit_events is
  'P3 anti-abuse: sliding-window rate-limit counter.  One row per '
  'allowed request.  hit_rate_limit() RPC checks count in the last 60s '
  'before inserting.  Rows older than 1h are purged by '
  'prune_rate_limit_events().';

create index if not exists idx_rate_limit_events_lookup
  on public.rate_limit_events (bucket, principal, occurred_at desc);

create index if not exists idx_rate_limit_events_occurred
  on public.rate_limit_events (occurred_at);

alter table public.rate_limit_events enable row level security;

drop policy if exists "rate_limit_events: deny client access"
  on public.rate_limit_events;
create policy "rate_limit_events: deny client access"
  on public.rate_limit_events
  for all
  to anon, authenticated
  using (false)
  with check (false);

-- ---------------------------------------------------------------------
-- RPC: hit_rate_limit(bucket, principal, max_per_minute)
-- ---------------------------------------------------------------------
-- Atomic check-and-insert: counts how many events for this
-- (bucket, principal) pair occurred in the last 60s; if >= max, returns
-- (allowed=false, count=N) WITHOUT inserting.  Otherwise inserts the
-- new event row and returns (allowed=true, count=N+1).
-- ---------------------------------------------------------------------

create or replace function public.hit_rate_limit(
  p_bucket          text,
  p_principal       text,
  p_max_per_minute  int
)
returns table (
  allowed       boolean,
  current_count int,
  window_ms     int
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_count int;
begin
  select count(*)::int
    into v_count
    from public.rate_limit_events e
   where e.bucket    = p_bucket
     and e.principal = p_principal
     and e.occurred_at > now() - interval '60 seconds';

  if v_count >= p_max_per_minute then
    return query select false, v_count, 60000;
    return;
  end if;

  insert into public.rate_limit_events (bucket, principal)
  values (p_bucket, p_principal);

  return query select true, v_count + 1, 60000;
end;
$$;

comment on function public.hit_rate_limit(text, text, int) is
  'P3 anti-abuse: sliding-window rate limiter.  Returns allowed=false '
  'when the principal has already used max_per_minute requests in the '
  'last 60s, otherwise inserts a new event and returns allowed=true.';

-- ---------------------------------------------------------------------
-- RPC: prune_rate_limit_events()
-- ---------------------------------------------------------------------
-- Garbage-collect rows older than 1 hour.  Called from claude-proxy
-- opportunistically (one in N requests) to keep the table small.
-- ---------------------------------------------------------------------

create or replace function public.prune_rate_limit_events()
returns int
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_deleted int;
begin
  delete from public.rate_limit_events
   where occurred_at < now() - interval '1 hour';
  get diagnostics v_deleted = row_count;
  return v_deleted;
end;
$$;

comment on function public.prune_rate_limit_events() is
  'P3 anti-abuse: GC rate_limit_events rows older than 1h.';

-- =====================================================================
-- 3. error_log (Sentry-lite for edge-fn incidents)
-- =====================================================================

create table if not exists public.error_log (
  id           bigserial primary key,
  occurred_at  timestamptz not null default now(),
  kind         text not null,                   -- 'cap_breach', 'rate_limit_triggered',
                                                -- 'upstream_5xx', 'halt_rail_miss', etc.
  severity     text not null default 'warn',    -- 'info' | 'warn' | 'error' | 'critical'
  source       text null,                       -- function name e.g. 'claude-proxy'
  message      text null,                       -- short human description
  details      jsonb null,                      -- arbitrary structured context
  principal    text null,                       -- user_id or 'ip:...'
  request_id   text null
);

comment on table public.error_log is
  'P3 anti-abuse: Sentry-lite sink for edge-fn incidents (cap breach, '
  'rate-limit triggers, 5xx, halt-rail misses).  Service-role only.  '
  'Owner queries:  SELECT * FROM error_log WHERE occurred_at > now() - '
  'interval ''1 hour'' ORDER BY occurred_at DESC;';

create index if not exists idx_error_log_recent
  on public.error_log (occurred_at desc);

create index if not exists idx_error_log_kind
  on public.error_log (kind, occurred_at desc);

alter table public.error_log enable row level security;

drop policy if exists "error_log: deny client access" on public.error_log;
create policy "error_log: deny client access"
  on public.error_log
  for all
  to anon, authenticated
  using (false)
  with check (false);

-- ---------------------------------------------------------------------
-- RPC: log_incident(kind, severity, source, message, details, principal)
-- ---------------------------------------------------------------------
-- Thin INSERT wrapper.  Lets edge functions log without holding the
-- service-role key in a normal client (they get it via the RPC layer).
-- ---------------------------------------------------------------------

create or replace function public.log_incident(
  p_kind       text,
  p_severity   text default 'warn',
  p_source     text default null,
  p_message    text default null,
  p_details    jsonb default null,
  p_principal  text default null,
  p_request_id text default null
)
returns bigint
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_id bigint;
begin
  insert into public.error_log
    (kind, severity, source, message, details, principal, request_id)
  values
    (p_kind, p_severity, p_source, p_message, p_details, p_principal, p_request_id)
  returning id into v_id;
  return v_id;
end;
$$;

comment on function public.log_incident(text, text, text, text, jsonb, text, text) is
  'P3 anti-abuse: log one incident row to error_log.  Returns the new row id.';
