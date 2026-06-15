-- =============================================================================
-- Plain-Language Explainer — Feature "Объясни простыми словами" (2026-06-16).
-- =============================================================================
--
-- Goal: a FI/EE user receives a Migri/court decision or a contract written in
-- bureaucratic legalese and does not understand what is wanted from them or
-- what to do next. The "explain it simply" flow lives today only as a one-off
-- prompt inside chat — no discoverable button, no work-with-selection, no
-- saved explanation. This feature gives it a dedicated single-shot screen and
-- endpoint (explain-plain) backed by the same model/RAG stack as chat.
--
-- This migration owns ONE table: `explain_requests`. It is the per-user
-- history + monthly-quota ledger for the explainer. One row per explanation.
--
-- Quota model (mirrors the chat/contract-review free-vs-pro split):
--   * Free tier: 3 explanations / calendar month.
--   * Pro tier : unlimited.
-- The edge function counts rows in the current period rather than keeping a
-- separate counter column, so history and quota can never drift apart.
--
-- PII NOTE (GDPR Art. 17): this table carries `user_id` AND user-pasted legal
-- text (`source_excerpt`) + the generated explanation. It MUST be added to
-- account-delete `USER_DATA_TABLES` and dsar-export. See function notes.
--
-- UPL NOTE: explanations are GENERIC INFORMATIONAL re-statements, never
-- individual legal advice. The edge function reuses the existing AI-disclaimer
-- and halt-rail; the client surfaces the standard disclaimer banner.
--
-- Idempotency: every statement is guarded so `supabase db push` is re-runnable.
-- =============================================================================

create extension if not exists pgcrypto;

-- ── 1. enums ──────────────────────────────────────────────────────────
do $$ begin
  if not exists (select 1 from pg_type where typname = 'explain_plain_level') then
    -- 'friend'    = "как другу" — A2/B1 readability, no jargon at all.
    -- 'with_terms'= "с юр-терминами" — plain but keeps key legal terms,
    --               each explained inline in a glossary.
    create type explain_plain_level as enum ('friend', 'with_terms');
  end if;
end $$;

-- ── 2. explain_requests table ─────────────────────────────────────────
-- Per-explanation row. RLS owner-only. The edge function counts rows in the
-- current calendar month to enforce the free-tier quota.
create table if not exists public.explain_requests (
    id              uuid primary key default gen_random_uuid(),
    user_id         uuid not null references auth.users(id) on delete cascade,
    -- Optional link to a case (Case Memory) — purely informational; this
    -- feature works equally on free-pasted text with no case.
    case_id         uuid,
    -- Optional source document this explanation was produced from (vault /
    -- case document id). Nullable: most calls paste/select raw text.
    source_document_id uuid,
    -- The level the user chose. Stored so the history can show which mode.
    level           explain_plain_level not null default 'friend',
    -- BCP-47-ish detected/selected locale of the explanation ('fi','et','ru'…).
    -- 17 locales supported via the shared language detector.
    output_language text not null default 'en',
    -- A SHORT excerpt of the source text (first chars) — kept for history
    -- display only, NOT the full document. Bounded to keep the row small and
    -- limit PII blast radius.
    source_excerpt  text not null,
    -- Character length of the full source the user submitted (analytics +
    -- "this was a long doc" UI hint). Not the excerpt length.
    source_length   int not null default 0,
    -- The generated explanation, stored as structured JSON:
    --   { tldr: string[], paragraphs: {heading,plain}[],
    --     glossary: {term,plain,ref?}[], next_steps: string[] }
    explanation     jsonb not null default '{}'::jsonb,
    -- Model that produced it (telemetry / future re-gen).
    model_used      text,
    created_at      timestamptz not null default now(),
    -- Guard rails: a non-empty, bounded excerpt.
    constraint explain_requests_excerpt_len
        check (char_length(source_excerpt) between 1 and 2000)
);

-- History list (newest first, per user). Also serves the monthly quota scan
-- (count rows where created_at >= period start).
create index if not exists explain_requests_user_created_idx
    on public.explain_requests (user_id, created_at desc);

-- Optional per-case filter for a future "explanations for this case" view.
create index if not exists explain_requests_case_idx
    on public.explain_requests (case_id)
    where case_id is not null;

-- ── 3. RLS — owner-only ───────────────────────────────────────────────
alter table public.explain_requests enable row level security;

drop policy if exists "own explain requests" on public.explain_requests;
create policy "own explain requests" on public.explain_requests
    for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

-- ── 4. RPC: explain_requests_recent ───────────────────────────────────
-- Ordered history for the explainer "Saved" tab. security invoker → RLS
-- confines results to the caller's rows; a non-owner gets an empty set.
create or replace function public.explain_requests_recent(p_limit int default 50)
returns table (
    id              uuid,
    case_id         uuid,
    level           explain_plain_level,
    output_language text,
    source_excerpt  text,
    source_length   int,
    explanation     jsonb,
    created_at      timestamptz
)
language sql stable security invoker
set search_path = public
as $$
    select
        r.id, r.case_id, r.level, r.output_language,
        r.source_excerpt, r.source_length, r.explanation, r.created_at
    from public.explain_requests r
    order by r.created_at desc
    limit greatest(1, least(coalesce(p_limit, 50), 200));
$$;

grant execute on function public.explain_requests_recent(int) to authenticated;

-- ── 5. RPC: explain_requests_used_this_month ──────────────────────────
-- Count of the caller's explanations since the first of the current calendar
-- month (UTC). The edge function uses this to enforce the free-tier cap of 3.
-- security invoker so RLS scopes the count to the caller automatically.
create or replace function public.explain_requests_used_this_month()
returns int
language sql stable security invoker
set search_path = public
as $$
    select count(*)::int
    from public.explain_requests r
    where r.created_at >= date_trunc('month', now());
$$;

grant execute on function public.explain_requests_used_this_month() to authenticated;
