# Post-Launch UX Fixes — FINAL

**Date:** 2026-04-22
**Branch:** `fix/post-launch-urgent`
**Base:** `main` @ `356c9ee` (v24.2.3+)
**Author:** OMEGA-UX-FIX-URGENT (3 coder agents, sequential TDD)

---

## Summary — three post-launch UX bugs → three TDD fixes

Owner reported these three problems while testing v24.2.3 on advocat.ee
on 2026-04-22. All three are now fixed on the `fix/post-launch-urgent`
branch; tests added, no regressions, ready to merge + redeploy.

| # | Bug | Root cause | Fix | Tests |
|---|-----|-----------|-----|-------|
| 1 | AI replied in Russian when user wrote in Estonian | System prompt forced `MUST respond ONLY in <profileLang>` | Per-message language detector overrides profile when needed | 25 detector + 5 system-prompt |
| 2 | AI stopped speaking responses aloud | Expressive audio tags (`[warmth]`, `[thoughtful]`…) only stripped before ElevenLabs, broke Google / browser TTS | `VoiceService.stripExpressiveTags()` promoted to public, applied on every TTS path + defence-in-depth in chat UI | 8 tag-strip |
| 3 | New users had no hint how to start the conversation | Welcome message was generic; no quick-action categories | `ChatWelcomeChips` widget — 5 localised categories (deport / labour / family / housing / other) + skip | 16 category + widget |

**Totals:** 54 new tests, 0 Dart test regressions (1337 pass / 11 pre-existing fails, identical to baseline), 0 analyzer errors, web build succeeds.

---

## Bug 1 — language mismatch

### Symptom
Owner selected Russian during onboarding → asked the AI an Estonian
question → received Russian answer.

### Root cause
`lib/services/system_prompts.dart:430` built a `_languageInstruction`
section containing the absolute clause:

> You MUST respond ONLY in $langName. This is non-negotiable.

`userLanguage` came from `Localizations.localeOf(context).languageCode`
(profile preference set at onboarding) and was passed verbatim into the
prompt on every message. The softer "USE THE PERSON'S LANGUAGE NATURALLY"
personality rule was overridden by the harder directive.

### Fix
**New file:** `lib/services/language_detector.dart`

- `LanguageDetector.detect(text)` — keyword + script + accented-char
  heuristic covering the 17 app languages. Pure, deterministic, no deps.
  - Cyrillic dominant → `ru` (default) or `uk` if Ukrainian markers
    (`і ї є ґ`) present.
  - Arabic dominant → `ar` or `fa` if Persian letters (`پ چ ژ گ`) present.
  - Latin → keyword frequency score across all candidates, with
    accented-char tie-breakers (`õ`/`Õ` → Estonian, `å` → Swedish, etc.).
  - Returns `null` for <3-char input so the caller keeps the profile
    preference.
- `LanguageDetector.resolveUserLanguage(profileLanguage, message)` —
  the integration point. Keeps the profile when detection is ambiguous;
  overrides only when the current message is clearly a different
  language.

**Wiring:** `lib/services/ai_service.dart`

- `sendChatMessage` and `sendChatMessageStreaming` both now compute
  `effectiveUserLanguage = LanguageDetector.resolveUserLanguage(
  profileLanguage: userLanguage, message: sanitizedMessage)` and pass
  *that* (not the raw profile value) into `SystemPrompts.buildLight/Chat
  Prompt`.

**System-prompt softening:** `lib/services/system_prompts.dart`

- Old wording:
  > You MUST respond ONLY in $langName. This is non-negotiable.
- New wording:
  > DEFAULT RESPONSE LANGUAGE: $langName.
  > ALWAYS MATCH THE LANGUAGE OF THE USER'S CURRENT MESSAGE. If their
  > message is in Estonian ("tere", "sa oled", "aitäh", "palun") —
  > respond in Estonian. If in Russian ("привет", "спасибо",
  > "пожалуйста") — respond in Russian. …
- `buildLightPrompt` has the same softening applied.

### Tests
- `test/services/language_detection_test.dart` — 25 tests covering
  every supported language, mixed-script input, empty / too-short
  input, profile-override policy.
- `test/services/system_prompt_language_test.dart` — 5 tests pin the
  new wording so a future accidental revert will fail CI.

### Files touched
- **added** `lib/services/language_detector.dart`
- **added** `test/services/language_detection_test.dart`
- **added** `test/services/system_prompt_language_test.dart`
- **modified** `lib/services/ai_service.dart`
- **modified** `lib/services/system_prompts.dart`

Commit: `4a8d41e fix(chat): per-message language override (post-launch bug 1)`

---

## Bug 2 — voice stopped working

