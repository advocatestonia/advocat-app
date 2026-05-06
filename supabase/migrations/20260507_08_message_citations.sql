-- =============================================================================
-- Phase 2 Pkg 2 — chat_message_citations
--   Per-marker grounding outcome attached to a chat_messages row. Written by
--   the claude-proxy verifier after each Anthropic round-trip (service-role).
--   Read by:
--     • Flutter chat (renders chips + bottom sheet + verified/unverified
--       badges via the message_citations() RPC below)
--     • Pkg 8 eval suite (citation precision metric)
--     • Pkg 4 Case Workspace (per-case citation density signal)
--
-- Owned by the user who owns the chat_messages row (cascade delete via FK).
-- RLS: read-own-only. Writes via service_role (proxy) only — no INSERT
-- policy means anon + authenticated cannot bypass the verifier and write
-- arbitrary citations.
--
-- FK to law_chunks(id) is on delete set null — corpus refreshes (monthly
-- scheduled trigger) replace law_chunks rows; we do NOT want historical
-- citations to cascade-delete. The snapshot fields (act_slug, paragraph,
-- snippet, source_url, in_force) preserve the citation if the chunk row
-- disappears.
--
-- Idempotency: every CREATE / ALTER is `if not exists`-guarded; safe to
-- re-run with `supabase db push`.
-- =============================================================================

create table if not exists public.chat_message_citations (
    id              uuid primary key default gen_random_uuid(),
    message_id      uuid not null references public.chat_messages(id) on delete cascade,
    user_id         uuid not null references public.users(id) on delete cascade,
    case_id         uuid not null references public.cases(id) on delete cascade,

    marker          text not null,                    -- '[[ref:TLS:88]]'
    status          text not null check (status in ('verified', 'unverified', 'historical')),
    chunk_id        text references public.law_chunks(id) on delete set null,

    act_slug        text not null,
    paragraph       text not null,
    act_name        text,
    title           text,
    snippet         text,                             -- ≤400 chars; truncated body
    source_url      text,
    jurisdiction    text,
    in_force        boolean,                          -- snapshot at verification time
    occurrences     int not null default 1 check (occurrences > 0),

    created_at      timestamptz not null default now()
);

create index if not exists chat_message_citations_message_idx
    on public.chat_message_citations (message_id);

create index if not exists chat_message_citations_case_idx
    on public.chat_message_citations (case_id, created_at desc);

-- Partial index — most rows are 'verified', the ones we filter for
-- (eval / quality monitoring) are the unverified/historical minority.
create index if not exists chat_message_citations_status_idx
    on public.chat_message_citations (status) where status <> 'verified';

alter table public.chat_message_citations enable row level security;

-- ── Read: owner only. Mirrors public.chat_messages_select_own. ──────────
do $$
begin
    if not exists (
        select 1
          from pg_policies
         where schemaname = 'public'
           and tablename  = 'chat_message_citations'
           and policyname = 'chat_message_citations_select_own'
    ) then
        create policy "chat_message_citations_select_own"
            on public.chat_message_citations
            for select
            using (auth.uid() = user_id);
    end if;
end
$$;

-- ── No INSERT/UPDATE/DELETE policy. ─────────────────────────────────────
-- Writes happen via the service_role from claude-proxy (the verifier).
-- Anon + authenticated cannot mint citations directly, which keeps the
-- "verified" badge meaningful — only the proxy that ran the model can
-- mark a citation verified.

-- ── RPC: message_citations(p_message_id) ────────────────────────────────
-- Owner-checked single-call fetcher for the chat UI. Mirrors the
-- security pattern in 20260507_05_pii_redaction_map.sql (security
-- definer + explicit search_path + auth.uid() null-guard + alter
-- function owner to postgres). Authenticated callers only.
create or replace function public.message_citations(p_message_id uuid)
returns setof public.chat_message_citations
language plpgsql
stable
security definer
set search_path = public
as $$
declare
    v_owner uuid;
begin
    if auth.uid() is null then
        raise exception 'unauthorized' using errcode = '42501';
    end if;

    select user_id into v_owner
      from public.chat_messages
     where id = p_message_id;

    if v_owner is null or v_owner <> auth.uid() then
        raise exception 'forbidden' using errcode = '42501';
    end if;

    return query
        select *
          from public.chat_message_citations
         where message_id = p_message_id
         order by created_at asc;
end;
$$;

grant execute on function public.message_citations(uuid) to authenticated;

-- B5 (project convention): pin owner on the SECURITY DEFINER RPC. Apply
-- via service-role / postgres connection so this ALTER succeeds; the
-- function needs to bypass RLS via the owner-check above, so postgres
-- ownership is correct.
alter function public.message_citations(uuid) owner to postgres;

-- PGRST schema cache reload — make the RPC + new table reachable after
-- `db push` (memory: reference_pitfalls_chat_infra).
notify pgrst, 'reload schema';
