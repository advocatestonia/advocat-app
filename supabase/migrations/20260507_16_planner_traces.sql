-- =============================================================================
-- Phase 2 Pkg 6 — chat_planner_traces
--   Per-message planner+executor+critique trace for the three-pass legal
--   reasoning loop. Written by the legal_planner edge module (service-role)
--   after each Pro/legal turn that opted into the planner. Read by the
--   Reasoning Trail UI extension to render the plan + critique sections.
--
-- Owned by the user who owns the chat_messages row (cascade delete via FK).
-- RLS: read-own-only. Writes via service_role (proxy) only — no INSERT
-- policy means anon + authenticated cannot bypass the loop and write
-- arbitrary traces.
--
-- Idempotency: every CREATE / ALTER is `if not exists`-guarded; safe to
-- re-run with `supabase db push`.
--
-- Pkg 6 also extends user_settings (shipped in _14) with one column:
--   • enable_planner_for_legal_turns boolean default false
--   The toggle is OFF by default — only Pro users who explicitly enable it
--   pay the +2 round-trip latency cost. The Dart side is also gated on
--   subscription tier so flipping the bit on a free account is a no-op.
--
-- Migration filename slot _16: max preceding _NN this day is _15
-- (`20260507_15_case_phase.sql`). Per
-- `lesson_migration_alphabetical_order.md`, the `_NN_` prefix enforces
-- topological dep order when multiple migrations land on the same day.
-- =============================================================================

create extension if not exists pgcrypto;

-- ── 1. Extend user_settings with the per-user opt-in toggle ─────────────
alter table public.user_settings
    add column if not exists enable_planner_for_legal_turns boolean
        not null default false;

comment on column public.user_settings.enable_planner_for_legal_turns is
    'Pkg 6 opt-in: when true and user is Pro, legal turns run the '
    '3-pass planner+executor+critique loop. Default false to keep the '
    'extra latency cost off the default chat path.';

-- ── 2. chat_planner_traces table ───────────────────────────────────────
create table if not exists public.chat_planner_traces (
    id                  uuid primary key default gen_random_uuid(),
    message_id          uuid not null references public.chat_messages(id) on delete cascade,

    -- The XML/JSON-shaped plan emitted by the planner pass. Schema is
    -- intentionally jsonb so we can iterate on the structure without
    -- another migration. The Dart parser tolerates absent fields.
    plan                jsonb not null,
    -- Executor draft — the marker-bearing answer that goes through the
    -- citation_grounder. Stored verbatim so the eval suite can score
    -- pre/post-critique drafts independently.
    executor_response   text not null,
    -- Critique pass output: { material_gap: bool, issues: [string] }.
    critique            jsonb not null,
    -- True when the executor was re-run with the critique injected.
    -- Capped at 1 regen per turn (loop guard) — a second material_gap
    -- never re-fires.
    regenerated_once    boolean not null default false,

    latency_ms          int not null check (latency_ms >= 0),
    cost_cents          int not null default 0 check (cost_cents >= 0),

    created_at          timestamptz not null default now()
);

-- One trace per message — re-running the loop overwrites via the proxy's
-- service-role upsert. Enforced at the DB level so a buggy retry can't
-- silently double-write.
create unique index if not exists chat_planner_traces_message_uq
    on public.chat_planner_traces (message_id);

create index if not exists chat_planner_traces_created_idx
    on public.chat_planner_traces (created_at desc);

alter table public.chat_planner_traces enable row level security;

-- ── Read: owner-only via JOIN to chat_messages.user_id ─────────────────
-- Mirrors the message_citations pattern (Pkg 2): we don't denormalise
-- user_id onto the trace row; the join enforces ownership and keeps the
-- security model identical to the parent message.
do $$
begin
    if not exists (
        select 1
          from pg_policies
         where schemaname = 'public'
           and tablename  = 'chat_planner_traces'
           and policyname = 'chat_planner_traces_select_own'
    ) then
        create policy "chat_planner_traces_select_own"
            on public.chat_planner_traces
            for select
            using (
                exists (
                    select 1
                      from public.chat_messages m
                     where m.id = chat_planner_traces.message_id
                       and m.user_id = auth.uid()
                )
            );
    end if;
end
$$;

-- ── No INSERT/UPDATE/DELETE policy. ─────────────────────────────────────
-- Writes happen via service_role from the legal_planner orchestrator.
-- Anon + authenticated cannot mint traces directly, which keeps the
-- regenerated_once / cost_cents fields trustworthy.

-- ── RPC: planner_trace(p_message_id) ────────────────────────────────────
-- Owner-checked single-call fetcher for the chat UI extension. Mirrors
-- the security pattern in 20260507_08_message_citations.sql:
--   • SECURITY DEFINER (so the trace lookup bypasses RLS once we've
--     verified the caller owns the parent message)
--   • explicit search_path pin (defeats schema-injection class for
--     SECURITY DEFINER functions)
--   • auth.uid() null guard (rejects unauthenticated callers cleanly)
--   • owner re-check via chat_messages join (NEVER trust the request
--     payload's claim that they own this message)
create or replace function public.planner_trace(p_message_id uuid)
returns setof public.chat_planner_traces
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
          from public.chat_planner_traces
         where message_id = p_message_id
         order by created_at asc;
end;
$$;

grant execute on function public.planner_trace(uuid) to authenticated;

-- B5 (project convention): pin owner on the SECURITY DEFINER RPC. Apply
-- via service-role / postgres connection so this ALTER succeeds; the
-- function needs to bypass RLS via the owner-check above, so postgres
-- ownership is correct.
alter function public.planner_trace(uuid) owner to postgres;

comment on table public.chat_planner_traces is
    'Phase 2 Pkg 6 — three-pass legal reasoning trace (plan, executor, '
    'critique, optional regeneration). One row per message_id; written '
    'by the legal_planner edge module (service-role); read via the '
    'planner_trace(uuid) RPC.';

-- PGRST schema cache reload — make the RPC + new table reachable after
-- `db push` (memory: reference_pitfalls_chat_infra).
notify pgrst, 'reload schema';
