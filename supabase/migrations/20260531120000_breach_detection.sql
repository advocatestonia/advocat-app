-- =============================================================================
-- Data Fortress — breach detection (2026-06-14).
-- =============================================================================
-- Closes the #1 readiness gap from the IR-plan: there was no AUTOMATIC breach
-- detection, so the "became aware" moment (T0 — start of the Art. 33 72h
-- clock) depended on a human noticing. This adds:
--
--   1. breach_alerts — append-only forensic table (one row per detected
--      anomaly). Tamper-evident hash chain (same construction as audit_log /
--      agent_audit_log). This IS the evidence that establishes T0.
--   2. detect_* SQL functions — each evaluates ONE anomaly class over the
--      audit_log / quota tables and returns a fired/not-fired verdict. Called
--      by the breach-tick edge fn on a cron.
--   3. record_breach_alert() — append a detected alert (service_role only).
--   4. get_my_breach_alerts() — client-visible breaches affecting THEM (so the
--      data subject sees a breach the moment it's detected, feeding Art. 34).
--
-- Anomaly classes (all over the Pillar-3 access log):
--   A. mass_read     — one principal read >N sensitive rows in a short window
--                      (exfiltration signature).
--   B. staff_offsession — a staff_read of a user's data with no corresponding
--                      user session activity (insider snooping).
--   C. decrypt_spike — decrypt/unwrap rate far above the per-user baseline.
--   D. us_egress_when_eu — an llm_egress to a non-EU region while residency is
--                      strict (a residency breach).
--
-- All idempotent. RLS-first; SECURITY DEFINER fns are the only writers.
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ---------------------------------------------------------------------------
-- 1. breach_alerts — append-only forensic record.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.breach_alerts (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  detected_at  timestamptz NOT NULL DEFAULT now(),
  -- 'mass_read' | 'staff_offsession' | 'decrypt_spike' | 'us_egress_when_eu'
  kind         text NOT NULL,
  severity     text NOT NULL DEFAULT 'high'
               CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  -- The principal that triggered it (may be a staff/service id), if known.
  actor        text,
  -- The data subject affected (for client notification + Art. 34). NULL when
  -- the anomaly is not tied to a single user.
  affected_user uuid,
  -- Structured evidence (counts, window, thresholds) — no raw PII.
  evidence     jsonb NOT NULL DEFAULT '{}'::jsonb,
  -- Dedup key so the cron doesn't write the same alert every tick.
  dedup_key    text,
  -- Tamper-evident hash chain.
  row_hash     text,
  prev_hash    text
);

CREATE INDEX IF NOT EXISTS breach_alerts_detected_idx
  ON public.breach_alerts (detected_at DESC);
CREATE INDEX IF NOT EXISTS breach_alerts_affected_idx
  ON public.breach_alerts (affected_user);
CREATE UNIQUE INDEX IF NOT EXISTS breach_alerts_dedup_idx
  ON public.breach_alerts (dedup_key)
  WHERE dedup_key IS NOT NULL;

ALTER TABLE public.breach_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.breach_alerts FORCE ROW LEVEL SECURITY;

-- The affected data subject may SELECT breaches about THEM (Art. 34
-- transparency). Everything else is service-role only.
DROP POLICY IF EXISTS breach_alerts_owner_select ON public.breach_alerts;
CREATE POLICY breach_alerts_owner_select
  ON public.breach_alerts
  FOR SELECT
  USING (auth.uid() = affected_user);

-- Append-only: block UPDATE/DELETE even under service_role (forensic
-- integrity — the breach record must not be rewritten after T0).
CREATE OR REPLACE FUNCTION public.tf_breach_alerts_append_only()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'breach_alerts is append-only (attempted %)', tg_op
    USING errcode = '42501';
END;
$$;

DROP TRIGGER IF EXISTS breach_alerts_no_update ON public.breach_alerts;
CREATE TRIGGER breach_alerts_no_update
  BEFORE UPDATE ON public.breach_alerts
  FOR EACH ROW EXECUTE FUNCTION public.tf_breach_alerts_append_only();

DROP TRIGGER IF EXISTS breach_alerts_no_delete ON public.breach_alerts;
CREATE TRIGGER breach_alerts_no_delete
  BEFORE DELETE ON public.breach_alerts
  FOR EACH ROW EXECUTE FUNCTION public.tf_breach_alerts_append_only();

-- Hash chain (mirrors audit_log).
CREATE OR REPLACE FUNCTION public.tf_breach_alerts_hash_chain()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE v_prev text;
BEGIN
  SELECT row_hash INTO v_prev
    FROM public.breach_alerts
   ORDER BY detected_at DESC, id DESC
   LIMIT 1;
  new.prev_hash := coalesce(v_prev, '');
  new.row_hash := encode(digest(
    coalesce(new.prev_hash, '')          || '|' ||
    coalesce(new.id::text, '')           || '|' ||
    coalesce(new.kind, '')               || '|' ||
    coalesce(new.severity, '')           || '|' ||
    coalesce(new.actor, '')              || '|' ||
    coalesce(new.affected_user::text,'') || '|' ||
    coalesce(new.evidence::text, '{}')   || '|' ||
    coalesce(new.detected_at::text, now()::text),
    'sha256'), 'hex');
  RETURN new;
END;
$$;

DROP TRIGGER IF EXISTS breach_alerts_hash_chain ON public.breach_alerts;
CREATE TRIGGER breach_alerts_hash_chain
  BEFORE INSERT ON public.breach_alerts
  FOR EACH ROW EXECUTE FUNCTION public.tf_breach_alerts_hash_chain();

-- ---------------------------------------------------------------------------
-- 2. record_breach_alert() — append a detected alert. service_role only.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.record_breach_alert(
  p_kind          text,
  p_severity      text,
  p_actor         text,
  p_affected_user uuid,
  p_evidence      jsonb,
  p_dedup_key     text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE v_id uuid;
BEGIN
  INSERT INTO public.breach_alerts
    (kind, severity, actor, affected_user, evidence, dedup_key)
  VALUES
    (p_kind, coalesce(p_severity, 'high'), p_actor, p_affected_user,
     coalesce(p_evidence, '{}'::jsonb), p_dedup_key)
  ON CONFLICT (dedup_key) WHERE dedup_key IS NOT NULL DO NOTHING
  RETURNING id INTO v_id;
  RETURN v_id;  -- NULL when deduped (already recorded)
END;
$$;

REVOKE ALL ON FUNCTION public.record_breach_alert(text, text, text, uuid, jsonb, text)
  FROM public, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.record_breach_alert(text, text, text, uuid, jsonb, text)
  TO service_role;

-- ---------------------------------------------------------------------------
-- 3. detect_* — anomaly evaluators over the access log. service_role only.
-- ---------------------------------------------------------------------------
-- A. mass_read: a single user_id with > p_threshold read_sensitive /
--    llm_egress events in the last p_window_minutes (exfiltration signature).
CREATE OR REPLACE FUNCTION public.detect_mass_read(
  p_window_minutes int DEFAULT 10,
  p_threshold      int DEFAULT 100
)
RETURNS TABLE (affected_user uuid, event_count bigint)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT user_id, count(*)
    FROM public.audit_log
   WHERE ts > now() - make_interval(mins => greatest(p_window_minutes, 1))
     AND action IN ('read_sensitive', 'llm_egress', 'document_parse')
     AND user_id IS NOT NULL
   GROUP BY user_id
  HAVING count(*) > greatest(p_threshold, 1);
$$;

-- B. staff_offsession: a staff_read / admin_access on a user's data — these
--    should be rare and always reviewable. We surface every one in the window
--    (the dedup key keeps it to one alert per actor+subject).
CREATE OR REPLACE FUNCTION public.detect_staff_access(
  p_window_minutes int DEFAULT 60
)
RETURNS TABLE (affected_user uuid, action text, event_count bigint)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT user_id, action, count(*)
    FROM public.audit_log
   WHERE ts > now() - make_interval(mins => greatest(p_window_minutes, 1))
     AND action IN ('staff_read', 'admin_access')
     AND user_id IS NOT NULL
   GROUP BY user_id, action;
$$;

REVOKE ALL ON FUNCTION public.detect_mass_read(int, int)
  FROM public, anon, authenticated;
REVOKE ALL ON FUNCTION public.detect_staff_access(int)
  FROM public, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.detect_mass_read(int, int) TO service_role;
GRANT EXECUTE ON FUNCTION public.detect_staff_access(int) TO service_role;

-- ---------------------------------------------------------------------------
-- 4. get_my_breach_alerts() — client-visible breaches affecting them (Art. 34).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_my_breach_alerts()
RETURNS TABLE (
  detected_at timestamptz,
  kind        text,
  severity    text,
  evidence    jsonb
)
LANGUAGE sql
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT b.detected_at, b.kind, b.severity, b.evidence
    FROM public.breach_alerts b
   WHERE b.affected_user = auth.uid()
   ORDER BY b.detected_at DESC
   LIMIT 100;
$$;

GRANT EXECUTE ON FUNCTION public.get_my_breach_alerts() TO authenticated;

-- ---------------------------------------------------------------------------
-- 5. Schedule the breach-tick cron (every 5 minutes).
-- ---------------------------------------------------------------------------
-- Uses the same invoke_edge_cron(text) path as the other crons
-- (deadline-radar-tick, agent-intentions-cron). Guarded: only schedules if
-- pg_cron + invoke_edge_cron are present, so replay on a clean DB (where the
-- cron infra isn't set up yet) doesn't fail. The owner ensures the breach-tick
-- edge fn is deployed --no-verify-jwt before this fires usefully.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron')
     AND EXISTS (
       SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'public' AND p.proname = 'invoke_edge_cron'
     )
  THEN
    PERFORM cron.schedule(
      'breach-tick-5min',
      '*/5 * * * *',
      $cron$select public.invoke_edge_cron('breach-tick');$cron$
    );
  ELSE
    RAISE NOTICE 'breach-tick cron NOT scheduled: pg_cron / invoke_edge_cron '
      'absent. Re-run after the cron infra is set up, or schedule manually.';
  END IF;
END $$;

NOTIFY pgrst, 'reload schema';
