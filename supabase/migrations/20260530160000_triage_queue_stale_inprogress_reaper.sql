-- 20260530160000_triage_queue_stale_inprogress_reaper.sql
-- ---------------------------------------------------------------------------
-- DEPT-2 #2 (2026-05-30): stuck `in_progress` triage-queue rows leak forever.
--
-- The retry loop is: pending → claim_next_triage flips to in_progress
-- (FOR UPDATE SKIP LOCKED) → worker dispatches → complete_triage flips to
-- done / pending(retry) / dead_letter.
--
-- BUG: triage-retry-tick's reportOutcome() swallows a failed/throwing
-- complete_triage RPC (it only console.error's — see
-- supabase/functions/triage-retry-tick/index.ts reportOutcome). If the
-- dispatch already SUCCEEDED but the terminal complete_triage call hits a
-- transient DB blip, the row stays `in_progress` and is NEVER re-examined:
-- the original claim_next_triage only ever SELECTs status='pending'
-- (migration 20260528040000, line ~147). The email was triaged, but the
-- queue row leaks permanently — it never reaches done/dead_letter and the
-- DLQ dashboard misses it. Over time in_progress rows accumulate.
--
-- FIX: extend claim_next_triage to ALSO reclaim STALE in_progress rows —
-- ones whose updated_at is older than a reap interval (default 10 min, far
-- longer than any legitimate single dispatch). Reclaiming bumps attempts
-- exactly like a normal claim, so:
--   * a row stuck purely because complete_triage failed gets re-dispatched
--     and finishes cleanly on the retry (idempotent triage — re-triaging a
--     thread is safe, it upserts), then completes;
--   * a row that is genuinely wedging the worker (dispatch hangs every time)
--     still climbs attempts and eventually dead-letters at max_attempts
--     instead of leaking forever.
--
-- FOR UPDATE SKIP LOCKED keeps this race-safe: a row currently being
-- processed by a live worker holds its row lock, so the reaper skips it and
-- only ever picks up rows whose worker has already gone away (lock released)
-- AND whose updated_at has aged past the threshold. No double-dispatch of an
-- in-flight row.
--
-- Idempotent: pure CREATE OR REPLACE FUNCTION — safe to re-apply. No schema
-- change, no data migration. Reversible by re-applying 20260528040000.
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
declare
  -- How long an in_progress row may sit before the reaper treats it as
  -- abandoned. Must exceed the worst-case single dispatch (an email-triage
  -- call with a few Anthropic round-trips is seconds, not minutes), so 10
  -- minutes has a wide safety margin against reclaiming a genuinely live row.
  v_reap_interval constant interval := interval '10 minutes';
begin
  return query
  with claimed as (
    select q.id
      from app.email_triage_queue q
     where (
             -- normal path: ready pending rows
             (q.status = 'pending' and q.next_retry_at <= now())
             -- reaper path: in_progress rows abandoned past the threshold
             or (q.status = 'in_progress' and q.updated_at < now() - v_reap_interval)
           )
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

comment on function public.claim_next_triage(text, int) is
  'Claim up to N ready rows (pending past next_retry_at, OR in_progress abandoned >10min ago) via FOR UPDATE SKIP LOCKED. Reaps stale in_progress rows so a swallowed complete_triage failure cannot leak a row forever. Worker is responsible for calling complete_triage when done.';