### Symptom
Owner: "AI stopped speaking responses. Before it spoke aloud, now it
just types."

### Root cause
`lib/services/system_prompts.dart` teaches Claude to insert Gemini-style
expressive audio tags (`[warmth]`, `[thoughtful]`, `[determination]`,
`[sigh]`, `[reassuring]`, …) before emotionally charged phrases.
Claude now uses them regularly in short v24.2.3 replies.

Only the ElevenLabs TTS path in `voice_service.dart:810` stripped those
tags. Every other engine — Google Chirp3-HD (used for Estonian,
Finnish, etc.) and the browser `SpeechSynthesis` fallback — received
the raw text and either read the literal `"[warmth] Tere, aitäh"` or
failed to synthesise (tag at the start tripped the service).

### Fix
`lib/services/voice_service.dart`

- Promoted the tag-strip regex into a public static helper:
  ```dart
  static String stripExpressiveTags(String text)
  ```
  Vocabulary matches 20 tags from `system_prompts.dart` (`warmth`,
  `thoughtful`, `determination`, `sigh`, `reassuring`, `whispers`,
  `laughs`, `excitement`, `enthusiasm`, `shouts`, `sarcastic`, `calm`,
  `confident`, `empathetic`, `serious`, `gentle`, `firm`, `curious`,
  `hopeful`, `concerned`). Case-insensitive. Preserves legal citations
  like `[section 26]` because they are not in the tag list.
- Applied it in:
  - `_speakWithGoogleTTS` — strip before sending to Chirp3-HD.
  - `_speakWithBrowserTts` — strip before browser SpeechSynthesis.
  - `_speakWithElevenLabs` — already stripped, now via the shared helper.
  - `speak()` entrypoint — defence-in-depth (parameter may bypass the
    caller-side clean if a new call site is added later).

`lib/features/chat/screens/chat_screen.dart`

- `_cleanTextForTTS` now calls `VoiceService.stripExpressiveTags` first,
  before its markdown cleanup. Belt-and-braces so debug logs show the
  real text that reaches the engine.

### Tests
`test/services/voice_tts_tag_strip_test.dart` — 8 tests:

- removes `[warmth]`, `[thoughtful]` tags at start, middle, multiple
- case-insensitive match (`[WARMTH]`, `[Thoughtful]`)
- every tag from the 20-item vocabulary gets stripped
- legal citations like `[section 26]` and `[HMS § 40]` are preserved
- leaves clean text unchanged
- empty input stays empty

### Files touched
- **modified** `lib/services/voice_service.dart`
- **modified** `lib/features/chat/screens/chat_screen.dart`
- **added** `test/services/voice_tts_tag_strip_test.dart`

Commit: `4bdf22e fix(voice): strip expressive tags for every TTS engine (bug 2)`

---

## Bug 3 — no onboarding questionnaire

### Symptom
Owner: "User registers → enters app → no question 'what is your
problem?' Needs quick buttons for popular case categories."

### Root cause
`_sendWelcomeMessage` in `chat_screen.dart:483` adds a single generic
assistant message (`"Hello! I am your legal assistant. Tell me what
happened…"`). No action chips, no category shortcuts. New users have to
guess what to ask.

### Fix
**New widget:** `lib/features/chat/widgets/welcome_chips.dart`

- `enum WelcomeCategory { deportation, workDispute, familyLaw, housing,
  other }` — five categories mapped to real `CaseType` enum values.
- `chipLabel(locale)` → localised chip label in 16 languages + English
  fallback.
