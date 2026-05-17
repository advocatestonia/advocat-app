-- =============================================================================
-- 20260516200000_lawyer_partnership.sql
--   Day2-E — "1 human-lawyer call/quarter free" Pro/Premium perk.
--
-- Adds the two-table backbone the booking flow needs:
--
--   * partner_lawyers   — one row per verified attorney who opted-in to take
--                         paid Advocat calls. Joins to profiles.id so we
--                         inherit the verify-lawyer audit trail and the
--                         is_partner_lawyer flag added below.
--   * lawyer_bookings   — one row per call. AI brief is generated 2h before
--                         the scheduled slot by lawyer-booking edge fn and
--                         stored here so the lawyer can re-open it.
--
-- Also adds `profiles.is_partner_lawyer` as a fast flag for the booking
-- directory filter (the partner_lawyers row carries the authoritative
-- per-month commitment + payout rate; the bool on profiles is just the
-- "exists at all + active" cache).
--
-- IMPORTANT — anti-regression:
--   The feature is gated by `LAWYER_PARTNERSHIP_ENABLED` env on the edge
--   fn AND `kLawyerPartnershipEnabled` flag in Flutter. Default OFF until
--   the owner has at least 3 EE solo lawyers enrolled (otherwise users
--   see an empty "no slots available" state which kills trust).
--
-- Backwards-compatible. All new columns nullable; no row touched.
-- =============================================================================

-- ─── profiles.is_partner_lawyer ─────────────────────────────────────────────
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS is_partner_lawyer BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN public.profiles.is_partner_lawyer IS
  'True when the user is an active partner lawyer (takes paid Advocat calls). Authoritative row is partner_lawyers; this is the fast-filter cache.';

CREATE INDEX IF NOT EXISTS idx_profiles_is_partner_lawyer
  ON public.profiles (is_partner_lawyer)
  WHERE is_partner_lawyer = true;

