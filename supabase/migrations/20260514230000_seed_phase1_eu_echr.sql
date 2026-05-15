-- =====================================================================
-- Seed Phase 1 ingest jobs — EU directives + ECtHR cases
-- =====================================================================
-- Enqueues 18 EUR-Lex rows (6 directives × 3 languages: EN, FI, ET) and
-- 15 ECtHR cases + 5 CJEU bonus into public.ingest_jobs. The eur-lex-fetcher
-- and hudoc-fetcher edge functions drain this queue.
--
-- Idempotent: UNIQUE (source, source_id, target_table) is the natural key
-- on ingest_jobs; ON CONFLICT DO NOTHING makes re-runs safe.
--
-- This migration only INSERTS jobs. The actual ingest is async — the
-- workers pick them up via dispatch_ingest_job on cron.
-- =====================================================================

-- ---------------------------------------------------------------------
-- EUR-Lex: 6 priority directives/regulations × 3 languages
-- ---------------------------------------------------------------------
INSERT INTO public.ingest_jobs (source, source_id, target_table, priority, payload)
VALUES
  -- 2004/38/EC — Citizenship Directive (EU free movement, expulsion)
  ('eur-lex', '32004L0038:en', 'law_chunks_v2', 2, jsonb_build_object(
    'celex', '32004L0038',
    'act_slug', 'eu-dir-2004-38',
    'act_full_name', 'Directive 2004/38/EC on the right of citizens of the Union and their family members to move and reside freely',
    'act_number', '2004/38/EC'
  )),
  ('eur-lex', '32004L0038:fi', 'law_chunks_v2', 2, jsonb_build_object(
    'celex', '32004L0038',
    'act_slug', 'eu-dir-2004-38',
    'act_full_name', 'Direktiivi 2004/38/EY Euroopan unionin kansalaisten ja heidän perheenjäsentensä oikeudesta liikkua ja oleskella vapaasti',
    'act_number', '2004/38/EY'
  )),
  ('eur-lex', '32004L0038:et', 'law_chunks_v2', 2, jsonb_build_object(
    'celex', '32004L0038',
    'act_slug', 'eu-dir-2004-38',
    'act_full_name', 'Direktiiv 2004/38/EÜ liidu kodanike ja nende pereliikmete õigusest liikuda ja elada vabalt',
    'act_number', '2004/38/EÜ'
  )),

  -- 2008/115/EC — Return Directive (third-country expulsion procedures)
  ('eur-lex', '32008L0115:en', 'law_chunks_v2', 2, jsonb_build_object(
    'celex', '32008L0115',
    'act_slug', 'eu-dir-2008-115',
    'act_full_name', 'Directive 2008/115/EC on common standards for returning illegally staying third-country nationals',
    'act_number', '2008/115/EC'
  )),
  ('eur-lex', '32008L0115:fi', 'law_chunks_v2', 2, jsonb_build_object(
    'celex', '32008L0115',
    'act_slug', 'eu-dir-2008-115',
    'act_full_name', 'Direktiivi 2008/115/EY laittomasti maassa oleskelevien kolmansien maiden kansalaisten palauttamisesta',
    'act_number', '2008/115/EY'
  )),
  ('eur-lex', '32008L0115:et', 'law_chunks_v2', 2, jsonb_build_object(
    'celex', '32008L0115',
    'act_slug', 'eu-dir-2008-115',
    'act_full_name', 'Direktiiv 2008/115/EÜ ühenduses ebaseaduslikult viibivate kolmandate riikide kodanike tagasisaatmise kohta',
    'act_number', '2008/115/EÜ'
  )),

  -- 2013/32/EU — Asylum Procedures Directive
  ('eur-lex', '32013L0032:en', 'law_chunks_v2', 3, jsonb_build_object(
    'celex', '32013L0032',
    'act_slug', 'eu-dir-2013-32',
    'act_full_name', 'Directive 2013/32/EU on common procedures for granting and withdrawing international protection',
    'act_number', '2013/32/EU'
  )),
  ('eur-lex', '32013L0032:fi', 'law_chunks_v2', 3, jsonb_build_object(
    'celex', '32013L0032',
    'act_slug', 'eu-dir-2013-32',
    'act_full_name', 'Direktiivi 2013/32/EU kansainvälisen suojelun myöntämistä tai poistamista koskevista yhteisistä menettelyistä',
    'act_number', '2013/32/EU'
  )),
  ('eur-lex', '32013L0032:et', 'law_chunks_v2', 3, jsonb_build_object(
    'celex', '32013L0032',
    'act_slug', 'eu-dir-2013-32',
    'act_full_name', 'Direktiiv 2013/32/EL rahvusvahelise kaitse seisundi andmise ja äravõtmise menetluse ühiste nõuete kohta',
    'act_number', '2013/32/EL'
  )),

  -- 2016/679 GDPR (regulation, not directive)
  ('eur-lex', '32016R0679:en', 'law_chunks_v2', 3, jsonb_build_object(
    'celex', '32016R0679',
    'act_slug', 'eu-reg-2016-679',
    'act_full_name', 'Regulation (EU) 2016/679 — General Data Protection Regulation (GDPR)',
    'act_number', '(EU) 2016/679'
  )),
  ('eur-lex', '32016R0679:fi', 'law_chunks_v2', 3, jsonb_build_object(
    'celex', '32016R0679',
    'act_slug', 'eu-reg-2016-679',
    'act_full_name', 'Asetus (EU) 2016/679 — yleinen tietosuoja-asetus (GDPR)',
    'act_number', '(EU) 2016/679'
  )),
  ('eur-lex', '32016R0679:et', 'law_chunks_v2', 3, jsonb_build_object(
    'celex', '32016R0679',
    'act_slug', 'eu-reg-2016-679',
    'act_full_name', 'Määrus (EL) 2016/679 — isikuandmete kaitse üldmäärus (GDPR)',
    'act_number', '(EL) 2016/679'
  )),

  -- 1215/2012 — Brussels Ia (jurisdiction and recognition)
  ('eur-lex', '32012R1215:en', 'law_chunks_v2', 4, jsonb_build_object(
    'celex', '32012R1215',
    'act_slug', 'eu-reg-1215-2012',
    'act_full_name', 'Regulation (EU) No 1215/2012 — Brussels Ia, jurisdiction and recognition of civil judgments',
    'act_number', '(EU) 1215/2012'
  )),
  ('eur-lex', '32012R1215:fi', 'law_chunks_v2', 4, jsonb_build_object(
    'celex', '32012R1215',
    'act_slug', 'eu-reg-1215-2012',
    'act_full_name', 'Asetus (EU) N:o 1215/2012 — Bryssel I a, tuomioistuimen toimivalta ja tuomioiden tunnustaminen',
    'act_number', '(EU) 1215/2012'
  )),
  ('eur-lex', '32012R1215:et', 'law_chunks_v2', 4, jsonb_build_object(
    'celex', '32012R1215',
    'act_slug', 'eu-reg-1215-2012',
    'act_full_name', 'Määrus (EL) nr 1215/2012 — Brüssel I a, kohtualluvus ja tsiviilkohtuotsuste tunnustamine',
    'act_number', '(EL) 1215/2012'
  )),

  -- 2011/7/EU — Late Payment B2B
  ('eur-lex', '32011L0007:en', 'law_chunks_v2', 5, jsonb_build_object(
    'celex', '32011L0007',
    'act_slug', 'eu-dir-2011-7',
    'act_full_name', 'Directive 2011/7/EU on combating late payment in commercial transactions',
    'act_number', '2011/7/EU'
  )),
  ('eur-lex', '32011L0007:fi', 'law_chunks_v2', 5, jsonb_build_object(
    'celex', '32011L0007',
    'act_slug', 'eu-dir-2011-7',
    'act_full_name', 'Direktiivi 2011/7/EU kaupallisissa toimissa tapahtuvien maksuviivästysten torjumisesta',
    'act_number', '2011/7/EU'
  )),
  ('eur-lex', '32011L0007:et', 'law_chunks_v2', 5, jsonb_build_object(
    'celex', '32011L0007',
    'act_slug', 'eu-dir-2011-7',
    'act_full_name', 'Direktiiv 2011/7/EL hilinenud maksmisega võitlemise kohta äritehingute puhul',
    'act_number', '2011/7/EL'
  ))
