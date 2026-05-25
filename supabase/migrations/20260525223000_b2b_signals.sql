-- ============================================================================
-- B2B silent lead detection — signal collection, scoring and modal trigger.
-- Date: 2026-05-25
--
-- Background
-- ----------
-- We want to surface a "Talk to Sales" modal to potential law-firm buyers
-- WITHOUT pre-questionnaires. Behavioural signals get collected silently
-- (server-side) and a per-user score is recomputed on every signal. When the
-- 30-day rolling score crosses the 100-point threshold for the first time we
-- flip `profiles.b2b_modal_pending = true` and the Flutter client picks the
-- flag up on its next session check and renders the modal.
--
-- This migration is ADDITIVE and IDEMPOTENT — it is safe to re-run.
--
-- Out of scope
-- ------------
-- The organisation stack (`public.organizations`, `create-organization` edge
-- fn, lib/features/organization/) is a parallel workstream that has its own
-- migrations under 20260523*. This file deliberately does NOT touch that
-- surface — it is a narrow detection layer that lives on `profiles`.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. profiles columns — scoring state + modal flag + email domain
-- ---------------------------------------------------------------------------
-- We add four columns:
--   * b2b_score          int     — 30-day rolling score (recomputed on every
--                                  record_b2b_signal call; kept in sync via
--                                  the RPC, never set directly).
--   * b2b_modal_pending  boolean — Flutter polls this. Flips to TRUE when
--                                  the score crosses 100 AND we have not
--                                  shown the modal before. Flutter sets it
--                                  back to FALSE once the modal is displayed
--                                  / dismissed.
--   * b2b_modal_shown_at timestamptz — set by Flutter when the modal is
--                                  acknowledged. Prevents repeated triggers.
--   * email_domain       text    — split_part(email, '@', 2). Used by the
--                                  signup hook for `law_firm_email_domain`
--                                  classification without re-parsing email
--                                  in app code. Plain text column (not a
--                                  generated column) because profiles.email
--                                  is mutable via OAuth catch-up and we want
--                                  the trigger to keep it in sync rather
--                                  than depend on Postgres' strict
--                                  STORED-generated immutability semantics
--                                  across the existing schema.

alter table public.profiles
  add column if not exists b2b_score          integer not null default 0;

alter table public.profiles
  add column if not exists b2b_modal_pending  boolean not null default false;

alter table public.profiles
  add column if not exists b2b_modal_shown_at timestamptz;

alter table public.profiles
  add column if not exists email_domain       text;

-- Backfill email_domain for existing rows; cheap because the table is small
-- and the column is null on every existing row.
update public.profiles
   set email_domain = lower(split_part(email, '@', 2))
 where email is not null
   and email_domain is null;

-- Keep email_domain in sync with email on every insert/update.
create or replace function public.profiles_sync_email_domain()
returns trigger
language plpgsql
as $$
begin
  if new.email is not null then
    new.email_domain := lower(split_part(new.email, '@', 2));
  else
    new.email_domain := null;
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_email_domain_sync on public.profiles;
create trigger profiles_email_domain_sync
  before insert or update of email on public.profiles
  for each row execute function public.profiles_sync_email_domain();

create index if not exists idx_profiles_b2b_modal_pending
  on public.profiles (b2b_modal_pending)
  where b2b_modal_pending = true;

create index if not exists idx_profiles_email_domain
  on public.profiles (email_domain)
  where email_domain is not null;

-- ---------------------------------------------------------------------------
-- 2. b2b_signals table — append-only log of every observed signal
-- ---------------------------------------------------------------------------
create table if not exists public.b2b_signals (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  signal_type  text not null,
  score        integer not null default 0,
  payload      jsonb,
  occurred_at  timestamptz not null default now()
);

-- Defensive: harden columns in case the table already existed from an
-- earlier partial migration (idempotent ALTER ... ADD IF NOT EXISTS).
alter table public.b2b_signals
  add column if not exists payload jsonb;

create index if not exists idx_b2b_signals_user_occurred
  on public.b2b_signals (user_id, occurred_at desc);

create index if not exists idx_b2b_signals_type_user_occurred
  on public.b2b_signals (signal_type, user_id, occurred_at desc);

