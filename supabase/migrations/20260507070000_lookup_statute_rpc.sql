-- =============================================================================
-- Phase 2 Pkg 1+2 — lookup_statute RPC.
--   Exact-paragraph lookup — NO embedding, NO similarity, just
--   (act_slug, paragraph, jurisdiction). The routing layer / chat tool
--   uses it whenever the user names a specific § ("what does KarS § 121
--   say verbatim"); embedding search is reserved for semantic queries.
--
--   Returns at most one row (the in-force version per the unique partial
--   index in 20260507060000_law_chunks_jurisdiction.sql). NULL is a normal
--   return — caller handles "not in our corpus".
--
--   ilike on act_slug is intentional: the corpus uses lowercase slugs
--   ("kars", "hms") but the model and users frequently send uppercase
--   ("KarS", "HMS"). Paragraph and jurisdiction are exact-match.
-- =============================================================================

create or replace function public.lookup_statute(
    p_act_slug      text,
    p_paragraph     text,
    p_jurisdiction  text default 'EE'
)
returns table (
    id            text,
    act_slug      text,
    act_name      text,
    paragraph     text,
    title         text,
    body          text,
    source_url    text,
    version_date  date,
    jurisdiction  text
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
        lc.version_date,
        lc.jurisdiction
    from public.law_chunks lc
    where lc.act_slug ilike p_act_slug
      and lc.paragraph = p_paragraph
      and lc.jurisdiction = p_jurisdiction
      and lc.in_force = true
    limit 1;
$$;

grant execute on function public.lookup_statute(text, text, text)
  to anon, authenticated;

-- B5: pin owner. lookup_statute is SECURITY INVOKER (no privilege
-- escalation needed) but we still ALTER OWNER for parity with the rest
-- of the migration set. Apply via service-role / postgres connection so
-- this ALTER succeeds; otherwise the migration aborts loudly.
alter function public.lookup_statute(text, text, text) owner to postgres;

-- PGRST schema cache reload — make the RPC reachable after `db push`
-- (memory: reference_pitfalls_chat_infra).
notify pgrst, 'reload schema';
