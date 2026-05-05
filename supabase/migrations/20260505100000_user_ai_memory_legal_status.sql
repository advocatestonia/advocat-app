-- ============================================================================
-- ADR-001 Tier 1 — Expand bounded vocabulary with legal-status keys
-- Date: 2026-05-05
-- Ref: docs/learning/ADR-001-three-tier-learning.md
--      Visioning Council 2026-05-05 (memory = #1 priority)
--
-- BACKGROUND: 20260423010000_user_ai_memory.sql introduced the
-- `public.user_ai_memory` table with a 10-key bounded vocabulary. This
-- migration documents the expansion to 13 keys by adding three legal-status
-- keys that gate which body of law applies to the user:
--
--   • legal_status      — citizen | eu_citizen | 3rd_country | asylum_seeker
--                          | refugee | stateless | other
--   • nationality       — ISO country code (RU, EE, FI, …)
--   • residence_status  — permanent | temporary | humanitarian | undefined
--
-- The vocabulary itself lives in three files (Dart client + Deno Edge
-- Function + this migration's documentation comment). No DDL change is
-- required because `key` is a free-form `text` column — the bounded
-- vocabulary is enforced application-side by extract-memory's JSON
-- schema. This migration ONLY refreshes the column comment so future
-- readers do not have to chase three sources of truth.
--
-- IDEMPOTENT — `comment on column` overwrites unconditionally.
-- ============================================================================

comment on column public.user_ai_memory.key is
  'Bounded vocabulary (13 keys, 2026-05-05): name, tone, emotional_state, '
  'case_focus, known_party, deadline, user_goal, preference, background, '
  'discussed_topic, legal_status, nationality, residence_status. '
  'Keep in sync with extract-memory/memory_schema.ts ALLOWED_KEYS and '
  'lib/models/user_memory.dart kAllowedMemoryKeys. The legal_status / '
  'nationality / residence_status keys gate which body of law applies '
  '(Estonian Aliens Act, EU directives, civil/criminal) and are rendered '
  'in a dedicated section by UserMemoryService.buildMemoryBlock.';

-- ============================================================================
-- Idempotency self-check: a `comment on column` is overwrite-by-design.
-- Running this file a second time MUST be a no-op.
-- ============================================================================
