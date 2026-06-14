-- =============================================================================
-- Legal Template Library — Feature #5 (2026-06-14).
-- =============================================================================
--
-- Goal: give FI/EE users a curated library of fill-in legal forms (kantelu,
-- valitus, vuokra-reklamaatio; kaebus, avaldus, üürinõue …) so the "I can do
-- this myself" barrier drops. Templates carry `{{placeholder}}` tokens that the
-- `template-fill` edge function substitutes with case/profile data; the result
-- is saved as a normal `user_drafts` row and exported via the existing
-- PDF/DOCX pipeline.
--
-- UPL note: these are GENERIC INFORMATIONAL FORMS, not individual legal advice.
-- Every template body opens with a disclaimer line ("Образец / Mall / Malli")
-- and the client app surfaces the standard project disclaimer. The seed rows
-- are flagged `is_sample = true` so the UI can mark them as samples.
--
-- Design:
--   * `legal_templates` is REFERENCE data — readable by everyone (incl. anon),
--     writable by NO client. Only migrations / service_role seed it.
--   * Placeholders use {{snake_case}} tokens. `required_fields` lists the
--     tokens that have no automatic source (user must type them), so the UI
--     can render a "missing fields" form. `auto_fields` documents which tokens
--     the edge fn can fill from case/profile (informational; the fn is the
--     authority).
--   * Idempotent: table create guarded, seed rows upserted on a stable slug.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Table.
-- ---------------------------------------------------------------------------
create table if not exists public.legal_templates (
  id              uuid primary key default gen_random_uuid(),
  -- Stable human-readable identifier, e.g. 'fi_kantelu_poliisi'. Used as the
  -- upsert key so re-running the seed is idempotent.
  slug            text not null unique,
  -- Broad category for gallery grouping: 'complaint', 'appeal', 'application',
  -- 'claim', 'request'.
  category        text not null,
  -- ISO-3166 alpha-2 jurisdiction. Only 'FI' / 'EE' seeded today.
  jurisdiction    text not null check (jurisdiction in ('FI', 'EE')),
  -- BCP-47-ish locale of the body text ('fi', 'et', 'en', 'ru').
  locale          text not null,
  -- Short title shown on the gallery card.
  title           text not null,
  -- One-line description shown under the title.
  description     text not null,
  -- The form body with {{placeholder}} tokens. Markdown.
  body_markdown   text not null,
  -- Tokens the user must supply manually (no automatic data source).
  required_fields jsonb not null default '[]'::jsonb,
  -- Tokens the edge fn fills from case/profile (documentation only).
  auto_fields     jsonb not null default '[]'::jsonb,
  -- True for curated sample forms (UI marks them "образец / mall / malli").
  is_sample       boolean not null default true,
  -- Lower = earlier in the gallery.
  sort_order      integer not null default 100,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz
);

create index if not exists idx_legal_templates_juris_locale
  on public.legal_templates (jurisdiction, locale, sort_order);

create index if not exists idx_legal_templates_category
  on public.legal_templates (category);

-- ---------------------------------------------------------------------------
-- 2. RLS — public read, no client write.
-- ---------------------------------------------------------------------------
alter table public.legal_templates enable row level security;

-- Readable by everyone (authenticated + anon): this is non-sensitive reference
-- content. No user data lives here.
drop policy if exists legal_templates_public_read on public.legal_templates;
create policy legal_templates_public_read
  on public.legal_templates
  for select
  using (true);

-- No INSERT/UPDATE/DELETE policy → all client writes denied. Seeding happens
-- via migration (definer context) / service_role only.
revoke insert, update, delete on public.legal_templates from anon, authenticated;
grant select on public.legal_templates to anon, authenticated;

-- ---------------------------------------------------------------------------
-- 3. Seed — 12 curated sample templates (6 FI + 6 EE).
-- ---------------------------------------------------------------------------
-- Bodies are deliberately generic samples. Placeholders:
--   {{full_name}}     – from profiles.full_name      (auto)
--   {{email}}         – from profiles.email           (auto)
--   {{case_title}}    – from cases.title              (auto)
--   {{case_number}}   – cases.court_case_number       (auto)
--   {{migri_ref}}     – cases.migri_reference_number  (auto)
--   {{today}}         – current date                  (auto)
--   {{recipient}}     – authority/landlord name       (required)
--   {{address}}       – sender postal address         (required)
--   {{subject}}       – matter/subject line           (required)
--   {{description}}   – free-text account of facts     (required)
--   {{demand}}        – what the writer asks for       (required)

