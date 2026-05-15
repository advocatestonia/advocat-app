-- ============================================================================
-- Phase 1 ajantasa seed — Option B (2026-05-15)
-- ============================================================================
-- Per business/legal/finlex_licensing_decision_2026-05-14.md and the §1
-- Phase-1 scope in the task brief: ingest consolidated/ajantasa text for the
-- 5 most-amended acts the model needs current sections from:
--   • HOL   434/2003 — Hallintolaki
--   • OHO   808/2019 — Laki oikeudenkäynnistä hallintoasioissa (KHO §114)
--   • UlkL  301/2004 — Ulkomaalaislaki (Sulga case, Track B)
--   • RL    39/1889  — Rikoslaki (post-2003 chapters)
--   • PolL  872/2011 — Poliisilaki
--
-- Distinct source_id format: "YYYY/NN:ajantasa" so the UNIQUE
-- (source, source_id, target_table) index does NOT collide with the existing
-- alkup jobs (which use "YYYY/NN"). The fetcher parses YYYY/NN via the same
-- regex by stripping the ":ajantasa" suffix — see processStatuteJob.
--
-- payload.redaktsioon='ajantasa' opts the fetcher into the consolidated
-- endpoint and the snippet_only license tagging.
--
-- Idempotent: ON CONFLICT DO NOTHING — re-running this migration is a no-op
-- if the rows already exist.
-- ============================================================================

INSERT INTO public.ingest_jobs (source, source_id, target_table, payload, priority) VALUES
  ('finlex', '2003/434:ajantasa',  'law_chunks_v2',
    '{"act_slug":"fi-hol","act_name":"Hallintolaki","act_number":"434/2003","lang":"fi","act_abbrev":"HOL","redaktsioon":"ajantasa"}'::jsonb, 1),
  ('finlex', '2019/808:ajantasa',  'law_chunks_v2',
    '{"act_slug":"fi-oho","act_name":"Laki oikeudenkäynnistä hallintoasioissa","act_number":"808/2019","lang":"fi","act_abbrev":"OHO","redaktsioon":"ajantasa"}'::jsonb, 1),
  ('finlex', '2004/301:ajantasa',  'law_chunks_v2',
    '{"act_slug":"fi-ulkl","act_name":"Ulkomaalaislaki","act_number":"301/2004","lang":"fi","act_abbrev":"UlkL","redaktsioon":"ajantasa"}'::jsonb, 1),
  ('finlex', '1889/39:ajantasa',   'law_chunks_v2',
    '{"act_slug":"fi-rl","act_name":"Rikoslaki","act_number":"39/1889","lang":"fi","act_abbrev":"RL","redaktsioon":"ajantasa"}'::jsonb, 2),
  ('finlex', '2011/872:ajantasa',  'law_chunks_v2',
    '{"act_slug":"fi-poll","act_name":"Poliisilaki","act_number":"872/2011","lang":"fi","act_abbrev":"PolL","redaktsioon":"ajantasa"}'::jsonb, 2)
ON CONFLICT (source, source_id, target_table) DO NOTHING;
