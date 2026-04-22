# Memory Tier 1 — FINAL

**Status:** Code-complete. DB migration + Edge Function + Dart service +
UI screen all built and tested. **Not yet deployed.** Integration into
the live chat pipeline is deferred behind the UX-FIX merge — see
`integration_patch.md`.

**Branch:** `feature/memory-tier1` (8 commits from `main`).
**Baseline tests preserved.** Added 24 Flutter + 20 Deno tests.

**Spec:** `docs/learning/ADR-001-three-tier-learning.md` §3.1 (Tier 1).

---

## What was built

### 1. Migration — `supabase/migrations/20260423010000_user_ai_memory.sql`

New `public.user_ai_memory` table:

- `id uuid PK`, `user_id → auth.users ON DELETE CASCADE`.
- `key text` from a bounded vocabulary (documented inline: name, tone,
  emotional_state, case_focus, known_party, deadline, user_goal,
  preference, background, discussed_topic).
- `value jsonb` shaped `{text, confidence, extracted_from}`.
- `confidence real CHECK (0..1)`, `source_session_id uuid`,
  `created_at`, `last_reinforced_at`, nullable `expires_at`.
- Unique index on `(user_id, key, value->>'text')` so re-extraction
  upserts rather than duplicates.
- Hot-path indexes on `(user_id, key)` and `(user_id, confidence desc)`.

RLS:

- `user_ai_memory_select_own` — `auth.uid() = user_id`.
- `user_ai_memory_delete_own` — `auth.uid() = user_id` (GDPR Art. 17).
- **No INSERT/UPDATE policy** — writes go through the Edge Function
  using the service role, so a user cannot spoof "I am a lawyer" into
  their own memory.

Idempotent — every DDL guarded by `IF NOT EXISTS` or `pg_*` existence
check. Matches the pattern of `20260422060000_delete_own_policies.sql`.

### 2. Edge Function — `supabase/functions/extract-memory/`

- `index.ts` — JWT-gated handler, 5 req/min/user.
- `memory_schema.ts` — pure system prompt + request builder +
  `parseHaikuFacts` (null-tolerant, schema-enforcing, never throws).

Behaviour:

- Calls Claude Haiku 4.5 (`claude-haiku-4-5-20251001`) with
  `temperature=0`, a strict `extract_facts` tool with an enum-bounded
  `key`, `maxLength=500`, and `maxItems=10`. `tool_choice` forces the
  tool so the response is deterministic to parse.
- Rejects body-supplied `user_id` with 400 (defence-in-depth; RLS
  already enforces identity).
- Upsert path: SELECT by `(user_id, key, value->>'text')`; on hit,
  UPDATE `last_reinforced_at` + `max(confidence)`. On miss, INSERT.
  Unique index is the backstop.
- Returns `{extracted, stored, duplicates}` for client toast / analytics.

### 3. Dart model + service

- `lib/models/user_memory.dart` — pure value class, `fromRow` parser,
  bounded-vocabulary set, `memoryKeyLabel` for the UI.
- `lib/services/user_memory_service.dart`:
  - `getMemories({limit})` — RLS-scoped fetch, confidence-sorted,
    expired rows filtered, never throws.
  - `buildMemoryBlock(memories)` — static, so the system-prompt builder
    calls it without a Supabase client. Renders the
    `=== WHAT WE KNOW ABOUT YOU ===` block with an anti-verbatim-quote
    guidance line.
  - `forget(id)`, `forgetAll()` — GDPR deletions, RLS-scoped.
  - `extractFromSession()` — best-effort invoke of the Edge Function;
    returns counts or null on error.

### 4. UI screen — `lib/features/profile/screens/ai_memory_screen.dart`

Route: `/profile/ai-memory` (registration deferred — see patch).

