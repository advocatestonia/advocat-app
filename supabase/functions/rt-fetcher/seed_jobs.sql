-- =============================================================================
-- rt-fetcher — Phase 2 Pkg 1 seed
--
-- 25 priority EE statutes → law_chunks_v2 (fetched + chunked by rt-fetcher).
--
-- Idempotent: UNIQUE(source, source_id, target_table) → re-running is a no-op
-- via ON CONFLICT DO NOTHING.
--
-- source_id is the RT abbreviation (e.g. "TsÜS", "KarS") — at runtime
-- rt-fetcher hits https://www.riigiteataja.ee/akt/{abbreviation} and
-- scrapes the canonical global_id from the response HTML. This keeps the
-- seed list short and human-readable (no opaque numeric global_ids to
-- maintain — RT republishes those whenever an act is amended).
--
-- Two abbreviations from the original 24-act task spec did NOT exist as
-- direct redirects on RT:
--   • PankS  → does not redirect. Correct: "PankrS" (Pankrotiseadus).
--   • PerekS → does not redirect. Correct: "PKS"   (Perekonnaseadus).
-- These have been replaced with the working forms below.
--
-- Plus the spec already substituted RaRS → RiKS (Riigikaitseseadus), making
-- this a true 25-act seed.
-- =============================================================================

INSERT INTO ingest_jobs (source, source_id, target_table, payload, priority) VALUES
  ('rt', 'PS',     'law_chunks_v2', '{"act_slug":"ee-ps","act_name":"Eesti Vabariigi põhiseadus","lang":"et"}'::jsonb,    1),
  ('rt', 'KarS',   'law_chunks_v2', '{"act_slug":"ee-kars","act_name":"Karistusseadustik","lang":"et"}'::jsonb,            1),
  ('rt', 'KrMS',   'law_chunks_v2', '{"act_slug":"ee-krms","act_name":"Kriminaalmenetluse seadustik","lang":"et"}'::jsonb, 1),
  ('rt', 'TsMS',   'law_chunks_v2', '{"act_slug":"ee-tsms","act_name":"Tsiviilkohtumenetluse seadustik","lang":"et"}'::jsonb, 1),
  ('rt', 'HMS',    'law_chunks_v2', '{"act_slug":"ee-hms","act_name":"Haldusmenetluse seadus","lang":"et"}'::jsonb,        1),
  ('rt', 'HKMS',   'law_chunks_v2', '{"act_slug":"ee-hkms","act_name":"Halduskohtumenetluse seadustik","lang":"et"}'::jsonb, 1),
  ('rt', 'VTMS',   'law_chunks_v2', '{"act_slug":"ee-vtms","act_name":"Väärteomenetluse seadustik","lang":"et"}'::jsonb,   2),
  ('rt', 'TsÜS',   'law_chunks_v2', '{"act_slug":"ee-tsus","act_name":"Tsiviilseadustiku üldosa seadus","lang":"et"}'::jsonb, 1),
  ('rt', 'VÕS',    'law_chunks_v2', '{"act_slug":"ee-vos","act_name":"Võlaõigusseadus","lang":"et"}'::jsonb,               1),
  ('rt', 'AÕS',    'law_chunks_v2', '{"act_slug":"ee-aos","act_name":"Asjaõigusseadus","lang":"et"}'::jsonb,               2),
  -- "PankS" from the spec is wrong → real RT abbreviation is "PankrS".
  ('rt', 'PankrS', 'law_chunks_v2', '{"act_slug":"ee-panks","act_name":"Pankrotiseadus","lang":"et","act_abbrev":"PankS"}'::jsonb, 3),
  ('rt', 'ÄS',     'law_chunks_v2', '{"act_slug":"ee-as","act_name":"Äriseadustik","lang":"et"}'::jsonb,                   2),
  -- "PerekS" from the spec is wrong → real RT abbreviation is "PKS".
  ('rt', 'PKS',    'law_chunks_v2', '{"act_slug":"ee-pereks","act_name":"Perekonnaseadus","lang":"et","act_abbrev":"PKS"}'::jsonb, 2),
  ('rt', 'PärS',   'law_chunks_v2', '{"act_slug":"ee-pars","act_name":"Pärimisseadus","lang":"et"}'::jsonb,                3),
  ('rt', 'TLS',    'law_chunks_v2', '{"act_slug":"ee-tls","act_name":"Töölepingu seadus","lang":"et"}'::jsonb,             1),
  ('rt', 'MTÜS',   'law_chunks_v2', '{"act_slug":"ee-mtus","act_name":"Mittetulundusühingute seadus","lang":"et"}'::jsonb, 4),
  ('rt', 'IKS',    'law_chunks_v2', '{"act_slug":"ee-iks","act_name":"Isikuandmete kaitse seadus","lang":"et"}'::jsonb,    2),
  ('rt', 'AvTS',   'law_chunks_v2', '{"act_slug":"ee-avts","act_name":"Avaliku teabe seadus","lang":"et"}'::jsonb,         3),
  ('rt', 'KOKS',   'law_chunks_v2', '{"act_slug":"ee-koks","act_name":"Kohaliku omavalitsuse korralduse seadus","lang":"et"}'::jsonb, 4),
  ('rt', 'VangS',  'law_chunks_v2', '{"act_slug":"ee-vangs","act_name":"Vangistusseadus","lang":"et"}'::jsonb,             4),
  ('rt', 'VRKS',   'law_chunks_v2', '{"act_slug":"ee-vrks","act_name":"Välismaalasele rahvusvahelise kaitse andmise seadus","lang":"et"}'::jsonb, 2),
  ('rt', 'KMS',    'law_chunks_v2', '{"act_slug":"ee-kms","act_name":"Käibemaksuseadus","lang":"et"}'::jsonb,              3),
  ('rt', 'TuMS',   'law_chunks_v2', '{"act_slug":"ee-tums","act_name":"Tulumaksuseadus","lang":"et"}'::jsonb,              3),
  ('rt', 'RiKS',   'law_chunks_v2', '{"act_slug":"ee-riks","act_name":"Riigikaitseseadus","lang":"et"}'::jsonb,            5),
  ('rt', 'HKTS',   'law_chunks_v2', '{"act_slug":"ee-hkts","act_name":"Halduskoostöö seadus","lang":"et"}'::jsonb,         5)
ON CONFLICT (source, source_id, target_table) DO NOTHING;
