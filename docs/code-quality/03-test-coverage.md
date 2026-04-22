# 03 — Test Coverage Analysis

**Agent:** C (tester, Test Coverage Analyzer)
**Branch:** `code-quality/omega-v1`
**Baseline:** 1068 tests passing, 11 skipped (run 2026-04-21).
**Date:** 2026-04-21

---

## 1. Headline numbers

- **Test files:** 53
- **Tests green:** 1068 / 1068 passed · 11 skipped
- **Overall line coverage:** 3 221 / 30 261 = **10.6%**

> The 10.6% is *misleading* — the denominator is dominated by the 80k+ LOC of static EU-wide legal-data DB files (one function per country, returning a JSON blob). Those files are data, not logic, and "covering" them just means instantiating them once.

A more meaningful cut: **business-logic services only** (the 12 non-DB, non-localisation files in `lib/services/` that have imports into the app).

---

## 2. Business-logic coverage (critical services)

Sorted from best to worst. Target for critical services per this audit: **≥ 70%**.

| Service                                      | Coverage | Verdict         | Notes                                                           |
|----------------------------------------------|---------:|-----------------|-----------------------------------------------------------------|
| `demo_data.dart`                             |  100.0%  | Excellent       | Trivial data module                                             |
| `country_config.dart`                        |  100.0%  | Excellent       | Small lookup table                                              |
| `estonian_law_search.dart`                   |   95.9%  | Excellent       | `estonian_law_search_test.dart`                                 |
| `knowledge_base.dart`                        |   94.1%  | Excellent       | Core AI knowledge retrieval                                     |
| `knowledge_router.dart`                      |   92.9%  | Excellent       | `knowledge_router_test.dart` 487/524                            |
| `knowledge_data_extended.dart`               |   88.6%  | Excellent       |                                                                 |
| `legal_loader.dart`                          |   85.7%  | Excellent       | `legal_loader_test.dart`                                        |
| `finnish_law_search.dart`                    |   85.0%  | Excellent       | `finnish_law_search_test.dart`                                  |
| `tool_definitions.dart`                      |   60.0%  | Adequate        | Tiny file (5 lines)                                             |
| `assistant_tools.dart`                       |   59.8%  | Below target    | 400/669 — golden-prompt tests cover the happy path              |
| `system_prompts.dart`                        |   57.9%  | Below target    | Prompts are templated text — usually covered by integration     |
| **`ai_service.dart`** (FROZEN)               |   39.5%  | **Red flag**    | 163/413 — critical path for chat pipeline                       |
| `email_service.dart`                         |   36.7%  | Below target    | 18/49                                                           |
| **`supabase_service.dart`**                  |   35.5%  | **Red flag**    | 82/231 — most-imported service (16 files)                       |
| `legal_aid_directory.dart`                   |   29.5%  | Below target    |                                                                 |
| **`claude_service.dart`**                    |   18.6%  | **Red flag**    | 39/210 — direct Anthropic client path (used when proxy off)     |
| **`stripe_checkout_service.dart`**           |   15.8%  | **Red flag**    | 9/57 — payment flow                                             |
| `notification_service.dart`                  |   15.3%  | Below target    |                                                                 |
| **`voice_service.dart`** (FROZEN)            |   14.5%  | **Red flag**    | 48/330 — STT/TTS pipeline                                       |
| `tool_executor.dart`                         |    1.7%  | **Red flag**    | 1/60 — runs Claude tool calls (nav, case ops)                   |
| **`client_knowledge_service.dart`**          |    0.0%  | **Red flag**    | 0/157 — new three-tier memory service (ADR-001)                 |

---

## 3. Red-flag services — missing-scenario checklist

Below: what a coverage-raising PR would add. Listed as recommendations only.

### 3.1 `client_knowledge_service.dart` (0%) — NEW, no tests yet

From ADR-001, this is the persistent client-knowledge store introduced in v24.3-dev. It is imported only by `ai_service.dart`. Missing:
- `upsertFact()` — happy path, duplicate-key conflict, RLS denial when user swapped.
- `recallForUser()` — empty history, >1k facts truncation, ordering by recency.
- Error path when Supabase is offline (fallback behaviour).
- Null/empty content validation.

~10 unit tests needed. Estimated: 2 hours of agent time.

### 3.2 `voice_service.dart` (14.5%) — FROZEN

