-- =====================================================================
-- Phase 2 Pkg 5 — Conversation State Machine
-- (handoff `data/handoff_phase2_advanced.md` — «где мы в кейсе»)
--
-- Adds three columns to `public.user_cases`:
--   * phase            text not null default 'intake'
--   * phase_entered_at timestamptz not null
--   * phase_metadata   jsonb not null default '{}'::jsonb
--
-- Plus the helper RPC `set_case_phase(p_case_id, p_phase, p_metadata)`
-- that the Flutter service and `case-auto-patch` edge function call to
-- transition state idempotently.
--
-- Backwards compat: existing rows backfill to:
--   * 'strategy' if `case_numbers` is non-empty (already past intake),
--   * 'intake'   otherwise.
--
-- Migration filename slot _15: parallel agent took _14
-- (`20260507_14_email_user_settings.sql` shipped same day). Per
-- `lesson_migration_alphabetical_order.md`, the `_NN_` prefix enforces
-- topological dep order when multiple migrations land on the same day.
-- No dep on email_user_settings — bumping to _15 keeps slots unique.
--
-- Idempotency: `add column if not exists`, `create or replace function`,
-- defensive constraint creation. `supabase db push` is safe to re-run.
-- =====================================================================

-- ── 1. Columns ────────────────────────────────────────────────────────
alter table public.user_cases
    add column if not exists phase            text,
    add column if not exists phase_entered_at timestamptz,
    add column if not exists phase_metadata   jsonb;

-- ── 2. One-shot backfill for existing rows ────────────────────────────
-- Keep the WHERE phase IS NULL guard so re-running the migration after
-- normal traffic does not stomp live phase transitions.
update public.user_cases
   set phase            = case
                            when jsonb_array_length(case_numbers) > 0
                                 then 'strategy'
                            else 'intake'
                          end,
       phase_entered_at = coalesce(phase_entered_at, created_at, now()),
       phase_metadata   = coalesce(phase_metadata, '{}'::jsonb)
 where phase is null;

-- ── 3. Pin defaults + NOT NULL + CHECK ────────────────────────────────
alter table public.user_cases
    alter column phase set default 'intake',
    alter column phase set not null,
    alter column phase_entered_at set default now(),
    alter column phase_entered_at set not null,
    alter column phase_metadata set default '{}'::jsonb,
    alter column phase_metadata set not null;

-- CHECK constraint — pinned by `test/migrations/case_phase_migration_test.dart`.
-- Five legal phase values: intake, strategy, draft, wait, closed.
do $$
begin
    if not exists (
        select 1 from pg_constraint
         where conname = 'user_cases_phase_chk'
           and conrelid = 'public.user_cases'::regclass
    ) then
        alter table public.user_cases
            add constraint user_cases_phase_chk
            check (phase in ('intake','strategy','draft','wait','closed'));
    end if;
end $$;

-- ── 4. Index for phase-filtered queries on active cases ───────────────
create index if not exists user_cases_phase_idx
    on public.user_cases (user_id, phase)
    where status = 'active';

-- =====================================================================
-- Helper RPC: set_case_phase(p_case_id, p_phase, p_metadata)
-- Idempotent state transition. Returns:
--   { changed: false, reason: 'case_not_found' }   — RLS or missing
--   { changed: false, reason: 'noop', phase: <X> } — already at p_phase
--   { changed: true,  from: <X>, to: <Y>,
--     phase_entered_at: <ts> }                     — transition applied
--
-- Security: invoker → RLS applies. The user can only transition cases
-- they own. The `case-auto-patch` edge function calls this AS THE USER
-- (RLS-bound) so we never need a service-role bypass for state changes.
-- =====================================================================
create or replace function public.set_case_phase(
    p_case_id  uuid,
    p_phase    text,
    p_metadata jsonb default '{}'::jsonb
) returns jsonb
language plpgsql
security invoker
as $$
declare
    v_current text;
    v_now     timestamptz := now();
begin
    if p_phase is null
       or p_phase not in ('intake','strategy','draft','wait','closed') then
        raise exception 'invalid phase: %', p_phase;
    end if;

    select phase into v_current
      from public.user_cases
     where id = p_case_id;

    if v_current is null then
        return jsonb_build_object(
            'changed', false,
            'reason',  'case_not_found'
        );
    end if;

    if v_current = p_phase then
        return jsonb_build_object(
            'changed', false,
            'reason',  'noop',
            'phase',   v_current
        );
    end if;

    update public.user_cases
       set phase            = p_phase,
           phase_entered_at = v_now,
           phase_metadata   = coalesce(p_metadata, '{}'::jsonb)
     where id = p_case_id;

    return jsonb_build_object(
        'changed',           true,
        'from',              v_current,
        'to',                p_phase,
        'phase_entered_at',  v_now
    );
end;
$$;

-- PGRST schema cache reload
notify pgrst, 'reload schema';