- `prefillMessage(locale)` → natural-language starter in ru/et/en/fi
  (owner's 4 core markets) + English fallback for the remaining 13.
  Example:
  - `WelcomeCategory.deportation.prefillMessage('et')` →
    `"Vajan abi väljasaatmismenetlusega. Mida teha?"`
  - `WelcomeCategory.housing.prefillMessage('ru')` →
    `"У меня проблема с арендой жилья (депозит, договор, выселение)."`
- `icon` → `flight_takeoff` / `work_outline` / `family_restroom` /
  `home_outlined` / `help_outline` for quick visual scanning.
- `ChatWelcomeChips(locale, onCategorySelected, onSkip)` — stateless
  widget: `Wrap` of five `ChatActionChip`s plus a `Skip` text button.

**Integration:** `lib/features/chat/screens/chat_screen.dart`

- New state flag `bool _showWelcomeChips = false`.
- `_sendWelcomeMessage` sets it `true` (only called when `_messages.isEmpty`,
  i.e. brand-new case).
- `_buildMessageList` adds one trailing slot in the `ListView.builder`
  that renders `ChatWelcomeChips` directly under the welcome assistant
  message.
- `_onWelcomeCategoryPicked(cat, prefill)` — pre-fills the input with
  the localised starter, waits 350 ms so the user can see the text,
  then auto-sends via `_sendMessage`. Hides the chips.
- `_onWelcomeSkip` — hides the chips, no side effects.
- `_sendMessage` also hides chips unconditionally on any manual send —
  they disappear the moment the user types their own starter.

### Combined effect with Bug 1
A user with profile=ru who taps the Estonian chip "Väljasaatmine"
gets:

1. Bug 3: input pre-fills with `"Vajan abi väljasaatmismenetlusega. Mida teha?"`
2. Bug 3: auto-send fires after 350 ms.
3. Bug 1: language detector reads "Vajan abi… mida teha" → returns `et` → overrides the `ru` profile for this message.
4. System prompt tells Claude: default Russian, but **match current
   Estonian message** → Claude answers in Estonian.

Behaviour now matches user intent end-to-end.

### Tests
`test/features/chat/welcome_chips_test.dart` — 16 tests:

- 7 unit tests — category → `CaseType` mapping, count = 5.
- 6 prefill tests — every category has non-empty prefill in ru/et/en/fi,
  unknown locale falls back to English, Russian/Estonian/Finnish/English
  strings contain expected substrings.
- 3 widget tests — renders 5 chips + skip, chip tap fires
  `onCategorySelected` with correct prefill, skip tap fires `onSkip`.

### Files touched
- **added** `lib/features/chat/widgets/welcome_chips.dart`
- **added** `test/features/chat/welcome_chips_test.dart`
- **modified** `lib/features/chat/screens/chat_screen.dart`

Commit: `4b76947 fix(chat): first-conversation category chips (bug 3)`

---

## Regression baseline

### Dart tests
```
Before: 1283 pass, 11 pre-existing fails, 12 skipped
After:  1337 pass, 11 pre-existing fails (identical), 12 skipped
Delta:  +54 new tests, 0 regressions
```

The 11 pre-existing failures all sit in
`test/services/schema_drift_fix_test.dart` (FIX-3) and
`test/services/gdpr_delete_rls_test.dart` (FIX-2) — unrelated to any
of the three bugs and unchanged by this branch.

### Static analysis
```
flutter analyze: 0 errors, 53 info/warning — all pre-existing.
```

### Build
```
flutter build web --release: ✓ Built build/web  (37 s)
```

### Deno (Edge Functions)
```
Before and after: 74 pass, 27 pre-existing fails (identical).
```

These fixes do not touch any Edge Function — no deploy-side change
needed.

---

## Commands for the owner — merge + redeploy

```bash
cd /Users/ai.place/Advocat/app/advocat_project

# Optional: preview the diff
git log --oneline main..fix/post-launch-urgent
# 4b76947 fix(chat): first-conversation category chips (bug 3)
# 4bdf22e fix(voice): strip expressive tags for every TTS engine (bug 2)
# 4a8d41e fix(chat): per-message language override (post-launch bug 1)

# Merge the fix branch into main (keeps the three commits)
git checkout main
git merge --no-ff fix/post-launch-urgent -m "merge: post-launch UX fixes (bugs 1, 2, 3)"

# Push to github
git push github main

# Redeploy to gh-pages (advocat.ee)
./scripts/build-and-deploy.sh
```

### Post-deploy smoke test

1. Open advocat.ee in incognito, register a fresh account with Russian
   profile.
2. After login, go to `/chat/new` — you should see the welcome message
   **plus** five chips: Депортация / Трудовой спор / Семейное право /
   Аренда жилья / Другое, and a "Пропустить" link below.
3. Click "Семейное право" → message should pre-fill then auto-send;
   AI reply should arrive in Russian.
4. In the same chat, type an Estonian question: `"Kas mul on õigus
   lahutust taotleda?"` → AI should reply in Estonian (bug 1
   verification).
5. With volume on, trigger a reply that begins with `[warmth]` or
   `[reassuring]` (easy — ask a distressing question like `"Minu
   päev oli kohutav"`) — voice should speak the cleaned reply
   without reading `[warmth]` out loud (bug 2 verification).

---

## Worktree note (for the session log)

During the session the git HEAD was being flipped to `feature/memory-tier1`
by a parallel background process whenever a commit landed. Two of the
three bug fixes (1 and 2) were committed on `fix/post-launch-urgent`
before the flip caught up. Bug 3 was completed in an isolated worktree
at `/tmp/advocat-fix` where the parallel process could not reach:

```bash
git worktree add /tmp/advocat-fix fix/post-launch-urgent
cd /tmp/advocat-fix
# edit, test, commit — then worktree list to remove when done
```

All three commits are on the same branch head, verified via
`git log --oneline main..fix/post-launch-urgent`.
