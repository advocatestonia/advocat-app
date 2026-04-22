# 04 — Test Infrastructure Audit (OMEGA-QA v1, rerun)

**Date:** 2026-04-22
**Scope:** CI/CD, pre-commit hooks, coverage thresholds, test-running ergonomics

## Current state (measured, not assumed)

### GitHub Actions / CI
- **No `.github/workflows/` directory exists** in this submodule.
- Parent monorepo also has no workflows configured (`ls -la .github` → no such dir).
- No CI-driven test runs. Tests are executed only when the developer runs
  `flutter test` manually or via the deploy script.

### Pre-commit hooks
- Only the default `.git/hooks/*.sample` files are present; no active hook.
- No `husky`, no `pre-commit` config, no `lefthook`.
- There is no local gate that prevents a commit with failing `flutter analyze` or
  `flutter test`.

### Deploy-time testing gates
- `scripts/build-and-deploy.sh` runs `test/e2e/prod_smoke.sh` AFTER deploy — this is
  a post-hoc smoke, not a pre-deploy gate.
- The shell smoke `prod_smoke.sh` only curls public routes / Supabase functions; it
  does not run the Dart test suite.

### Coverage
- `coverage/lcov.info` exists (last generated 2026-04-22 09:00).
- **Overall coverage: 3 221 / 30 261 lines = 10.6 %.**
- 122 Dart source files covered (out of many more total).
- No coverage threshold enforced anywhere.
- No `codecov.yml`, no `minimum_coverage` setting in CI.

### Test runner ergonomics
- No `test/dart_test.yaml` override for concurrency, timeouts, or tags.
- No tagged test groups (`@Tags(['slow'])`, `@Tags(['integration'])`). Everything
  runs in every `flutter test` invocation.
- No `--concurrency=N` guidance documented.

## Gaps vs target

| Target                                                   | Current | Priority |
|----------------------------------------------------------|---------|----------|
| GitHub Actions workflow running `flutter test` on push   | ❌      | P0       |
| GitHub Actions workflow running `flutter analyze`        | ❌      | P0       |
| GitHub Actions workflow running Deno `edge-function` tests | ❌    | P1       |
| Pre-commit hook running `flutter analyze`                | ❌      | P1       |
| Pre-commit hook running changed-file tests               | ❌      | P2       |
| Coverage threshold check (target ≥ 30% baseline)         | ❌      | P1       |
| `test/dart_test.yaml` with tags: `slow`, `integration`   | ❌      | P1       |
| `flutter test --machine` in CI for structured output     | ❌      | P1       |
| Codecov or similar coverage reporting on PRs             | ❌      | P2       |
| Nightly regression job running the 5x flaky-detect loop  | ❌      | P2       |

## Analyzer configuration

`analysis_options.yaml` is already tightened (OMEGA stage 2):
- `avoid_print` → warning
- `unused_import`, `unused_element`, `unawaited_futures` → warning
- `prefer_const_*`, `prefer_final_locals`, `unnecessary_late`, `unnecessary_cast` → info

This is good, but there is no CI enforcement — so a WARNING-level regression can land
in main undetected.

## Minimal recommended fix set (for the next infra PR, out of scope for this task)

1. Add `.github/workflows/test.yml`:
   ```yaml
   on: [push, pull_request]
   jobs:
     test:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         - uses: subosito/flutter-action@v2
           with: { flutter-version: '3.41.6' }
         - run: flutter pub get
         - run: flutter analyze --fatal-infos
         - run: flutter test --coverage --reporter=expanded
         - name: enforce coverage floor
           run: |
             pct=$(awk -F: '/^LH:/{lh+=$2} /^LF:/{lf+=$2} END{printf "%d", lh*100/lf}' coverage/lcov.info)
             echo "coverage: $pct%"
             [ "$pct" -ge 12 ] || { echo "coverage floor failed (12%)"; exit 1; }
   ```
2. Add `.githooks/pre-commit` with `flutter analyze` (users opt in via
   `git config core.hooksPath .githooks`).
3. Tag slow tests in `dart_test.yaml` so `flutter test --exclude-tags=slow` gives a
   fast feedback loop.
4. Add `scripts/flaky-detect.sh` that runs `flutter test` 3x and diffs counts — the
   same method this audit used.

## Non-goal for this task

This rerun writes the reports + 10-20 new critical tests — it does NOT land the CI
workflow itself. That belongs in a separate `infra/ci` PR.
