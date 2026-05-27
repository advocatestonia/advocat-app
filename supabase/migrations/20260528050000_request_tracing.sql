-- request_tracing — distributed trace_id column + trace_timeline view.
-- ---------------------------------------------------------------------------
-- Before this migration, debugging one user complaint ("my email never got
-- triaged") required a manual JOIN across agent_runs, agent_audit_log,
-- email_triage_results, case_timeline_events, email_triage_queue, plus
-- Supabase edge-function logs — every table keyed on different IDs
-- (agent_run_id vs thread_id vs case_id), making causal ordering of a
-- single request impossible without grep-and-eyeballing logs.
--
-- This migration adds a single nullable `trace_id uuid` column to every
-- "interesting" table and provides a JOIN VIEW `app.trace_timeline` that
-- returns the unified event stream for one trace_id in temporal order.
--
-- Trace_id is GENERATED at the edge fn entrypoint (or supplied via the
-- `x-trace-id` request header from Flutter), then PROPAGATED through every
-- downstream RPC and edge fn call. Failure mode is fail-soft: trace_id is
-- nullable everywhere, so missing headers / legacy rows just get NULL and
-- continue working.
-- ---------------------------------------------------------------------------

-- ── 1. ALTER TABLE for every audit-bearing table ─────────────────────────
-- Each ADD COLUMN is `if not exists` so the migration is re-run safe.

alter table public.agent_runs
  add column if not exists trace_id uuid;
create index if not exists agent_runs_trace_idx
  on public.agent_runs (trace_id)
  where trace_id is not null;

alter table public.agent_audit_log
  add column if not exists trace_id uuid;
create index if not exists agent_audit_log_trace_idx
  on public.agent_audit_log (trace_id)
  where trace_id is not null;

alter table public.email_triage_results
  add column if not exists trace_id uuid;
create index if not exists email_triage_results_trace_idx
  on public.email_triage_results (trace_id)
  where trace_id is not null;

alter table public.case_timeline_events
  add column if not exists trace_id uuid;
create index if not exists case_timeline_events_trace_idx
  on public.case_timeline_events (trace_id)
  where trace_id is not null;

-- email_triage_queue already added trace_id in 20260528040000. The
-- index there is unconditional via primary-key path; add a trace-aware
-- index for the timeline view JOIN to hit it cheaply.
create index if not exists email_triage_queue_trace_idx
  on app.email_triage_queue (trace_id)
  where trace_id is not null;

-- ── 2. Helper RPC: bind a trace_id to a thread_id (lookup hot path) ─────
-- The retry-tick worker needs to discover the trace_id that started a
-- thread's triage chain so successive retries record under the same
-- trace_id. The queue row carries it; this helper is just sugar.
create or replace function public.lookup_trace_for_thread(
  p_thread_id text
) returns uuid
language sql
security definer
set search_path = 'public', 'app'
stable
as $function$
  select trace_id
    from app.email_triage_queue
   where thread_id = p_thread_id
     and trace_id is not null
   order by created_at desc
   limit 1;
$function$;

revoke all on function public.lookup_trace_for_thread(text) from public, anon, authenticated;
grant execute on function public.lookup_trace_for_thread(text) to service_role;

-- ── 3. The trace_timeline view ──────────────────────────────────────────
-- Returns every event recorded under one trace_id across all instrumented
-- tables, ordered by happened_at. Each row carries a `source` discriminator
-- so the dashboard can colour by subsystem (agent_loop / triage / queue /
-- timeline).
--
-- Usage:
--   SELECT * FROM app.trace_timeline
--    WHERE trace_id = 'aaaa...'::uuid
--    ORDER BY happened_at;
--
-- The view is SECURITY INVOKER (default), so RLS on the underlying tables
-- still applies for client reads. Owner-only reads via `agent_runs` /
-- `agent_audit_log` / `case_timeline_events` RLS policies are preserved.
-- Service-role bypasses, which is the operator dashboard path.
create or replace view app.trace_timeline as
  select trace_id,
         'agent_run'::text             as source,
         id::text                       as ref_id,
         status                         as detail,
         null::int                      as iter,
         user_id,
         started_at                     as happened_at
    from public.agent_runs
   where trace_id is not null
  union all
  select trace_id,
         'agent_audit'::text            as source,
         id::text                       as ref_id,
         tool || ':' || status          as detail,
         iter                           as iter,
         user_id,
         started_at                     as happened_at
    from public.agent_audit_log
   where trace_id is not null
  union all
  select trace_id,
         'triage_result'::text          as source,
         id::text                       as ref_id,
         coalesce(severity, 'unknown')  as detail,
         null::int                      as iter,
         user_id,
         created_at                     as happened_at
    from public.email_triage_results
   where trace_id is not null
  union all
  select trace_id,
         'timeline_event'::text         as source,
         id::text                       as ref_id,
         event_type                     as detail,
         null::int                      as iter,
         user_id,
         occurred_at                    as happened_at
    from public.case_timeline_events
   where trace_id is not null
  union all
  select trace_id,
         'triage_queue'::text           as source,
         id::text                       as ref_id,
         status                         as detail,
         attempts                       as iter,
         user_id,
         updated_at                     as happened_at
    from app.email_triage_queue
   where trace_id is not null;

comment on view app.trace_timeline is
  'Unified per-trace event stream — JOIN across agent_runs, agent_audit_log, email_triage_results, case_timeline_events, email_triage_queue (2026-05-28). One SELECT replaces five manual JOINs during incident triage.';

-- ── 4. Function form for typed access (operator scripts) ────────────────
-- Functions are easier to call from external clients than views with
-- complex predicates. Returns the same rows but parameterised on trace_id.
create or replace function public.trace_timeline(
  p_trace_id uuid
) returns table (
  trace_id uuid,
  source text,
  ref_id text,
  detail text,
  iter int,
  user_id uuid,
  happened_at timestamptz
)
language sql
security definer
set search_path = 'public', 'app'
stable
as $function$
  select trace_id, source, ref_id, detail, iter, user_id, happened_at
    from app.trace_timeline
   where trace_id = p_trace_id
   order by happened_at asc, source asc;
$function$;

revoke all on function public.trace_timeline(uuid) from public, anon, authenticated;
grant execute on function public.trace_timeline(uuid) to service_role;

comment on function public.trace_timeline(uuid) is
  'Return the ordered event stream for one trace_id. Operator/admin tooling.';

notify pgrst, 'reload schema';
