-- ============================================================================
-- EU Corpus 3-feature wave — Deadline Radar EU + Landmark Explorer
-- Date: 2026-05-26
-- Reference: docs/eu_corpus/MASTER_DEPLOY_PLAN_3_FEATURES.md
--            docs/eu_corpus/API_SPEC_3_FEATURES.md
--
-- Adds three net-new tables (all additive, fully idempotent):
--   1. holiday_calendars     — 36 national + supranational calendars (889
--                              holiday entries) for deadline arithmetic.
--   2. deadline_radar_eu     — 122 statute-of-limitations + appeal windows
--                              across 31 EU/EEA/CoE jurisdictions.
--   3. landmark_cases        — 500 curated ECHR + CJEU landmarks (200 + 300).
--
-- Naming rationale
-- ----------------
-- `public.deadlines` already exists in prod with a per-USER schema (case
-- deadlines tied to users). The DRAFT_premium_layers `deadlines` schema
-- would collide. We use `deadline_radar_eu` to keep the existing per-user
-- surface untouched and add the EU corpus knowledge as a sibling table.
--
-- License: holiday/limitation data are public-law facts (no copyright).
-- ECHR/CJEU metadata is public; significance summaries are CC-BY-SA-4.0.
-- ============================================================================

begin;

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- 1. HOLIDAY CALENDARS — 36 calendars, 889 entries
-- ---------------------------------------------------------------------------
-- One row per calendar. Holidays stored as JSONB array (the access pattern
-- is "give me all holidays for FI in 2026" — single-row read, then in-memory
-- filter; we never need cross-calendar joins on individual holidays).
-- weekend_pattern as int[] (ISO weekday numbers, 1=Mon, 7=Sun).
create table if not exists public.holiday_calendars (
  calendar_id        text primary key,
  jurisdiction       text not null,
  name               text not null,
  weekend_pattern    integer[] not null default '{6,7}'::integer[],
  holidays           jsonb not null default '[]'::jsonb,
  source_notes       text,
  generated_at       date,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);

comment on table public.holiday_calendars is
  'EU + EEA + CoE judicial holiday calendars. Seeded from data/seeds/holiday_calendars.json (36 calendars, 889 entries).';
comment on column public.holiday_calendars.holidays is
  'JSONB array of {date, name} entries. ISO-8601 dates. Easter-dependent dates pre-computed per year.';
comment on column public.holiday_calendars.weekend_pattern is
  'ISO weekday integers treated as weekend. Default {6,7} = Sat+Sun.';

create index if not exists holiday_calendars_juris_idx
  on public.holiday_calendars (jurisdiction);

-- ---------------------------------------------------------------------------
-- 2. DEADLINE RADAR EU — 122 limitation periods + appeal windows
-- ---------------------------------------------------------------------------
-- Schema mirrors data/seeds/limitation_periods.json shape:
--   id, jurisdiction (ISO-3166), category, subtype, period (display),
--   period_iso (ISO-8601 duration), from (trigger event description),
--   statute_ref, absolute_cap, interruption_events (jsonb[]),
--   exceptions (jsonb[]).
-- Adds holiday_calendar_id pointer + computation_rule for the radar engine.
create table if not exists public.deadline_radar_eu (
  id                    text primary key,
  jurisdiction          text not null,
  category              text not null,
  subtype               text,
  period                text not null,
  period_iso            text,        -- nullable: criminal prescriptions are tiered (3/5/10/20/30y by penalty) and cannot be expressed as a single ISO duration
  trigger_event         text,
  statute_ref           text not null,
  absolute_cap          text,
  interruption_events   jsonb not null default '[]'::jsonb,
  exceptions            jsonb not null default '[]'::jsonb,
  holiday_calendar_id   text references public.holiday_calendars(calendar_id) on delete set null,
  computation_rule      text check (computation_rule in ('calendar_day','working_day','clear_day')),
  last_verified         date,
  source_notes          text,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);

comment on table public.deadline_radar_eu is
  'Statute-of-limitations + appeal periods across EU/EEA/CoE. Seeded from data/seeds/limitation_periods.json (122 entries, 31 jurisdictions).';
comment on column public.deadline_radar_eu.period_iso is
  'ISO 8601 duration (e.g. P3Y, P6M, P30D). Drives deterministic radar arithmetic.';

create index if not exists deadline_radar_eu_juris_cat_idx
  on public.deadline_radar_eu (jurisdiction, category);

create index if not exists deadline_radar_eu_statute_ref_idx
  on public.deadline_radar_eu (statute_ref);

