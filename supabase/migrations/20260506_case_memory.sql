-- =====================================================================
-- Case Memory — Pkg 1.A of smart-lawyer rebuild (handoff 2026-05-05)
-- Tables: user_cases, case_documents, case_chat_sessions
-- Plus: case_id column on existing chat_messages table
--
-- Sister tasks (build on this schema):
--   Pkg 1.B — claude-proxy injects load_active_case() output into prompt
--   Pkg 1.C — auto-patch worker extracts JSON deltas from assistant turns
--   Pkg 1.D — Flutter "Мои дела" UI + active-case state
--
-- Pre-flight verification (2026-05-06):
--   * `public.chat_messages` exists (from 001_complete_schema.sql line 205).
--   * It already has a `case_id uuid not null references public.cases(id)`
--     column — `public.cases` is the LEGACY case table (deportation-only).
--   * The new `public.user_cases` is the multi-jurisdiction successor.
--   * The `add column if not exists case_id` below is a no-op when the
--     column already exists; it stays in the migration so Pkg 1.B has a
--     stable column name to filter on. See TODO at the alter statement
--     for the FK migration plan owned by Pkg 1.B/1.C.
--
-- Idempotency:
--   * `if not exists` everywhere. Owner may run `supabase db push` twice.
--   * `gen_random_uuid()` from pgcrypto (modern Supabase default).
--   * `vector` extension already loaded by 20260506_law_corpus.sql; the
--     `create extension if not exists` here is harmless.
-- =====================================================================

create extension if not exists vector;
create extension if not exists "uuid-ossp";

-- ── 1. user_cases ─────────────────────────────────────────────────────
-- Per-user case file. JSONB columns hold structured-but-evolving facts
-- the auto-patch worker (Pkg 1.C) updates after each assistant turn.
create table if not exists public.user_cases (
    id              uuid primary key default gen_random_uuid(),
    user_id         uuid not null references auth.users(id) on delete cascade,
    title           text not null,
    jurisdiction    text not null,                  -- 'EE' | 'FI' | 'RU' | 'EN' | 'UA' | ...
    case_type       text,                            -- 'deportation' | 'criminal' | 'civil' | 'family' | 'admin' | 'immigration' | 'labor'
    status          text not null default 'active' check (status in ('active','archived','closed')),
    case_numbers    jsonb not null default '[]'::jsonb,
    parties         jsonb not null default '[]'::jsonb,
    key_dates       jsonb not null default '[]'::jsonb,
    authorities     jsonb not null default '[]'::jsonb,
    timeline        jsonb not null default '[]'::jsonb,
    open_questions  jsonb not null default '[]'::jsonb,
    next_actions    jsonb not null default '[]'::jsonb,
    summary         text,
    language        text not null default 'ru',
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now()
);

create index if not exists user_cases_user_id_idx     on public.user_cases (user_id);
create index if not exists user_cases_status_idx      on public.user_cases (status);
create index if not exists user_cases_updated_idx     on public.user_cases (updated_at desc);

-- ── 2. case_documents ─────────────────────────────────────────────────
-- One row per uploaded file. `parsed_text` holds the FULL extracted body
-- (Pkg 2 PDF parser); `embedding` is computed from `parsed_summary` so
-- top-K similarity ranking is cheap. `key_extractions` is a structured
-- {doc_type, doc_date, parties, case_numbers, key_facts, ...} JSON.
create table if not exists public.case_documents (
    id               uuid primary key default gen_random_uuid(),
    case_id          uuid not null references public.user_cases(id) on delete cascade,
    user_id          uuid not null references auth.users(id) on delete cascade,
    filename         text not null,
    storage_path     text not null,
    mime_type        text,
    size_bytes       bigint,
    doc_type         text,        -- 'court_decision' | 'medical' | 'police_report' | 'correspondence' | 'evidence' | 'other'
    doc_date         date,
    parsed_text      text,
    parsed_summary   text,
    key_extractions  jsonb,
    embedding        vector(1536),
    uploaded_at      timestamptz not null default now()
);

create index if not exists case_documents_case_id_idx       on public.case_documents (case_id);
create index if not exists case_documents_user_id_idx       on public.case_documents (user_id);
create index if not exists case_documents_doc_type_idx      on public.case_documents (doc_type);
-- ivfflat lists=50 — fewer than law_chunks (lists=100) because per-case
-- doc counts are small; lists≈sqrt(rows) is the rule of thumb. Cosine.
create index if not exists case_documents_embedding_idx
    on public.case_documents using ivfflat (embedding vector_cosine_ops) with (lists = 50);

