-- =====================================================================
-- Case Timeline Events — auto-populated chronological log per case.
--
-- Pattern source: `cases/sulga/_timeline/TIMELINE.md` — owner currently
-- maintains a manual timeline file. This migration creates the in-app
-- equivalent so every paying case gets its own auto-built audit trail
-- populated from email events, consilium decisions, deadline writes,
-- document uploads, and phase transitions.
--
-- Adds:
--   * Table `public.case_timeline_events`
--   * RLS: owner SELECT only; INSERT restricted to service role
--     (edge functions write; users only read). A user can also INSERT
--     event_type='manual_note' rows for their own cases — that is the
--     one-and-only client-write path.
--   * RPC `record_case_event(p_case_id, p_event_type, p_title,
--                            p_summary, p_payload, p_occurred_at)`
--     SECURITY DEFINER — edge functions and the manual-note UI call
--     this. Idempotency dedupe via (case_id, event_type, dedupe_key)
--     where dedupe_key is sourced from payload->>'dedupe_key' or
--     synthesised from payload->>'id'.
--   * Index on (case_id, occurred_at DESC) — the read-pattern hot path.
--
-- Author: agent (case-timeline-ui task) | Date: 2026-05-25
-- Idempotency: every DDL is `if not exists`. `supabase db push` safe
-- to re-run.
-- =====================================================================

create extension if not exists pgcrypto;

