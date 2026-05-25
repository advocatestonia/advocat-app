-- 20260525200000_email_triage_lawyer_opinions.sql
-- ----------------------------------------------------------------------------
-- Phase 2 — wire 15-lawyer consilium into email-triage.
--
-- When EMAIL_TRIAGE_USE_CONSILIUM=true, supabase/functions/email-triage
-- routes the model call through the consilium pipeline
-- (supabase/functions/_shared/consilium.ts). Each lawyer's `role_opinion`
-- SSE payload is captured into a JSONB array and persisted here for audit.
--
-- Shape (one element per lawyer):
--   {
--     "role_id":        text,
--     "role_name":      text,
--     "opinion":        text,    -- 1-2 sentence summary, ≤ 400 chars
--     "position":       text,    -- push|settle|investigate|out_of_scope|unknown
--     "confidence":     number|null,
--     "key_citation":   text|null
--   }
--
-- NULL on the legacy single-Sonnet path (flag off OR pre-2026-05-25 rows).
-- Empty array `[]` on consilium runs where no role produced an opinion.
-- ----------------------------------------------------------------------------

alter table public.email_triage_results
    add column if not exists lawyer_opinions jsonb null;

comment on column public.email_triage_results.lawyer_opinions is
    'Per-lawyer audit payloads captured from the consilium SSE role_opinion '
    'events when EMAIL_TRIAGE_USE_CONSILIUM=true. NULL on the legacy '
    'single-Sonnet triage path. See migration '
    '20260525200000_email_triage_lawyer_opinions.sql for shape.';