insert into public.legal_templates
  (slug, category, jurisdiction, locale, title, description,
   body_markdown, required_fields, auto_fields, is_sample, sort_order)
values
  -- ─── FINLAND ───────────────────────────────────────────────────────────
  (
    'fi_kantelu_poliisi', 'complaint', 'FI', 'fi',
    'Kantelu poliisin toiminnasta',
    'Hallintokantelu viranomaisen menettelystä (malli — ei oikeudellista neuvontaa).',
    E'> **MALLI — ei henkilökohtaista oikeudellista neuvontaa.**\n\n# Kantelu poliisin toiminnasta\n\n**Päiväys:** {{today}}\n\n**Kantelija:** {{full_name}}\n**Osoite:** {{address}}\n**Sähköposti:** {{email}}\n\n**Viranomainen, jota kantelu koskee:** {{recipient}}\n**Asia:** {{subject}}\n**Asianumero / viite:** {{case_number}}\n\n## Kantelun kohde\n\n{{description}}\n\n## Vaatimus\n\n{{demand}}\n\nPyydän viranomaista tutkimaan menettelyn lainmukaisuuden ja ilmoittamaan ratkaisusta minulle kirjallisesti.\n\nKunnioittavasti,\n\n{{full_name}}',
    '["recipient","address","subject","description","demand"]'::jsonb,
    '["full_name","email","case_number","today"]'::jsonb,
    true, 10
  ),
  (
    'fi_valitus_hallinto', 'appeal', 'FI', 'fi',
    'Valitus hallintopäätöksestä',
    'Valitus viranomaisen päätöksestä (malli — yleinen lomake).',
    E'> **MALLI — ei henkilökohtaista oikeudellista neuvontaa.**\n\n# Valitus\n\n**Päiväys:** {{today}}\n\n**Valittaja:** {{full_name}}\n**Osoite:** {{address}}\n**Sähköposti:** {{email}}\n\n**Päätös, johon haetaan muutosta:** {{subject}}\n**Asianumero:** {{case_number}}\n**Migri-viite:** {{migri_ref}}\n\n## Vaatimukset\n\n{{demand}}\n\n## Perustelut\n\n{{description}}\n\nPyydän, että päätös kumotaan tai muutetaan edellä esitetyin perustein.\n\n{{full_name}}',
    '["address","subject","description","demand"]'::jsonb,
    '["full_name","email","case_number","migri_ref","today"]'::jsonb,
    true, 20
  ),
  (
    'fi_vuokra_reklamaatio', 'claim', 'FI', 'fi',
    'Vuokra-asunnon reklamaatio',
    'Reklamaatio vuokranantajalle puutteista (malli).',
    E'> **MALLI — ei henkilökohtaista oikeudellista neuvontaa.**\n\n# Reklamaatio vuokranantajalle\n\n**Päiväys:** {{today}}\n\n**Vuokralainen:** {{full_name}}\n**Osoite:** {{address}}\n**Sähköposti:** {{email}}\n\n**Vuokranantaja:** {{recipient}}\n**Asia:** {{subject}}\n\n## Reklamaation kohde\n\n{{description}}\n\n## Vaatimus\n\n{{demand}}\n\nPyydän vastausta 14 päivän kuluessa tämän kirjeen päiväyksestä.\n\n{{full_name}}',
    '["recipient","address","subject","description","demand"]'::jsonb,
    '["full_name","email","today"]'::jsonb,
    true, 30
  ),
  (
    'fi_oikaisuvaatimus', 'appeal', 'FI', 'fi',
    'Oikaisuvaatimus',
    'Oikaisuvaatimus viranomaisen päätökseen (malli).',
    E'> **MALLI — ei henkilökohtaista oikeudellista neuvontaa.**\n\n# Oikaisuvaatimus\n\n**Päiväys:** {{today}}\n\n**Vaatija:** {{full_name}}\n**Osoite:** {{address}}\n**Sähköposti:** {{email}}\n\n**Päätös:** {{subject}}\n**Asianumero:** {{case_number}}\n\n## Vaatimus\n\n{{demand}}\n\n## Perustelut\n\n{{description}}\n\n{{full_name}}',
    '["address","subject","description","demand"]'::jsonb,
    '["full_name","email","case_number","today"]'::jsonb,
    true, 40
  ),
  (
    'fi_asiakirjapyynto', 'request', 'FI', 'fi',
    'Asiakirjapyyntö (JulkL)',
    'Pyyntö saada viranomaisen asiakirja (julkisuuslaki, malli).',
    E'> **MALLI — ei henkilökohtaista oikeudellista neuvontaa.**\n\n# Asiakirjapyyntö\n\n**Päiväys:** {{today}}\n\n**Pyytäjä:** {{full_name}}\n**Sähköposti:** {{email}}\n\n**Viranomainen:** {{recipient}}\n**Asia:** {{subject}}\n**Asianumero:** {{case_number}}\n\nPyydän julkisuuslain (621/1999) nojalla jäljennöksen seuraavista asiakirjoista:\n\n{{description}}\n\nPyydän toimittamaan asiakirjat sähköpostitse osoitteeseen {{email}} viivytyksettä.\n\n{{full_name}}',
    '["recipient","subject","description"]'::jsonb,
    '["full_name","email","case_number","today"]'::jsonb,
    true, 50
  ),
  (
    'fi_hakemus_migri', 'application', 'FI', 'fi',
    'Hakemus / lisäselvitys Migrille',
    'Vapaamuotoinen hakemus tai lisäselvitys Maahanmuuttovirastolle (malli).',
    E'> **MALLI — ei henkilökohtaista oikeudellista neuvontaa.**\n\n# Hakemus Maahanmuuttovirastolle\n\n**Päiväys:** {{today}}\n\n**Hakija:** {{full_name}}\n**Sähköposti:** {{email}}\n**Migri-viite:** {{migri_ref}}\n\n**Asia:** {{subject}}\n\n## Hakemus\n\n{{description}}\n\n## Vaatimus\n\n{{demand}}\n\n{{full_name}}',
    '["subject","description","demand"]'::jsonb,
    '["full_name","email","migri_ref","today"]'::jsonb,
    true, 60
  ),

  -- ─── ESTONIA ───────────────────────────────────────────────────────────
  (
    'ee_kaebus_haldus', 'complaint', 'EE', 'et',
    'Kaebus ametiasutuse tegevuse peale',
    'Haldusasutuse tegevuse vaidlustamine (näidis — ei ole õigusnõustamine).',
    E'> **NÄIDIS — ei ole isiklik õigusnõustamine.**\n\n# Kaebus\n\n**Kuupäev:** {{today}}\n\n**Kaebaja:** {{full_name}}\n**Aadress:** {{address}}\n**E-post:** {{email}}\n\n**Asutus:** {{recipient}}\n**Asi:** {{subject}}\n**Viitenumber:** {{case_number}}\n\n## Kaebuse sisu\n\n{{description}}\n\n## Nõue\n\n{{demand}}\n\nPalun asutusel kontrollida menetluse õiguspärasust ja teavitada mind otsusest kirjalikult.\n\nLugupidamisega,\n\n{{full_name}}',
    '["recipient","address","subject","description","demand"]'::jsonb,
    '["full_name","email","case_number","today"]'::jsonb,
    true, 10
  ),
  (
    'ee_avaldus_haldus', 'application', 'EE', 'et',
    'Avaldus ametiasutusele',
    'Vabas vormis avaldus haldusasutusele (näidis).',
    E'> **NÄIDIS — ei ole isiklik õigusnõustamine.**\n\n# Avaldus\n\n**Kuupäev:** {{today}}\n\n**Avaldaja:** {{full_name}}\n**Aadress:** {{address}}\n**E-post:** {{email}}\n\n**Adressaat:** {{recipient}}\n**Asi:** {{subject}}\n\n## Avalduse sisu\n\n{{description}}\n\n## Taotlus\n\n{{demand}}\n\n{{full_name}}',
    '["recipient","address","subject","description","demand"]'::jsonb,
    '["full_name","email","today"]'::jsonb,
    true, 20
  ),
  (
    'ee_uurinoue_uurileandja', 'claim', 'EE', 'et',
    'Pretensioon üürileandjale',
    'Pretensioon üüripinna puuduste kohta (näidis).',
    E'> **NÄIDIS — ei ole isiklik õigusnõustamine.**\n\n# Pretensioon üürileandjale\n\n**Kuupäev:** {{today}}\n\n**Üürnik:** {{full_name}}\n**Aadress:** {{address}}\n**E-post:** {{email}}\n\n**Üürileandja:** {{recipient}}\n**Asi:** {{subject}}\n\n## Pretensiooni sisu\n\n{{description}}\n\n## Nõue\n\n{{demand}}\n\nPalun vastata 14 päeva jooksul käesoleva kirja kuupäevast.\n\n{{full_name}}',
    '["recipient","address","subject","description","demand"]'::jsonb,
    '["full_name","email","today"]'::jsonb,
    true, 30
  ),
  (
    'ee_vaie', 'appeal', 'EE', 'et',
    'Vaie haldusakti peale',
    'Vaie haldusorgani otsuse peale (näidis).',
    E'> **NÄIDIS — ei ole isiklik õigusnõustamine.**\n\n# Vaie\n\n**Kuupäev:** {{today}}\n\n**Vaide esitaja:** {{full_name}}\n**Aadress:** {{address}}\n**E-post:** {{email}}\n\n**Vaidlustatav otsus:** {{subject}}\n**Viitenumber:** {{case_number}}\n\n## Nõue\n\n{{demand}}\n\n## Põhjendused\n\n{{description}}\n\n{{full_name}}',
    '["address","subject","description","demand"]'::jsonb,
    '["full_name","email","case_number","today"]'::jsonb,
    true, 40
  ),
  (
    'ee_teabenoue', 'request', 'EE', 'et',
    'Teabenõue (AvTS)',
    'Teabenõue avaliku teabe seaduse alusel (näidis).',
    E'> **NÄIDIS — ei ole isiklik õigusnõustamine.**\n\n# Teabenõue\n\n**Kuupäev:** {{today}}\n\n**Esitaja:** {{full_name}}\n**E-post:** {{email}}\n\n**Asutus:** {{recipient}}\n**Asi:** {{subject}}\n\nPalun avaliku teabe seaduse alusel väljastada koopia järgmistest dokumentidest:\n\n{{description}}\n\nPalun edastada dokumendid e-posti aadressile {{email}}.\n\n{{full_name}}',
    '["recipient","subject","description"]'::jsonb,
    '["full_name","email","today"]'::jsonb,
    true, 50
  ),
  (
    'ee_avaldus_ppa', 'application', 'EE', 'et',
    'Avaldus PPA-le (migratsioon)',
    'Vabas vormis avaldus või lisaselgitus Politsei- ja Piirivalveametile (näidis).',
    E'> **NÄIDIS — ei ole isiklik õigusnõustamine.**\n\n# Avaldus Politsei- ja Piirivalveametile\n\n**Kuupäev:** {{today}}\n\n**Avaldaja:** {{full_name}}\n**E-post:** {{email}}\n**Viitenumber:** {{case_number}}\n\n**Asi:** {{subject}}\n\n## Avalduse sisu\n\n{{description}}\n\n## Taotlus\n\n{{demand}}\n\n{{full_name}}',
    '["subject","description","demand"]'::jsonb,
    '["full_name","email","case_number","today"]'::jsonb,
    true, 60
  )
on conflict (slug) do update set
  category        = excluded.category,
  jurisdiction    = excluded.jurisdiction,
  locale          = excluded.locale,
  title           = excluded.title,
  description     = excluded.description,
  body_markdown   = excluded.body_markdown,
  required_fields = excluded.required_fields,
  auto_fields     = excluded.auto_fields,
  is_sample       = excluded.is_sample,
  sort_order      = excluded.sort_order,
  updated_at      = now();
