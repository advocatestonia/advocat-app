-- =============================================================================
-- Demand-Letter Generator — Feature #2 (2026-06-17).
-- =============================================================================
--
-- Stores the formal pre-court demand letters (FI maksuvaatimus / EE nõudekiri)
-- that the guided 5-step wizard produces. Each row is one saved letter, owned
-- by the user who generated it. The `demand-letter` edge function (service_role)
-- composes the body and inserts/updates rows here; the client reads its own
-- rows for the "my letters" list and re-export.
--
-- UPL note: the generated body always carries a non-removable disclaimer line
-- ("on behalf of the user, general template, not legal advice"). We never
-- auto-send — `status` starts at 'draft' and only the user can move it to
-- 'sent' after they actually dispatch the letter themselves.
--
-- PII: this table holds user_id + recipient_name + free-text basis (which can
-- contain personal data). It MUST be included in the Art.17 account-delete
-- sweep (USER_DATA_TABLES) — see notes returned to the coordinator.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Table.
-- ---------------------------------------------------------------------------
create table if not exists public.demand_letters (
  id              uuid primary key default gen_random_uuid(),
  -- Owner. Cascade-delete with the user (defence in depth alongside Art.17).
  user_id         uuid not null references auth.users (id) on delete cascade,
  -- Optional link to a case the letter relates to.
  case_id         uuid references public.cases (id) on delete set null,
  -- One of the four supported presets.
  claim_type      text not null check (
                    claim_type in (
                      'deposit_return', 'unpaid_wage',
                      'fine_dispute', 'generic_claim'
                    )
                  ),
  -- ISO-3166 alpha-2 jurisdiction whose norms were cited.
  jurisdiction    text not null check (jurisdiction in ('FI', 'EE')),
  -- Output language of the body.
  lang            text not null check (lang in ('fi', 'et', 'ru', 'en')),
  -- Denormalised recipient name for the list view (full body is in markdown).
  recipient_name  text not null,
  -- Demanded amount as entered (kept as text — formatting is user-controlled).
  amount          text,
  currency        text not null default 'EUR',
  -- Subject line / saved-letter title.
  subject         text not null,
  -- The composed letter body (markdown). Bounded by the edge fn (≤100k).
  body_markdown   text not null,
  -- Lifecycle: 'draft' (default) → 'sent' (user marks after dispatching).
  status          text not null default 'draft'
                    check (status in ('draft', 'sent')),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists idx_demand_letters_user
  on public.demand_letters (user_id, updated_at desc);

create index if not exists idx_demand_letters_case
  on public.demand_letters (case_id)
  where case_id is not null;

-- ---------------------------------------------------------------------------
-- 2. RLS — owner-only. service_role (edge fn) bypasses RLS.
-- ---------------------------------------------------------------------------
alter table public.demand_letters enable row level security;

drop policy if exists demand_letters_owner_all on public.demand_letters;
create policy demand_letters_owner_all
  on public.demand_letters
  for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- 3. updated_at touch trigger — keeps the sort-by-recent index honest.
-- ---------------------------------------------------------------------------
create or replace function public.touch_demand_letters_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_demand_letters_touch on public.demand_letters;
create trigger trg_demand_letters_touch
  before update on public.demand_letters
  for each row
  execute function public.touch_demand_letters_updated_at();
