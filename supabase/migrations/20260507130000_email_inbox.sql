-- =====================================================================
-- Email Agent Integration — D2 schema
-- (handoff `business/email_agent_handoff_2026-05-06/09_INTEGRATION_INTO_ADVOCAT.md`)
--
-- Adds three tables that back the proactive email-triage feature:
--
--   * email_threads            — one row per Gmail thread we have observed,
--                                with triage_status + last-sync cursor.
--   * email_messages           — last 5 messages per thread (older purged
--                                by a future consolidation cron). Body is
--                                hard-capped at 50 KB at the application
--                                layer (D3 inbox-sync truncates before
--                                insert); a SQL CHECK enforces a slack 60
--                                KB ceiling so a buggy client cannot blow
--                                the row up to the row-size limit.
--   * email_triage_results     — Sonnet 4.6 v1.1-final output, exactly
--                                one row per triage run. The 6 mandatory
--                                output blocks land in dedicated columns;
--                                the 4 optional blocks land in jsonb.
--
-- Migration filename slot _13: max preceding _NN this day is _12
-- (`20260507120000_deadline_extractor_rpcs.sql`). Per
-- `lesson_migration_alphabetical_order.md`, the `_NN_` prefix enforces
-- topological dep order when multiple migrations land on the same day.
--
-- Idempotency: every DDL is `if not exists`; `supabase db push` is safe
-- to re-run. Mirrors `20260506100000_case_memory.sql` shape.
-- =====================================================================

create extension if not exists pgcrypto;
create extension if not exists "uuid-ossp";

-- ── 1. email_threads ──────────────────────────────────────────────────
-- One row per (user_id, gmail_thread_id) — the natural upsert key for
-- D3 inbox-sync. `case_id` is best-effort: D3 attempts to attach the
-- thread to an active case via subject + sender heuristics; nullable so
-- threads without a clear case still get triaged.
create table if not exists public.email_threads (
    id              uuid primary key default gen_random_uuid(),
    user_id         uuid not null references auth.users(id) on delete cascade,
    case_id         uuid references public.user_cases(id) on delete set null,
    gmail_thread_id text not null,
    last_message_at timestamptz not null,
    last_synced_at  timestamptz,
    snippet         text,
    subject         text,
    participants    jsonb not null default '[]'::jsonb,
    label_ids       text[] not null default '{}',
    triage_status   text not null default 'pending'
                     check (triage_status in
                       ('pending','triaged','skipped','handled-auto',
                        'archived','spam','error')),
    last_history_id text,
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),
    unique (user_id, gmail_thread_id)
);

create index if not exists email_threads_user_status_idx
    on public.email_threads (user_id, triage_status, last_message_at desc);

create index if not exists email_threads_case_idx
    on public.email_threads (case_id)
    where case_id is not null;

create index if not exists email_threads_pending_idx
    on public.email_threads (user_id, last_message_at desc)
    where triage_status = 'pending';

-- ── 2. email_messages ─────────────────────────────────────────────────
-- Per-message body + headers. D3 keeps the last 5 messages of a thread;
-- a future consolidation cron purges older rows. Body cap: 50 KB at the
-- app layer; SQL CHECK gives a slack 60 KB ceiling.
create table if not exists public.email_messages (
    id                uuid primary key default gen_random_uuid(),
    thread_id         uuid not null references public.email_threads(id)
                          on delete cascade,
    user_id           uuid not null references auth.users(id)
                          on delete cascade,
    gmail_message_id  text not null,
    rfc_message_id    text,             -- RFC-2822 Message-ID header
    sender_email      text not null,
    sender_name       text,
    to_recipients     text[] not null default '{}',
    cc_recipients     text[] not null default '{}',
    subject           text,
    body_plaintext    text,             -- ≤ 50 KB by D3, ≤ 60 KB by SQL
    snippet           text,
    sent_at           timestamptz not null,
    has_attachments   boolean not null default false,
    attachments_meta  jsonb not null default '[]'::jsonb,
    headers_meta      jsonb not null default '{}'::jsonb,
    created_at        timestamptz not null default now(),
    unique (gmail_message_id),
    constraint email_messages_body_size_check
        check (body_plaintext is null
               or octet_length(body_plaintext) <= 60000)
);

create index if not exists email_messages_thread_idx
    on public.email_messages (thread_id, sent_at desc);

create index if not exists email_messages_user_sent_idx
    on public.email_messages (user_id, sent_at desc);

