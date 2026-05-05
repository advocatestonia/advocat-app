-- =============================================================================
-- Agent Intentions — long-horizon scheduled follow-ups.
-- =============================================================================
-- Ref: lib/services/assistant_tools.dart#_setFollowupIntention
--      lib/services/agent_intentions_service.dart
--      supabase/functions/agent-intentions-cron/index.ts
--
-- Why this exists
-- ---------------
-- When the AI promises to follow up later ("I'll remind you in 30 days about
-- the appeal deadline", "I'll check the court case status next month"), it
-- must actually do it. Chat is stateless across sessions, so we persist the
-- intention here and a cron Edge Function fires it when due.
--
-- GDPR
-- ----
-- conversation_context jsonb stores ONLY the AI's own intention summary, never
-- raw chat history. Hard cap of 500 chars on the `summary` field is enforced
-- both server-side via CHECK constraint and at the service layer.
-- =============================================================================

create table if not exists public.agent_intentions (
    id                    uuid primary key default gen_random_uuid(),
    user_id               uuid not null references auth.users(id) on delete cascade,
    case_id               text,
    intent_type           text not null check (intent_type in (
                              'remind_deadline',
                              'check_court_status',
                              'follow_up_question',
                              'check_company_status'
                          )),
    target_id             text,            -- e.g. court case number, company registry code
    check_until           timestamptz,     -- nullable — null = "until completed"
    next_check_at         timestamptz not null,
    last_checked_at       timestamptz,
    conversation_context  jsonb not null,  -- {summary: <=500 chars, locale: 'ru'|'et'|'en'}
    completed             boolean not null default false,
    notification_sent_at  timestamptz,
    created_at            timestamptz not null default now(),

    -- GDPR guard: summary length capped at 500 chars in JSON, locale enum.
    constraint agent_intentions_summary_len check (
        char_length(coalesce(conversation_context->>'summary', '')) <= 500
    ),
    constraint agent_intentions_locale_enum check (
        coalesce(conversation_context->>'locale', 'en') in ('ru','et','en')
    )
);

-- Hot path: cron-fn loops over due, uncompleted rows.
create index if not exists idx_agent_intentions_due
    on public.agent_intentions (next_check_at)
    where completed = false;

-- UI path: list pending intentions for a case_id.
create index if not exists idx_agent_intentions_user_case
    on public.agent_intentions (user_id, case_id, completed, next_check_at);

-- ── Row-Level Security ──────────────────────────────────────────────────────
alter table public.agent_intentions enable row level security;

drop policy if exists "agent_intentions_owner_all" on public.agent_intentions;

create policy "agent_intentions_owner_all"
    on public.agent_intentions for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

-- ── Force PostgREST to reload its schema cache ──────────────────────────────
notify pgrst, 'reload schema';