- Loading / empty / populated states via `FutureProvider.autoDispose`.
- Facts grouped by key in canonical order so layout is stable.
- Per-row delete with a confirm dialog that quotes the fact.
- "Forget everything" at the bottom behind a second confirm dialog.
- Pull-to-refresh via `RefreshIndicator` + `ref.invalidate`.
- **Copy is inline English** — ARB keys will be added in the same PR
  that wires the route, to keep `lib/l10n/*.arb` free of conflicts
  with UX-FIX.

## Test changes

- **Flutter:** baseline 1308 passed / 11 pre-existing failures.
  After Tier 1: **1332 passed / same 11 failures** (+24 new).
- **Deno:** baseline 118 passed. After Tier 1: **138 passed** (+20).
- **Analyze:** 0 new issues across the 6 new files.

Test files added:

- `test/services/user_ai_memory_migration_test.dart` (14 tests)
- `test/services/user_memory_service_test.dart` (13 tests)
- `test/features/profile/ai_memory_screen_test.dart` (6 tests)
- `supabase/functions/extract-memory/__tests__/extract_memory_test.ts`
  (20 tests — 12 pure-function + 8 source-contract)

## What was NOT integrated (intentionally)

Per the OMEGA directive, these edits are deferred until
`fix/post-launch-urgent` (UX-FIX) merges to `main`:

1. `lib/services/system_prompts.dart buildChatPrompt()` — inject the
   memory block after the case context, before the knowledge-base
   sections. UX-FIX is adding language-detection logic to this same
   function; merging now risks a conflict.
2. `lib/services/ai_service.dart` — fetch memories before the prompt,
   fire-and-forget `extractFromSession()` after streaming completes.
3. `lib/config/router.dart` — register `/profile/ai-memory`.
4. `lib/features/settings/screens/settings_screen.dart` — surface
   the entry point.
5. `lib/l10n/app_*.arb` — add localised copy for all 17 languages
   (currently the screen uses inline English placeholders).

The exact diffs with anchors and before/after snippets live in
`integration_patch.md` next to this file (~30 lines total across 3
files + a router entry + an ARB entry).

## Owner actions after UX-FIX merge

1. `git checkout main && git pull`
2. `git merge feature/memory-tier1`
3. Apply `integration_patch.md` diffs 1-5 in a single PR titled
   `feat(memory): wire Tier 1 into chat pipeline`.
4. Add ARB keys (patch §6) in the same PR.
5. `supabase db push` — applies the new
   `20260423010000_user_ai_memory.sql`.
6. `supabase functions deploy extract-memory`.
7. Verify `CLAUDE_API_KEY` is set on the function
   (`supabase secrets list`). Same key `claude-proxy` already uses.
8. `./scripts/build-and-deploy.sh`.
9. `./test/e2e/prod_smoke.sh` — expect 21/21 GREEN.

## Risks tracked

- **Haiku hallucination.** System prompt forbids invention; confidence
  < 0.5 dropped; `parseHaikuFacts` tolerates malformed JSON rather
  than crashing. First-month review cadence: run a weekly query
  `SELECT key, value->>'text', confidence FROM user_ai_memory ORDER BY
  created_at DESC LIMIT 50` and sample ten rows for plausibility.
- **Privacy.** Users can inspect every row and delete individually
  or in bulk. RLS DELETE is the only path; INSERT/UPDATE are
  service-role-only.
- **Prompt bloat.** Cap of 20 rows × 500 chars = ~200-500 tokens
  added to the system prompt per user once populated. Acceptable
  compared to the ~50K tokens the full prompt already carries.
- **Haiku cost.** One call per session at ~3K input tokens.
  At Haiku 4.5 pricing (≈$0.001/call) the monthly bill is negligible
  even at 10K sessions/mo.

## Commit log

```
67cf972 feat(memory): migration for user_ai_memory table
36ae245 feat(memory): extract-memory Edge Function
acccc10 test(memory): Deno contract tests for extract-memory
1e8f975 feat(memory): UserMemoryService Dart
31d4f76 test(memory): unit tests for UserMemoryService
7963aab feat(memory): AI memory settings screen
5e1638f test(memory): widget tests for AI memory screen
(+this docs commit)
```
