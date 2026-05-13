-- =============================================================================
-- ab_assignments + ab_events — server-side persistence for A/B experiments.
-- =============================================================================
-- Two tables, both small and append-only-friendly:
--
--   ab_assignments
--     Sticky bucket per (user, experiment). One row per user-experiment pair.
--     `variant` is a free-form short string (e.g. 'v1', 'v2', 'control_a').
--     We do not store weights — that's a property of the experiment config,
--     not the assignment.
--
--   ab_events
--     Append-only event stream. Records exposure, CTA clicks, signup,
--     subscribe, etc. Tied to (user, experiment) so we can join with
--     `subscriptions` for attribution analysis.
--
-- Both tables are RLS-restricted: a user can only see/insert their own rows.
-- Edge functions running with the service role bypass RLS.
--
-- For the `pricing` experiment specifically the analyst flow is:
--   SELECT
--     a.variant,
--     COUNT(DISTINCT a.user_id)                            AS users,
--     COUNT(DISTINCT e_view.user_id)                       AS views,
--     COUNT(DISTINCT e_click.user_id)                      AS clicks,
--     COUNT(DISTINCT e_signup.user_id)                     AS signups
--   FROM ab_assignments a
--     LEFT JOIN ab_events e_view   ON e_view.user_id = a.user_id
--                                  AND e_view.experiment = a.experiment
--                                  AND e_view.event = 'pricing_view'
--     LEFT JOIN ab_events e_click  ON e_click.user_id = a.user_id
--                                  AND e_click.experiment = a.experiment
--                                  AND e_click.event = 'pricing_cta_click'
--     LEFT JOIN ab_events e_signup ON e_signup.user_id = a.user_id
--                                  AND e_signup.experiment = a.experiment
--                                  AND e_signup.event = 'signup_attributed'
--   WHERE a.experiment = 'pricing'
--   GROUP BY a.variant;
-- =============================================================================

-- ── ab_assignments ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.ab_assignments (
  user_id      uuid        NOT NULL,
  experiment   text        NOT NULL CHECK (char_length(experiment) BETWEEN 1 AND 64),
  variant      text        NOT NULL CHECK (char_length(variant)    BETWEEN 1 AND 32),
  created_at   timestamptz NOT NULL DEFAULT now(),
  -- Sticky bucket: exactly one row per (user, experiment).
  PRIMARY KEY (user_id, experiment)
);

COMMENT ON TABLE  public.ab_assignments IS 'Sticky variant per (user, experiment) — append-on-first-touch.';
COMMENT ON COLUMN public.ab_assignments.experiment IS 'Experiment key — must match AbExperiment.known on the client.';
COMMENT ON COLUMN public.ab_assignments.variant    IS 'Variant label, e.g. v1, v2, control_a — opaque to the table.';

-- ── ab_events ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.ab_events (
  id           bigserial   PRIMARY KEY,
  user_id      uuid        NOT NULL,
  experiment   text        NOT NULL CHECK (char_length(experiment) BETWEEN 1 AND 64),
  variant      text        NOT NULL CHECK (char_length(variant)    BETWEEN 1 AND 32),
  event        text        NOT NULL CHECK (char_length(event)      BETWEEN 1 AND 64),
  occurred_at  timestamptz NOT NULL DEFAULT now(),
  metadata     jsonb       NOT NULL DEFAULT '{}'::jsonb
);

COMMENT ON TABLE public.ab_events IS 'Append-only A/B exposure + interaction stream. Joined to ab_assignments for funnel analysis.';

-- Standard analytics indexes. We do not need a per-row unique constraint —
-- the same user can record the same event multiple times (e.g. multiple CTA
-- clicks); deduplication is the analyst's job.
CREATE INDEX IF NOT EXISTS ab_events_experiment_event_occurred_idx
  ON public.ab_events (experiment, event, occurred_at DESC);

CREATE INDEX IF NOT EXISTS ab_events_user_experiment_idx
  ON public.ab_events (user_id, experiment, occurred_at DESC);

-- ── RLS ─────────────────────────────────────────────────────────────────────
ALTER TABLE public.ab_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ab_events      ENABLE ROW LEVEL SECURITY;

-- Read own rows.
DROP POLICY IF EXISTS ab_assignments_select_own ON public.ab_assignments;
CREATE POLICY ab_assignments_select_own
  ON public.ab_assignments
  FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS ab_events_select_own ON public.ab_events;
CREATE POLICY ab_events_select_own
  ON public.ab_events
  FOR SELECT
  USING (auth.uid() = user_id);

-- Insert only own rows.
DROP POLICY IF EXISTS ab_assignments_insert_own ON public.ab_assignments;
CREATE POLICY ab_assignments_insert_own
  ON public.ab_assignments
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS ab_events_insert_own ON public.ab_events;
CREATE POLICY ab_events_insert_own
  ON public.ab_events
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- No UPDATE/DELETE policies — both tables are effectively append-only.
-- Service-role can still mutate (bypasses RLS) for admin cleanup.

-- ── Sanity guard: variant cardinality stays small ──────────────────────────
-- Not a constraint, just a comment for future readers. If you find yourself
-- adding many variants for one experiment, you probably want a new
-- experiment key instead.
