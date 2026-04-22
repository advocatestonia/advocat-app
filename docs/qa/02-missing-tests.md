# 02 — Missing Test Scenarios (OMEGA-QA v1, rerun)

**Date:** 2026-04-22
**Scope:** critical services (voice, stripe, supabase) + 13 Edge Functions
**Method:** read each service/function vs existing test files; enumerated uncovered
branches, error paths, fallback chains.

## A. `voice_service.dart` — TTS/STT fallback chain

Existing tests in `test/services/voice_service_test.dart` cover:
construction, enum values, default state, 17-language locale acceptance, dispose.

**Gaps (error paths / fallback logic):**

| # | Scenario                                                                                      | Priority |
|---|-----------------------------------------------------------------------------------------------|----------|
| V1 | `_humanizeWhisperError` — every documented error code returns a user-presentable message    | P0       |
| V2 | `_shouldPreferElevenLabs` returns true for `en`/`ru`/`uk`, false for `et`/`fi`/`de`          | P0       |
| V3 | `_geminiTagRegex` strips `[warmth]`, `[thoughtful]`, keeps regular text                      | P1       |
| V4 | Unknown `langCode` falls back to `en-US` locale (not a crash)                                | P0       |
| V5 | `stopListening()` returns empty string when not listening (already covered) — add double stop | P2       |
| V6 | `voiceLevel` returns 0 on non-web even when `_isListening` claims true                       | P2       |
| V7 | `setVoiceGender(male)` flips pitch to 0.85, `female` to 0.95                                 | P1       |
| V8 | `ElevenLabs voice ID` is Charlotte for female, George for male (regression guard)            | P1       |
| V9 | `isSttAvailable` is true under any of the 4 state flags (table test)                         | P1       |
| V10| `warmUp()` is a no-op when `_googleTtsAvailable=false`                                        | P2       |

## B. `stripe_checkout_service.dart` — payment flow

Existing tests cover: construction, init-guard throws for basic/premium/free, mapping
errors. **Gaps:**

| # | Scenario                                                                               | Priority |
|---|----------------------------------------------------------------------------------------|----------|
| S1 | `_PlanMapping.toPlanId['basic']` must equal `'counsel'`, `'premium']` = `'representation'` | P0   |
| S2 | `_PlanMapping.billingPeriod(isAnnual: true)` = `'yearly'`, false = `'monthly'`         | P0       |
| S3 | `startFoundingCheckout` uses literal `billing_period: 'founding'`                      | P0       |
| S4 | Unknown plan `'enterprise'` throws `ArgumentError` with clear message                  | P0       |
| S5 | Empty `customerEmail` is NOT added to body (only non-empty)                            | P1       |
| S6 | Non-Map response surfaces `runtimeType` in error message                               | P1       |
| S7 | Missing `url` field throws "Checkout URL was empty"                                    | P0       |
| S8 | Network exception is wrapped with "Please check your connection"                       | P1       |
| S9 | `response.status != 200` surfaces `data['error']` when available                       | P1       |

## C. `supabase_service.dart` — RLS / UUID guards

Existing tests cover: demo-mode fallbacks, createCase, uploadDocument, getChatMessages,
exportUserData JSON shape. **Gaps:**

| # | Scenario                                                                               | Priority |
|---|----------------------------------------------------------------------------------------|----------|
| B1 | `_uuidLike` regex — positive ✅ real UUID v4, negative ❌ `general`, `case-1`, empty   | P0       |
| B2 | `getCaseById('general')` throws `ArgumentError` before hitting Postgres                | P0       |
| B3 | `_isRealUuid('case-new-1234567890')` is false (short), real UUID v4 is true           | P0       |
| B4 | `getChatMessages` with non-UUID caseId filters `case_id IS NULL` (not `eq`)           | P0       |
| B5 | `uploadDocument` with non-UUID caseId omits `case_id` column in insert               | P1       |
| B6 | `exportUserData` roundtrips valid JSON (can be re-decoded) and includes all 6 sections | P1       |
| B7 | `_buildExportJson` version field is `1.0.0`, app field is `Advocat`                   | P2       |
| B8 | `_placeholderCase(id)` preserves the requested id                                     | P2       |
| B9 | `getUserProfile()` returns `null` when authed user id is null (non-demo path)         | P1       |

## D. Edge Functions — Deno test coverage

| Function          | `index.test.ts` present? | Coverage gap                                       | Priority |
|-------------------|--------------------------|----------------------------------------------------|----------|
| `_shared/auth.ts` | ✅ YES (18 tests)         | —                                                  | —        |
| `stripe-webhook`  | ❌ NO                     | signature verification, `timingSafeEqual`, replay-window, plan-mapping, idempotency | P0 |
| `create-checkout` | ❌ NO                     | plan validation, founding-vs-monthly-vs-yearly, auth gate, Stripe error mapping | P0 |
| `claude-proxy`    | ❌ NO                     | rate-limit logic, JWT verification, request body size cap, Claude API error pass-through | P0 |
| `send-email`      | ❌ NO (contract test T17 only) | `scrubHeaderText` CRLF-injection edge cases, empty body, missing to/from   | P0 |
| `whisper-stt`     | ❌ NO (contract test T13 only) | audio size limit boundary (20 MB ± 1), language hint passthrough, fallback to auto | P1 |
| `tts-proxy`       | ❌ NO                     | voice ID validation, ElevenLabs error pass-through, retry on 5xx            | P1 |
| `google-tts`      | ❌ NO                     | voice fallback (Chirp3-HD-Kore for ET), chunk size cap                     | P1 |
| `check-company`   | ❌ NO                     | Estonian e-Business Register integration mock, plan-gate for premium       | P1 |
| `check-vehicle`   | ❌ NO                     | EE plate regex, invalid format handling                                    | P1 |
| `check-ai-quota`  | ❌ NO                     | quota computation, tier mapping, day-rollover                              | P0 |
| `customer-portal` | ❌ NO                     | Stripe Billing Portal session URL returned                                 | P1 |
| `deadline-reminder` | ❌ NO                   | cron trigger, email composition, timezone handling                         | P2 |

## Priority summary

- **P0 (must-have):** V1, V2, V4, S1, S2, S3, S4, S7, B1, B2, B3, B4 (dart side) +
  edge-function tests for `stripe-webhook`, `create-checkout`, `claude-proxy`,
  `send-email`, `check-ai-quota`.
- **P1:** remaining service gaps + `whisper-stt`, `tts-proxy`, `google-tts`, `check-*`,
  `customer-portal`.
- **P2:** V5-V6, V10, B7-B8 + `deadline-reminder`.

## Total countable gaps

- Dart service unit tests: **28**
- Edge Function Deno tests: **≥ 60** (average 5 per function × 12 untested functions)

## Notes for the TDD pass (next phase)

- All P0 Dart-side tests can be written without network (plan mapping, UUID guards,
  error humaniser, fallback chain gates) — ideal for fast TDD loop.
- Edge Function tests require Deno `--allow-read`, reuse pattern from `_shared/auth.test.ts`
  (source-code contract assertions + in-process function invocation).
