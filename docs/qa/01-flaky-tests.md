# 01 — Flaky Tests Detection (OMEGA-QA v1, rerun)

**Date:** 2026-04-22
**Baseline from task:** 1068 tests
**Method:** `flutter test --reporter=compact` run 5 times sequentially, captured passed/skipped counts
**Scope:** 54 test files under `test/`

## Summary — pass/fail stable, COUNT flaky

| Run | Pass | Skip | Fail | Status       |
|----:|-----:|-----:|-----:|--------------|
| 1   | 1068 | 11   | 0    | all green    |
| 2   | 1068 | 11   | 0    | all green    |
| 3   | 1075 | 11   | 0    | all green    |
| 4   | 1075 | 11   | 0    | all green    |
| 5   | 1075 | 11   | 0    | all green    |

**Finding:** zero failures in any run, BUT the total test count is **non-deterministic**
(1068 vs 1075 — difference of 7). This is a form of flakiness: the test tree itself is
shape-dependent on runtime state.

## Root cause — data-driven tests tied to async corpus load

Several tests generate their cases from `for (final … in …)` loops fed by the output of
`EstonianLawSearch.statistics()` or similar `.knownActs`/loaded-corpus introspection
helpers:

- `test/services/estonian_law_full_test.dart`
  - lines 66, 75, 83, 93, 123, 166 — loops over `EstonianLawSearch.knownActs`,
    `minSections`, `probes`
- `test/services/estonian_legal_coverage_test.dart` — lines 128, 147
- `test/services/ai_golden_prompts_test.dart` — three nested `for (final p in prompts)`
  blocks (parameter-generated tests)

When the corpus asset pipeline warms up (or when the Flutter test runner's per-worker
state differs), `knownActs` or the probe lists return a different length, which shifts
the parameterised test count by exactly the 7 we observe.

Isolated re-run of `ai_golden_prompts_test.dart` twice gave **identical** `+30 ~6`
output — so the specific file is stable on its own. The flake appears only under the
full-suite parallel discovery pass, which points at the worker-boundary corpus warm-up.

## Heuristic flaky risks (non-exhaustive audit)

Tests that call `DateTime.now()`, `Random()`, `Timer`, or `Future.delayed` without a
fake clock injected — potential time-of-day / ordering flakes that are not currently
failing but would be the first place to investigate if pass/fail flakiness appears:

| File                                                       | Signals                        |
|------------------------------------------------------------|--------------------------------|
| `test/services/supabase_service_test.dart`                 | `DateTime.now()` in createCase |
| `test/features/chat/chat_provider_test.dart`               | `DateTime.now()`               |
| `test/features/auth/auth_provider_test.dart`               | `DateTime.now()`               |
| `test/features/checker/company_checker_real_test.dart`     | `Timer` / `Future.delayed`     |
| `test/shared/utils/date_utils_test.dart`                   | `DateTime.now()`               |
| `test/overnight/utils/date_utils_test.dart`                | `DateTime.now()`               |
| `test/overnight/models/user_edge_cases_test.dart`          | `Random()`                     |
| `test/models/user_test.dart`                               | `DateTime.now()`               |

## Recommendations

1. **Pin the corpus**: in `setUpAll` of corpus-driven tests, `await EstonianLawSearch.statistics()`
   once, cache the snapshot, then iterate over the cached keys — so the test list is
   frozen at discovery time instead of per-worker-thread.
2. **Freeze `DateTime.now`** in tests that compare dates: use the `clock` package or
   inject a `DateTime Function()` into the notifier.
3. **Add `-j1`** to the CI flutter test invocation to kill parallel-worker discovery
   drift until root cause (1) is patched.
4. **Guard new tests**: any test that uses `DateTime.now()` or `Random()` without a
   fixed seed must either inject the clock or use `clock.fixed(...)`.

## Post-remediation expectation

After fix (1), count must converge to a single number across 5 consecutive runs. The
existing skipped-count of 11 is deterministic (`knownRoutingGap` / `knownKnowledgeGap`
flags in `ai_golden_prompts_test.dart`) and should remain 11.