**Not touched per owner rule.** But recorded gaps for v24.3 when the freeze thaws:
- Gemini 3.1 Flash TTS fallback when primary provider 5xx's.
- STT permission-denied path on mobile.
- Language-routing table: each of ru/en/uk/et/fi/de/fr/es/it/pt/sv/pl/ar should have at least one smoke test.
- Hot-swap voice without user input (Charlotte ↔ George).

### 3.3 `ai_service.dart` (39.5%) — FROZEN

**Not touched per owner rule.** Gaps:
- Error flows when `claude-proxy` returns 429 (rate-limit).
- Invalid-JSON response from proxy (current behaviour?).
- Quota exhaustion path (`check-ai-quota` returns `allowed: false`).
- Tool-call parsing with malformed args.
- Token-counting edge cases.

### 3.4 `supabase_service.dart` (35.5%)

Most-imported service (16 imports). Gaps:
- Auth state transitions: login → logout → session-expired → re-login.
- Profile creation race condition when `onAuthStateChange` fires twice.
- Case/deadline creation under RLS failure.
- Realtime subscription teardown on provider dispose.

### 3.5 `claude_service.dart` (18.6%)

The "direct mode" (non-proxy) path. Gaps:
- Streaming response parser (SSE edge cases).
- Network timeout and retry.
- Abort mid-stream.

Low priority because prod runs via proxy 100% of the time — direct mode is for local/dev only.

### 3.6 `stripe_checkout_service.dart` (15.8%)

Payment flow. Gaps:
- Each of the 6 price entries (`counsel` × monthly/yearly/founding + `representation` × same) — smoke test that the correct Stripe session is requested.
- Failure cases: backend returns 500, 401.
- Web redirect success/cancel callback handling.

**Flagging as P1** — payments are high-stakes, and coverage here is the lowest among paid-feature code.

### 3.7 `tool_executor.dart` (1.7%)

Executes LLM tool calls. Essentially untested at unit-level. Integration tests (`assistant_tools_v24_1_test.dart`) cover this transitively, so effective coverage is higher — but a focused unit suite would document the contract.

---

## 4. UI / screen coverage (expected: low)

Widgets/screens sit at 0–5% coverage across the board. This is normal for Flutter — widget tests are usually smoke tests, golden tests, or driven by integration tests (`prod_smoke.sh`). Not flagging individually.

Priorities if UI coverage push is ever scheduled:
1. `chat_screen.dart` (1338 LOC) — critical UX surface.
2. `rights_detail_screen.dart` (897 LOC).
3. `tool_result_card.dart` (498 LOC).

---

## 5. Testing infrastructure observations

### 5.1 Good

- Provider overrides are used correctly (`ProviderContainer` / `ProviderScope`).
- Mocks for Supabase/Dio via `mockito`.
- Golden-prompt tests (`ai_golden_prompts_test.dart`) are a nice reproducibility layer for AI output.
- E2E smoke (`test/e2e/prod_smoke.sh` — 21 checks, 21/21 green) complements unit suite.

### 5.2 Gaps

- **Zero integration tests for Edge Functions.** `supabase/functions/_shared/auth.test.ts` exists; the other functions don't have matching tests. This is the biggest coverage blind spot.
- No test for the `send-email` deliverability path.
- No test for `stripe-webhook` signature verification (though Stripe does this server-side, fuzzing the verifier is cheap).
- No test proving `deadline-reminder` actually writes to the notifications table for each bucket of users.

### 5.3 Flakiness

No visible flakes from CI — baseline was 1068/1068 green twice consecutively. Good.

---

## 6. Summary & recommendations

**Grade: C+.**

- Knowledge/search layer (`knowledge_*`, `estonian_law_search`, `finnish_law_search`, `legal_loader`): A-grade, 85–96%. Clearly the team's strong test discipline.
- Core services powering the paid product (AI pipeline, payments, voice): 15–40%. Needs work.
- Brand-new `client_knowledge_service.dart` ships with 0% coverage — should not go to prod without at least happy-path tests.

**Top 3 coverage-raising PRs if owner wants to pick them up:**

1. `client_knowledge_service.dart` → **≥ 75%** (2 hrs, no frozen-file blocker).
2. `stripe_checkout_service.dart` → **≥ 70%** (2 hrs).
3. `supabase_service.dart` → **≥ 60%** (4 hrs — more branches).

FROZEN files (`ai_service.dart`, `voice_service.dart`) are NOT included in the recommendations above, per Rule #0.