-- Score cap — refuse insane values that would skew the rolling sum.
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'b2b_signals_score_range_chk'
  ) then
    alter table public.b2b_signals
      add constraint b2b_signals_score_range_chk check (score between 0 and 1000);
  end if;
end$$;

-- ---------------------------------------------------------------------------
-- 3. RLS — user reads own signals, only service_role writes
-- ---------------------------------------------------------------------------
alter table public.b2b_signals enable row level security;

drop policy if exists b2b_signals_select_own on public.b2b_signals;
create policy b2b_signals_select_own
  on public.b2b_signals
  for select
  using (auth.uid() = user_id);

-- No insert/update/delete policies => only service_role bypasses RLS.
-- The b2b-signal edge fn uses the service-role client and the RPC
-- record_b2b_signal is SECURITY DEFINER, so neither path needs an
-- explicit policy.

-- ---------------------------------------------------------------------------
-- 4. compute_b2b_score(uuid) — 30-day sum
-- ---------------------------------------------------------------------------
create or replace function public.compute_b2b_score(p_user_id uuid)
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(sum(score), 0)::integer
    from public.b2b_signals
   where user_id = p_user_id
     and occurred_at > now() - interval '30 days';
$$;

revoke all on function public.compute_b2b_score(uuid) from public;
grant execute on function public.compute_b2b_score(uuid) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 5. record_b2b_signal — write a signal + recompute score + flip the flag
-- ---------------------------------------------------------------------------
-- SECURITY DEFINER so the edge fn can call it via the service role and the
-- function bypasses RLS for the INSERT. The function:
--   1. Inserts the signal row.
--   2. Recomputes the 30-day rolling score for the user.
--   3. Updates public.profiles.b2b_score.
--   4. If the new score is >= 100 AND b2b_modal_shown_at is NULL, flips
--      b2b_modal_pending to true. (If the modal has already been shown we
--      never flip again — owner can clear shown_at to re-arm a single user.)
-- The function is intentionally tolerant: missing profile row is treated
-- as "nothing to update" — the signal is still recorded so we don't lose
-- the data even for partially-provisioned users.
create or replace function public.record_b2b_signal(
  p_user_id     uuid,
  p_signal_type text,
  p_score       integer,
  p_payload     jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_new_score integer;
  v_score     integer := coalesce(p_score, 0);
begin
  if p_user_id is null or p_signal_type is null or length(p_signal_type) = 0 then
    raise exception 'record_b2b_signal: user_id and signal_type are required';
  end if;

  -- Clamp score to the table check-constraint range.
  if v_score < 0 then
    v_score := 0;
  elsif v_score > 1000 then
    v_score := 1000;
  end if;

  insert into public.b2b_signals (user_id, signal_type, score, payload)
  values (p_user_id, p_signal_type, v_score, p_payload);

  -- Recompute 30-day rolling sum.
  v_new_score := public.compute_b2b_score(p_user_id);

  update public.profiles
     set b2b_score = v_new_score,
         b2b_modal_pending = case
           when v_new_score >= 100 and b2b_modal_shown_at is null then true
           else b2b_modal_pending
         end,
         updated_at = now()
   where id = p_user_id;
end;
$$;

revoke all on function public.record_b2b_signal(uuid, text, integer, jsonb) from public;
grant execute on function public.record_b2b_signal(uuid, text, integer, jsonb) to service_role;

-- ---------------------------------------------------------------------------
-- 6. Documentation comments — drive ops self-service.
-- ---------------------------------------------------------------------------
comment on table  public.b2b_signals is
  'Append-only B2B behavioural signal log. Read-own via RLS; writes via record_b2b_signal SECURITY DEFINER RPC.';

comment on column public.profiles.b2b_score is
  '30-day rolling B2B lead score. Maintained by record_b2b_signal — do not set directly.';

comment on column public.profiles.b2b_modal_pending is
  'When TRUE, Flutter should surface the B2B / law-firm modal. Cleared by client on dismissal.';

comment on column public.profiles.b2b_modal_shown_at is
  'Set by Flutter when the B2B modal has been shown. Suppresses re-trigger by record_b2b_signal.';

comment on column public.profiles.email_domain is
  'Lower-cased everything-after-the-@ of profiles.email, kept in sync by profiles_email_domain_sync trigger.';
