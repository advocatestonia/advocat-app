-- =============================================================================
-- Phase 2 Pkg 1 — law_chunks gets jurisdiction + in_force columns.
--   • jurisdiction (text, NOT NULL after backfill, CHECK ∈ {EE,FI,EU,RU,DE})
--     — drives the multi-jurisdiction routing layer in claude_service /
--       law-search / lookup_statute.
--   • in_force (bool NOT NULL DEFAULT true) — lets us version statutes:
--     when an act is amended, the new chunk is `in_force = true`, the prior
--     row gets flipped to `in_force = false` and is excluded from search /
--     lookup. Together with the partial unique index this guarantees
--     "exactly one in-force version of (act_slug, paragraph, jurisdiction)"
--     at any point — the invariant lookup_statute relies on.
--
-- Backfill rules for the 8345 existing rows (P0-1/P0-2 corpus):
--   • lang ∈ {et, ru, en}        → 'EE' (Estonian acts; ru/en chunks are
--                                   translations of EE acts).
--   • lang ∈ {eu_en, eu_et, eu_ru} → 'EU' (CELEX-IDs).
--   • else                        → 'EE' (conservative — no FI/DE/RU acts
--                                   exist in the corpus today; this just
--                                   keeps the NOT NULL constraint happy
--                                   for any unforeseen lang values).
-- =============================================================================

alter table public.law_chunks
  add column if not exists jurisdiction text,
  add column if not exists in_force boolean not null default true;

-- ── Backfill jurisdiction for the existing 8345 rows. The CASE mirrors the
-- corpus convention defined in P0-1 (data/corpus/{et,eu}/*.md frontmatter).
update public.law_chunks
   set jurisdiction = case
     when lang = 'et'                            then 'EE'
     when lang in ('eu_en', 'eu_et', 'eu_ru')   then 'EU'
     when lang = 'ru'                            then 'EE'  -- RU translations are of EE acts
     when lang = 'en'                            then 'EE'  -- EN translations are of EE acts
     else                                              'EE' -- conservative back-compat default
   end
 where jurisdiction is null;

alter table public.law_chunks
  alter column jurisdiction set not null,
  add constraint law_chunks_jurisdiction_check
    check (jurisdiction in ('EE', 'FI', 'EU', 'RU', 'DE'));

-- ── Routing speed index. The existing law_chunks_lang_topic_idx covers the
-- (lang, topic) hot path; this one covers (jurisdiction, in_force) which
-- the routing layer hits before falling through to embedding search.
create index if not exists law_chunks_jurisdiction_in_force_idx
  on public.law_chunks (jurisdiction, in_force);

-- ── Critical invariant: only ONE in-force version of
-- (act_slug, paragraph, jurisdiction). Partial unique index — historical
-- rows with `in_force = false` are exempt so amendments can coexist with
-- their predecessor.
create unique index if not exists law_chunks_in_force_unique
  on public.law_chunks (act_slug, paragraph, jurisdiction)
  where in_force = true;

-- ── Updated law_search RPC: gains a (nullable) query_jurisdiction
-- parameter and the in_force filter. Behaviour:
--   • query_jurisdiction = null → search everything (back-compat with
--     P0-2/P0-3 callers that don't yet pass jurisdiction).
--   • query_jurisdiction = 'EE' → only EE rows.
--   • query_lang = null         → ignore lang filter (multi-lang search).
--   • query_lang = 'et'         → EE-language rows OR any eu_* (EU
--                                  directives are language-agnostic from
--                                  the chat layer's POV).
-- We DROP the old function first because the signature changes (4-arg
-- shape becomes 5-arg shape). `create or replace` does NOT permit
-- signature changes, so DROP is mandatory. The DROP+CREATE pair is
-- wrapped in a single transaction so concurrent callers never see a
-- moment where law_search does not exist (B1 fix). Existing callers
-- (P0-3 client) bind to the new function via positional defaults.
begin;

drop function if exists public.law_search(vector(1536), text, int, float);

create or replace function public.law_search(
    query_embedding      vector(1536),
    query_lang           text,
    match_count          int default 8,
    similarity_threshold float default 0.60,
    query_jurisdiction   text default null
)
returns table (
    id            text,
    act_slug      text,
    act_name      text,
    paragraph     text,
    title         text,
    body          text,
    source_url    text,
    jurisdiction  text,
    similarity    float
)
language sql stable security invoker as $$
    select
        lc.id,
        lc.act_slug,
        lc.act_name,
        lc.paragraph,
        lc.title,
        lc.body,
        lc.source_url,
        lc.jurisdiction,
        1 - (lc.embedding <=> query_embedding) as similarity
    from public.law_chunks lc
    where lc.in_force = true
      and (query_jurisdiction is null or lc.jurisdiction = query_jurisdiction)
      and (
            query_lang is null
            or lc.lang = query_lang
            or lc.lang like 'eu_%'
          )
      and 1 - (lc.embedding <=> query_embedding) >= similarity_threshold
    order by lc.embedding <=> query_embedding
    limit match_count;
$$;

commit;

-- PGRST schema cache reload — make new RPC + columns reachable after
-- `db push` (memory: reference_pitfalls_chat_infra).
notify pgrst, 'reload schema';
