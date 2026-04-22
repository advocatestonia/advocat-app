# Memory Tier 1 — integration patch (DEFERRED)

**Status:** NOT applied. Apply after `fix/post-launch-urgent`
(UX-FIX) merges to `main`.

**Why deferred:** UX-FIX is modifying `lib/services/system_prompts.dart`
(language detection) and `lib/services/voice_service.dart`, and touching
`lib/features/chat/screens/chat_screen.dart`. Landing the integration
patch on `feature/memory-tier1` now would guarantee a merge conflict.

This document is the full recipe for wiring Tier 1 into the live chat
pipeline once UX-FIX is out of the way. Every diff is specific and
minimal — the combined footprint is ~30 lines across 3 files plus 2
router entries.

---

## 1. Inject the memory block into the system prompt

**File:** `lib/services/system_prompts.dart`

**Where:** Inside `SystemPrompts.buildChatPrompt()`, after the per-case
context is appended and before the knowledge-base sections. Keep the
memory block *above* the knowledge sections so the model reads "who
you are talking to" before "what you know about Estonian law".

**Add a new parameter:**

```dart
static String buildChatPrompt({
  CaseType? caseType,
  String? country,
  String? nationality,
  String? caseContext,
  String? userLanguage,
  String? query,
  bool useReducedContext = false,
  String memoryBlock = '',        // ← NEW
}) {
```

**Add ~5 lines where the prompt is being built:**

```dart
// === WHAT WE KNOW ABOUT YOU === (ADR-001 Tier 1)
if (memoryBlock.isNotEmpty) {
  buf.writeln(memoryBlock);
  buf.writeln();
}
```

Place it **after** the case-context block and **before** the first
knowledge-base section (search for the first `=== ESTONIAN LAW ===`
or similar marker). The exact anchor depends on UX-FIX's final
version of the file.

## 2. Fetch + pass the memory block from ai_service.dart

**File:** `lib/services/ai_service.dart`

Before constructing the system prompt, fetch the user's memories and
format them. The `UserMemoryService.buildMemoryBlock` is static so we
don't need to reach through a provider.

```dart
// ── Add near the top of AiService.sendMessage / streamMessage ─────────
final memoryService = ref.read(userMemoryServiceProvider);
final memories = await memoryService.getMemories(limit: 20);
final memoryBlock = UserMemoryService.buildMemoryBlock(memories);

// ── Pass through to SystemPrompts.buildChatPrompt ─────────────────────
final systemPrompt = SystemPrompts.buildChatPrompt(
  caseType: ...,
  country: ...,
  caseContext: ...,
  userLanguage: ...,
  memoryBlock: memoryBlock,  // ← NEW
);
```

The fetch is cheap (one `select` against a small indexed table). If
latency ever becomes a concern, cache in-memory for the chat session.

## 3. Trigger extraction after the assistant finishes streaming

**File:** `lib/services/ai_service.dart`

At the end of the streaming handler — after the final chunk has been
written to Supabase — fire-and-forget the extractor. **Do not `await`**
— the user should never wait on us.

```dart
// ── After streaming is complete and message is persisted ──────────────
// Kick off extraction; do NOT await — it's best-effort.
unawaited(
  ref.read(userMemoryServiceProvider).extractFromSession(
        messages: recentMessages
            .map((m) => (role: m.role, content: m.content))
            .toList(),
        sessionId: caseId, // or session id, depending on your model
      ),
);
```

Guard with a minimum message count so we don't burn Haiku calls on
one-turn conversations:

```dart
if (recentMessages.length >= 4) {
  unawaited(ref.read(userMemoryServiceProvider).extractFromSession(...));
}
```

Import `dart:async` for `unawaited` if it isn't already imported.

## 4. Register the route

**File:** `lib/config/router.dart`

**Add to `AppRoutes`:**

```dart
static const String aiMemory = '/profile/ai-memory';
```

**Add to the `routes:` list** (place near `settings` and `subscription`
for symmetry):

```dart
GoRoute(
  path: AppRoutes.aiMemory,
  name: 'aiMemory',
  builder: (context, state) => const AiMemoryScreen(),
),
```

**Import at top of file:**

```dart
import '../features/profile/screens/ai_memory_screen.dart';
```

## 5. Surface the entry point in settings

**File:** `lib/features/settings/screens/settings_screen.dart`

Add a tile in the "Preferences" or "Privacy" section:

```dart
_SettingsTile(
  icon: AppIcons.psychology, // or Icons.memory
  title: 'AI memory',
  subtitle: 'Review and forget what the AI remembers about you',
  trailing: const Icon(
    AppIcons.chevronRight,
    color: AppColors.textTertiary,
  ),
  onTap: () => context.push(AppRoutes.aiMemory),
),
```

## 6. Add ARB localisation keys (RU/EN/ET/FI)

Once UX-FIX merges, the inline English copy in `ai_memory_screen.dart`
should move to ARB keys. Proposed key names:

```
aiMemoryTitle: "What we remember"
aiMemoryHeader: "These are facts the AI has picked up..."
aiMemoryEmpty: "The AI hasn't learned anything specific..."
aiMemoryForget: "Forget"
aiMemoryForgetConfirmTitle: "Forget this?"
aiMemoryForgetAll: "Forget everything"
aiMemoryForgetAllConfirmTitle: "Forget everything?"
aiMemoryForgetAllConfirmBody: "The assistant will lose every..."
aiMemoryConfidence: "Confidence {pct}% · {ago}"
aiMemorySettingsTile: "AI memory"
aiMemorySettingsSubtitle: "Review and forget what the AI remembers"
```

Add to all 17 `app_*.arb` files. The RU, ET, FI translations are the
critical ones for launch.

## Owner checklist (post-UX-FIX merge)

- [ ] Merge `feature/memory-tier1` into `main`.
- [ ] Apply diffs 1-5 above in a single PR titled
      `feat(memory): wire Tier 1 into chat pipeline`.
- [ ] Add ARB keys (diff 6) in the same PR.
- [ ] `supabase db push` to apply
      `20260423010000_user_ai_memory.sql`.
- [ ] `supabase functions deploy extract-memory`.
- [ ] Confirm `CLAUDE_API_KEY` is present for the `extract-memory`
      function (same secret already used by `claude-proxy`).
- [ ] Smoke: chat for 5+ turns, check `SELECT * FROM user_ai_memory
      WHERE user_id = '<you>'` returns 1-3 rows.
- [ ] Smoke: open Settings → AI memory, verify rows render and the
      forget flow deletes them.
- [ ] `./test/e2e/prod_smoke.sh` — expect 21/21 GREEN.
