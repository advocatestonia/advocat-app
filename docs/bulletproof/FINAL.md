# OMEGA-BULLETPROOF — FINAL report

Branch: `safety/bulletproof` (off `main @ 52c76e8`).
Date: 2026-04-21.
Objective: add safety infrastructure so a future deploy cannot break prod
without being caught first. **Nothing is deployed by this branch.**

## What was added

### BP-1: Full user journey integration test
- `test/integration/full_user_journey_test.dart`
- `docs/bulletproof/01-e2e-journey.md`
- 15 scenario groups, 21 `test(...)` asserts; fully offline / no network.
- Covers: anonymous visit, signup, Basic €14.99 checkout, webhook
  idempotency, AI consent, AI quota, deadline RLS, upload size caps,
  cron idempotency, AI response copy-safety, refund eligibility (<=7
  messages), GDPR Art.17 cascade, founder beta cap, telemetry consent
  gate, legal disclaimer presence.

### BP-2: Extended prod smoke (21 -> 37 required + 1 conditional)
- `test/e2e/prod_smoke.sh` (updated, backward-compatible)
- `docs/bulletproof/02-extended-smoke.md`
- New probes:
  - landing + app.html disclaimer markers
  - privacy.html, terms.html, robots.txt, sitemap.xml, payment-*.html 200
  - create-checkout / customer-portal / claude-proxy reject POST without
    JWT
  - stripe-webhook rejects invalid signature
  - deadline-reminder rejects POST without cron secret
  - check-refund-eligibility presence probe (401/403/404)
  - Optional AI quality probe: if `SMOKE_AUTH_JWT` env is set, POSTs to
    claude-proxy and asserts reply > 50 chars (catches the Apr-18/Apr-20
    blank-response class of failures).
- Supports `SMOKE_BASE_URL`, `SMOKE_TIMEOUT` env overrides for use by
  canary-deploy against staging.

### BP-3: Monitoring + alerting scaffolding (DRAFT)
- `supabase/migrations/20260421_app_errors_event_kind.sql` — adds
  `event_kind` enum-like column to the existing `app_errors` table. Safe
  idempotent migration; default value preserves back-compat with the
  wave1 telemetry sink.
- `lib/shared/telemetry_events.dart` — typed helpers
  (`reportAiFailure`, `reportStripeFailure`, `reportCronFailure`,
  `reportRlsViolation`, `reportCapHit`, `reportCostAlert`). All respect
  the existing consent gate in `telemetry_sink.dart`; no events fire
  without explicit opt-in.
- `config/monitoring/axiom.yaml` — Axiom / Better Stack shipping config,
  PII scrub regex for emails / phones / IBANs.
- `config/monitoring/alert_rules.yaml` — 9 alert rules
  (error_rate_high, ai_response_failures, stripe_webhook_failures,
  deadline_cron_failure, rls_violation_spike, founder_cap_80pct,
  founder_cap_full, claude_cost_daily, chargeback_rate_high).
- `config/monitoring/status_page.html` — drop-in status page template
  driven by a `status.json` that a small deploy-time worker can emit.
- `docs/bulletproof/03-monitoring.md`

### BP-4: Canary deploy + rollback automation
- `scripts/canary-deploy.sh` (new)
- `scripts/rollback.sh` (updated, backward-compatible)
- `docs/bulletproof/04-canary-rollback.md`
- Canary flow: build once -> push to gh-pages:/staging/ -> smoke staging
  -> promote to root -> smoke prod -> auto-rollback on failure.
- Rollback extensions: `--mark-bad <sha>` audit ledger in
  `docs/ROLLBACK_LOG.txt`; `--sql-down <name>` optional down-migration
  runner; post-rollback smoke verification with distinct exit code for
  "pushed but still failing".

## Tests before / after

| Suite | Before | After | Delta |
|---|---|---|---|
| `test/integration/v242_regression_test.dart` | 5 tests | 5 tests | unchanged |
| `test/integration/wow_scenarios_test.dart` | 50 scenarios | 50 scenarios | unchanged |
| `test/integration/full_user_journey_test.dart` | -- | 21 tests | NEW |
| `test/e2e/prod_smoke.sh` checks | 21 | 37 required + 1 conditional | +17 |

Total Flutter integration asserts in this branch: **76** (was 55).

## New / updated scripts

| Path | Status |
|---|---|
| `scripts/canary-deploy.sh` | NEW, executable, `bash -n` OK |
| `scripts/rollback.sh` | UPDATED (backward-compatible), `bash -n` OK |
| `test/e2e/prod_smoke.sh` | UPDATED (backward-compatible), `bash -n` OK |
| `test/integration/full_user_journey_test.dart` | NEW, 21/21 green |
| `lib/shared/telemetry_events.dart` | NEW, `flutter analyze` clean |
| `supabase/migrations/20260421_app_errors_event_kind.sql` | NEW, idempotent |