-- ---------------------------------------------------------------------------
-- 3. LANDMARK CASES — 500 curated ECHR + CJEU
-- ---------------------------------------------------------------------------
-- Merged ECHR + CJEU into one table with `court` discriminator. ECLI is the
-- canonical key; CELEX kept as secondary identifier for CJEU rows.
-- BM25-ready via generated tsvector. No embeddings yet — landmark-search v1
-- ships with keyword + court/area filter only; embedding column reserved
-- for v2 hybrid ranking.
create table if not exists public.landmark_cases (
  id                  uuid primary key default gen_random_uuid(),
  court               text not null check (court in ('CJEU','ECHR','GC','EFTA')),
  ecli                text not null,
  celex               text,
  case_name           text not null,
  case_number         text,
  applicant           text,
  respondent_state    text,
  year                integer,
  decided_at          date,
  area                text[] not null default '{}'::text[],
  articles_violated   text[] not null default '{}'::text[],
  articles_engaged    text[] not null default '{}'::text[],
  protocols           text[] not null default '{}'::text[],
  importance          integer check (importance between 1 and 3),
  importance_level    text check (importance_level in ('landmark','leading','notable','persuasive')),
  significance        text,
  source_url          text,
  embedding           vector(1536),
  search_tsv          tsvector,
  created_at          timestamptz not null default now()
);

comment on table public.landmark_cases is
  'Curated EU/CoE landmark judgments. 300 CJEU + 200 ECHR (data/seeds/cjeu_landmarks.json, echr_landmarks.json).';
comment on column public.landmark_cases.importance is
  '1=Grand Chamber/foundational; 2=Chamber/significant; 3=notable.';

create unique index if not exists landmark_cases_ecli_uq
  on public.landmark_cases (ecli);

create index if not exists landmark_cases_court_year_idx
  on public.landmark_cases (court, year desc);

create index if not exists landmark_cases_area_gin
  on public.landmark_cases using gin (area);

create index if not exists landmark_cases_search_tsv_gin
  on public.landmark_cases using gin (search_tsv);

create index if not exists landmark_cases_celex_idx
  on public.landmark_cases (celex) where celex is not null;

-- ---------------------------------------------------------------------------
-- 4. RLS — public-read; service-role write only
-- ---------------------------------------------------------------------------
alter table public.holiday_calendars  enable row level security;
alter table public.deadline_radar_eu  enable row level security;
alter table public.landmark_cases     enable row level security;

drop policy if exists "holiday_calendars readable by anon" on public.holiday_calendars;
create policy "holiday_calendars readable by anon"
  on public.holiday_calendars for select using (true);

drop policy if exists "deadline_radar_eu readable by anon" on public.deadline_radar_eu;
create policy "deadline_radar_eu readable by anon"
  on public.deadline_radar_eu for select using (true);

drop policy if exists "landmark_cases readable by anon" on public.landmark_cases;
create policy "landmark_cases readable by anon"
  on public.landmark_cases for select using (true);

-- ---------------------------------------------------------------------------
-- 5. updated_at trigger (generic) — keep created_at immutable, updated_at fresh
-- ---------------------------------------------------------------------------
create or replace function public.tg_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists holiday_calendars_set_updated_at on public.holiday_calendars;
create trigger holiday_calendars_set_updated_at
  before update on public.holiday_calendars
  for each row execute function public.tg_set_updated_at();

drop trigger if exists deadline_radar_eu_set_updated_at on public.deadline_radar_eu;
create trigger deadline_radar_eu_set_updated_at
  before update on public.deadline_radar_eu
  for each row execute function public.tg_set_updated_at();

-- ---------------------------------------------------------------------------
-- 6. landmark_cases search_tsv maintained by trigger (generation expressions
--    must be IMMUTABLE; trigger is the equivalent + lets us use array_to_string)
-- ---------------------------------------------------------------------------
create or replace function public.tg_landmark_cases_tsv()
returns trigger
language plpgsql
as $$
begin
  new.search_tsv :=
    setweight(to_tsvector('simple', coalesce(new.case_name, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(new.case_number, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(new.ecli, '')), 'B') ||
    setweight(to_tsvector('simple', coalesce(new.significance, '')), 'C') ||
    setweight(to_tsvector('simple', coalesce(array_to_string(new.area, ' '), '')), 'B');
  return new;
end;
$$;

drop trigger if exists landmark_cases_set_tsv on public.landmark_cases;
create trigger landmark_cases_set_tsv
  before insert or update on public.landmark_cases
  for each row execute function public.tg_landmark_cases_tsv();

-- ---------------------------------------------------------------------------
-- 7. PostgREST schema cache reload
-- ---------------------------------------------------------------------------
notify pgrst, 'reload schema';

commit;
