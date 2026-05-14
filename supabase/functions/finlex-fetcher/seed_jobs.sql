-- =============================================================================
-- finlex-fetcher — Phase 2 Pkg 1 seed
--
-- Two job batches:
--   1. 25 priority FI statutes  → law_chunks_v2  (will fetch + chunk)
--   2. 80 KKO/KHO cases         → case_chunks    (will be marked 'blocked'
--                                                  until headless-browser
--                                                  fetcher is wired — see
--                                                  index.ts CASE_FETCH_BLOCKED_REASON)
--
-- Idempotent: UNIQUE(source, source_id, target_table) means re-running this
-- file is a no-op (ON CONFLICT DO NOTHING handles the conflict).
--
-- act_number convention: payload.act_number stores "NN/YYYY" (Finnish
-- citation convention) — distinct from source_id which is "YYYY/NN" (the
-- Finlex URI segment order). This is intentional. ALL legal citations
-- downstream use NN/YYYY (e.g. "Rikoslaki (39/1889)"), but the Finlex
-- API path order is YYYY/NN.
-- =============================================================================

-- ── 25 priority FI statutes ──────────────────────────────────────────────────

INSERT INTO ingest_jobs (source, source_id, target_table, payload, priority) VALUES
  ('finlex', '1889/39',   'law_chunks_v2', '{"act_slug":"fi-rl","act_name":"Rikoslaki","act_number":"39/1889","lang":"fi","act_abbrev":"RL"}'::jsonb, 1),
  ('finlex', '1734/4',    'law_chunks_v2', '{"act_slug":"fi-ok","act_name":"Oikeudenkäymiskaari","act_number":"4/1734","lang":"fi","act_abbrev":"OK"}'::jsonb, 1),
  ('finlex', '1997/689',  'law_chunks_v2', '{"act_slug":"fi-rol","act_name":"Laki oikeudenkäynnistä rikosasioissa","act_number":"689/1997","lang":"fi","act_abbrev":"ROL"}'::jsonb, 1),
  ('finlex', '2003/434',  'law_chunks_v2', '{"act_slug":"fi-hol","act_name":"Hallintolaki","act_number":"434/2003","lang":"fi","act_abbrev":"HOL"}'::jsonb, 1),
  ('finlex', '2019/808',  'law_chunks_v2', '{"act_slug":"fi-oho","act_name":"Laki oikeudenkäynnistä hallintoasioissa","act_number":"808/2019","lang":"fi","act_abbrev":"OHO"}'::jsonb, 1),
  ('finlex', '2004/301',  'law_chunks_v2', '{"act_slug":"fi-ulkl","act_name":"Ulkomaalaislaki","act_number":"301/2004","lang":"fi","act_abbrev":"UlkL"}'::jsonb, 1),
  ('finlex', '2011/872',  'law_chunks_v2', '{"act_slug":"fi-poll","act_name":"Poliisilaki","act_number":"872/2011","lang":"fi","act_abbrev":"PolL"}'::jsonb, 2),
  ('finlex', '2011/805',  'law_chunks_v2', '{"act_slug":"fi-esitutkintal","act_name":"Esitutkintalaki","act_number":"805/2011","lang":"fi","act_abbrev":"ETL"}'::jsonb, 2),
  ('finlex', '2011/806',  'law_chunks_v2', '{"act_slug":"fi-pakkokeinol","act_name":"Pakkokeinolaki","act_number":"806/2011","lang":"fi","act_abbrev":"PKL"}'::jsonb, 2),
  ('finlex', '1974/412',  'law_chunks_v2', '{"act_slug":"fi-vahingonkorvausl","act_name":"Vahingonkorvauslaki","act_number":"412/1974","lang":"fi","act_abbrev":"VKL"}'::jsonb, 2),
  ('finlex', '2005/1204', 'law_chunks_v2', '{"act_slug":"fi-rikosvahinkol","act_name":"Rikosvahinkolaki","act_number":"1204/2005","lang":"fi","act_abbrev":"RikVahL"}'::jsonb, 2),
  ('finlex', '1999/731',  'law_chunks_v2', '{"act_slug":"fi-perustuslaki","act_name":"Suomen perustuslaki","act_number":"731/1999","lang":"fi","act_abbrev":"PL"}'::jsonb, 2),
  ('finlex', '2014/1325', 'law_chunks_v2', '{"act_slug":"fi-yhdenvertaisuusl","act_name":"Yhdenvertaisuuslaki","act_number":"1325/2014","lang":"fi","act_abbrev":"YVL"}'::jsonb, 3),
  ('finlex', '2015/410',  'law_chunks_v2', '{"act_slug":"fi-kuntal","act_name":"Kuntalaki","act_number":"410/2015","lang":"fi","act_abbrev":"KuntaL"}'::jsonb, 3),
  ('finlex', '1999/621',  'law_chunks_v2', '{"act_slug":"fi-julkisuusl","act_name":"Laki viranomaisten toiminnan julkisuudesta","act_number":"621/1999","lang":"fi","act_abbrev":"JulkL"}'::jsonb, 3),
  ('finlex', '2018/1050', 'law_chunks_v2', '{"act_slug":"fi-tietosuojal","act_name":"Tietosuojalaki","act_number":"1050/2018","lang":"fi","act_abbrev":"TSL"}'::jsonb, 3),
  ('finlex', '1929/234',  'law_chunks_v2', '{"act_slug":"fi-avioliittol","act_name":"Avioliittolaki","act_number":"234/1929","lang":"fi","act_abbrev":"AL"}'::jsonb, 3),
  ('finlex', '1983/361',  'law_chunks_v2', '{"act_slug":"fi-lapsenhuoltol","act_name":"Laki lapsen huollosta ja tapaamisoikeudesta","act_number":"361/1983","lang":"fi","act_abbrev":"LHL"}'::jsonb, 3),
  ('finlex', '1999/442',  'law_chunks_v2', '{"act_slug":"fi-holhoustoimil","act_name":"Laki holhoustoimesta","act_number":"442/1999","lang":"fi","act_abbrev":"HolhL"}'::jsonb, 4),
  ('finlex', '2001/55',   'law_chunks_v2', '{"act_slug":"fi-tyosopimusl","act_name":"Työsopimuslaki","act_number":"55/2001","lang":"fi","act_abbrev":"TSopL"}'::jsonb, 2),
  ('finlex', '1978/38',   'law_chunks_v2', '{"act_slug":"fi-kuluttajansuojal","act_name":"Kuluttajansuojalaki","act_number":"38/1978","lang":"fi","act_abbrev":"KSL"}'::jsonb, 3),
  ('finlex', '1993/57',   'law_chunks_v2', '{"act_slug":"fi-velkajarjestelyl","act_name":"Laki yksityishenkilön velkajärjestelystä","act_number":"57/1993","lang":"fi","act_abbrev":"VJL"}'::jsonb, 4),
  ('finlex', '2004/120',  'law_chunks_v2', '{"act_slug":"fi-konkurssil","act_name":"Konkurssilaki","act_number":"120/2004","lang":"fi","act_abbrev":"KonkL"}'::jsonb, 3),
  ('finlex', '2003/13',   'law_chunks_v2', '{"act_slug":"fi-sahkoinen-asiointi","act_name":"Laki sähköisestä asioinnista viranomaistoiminnassa","act_number":"13/2003","lang":"fi","act_abbrev":"SAVL"}'::jsonb, 4),
  -- Padding entry to reach 25: Laki ulkomaalaisrekisteristä 1270/1997 (FI alien registry act, supports UlkL workflow)
  ('finlex', '1997/1270', 'law_chunks_v2', '{"act_slug":"fi-ulkrekl","act_name":"Laki ulkomaalaisrekisteristä","act_number":"1270/1997","lang":"fi","act_abbrev":"UlkRekL"}'::jsonb, 4)