-- ── 3. case_chat_sessions ─────────────────────────────────────────────
-- A "session" groups messages by visit. Lets Pkg 1.B render a
-- per-session timeline in "Мои дела" without scanning all chat_messages.
create table if not exists public.case_chat_sessions (
    id          uuid primary key default gen_random_uuid(),
    case_id     uuid not null references public.user_cases(id) on delete cascade,
    user_id     uuid not null references auth.users(id) on delete cascade,
    started_at  timestamptz not null default now(),
    ended_at    timestamptz
);

create index if not exists case_chat_sessions_case_id_idx on public.case_chat_sessions (case_id);
create index if not exists case_chat_sessions_user_id_idx on public.case_chat_sessions (user_id);

-- ── 4. case_id column on chat_messages ────────────────────────────────
-- TODO(Pkg 1.B): chat_messages.case_id already exists (001_complete_schema
-- line 207) and references the LEGACY public.cases(id), not the new
-- public.user_cases(id). The `add column if not exists` below is a
-- no-op on existing prod and so does NOT migrate the FK. Pkg 1.B owns
-- the FK migration: either (a) a separate `user_case_id` column on
-- chat_messages keyed to user_cases, or (b) a backfill+swap migration.
-- For now Pkg 1.B can filter messages-for-a-case via the chat session
-- table (case_chat_sessions) join. Keeping the alter for fresh databases
-- where chat_messages was created without the column.
alter table if exists public.chat_messages
    add column if not exists case_id uuid references public.user_cases(id) on delete set null;
create index if not exists chat_messages_case_id_idx on public.chat_messages (case_id);

-- ── 5. updated_at trigger for user_cases ──────────────────────────────
create or replace function public.touch_user_cases_updated_at()
returns trigger language plpgsql as $$
begin
    new.updated_at := now();
    return new;
end;
$$;

drop trigger if exists user_cases_updated_at on public.user_cases;
create trigger user_cases_updated_at
    before update on public.user_cases
    for each row execute function public.touch_user_cases_updated_at();

-- =====================================================================
-- Row-level security — user owns their case file end-to-end.
-- =====================================================================

alter table public.user_cases         enable row level security;
alter table public.case_documents     enable row level security;
alter table public.case_chat_sessions enable row level security;

drop policy if exists "own cases"       on public.user_cases;
drop policy if exists "own case docs"   on public.case_documents;
drop policy if exists "own case chats"  on public.case_chat_sessions;

create policy "own cases"      on public.user_cases         for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own case docs"  on public.case_documents     for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own case chats" on public.case_chat_sessions for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- =====================================================================
-- Helper RPC: load_active_case — used by claude-proxy (Pkg 1.B) to fold
-- the active case + its 10 most recent docs into the system prompt.
--
-- Contract (input → output):
--   IN : p_case_id uuid
--   OUT: jsonb {
--          "case": <full user_cases row as jsonb>,
--          "recent_documents": [
--            <case_documents row minus parsed_text and embedding>,
--            … up to 10, ordered by uploaded_at desc
--          ]
--        }
--
-- Why exclude parsed_text/embedding from recent_documents:
--   * parsed_text can be megabytes per doc — Pkg 1.B fetches it
--     selectively via top-K similarity, not en bloc.
--   * embedding is a 1536-d vector — useless to ship to the client.
--
-- security invoker → RLS applies, so the calling user can only load
-- their own cases.
-- =====================================================================
create or replace function public.load_active_case(p_case_id uuid)
returns jsonb
language sql
stable
security invoker
as $$
    select jsonb_build_object(
        'case', to_jsonb(c.*),
        'recent_documents', coalesce(
            (
                select jsonb_agg(d_row order by d_row->>'uploaded_at' desc)
                from (
                    select to_jsonb(d.*) - 'parsed_text' - 'embedding' as d_row
                    from public.case_documents d
                    where d.case_id = c.id
                    order by d.uploaded_at desc
                    limit 10
                ) sub
            ),
            '[]'::jsonb
        )
    )
    from public.user_cases c
    where c.id = p_case_id
$$;

-- PGRST schema cache reload — ensures the new RPC is reachable
-- immediately after `supabase db push` (memory: reference_pitfalls_chat_infra).
notify pgrst, 'reload schema';
