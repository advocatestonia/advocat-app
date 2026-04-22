# OMEGA-QA v1 rerun — FINAL

**Branch:** `qa/omega-v1`
**Date:** 2026-04-22
**Baseline (from task):** 1068 tests
**Measured baseline on `qa/omega-v1` pre-work:** 1068-1075 (flaky count, see §Flaky)
**Post-work green count:** **1109** (+34 new tests)
**Post-work failures:** **0**

## Deliverables

### 4 analytical reports (committed `e7600c7`)

| File | Topic | Key finding |
|------|-------|-------------|
| `docs/qa/01-flaky-tests.md` | 5x full-suite runs | 0 failures but count flaky (1068 vs 1075). Root cause: async corpus-loaded parameterised tests in `estonian_law_full_test.dart` + `ai_golden_prompts_test.dart`. |
| `docs/qa/02-missing-tests.md` | service/function coverage gaps | 28 dart-side gaps (voice V1-V10, stripe S1-S9, supabase B1-B9) + 60+ Edge Function gaps (only `_shared/auth.ts` has Deno tests among 13 functions) |
| `docs/qa/03-e2e-gaps.md` | E2E journey coverage | 10 multi-step journeys missing (payment flow, voice end-to-end, anon→signup→trial→paid, RLS-leak, webhook-idempotency). No widget-level E2E harness, no mock Supabase/Stripe servers |
| `docs/qa/04-test-infra.md` | CI/hooks/coverage | No GitHub Actions, no pre-commit hook, 10.6% overall line coverage (3 221 / 30 261), no enforced floor |

### 34 new critical tests (3 batches, each commit green)

| Batch | Commit | File | Tests | Gaps addressed |
|-------|--------|------|------:|----------------|
| 1 | `4feae8f` | `test/services/supabase_uuid_guard_test.dart` | 11 | B1, B2, B4, B5 — UUID-shape guards in `SupabaseService.getCaseById`, `getChatMessages`, `uploadDocument` |
| 2 | `60e67d4` | `test/services/stripe_plan_mapping_test.dart` | 8 | S1-S4 — `_PlanMapping.toPlanId` via error-surface introspection; founding vs monthly vs yearly; known + unknown + empty + typo plan ids |
| 3 | `41c5488` | `test/services/assistant_tools_input_validation_test.dart` | 15 | input hardening for unknown tool names, send_email malformed inputs, read_document guards, wrong parameter types, `ToolResult` contract invariants |

All commits are on `qa/omega-v1`. `fix/sprint0-blockers` unchanged.

## Baseline verification

| Run | Before PR | After PR |
|----:|----------:|---------:|
| 1   | 1068 pass, 11 skip, 0 fail | — |
| 2   | 1068 pass, 11 skip, 0 fail | — |
| 3   | 1075 pass, 11 skip, 0 fail | — |
| 4   | 1075 pass, 11 skip, 0 fail | — |
| 5   | 1075 pass, 11 skip, 0 fail | — |
| 6 (post-work) | — | **1109 pass, 11 skip, 0 fail** |

Count delta: +34 == 11 + 8 + 15, matches the three batches. **Zero regressions.**

## TDD discipline — honest note

Pure red-green TDD was NOT achievable for all 34 tests because:
1. The `lib/` code is already in-place (v24.2.3 shipped) — tests can only pin
   existing behaviour, not drive it.
2. Rule #1 of the task: must not break 1068 baseline. This rules out any test
   that is red on current `main`.

What I did do, consistent with the spirit of TDD:
- For each test: ran the new file in isolation BEFORE adding it to the commit,
  verified it loads and passes, then ran the full suite to confirm the
  regression baseline holds.
- Each commit is independently green and was verified via `flutter test
  --reporter=compact` immediately before committing.
- Batches are granular so any single commit can be reverted without cascade.

For future TDD on new features (not covered in this rerun): the pattern would
be Phase 5a "write failing test" → Phase 5b "implement lib/ change" → Phase 5c
"green + commit".

## Branch state

```
qa/omega-v1
├── e7600c7  docs(qa): add OMEGA-QA v1 rerun reports (flaky, missing, e2e, infra)
├── 4feae8f  test(supabase): add 11 UUID guard tests (gap B1/B2/B4/B5)
├── 60e67d4  test(stripe): add 8 plan-mapping regression tests (gap S1/S2/S3/S4)
└── 41c5488  test(tools): add 15 assistant-tools input-validation tests
```

Parent branches (`fix/sprint0-blockers`, `main`) untouched.

## What was NOT done (deliberately out of scope)

- Private-function tests for `_humanizeWhisperError`, `_shouldPreferElevenLabs`,
  `_PlanMapping.toPlanId` directly — would need `@visibleForTesting` exposure
  in `lib/`, which violates Rule #1 (no `lib/` changes in QA branch).
- Deno tests for the 12 untested Edge Functions — needs a separate Deno-aware
  PR with its own scaffold.
- Widget-level E2E harness + mock Supabase/Stripe — belongs in infra sprint.
- GitHub Actions CI + pre-commit hook — infra PR, not QA PR.

## Recommended next steps (roadmap, not for this PR)

1. **Infra PR** — add `.github/workflows/test.yml` with `flutter analyze` +
   `flutter test --coverage` + coverage floor (see `04-test-infra.md` §Minimal
   recommended fix set).
2. **Flaky fix PR** — pin `EstonianLawSearch.knownActs` / corpus-driven loops
   in `setUpAll` so the parameterised test count converges (see
   `01-flaky-tests.md` §Recommendations).
3. **Edge Function test PR** — Deno tests for `stripe-webhook`, `create-checkout`,
   `claude-proxy`, `send-email`, `check-ai-quota` (5 P0 functions).
4. **E2E harness PR** — add `mockito` / `supabase_flutter_test` scaffold, then
   implement the 10 multi-step journeys from `03-e2e-gaps.md`.

Each of these is its own concern. Bundling them would produce a mega-PR that
is hard to review and risky to revert.
