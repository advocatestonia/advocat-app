-- ============================================================================
-- ADR-001 Tier 1 — Structured per-user AI memory
-- Date: 2026-04-23
-- Ref: docs/learning/ADR-001-three-tier-learning.md
--
-- PROBLEM: conversation_summaries stores regex-extracted text (dates,
-- euro amounts) but nothing about the user themselves (tone, emotional
-- state, goals, known parties). Global user facts are lost between
-- sessions, so the AI feels like a new assistant every conversation.
--
-- FIX: Introduce `public.user_ai_memory` — one row per
-- (user_id, key, value) fact, extracted by the Haiku-powered
-- `extract-memory` Edge Function after each session. Users can inspect
-- and delete rows themselves (GDPR Art. 17).
--
-- This migration is IDEMPOTENT — wrapped in `if not exists` guards and
-- DO blocks for policies, matching the pattern in
-- 20260422060000_delete_own_policies.sql. Safe to apply multiple times.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Table
-- ---------------------------------------------------------------------------

create table if not exists public.user_ai_memory (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  -- Bounded vocabulary — keep in sync with extract-memory schema:
  --   name, tone, emotional_state, case_focus, known_party, deadline,
  --   user_goal, preference, background, discussed_topic.
  key text not null,
  -- {text: "...", confidence: 0.9, extracted_from: "session_id"}.
  value jsonb not null,
  confidence real not null default 0.5
    check (confidence >= 0 and confidence <= 1),
  -- Optional link to the chat session (e.g. first chat_messages.id of
  -- the window we extracted from). Nullable because Haiku may infer
  -- facts that span the whole session.
  source_session_id uuid,
  created_at timestamptz not null default now(),
  last_reinforced_at timestamptz not null default now(),
  -- Nullable — set when the fact is time-bound (e.g. a court date that
  -- passes). The fetch layer filters `expires_at is null or expires_at > now()`.
  expires_at timestamptz
);

-- Uniqueness: one row per (user, key, extracted text). Using the JSONB
-- value->>'text' keeps the constraint stable even when confidence is
-- reinforced. Duplicate extractions should UPDATE `last_reinforced_at`
-- not INSERT.
do $$
begin
  if not exists (
    select 1 from pg_indexes
    where schemaname = 'public'
      and tablename  = 'user_ai_memory'
      and indexname  = 'user_ai_memory_user_key_text_uniq'
  ) then
    create unique index user_ai_memory_user_key_text_uniq
      on public.user_ai_memory (user_id, key, (value->>'text'));
  end if;
end$$;

-- Hot-path indexes — list by user and sort by confidence descending.
create index if not exists idx_user_ai_memory_user_key
  on public.user_ai_memory (user_id, key);
create index if not exists idx_user_ai_memory_user_confidence
  on public.user_ai_memory (user_id, confidence desc);

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

alter table public.user_ai_memory enable row level security;

-- SELECT own rows only. The Edge Function uses the service role so it
-- bypasses this and can write on behalf of any user (after its own
-- JWT check).
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename  = 'user_ai_memory'
      and policyname = 'user_ai_memory_select_own'
  ) then
    create policy "user_ai_memory_select_own"
      on public.user_ai_memory
      for select
      using (auth.uid() = user_id);
  end if;
end$$;

-- DELETE own rows (GDPR Art. 17 — right to erasure).
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename  = 'user_ai_memory'
      and policyname = 'user_ai_memory_delete_own'
  ) then
    create policy "user_ai_memory_delete_own"
      on public.user_ai_memory
      for delete
      using (auth.uid() = user_id);
  end if;
end$$;

-- NB: intentionally NO insert/update policy for the anon/authenticated
-- role. Only the Edge Function (service role) may write — this stops
-- a user spoofing "I am a lawyer" into their own memory.

-- ---------------------------------------------------------------------------
-- Documentation comment (visible in Supabase Studio)
-- ---------------------------------------------------------------------------

comment on table public.user_ai_memory is
  'ADR-001 Tier 1 — structured per-user facts extracted by Haiku from '
  'chat sessions. One row per (user_id, key, value->>''text''). Users '
  'can select/delete their own rows (GDPR Art. 17). Writes are '
  'service-role only, via the extract-memory Edge Function.';

comment on column public.user_ai_memory.key is
  'Bounded vocabulary: name, tone, emotional_state, case_focus, '
  'known_party, deadline, user_goal, preference, background, '
  'discussed_topic. Keep in sync with extract-memory/index.ts schema.';

comment on column public.user_ai_memory.value is
  'JSONB payload. Required shape: {"text": string, "confidence": 0..1, '
  '"extracted_from": string (session id)}. Unique index on '
  '(user_id, key, value->>''text'').';

comment on column public.user_ai_memory.last_reinforced_at is
  'Bumped by the Edge Function on upsert when the same (user, key, '
  'text) triple is re-extracted. Used by the fetch layer to rank '
  'recently reinforced facts higher.';

-- ============================================================================
-- Idempotency self-check: every DDL above is guarded by IF NOT EXISTS or
-- a pg_* lookup. Running this file a second time MUST be a no-op.
-- ============================================================================