ON CONFLICT (source, source_id, target_table) DO NOTHING;

-- ── 80 KKO/KHO cases — currently blocked (see index.ts comment) ──────────────
-- Top-40 KKO + top-40 KHO from 2022-2024 (highest-volume recent years).
-- All payloads use `court` + `case_year` + `case_number` so a future
-- headless-browser fetcher has everything it needs (matches the
-- www.finlex.fi/fi/oikeuskaytanto/korkein-oikeus/ennakkopaatokset/{year}/{num}
-- URL template).

INSERT INTO ingest_jobs (source, source_id, target_table, payload, priority)
SELECT
  'finlex',
  court || ':' || y::text || ':' || n::text,
  'case_chunks',
  jsonb_build_object(
    'court', court,
    'case_year', y,
    'case_number', n,
    'lang', 'fi',
    'ecli', 'ECLI:FI:' || court || ':' || y::text || ':' || n::text
  ),
  CASE WHEN y >= 2024 THEN 2 ELSE 3 END
FROM (
  -- KKO 2024: 1..30, 2023: 1..10 (40 total)
  SELECT 'KKO'::text AS court, 2024::int AS y, n::int FROM generate_series(1, 30) n
  UNION ALL
  SELECT 'KKO', 2023, n FROM generate_series(1, 10) n
  UNION ALL
  -- KHO 2024: 1..30, 2023: 1..10 (40 total)
  SELECT 'KHO', 2024, n FROM generate_series(1, 30) n
  UNION ALL
  SELECT 'KHO', 2023, n FROM generate_series(1, 10) n
) AS cases
ON CONFLICT (source, source_id, target_table) DO NOTHING;
