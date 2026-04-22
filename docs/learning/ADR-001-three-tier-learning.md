# ADR-001: Three-Tier Personal AI Memory & Learning

**Status:** Accepted — Tier 1 in implementation (2026-04-23)
**Owners:** Dmitri Sulga (product), OMEGA coordinator (execution)
**Related:** `lib/services/client_knowledge_service.dart` (current regex-based memory)

## Context

Today Advocat's chat has *session* memory (last N messages + per-case
documents + a regex-extracted `conversation_summaries` row). This gets the
AI through one conversation but does not survive across sessions in any
useful structured way:

- **Regex-based summaries** pick out dates and euro amounts, but nothing
  about the user themselves (tone, emotional state, goals, deadlines
  mentioned once).
- **Per-case context** is fetched fresh every chat. Global user facts
  ("prefers short responses", "anxious", "wife is Sofia") are lost.
- **No user-facing control.** Users cannot inspect or delete what the
  AI "remembers" about them — GDPR Art. 17 risk.

We want the AI to feel like a legal friend who remembers you, without
re-training the model or storing verbatim transcripts.

## Decision

Three tiers of learning, each with its own storage, update cadence, and
privacy surface.

### Tier 1 — Structured per-user memory (THIS ADR's scope)

- Table: `user_ai_memory(user_id, key, value jsonb, confidence, …)`.
- Extracted after each chat session by a small Haiku call (strict JSON
  schema, max 10 facts).
- Injected into the system prompt as a `=== WHAT WE KNOW ABOUT YOU ===`
  block before the per-case context.
- User can view and delete each fact (GDPR Art. 17, right to be
  forgotten). "Forget everything" button wipes all rows.
- Keys are a bounded vocabulary: `name`, `tone`, `emotional_state`,
  `case_focus`, `known_party`, `deadline`, `user_goal`, `preference`,
  `background`, `discussed_topic`.

### Tier 2 — Community patterns (FUTURE)

- Anonymised aggregate: "users with deportation cases often ask about
  Valtiokonttori compensation". Informs suggested-questions UI. Separate
  ADR when we build it.

### Tier 3 — Model-side fine-tuning (FUTURE)

- Periodic LoRA over successful chat transcripts to nudge tone/format.
  Out of scope until we have >10 K sessions.

## Consequences

**Positive**
- Feels personal across sessions without touching the model weights.
- One Haiku call per session (cheap: ~3K tokens, ~$0.001).
- Clean GDPR story: rows are structured, labelled, user-deletable.
- Does not break today's session memory — this is additive.

**Negative / trade-offs**
- One extra DB table + one extra Edge Function to operate.
- Haiku can hallucinate facts → confidence field + upsert-on-reinforcement
  mitigates, but we will review production output weekly for the first
  month.
- System prompt grows by ~200–500 tokens per user once populated.

## Rollout plan (Tier 1)

1. Migration `20260423010000_user_ai_memory.sql` (table + RLS).
2. Edge Function `extract-memory` (JWT-gated, rate-limited).
3. `UserMemoryService` in Flutter (fetch, format, delete).
4. Settings screen `/profile/ai-memory` for review + GDPR deletion.
5. **Integration patch (deferred until UX-FIX branch merges):**
   - Inject memory block in `system_prompts.dart buildChatPrompt()`.
   - Trigger `extractFromSession()` after streaming complete in
     `ai_service.dart`.

## Non-goals

- Does **not** replace `client_knowledge_service.dart`. That service is
  still the source of truth for *case* and *profile* context per chat.
- Does **not** change how `conversation_summaries` works. Tier 1 lives
  alongside it; the regex summary stays until we decide whether Haiku
  extraction fully covers the same ground.
