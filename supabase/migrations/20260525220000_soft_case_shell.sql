-- =====================================================================
-- Soft-case shell — auto-materialised case row for first-touch uploads.
--
-- P0 bug context:
-- The Flutter PdfParserService used to set documentId='' whenever the
-- caller passed activeCaseId=null. The pdf-parser edge function then
-- intentionally skipped the case_documents insert, which in turn meant
-- the deadline-extractor never ran. For an anonymous-but-authenticated
-- visitor uploading their first käännytyspäätös, the 10-day appeal
-- deadline silently vanished.
--
-- Fix: an authenticated user without an active case gets a "soft shell"
-- case row auto-created on first upload. The user can rename it later
-- (see banner in pdf_parser_service.dart). Anon visitors still get the
-- old documentId='' path — they can't persist anything anyway.
--
-- Adds:
--   * Column   public.user_cases.is_soft_shell BOOLEAN DEFAULT false
--                — flags shells so the UI can show the rename banner.
--   * RPC      public.ensure_soft_case_for_user(p_user_id uuid)
--                — SECURITY DEFINER, idempotent: returns the user's
--                  existing soft-shell case if any, otherwise inserts
--                  a fresh "Untitled case YYYY-MM-DD" row and returns
--                  the new id. Five consecutive calls return the same
--                  case_id (idempotency contract).
--   * RLS      Owner-only SELECT/UPDATE/DELETE already enforced by
--                Pkg 1.A's "own cases" policy on public.user_cases
--                (auth.uid() = user_id). No new policies required —
--                soft-shell rows are just regular user_cases rows.
--
-- Author: agent (soft-case-shell task) | Date: 2026-05-25
-- Idempotency: every DDL is `if not exists` / `create or replace`.
-- Safe to re-run `supabase db push`.
-- =====================================================================

create extension if not exists pgcrypto;

-- ── 1. Flag column on user_cases ──────────────────────────────────────
-- DEFAULT false so every existing row stays a "real" case. New shells
-- set this true explicitly inside ensure_soft_case_for_user.
alter table public.user_cases
    add column if not exists is_soft_shell boolean not null default false;

-- Partial index: 99% of rows are real cases, so a partial index on the
-- shell rows alone gives a tiny, fast lookup for ensure_soft_case().
create index if not exists user_cases_soft_shell_idx
    on public.user_cases (user_id)
    where is_soft_shell = true;

-- ── 2. RPC: ensure_soft_case_for_user ─────────────────────────────────
-- Idempotency contract: calling 5 times in a row MUST return the same
-- case_id. We pick the OLDEST soft shell so repeated calls converge on
-- one row (the user might also have manually-titled cases — those are
-- intentionally NOT reused; soft-shell flag is what we filter on).
--
-- SECURITY DEFINER because we want this to work even if the caller has
-- never inserted into user_cases before (e.g. a freshly-signed-up
-- user). We still verify p_user_id matches auth.uid() to prevent
-- cross-user shell creation via a forged param.
--
-- Title format mirrors the banner copy: "Untitled case YYYY-MM-DD".
-- Locale-aware rendering happens client-side; the DB stores a stable
-- ASCII string so search/sort stays deterministic.
create or replace function public.ensure_soft_case_for_user(p_user_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
    v_case_id uuid;
    v_today   text;
begin
    -- Defence-in-depth: only the user themselves (or service role) may
    -- create a shell. auth.uid() is null when service-role calls this,
    -- which is allowed (e.g. background workers).
    if auth.uid() is not null and auth.uid() <> p_user_id then
        raise exception 'ensure_soft_case_for_user: cross-user shell creation denied'
            using errcode = '42501';
    end if;

    -- Reuse the oldest existing shell so repeated calls converge.
    select id into v_case_id
    from public.user_cases
    where user_id = p_user_id
      and is_soft_shell = true
      and status = 'active'
    order by created_at asc
    limit 1;

    if v_case_id is not null then
        return v_case_id;
    end if;

    v_today := to_char(now() at time zone 'utc', 'YYYY-MM-DD');

    insert into public.user_cases (
        user_id,
        title,
        jurisdiction,
        status,
        language,
        is_soft_shell
    ) values (
        p_user_id,
        'Untitled case ' || v_today,
        'EE',           -- safe default; user can change on rename
        'active',
        'en',           -- safe default; client overrides via update
        true
    )
    returning id into v_case_id;

    return v_case_id;
end;
$$;

-- Grant execute to the authenticated role so logged-in users can call
-- this from PostgREST. Anon stays denied — they can't persist anyway.
grant execute on function public.ensure_soft_case_for_user(uuid)
    to authenticated, service_role;

-- PGRST schema cache reload — ensures the new RPC is reachable
-- immediately after `supabase db push` (memory pattern: see
-- reference_pitfalls_chat_infra).
notify pgrst, 'reload schema';
