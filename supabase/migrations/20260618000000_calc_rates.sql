-- =============================================================================
-- Legal Calculators Hub — versioned rates table (Feature #3, 2026-06-18).
-- =============================================================================
--
-- Goal: the Legal Calculators Hub (severance / limitation-period / state-fee /
-- child-support) needs *versionable* numeric inputs — state fees (riigilõiv /
-- oikeudenkäyntimaksu), statutory limitation periods, severance coefficients,
-- and child-support reference floors. These values change by law amendment, so
-- they must NOT be hard-coded only in the Flutter binary. They live here and
-- are served by the `calc-rates` edge function with an offline fallback baked
-- into the app for resilience.
--
-- UPL / accuracy note: these are PUBLISHED STATUTORY REFERENCE VALUES, not
-- individual advice. Each row carries `source_label` + `source_url` + an
-- `effective_from` date so the UI can show "rates as of <date>" and an
-- "indicative, not an official calculation" banner. Child-support especially is
-- highly fact-dependent (UL §59-§61 / EE PKS §101) — the app surfaces it as an
-- orientation floor only.
--
-- Design:
--   * `calc_rates` is REFERENCE data — readable by everyone (incl. anon),
--     writable by NO client. Only migrations / service_role seed it.
--   * No `user_id` column → NO Art.17 (account-delete) coverage needed. This
--     table holds zero personal data.
--   * One row = one (jurisdiction, rate_key, effective_from) version. The edge
--     fn selects the latest row with effective_from <= today per key.
--   * `value_numeric` for scalar rates; `payload` jsonb for tiered/bracketed
--     structures (e.g. state-fee brackets, limitation-period catalogue).
--   * Idempotent: table create guarded, seed rows upserted on the natural key.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Table.
-- ---------------------------------------------------------------------------
create table if not exists public.calc_rates (
  id              uuid primary key default gen_random_uuid(),
  -- ISO-3166 alpha-2 jurisdiction. 'FI' / 'EE' seeded today; 'EU' reserved.
  jurisdiction    text not null check (jurisdiction in ('FI', 'EE', 'EU')),
  -- Which calculator + datum this row feeds. Stable snake_case key, e.g.
  -- 'state_fee_brackets', 'limitation_periods', 'severance_coefficients',
  -- 'child_support_floor'.
  rate_key        text not null,
  -- Scalar value when the datum is a single number (e.g. a floor amount).
  value_numeric   numeric,
  -- Structured value when the datum is tiered/bracketed/catalogued.
  payload         jsonb not null default '{}'::jsonb,
  -- ISO currency where monetary. Null for non-monetary (e.g. day counts).
  currency        text,
  -- Date this version takes legal effect. Latest <= today wins.
  effective_from  date not null,
  -- Human-readable citation shown in the UI ("TLS §100", "OK 1734 ...").
  source_label    text not null default '',
  -- Canonical source URL (riigiteataja / finlex).
  source_url      text not null default '',
  created_at      timestamptz not null default now(),
  updated_at      timestamptz
);

create unique index if not exists calc_rates_natural_key
  on public.calc_rates (jurisdiction, rate_key, effective_from);

create index if not exists calc_rates_lookup
  on public.calc_rates (jurisdiction, rate_key, effective_from desc);

-- ---------------------------------------------------------------------------
-- 2. RLS — public read, no client write.
-- ---------------------------------------------------------------------------
alter table public.calc_rates enable row level security;

drop policy if exists calc_rates_public_read on public.calc_rates;
create policy calc_rates_public_read
  on public.calc_rates
  for select
  using (true);

-- No INSERT/UPDATE/DELETE policy → all client writes denied. Seeding happens
-- via migration (definer context) / service_role only.
revoke insert, update, delete on public.calc_rates from anon, authenticated;
grant select on public.calc_rates to anon, authenticated;

-- ---------------------------------------------------------------------------
-- 3. Seed — current FI + EE reference rates (effective 2026-01-01).
-- ---------------------------------------------------------------------------
-- NOTE: figures are indicative published statutory references. The app labels
-- them "rates as of <effective_from>" and disclaims official calculation.

insert into public.calc_rates
  (jurisdiction, rate_key, value_numeric, payload, currency, effective_from,
   source_label, source_url)
values
  -- ---- Finland: court application fees (tuomioistuinmaksut) -------------
  ('FI', 'state_fee_brackets', null,
   jsonb_build_object(
     'unit', 'EUR',
     'brackets', jsonb_build_array(
       jsonb_build_object('label', 'Käräjäoikeus (laaja riita-asia)', 'fee', 530),
       jsonb_build_object('label', 'Käräjäoikeus (suppea/summaarinen)', 'fee', 110),
       jsonb_build_object('label', 'Hovioikeus (valitus)', 'fee', 540),
       jsonb_build_object('label', 'Korkein oikeus (valitus)', 'fee', 560),
       jsonb_build_object('label', 'Hallinto-oikeus', 'fee', 270),
       jsonb_build_object('label', 'Korkein hallinto-oikeus (KHO)', 'fee', 540)
     )
   ),
   'EUR', date '2026-01-01',
   'Tuomioistuinmaksulaki 1455/2015',
   'https://www.finlex.fi/fi/laki/ajantasa/2015/20151455'),

  -- ---- Finland: limitation / appeal periods ----------------------------
  ('FI', 'limitation_periods', null,
   jsonb_build_object(
     'periods', jsonb_build_array(
       jsonb_build_object('key', 'general_debt', 'label', 'Yleinen velan vanhentuminen', 'days', null, 'years', 3, 'norm', 'Laki velan vanhentumisesta 728/2003 §4'),
       jsonb_build_object('key', 'damages', 'label', 'Vahingonkorvaus', 'days', null, 'years', 3, 'norm', 'VanhL 728/2003 §7'),
       jsonb_build_object('key', 'civil_appeal', 'label', 'Valitus käräjäoikeudesta hovioikeuteen', 'days', 30, 'years', null, 'norm', 'OK 1734 25:5'),
       jsonb_build_object('key', 'admin_appeal', 'label', 'Valitus hallintopäätöksestä', 'days', 30, 'years', null, 'norm', 'OikeudenkäyntiHL 808/2019 §13'),
       jsonb_build_object('key', 'echr', 'label', 'Valitus Euroopan ihmisoikeustuomioistuimeen', 'days', null, 'years', null, 'months', 4, 'norm', 'ECHR Art. 35 (4kk)')
     )
   ),
   null, date '2026-01-01',
   'Laki velan vanhentumisesta 728/2003; OK 1734',
   'https://www.finlex.fi/fi/laki/ajantasa/2003/20030728'),

  -- ---- Finland: severance / notice (irtisanomisaika) -------------------
  ('FI', 'severance_coefficients', null,
   jsonb_build_object(
     'kind', 'notice_months_by_tenure',
     'note', 'Työsopimuslaki 55/2001 6:3 — irtisanomisaika työnantajan irtisanoessa.',
     'tiers', jsonb_build_array(
       jsonb_build_object('max_years', 1, 'notice_months', 0.5),
       jsonb_build_object('max_years', 4, 'notice_months', 1),
       jsonb_build_object('max_years', 8, 'notice_months', 2),
       jsonb_build_object('max_years', 12, 'notice_months', 4),
       jsonb_build_object('max_years', 999, 'notice_months', 6)
     )
   ),
   null, date '2026-01-01',
   'Työsopimuslaki 55/2001 6:3',
   'https://www.finlex.fi/fi/laki/ajantasa/2001/20010055'),

  -- ---- Finland: child support reference floor --------------------------
  ('FI', 'child_support_floor', 195.31,
   jsonb_build_object(
     'note', 'Ohjeellinen elatusapu — todellinen määrä lasketaan lapsen tarpeen ja vanhempien maksukyvyn mukaan (Laki lapsen elatuksesta 704/1975).',
     'percent_of_net_per_child', 17
   ),
   'EUR', date '2026-01-01',
   'Laki lapsen elatuksesta 704/1975; oikeusministeriön ohje',
   'https://www.finlex.fi/fi/laki/ajantasa/1975/19750704'),

  -- ---- Estonia: state fees (riigilõiv) ---------------------------------
  ('EE', 'state_fee_brackets', null,
   jsonb_build_object(
     'unit', 'EUR',
     'note', 'Riigilõivuseadus — hagi riigilõiv sõltub hinnast; allpool orienteeruvad astmed.',
     'brackets', jsonb_build_array(
       jsonb_build_object('label', 'Hagi kuni 350 €', 'fee', 75),
       jsonb_build_object('label', 'Hagi 350–500 €', 'fee', 100),
       jsonb_build_object('label', 'Hagi 500–1000 €', 'fee', 125),
       jsonb_build_object('label', 'Hagi 1000–2000 €', 'fee', 200),
       jsonb_build_object('label', 'Hagi 2000–5000 €', 'fee', 300),
       jsonb_build_object('label', 'Apellatsioonkaebus', 'fee', 300),
       jsonb_build_object('label', 'Kassatsioonkaebus (Riigikohus)', 'fee', 350)
     )
   ),
   'EUR', date '2026-01-01',
   'Riigilõivuseadus',
   'https://www.riigiteataja.ee/akt/RLS'),

  -- ---- Estonia: limitation / appeal periods ----------------------------
  ('EE', 'limitation_periods', null,
   jsonb_build_object(
     'periods', jsonb_build_array(
       jsonb_build_object('key', 'general_claim', 'label', 'Tehingust tuleneva nõude aegumine', 'days', null, 'years', 3, 'norm', 'TsÜS §146 lg 1'),
       jsonb_build_object('key', 'property', 'label', 'Asjaõiguslik nõue', 'days', null, 'years', 10, 'norm', 'TsÜS §146 lg 4'),
       jsonb_build_object('key', 'damages', 'label', 'Kahju hüvitamise nõue', 'days', null, 'years', 3, 'norm', 'TsÜS §150'),
       jsonb_build_object('key', 'civil_appeal', 'label', 'Apellatsioonkaebus maakohtu otsusele', 'days', 30, 'years', null, 'norm', 'TsMS §632 lg 1'),
       jsonb_build_object('key', 'admin_appeal', 'label', 'Kaebus haldusakti peale', 'days', 30, 'years', null, 'norm', 'HKMS §46'),
       jsonb_build_object('key', 'echr', 'label', 'Kaebus Euroopa Inimõiguste Kohtusse', 'days', null, 'years', null, 'months', 4, 'norm', 'EIÕK art 35 (4 kuud)')
     )
   ),
   null, date '2026-01-01',
   'TsÜS; TsMS; HKMS',
   'https://www.riigiteataja.ee/akt/TSYS'),

  -- ---- Estonia: severance / notice (koondamine) ------------------------
  ('EE', 'severance_coefficients', null,
   jsonb_build_object(
     'kind', 'koondamine',
     'note', 'TLS §100 — koondamishüvitis (tööandja) + Töötukassa hüvitis tööstaaži alusel.',
     'employer_months', 1,
     'fund_tiers', jsonb_build_array(
       jsonb_build_object('min_years', 5, 'max_years', 10, 'fund_months', 1),
       jsonb_build_object('min_years', 10, 'max_years', 999, 'fund_months', 2)
     ),
     'notice_tiers', jsonb_build_array(
       jsonb_build_object('max_years', 1, 'notice_days', 15),
       jsonb_build_object('max_years', 5, 'notice_days', 30),
       jsonb_build_object('max_years', 10, 'notice_days', 60),
       jsonb_build_object('max_years', 999, 'notice_days', 90)
     )
   ),
   null, date '2026-01-01',
   'Töölepingu seadus §100, §97',
   'https://www.riigiteataja.ee/akt/TLS'),

  -- ---- Estonia: child support reference floor --------------------------
  ('EE', 'child_support_floor', 209.20,
   jsonb_build_object(
     'note', 'Orienteeruv miinimumelatis — tegelik summa sõltub lapse vajadusest ja vanemate maksevõimest (PKS §101).',
     'percent_of_net_per_child', 17
   ),
   'EUR', date '2026-01-01',
   'Perekonnaseadus §101; elatise miinimum',
   'https://www.riigiteataja.ee/akt/PKS')
on conflict (jurisdiction, rate_key, effective_from) do update set
  value_numeric = excluded.value_numeric,
  payload       = excluded.payload,
  currency      = excluded.currency,
  source_label  = excluded.source_label,
  source_url    = excluded.source_url,
  updated_at    = now();