## Safety audit (ФАЗА 2)

All new additions were checked against the review checklist:

1. **Do they break existing tests?**
   - `v242_regression_test.dart`: 1/1 passed in-place (4 skipped by
     design — need dart-define-from-file). Unchanged.
   - `full_user_journey_test.dart`: 21/21 green on `safety/bulletproof`.
2. **Do they require prod changes to work?**
   - No. `canary-deploy.sh` and the extended smoke use the existing
     `github` remote and existing Edge Functions. The monitoring draft
     is documentation until the owner creates an Axiom account.
3. **Do they touch the FROZEN v24.2 surface?**
   - `google-tts`, `tts-proxy`, `whisper-stt`, `claude-proxy` Edge
     Function source: untouched. No changes anywhere under
     `supabase/functions/{google-tts, tts-proxy, whisper-stt, claude-proxy}`.
   - Deploy script preserves the `LANDING_FILES` exclude list; canary
     script mirrors it exactly.
   - Build-and-deploy.sh itself is unchanged — we only extended the
     prod_smoke.sh it already invokes.
4. **Do they conflict with parallel branches?**
   - Branch off `main @ 52c76e8`, same base as CORPUS-FIX and
     PRICING. No overlapping files in the staged set (our 12 files
     vs. their refund_*/waitlist/beta_cap migrations + Estonian JSON
     corpus). Confirmed via `git status --short` during a parallel
     agent shuffle — no conflicts.
5. **Are they documented for the owner?**
   - Four topic-level files under `docs/bulletproof/` + this FINAL.md.

## Owner actions required (for the pieces that need human onboarding)

These are **optional**. Everything in this branch works without them;
the actions below unlock the monitoring / alerting rail.

1. **Axiom or Better Stack account.** Free tier is enough.
   - Create dataset `advocat-prod`, EU region, 30-day retention.
   - `supabase secrets set AXIOM_TOKEN=<ingest-token>` in project
     `okgnkucgwsytsondrjye`.
   - Write a small `supabase/functions/log-shipper/` (topology in
     `config/monitoring/axiom.yaml`; ~1 hour).
2. **Telegram bot (optional).** Register a bot, get token, set it as a
   Supabase secret, replace the `telegram_owner.placeholder: true`
   entry in `config/monitoring/alert_rules.yaml`.
3. **Wire `report*()` helpers into catch-sites.**
   - `reportAiFailure(...)` in `ChatController` / `ClaudeProxy` error
     path.
   - `reportStripeFailure(...)` in stripe-webhook EF error path.
   - `reportCronFailure(...)` in deadline-reminder EF error path.
   - `reportRlsViolation(...)` wherever a `.from(...)` write fails with
     code 42501.
   - `reportCapHit(...)` in create-checkout EF rejection branch.
4. **Status page domain (optional).** Point a CNAME
   `status.advocat.ee -> <advocatestonia>.github.io` and drop
   `config/monitoring/status_page.html` as `status/index.html` on
   gh-pages; teach `scripts/canary-deploy.sh` to write `status.json`
   alongside.

## Deploy readiness score

**Before bulletproof:** 6/10. v24.2 freeze + prod_smoke + rollback
existed, but only 21 checks, no staging, no auto-rollback, no alerting.

**After bulletproof (this branch):** 8.5/10.
- +1.0 — canary with staging smoke before prod (catches Apr-18 class
  bugs without touching prod)
- +0.5 — extended smoke with auth/security/AI probes
- +0.5 — E2E contract test for real user journeys
- +0.5 — monitoring scaffolding (errors / AI / Stripe / cron / cap / cost /
  chargeback) ready to light up when owner wires Axiom/Telegram

The last 1.5 points require owner actions above to be fully earned (the
monitoring rail is draft-only until a dataset exists).

## Rollback plan (if this branch ever lands and breaks something)

1. `git checkout main`
2. `git revert <merge commit of safety/bulletproof>`
3. `scripts/build-and-deploy.sh` (no infra changes revert — the branch
   does not redeploy anything on merge, so the only revert surface is
   the staged source files and one idempotent migration).
4. The `event_kind` column is idempotent-add. Leaving it in place is
   harmless even if helpers are unused — it has a safe default of
   `error` and the CHECK constraint only rejects typos. If truly
   unwanted:
   ```sql
   alter table public.app_errors drop column if exists event_kind;
   ```
   No data loss beyond the categorization.

## Exit criteria for this agent run

- [x] Branch `safety/bulletproof` created off `main`.
- [x] BP-1 tests 21/21 green.
- [x] BP-2 smoke expanded to 37+1 checks, `bash -n` clean.
- [x] BP-3 migration idempotent, Dart helpers `flutter analyze` clean.
- [x] BP-4 canary + updated rollback, `bash -n` clean.
- [x] FROZEN surface untouched.
- [x] No prod deploy attempted.
- [x] All outputs documented under `docs/bulletproof/`.