-- ── 3. email_triage_results ───────────────────────────────────────────
-- Sonnet 4.6 output, one row per triage run. Mandatory enums are
-- column-typed; optional blocks land in jsonb. `seen_by_user_at` is the
-- "user has read the briefing" bit — the agent-intentions-cron sweeps
-- for severity ∈ (CRITICAL, HIGH) AND seen_by_user_at IS NULL.
create table if not exists public.email_triage_results (
    id                    uuid primary key default gen_random_uuid(),
    thread_id             uuid not null references public.email_threads(id)
                              on delete cascade,
    user_id               uuid not null references auth.users(id)
                              on delete cascade,
    -- 6 mandatory blocks (parsed by edge fn)
    privilege_check       text not null
        check (privilege_check in
            ('passed','blocked','suspicious_privileged',
             'waiver_suspected','own_counsel_advisory')),
    conflict_check        text not null
        check (conflict_check in ('passed','flagged')),
    triage_track          text,            -- canonicalised first track
    triage_inbound        text,
    triage_summary        text,            -- REASONING field, 2–4 sentences
    deadlines             jsonb not null default '[]'::jsonb,
    contradictions        jsonb not null default '[]'::jsonb,
    evidence_gaps         jsonb not null default '[]'::jsonb,
    posture               text not null
        check (posture in ('reply_now','hold_for_user','no_reply')),
    user_brief            text not null,
    actions_required      jsonb not null default '[]'::jsonb,
    -- 4 optional blocks
    appeal_route          jsonb,
    gdpr_basis            jsonb,
    attachments_pending   jsonb not null default '[]'::jsonb,
    memory_updates        jsonb not null default '[]'::jsonb,
    -- draft (only when posture=reply_now AND no privilege/conflict halt)
    draft_language        text,
    draft_subject         text,
    draft_body            text,
    draft_to              text[] not null default '{}',
    draft_cc              text[] not null default '{}',
    -- send recommendation enum
    send_recommendation   text not null
        check (send_recommendation in
            ('auto_send_eligible','hold_for_user_review','archive')),
    severity              text not null
        check (severity in ('CRITICAL','HIGH','MEDIUM','LOW')),
    -- meta
    prompt_version        text not null,        -- e.g. v1.1-final
    model_id              text not null,        -- claude-sonnet-4-6
    raw_model_output      text,                 -- audit trail (capped)
    reviewer_status       text
        check (reviewer_status is null
               or reviewer_status in ('passed','regenerated','flagged')),
    reviewer_failures     jsonb not null default '[]'::jsonb,
    seen_by_user_at       timestamptz,
    user_action           text
        check (user_action is null
               or user_action in ('sent','edited','rejected','snoozed')),
    created_at            timestamptz not null default now()
);

-- Hot path: agent-intentions-cron scans unseen CRITICAL/HIGH per user.
create index if not exists email_triage_user_severity_idx
    on public.email_triage_results
        (user_id, severity, created_at desc)
    where seen_by_user_at is null;

create index if not exists email_triage_thread_idx
    on public.email_triage_results (thread_id, created_at desc);

create index if not exists email_triage_pending_review_idx
    on public.email_triage_results (user_id, created_at desc)
    where send_recommendation = 'hold_for_user_review'
      and seen_by_user_at is null;

-- ── 4. updated_at trigger for email_threads ───────────────────────────
create or replace function public.touch_email_threads_updated_at()
returns trigger language plpgsql as $$
begin
    new.updated_at := now();
    return new;
end;
$$;

drop trigger if exists email_threads_updated_at on public.email_threads;
create trigger email_threads_updated_at
    before update on public.email_threads
    for each row execute function public.touch_email_threads_updated_at();

-- ── 5. Row-level security — owner-only ────────────────────────────────
alter table public.email_threads        enable row level security;
alter table public.email_messages       enable row level security;
alter table public.email_triage_results enable row level security;

drop policy if exists "email_threads_owner_all"  on public.email_threads;
drop policy if exists "email_messages_owner_all" on public.email_messages;
drop policy if exists "email_triage_owner_all"   on public.email_triage_results;

create policy "email_threads_owner_all" on public.email_threads
    for all to authenticated
    using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "email_messages_owner_all" on public.email_messages
    for all to authenticated
    using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "email_triage_owner_all" on public.email_triage_results
    for all to authenticated
    using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ── 6. PGRST schema cache reload ──────────────────────────────────────
-- Ensures D3/D4 edge functions can SELECT the new tables immediately
-- after `supabase db push` (memory: reference_pitfalls_chat_infra).
notify pgrst, 'reload schema';