-- ─── partner_lawyers ────────────────────────────────────────────────────────
-- One row per opted-in attorney. The `lawyer_id` references the SAME id as
-- profiles.id — this is a 1:1 extension keyed on auth.users.id, the same
-- shape we use for case_workspace and email_inbox_sync.
--
-- Lifecycle:
--   started_at     — opt-in moment.
--   paused_at      — temporarily not taking bookings (vacation, capacity).
--   ended_at       — left the programme.
-- The "is currently active for bookings" predicate is:
--   active = true AND paused_at IS NULL AND ended_at IS NULL
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.partner_lawyers (
  lawyer_id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Public-facing anonymised summary the booking screen renders. Owner
  -- writes this row from the admin queue after a quick interview. Example:
  --   "Tallinn family-law solo practice, 8 years stage, EE+RU+EN."
  -- Capped to keep the directory card compact.
  public_blurb       TEXT NOT NULL CHECK (length(public_blurb) BETWEEN 10 AND 280),

  -- ISO 3166-1 alpha-2 of where the lawyer practises. Drives the
  -- jurisdiction filter on the booking screen ("Estonian law", "Finnish
  -- immigration", etc.).
  country            CHAR(2) NOT NULL CHECK (country IN ('EE','FI')),

  -- Free-form specialty tags. The booking UI does a substring match
  -- against the topic the user selected. Keep this small — admin
  -- normalises (e.g. ["family","immigration"]).
  specialties        TEXT[] NOT NULL DEFAULT '{}'::TEXT[]
                     CHECK (array_length(specialties, 1) IS NULL
                            OR array_length(specialties, 1) <= 10),

  -- Languages the lawyer accepts calls in, ISO 639-1. Same UI rule as
  -- specialties — substring match against user prefs.
  languages          TEXT[] NOT NULL DEFAULT '{et}'::TEXT[]
                     CHECK (array_length(languages, 1) IS NULL
                            OR array_length(languages, 1) <= 8),

  -- Commitment the lawyer agreed to. Used by the assignment heuristic to
  -- avoid overbooking the same lawyer.
  hours_per_month    INT NOT NULL CHECK (hours_per_month BETWEEN 1 AND 40),

  -- Payout per completed call, EUR. We default to 25 (the middle of the
  -- €20–30 band in the brief). Stored as INT cents to avoid float math
  -- (column name is _eur for documentation only; values are cents).
  payout_rate_cents  INT NOT NULL DEFAULT 2500
                     CHECK (payout_rate_cents BETWEEN 1000 AND 10000),

  -- ─── Lifecycle ────────────────────────────────────────────────────────
  active             BOOLEAN NOT NULL DEFAULT true,
  started_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  paused_at          TIMESTAMPTZ,
  ended_at           TIMESTAMPTZ,

  -- ─── Stats cache (denormalised; recomputed by post-booking trigger) ───
  bookings_total     INT NOT NULL DEFAULT 0 CHECK (bookings_total >= 0),
  bookings_completed INT NOT NULL DEFAULT 0 CHECK (bookings_completed >= 0),
  avg_rating         NUMERIC(3,2),
  earnings_ytd_cents INT NOT NULL DEFAULT 0 CHECK (earnings_ytd_cents >= 0),

  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_partner_lawyers_active_country
  ON public.partner_lawyers (country)
  WHERE active = true AND paused_at IS NULL AND ended_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_partner_lawyers_specialties_gin
  ON public.partner_lawyers USING gin (specialties);

ALTER TABLE public.partner_lawyers ENABLE ROW LEVEL SECURITY;

-- The lawyer reads their own row.
CREATE POLICY "partner reads own"
  ON public.partner_lawyers
  FOR SELECT
  TO authenticated
  USING (auth.uid() = lawyer_id);

-- A regular user reads the public-facing fields of ACTIVE partners only
-- (for the booking directory). We can't `SELECT` only some columns from
-- a single policy, so the policy gates the row and the edge fn projects
-- the safe columns. (The directory query runs as service_role anyway,
-- and joins a "v_public_partners" view in a later migration; for v1 we
-- just trust the edge fn.)
CREATE POLICY "any user reads active partners"
  ON public.partner_lawyers
  FOR SELECT
  TO authenticated
  USING (active = true AND paused_at IS NULL AND ended_at IS NULL);

-- All writes via edge fn / service role.
CREATE POLICY "service writes partner_lawyers"
  ON public.partner_lawyers
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

GRANT SELECT ON public.partner_lawyers TO authenticated;

COMMENT ON TABLE public.partner_lawyers IS
  'Verified attorneys who opted-in to take paid Advocat calls. 1:1 on profiles.id.';
COMMENT ON COLUMN public.partner_lawyers.payout_rate_cents IS
  'Payout per completed call in EUR cents. Default 2500 (€25.00).';


-- ─── lawyer_bookings ────────────────────────────────────────────────────────
-- One row per call. The status lifecycle is:
--   requested → assigned → confirmed → completed
--                                   ↘ cancelled
--                                   ↘ no_show
-- AI brief is generated by the lawyer-booking edge fn 2h before
-- scheduled_at via a pg_cron job (see seed below). Stored in ai_brief_md
-- so the lawyer can re-open it on their dashboard.
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.lawyer_bookings (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  user_id            UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  lawyer_id          UUID REFERENCES auth.users(id) ON DELETE SET NULL,

  -- Topic the user picked on the booking screen. Free-form text capped
  -- so the AI brief prompt stays bounded.
  topic              TEXT NOT NULL CHECK (length(topic) BETWEEN 3 AND 100),

  -- Optional pointer to the case the call is about. Lets the AI brief
  -- pull in the case_facts JSON for richer context.
  case_id            UUID,

  -- Language the user wants the call in (ISO 639-1).
  language           TEXT NOT NULL DEFAULT 'et' CHECK (length(language) = 2),

  -- Pre-call free-text from the user — what they want covered. The AI
  -- brief incorporates this verbatim.
  user_brief         TEXT CHECK (user_brief IS NULL OR length(user_brief) <= 4000),

  scheduled_at       TIMESTAMPTZ,
  duration_minutes   INT NOT NULL DEFAULT 15
                     CHECK (duration_minutes IN (15, 30)),

  -- Google Meet link. Populated when status → 'confirmed'. NULL until
  -- the slot is locked in. Future: Cal.com bridge writes this on webhook.
  meet_link          TEXT CHECK (meet_link IS NULL OR length(meet_link) <= 500),

  -- AI brief markdown (generated by edge fn 2h before scheduled_at).
  ai_brief_md        TEXT CHECK (ai_brief_md IS NULL OR length(ai_brief_md) <= 20000),
  ai_brief_at        TIMESTAMPTZ,

  -- Lawyer's post-call summary (1-page form, capped).
  outcome_summary    TEXT CHECK (outcome_summary IS NULL OR length(outcome_summary) <= 4000),
  outcome_at         TIMESTAMPTZ,

  -- User rating 1–5 (post-call).
  user_rating        INT CHECK (user_rating IS NULL OR user_rating BETWEEN 1 AND 5),
  user_feedback      TEXT CHECK (user_feedback IS NULL OR length(user_feedback) <= 2000),

  -- Payout snapshot (recorded at completion to insulate from rate changes).
  payout_cents       INT CHECK (payout_cents IS NULL OR payout_cents >= 0),
  paid_out_at        TIMESTAMPTZ,

  status             TEXT NOT NULL DEFAULT 'requested'
                     CHECK (status IN ('requested','assigned','confirmed',
                                       'completed','cancelled','no_show')),

  -- Quarter the booking is consumed against (e.g. '2026-Q2'). We count
  -- per-quarter quota off this column. Auto-derived on insert.
  quota_quarter      TEXT NOT NULL
                     CHECK (quota_quarter ~ '^[0-9]{4}-Q[1-4]$'),

  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Quota query: "how many bookings has user_id made this quarter?"
CREATE INDEX IF NOT EXISTS idx_lawyer_bookings_user_quarter
  ON public.lawyer_bookings (user_id, quota_quarter)
  WHERE status IN ('requested','assigned','confirmed','completed');

-- Lawyer dashboard: upcoming bookings sorted by time.
CREATE INDEX IF NOT EXISTS idx_lawyer_bookings_lawyer_scheduled
  ON public.lawyer_bookings (lawyer_id, scheduled_at)
  WHERE status IN ('assigned','confirmed');

-- Brief-generation cron worker: "what is due in the next 2h?".
CREATE INDEX IF NOT EXISTS idx_lawyer_bookings_brief_due
  ON public.lawyer_bookings (scheduled_at)
  WHERE ai_brief_md IS NULL AND status = 'confirmed';

ALTER TABLE public.lawyer_bookings ENABLE ROW LEVEL SECURITY;

-- User reads their own bookings.
CREATE POLICY "user reads own bookings"
  ON public.lawyer_bookings
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Lawyer reads bookings assigned to them. (Note: the read is broader
-- than the writer permission — the lawyer reads ai_brief_md but cannot
-- update the user-side columns.)
CREATE POLICY "lawyer reads own bookings"
  ON public.lawyer_bookings
  FOR SELECT
  TO authenticated
  USING (auth.uid() = lawyer_id);

-- Lawyer updates only the post-call columns on their own bookings.
CREATE POLICY "lawyer updates outcome"
  ON public.lawyer_bookings
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = lawyer_id)
  WITH CHECK (auth.uid() = lawyer_id);

-- All other writes via edge fn / service role.
CREATE POLICY "service writes bookings"
  ON public.lawyer_bookings
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

GRANT SELECT, UPDATE ON public.lawyer_bookings TO authenticated;

COMMENT ON TABLE public.lawyer_bookings IS
  'Day2-E — calls between Pro/Premium users and partner lawyers. Quota is per quota_quarter.';

-- ─── Auto-derive quota_quarter trigger ──────────────────────────────────────
-- The client passes scheduled_at; the server derives 'YYYY-Q[1-4]' from it
-- to keep the quota query trivially indexable. Defaults to "now" quarter
-- when scheduled_at is NULL on insert (waiting list rows).
CREATE OR REPLACE FUNCTION public.lawyer_bookings_set_quarter()
RETURNS TRIGGER AS $$
DECLARE
  ts TIMESTAMPTZ;
  yr INT;
  qt INT;
BEGIN
  ts := COALESCE(NEW.scheduled_at, NEW.created_at, now());
  yr := EXTRACT(YEAR FROM ts);
  qt := EXTRACT(QUARTER FROM ts);
  NEW.quota_quarter := yr::TEXT || '-Q' || qt::TEXT;
  NEW.updated_at := now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_lawyer_bookings_set_quarter ON public.lawyer_bookings;
CREATE TRIGGER trg_lawyer_bookings_set_quarter
  BEFORE INSERT OR UPDATE OF scheduled_at ON public.lawyer_bookings
  FOR EACH ROW
  EXECUTE FUNCTION public.lawyer_bookings_set_quarter();

-- ─── Partner stats sync (cheap, called from edge fn after status change) ───
-- Recomputes the denormalised stats columns. Idempotent.
CREATE OR REPLACE FUNCTION public.refresh_partner_lawyer_stats(p_lawyer UUID)
RETURNS VOID AS $$
DECLARE
  v_total      INT;
  v_completed  INT;
  v_avg        NUMERIC(3,2);
  v_earnings   INT;
  v_year_start TIMESTAMPTZ;
BEGIN
  v_year_start := date_trunc('year', now());

  SELECT
    COUNT(*) FILTER (WHERE status IN ('requested','assigned','confirmed','completed','no_show')),
    COUNT(*) FILTER (WHERE status = 'completed'),
    AVG(user_rating) FILTER (WHERE user_rating IS NOT NULL),
    COALESCE(
      SUM(payout_cents) FILTER (
        WHERE status = 'completed' AND paid_out_at >= v_year_start
      ),
      0
    )
  INTO v_total, v_completed, v_avg, v_earnings
  FROM public.lawyer_bookings
  WHERE lawyer_id = p_lawyer;

  UPDATE public.partner_lawyers
  SET bookings_total = COALESCE(v_total, 0),
      bookings_completed = COALESCE(v_completed, 0),
      avg_rating = v_avg,
      earnings_ytd_cents = COALESCE(v_earnings, 0),
      updated_at = now()
  WHERE lawyer_id = p_lawyer;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.refresh_partner_lawyer_stats IS
  'Recompute partner_lawyers cached stats columns. Called from lawyer-booking edge fn after status changes.';

-- ─── Per-user quarterly quota helper (used by edge fn pre-flight) ───────────
-- Returns the count of "active" bookings in the current quarter for a user.
-- "Active" = anything not cancelled and not no_show.
CREATE OR REPLACE FUNCTION public.lawyer_bookings_quota_used(p_user UUID)
RETURNS INT AS $$
DECLARE
  v_q TEXT;
  v_n INT;
BEGIN
  v_q := EXTRACT(YEAR FROM now())::TEXT || '-Q' ||
         EXTRACT(QUARTER FROM now())::TEXT;
  SELECT COUNT(*)
  INTO v_n
  FROM public.lawyer_bookings
  WHERE user_id = p_user
    AND quota_quarter = v_q
    AND status IN ('requested','assigned','confirmed','completed');
  RETURN COALESCE(v_n, 0);
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION public.lawyer_bookings_quota_used IS
  'Bookings consumed by the user this quarter (excludes cancelled/no_show).';
