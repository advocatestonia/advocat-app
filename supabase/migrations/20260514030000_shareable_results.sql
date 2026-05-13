-- 20260514030000_shareable_results.sql
-- -----------------------------------------------------------------------------
-- Shareable, anonymized previews of Contract Review / Legal Advice outputs.
--
-- Product flow:
--   1. User clicks "Share this analysis" on a Contract Review or major chat
--      AI answer.
--   2. The `share-result` edge function runs a two-stage PII redaction
--      (regex + Haiku) over the original output and writes one row here.
--   3. A public URL `https://advocat.ee/s/<share_slug>` renders the redacted
--      preview + a CTA "try with your own contract — first one free".
--   4. Friends signing up via the share page get attributed back to the
--      original sharer via the `signup_attributions` counter (incremented
--      by the signup handler when it sees the `advocat_share_referrer`
--      cookie / localStorage entry).
--
-- Privacy invariants (enforced in code, audited here):
--   * `redacted_content` MUST NOT contain personal names, addresses, phone,
--     email, case numbers, or small private-company names. The redactor
--     replaces every such token with placeholders ([NAME], [ADDR], [PHONE],
--     [EMAIL], [CASE_NO], [ORG_PRIVATE]). Public organisations and statute
--     references stay.
--   * `jurisdiction`, `case_type`, and rounded monetary amounts are
--     preserved — they're the marketing payload.
--   * `is_public` defaults to true; users can flip to false to take a share
--     down. `expires_at` defaults to NOW()+90d to bound liability.
--
-- RLS:
--   * Non-expired, public rows are world-readable (anon role) so the
--     `/s/<slug>` page can render without a session.
--   * Owners (auth.uid() = user_id) can SELECT/UPDATE/DELETE their own
--     rows in any state for the "My shares" panel.
--
-- Source-of-truth foreign key:
--   * `source_id` is intentionally NOT a FK constraint — it can point at
--     contract_reviews.id OR case_messages.id OR case_deadlines.id depending
--     on source_type. The edge function verifies ownership against the
--     appropriate table before insert.
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.shared_results (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             uuid REFERENCES auth.users(id) ON DELETE SET NULL,

  -- 8-char nanoid (case-sensitive) used in the public URL. Unique across
  -- the table; the edge function retries on collision (probability < 1e-9
  -- per insert at the current scale, so retries are virtually never hit).
  share_slug          text UNIQUE NOT NULL,

  -- What kind of output was shared. Drives the page template + the
  -- redactor's per-source heuristics.
  source_type         text NOT NULL
                      CHECK (source_type IN (
                        'contract_review',
                        'legal_advice',
                        'deadline_analysis'
                      )),
  source_id           uuid,

  -- Marketing payload.
  title               text NOT NULL,
  insight_summary     text NOT NULL,
  jurisdiction        text,                   -- 'EE', 'FI', 'EU', null
  case_type           text,                   -- 'dealer agreement', 'NDA', …

  -- The actual anonymised content. Free-form JSON: {bullets: [...],
  -- risks: [...], statute_refs: [...]}. Schema is enforced in code, not DB.
  redacted_content    jsonb NOT NULL,

  -- Optional OG image (PNG, ~1200x630) generated for nice link previews.
  og_image_url        text,

  -- Analytics counters. Both are incremented by the edge fn; never set by
  -- clients directly (no RLS UPDATE policy grants this column).
  view_count          int NOT NULL DEFAULT 0,
  signup_attributions int NOT NULL DEFAULT 0,

  created_at          timestamptz NOT NULL DEFAULT now(),
  expires_at          timestamptz NOT NULL DEFAULT (now() + INTERVAL '90 days'),
  is_public           boolean NOT NULL DEFAULT true
);

-- ── Indexes ────────────────────────────────────────────────────────────────
-- Public-page lookup. The slug is already UNIQUE; this index is implicit
-- via the UNIQUE constraint but we name it explicitly for clarity.
CREATE INDEX IF NOT EXISTS idx_shared_results_slug
  ON public.shared_results (share_slug);

-- "My shares" panel — list newest first.
CREATE INDEX IF NOT EXISTS idx_shared_results_user
  ON public.shared_results (user_id, created_at DESC);

-- Background expirer task (future) — partial index on still-public rows.
CREATE INDEX IF NOT EXISTS idx_shared_results_expires
  ON public.shared_results (expires_at)
  WHERE is_public = true;

-- ── RLS ────────────────────────────────────────────────────────────────────
ALTER TABLE public.shared_results ENABLE ROW LEVEL SECURITY;

-- Public read of non-expired, public rows — the `/s/<slug>` page needs no
-- session. We do NOT expose user_id directly via this policy; the edge fn
-- selects only marketing columns.
DROP POLICY IF EXISTS "public reads non-expired" ON public.shared_results;
CREATE POLICY "public reads non-expired"
  ON public.shared_results
  FOR SELECT
  TO anon, authenticated
  USING (is_public = true AND expires_at > now());

-- Owners can manage their own rows (incl. expired ones, so they can renew
-- via the "My shares" panel).
DROP POLICY IF EXISTS "owner manages own shares" ON public.shared_results;
CREATE POLICY "owner manages own shares"
  ON public.shared_results
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ── Grants ─────────────────────────────────────────────────────────────────
-- INSERT is server-side only (edge fn uses service role). We grant SELECT
-- to anon/authenticated so the public-preview path works.
GRANT SELECT ON public.shared_results TO anon, authenticated;

COMMENT ON TABLE public.shared_results IS
  'Anonymized public previews of Contract Review / legal advice outputs. Served at /s/<share_slug>. Redaction performed server-side by share-result edge fn (two-stage: regex + Haiku). See lesson_sulga_three_identity_errors for the privacy invariants this table must uphold.';
