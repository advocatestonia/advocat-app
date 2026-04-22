# BP-3 — Monitoring + alerting

**Status: DRAFT. Nothing applied to prod. Owner must opt in.**

Purpose: turn the existing Sentry-lite (`app_errors` + `telemetry_sink.dart`)
from a passive dump into an actionable alerting pipeline, without paying
for Sentry/Bugsnag.

## What was added

### 1. Categorized events
- Migration: `supabase/migrations/20260421_app_errors_event_kind.sql`
  Adds `event_kind` column with CHECK constraint on:
  `error | ai_failure | stripe_failure | cron_failure | rls_violation | cap_hit | cost_alert`.
  Default `error` preserves back-compat with the existing sink.
- Flutter helpers: `lib/shared/telemetry_events.dart`
  Typed wrappers: `reportAiFailure(...)`, `reportStripeFailure(...)`,
  `reportCronFailure(...)`, `reportRlsViolation(...)`, `reportCapHit(...)`,
  `reportCostAlert(...)`. All respect the existing consent gate in
  `telemetry_sink.dart` — no events fire without explicit opt-in.

### 2. Axiom / Better Stack forwarding
- Draft config: `config/monitoring/axiom.yaml`
- Owner TODO:
  1. Create free Axiom account (EU region).
  2. Create dataset `advocat-prod`.
  3. `supabase secrets set AXIOM_TOKEN=<ingest-token>`.
  4. Write a tiny `supabase/functions/log-shipper/` that pulls new rows
     via realtime (`postgres_changes`) and POSTs to Axiom ingest. Draft
     code not included — topology and contract are in the YAML. ~1h work.

### 3. Alert rules
- File: `config/monitoring/alert_rules.yaml`
- 9 rules, mapped to two channels (`email_owner`, `telegram_owner`):

  | id | trigger | severity |
  |---|---|---|
  | error_rate_high | >10 generic errors in 10min | page |
  | ai_response_failures | >5 ai_failure in 15min | page |
  | stripe_webhook_failures | any stripe_failure in 30min | page |
  | deadline_cron_failure | any cron_failure in 1h | ticket |
  | rls_violation_spike | >3 rls_violation in 10min | page |
  | founder_cap_80pct | 20/25 seats active | info |
  | founder_cap_full | 25/25 seats active | ticket |
  | claude_cost_daily | daily Claude spend > €20 | info |
  | chargeback_rate_high | >1% last 7d | page |

### 4. Status page
- Draft: `config/monitoring/status_page.html`
- Client-only polling shell. Can be hosted on a `status.advocat.ee` CNAME
  or as a subpath of gh-pages. Reads from `./status.json`, which a
  GitHub Actions cron (or a small Edge Function) can update every minute
  by running a subset of `prod_smoke.sh`.

## Flow

```
Flutter client
   │ reportAiFailure() / reportStripeFailure() / ...
   ▼
telemetry_sink (consent-gated, PII-scrubbed)
   │ INSERT INTO app_errors (..., event_kind=...)
   ▼
Supabase Postgres (RLS: service_role only)
   │ realtime change notification
   ▼
log-shipper Edge Function  ─►  Axiom dataset advocat-prod
                                  │ alert_rules.yaml
                                  ▼
                             email / telegram owner
```

## What is NOT included (out of scope for bulletproof)

- `log-shipper` Edge Function code (draft topology only).
- Real Axiom/BetterStack account — owner creates.
- Telegram bot token — owner wires.
- The 6 new `report*` helpers are NOT yet wired into catch-sites; BP-3
  only adds the scaffolding. Wiring is a separate, non-bulletproof task
  — see follow-up item in FINAL.md.

## Safety

- Migration is **idempotent** (`add column if not exists`, `create index if not exists`).
- New Flutter file is import-only; no caller in prod code changes yet, so
  existing builds are unaffected.
- `axiom.yaml`, `alert_rules.yaml`, `status_page.html` are documentation.
  No production surface touches them until the owner opts in.
