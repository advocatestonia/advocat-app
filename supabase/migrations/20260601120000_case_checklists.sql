-- =====================================================================
-- Case-Type Checklists — static "what to do next" roadmaps per case type.
--
-- Problem this solves: a user with a real-world problem (dismissal /
-- eviction / fine / residence permit) does not know the SEQUENCE of
-- actions — which documents to gather, which deadlines apply, where to
-- turn. The AI chat answers once; this feature gives every case a
-- persistent, trackable roadmap with progress.
--
-- Design (pure RLS + RPC — no LLM, no cron, no edge function):
--   * Table `public.checklist_templates` — seeded, ordered steps keyed
--     by (case_type, jurisdiction). Public read-only reference content.
--   * Table `public.checklist_progress` — one row per (user, case, item)
--     the user has acted on. `done` is the checkmark; `noted_at` audits
--     the last toggle.
--   * RPC `get_case_checklist(p_case_id)` SECURITY DEFINER — resolves the
--     case's type+jurisdiction, returns the matching template items LEFT
--     JOINed with the caller's own progress so the UI gets one ordered
--     list with `done` flags in a single round-trip.
--   * RPC `toggle_checklist_item(p_case_id, p_item_id, p_done)` SECURITY
--     DEFINER — upserts the caller's progress row, verifying case
--     ownership first.
--
-- Legal-safety note: seed content is INFORMATIONAL, not legal advice.
-- Deadline figures (e.g. "30 days to appeal") are statutory defaults and
-- the UI labels the whole panel "information, not legal advice".
--
-- Author: agent (case-checklists task) | Date: 2026-06-01
-- Idempotency: every DDL is `if not exists` / `create or replace`; the
-- seed uses `on conflict do nothing`. `supabase db push` safe to re-run.
-- =====================================================================

create extension if not exists pgcrypto;

-- ── 1. Tables ─────────────────────────────────────────────────────────

