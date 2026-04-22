# AI Quality — fix/ai-quality final report

**Branch:** `fix/ai-quality`  
**Scope:** two bugs reported by owner against the Advocat AI assistant.  
**NOT deployed.** No PR created. Owner decides next step.

---

## Bugs

### Bug 1 — file attachments never reach the AI

Users pick a document (PDF / image / txt) with the chat attach button.
The AI keeps answering about the file name, unable to see any content.

### Bug 2 — AI cannot answer short

Yes/no questions, list requests, and one-line commands trigger 3–5
paragraph essays.  Users want length that matches the shape of the
question.

(Bug 3 from owner — RU/ET grammar slips — was bundled with Bug 2's fix
since the root-cause guess was prompt-level, not model-level.)

---

## Root causes

### Bug 1

In `lib/features/chat/screens/chat_screen.dart` `_pickAndAttachFile` did:

```
final result = await FilePicker.platform.pickFiles(
  withData: kIsWeb, // bytes only on web
);
…
String attachLabel = 'Document attached: $fileName';
_sendMessage(attachLabel);
```

Three problems stacked:

1. `withData: kIsWeb` means on iOS/Android/macOS the picker returns a
   path but no bytes, so even if downstream code tried to read the
   content it could not.
2. Nothing ever reads or uploads the file.  `attachLabel` is a plain
   string with only the filename — Claude receives that string, nothing
   else.  No attachment record, no document id, no body.
3. Upstream `read_document` / `analyze_contract` tools *do* exist and
   *do* accept a `document_id`, but the picker never produced one.

### Bug 2

- `SystemPrompts.buildChatPrompt` stitches together ~30 KB of
  personality / capability rules but has **no** explicit instruction
  about short answers.  Rule #5 says "keep responses short — 3–5
  sentences" but rule #18 demands "always end complex responses with a
  natural next-step offer" which pushes every reply up to at least two
  paragraphs.
- `ClaudeService.maxTokensForModel` returns 800 (Haiku) / 2500 (Sonnet)
  flat.  A one-word "yes" answer gets 2500 tokens of budget.
- `isSimpleQuery` exists but only catches greetings / meta — it does
  NOT catch "Yes or no: can I appeal?" which is both simple in shape
  and complex in content.

### Bug 3 (grammar)

- The language instruction (`_languageInstruction`) pins the output
  language but never tells the model to proofread.  Claude Sonnet 4 /
  Haiku 4.5 write good RU / ET natively, but without an explicit
  "grammatically correct, proofread before sending" directive the
  cheapest paths default to whatever first draft the sampler produces.

---

## What was changed

### Fix 1 — `ChatAttachmentService` (commit `00c6cfe`)

`lib/services/chat_attachment_service.dart` (new) — a stateless
helper that turns a picked file into either:

- **txt / md / csv / json** → UTF-8 decoded, first 200 KB inlined into
  the chat message so Claude sees the body directly.
- **pdf / jpg / png / webp / heic** → caller first uploads bytes via
  `SupabaseService.uploadDocument`, the resulting `document_id` is
  baked into an AI-visible instruction to call the existing
  `read_document` tool.
- **unsupported** → localized user-facing explanation.

`lib/features/chat/screens/chat_screen.dart` `_pickAndAttachFile` now:

- requests bytes on every platform (`withData: true`);
- uses the classification service;
- uploads binary attachments to Supabase and propagates the id;
- sends an AI-visible message that contains actual content OR an
  explicit `read_document(document_id=…)` instruction.

All user-facing strings localized for ET / EN / RU (matches the three
languages already branched in the attach bottom sheet).

### Fix 2 — adaptive response length (commit `0a75581`)

`lib/services/claude_service.dart`:

- new `isShortQuery(String)` — detects yes/no questions, list
  requests, and direct commands in EN / RU / ET / FI.  Explicit
  verbosity markers (`in detail`, `подробно`, `üksikasjalikult`, …)
  override to full length.
- new `maxTokensForShortQuery()` returning **200**.
- Dart regex note: `\b` is ASCII-only, so we use `(\s|$)` after
  Cyrillic / Estonian tokens and enable `unicode: true` on those
  patterns.  Input is lowercased before matching because
  `caseSensitive: false` only folds ASCII.

`lib/services/ai_service.dart` — both the non-streaming and streaming
chat paths consult `isShortQuery` and clamp `max_tokens` to 200 when
it returns true.

`lib/services/system_prompts.dart`:

- new private constant `_adaptiveLength` with the ADAPTIVE RESPONSE
  LENGTH section.  Injected right after `_rules` in
  `buildChatPrompt`.
- `buildLightPrompt` (used by greetings / meta) also gets the
  directive so the fast path produces short answers.

### Fix 3 — grammar reinforcement (same commit `0a75581`)

`lib/services/system_prompts.dart`:

- `_languageInstruction` appended with: "Write grammatically correct
  $langName — proofread for spelling, agreement, and case before
  sending."
- `buildLightPrompt` prepended with the same directive so even 30-word
  replies get the proofread step.

---

## New tests

