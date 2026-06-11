CREATE OR REPLACE FUNCTION patch_case_facts(
  p_case_id         UUID,
  p_certain_dates   JSONB DEFAULT '[]',
  p_certain_parties JSONB DEFAULT '[]',
  p_certain_case_numbers TEXT[] DEFAULT '{}',
  p_open_questions  TEXT[] DEFAULT '{}',
  p_contradictions  TEXT[] DEFAULT '{}',
  p_legal_claims    TEXT[] DEFAULT '{}'
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE user_cases SET
    key_dates = (
      SELECT jsonb_agg(DISTINCT elem)
      FROM (
        SELECT elem FROM jsonb_array_elements(COALESCE(key_dates, '[]'::jsonb)) AS t(elem)
        UNION
        SELECT elem FROM jsonb_array_elements(p_certain_dates) AS t(elem)
      ) sub
    ),
    parties = (
      SELECT jsonb_agg(DISTINCT elem)
      FROM (
        SELECT elem FROM jsonb_array_elements(COALESCE(parties, '[]'::jsonb)) AS t(elem)
        UNION
        SELECT elem FROM jsonb_array_elements(p_certain_parties) AS t(elem)
      ) sub
    ),
    open_questions = (
      SELECT jsonb_agg(DISTINCT v)
      FROM (
        SELECT v FROM jsonb_array_elements_text(COALESCE(open_questions, '[]'::jsonb)) AS t(v)
        UNION
        SELECT unnest(p_open_questions)
        UNION
        SELECT 'CONTRADICTION: ' || unnest(p_contradictions)
        UNION
        SELECT 'CLAIM: ' || unnest(p_legal_claims)
      ) sub
    ),
    updated_at = NOW()
  WHERE id = p_case_id;
END;
$$;