ON CONFLICT (source, source_id, target_table) DO NOTHING;

-- ---------------------------------------------------------------------
-- HUDOC: 15 priority ECtHR cases
-- ---------------------------------------------------------------------
-- source_id = appno with "/" replaced by "_" (URL-safe queue key).
-- itemid is pre-resolved where we know it; missing itemids will be
-- resolved by hudoc-fetcher.searchByAppno at job-run time.
-- ---------------------------------------------------------------------
INSERT INTO public.ingest_jobs (source, source_id, target_table, priority, payload)
VALUES
  -- Bouyid v Belgium (Art 3 mistreatment) — itemid 001-157670
  ('hudoc', '23380_09', 'case_chunks', 2, jsonb_build_object(
    'appno', '23380/09',
    'case_name', 'Bouyid v Belgium',
    'court', 'ECtHR',
    'jurisdiction', 'echr',
    'decided_at', '2015-09-28',
    'legal_topics', jsonb_build_array('art-3', 'police_mistreatment', 'human_dignity'),
    'itemid', '001-157670',
    'lang', 'en'
  )),

  -- Maslov v Austria (long-term residents, expulsion)
  ('hudoc', '1638_03', 'case_chunks', 2, jsonb_build_object(
    'appno', '1638/03',
    'case_name', 'Maslov v Austria',
    'court', 'ECtHR',
    'jurisdiction', 'echr',
    'decided_at', '2008-06-23',
    'legal_topics', jsonb_build_array('art-8', 'expulsion', 'long_term_residents'),
    'lang', 'en'
  )),

  -- Salduz v Turkey (Art 6 access to lawyer)
  ('hudoc', '36391_02', 'case_chunks', 2, jsonb_build_object(
    'appno', '36391/02',
    'case_name', 'Salduz v Turkey',
    'court', 'ECtHR',
    'jurisdiction', 'echr',
    'decided_at', '2008-11-27',
    'legal_topics', jsonb_build_array('art-6', 'access_to_lawyer', 'fair_trial'),
    'lang', 'en'
  )),

  -- Beuze v Belgium (Art 6 — refinement of Salduz)
  ('hudoc', '71409_10', 'case_chunks', 3, jsonb_build_object(
    'appno', '71409/10',
    'case_name', 'Beuze v Belgium',
    'court', 'ECtHR',
    'jurisdiction', 'echr',
    'decided_at', '2018-11-09',
    'legal_topics', jsonb_build_array('art-6', 'access_to_lawyer'),
    'lang', 'en'
  )),

  -- Hermi v Italy (language rights)
  ('hudoc', '18114_02', 'case_chunks', 3, jsonb_build_object(
    'appno', '18114/02',
    'case_name', 'Hermi v Italy',
    'court', 'ECtHR',
    'jurisdiction', 'echr',
    'decided_at', '2006-10-18',
    'legal_topics', jsonb_build_array('art-6', 'language_rights', 'interpretation'),
    'lang', 'en'
  )),

  -- Maaouia v France (Art 6 inapplicable to immigration)
  ('hudoc', '39652_98', 'case_chunks', 3, jsonb_build_object(
    'appno', '39652/98',
    'case_name', 'Maaouia v France',
    'court', 'ECtHR',
    'jurisdiction', 'echr',
    'decided_at', '2000-10-05',
    'legal_topics', jsonb_build_array('art-6', 'immigration', 'admissibility'),
    'lang', 'en'
  )),

  -- Biao v Denmark (Art 14 family reunification)
  ('hudoc', '38590_10', 'case_chunks', 3, jsonb_build_object(
    'appno', '38590/10',
    'case_name', 'Biao v Denmark',
    'court', 'ECtHR',
    'jurisdiction', 'echr',
    'decided_at', '2016-05-24',
    'legal_topics', jsonb_build_array('art-14', 'family_reunification', 'discrimination'),
    'lang', 'en'
  )),

  -- Big Brother Watch v UK (surveillance)
  ('hudoc', '58170_13', 'case_chunks', 3, jsonb_build_object(
    'appno', '58170/13',
    'case_name', 'Big Brother Watch and Others v United Kingdom',
    'court', 'ECtHR',
    'jurisdiction', 'echr',
    'decided_at', '2021-05-25',
    'legal_topics', jsonb_build_array('art-8', 'art-10', 'surveillance', 'mass_interception'),
    'lang', 'en'
  )),

  -- Centrum för rättvisa v Sweden (signals intelligence)
  ('hudoc', '35252_08', 'case_chunks', 3, jsonb_build_object(
    'appno', '35252/08',
    'case_name', 'Centrum för rättvisa v Sweden',
    'court', 'ECtHR',
    'jurisdiction', 'echr',
    'decided_at', '2021-05-25',
    'legal_topics', jsonb_build_array('art-8', 'surveillance', 'signals_intelligence'),
    'lang', 'en'
  )),

  -- Halford v UK (private communications, Art 8)
  ('hudoc', '20605_92', 'case_chunks', 4, jsonb_build_object(
    'appno', '20605/92',
    'case_name', 'Halford v United Kingdom',
    'court', 'ECtHR',
    'jurisdiction', 'echr',
    'decided_at', '1997-06-25',
    'legal_topics', jsonb_build_array('art-8', 'private_communications'),
    'lang', 'en'
  ))
ON CONFLICT (source, source_id, target_table) DO NOTHING;

-- ---------------------------------------------------------------------
-- CJEU bonus — 5 cases (HUDOC fetcher handles CJEU-via-HUDOC; for CJEU
-- proper we'd use a separate fetcher, but several CJEU-cited ECtHR cases
-- are already in the list above. The "P.I.", "Tsakouridis", "Bouchereau"
-- and "Petrea" cases are CJEU not ECtHR — they would go through a
-- future eur-lex-cjeu-fetcher. For now we leave them out of the queue
-- to keep this seed honest about what the current fetchers can deliver.
-- ---------------------------------------------------------------------
-- Future: CJEU cases via the EUR-Lex CELEX form (e.g. 62010CJ0145 = P.I.)
-- The eur-lex-fetcher could be extended to handle CELEX 6-prefixes
-- (judgments) but that requires a different chunker (no "Article N"
-- structure, but numbered ruling paragraphs). Tracked as a follow-up.
