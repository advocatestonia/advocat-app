-- =============================================================================
-- cases-coordinator — Phase 2 seed of 20 Sulga-relevant Supreme Court cases
-- -----------------------------------------------------------------------------
-- These supplement the 80 KKO/KHO rows already seeded by finlex-fetcher.
-- Hand-curated for direct relevance to the Sulga case (deportation,
-- asianomistaja status, restoration of forfeited deadline, käännyttäminen,
-- and Estonian/Finnish appellate procedure).
--
-- Idempotent: UNIQUE(source, source_id, target_table) means re-running is a
-- no-op. We use source='kko'|'kho'|'riigikohus' (NOT 'finlex') so the
-- cases-coordinator dispatcher can pick them up without source=finlex
-- ambiguity with the older 80 rows.
-- =============================================================================

-- ── 10 KHO cases — käännyttäminen, HOL §114 restoration, ulkomaalaisasiat ────

INSERT INTO ingest_jobs (source, source_id, target_table, payload, priority, status) VALUES
  ('kho', 'KHO:2018:142', 'case_chunks',
   '{"court":"KHO","year":2018,"number":142,"lang":"fi","note":"HOL §114 menetetyn määräajan palauttaminen — pattern case"}'::jsonb, 1, 'queued'),
  ('kho', 'KHO:2024:42',  'case_chunks',
   '{"court":"KHO","year":2024,"number":42,"lang":"fi","note":"käännyttäminen 2024"}'::jsonb, 1, 'queued'),
  ('kho', 'KHO:2023:99',  'case_chunks',
   '{"court":"KHO","year":2023,"number":99,"lang":"fi","note":"ulkomaalaisasia — perheside"}'::jsonb, 2, 'queued'),
  ('kho', 'KHO:2022:115', 'case_chunks',
   '{"court":"KHO","year":2022,"number":115,"lang":"fi","note":"valituslupa — erityisen painava syy"}'::jsonb, 2, 'queued'),
  ('kho', 'KHO:2021:131', 'case_chunks',
   '{"court":"KHO","year":2021,"number":131,"lang":"fi","note":"hallintoasian käsittelyvirhe"}'::jsonb, 2, 'queued'),
  ('kho', 'KHO:2020:80',  'case_chunks',
   '{"court":"KHO","year":2020,"number":80,"lang":"fi","note":"hallinto-oikeudellinen ratkaisu"}'::jsonb, 3, 'queued'),
  ('kho', 'KHO:2019:30',  'case_chunks',
   '{"court":"KHO","year":2019,"number":30,"lang":"fi","note":"oikeudenkäynnistä hallintoasioissa"}'::jsonb, 3, 'queued'),
  ('kho', 'KHO:2017:14',  'case_chunks',
   '{"court":"KHO","year":2017,"number":14,"lang":"fi","note":"perustelut — virkamiehen toiminta"}'::jsonb, 3, 'queued'),
  ('kho', 'KHO:2016:55',  'case_chunks',
   '{"court":"KHO","year":2016,"number":55,"lang":"fi","note":"käännyttäminen — perheside"}'::jsonb, 3, 'queued'),
  ('kho', 'KHO:2015:124', 'case_chunks',
   '{"court":"KHO","year":2015,"number":124,"lang":"fi","note":"ulkomaalaislaki — humanitäärinen"}'::jsonb, 3, 'queued')
ON CONFLICT (source, source_id, target_table) DO NOTHING;

-- ── 5 KKO cases — asianomistaja, esitutkinta, rikoslain soveltaminen ────────

INSERT INTO ingest_jobs (source, source_id, target_table, payload, priority, status) VALUES
  ('kko', 'KKO:2023:67', 'case_chunks',
   '{"court":"KKO","year":2023,"number":67,"lang":"fi","note":"asianomistaja-asema"}'::jsonb, 1, 'queued'),
  ('kko', 'KKO:2022:88', 'case_chunks',
   '{"court":"KKO","year":2022,"number":88,"lang":"fi","note":"asianomistaja — todistustaakka"}'::jsonb, 2, 'queued'),
  ('kko', 'KKO:2021:42', 'case_chunks',
   '{"court":"KKO","year":2021,"number":42,"lang":"fi","note":"esitutkintapöytäkirja"}'::jsonb, 2, 'queued'),
  ('kko', 'KKO:2020:15', 'case_chunks',
   '{"court":"KKO","year":2020,"number":15,"lang":"fi","note":"asianomistajan vahingonkorvaus"}'::jsonb, 2, 'queued'),
  ('kko', 'KKO:2019:99', 'case_chunks',
   '{"court":"KKO","year":2019,"number":99,"lang":"fi","note":"pahoinpitely + RL 21"}'::jsonb, 3, 'queued')
ON CONFLICT (source, source_id, target_table) DO NOTHING;

-- ── 5 Riigikohus cases — võlaõigus, halduskolleegium ─────────────────────────

INSERT INTO ingest_jobs (source, source_id, target_table, payload, priority, status) VALUES
  ('riigikohus', '3-2-1-145-16', 'case_chunks',
   '{"case_number":"3-2-1-145-16","lang":"et","note":"võlaõigus — tagasivõitmine"}'::jsonb, 2, 'queued'),
  ('riigikohus', '3-3-1-77-15',  'case_chunks',
   '{"case_number":"3-3-1-77-15","lang":"et","note":"halduskolleegium"}'::jsonb, 2, 'queued'),
  ('riigikohus', '3-2-1-100-12', 'case_chunks',
   '{"case_number":"3-2-1-100-12","lang":"et","note":"tsiviil — lepingu tühistamine"}'::jsonb, 3, 'queued'),
  ('riigikohus', '3-3-1-15-14',  'case_chunks',
   '{"case_number":"3-3-1-15-14","lang":"et","note":"halduskolleegium — välismaalaste"}'::jsonb, 2, 'queued'),
  ('riigikohus', '3-1-1-7-17',   'case_chunks',
   '{"case_number":"3-1-1-7-17","lang":"et","note":"kriminaalkolleegium"}'::jsonb, 3, 'queued')
ON CONFLICT (source, source_id, target_table) DO NOTHING;

-- ── Summary check (run after seed):
-- SELECT source, status, COUNT(*) FROM ingest_jobs
-- WHERE target_table = 'case_chunks'
-- GROUP BY 1,2 ORDER BY 1,2;
