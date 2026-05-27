-- email_triage_queue — durable retry queue / DLQ for email-triage pipeline.
-- ---------------------------------------------------------------------------
-- Before this migration, a transient Anthropic 529 / timeout / 5xx in
-- email-triage left email_threads.triage_status='pending' forever. There was
-- no attempt counter, no backoff, and no dead-letter path — operations had
-- to detect failures by SELECT count(*) FROM email_threads WHERE triage_status
-- = 'pending' AND last_message_at < now() - interval '15 minutes', then
-- manually re-invoke the function per row. This table replaces that by
-- giving the triage pipeline an at-least-once durable queue with explicit
-- attempts, next_retry_at (exponential backoff: 2^attempts * 60 s, capped),
-- last_error capture, and a dead_letter status after max_attempts.
--
-- Status state machine:
--   pending     → claim_next_triage flips to in_progress (SKIP LOCKED)
--   in_progress → complete_triage flips to done / pending (retry) / dead_letter
--   done        → terminal success
--   dead_letter → terminal failure; operator review via DLQ dashboard
--
-- RLS deny-all: only the service-role JWT (edge functions) writes here.
-- The SECURITY DEFINER RPCs below are the public surface; clients never
-- touch the table directly.
-- ---------------------------------------------------------------------------

create schema if not exists app;

