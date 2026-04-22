# Phase 5 — Pricing Phases 2-6 on `pricing-final/phase-2-6`

## Status: GREEN — branch pushed, NOT merged (deploy playbook in 09-deploy-instructions.md)

## Branch
- Name: `pricing-final/phase-2-6`
- Base: `main` @ `a9b47d7` (post-pricing-phase-1)
- Final head: `47f68b9`
- Tag: `v2-pricing-final-ready-20260422-213459`
- Pushed to `github`

## Phase-by-phase commits

### Phase 2 — consent modal + log-refund-consent Edge Function
Commit: `173235a feat(pricing-phase-2): consent modal + log-refund-consent Edge Function`

New files:
- `supabase/functions/log-refund-consent/index.ts` — JWT-gated (3/min),
  service-role INSERT, SHA-256(IP + pepper) hashing, user-agent truncated
  at 512 chars
- `supabase/functions/log-refund-consent/__tests__/log_consent_test.ts` —
  12 source-contract Deno tests (LRC-T01..T12)
- `lib/features/settings/widgets/refund_consent_modal.dart` — full widget
  with checkbox-gated Begin button, network failure is non-blocking
  (server reconciles via first_message_at), injectable `onLogConsent`
  hook for tests
- `test/features/settings/widgets/refund_consent_modal_test.dart` — 6
  widget tests covering render, gating, submit, failure, in-flight guard

L10n:
- `app_en.arb`, `app_ru.arb`, `app_et.arb`, `app_fi.arb` — 11 new keys:
  `founderBetaBadge`, `refundPolicyShort`, `consentModalTitle`,
  `consentModalBody`, `consentModalCheckbox`, `consentModalButton`,
  `betaCapFull`, `waitlistJoinedTitle`, `waitlistJoinedBody`
- Other 13 locales fall back to English for these keys (default Flutter
  behaviour when `.arb` missing a key)
- `flutter gen-l10n` ran; all 17 generated `app_localizations_*.dart`
  updated

Tests: +6 Dart, +12 Deno

### Phase 3 — message counter hook
Commit: `bbf7367 feat(pricing-phase-3): message counter hook in ai_service`

Modifications:
- `lib/services/supabase_service.dart` — new `incrementMessageCount()`
  RPC wrapper (handles int / num / String / null returns; never throws)
- `lib/services/ai_service.dart`:
  - `MessageCounter` abstraction + `SupabaseMessageCounter` impl
  - `_bumpMessageCounter()` — fire-and-forget with `catchError` so a
    rejected future doesn't surface as unhandled async error
  - Null counter is a no-op (demo mode / unauthenticated safe)
  - Hook fires at 6 user-facing success points:
    * non-streaming cache hit
    * simple-query non-streaming return
    * tool-use response return
    * normal text-only response return
    * streaming completion
    * streaming cache hit
  - Proxy fallback + "all backends unavailable" branches do NOT count
  - `@visibleForTesting`: `debugBumpMessageCounter`, `debugCacheResponse`
  - `aiServiceProvider` wires `SupabaseMessageCounter` by default
- `test/services/ai_service_message_counter_test.dart` — +5 tests
  covering DI, null-safety, async rejection swallowing, call-count
  contract via debug hook

Tests: +5 Dart

### Phase 4 — beta cap enforcement + join-waitlist
Commit: `294e8ae feat(pricing-phase-4): beta cap enforcement in create-checkout + join-waitlist`

Modifications to `supabase/functions/create-checkout/index.ts`:
- New `enforceBetaCap()`:
  - Reads `public.app_config.beta_cap` → `{ max_paying_users, active }`
  - Fails open when config row missing (dev safety)
  - Counts only `status = 'active'` subscriptions (trialing excluded)
  - Runs AFTER JWT gate (no leaking counters to anonymous probes)
  - Runs BEFORE Stripe call (no quota burn on rejections)
  - 403 body includes `beta_cap_full: true` + `waitlist_url` for client
    routing

New files:
- `supabase/functions/join-waitlist/index.ts` — anonymous-friendly
  (`anonymousPerMinute: 3`, authed: 5), validates email + normalises
  to lowercase + trim, idempotent (duplicate email → `already_joined:
  true`), returns 1-based position on first join, null on repeat
  (privacy), source param length-capped at 64
- `supabase/functions/join-waitlist/__tests__/waitlist_test.ts` — 13
  source-contract tests (JWL-T01..T13)
- 6 new create-checkout contract tests (F7-T10..T15) including strict
  order-of-operations guards

Tests: +19 Deno

### Phase 5 — UI cleanup (hide Pro tier + Founder's Beta badge)
Commit: `7514b96 feat(pricing-phase-5): hide Pro tier + Founder's Beta badge + refund policy line`

Modifications to `lib/features/settings/screens/subscription_screen.dart`:
- Remove the `premium` `_PlanCard` (€29.99 monthly, €249.99 annual).
  Comment block explains return conditions (tied to
  `app_config.beta_cap.active`)
- Add `_FounderBetaBadge` widget rendered between current-plan card and
  billing toggle — localised badge chip + refund policy one-liner with
  safe English fallback

New tests:
- `test/features/settings/subscription_screen_beta_test.dart` — 6
  source-contract tests (fails if Pro tier re-added, prices reappear,
  badge removed, policy line dropped, Basic/Free tiers disappear)

Tests: +6 Dart

### Phase 6 — ToS refund policy with Art. 16(m) waiver
Commit: `47f68b9 feat(pricing-phase-6): update ToS refund policy with Art. 16(m) waiver`

Modifications:
- `lib/features/legal/screens/terms_of_service_screen.dart` (section 7.5):
  Rewrite to surface the two-cutoff rule (14 days OR 7 AI responses),
  cite CRD Arts. 9 and 16(m), name the in-app consent modal
- `web/terms.html`: EN/RU/ET cards updated with the same dual cutoff

New tests:
- `test/features/legal/terms_of_service_refund_test.dart` — 9 source-
  contract tests guarding both ToS surfaces stay aligned with the
  consent modal wording (Art. 16(m) enforceability depends on this)

Tests: +9 Dart

## Cumulative tally (branch only)

| Metric | Before branch (main) | After branch | Delta |
|--------|----------------------|--------------|-------|
| Dart tests passing | 1294 | **1320** | **+26** |
| Deno tests passing | 118 | **149** | **+31** |
| Analyzer issues | 53 | 53 | 0 |
| main.dart.js | 6.3 MB | **6.3 MB** | 0 |

## Deploy readiness

- Branch pushed to `github`
- Tag `v2-pricing-final-ready-20260422-213459` points at head
- Migrations to push (all idempotent, already merged to main via
  Phase 4 of merge-deploy-v2):
  - `20260422_refund_eligibility.sql`
  - `20260422_refund_consents.sql`
  - `20260422_beta_cap.sql`
  - `20260422_waitlist.sql`
  - `20260422_increment_message_count.sql`
- Edge Functions to deploy (2 NEW + 1 MODIFIED):
  - NEW: `log-refund-consent`
  - NEW: `join-waitlist`
  - MODIFIED: `create-checkout` (beta cap enforcement)
- Secrets needed: `IP_HASH_PEPPER` (for log-refund-consent; falls back
  to `"advocat-v1-fallback"` if unset, with warning)

See `09-deploy-instructions.md` for the playbook.