-- Template steps. `case_type` mirrors the `case_type` enum values stored
-- as text so a single template table can serve both `public.cases`
-- (enum) and `public.user_cases` (free-text case_type). `jurisdiction`
-- is 'FI' | 'EE' | '*' (the wildcard '*' applies to any jurisdiction).
create table if not exists public.checklist_templates (
    id            uuid primary key default gen_random_uuid(),
    case_type     text not null,
    jurisdiction  text not null default '*',
    step_order    int  not null,
    title         text not null,
    description   text,
    -- Optional statutory deadline hint in days (e.g. 30 = "30 days to
    -- appeal"). Rendered as an informational chip, NOT wired to the
    -- deadline-radar — keeps this feature self-contained.
    deadline_days int,
    created_at    timestamptz not null default now()
);

-- Each (case_type, jurisdiction, step_order) is unique so the seed is
-- idempotent and steps render in a stable order.
create unique index if not exists checklist_templates_key_idx
    on public.checklist_templates (case_type, jurisdiction, step_order);

create index if not exists checklist_templates_type_idx
    on public.checklist_templates (case_type, jurisdiction);

-- User progress. One row per (user, case, item). Absence of a row means
-- "not done". We key on (user_id, case_id, item_id) so the same template
-- item tracked across two of the user's cases stays independent.
create table if not exists public.checklist_progress (
    id        uuid primary key default gen_random_uuid(),
    user_id   uuid not null references auth.users(id) on delete cascade,
    case_id   uuid not null,
    item_id   uuid not null references public.checklist_templates(id) on delete cascade,
    done      boolean not null default false,
    noted_at  timestamptz not null default now()
);

create unique index if not exists checklist_progress_key_idx
    on public.checklist_progress (user_id, case_id, item_id);

create index if not exists checklist_progress_case_idx
    on public.checklist_progress (case_id);

-- ── 2. RLS ────────────────────────────────────────────────────────────

-- Templates: world-readable reference content. No client writes (seed is
-- migration-managed; service role / migrations bypass RLS).
alter table public.checklist_templates enable row level security;
drop policy if exists "checklist_templates_public_read"
    on public.checklist_templates;
create policy "checklist_templates_public_read"
    on public.checklist_templates for select
    to authenticated, anon
    using (true);

-- Progress: strict per-user ownership for every verb.
alter table public.checklist_progress enable row level security;
drop policy if exists "checklist_progress_owner_select"
    on public.checklist_progress;
drop policy if exists "checklist_progress_owner_insert"
    on public.checklist_progress;
drop policy if exists "checklist_progress_owner_update"
    on public.checklist_progress;
drop policy if exists "checklist_progress_owner_delete"
    on public.checklist_progress;

create policy "checklist_progress_owner_select"
    on public.checklist_progress for select
    to authenticated
    using (auth.uid() = user_id);

create policy "checklist_progress_owner_insert"
    on public.checklist_progress for insert
    to authenticated
    with check (auth.uid() = user_id);

create policy "checklist_progress_owner_update"
    on public.checklist_progress for update
    to authenticated
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

create policy "checklist_progress_owner_delete"
    on public.checklist_progress for delete
    to authenticated
    using (auth.uid() = user_id);

-- ── 3. RPC: get_case_checklist ────────────────────────────────────────
-- Resolves the case's (case_type, jurisdiction) and returns the matching
-- template items, the caller's progress flag joined in. Jurisdiction
-- match is exact first, then falls back to the '*' wildcard template if
-- no jurisdiction-specific one exists. SECURITY DEFINER so it can read
-- the caller's case row regardless of which case table holds it, while
-- still enforcing ownership via auth.uid().
--
-- Returns a jsonb array of:
--   { item_id, step_order, title, description, deadline_days, done }
-- ordered by step_order. Empty array when no template matches the type.
create or replace function public.get_case_checklist(p_case_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
    v_uid          uuid := auth.uid();
    v_case_type    text;
    v_jurisdiction text;
    v_result       jsonb;
begin
    if v_uid is null then
        return '[]'::jsonb;
    end if;

    -- Resolve the case from whichever table owns it, enforcing ownership.
    -- `public.cases` uses an enum `type` column; cast to text.
    select c.type::text, coalesce(c.nationality, '*')
      into v_case_type, v_jurisdiction
      from public.cases c
     where c.id = p_case_id and c.user_id = v_uid;

    -- Fallback to the case-memory table (user_cases) when not found above.
    if v_case_type is null then
        select uc.case_type, coalesce(uc.jurisdiction, '*')
          into v_case_type, v_jurisdiction
          from public.user_cases uc
         where uc.id = p_case_id and uc.user_id = v_uid;
    end if;

    if v_case_type is null then
        -- Case not found / not owned by caller.
        return '[]'::jsonb;
    end if;

    -- Prefer a jurisdiction-specific template; fall back to wildcard '*'.
    -- We pick the jurisdiction that actually has rows for this case_type.
    if not exists (
        select 1 from public.checklist_templates t
         where t.case_type = v_case_type
           and t.jurisdiction = v_jurisdiction
    ) then
        v_jurisdiction := '*';
    end if;

    select coalesce(
        jsonb_agg(
            jsonb_build_object(
                'item_id', t.id,
                'step_order', t.step_order,
                'title', t.title,
                'description', t.description,
                'deadline_days', t.deadline_days,
                'done', coalesce(p.done, false)
            )
            order by t.step_order
        ),
        '[]'::jsonb
    )
      into v_result
      from public.checklist_templates t
      left join public.checklist_progress p
        on p.item_id = t.id
       and p.case_id = p_case_id
       and p.user_id = v_uid
     where t.case_type = v_case_type
       and t.jurisdiction = v_jurisdiction;

    return v_result;
end;
$$;

revoke all on function public.get_case_checklist(uuid) from public, anon;
grant execute on function public.get_case_checklist(uuid) to authenticated;

-- ── 4. RPC: toggle_checklist_item ─────────────────────────────────────
-- Upserts the caller's progress row for one template item, verifying the
-- caller owns the case. Returns { ok: bool, done: bool } or
-- { ok: false, reason: ... }.
create or replace function public.toggle_checklist_item(
    p_case_id uuid,
    p_item_id uuid,
    p_done    boolean
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
    v_uid    uuid := auth.uid();
    v_owns   boolean;
    v_exists boolean;
begin
    if v_uid is null then
        return jsonb_build_object('ok', false, 'reason', 'unauthenticated');
    end if;

    -- Verify the caller owns the case (either case table).
    select exists (
        select 1 from public.cases c
         where c.id = p_case_id and c.user_id = v_uid
        union all
        select 1 from public.user_cases uc
         where uc.id = p_case_id and uc.user_id = v_uid
    ) into v_owns;

    if not v_owns then
        return jsonb_build_object('ok', false, 'reason', 'case_not_found');
    end if;

    -- Verify the template item exists (guards against orphan toggles).
    select exists (
        select 1 from public.checklist_templates t where t.id = p_item_id
    ) into v_exists;

    if not v_exists then
        return jsonb_build_object('ok', false, 'reason', 'item_not_found');
    end if;

    insert into public.checklist_progress (user_id, case_id, item_id, done, noted_at)
    values (v_uid, p_case_id, p_item_id, p_done, now())
    on conflict (user_id, case_id, item_id)
    do update set done = excluded.done, noted_at = now();

    return jsonb_build_object('ok', true, 'done', p_done);
end;
$$;

revoke all on function public.toggle_checklist_item(uuid, uuid, boolean) from public, anon;
grant execute on function public.toggle_checklist_item(uuid, uuid, boolean) to authenticated;

-- ── 5. Seed: checklist_templates ──────────────────────────────────────
-- 8 roadmaps across the case types most common for B2C users. Steps are
-- ordered; deadline_days carries the statutory clock where one exists.
-- All content is informational. `on conflict do nothing` keeps the seed
-- idempotent against the unique (case_type, jurisdiction, step_order)
-- index.

insert into public.checklist_templates
    (case_type, jurisdiction, step_order, title, description, deadline_days)
values
-- ── Labor dispute / dismissal — Finland ──────────────────────────────
('labor_dispute', 'FI', 1, 'Gather your employment contract',
 'Locate the signed contract, latest payslips and any written warnings. These define your rights and notice period.', null),
('labor_dispute', 'FI', 2, 'Request the dismissal decision in writing',
 'Ask the employer for the grounds for termination in writing. An employee is entitled to a written statement of the reason.', null),
('labor_dispute', 'FI', 3, 'Contact your trade union or shop steward',
 'If you are a union member, your union gives free legal help and can negotiate on your behalf.', null),
('labor_dispute', 'FI', 4, 'Note the claim deadline',
 'Claims for unlawful termination compensation are time-barred — typically within two years of employment ending. Act early.', 730),
('labor_dispute', 'FI', 5, 'File a complaint or claim',
 'Escalate to the Occupational Safety and Health Authority (AVI) or the district court, or seek a settlement.', null),

-- ── Labor dispute / dismissal — Estonia ──────────────────────────────
('labor_dispute', 'EE', 1, 'Gather your employment contract',
 'Collect the contract, pay records and any termination notice. Check the agreed notice period.', null),
('labor_dispute', 'EE', 2, 'Request written grounds for termination',
 'The employer must give the reason for cancellation in a format that can be reproduced in writing.', null),
('labor_dispute', 'EE', 3, 'Challenge within 30 days',
 'A request to declare the cancellation void must be filed with the Labour Dispute Committee or court within 30 calendar days of receiving the notice.', 30),
('labor_dispute', 'EE', 4, 'File with the Labour Dispute Committee',
 'The Töövaidluskomisjon resolves employment disputes free of charge. Submit your application with evidence.', null),

-- ── Tenant rights / eviction — wildcard ──────────────────────────────
('tenant_rights', '*', 1, 'Collect your lease and payment records',
 'Find the rental agreement, proof of rent payments and any deposit receipts.', null),
('tenant_rights', '*', 2, 'Get the notice or claim in writing',
 'Request the eviction notice or landlord claim in writing, including the stated reason and any deadline.', null),
('tenant_rights', '*', 3, 'Document the dwelling condition',
 'Photograph defects and keep written communication. This evidence matters if the dispute reaches a court or board.', null),
('tenant_rights', '*', 4, 'Respond before the deadline',
 'Reply to the landlord or housing authority within the stated period. Missing it can weaken your position.', null),
('tenant_rights', '*', 5, 'Seek tenant advice or legal aid',
 'Contact a tenants'' association or the legal-aid service to review your options before any hearing.', null),

-- ── Fine / debt collection — wildcard ────────────────────────────────
('debt_collection', '*', 1, 'Read the fine or claim carefully',
 'Identify who issued it, the amount, the reason and the payment or appeal deadline.', null),
('debt_collection', '*', 2, 'Check the deadline to object',
 'Most fines and payment orders can be contested within a short window — often 30 days. Note the exact date.', 30),
('debt_collection', '*', 3, 'Gather evidence supporting your objection',
 'Collect receipts, correspondence or any proof the charge is wrong or already paid.', null),
('debt_collection', '*', 4, 'Submit a written objection or appeal',
 'File your objection with the issuing authority in writing and keep proof of submission.', null),
('debt_collection', '*', 5, 'Arrange payment or a payment plan if valid',
 'If the claim is correct, pay on time or request an instalment plan to avoid enforcement and added costs.', null),

-- ── Residence permit / Migri — Finland ───────────────────────────────
('residence_permit', 'FI', 1, 'Gather your identity and status documents',
 'Collect your passport, current permit, and the decision letter you received from Migri.', null),
('residence_permit', 'FI', 2, 'Read the decision and its appeal instructions',
 'The decision states whether and where it can be appealed and the time limit. Read the appended ohjeet carefully.', null),
('residence_permit', 'FI', 3, 'Note the appeal deadline',
 'Appeals to the Administrative Court are generally due within 30 days of receiving the decision.', 30),
('residence_permit', 'FI', 4, 'Collect supporting evidence',
 'Assemble proof of income, family ties, employment or studies relevant to your permit ground.', null),
('residence_permit', 'FI', 5, 'File the appeal or new application',
 'Submit the appeal to the Administrative Court (hallinto-oikeus), or lodge a corrected application with Migri.', null),

-- ── Residence permit — Estonia ───────────────────────────────────────
('residence_permit', 'EE', 1, 'Gather your identity and status documents',
 'Collect your passport, current residence card and the PPA decision letter.', null),
('residence_permit', 'EE', 2, 'Read the decision and appeal instructions',
 'The decision explains the challenge procedure and time limit. Note whether a challenge (vaie) or court appeal applies.', null),
('residence_permit', 'EE', 3, 'Note the appeal deadline',
 'A challenge to the PPA is generally due within 30 days; an administrative-court appeal within 30 days of the decision.', 30),
('residence_permit', 'EE', 4, 'Collect supporting evidence',
 'Assemble proof of income, accommodation, family ties or study/work grounds for your permit.', null),
('residence_permit', 'EE', 5, 'File the challenge or court appeal',
 'Submit a vaie to the PPA or an appeal to the administrative court within the deadline.', null),

-- ── Contract review (generic, wildcard) ──────────────────────────────
('other', '*', 1, 'Collect the full contract and annexes',
 'Make sure you have every page, schedule and signed amendment before reviewing.', null),
('other', '*', 2, 'Identify the key obligations and deadlines',
 'List what each party must do, by when, and the payment and termination terms.', null),
('other', '*', 3, 'Flag risky or unclear clauses',
 'Mark penalties, auto-renewal, liability and jurisdiction clauses for closer review.', null),
('other', '*', 4, 'Run an AI contract review',
 'Use the Contract Review tool to get a clause-by-clause summary and risk flags.', null),
('other', '*', 5, 'Decide and document next steps',
 'Negotiate amendments, sign, or seek a lawyer''s confirmation before committing.', null)
on conflict (case_type, jurisdiction, step_order) do nothing;
