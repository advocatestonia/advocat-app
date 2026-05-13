-- =============================================================================
-- 20260514130000_drafting_studio.sql — Pkg 7 Drafting Studio MVP.
-- =============================================================================
-- Two tables that together back the in-app legal draft editor:
--
--   user_drafts     — the working document (markdown + plaintext mirror,
--                     language, jurisdiction, status). Autosaved every 30s
--                     by the Flutter editor, and pre-filled from Contract
--                     Review when the user clicks "Draft a reply".
--   draft_versions  — snapshot history. Capped to last 10 by an after-insert
--                     trigger; AI revisions flagged so we can show a small
--                     sparkle marker in the version list.
--
-- Deferred to v2 (NOT in this migration):
--   - Full track-changes UI (we keep the snapshot, no diff metadata yet)
--   - Multi-user collaboration (no shared_with table)
--   - Comment threads (no draft_comments table)
-- =============================================================================

-- ─── user_drafts: the working document ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_drafts (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Optional case scoping. We do NOT FK to user_cases because the same
  -- editor can be used for blank / case-less drafts (e.g. ad-hoc memo).
  case_id          UUID,

  -- Where the draft came from. Drives the integration UI (e.g. the
  -- "Reply to [counterparty]" title for contract_review_reply).
  source_type      TEXT NOT NULL DEFAULT 'blank'
                   CHECK (source_type IN (
                     'blank',
                     'contract_review_reply',
                     'letter',
                     'appeal',
                     'memo'
                   )),
  -- Optional pointer back to the originating row (e.g. contract_reviews.id).
  -- Free-form UUID; no FK because the source table varies by source_type.
  source_id        UUID,

  -- Body. We persist markdown as the source of truth and mirror plaintext
  -- for cheap full-text search later (no tsvector index in this MVP).
  title            TEXT,
  content_markdown TEXT NOT NULL DEFAULT '',
  content_plaintext TEXT NOT NULL DEFAULT '',

  -- ISO-639-1 (et, fi, en, …) and ISO-3166-alpha2 (EE, FI, …).
  language         TEXT,
  jurisdiction     TEXT,

  status           TEXT NOT NULL DEFAULT 'draft'
                   CHECK (status IN ('draft', 'finalized', 'sent', 'archived')),

  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Free-form bag for editor-side state (cursor position, last AI
  -- instruction, export-format preference, etc).
  metadata         JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS user_drafts_user_idx
  ON public.user_drafts (user_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS user_drafts_case_idx
  ON public.user_drafts (case_id)
  WHERE case_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS user_drafts_source_idx
  ON public.user_drafts (source_type, source_id)
  WHERE source_id IS NOT NULL;

ALTER TABLE public.user_drafts ENABLE ROW LEVEL SECURITY;

-- Owner-only access. Service role bypasses RLS via SUPABASE_SERVICE_ROLE_KEY.
DROP POLICY IF EXISTS "user_drafts_owner_all" ON public.user_drafts;
CREATE POLICY "user_drafts_owner_all"
  ON public.user_drafts
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- updated_at touch trigger — keeps the index above honest for sort-by-recent.
CREATE OR REPLACE FUNCTION public.touch_user_drafts_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS user_drafts_touch_updated_at ON public.user_drafts;
CREATE TRIGGER user_drafts_touch_updated_at
  BEFORE UPDATE ON public.user_drafts
  FOR EACH ROW EXECUTE FUNCTION public.touch_user_drafts_updated_at();

-- ─── draft_versions: snapshot history (last 10 per draft) ───────────────────
CREATE TABLE IF NOT EXISTS public.draft_versions (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  draft_id         UUID NOT NULL REFERENCES public.user_drafts(id) ON DELETE CASCADE,

  -- Snapshot of content_markdown at save time. Plain markdown — when
  -- restoring we replay it into content_markdown and rebuild plaintext
  -- on the client.
  content_snapshot TEXT NOT NULL,

  -- True if this snapshot was created by accepting an AI revision (vs a
  -- normal autosave or manual save). Drives the sparkle icon in the
  -- version-history list.
  ai_revision      BOOLEAN NOT NULL DEFAULT false,

  -- Free-form metadata: AI instruction text, selection range, etc.
  metadata         JSONB NOT NULL DEFAULT '{}'::jsonb,

  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS draft_versions_draft_idx
  ON public.draft_versions (draft_id, created_at DESC);

ALTER TABLE public.draft_versions ENABLE ROW LEVEL SECURITY;

-- Read access: only the draft's owner. Versions are append-only via the
-- service role from inside the autosave path; clients never INSERT directly.
DROP POLICY IF EXISTS "draft_versions_owner_select" ON public.draft_versions;
CREATE POLICY "draft_versions_owner_select"
  ON public.draft_versions
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_drafts d
      WHERE d.id = draft_versions.draft_id
        AND d.user_id = auth.uid()
    )
  );

-- Owner can insert versions (the Flutter client writes them directly on
-- AI-revision accept and on manual "Save snapshot"). Service role bypasses.
DROP POLICY IF EXISTS "draft_versions_owner_insert" ON public.draft_versions;
CREATE POLICY "draft_versions_owner_insert"
  ON public.draft_versions
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.user_drafts d
      WHERE d.id = draft_versions.draft_id
        AND d.user_id = auth.uid()
    )
  );

-- ─── Cap version history at 10 per draft ────────────────────────────────────
-- We keep the trigger simple: after each insert, delete the oldest rows
-- beyond the 10-row window for that draft. ON CASCADE handles the
-- draft-deletion path.
CREATE OR REPLACE FUNCTION public.cap_draft_versions()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  DELETE FROM public.draft_versions
   WHERE draft_id = NEW.draft_id
     AND id NOT IN (
       SELECT id FROM public.draft_versions
        WHERE draft_id = NEW.draft_id
        ORDER BY created_at DESC
        LIMIT 10
     );
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS draft_versions_cap ON public.draft_versions;
CREATE TRIGGER draft_versions_cap
  AFTER INSERT ON public.draft_versions
  FOR EACH ROW EXECUTE FUNCTION public.cap_draft_versions();

-- ─── Grants ─────────────────────────────────────────────────────────────────
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_drafts TO authenticated;
GRANT SELECT, INSERT ON public.draft_versions TO authenticated;

COMMENT ON TABLE public.user_drafts IS
  'Pkg 7 Drafting Studio MVP — user-owned legal draft documents (markdown).';
COMMENT ON TABLE public.draft_versions IS
  'Pkg 7 Drafting Studio MVP — snapshot history (capped at last 10 per draft).';