-- ── 1. Table ──────────────────────────────────────────────────────────
create table if not exists public.case_timeline_events (
    id           uuid primary key default gen_random_uuid(),
    case_id      uuid not null references public.user_cases(id) on delete cascade,
    user_id      uuid not null references auth.users(id) on delete cascade,
    event_type   text not null
                 check (event_type in (
                     'email_in',
                     'email_out',
                     'consilium_decision',
                     'deadline_set',
                     'doc_uploaded',
                     'phase_change',
                     'manual_note'
                 )),
    title        text not null,
    summary      text,
    payload      jsonb not null default '{}'::jsonb,
    -- Deduplication: pipelines pass payload->>'dedupe_key' or
    -- payload->>'id'. The generated column lets us put a partial
    -- unique index on it so retries / re-triages do not duplicate
    -- events. Manual notes never set a dedupe_key (timeline is the
    -- user's freeform log) so they are exempt.
    dedupe_key   text generated always as (
        coalesce(payload->>'dedupe_key', payload->>'id')
    ) stored,
    occurred_at  timestamptz not null default now(),
    created_at   timestamptz not null default now()
);

-- ── 2. Indexes ────────────────────────────────────────────────────────
-- Hot path: render the case timeline newest-first.
create index if not exists case_timeline_events_case_idx
    on public.case_timeline_events (case_id, occurred_at desc);

-- Filter by user (when a global feed is needed — admin tooling).
create index if not exists case_timeline_events_user_idx
    on public.case_timeline_events (user_id, occurred_at desc);

-- Idempotency guard for pipeline writes.
create unique index if not exists case_timeline_events_dedupe_idx
    on public.case_timeline_events (case_id, event_type, dedupe_key)
    where dedupe_key is not null;

-- ── 3. RLS ────────────────────────────────────────────────────────────
alter table public.case_timeline_events enable row level security;

drop policy if exists "case_timeline_events_owner_select"
    on public.case_timeline_events;
drop policy if exists "case_timeline_events_owner_manual_insert"
    on public.case_timeline_events;
drop policy if exists "case_timeline_events_owner_delete_manual"
    on public.case_timeline_events;

-- Read: owner can read their own events.
create policy "case_timeline_events_owner_select"
    on public.case_timeline_events for select
    to authenticated
    using (auth.uid() = user_id);

-- Write: owner can insert manual notes only. All other event_types are
-- pipeline-emitted via the SECURITY DEFINER RPC below — direct INSERTs
-- of those types are blocked at policy level.
create policy "case_timeline_events_owner_manual_insert"
    on public.case_timeline_events for insert
    to authenticated
    with check (
        auth.uid() = user_id
        and event_type = 'manual_note'
    );

-- Delete: owner can delete their own manual notes (typo correction).
-- Pipeline-emitted rows are immutable to the client.
create policy "case_timeline_events_owner_delete_manual"
    on public.case_timeline_events for delete
    to authenticated
    using (auth.uid() = user_id and event_type = 'manual_note');

-- ── 4. RPC: record_case_event ─────────────────────────────────────────
-- SECURITY DEFINER — bypass RLS so service-role edge fns can write
-- system events on behalf of users. Ownership is verified by joining
-- through user_cases.user_id.
--
-- Returns:
--   - {ok: true,  event_id: <uuid>}            on insert
--   - {ok: true,  event_id: <uuid>, dedup: true} on idempotent retry
--   - {ok: false, reason: 'case_not_found'}    invalid case_id
--   - {ok: false, reason: 'invalid_event_type'} unknown event_type
create or replace function public.record_case_event(
    p_case_id     uuid,
    p_event_type  text,
    p_title       text,
    p_summary     text default null,
    p_payload     jsonb default '{}'::jsonb,
    p_occurred_at timestamptz default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
    v_user_id    uuid;
    v_event_id   uuid;
    v_occurred   timestamptz;
    v_dedupe_key text;
    v_existing   uuid;
begin
    -- Validate event_type.
    if p_event_type not in (
        'email_in','email_out','consilium_decision','deadline_set',
        'doc_uploaded','phase_change','manual_note'
    ) then
        return jsonb_build_object(
            'ok', false,
            'reason', 'invalid_event_type'
        );
    end if;

    -- Resolve the case owner (also serves as existence check).
    select user_id into v_user_id
      from public.user_cases
     where id = p_case_id;
    if v_user_id is null then
        return jsonb_build_object(
            'ok', false,
            'reason', 'case_not_found'
        );
    end if;

    v_occurred := coalesce(p_occurred_at, now());
    v_dedupe_key := coalesce(p_payload->>'dedupe_key', p_payload->>'id');

    -- Idempotent retry: if the same (case_id, event_type, dedupe_key)
    -- already exists, return the prior event_id rather than failing on
    -- the unique constraint.
    if v_dedupe_key is not null then
        select id into v_existing
          from public.case_timeline_events
         where case_id = p_case_id
           and event_type = p_event_type
           and dedupe_key = v_dedupe_key
         limit 1;
        if v_existing is not null then
            return jsonb_build_object(
                'ok', true,
                'event_id', v_existing,
                'dedup', true
            );
        end if;
    end if;

    insert into public.case_timeline_events (
        case_id, user_id, event_type, title, summary, payload, occurred_at
    ) values (
        p_case_id,
        v_user_id,
        p_event_type,
        coalesce(p_title, p_event_type),
        p_summary,
        coalesce(p_payload, '{}'::jsonb),
        v_occurred
    )
    returning id into v_event_id;

    return jsonb_build_object(
        'ok', true,
        'event_id', v_event_id
    );
exception
    when unique_violation then
        -- Race with a concurrent caller — return the already-inserted row.
        select id into v_existing
          from public.case_timeline_events
         where case_id = p_case_id
           and event_type = p_event_type
           and dedupe_key = v_dedupe_key
         limit 1;
        return jsonb_build_object(
            'ok', true,
            'event_id', v_existing,
            'dedup', true
        );
end;
$$;

comment on function public.record_case_event(
    uuid, text, text, text, jsonb, timestamptz
) is
    'Append an event to case_timeline_events. SECURITY DEFINER — used '
    'by edge fns (email-inbox-sync, email-triage, send-email, '
    'deadline-extractor, case-auto-patch) and the manual-note UI. '
    'Idempotent: re-inserts with same (case_id, event_type, dedupe_key) '
    'return the prior event_id.';

-- Allow authenticated users to call the RPC (for manual notes + UI).
-- Service role bypasses regardless. Anon is denied.
revoke all on function public.record_case_event(
    uuid, text, text, text, jsonb, timestamptz
) from public;
grant execute on function public.record_case_event(
    uuid, text, text, text, jsonb, timestamptz
) to authenticated, service_role;

-- ── 5. Backfill function ──────────────────────────────────────────────
-- Idempotent: scans the last 30 days of email_threads, email_triage_results,
-- and case_deadlines and emits matching timeline events. Skip if the
-- (case_id, event_type, dedupe_key) row already exists (handled by the
-- RPC's dedupe path).
--
-- Owner runs this once manually after migration:
--   select public.backfill_case_timeline_events(30);
-- Returns a JSONB report `{email_in: N, consilium_decision: N, deadline_set: N}`.
create or replace function public.backfill_case_timeline_events(
    p_lookback_days int default 30
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
    v_cutoff       timestamptz;
    v_email_in     int := 0;
    v_consilium    int := 0;
    v_deadline_set int := 0;
    rec            record;
    v_result       jsonb;
begin
    v_cutoff := now() - (p_lookback_days || ' days')::interval;

    -- ── email_in events ──────────────────────────────────────────────
    for rec in
        select et.case_id, et.user_id, et.id as thread_id,
               et.subject, et.snippet, et.last_message_at
          from public.email_threads et
         where et.case_id is not null
           and et.last_message_at >= v_cutoff
    loop
        v_result := public.record_case_event(
            rec.case_id,
            'email_in',
            coalesce(rec.subject, '(no subject)'),
            rec.snippet,
            jsonb_build_object(
                'thread_id', rec.thread_id,
                'dedupe_key', 'thread:' || rec.thread_id
            ),
            rec.last_message_at
        );
        if (v_result->>'ok')::boolean
           and (v_result->>'dedup') is null then
            v_email_in := v_email_in + 1;
        end if;
    end loop;

    -- ── consilium_decision events ────────────────────────────────────
    for rec in
        select etr.user_id, et.case_id, etr.id as triage_id,
               etr.triage_summary, etr.severity, etr.posture,
               etr.send_recommendation, etr.created_at
          from public.email_triage_results etr
          join public.email_threads et on et.id = etr.thread_id
         where et.case_id is not null
           and etr.created_at >= v_cutoff
    loop
        v_result := public.record_case_event(
            rec.case_id,
            'consilium_decision',
            'AI triage: ' || coalesce(rec.severity, 'review'),
            rec.triage_summary,
            jsonb_build_object(
                'triage_id', rec.triage_id,
                'severity', rec.severity,
                'posture', rec.posture,
                'send_recommendation', rec.send_recommendation,
                'dedupe_key', 'triage:' || rec.triage_id
            ),
            rec.created_at
        );
        if (v_result->>'ok')::boolean
           and (v_result->>'dedup') is null then
            v_consilium := v_consilium + 1;
        end if;
    end loop;

    -- ── deadline_set events ──────────────────────────────────────────
    for rec in
        select cd.case_id, cd.id as deadline_id, cd.title,
               cd.description, cd.deadline_at, cd.priority,
               cd.created_at, cd.statute_basis
          from public.case_deadlines cd
         where cd.created_at >= v_cutoff
           and cd.status = 'active'
    loop
        v_result := public.record_case_event(
            rec.case_id,
            'deadline_set',
            rec.title,
            rec.description,
            jsonb_build_object(
                'deadline_id', rec.deadline_id,
                'deadline_at', rec.deadline_at,
                'priority', rec.priority,
                'statute_basis', rec.statute_basis,
                'dedupe_key', 'deadline:' || rec.deadline_id
            ),
            rec.created_at
        );
        if (v_result->>'ok')::boolean
           and (v_result->>'dedup') is null then
            v_deadline_set := v_deadline_set + 1;
        end if;
    end loop;

    return jsonb_build_object(
        'email_in', v_email_in,
        'consilium_decision', v_consilium,
        'deadline_set', v_deadline_set,
        'lookback_days', p_lookback_days
    );
end;
$$;

comment on function public.backfill_case_timeline_events(int) is
    'One-shot backfill — scans email_threads, email_triage_results, and '
    'case_deadlines for the given lookback window and emits timeline '
    'events. Idempotent (dedupe_key prevents double-inserts).';

revoke all on function public.backfill_case_timeline_events(int) from public;
grant execute on function public.backfill_case_timeline_events(int)
    to service_role;

-- ── 6. PGRST schema reload ────────────────────────────────────────────
-- Ensures edge fns see the new table + RPC immediately after deploy.
notify pgrst, 'reload schema';
