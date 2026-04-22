# 03 — E2E Scenario Gaps (OMEGA-QA v1, rerun)

**Date:** 2026-04-22
**Existing E2E surface:**
- `test/integration/wow_scenarios_test.dart` — 50 owner-described scenarios (tool layer)
- `test/integration/v242_regression_test.dart` — 6 AppConfig / shell regression tests
- `test/overnight/integration/` — 3 files (app_config, knowledge_base, knowledge_router)
- `test/e2e/prod_smoke.sh` — bash curl-based prod smoke (post-deploy gate)

## What the 50 wow_scenarios DO cover (good)

Tool-layer contracts for all 50 user-journey prompts:
- search_estonian_law across 12+ acts (MKS, KarS, TLS, KMS, TuMS, KrMS, TsMS, IKS, PärS, HMS, LKindlS, ÄS, PKS, LS)
- send_email, draft_email (approval-gated)
- check_company, check_vehicle
- create_deadline, get_deadlines, list_cases, create_case, update_case, get_case_status
- list_documents, read_document, analyze_contract
- find_lawyer, generate_draft, translate_text, change_language, navigate_to
- search_knowledge, get_user_profile
- Input hardening (21-30): unknown tool, missing fields, malformed emails, empty queries

## What the 50 scenarios DO NOT cover (gaps)

The wow_scenarios run only against the `AssistantTools` executor — they stop at the tool
result. **Full multi-step user journeys are missing:**

### E1 — Full payment flow (P0)
- Anonymous user lands on `/pricing`
- Clicks "Basic monthly" → `StripeCheckoutService.startCheckout({uiPlanId: 'basic', isAnnual: false})`
- Edge function `create-checkout` returns 200 with `{ url }`
- Redirect happens (web_redirect.redirectToUrl called exactly once)
- On `/payment-success?session_id=cs_test_…` the app handles webhook-delivered state
- Tier on profile is updated to `basic`
- Subsequent chat requests no longer hit quota block

**Currently covered:** only `startCheckout` guard (throws when Supabase uninit).

### E2 — Voice end-to-end (P0)
- User presses mic button → `initSpeech()` resolves true on supported browser
- `startListening('ru')` returns a stream
- Web Speech API callback fires with partial + final transcript
- `stopListening()` returns non-empty text
- Text is submitted to chat → response streamed
- `speak(reply, langCode: 'ru')` attempts ElevenLabs first (because RU is in `_preferElevenLabsFor`)
- On ElevenLabs failure, Google TTS is attempted
- On both failures, browser TTS fires
- `isSpeaking` transitions false→true→false

**Currently covered:** construction + enum defaults only.

### E3 — Anonymous → signup → trial → paid (P0)
- Open `/chat` while logged out → demo-mode banner visible
- `SupabaseService.isDemo` is true, `currentUserId` returns `DemoData.user.id`
- User hits "Sign up" → `signUp(email, password)` returns AuthResponse
- Redirect to confirm-email screen
- After confirm, `authStateChanges` emits a SIGNED_IN event
- `getUserProfile` now returns real profile (not demo)
- User lands on trial (N days free, configurable)
- Trial expires → `check-ai-quota` returns quota exhausted
- User clicks "Upgrade" → flows into E1 payment
- Post-payment: profile tier updated, chat unblocked

**Currently covered:** demo-mode paths only, no trial/upgrade transition.

### E4 — Case document flow (P1)
- Create case → uploadDocument → read_document via tool → signed URL resolves
- Download works (byte count matches)
- Delete case → storage files removed
- RLS: a different user cannot read the signed URL after it expires (5 min)

**Currently covered:** `uploadDocument` returns demo id in demo mode only.

### E5 — Deadline reminder cron (P1)
- Create deadline with due_date = tomorrow
- Run `deadline-reminder` Edge Function (manually invoked)
- Verify an email would be sent (with `send-email` stubbed to count calls)
- Late deadline (past due) does NOT trigger duplicate reminder

**Currently covered:** 0 tests.

### E6 — Language switching persistence (P1)
- Default lang = device locale (fallback en)
- User calls `change_language(lang: 'et')`
- Setting persists across app restart (SharedPreferences)
- UI strings update, and next `speak()` uses Estonian locale

**Currently covered:** tool exec only (31-33), no persistence check.

### E7 — Chat streaming end-to-end (P0)
- ChatProvider sends message
- `claude-proxy` Edge Function streams SSE chunks
- Each chunk appends to assistant message text
- On completion, message is saved to `chat_messages` (Supabase)
- Reload → history reappears via `getChatMessages(caseId)`

**Currently covered:** chat_provider_test does unit tests only, no streaming/persistence.

### E8 — RLS violation does not leak data (P0)
- User A uploads doc in case A
- User B queries `documents` table with `user_id = userA` — expect 0 rows
- User B calls `getDocumentUrl` with user A's storage_path — expect 403
- User B sets `case_id = caseA` in insert — RLS rejects

**Currently covered:** 0 tests.

### E9 — Stripe webhook idempotency (P0)
- `stripe-webhook` receives `invoice.payment_succeeded` twice (same event id)
- Tier is set only once, no double-billing state
- Replay of stale event (timestamp > 5 min old) is rejected with 401

**Currently covered:** 0 tests (T16 only checks source code imports `timingSafeEqual`).

### E10 — Error surfaces reach the user (P1)
- Edge function returns 500 → user sees friendly error (no raw JSON dump)
- Network timeout → "check your connection"
- Quota exhausted → upgrade CTA shown
- All 10 error translations exist in `.arb` files

**Currently covered:** partial in wow 22-30, but not user-facing surfacing.

## Infrastructure gaps preventing proper E2E

1. **No widget-level E2E harness** that drives a real `MaterialApp` through multiple
   screens. `testWidgets` in `v242_regression_test.dart` only pumps a single stub.
2. **No mock Supabase server** (e.g. `mockito` + `StubSupabaseClient` or
   `supabase_flutter_test`). All integration tests live in demo mode.
3. **No mock Stripe server** for checkout/webhook round-trips.
4. **No Playwright / browser-driver test for `https://advocat.ee` prod build** — only
   bash curl smoke in `test/e2e/prod_smoke.sh`.
5. **No goldens** for critical screens (landing, chat, pricing, vault).

## Recommended first-batch expansion (before writing the 10-20 new tests)

Pick 2 gaps per P0 that can land in pure-Dart, demo-mode-faked setup:

- E1 subset: `create-checkout` body shape + redirect-target assertion
- E2 subset: full TTS fallback chain (mock web_speech + AppConfig) — covered in Phase 5
- E3 subset: isDemo transition when Supabase is initialised
- E7 subset: ChatProvider sends exactly one message per user input
- E8 subset: `_uuidLike` guards block Postgres 400 on non-UUID ids
- E9 subset: `timingSafeEqual` rejects mismatched signatures character-by-character

The remaining gaps need mock-server infrastructure (Phase 6+) or real-Playwright runs
(Phase 7, out of scope for this rerun).
