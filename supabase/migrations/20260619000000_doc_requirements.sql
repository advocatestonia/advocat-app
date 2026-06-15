-- =====================================================================
-- Document-Collection Checklist (Feature #4) — doc_requirement_templates
-- (master set) + doc_collection_progress (per-user check-off + linked file).
-- =====================================================================
-- Problem this solves: before going to Migri / a court / a lawyer, a user
-- does not know WHICH documents and certificates to gather (passport,
-- bank statements, contracts, certificates). The existing checklists
-- feature is a task-step action plan ("what to DO next"); this feature is
-- a materialised list of DOCUMENTS to COLLECT, with collection progress
-- and an optional link to an already-uploaded file.
--
-- Distinct from the checklists feature:
--   * checklist_templates  : ordered ACTIONS keyed by (case_type, juris).
--   * doc_requirement_templates : a flat set of DOCUMENTS keyed by a
--     user-pickable problem_type (residence_permit / tenant_rights /
--     dismissal / inheritance / divorce). Each row says WHAT to collect,
--     WHERE to get it, and WHY it is needed.
--
-- Keyed by a free-text problem_type the user selects in the UI (not a
-- case row), so the screen works even before a case exists — the most
-- common moment a user needs to know "what do I bring?".
--
-- Design (pure RLS + RPC — no LLM here; AI top-up is a separate edge
-- function `doc-requirements` that proposes EXTRA items for non-standard
-- cases and never writes to these tables):
--   * Table `public.doc_requirement_templates` — seeded, public-read
--     reference content keyed by (problem_type, jurisdiction, sort_order).
--   * Table `public.doc_collection_progress` — one row per
--     (user, problem_type, requirement) the user has acted on. `collected`
--     is the checkmark; `document_id` optionally links the uploaded file
--     that satisfies the requirement; `noted_at` audits the last change.
--   * RPC `get_doc_requirements(p_problem_type, p_jurisdiction)` SECURITY
--     DEFINER — returns the matching requirement rows LEFT JOINed with the
--     caller's own progress in a single round-trip.
--   * RPC `toggle_doc_requirement(p_requirement_id, p_problem_type,
--     p_collected, p_document_id)` SECURITY DEFINER — upserts the caller's
--     progress row; verifies (when set) that p_document_id is a document
--     the caller owns, so a user cannot pin someone else's file.
--
-- Legal-safety note: the list of documents is publicly-available,
-- procedural information — NOT advice on the merits. The UI labels the
-- whole panel "basic list — your situation may need more or fewer
-- documents". The AI top-up only ADDS suggestions to the same disclaimer.
--
-- Author: agent (doc-collection task #4) | Date: 2026-06-19
-- Idempotency: every DDL is `if not exists` / `create or replace`; the
-- seed uses `on conflict do nothing`. `supabase db push` safe to re-run.
--
-- Art.17 (account-delete): `doc_collection_progress` carries `user_id` and
-- MUST be added to USER_DATA_TABLES in account-delete/handler.ts
-- (and dsar-export) as ["doc_collection_progress", "user_id"].
-- =====================================================================

create extension if not exists pgcrypto;

-- ── 1. Tables ─────────────────────────────────────────────────────────

-- Master set of required documents. `problem_type` is free text that the
-- UI offers as a fixed list of buttons. `jurisdiction` is 'FI' | 'EE' |
-- '*' (wildcard applies to any jurisdiction).
create table if not exists public.doc_requirement_templates (
    id            uuid primary key default gen_random_uuid(),
    problem_type  text not null,
    jurisdiction  text not null default '*',
    sort_order    int  not null,
    -- WHAT to collect (e.g. "Valid passport").
    title         text not null,
    -- WHERE to get it (e.g. "Your home-country authority / embassy").
    where_to_get  text,
    -- WHY it is needed (e.g. "Proves identity and nationality").
    why_needed    text,
    -- Soft hint that the requirement is optional / situational.
    optional      boolean not null default false,
    created_at    timestamptz not null default now()
);

-- Each (problem_type, jurisdiction, sort_order) is unique so the seed is
-- idempotent and rows render in a stable order.
create unique index if not exists doc_requirement_templates_key_idx
    on public.doc_requirement_templates (problem_type, jurisdiction, sort_order);

create index if not exists doc_requirement_templates_type_idx
    on public.doc_requirement_templates (problem_type, jurisdiction);

-- User progress. One row per (user, problem_type, requirement). Absence of
-- a row means "not collected". `document_id` optionally links the uploaded
-- file from public.documents that satisfies this requirement; it is set
-- null if that document is later deleted.
create table if not exists public.doc_collection_progress (
    id             uuid primary key default gen_random_uuid(),
    user_id        uuid not null references auth.users(id) on delete cascade,
    problem_type   text not null,
    requirement_id uuid not null references public.doc_requirement_templates(id) on delete cascade,
    collected      boolean not null default false,
    document_id    uuid references public.documents(id) on delete set null,
    noted_at       timestamptz not null default now()
);

create unique index if not exists doc_collection_progress_key_idx
    on public.doc_collection_progress (user_id, problem_type, requirement_id);

create index if not exists doc_collection_progress_user_idx
    on public.doc_collection_progress (user_id);

-- ── 2. RLS ────────────────────────────────────────────────────────────

-- Templates: world-readable reference content. No client writes (seed is
-- migration-managed; service role / migrations bypass RLS).
alter table public.doc_requirement_templates enable row level security;
drop policy if exists "doc_requirement_templates_public_read"
    on public.doc_requirement_templates;
create policy "doc_requirement_templates_public_read"
    on public.doc_requirement_templates for select
    to authenticated, anon
    using (true);

-- Progress: strict per-user ownership for every verb.
alter table public.doc_collection_progress enable row level security;
drop policy if exists "doc_collection_progress_owner_select"
    on public.doc_collection_progress;
drop policy if exists "doc_collection_progress_owner_insert"
    on public.doc_collection_progress;
drop policy if exists "doc_collection_progress_owner_update"
    on public.doc_collection_progress;
drop policy if exists "doc_collection_progress_owner_delete"
    on public.doc_collection_progress;

create policy "doc_collection_progress_owner_select"
    on public.doc_collection_progress for select
    to authenticated
    using (auth.uid() = user_id);

create policy "doc_collection_progress_owner_insert"
    on public.doc_collection_progress for insert
    to authenticated
    with check (auth.uid() = user_id);

create policy "doc_collection_progress_owner_update"
    on public.doc_collection_progress for update
    to authenticated
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

create policy "doc_collection_progress_owner_delete"
    on public.doc_collection_progress for delete
    to authenticated
    using (auth.uid() = user_id);

-- ── 3. RPC: get_doc_requirements ──────────────────────────────────────
-- Returns the requirement rows for a (problem_type, jurisdiction), with
-- the caller's progress flag + linked document joined in. Jurisdiction
-- match is exact first, then falls back to the '*' wildcard set when no
-- jurisdiction-specific rows exist. SECURITY DEFINER so it can read the
-- caller's progress regardless of RLS while still scoping to auth.uid().
--
-- Returns a jsonb array of:
--   { requirement_id, sort_order, title, where_to_get, why_needed,
--     optional, collected, document_id }
-- ordered by sort_order. Empty array when no template matches the type.
create or replace function public.get_doc_requirements(
    p_problem_type text,
    p_jurisdiction text default '*'
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
    v_uid          uuid := auth.uid();
    v_jurisdiction text := coalesce(nullif(p_jurisdiction, ''), '*');
    v_result       jsonb;
begin
    if v_uid is null then
        return '[]'::jsonb;
    end if;
    if p_problem_type is null or length(p_problem_type) = 0 then
        return '[]'::jsonb;
    end if;

    -- Prefer jurisdiction-specific rows; fall back to wildcard '*'.
    if not exists (
        select 1 from public.doc_requirement_templates t
         where t.problem_type = p_problem_type
           and t.jurisdiction = v_jurisdiction
    ) then
        v_jurisdiction := '*';
    end if;

    select coalesce(
        jsonb_agg(
            jsonb_build_object(
                'requirement_id', t.id,
                'sort_order', t.sort_order,
                'title', t.title,
                'where_to_get', t.where_to_get,
                'why_needed', t.why_needed,
                'optional', t.optional,
                'collected', coalesce(p.collected, false),
                'document_id', p.document_id
            )
            order by t.sort_order
        ),
        '[]'::jsonb
    )
      into v_result
      from public.doc_requirement_templates t
      left join public.doc_collection_progress p
        on p.requirement_id = t.id
       and p.problem_type = p_problem_type
       and p.user_id = v_uid
     where t.problem_type = p_problem_type
       and t.jurisdiction = v_jurisdiction;

    return v_result;
end;
$$;

revoke all on function public.get_doc_requirements(text, text) from public, anon;
grant execute on function public.get_doc_requirements(text, text) to authenticated;

-- ── 4. RPC: toggle_doc_requirement ────────────────────────────────────
-- Upserts the caller's progress row for one requirement. When
-- p_document_id is non-null it must reference a document the caller owns —
-- guards against pinning someone else's file. Pass p_document_id = null to
-- clear the link. Returns { ok, collected, document_id } or
-- { ok:false, reason }.
create or replace function public.toggle_doc_requirement(
    p_requirement_id uuid,
    p_problem_type   text,
    p_collected      boolean,
    p_document_id    uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
    v_uid       uuid := auth.uid();
    v_exists    boolean;
    v_doc_owned boolean;
begin
    if v_uid is null then
        return jsonb_build_object('ok', false, 'reason', 'unauthenticated');
    end if;
    if p_problem_type is null or length(p_problem_type) = 0 then
        return jsonb_build_object('ok', false, 'reason', 'problem_type_required');
    end if;

    -- Verify the requirement template exists (guards orphan toggles).
    select exists (
        select 1 from public.doc_requirement_templates t
         where t.id = p_requirement_id
    ) into v_exists;
    if not v_exists then
        return jsonb_build_object('ok', false, 'reason', 'requirement_not_found');
    end if;

    -- If a document is being linked, the caller must own it.
    if p_document_id is not null then
        select exists (
            select 1 from public.documents d
             where d.id = p_document_id and d.user_id = v_uid
        ) into v_doc_owned;
        if not v_doc_owned then
            return jsonb_build_object('ok', false, 'reason', 'document_not_owned');
        end if;
    end if;

    insert into public.doc_collection_progress
        (user_id, problem_type, requirement_id, collected, document_id, noted_at)
    values
        (v_uid, p_problem_type, p_requirement_id, p_collected, p_document_id, now())
    on conflict (user_id, problem_type, requirement_id)
    do update set
        collected   = excluded.collected,
        document_id = excluded.document_id,
        noted_at    = now();

    return jsonb_build_object(
        'ok', true,
        'collected', p_collected,
        'document_id', p_document_id
    );
end;
$$;

revoke all on function public.toggle_doc_requirement(uuid, text, boolean, uuid) from public, anon;
grant execute on function public.toggle_doc_requirement(uuid, text, boolean, uuid) to authenticated;

-- ── 5. Seed: doc_requirement_templates ────────────────────────────────
-- Five problem types (residence permit / tenant / dismissal / inheritance
-- / divorce). Content is procedural, publicly-available information — NOT
-- advice on the merits. `on conflict do nothing` keeps the seed idempotent
-- against the unique (problem_type, jurisdiction, sort_order) index.

insert into public.doc_requirement_templates
    (problem_type, jurisdiction, sort_order, title, where_to_get, why_needed, optional)
values
-- ── Residence permit / Migri / PPA — wildcard ────────────────────────
('residence_permit', '*', 1, 'Valid passport',
 'Your home-country authority or embassy.',
 'Proves your identity and nationality — required for every application.', false),
('residence_permit', '*', 2, 'Current residence permit or visa',
 'The card or sticker you already hold, or your latest decision letter.',
 'Shows your current legal status and its expiry date.', false),
('residence_permit', '*', 3, 'The decision letter you are responding to',
 'The letter from Migri (FI) or the PPA (EE), including its appeal instructions.',
 'States the grounds, the appeal route and the deadline you must meet.', false),
('residence_permit', '*', 4, 'Proof of income or means of support',
 'Recent payslips, an employment contract, or bank statements.',
 'Most permit grounds require you to show you can support yourself.', false),
('residence_permit', '*', 5, 'Proof of accommodation',
 'A lease, ownership deed, or a host''s written statement.',
 'Confirms where you live, which several permit types require.', false),
('residence_permit', '*', 6, 'Evidence of family ties',
 'Marriage / birth certificates, or proof of a registered partnership.',
 'Needed when the permit is based on family reunification.', true),
('residence_permit', '*', 7, 'Proof of studies or employment',
 'An admission letter, study certificate, or employer confirmation.',
 'Supports a study- or work-based permit ground.', true),

-- ── Tenant rights / eviction — wildcard ──────────────────────────────
('tenant_rights', '*', 1, 'The rental agreement',
 'Your own copy, or request it from the landlord or agency.',
 'Defines the rent, deposit, notice period and each party''s duties.', false),
('tenant_rights', '*', 2, 'Proof of rent payments',
 'Bank transfers, receipts, or a payment history from your bank.',
 'Disproves any claim of arrears and shows you paid on time.', false),
('tenant_rights', '*', 3, 'The deposit receipt',
 'The landlord or the escrow account where the deposit is held.',
 'Establishes the deposit amount and your claim to its return.', false),
('tenant_rights', '*', 4, 'The notice or claim you received',
 'The eviction notice or landlord letter, in writing.',
 'States the reason and any deadline you must respond to.', false),
('tenant_rights', '*', 5, 'Photos of the dwelling''s condition',
 'Take dated photos of any defects yourself.',
 'Evidence if the dispute over damage or repairs reaches a board or court.', true),
('tenant_rights', '*', 6, 'Written communication with the landlord',
 'Save emails, messages and letters exchanged.',
 'Documents what was agreed, promised or disputed.', true),

-- ── Dismissal / labour dispute — wildcard ────────────────────────────
('dismissal', '*', 1, 'Your employment contract',
 'Your signed copy, or request it from HR / the employer.',
 'Defines your role, pay, notice period and termination terms.', false),
('dismissal', '*', 2, 'The termination notice',
 'Request the dismissal decision in writing from the employer.',
 'States the grounds and date — the basis for any challenge.', false),
('dismissal', '*', 3, 'Recent payslips',
 'Your own records or the employer''s payroll system.',
 'Establish your salary, used to calculate any compensation.', false),
('dismissal', '*', 4, 'Any written warnings or performance records',
 'Your email, HR file, or the employer on request.',
 'Show whether the dismissal followed a fair procedure.', true),
('dismissal', '*', 5, 'Union membership proof',
 'Your trade union or shop steward.',
 'Unlocks free legal help and representation in the dispute.', true),
('dismissal', '*', 6, 'Records of working hours and overtime',
 'Time sheets, rota screenshots, or your own log.',
 'Support unpaid-wage or overtime claims alongside the dismissal.', true),

-- ── Inheritance / estate — wildcard ──────────────────────────────────
('inheritance', '*', 1, 'The death certificate',
 'The civil registry or the authority that issued it.',
 'The starting document for opening any estate or succession.', false),
('inheritance', '*', 2, 'The will, if one exists',
 'The deceased''s papers, a notary, or the will registry.',
 'Determines how the estate is distributed.', false),
('inheritance', '*', 3, 'Proof of your relationship to the deceased',
 'Birth or marriage certificates from the civil registry.',
 'Establishes your status as an heir.', false),
('inheritance', '*', 4, 'List of the estate''s assets and debts',
 'Bank statements, property deeds, and creditor letters.',
 'Needed to value the estate and decide whether to accept it.', false),
('inheritance', '*', 5, 'Property and vehicle ownership documents',
 'Land registry extracts and vehicle registration papers.',
 'Identify the assets that must be transferred to the heirs.', true),
('inheritance', '*', 6, 'The deceased''s ID document',
 'Among the deceased''s papers, if available.',
 'Helps authorities confirm identity during the succession.', true),

-- ── Divorce / separation — wildcard ──────────────────────────────────
('divorce', '*', 1, 'The marriage certificate',
 'The civil registry where the marriage was registered.',
 'Required to start any divorce or dissolution proceeding.', false),
('divorce', '*', 2, 'Identity documents for both spouses',
 'Your passports or national ID cards.',
 'Confirm the identities of the parties to the proceeding.', false),
('divorce', '*', 3, 'Children''s birth certificates',
 'The civil registry.',
 'Needed for custody, residence and child-support arrangements.', true),
('divorce', '*', 4, 'Proof of income for both spouses',
 'Payslips, tax returns, or bank statements.',
 'Used to decide maintenance and the division of expenses.', false),
('divorce', '*', 5, 'List of shared assets and debts',
 'Property deeds, loan agreements, and bank statements.',
 'Basis for dividing matrimonial property.', false),
('divorce', '*', 6, 'Any prenuptial or marital-property agreement',
 'Your own copy or the notary who registered it.',
 'Can override the default rules for dividing property.', true)
on conflict (problem_type, jurisdiction, sort_order) do nothing;
