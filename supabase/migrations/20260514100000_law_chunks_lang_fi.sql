-- =============================================================================
-- Phase 2 Pkg 1 (Finland corpus) — extend law_chunks.lang CHECK to allow 'fi'
-- and 'eu_fi'.
--
-- Why this is the entire schema delta for Finnish ingestion:
--   • jurisdiction column already exists (20260507060000) with CHECK including
--     'FI'. The partial unique index `law_chunks_in_force_unique (act_slug,
--     paragraph, jurisdiction) where in_force` already scopes uniqueness per
--     jurisdiction — Finnish § 1 of one act will not collide with Estonian
--     § 1 of another act.
--   • law_search RPC already accepts query_jurisdiction.
--   • The ONLY remaining blocker is the lang CHECK constraint, which today
--     only permits {et, ru, en, eu_et, eu_ru, eu_en}. The Finlex ingest will
--     write rows with lang='fi' (Finnish statutes) and Phase 2 will add
--     lang='eu_fi' (Finnish translations of EU directives — same body, just
--     translated, so we keep them flagged as EU jurisdiction).
--
-- Idempotent: DROP IF EXISTS + ADD recreates the constraint with the wider
-- value set. Existing rows are unaffected — the new set is a strict superset.
-- =============================================================================

alter table public.law_chunks
  drop constraint if exists law_chunks_lang_check;

alter table public.law_chunks
  add constraint law_chunks_lang_check
    check (lang in (
      'et', 'ru', 'en', 'fi',
      'eu_et', 'eu_ru', 'eu_en', 'eu_fi'
    ));

-- PGRST schema cache reload — make the new constraint visible to PostgREST
-- without a manual edge function restart. Matches the pattern used in the
-- jurisdiction migration (memory: reference_pitfalls_chat_infra).
notify pgrst, 'reload schema';
