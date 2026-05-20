-- 20260520121540_extend_user_oauth_tokens.sql
-- ----------------------------------------------------------------------------
-- Extend public.user_oauth_tokens with three columns required by the
-- OAuth-honesty rollout (audit 2026-05-20):
--
--   * `scope`            — space-separated OAuth scopes actually granted by
--                          Google. Required at runtime so we can tell apart a
--                          `gmail.send`-only token from one that also has
--                          `gmail.readonly` (different processor vs controller
--                          GDPR posture and different feature surfaces).
--
--   * `last_sync_at`     — last successful Gmail inbox sync for this token,
--                          written by the email-inbox-sync edge function.
--                          Powers the honest UI state "connected, last sync 3h
--                          ago" instead of an opaque "connected".
--
--   * `last_sync_error`  — message of the most recent sync error; NULL when
--                          the last attempt succeeded. Powers the honest UI
--                          state "connected but sync failing — re-auth".
--
-- All additions are IF NOT EXISTS / additive. Existing rows get NULL values,
-- which is fine because every pre-existing row is for a stale OAuth flow that
-- did not capture scope anyway (per audit findings).
--
-- Plus: composite index on (user_id, provider) to support the upsert path in
-- oauth-callback (onConflict: user_id,provider) and the read path in
-- send-email / email-inbox-sync (lookup by both keys).
-- ----------------------------------------------------------------------------

ALTER TABLE public.user_oauth_tokens
  ADD COLUMN IF NOT EXISTS scope text,
  ADD COLUMN IF NOT EXISTS last_sync_at timestamptz,
  ADD COLUMN IF NOT EXISTS last_sync_error text;

COMMENT ON COLUMN public.user_oauth_tokens.scope IS
  'Space-separated OAuth scopes actually granted by provider. Required for verifying gmail.readonly vs gmail.send capabilities at runtime.';
COMMENT ON COLUMN public.user_oauth_tokens.last_sync_at IS
  'Last successful inbox sync for this token. Updated by email-inbox-sync edge fn.';
COMMENT ON COLUMN public.user_oauth_tokens.last_sync_error IS
  'Last sync error message, NULL when last attempt succeeded. Used for honest UI state.';

CREATE INDEX IF NOT EXISTS idx_user_oauth_tokens_user_provider
  ON public.user_oauth_tokens (user_id, provider);