create table if not exists app.email_triage_queue (
  id uuid primary key default gen_random_uuid(),
  thread_id text not null,
  user_id uuid not null,
  payload jsonb not null,
  attempts int not null default 0,
  max_attempts int not null default 5,
  next_retry_at timestamptz not null default now(),
  last_error text,
  dead_letter_at timestamptz,
  status text not null check (status in ('pending', 'in_progress', 'done', 'dead_letter')) default 'pending',
  trace_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Hot path: claim_next_triage scans pending rows ordered by next_retry_at.
create index if not exists idx_queue_next_retry
  on app.email_triage_queue (next_retry_at)
  where status = 'pending';

-- DLQ dashboard read pattern.
create index if not exists idx_queue_dead_letter
  on app.email_triage_queue (dead_letter_at desc)
  where status = 'dead_letter';

-- Idempotency: one open queue row per thread_id. Two concurrent
-- enqueue_triage calls for the same thread collapse into one row.
create unique index if not exists idx_queue_thread_open
  on app.email_triage_queue (thread_id)
  where status in ('pending', 'in_progress');

-- Backlog visibility for ops.
create index if not exists idx_queue_status_updated
  on app.email_triage_queue (status, updated_at desc);

-- RLS deny-all. Service-role bypasses; authenticated/anon never sees rows.
alter table app.email_triage_queue enable row level security;

drop policy if exists "email_triage_queue no client read" on app.email_triage_queue;
create policy "email_triage_queue no client read"
  on app.email_triage_queue
  for select
  using (false);

drop policy if exists "email_triage_queue no client write" on app.email_triage_queue;
create policy "email_triage_queue no client write"
  on app.email_triage_queue
  for insert
  with check (false);

drop policy if exists "email_triage_queue no client update" on app.email_triage_queue;
create policy "email_triage_queue no client update"
  on app.email_triage_queue
  for update
  using (false);

-- ---------------------------------------------------------------------------
-- enqueue_triage(thread_id, user_id, payload, trace_id) RETURNS uuid
--
-- Insert a new pending row, OR reset an existing open row's next_retry_at
-- back to now() so a fresh enqueue from email-inbox-sync runs immediately.
-- Returns the queue row id.
-- ---------------------------------------------------------------------------
create or replace function public.enqueue_triage(
  p_thread_id text,
  p_user_id uuid,
  p_payload jsonb default '{}'::jsonb,
  p_trace_id uuid default null
) returns uuid
language plpgsql
security definer
set search_path = 'public', 'app'
as $function$
declare
  v_id uuid;
begin
  insert into app.email_triage_queue (thread_id, user_id, payload, trace_id, status, next_retry_at)
  values (p_thread_id, p_user_id, coalesce(p_payload, '{}'::jsonb), p_trace_id, 'pending', now())
  on conflict (thread_id) where status in ('pending', 'in_progress') do update
    set next_retry_at = least(app.email_triage_queue.next_retry_at, now()),
        payload = coalesce(excluded.payload, app.email_triage_queue.payload),
        trace_id = coalesce(excluded.trace_id, app.email_triage_queue.trace_id),
        updated_at = now()
  returning id into v_id;
  return v_id;
end;
$function$;

revoke all on function public.enqueue_triage(text, uuid, jsonb, uuid) from public, anon, authenticated;
grant execute on function public.enqueue_triage(text, uuid, jsonb, uuid) to service_role;

-- ---------------------------------------------------------------------------
-- claim_next_triage(worker_id, batch_size) RETURNS SETOF queue rows
--
-- Pull up to batch_size ready rows (status='pending' AND next_retry_at <= now())
-- under FOR UPDATE SKIP LOCKED so N concurrent workers do not double-process.
-- Flips status to 'in_progress' and bumps attempts. Returns the claimed rows
-- so the worker can dispatch them.
-- ---------------------------------------------------------------------------
create or replace function public.claim_next_triage(
  p_worker_id text default 'triage-retry-tick',
  p_batch_size int default 10
) returns table (
  id uuid,
  thread_id text,
  user_id uuid,
  payload jsonb,
  attempts int,
  max_attempts int,
  trace_id uuid
)
language plpgsql
security definer
set search_path = 'public', 'app'
as $function$
begin
  return query
  with claimed as (
    select q.id
      from app.email_triage_queue q
     where q.status = 'pending'
       and q.next_retry_at <= now()
     order by q.next_retry_at asc
     limit p_batch_size
     for update skip locked
  )
  update app.email_triage_queue q
     set status = 'in_progress',
         attempts = q.attempts + 1,
         updated_at = now()
    from claimed
   where q.id = claimed.id
   returning q.id, q.thread_id, q.user_id, q.payload, q.attempts, q.max_attempts, q.trace_id;
end;
$function$;

revoke all on function public.claim_next_triage(text, int) from public, anon, authenticated;
grant execute on function public.claim_next_triage(text, int) to service_role;

-- ---------------------------------------------------------------------------
-- complete_triage(id, outcome, error) RETURNS row
--
-- outcome ∈ {'done', 'retry', 'dead_letter'}.
--   done        → terminal success.
--   retry       → if attempts >= max_attempts, transition to dead_letter;
--                 otherwise schedule next_retry_at = now() + 2^attempts * 60 s
--                 (capped at 1 hour). Keep status='pending' for claim.
--   dead_letter → force terminal failure (operator decision).
--
-- Backoff formula: delay_seconds = least(60 * power(2, attempts), 3600).
--   attempts=1 → 120 s   attempts=2 → 240 s   attempts=3 → 480 s
--   attempts=4 → 960 s   attempts=5 → 1920 s  attempts>=6 → 3600 s (cap)
-- ---------------------------------------------------------------------------
create or replace function public.complete_triage(
  p_id uuid,
  p_outcome text,
  p_error text default null
) returns table (
  id uuid,
  status text,
  attempts int,
  next_retry_at timestamptz
)
language plpgsql
security definer
set search_path = 'public', 'app'
as $function$
declare
  v_attempts int;
  v_max int;
  v_delay int;
  v_new_status text;
  v_next timestamptz;
begin
  if p_outcome not in ('done', 'retry', 'dead_letter') then
    raise exception 'invalid outcome: %', p_outcome;
  end if;

  select q.attempts, q.max_attempts into v_attempts, v_max
    from app.email_triage_queue q
   where q.id = p_id
   for update;

  if v_attempts is null then
    -- Row not found; nothing to do.
    return;
  end if;

  if p_outcome = 'done' then
    v_new_status := 'done';
    v_next := now();
  elsif p_outcome = 'dead_letter' or v_attempts >= v_max then
    v_new_status := 'dead_letter';
    v_next := now();
  else
    -- Retry path: exponential backoff capped at 1 hour.
    v_delay := least(60 * power(2, v_attempts)::int, 3600);
    v_new_status := 'pending';
    v_next := now() + (v_delay || ' seconds')::interval;
  end if;

  update app.email_triage_queue q
     set status = v_new_status,
         next_retry_at = v_next,
         last_error = coalesce(p_error, q.last_error),
         dead_letter_at = case when v_new_status = 'dead_letter' then now() else null end,
         updated_at = now()
   where q.id = p_id;

  return query
  select q.id, q.status, q.attempts, q.next_retry_at
    from app.email_triage_queue q
   where q.id = p_id;
end;
$function$;

revoke all on function public.complete_triage(uuid, text, text) from public, anon, authenticated;
grant execute on function public.complete_triage(uuid, text, text) to service_role;

-- ---------------------------------------------------------------------------
-- triage_queue_stats() — operations dashboard helper. Returns one row per
-- status with counts + oldest pending age. Cheap (uses partial indices).
-- ---------------------------------------------------------------------------
create or replace function public.triage_queue_stats()
returns table (
  status text,
  count bigint,
  oldest_age_seconds bigint
)
language sql
security definer
set search_path = 'public', 'app'
as $function$
  select status,
         count(*)::bigint,
         coalesce(extract(epoch from (now() - min(updated_at)))::bigint, 0)
    from app.email_triage_queue
   group by status;
$function$;

revoke all on function public.triage_queue_stats() from public, anon, authenticated;
grant execute on function public.triage_queue_stats() to service_role;

comment on table app.email_triage_queue is
  'At-least-once durable retry queue for email-triage (2026-05-28). Replaces silent pending status. RLS deny-all; service-role only via SECURITY DEFINER RPCs.';
comment on function public.enqueue_triage(text, uuid, jsonb, uuid) is
  'Enqueue or reset an email-triage retry. Idempotent on thread_id while a row is open.';
comment on function public.claim_next_triage(text, int) is
  'Claim up to N ready rows via FOR UPDATE SKIP LOCKED. Worker is responsible for calling complete_triage when done.';
comment on function public.complete_triage(uuid, text, text) is
  'Terminate or reschedule a claimed triage row. Exponential backoff 2^attempts * 60 s, capped at 1 hour. Transitions to dead_letter after max_attempts.';

notify pgrst, 'reload schema';
