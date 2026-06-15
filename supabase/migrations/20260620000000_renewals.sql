-- =====================================================================
-- Permit / Document Renewal Radar (Feature #5) — renewable_documents.
-- =====================================================================
-- The existing Deadline Radar (Pkg 9, public.case_deadlines) and the Smart
-- Case Follow-ups (public.case_followups) both track work tied to a *case*:
-- procedural deadlines parsed out of documents, and soft AI next-steps. Neither
-- tracks the **expiry of the user's own personal documents** — residence permit
-- (ВНЖ), passport, insurance, driving licence — and neither sends *advance*
-- reminders far ahead of the date (90 / 30 / 7 days out).
--
-- Missing a renewal window is a real expat catastrophe (cf. the Sulga case: a
-- lapsed residence status cascaded into deportation). A renewable document is
-- therefore its own first-class entity, deliberately separate from court
-- deadlines:
--
--   * case_deadlines     : HARD statutory deadlines parsed from case documents.
--   * case_followups     : SOFT AI/user next-steps inside a case.
--   * renewable_documents: the user's PERSONAL documents that periodically
--                          expire and must be renewed (this file). NOT tied to
--                          any case; lives at the user level.
--
-- Reminder model: three lead windows (90 / 30 / 7 days before expiry). A
-- single `renewal-tick` cron sweeps rows whose next un-sent window has been
-- reached and dispatches push + email, then advances a watermark so each
-- window fires at most once. The watermark approach (vs one row per reminder)
-- keeps the schema small and makes "which reminders are still pending"
-- a pure function of (expires_on, reminders_sent, today).
--
-- Idempotency: every statement is `if not exists` / `or replace` so
-- `supabase db push` is safe to re-run.
--
-- PII / GDPR Art. 17: renewable_documents carries user_id + document number +
-- expiry — it MUST be added to account-delete USER_DATA_TABLES and
-- dsar-export. See the cron README / notes.
-- =====================================================================

create extension if not exists "uuid-ossp";
create extension if not exists pgcrypto;

-- ── 1. enums ──────────────────────────────────────────────────────────
do $$ begin
  if not exists (select 1 from pg_type where typname = 'renewable_doc_type') then
    create type renewable_doc_type as enum (
      'residence_permit', -- ВНЖ / oleskelulupa / elamisluba
      'passport',
      'id_card',
      'visa',
      'driving_licence',
      'insurance',         -- health / travel / liability
      'work_permit',
      'other'
    );
  end if;
end $$;

-- ── 2. renewable_documents table ──────────────────────────────────────
-- One row per tracked personal document. RLS owner-only.
--
-- reminders_sent: text[] of windows already dispatched, holding a subset of
-- {'90','30','7'}. The cron only sends a window not yet present, so a re-run /
-- overlapping tick never double-notifies. Cheaper and clearer than a separate
-- ledger table for a feature with at most a handful of rows per user.
create table if not exists public.renewable_documents (
    id              uuid primary key default gen_random_uuid(),
    user_id         uuid not null references auth.users(id) on delete cascade,
    doc_type        renewable_doc_type not null default 'other',
    -- Human label shown in the UI ("Estonian residence permit", "EU passport").
    label           text not null,
    -- Optional document number / reference. PII — wiped on account delete.
    doc_number      text,
    -- ISO-3166 alpha-2 issuing jurisdiction (e.g. 'FI', 'EE'). Drives the
    -- "how to renew" guide link the client resolves locally.
    jurisdiction    text,
    -- The expiry date. The single anchor all reminder windows derive from.
    expires_on      date not null,
    -- Windows already dispatched: subset of {'90','30','7'}. Advances forward.
    reminders_sent  text[] not null default '{}',
    -- User can mute a single document without deleting it.
    notifications_enabled boolean not null default true,
    notes           text,
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),
    constraint renewable_documents_label_len
        check (char_length(label) between 1 and 200),
    constraint renewable_documents_number_len
        check (doc_number is null or char_length(doc_number) <= 120),
    constraint renewable_documents_juris_len
        check (jurisdiction is null or char_length(jurisdiction) <= 2)
);

-- Per-user ordered list (the screen query): soonest-expiring first.
create index if not exists renewable_documents_user_idx
    on public.renewable_documents (user_id, expires_on);

-- Cron scan: only rows not muted, ordered by expiry. We can't put the
-- "reminders_sent is incomplete" test in a partial-index predicate cheaply, so
-- the index just narrows to enabled rows ordered by expiry; the cron filters
-- the windows in pure logic.
create index if not exists renewable_documents_cron_idx
    on public.renewable_documents (expires_on)
    where notifications_enabled = true;

-- ── 3. updated_at trigger ─────────────────────────────────────────────
create or replace function public.touch_renewable_documents_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at := now();
    return new;
end;
$$;

drop trigger if exists renewable_documents_updated_at on public.renewable_documents;
create trigger renewable_documents_updated_at
    before update on public.renewable_documents
    for each row execute function public.touch_renewable_documents_updated_at();

-- ── 4. RLS — owner-only ───────────────────────────────────────────────
alter table public.renewable_documents enable row level security;

drop policy if exists "own renewable documents" on public.renewable_documents;
create policy "own renewable documents" on public.renewable_documents
    for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

-- ── 5. RPC: renewable_documents_list ──────────────────────────────────
-- Ordered list for the radar screen. security invoker → RLS confines results
-- to the caller's rows. Soonest-expiring first.
create or replace function public.renewable_documents_list()
returns table (
    id              uuid,
    doc_type        renewable_doc_type,
    label           text,
    doc_number      text,
    jurisdiction    text,
    expires_on      date,
    reminders_sent  text[],
    notifications_enabled boolean,
    notes           text,
    created_at      timestamptz
)
language sql stable security invoker
set search_path = public
as $$
    select
        d.id, d.doc_type, d.label, d.doc_number, d.jurisdiction,
        d.expires_on, d.reminders_sent, d.notifications_enabled,
        d.notes, d.created_at
    from public.renewable_documents d
    where d.user_id = auth.uid()
    order by d.expires_on asc, d.created_at asc;
$$;

grant execute on function public.renewable_documents_list() to authenticated;

-- ── 6. Schedule the daily renewal-tick cron ───────────────────────────
-- Reuses the existing public.invoke_edge_cron(text) RPC (migration
-- 20260528060000), which reads supabase_functions_url + cron_secret from
-- vault.decrypted_secrets and attaches the x-cron-secret header the function's
-- gate requires — the SAME path deadline-radar-tick / followup-tick use. No new
-- external scheduler. Daily at 08:00 UTC: renewal windows are coarse (90/30/7
-- days) so once a day is ample, and a fixed morning slot lands push/email at a
-- reasonable hour for EU users.
--
-- Fail-soft: if the vault entries are not yet populated, invoke_edge_cron logs
-- a NOTICE and no-ops. Wrapped in a guard so the migration still applies on a
-- local stack where pg_cron may be absent. Drop-then-schedule = re-runnable.
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    -- Drop any prior entry so re-running replaces rather than dup-errors.
    perform cron.unschedule(jobid)
      from cron.job where jobname = 'renewal-tick-daily';

    perform cron.schedule(
      'renewal-tick-daily',
      '0 8 * * *',
      $cron$select public.invoke_edge_cron('renewal-tick');$cron$
    );
  else
    raise notice 'pg_cron not installed; skipping renewal-tick schedule';
  end if;
end$$;

-- =====================================================================
-- End of Renewal Radar migration.
-- =====================================================================