`test/ai_quality/chat_attachment_service_test.dart` — 9 tests:

- `classify` — 5 mime / extension cases.
- `buildUserMessage` — 3 cases (txt inlined, PDF with doc id, image
  with doc id).
- 200 KB size-guard truncation.

`test/ai_quality/adaptive_length_test.dart` — 21 tests:

- system-prompt contains `ADAPTIVE RESPONSE LENGTH` block (2).
- `isShortQuery` hits yes/no in 8 multilingual variants, list in 4,
  command in 3 (15 parametrised).
- two explicit "explain in detail" queries stay non-short.
- `maxTokensForShortQuery` returns ≤ 300.

`test/ai_quality/grammar_language_test.dart` — 3 tests:

- `grammatically correct` / `proofread` / `correct grammar`
  appears in the built prompt for RU, ET, and the light prompt.

**Total new tests: 33.**  All pass.

---

## Commits on `fix/ai-quality`

```
0a75581 fix(ai-quality): adaptive response length + grammar reinforcement
00c6cfe fix(ai-quality): chat attachments actually reach the AI
```

(A `launch/wave1` parallel agent also cherry-picked some of its own
commits onto `fix/ai-quality` while I was working — see "Known
interference" below.)

---

## Regression

Baseline on `main`:

```
+1066  11 skipped  2 failed (pre-existing: test/l10n/localization_test.dart)
```

On `fix/ai-quality` after both fix commits:

```
+1108  11 skipped  5 failed
```

**Delta: +42 tests passing, +3 failing.**

The +42 are: my 33 new AI-quality tests plus 9 others that landed
with the parallel agent's commits.  The +3 new failures all come from
one file: `test/features/chat/selectable_message_test.dart`.  That
file was committed to `fix/ai-quality` by the parallel launch/wave1
agent (commit `cd0afe5`) as a deliberate TDD-RED pin — the matching
implementation (selectable message bubbles, copy icon) is part of
their wave1 scope, not mine.  Those tests were red BEFORE my commits
and remain red; I did not address them per owner's scope ("don't
touch launch/wave1 territory").

`flutter analyze` on all AI-quality files: 0 errors, 0 warnings, 9
pre-existing info-level hints — nothing introduced by this branch.

---

## Known interference

During this session the parallel `launch/wave1` agent repeatedly
switched HEAD and worktree while my bash calls were in flight, and
cherry-picked `launch(wave…)` commits onto `fix/ai-quality` (expected
to be my branch alone).  Symptoms: my writes landed on the wrong
branch twice; stashes got mixed; the parallel agent's RED
`selectable_message_test.dart` now lives on this branch.

All AI-quality commits were verified to land on `fix/ai-quality` by
recording `git branch --show-current` before and after the commit in
the same bash call.  If the owner wants a cleanly-isolated branch
they can cherry-pick `00c6cfe` and `0a75581` onto a fresh branch:

```
git checkout -b fix/ai-quality-clean main
git cherry-pick 00c6cfe
git cherry-pick 0a75581
```

Both commits apply cleanly against `main`.

---

## How the owner can verify locally (no deploy)

```
cd /Users/ai.place/Advocat/app/advocat_project
git checkout fix/ai-quality

# 1. AI-quality unit tests pass.
flutter test test/ai_quality/

# 2. Static analysis clean.
flutter analyze lib/services/chat_attachment_service.dart \
                lib/services/claude_service.dart \
                lib/services/system_prompts.dart \
                lib/services/ai_service.dart \
                lib/features/chat/screens/chat_screen.dart

# 3. Smoke-run the chat screen (demo mode is fine).
flutter run -d chrome
#  attach a .txt file — AI answer quotes the body
#  attach a .pdf — AI answer cites document_id and calls read_document
#  ask "Yes or no: can I appeal?" — answer ≤ 30 words, no paragraph
#  ask "Составь список документов" — bulleted list only, no preamble
#  ask "Объясни подробно процесс обжалования" — full structured answer
```

---

## What was NOT fixed (and why)

- **selectable message / copy icon** — parallel agent's scope
  (launch/wave1), not owner's two AI-quality bugs.  Left alone.
- **Claude vision blocks for PDF / image attachments** — Claude 3.5
  Sonnet does support inline PDF content blocks, but the current
  `claude-proxy/index.ts` passes the body through verbatim and the
  client never builds image / PDF content blocks.  The read_document
  tool already covers this path via OCR (document worker); switching
  to vision would be a separate optimisation, not a bug fix.
- **Live streaming grammar check** — we added a prompt-level "proofread
  before sending" directive which is enough for a first pass.  A
  true server-side second-pass reviewer (Haiku proof-read step) would
  be a follow-up.  The commit is small enough that it can be rolled
  back without impact if it turns out to have no measurable effect.

---

## Next step (owner decides)

When ready to open a PR:

```
git push origin fix/ai-quality
gh pr create --base main --head fix/ai-quality \
  --title "fix(ai-quality): AI sees attachments, gives short answers, proofreads"
```

Absolutely no commands were run that touch `main`, `gh-pages`, or any
deployment target.
