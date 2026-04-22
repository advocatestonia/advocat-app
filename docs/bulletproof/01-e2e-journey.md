# BP-1 — Full user journey integration test

Scope: 15 integration-level scenarios codifying the contracts a real
paying user depends on.  They are intentionally **offline / fake-world**
— no Supabase, no Stripe HTTP, no Edge Function calls. If these break,
the production flow is broken; if they pass they tell us the public
contract is preserved after any refactor.

## File

`test/integration/full_user_journey_test.dart`

## Run

```bash
# from app/advocat_project/
flutter test test/integration/full_user_journey_test.dart

# or with prod-like defines (matches v242 regression harness)
flutter test --dart-define-from-file=.env.prod \
  test/integration/full_user_journey_test.dart
```

## Scenarios

| # | Name | Invariant |
|---|---|---|
| 1 | anonymous visitor | anon users have no subscription row |
| 2 | signup flow | signup alone does NOT create a paid sub |
| 2b | duplicate signup | idempotent, no double-create |
| 3 | Basic €14.99 checkout | webhook transitions to plan=basic + status=active |
| 4 | webhook idempotency | replayed event is a no-op |
| 5 | AI consent modal | first AI msg requires explicit consent |
| 5b | consent denied | AI calls blocked at gate |
| 6 | 5 AI messages | quota counter increments, history persists |
| 7 | deadline creation | user_id matches auth.uid() (RLS contract) |
| 8 | upload > 25 MB | rejected before S3 hit |
| 8b | upload 2 MB PDF | accepted, owner-tagged |
| 9 | deadline cron idempotency | fires once, marks reminded=true, never re-fires |
| 10 | AI response copy | plaintext, no `<script>`/`<iframe>` |
| 11 | refund <= 7 messages | eligible |
| 11b | refund > 7 messages | NOT eligible |
| 12 | GDPR Art.17 delete | cascades across subs / deadlines / docs / ai history / consent |
| 13 | founder cap at 25 | 26th active rejected |
| 13b | cap frees on cancel | canceled seats become available |
| 14 | telemetry no consent | zero events |
| 14b | telemetry with consent | events flow to app_errors |
| 15 | legal disclaimer | non-advice language present |

Total: **21 distinct `test(...)` asserts in 15 scenario groups**, all
green at commit time.

## Why fakes instead of real Supabase

- Running against real Supabase from a unit runner hits network + auth,
  which is slow and flaky and requires owner credentials in CI.
- The **contracts** — what shape the data has after each step — are
  what actually regress. Fakes enforce them.
- The prod-facing counterpart is `test/e2e/prod_smoke.sh` (HTTP probes)
  and `test/integration/v242_regression_test.dart` (dart-define
  wiring). Together the three layers cover:
  - config wiring (v242_regression)
  - user-flow contracts (THIS FILE)
  - prod surface (prod_smoke.sh)

## What it does NOT cover

- UI rendering / widget trees — that belongs in `wow_scenarios_test.dart`
  and future golden tests.
- Real Stripe test-mode calls — deferred to manual QA until we have a
  CI with Stripe test keys.
- Accessibility assertions — out of scope for BP-1.

## Exit criteria

All 21 asserts green locally. No dependency on `.env.prod` except where
explicitly gated (none here — this file is fully self-contained).
