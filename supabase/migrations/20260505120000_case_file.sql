-- =============================================================================
-- Case File feature — auto-built dossier from chat extraction.
-- =============================================================================
-- Ref: lib/services/case_file_extractor.dart
--      lib/services/case_file_service.dart
--      lib/models/case_file.dart
--
-- Three small tables, all RLS-locked to the owning user. The Dart service
-- dedupes BEFORE insert to keep these append-only and predictable.
-- =============================================================================

-- ── Events: timeline of legal events extracted from chat ────────────────────
create table if not exists public.case_file_events (
    id              uuid primary key default gen_random_uuid(),
    user_id         uuid not null references auth.users(id) on delete cascade,
    case_id         text,
    event_date      date,
    title           text not null,
    description     text,
    category        text check (category in (
                        'decision','deadline','submission',
                        'communication','hearing','other'
                    )),
    source_message_id text,
    created_at      timestamptz not null default now()
);

create index if not exists case_file_events_user_idx
    on public.case_file_events(user_id, created_at desc);
create index if not exists case_file_events_user_case_idx
    on public.case_file_events(user_id, case_id, event_date asc nulls last);

-- ── Parties: graph of authorities, people, companies, lawyers ───────────────
create table if not exists public.case_file_parties (
    id          uuid primary key default gen_random_uuid(),
    user_id     uuid not null references auth.users(id) on delete cascade,
    case_id     text,
    name        text not null,
    type        text check (type in ('authority','person','company','lawyer','other')),
    context     text,
    created_at  timestamptz not null default now()
);

create index if not exists case_file_parties_user_idx
    on public.case_file_parties(user_id, created_at desc);

-- ── Deadlines: countdown widgets + reminders ────────────────────────────────
create table if not exists public.case_file_deadlines (
    id              uuid primary key default gen_random_uuid(),
    user_id         uuid not null references auth.users(id) on delete cascade,
    case_id         text,
    deadline_date   date not null,
    title           text not null,
    law             text,
    completed       boolean not null default false,
    created_at      timestamptz not null default now()
);

create index if not exists case_file_deadlines_user_idx
    on public.case_file_deadlines(user_id, deadline_date asc);

-- ── Row-Level Security ──────────────────────────────────────────────────────
alter table public.case_file_events    enable row level security;
alter table public.case_file_parties   enable row level security;
alter table public.case_file_deadlines enable row level security;

-- Drop-then-create so the migration is idempotent if reapplied.
drop policy if exists "case_file_events_owner_all"    on public.case_file_events;
drop policy if exists "case_file_parties_owner_all"   on public.case_file_parties;
drop policy if exists "case_file_deadlines_owner_all" on public.case_file_deadlines;

create policy "case_file_events_owner_all"
    on public.case_file_events for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

create policy "case_file_parties_owner_all"
    on public.case_file_parties for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

create policy "case_file_deadlines_owner_all"
    on public.case_file_deadlines for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

-- ── Force PostgREST to reload its schema cache (avoids 'unknown table'
--    on hot deploys — see reference_pitfalls_chat_infra memory).
notify pgrst, 'reload schema';
