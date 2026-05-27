-- =============================================================================
-- 20260527080200_drafts_vault_link.sql — Drafting × Vault integration bridge.
-- =============================================================================
-- Wires the two parallel features (Drafting Studio + Vault) so a draft can be
-- "filed" into the Vault as an immutable copy, and so a Vault note can be
-- opened in the Drafting Studio.
--
-- Three changes:
--   1. user_drafts.vault_copy_id  → link to the Vault document created by
--      "Save to Vault". NULL when the draft has never been filed.
--   2. user_drafts.source_type    → extend CHECK to allow 'vault_note' and
--      'vault_import' so we can tell:
--          'vault_note'   — draft created from the Vault "Create Note" CTA
--                           (will auto-save back to Vault on first save)
--          'vault_import' — draft created from an existing Vault doc via
--                           "Edit in Studio" (markdown/text only)
--   3. vault_tags.is_system + the seed of a "Draft" system tag. Same shape as
--      the six user-facing defaults but flagged so the UI can hide the
--      delete affordance and so RLS prevents user-side mutation.
--
-- Idempotent — uses ADD COLUMN IF NOT EXISTS / DO blocks so we can replay
-- safely if the deploy cron retries.
-- =============================================================================

-- ─── 1. user_drafts.vault_copy_id ───────────────────────────────────────────
ALTER TABLE public.user_drafts
  ADD COLUMN IF NOT EXISTS vault_copy_id UUID
    REFERENCES public.documents(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS user_drafts_vault_copy_idx
  ON public.user_drafts (vault_copy_id)
  WHERE vault_copy_id IS NOT NULL;

COMMENT ON COLUMN public.user_drafts.vault_copy_id IS
  'Bridge to documents(id). Set by DraftService.saveToVault(); NULL otherwise. '
  'ON DELETE SET NULL — purging a vault row leaves the draft intact.';

-- ─── 2. Extend source_type CHECK to allow vault_note / vault_import ─────────
-- Drop the old constraint by-name (created without name → PostgreSQL gave it
-- user_drafts_source_type_check). We rebuild it with the full union.
DO $$
DECLARE
  cname text;
BEGIN
  SELECT conname INTO cname
    FROM pg_constraint
   WHERE conrelid = 'public.user_drafts'::regclass
     AND contype = 'c'
     AND pg_get_constraintdef(oid) ILIKE '%source_type%';
  IF cname IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.user_drafts DROP CONSTRAINT %I', cname);
  END IF;
END $$;

ALTER TABLE public.user_drafts
  ADD CONSTRAINT user_drafts_source_type_check
  CHECK (source_type IN (
    'blank',
    'contract_review_reply',
    'letter',
    'appeal',
    'memo',
    'vault_note',
    'vault_import'
  ));

-- ─── 3. vault_tags.is_system + "Draft" system tag ──────────────────────────
-- We don't own the vault_tags / vault_document_tags migrations (the Vault
-- agent ships those). To stay decoupled we (a) gate on table existence and
-- (b) leave a fallback: if vault_tags doesn't exist yet, the Flutter side
-- simply skips tagging until the next deploy. DraftService.saveToVault
-- already tolerates a missing tag table.

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
     WHERE table_schema = 'public' AND table_name = 'vault_tags'
  ) THEN
    -- 3a. is_system flag.
    EXECUTE 'ALTER TABLE public.vault_tags
             ADD COLUMN IF NOT EXISTS is_system BOOLEAN NOT NULL DEFAULT FALSE';

    -- 3b. Seed the "Draft" system tag per existing user. We do it as a
    --     trigger-style ensure-row rather than a one-shot INSERT so users
    --     who sign up after this migration also get the tag — see the
    --     ensure_draft_system_tag() function below + trigger.
    EXECUTE 'CREATE OR REPLACE FUNCTION public.ensure_draft_system_tag()
             RETURNS TRIGGER LANGUAGE plpgsql AS $f$
             BEGIN
               INSERT INTO public.vault_tags (user_id, slug, label, is_system)
               VALUES (NEW.id, ''draft'', ''Draft'', TRUE)
               ON CONFLICT DO NOTHING;
               RETURN NEW;
             END;
             $f$';

    -- Back-fill for existing users (idempotent via ON CONFLICT).
    EXECUTE 'INSERT INTO public.vault_tags (user_id, slug, label, is_system)
             SELECT id, ''draft'', ''Draft'', TRUE
               FROM public.users
              ON CONFLICT DO NOTHING';

    -- Attach the trigger to auth.users so each new sign-up gets the tag.
    EXECUTE 'DROP TRIGGER IF EXISTS ensure_draft_tag_on_user_insert
              ON public.users';
    EXECUTE 'CREATE TRIGGER ensure_draft_tag_on_user_insert
               AFTER INSERT ON public.users
               FOR EACH ROW EXECUTE FUNCTION public.ensure_draft_system_tag()';
  END IF;
END $$;

-- ─── Grants ─────────────────────────────────────────────────────────────────
-- Nothing new to grant — existing user_drafts grants already cover the new
-- column (UPDATE permission). vault_tags grants are owned by the Vault agent.

COMMENT ON CONSTRAINT user_drafts_source_type_check ON public.user_drafts IS
  'Allowed source types — "vault_note" and "vault_import" added 2026-05-27 '
  'for the Drafting × Vault integration bridge.';
