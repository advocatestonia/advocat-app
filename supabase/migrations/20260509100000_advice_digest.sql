-- Add advice_digest column to user_cases
ALTER TABLE user_cases ADD COLUMN IF NOT EXISTS advice_digest JSONB DEFAULT '[]';

-- RPC to append an entry (never overwrites, always appends)
CREATE OR REPLACE FUNCTION append_advice_digest(
  p_case_id UUID,
  p_entry   JSONB
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE user_cases
  SET advice_digest = COALESCE(advice_digest, '[]'::jsonb) || jsonb_build_array(p_entry),
      updated_at = NOW()
  WHERE id = p_case_id;
END;
$$;
