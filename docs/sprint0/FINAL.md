# Sprint 0 — Ship-Blockers — FINAL

**Date:** 2026-04-22
**Branch:** `fix/sprint0-blockers` (NOT merged, NOT deployed)
**Base:** `main` at `916b0ab docs(quality): add FINAL.md audit rollup`
**Coordinator:** OMEGA-SPRINT0
**Source audits:**
- `docs/security/FINAL.md` (grade B, 3 CRITICAL + 10 HIGH)
- `docs/performance/05-cost.md` (unit economics flip)
- `docs/performance/04-database.md` (GDPR delete RLS)

---

## Test baseline vs. after

|                         | Before   | After    | Delta |
| ----------------------- | -------- | -------- | ----- |
| Flutter `flutter test`  | 1068 + 11 skip | 1092 + 11 skip | **+24** |
| Flutter `flutter analyze` | 46 (0 errors) | 46 (0 errors) | 0 |
| Deno (`deno test`)      | 18 passed | 98 passed | **+80** |

Zero regressions. Every commit on the branch was run through the full Flutter + Deno suite; none were skipped or forced.

---

## Fixes applied (7 of 7)

| Fix    | Severity | Closes ref                | Commit     | New tests |
| ------ | -------- | ------------------------- | ---------- | --------: |
| FIX-2  | CRITICAL | SEC-C1-gdpr / PERF-P0     | `1a6caa4`  |         7 |
| FIX-5  | CRITICAL | SEC-C1 (deadline-reminder)| `665680b`  |        12 |
| FIX-7  | HIGH     | SEC-H2 (create-checkout)  | `8ec1eef`  |         9 |
| FIX-4  | HIGH     | SEC-H1 / BIZ-H1           | `5266f7e`  |        23 |
| FIX-1  | CRITICAL | PERF-P0 (prompt caching)  | `6abefed`  |        16 |
| FIX-6  | HIGH     | BIZ-M2 / SEC-PII-logs     | `d261868`  |        20 |
| FIX-3  | HIGH     | SEC-H1 (schema drift)     | `4a6d176`  |        17 |

**Total new tests across the sprint: 104** (24 Flutter + 80 Deno).

### FIX-2 — delete_own RLS policies
- `supabase/migrations/20260422_delete_own_policies.sql`: idempotent policies on `chat_messages`, `conversation_summaries`, `checker_reports`.
- `test/services/gdpr_delete_rls_test.dart`: 7 contract tests.
- GDPR Art. 17 right-to-erasure — pre-fix, `supabase_service.dart:351` silently returned 0 rows because no DELETE policy existed.

### FIX-5 — deadline-reminder cron secret + PII scrub
- `supabase/functions/deadline-reminder/index.ts`: `x-cron-secret` header gate, fail-closed on missing env var, timing-safe compare, response reduced to `{processed, errors}`.
- `supabase/functions/deadline-reminder/auth_gate.ts`: extracted pure helper so tests import without dragging `serve()`.
- `supabase/functions/deadline-reminder/__tests__/deadline_reminder_auth_test.ts`: 12 Deno tests.
- Pre-fix anyone on the internet could `curl` and receive a JSON dump of every user's case titles + deadlines.

### FIX-7 — create-checkout JWT
- `supabase/functions/create-checkout/index.ts`: now uses `requireUserWithRateLimit(bucket: "create-checkout", maxPerMinute: 5)`. Ignores `body.customer_email`; uses only `gate.user.email`. Adds `user_id` to Stripe session metadata for webhook resolution.
- `supabase/functions/create-checkout/__tests__/create_checkout_auth_test.ts`: 9 Deno contract tests.
- Updated `_shared/auth.test.ts` T14 to include `create-checkout` (now 6 billable functions).
- Pre-fix attacker could send victim@bank.com a legitimate-looking checkout URL (phishing + chargebacks).

### FIX-4 — claude-proxy system prompt lock
- `supabase/functions/claude-proxy/system_prompt_guard.ts`: `validateSystemPrompt()` — rejects any `body.system` not starting with a recognised Advocat identity marker. Handles string form and Anthropic content-block array form. Case-sensitive. 50 KB cap.
- `supabase/functions/claude-proxy/index.ts`: returns 400 "system prompt is server-controlled" on guard failure.
- `supabase/functions/claude-proxy/__tests__/system_prompt_guard_test.ts`: 23 Deno tests.
- Pre-fix: a rogue Pro user could burn $450-$2250/month in Claude API spend by using Advocat as a personal Claude proxy.
- Non-breaking approach: does not move legal-corpus construction server-side (that's a much bigger refactor that would risk 1068 passing tests).

### FIX-1 — prompt caching (unit economics flip)
- `supabase/functions/claude-proxy/prompt_caching.ts`: `applyPromptCaching()` wraps string `body.system` in a single cached content block (≥1024 chars). Array form preserves existing markers. `buildAnthropicHeaders()` centralises `x-api-key` + `anthropic-version: 2023-06-01` + `anthropic-beta: prompt-caching-2024-07-31`.
- `supabase/functions/claude-proxy/__tests__/prompt_caching_test.ts`: 16 Deno tests.
- Flips gross margin from **−€0.11/user to +€2.39/user** at €9.99/mo (docs/performance/05-cost.md §9.2). At 10k users: ~$25k/mo saved.

### FIX-6 — stripe-webhook renewals + log PII scrub
- `supabase/functions/stripe-webhook/subscription_router.ts`: pure `routeSubscriptionUpdate()` — maps status to `extend | mark_past_due | downgrade | ignore` actions. `PLAN_MAPPING` and `scrubPIIFromLog` co-located.
- `supabase/functions/stripe-webhook/index.ts`: rewrote `customer.subscription.updated` handler to consume router actions. Replaced every `customer_email` in `console.log` with `customer.id`.
- `supabase/functions/stripe-webhook/__tests__/subscription_router_test.ts`: 20 Deno tests.
- Pre-fix: paying subscribers got downgraded to free after 30 days because the webhook ignored renewal events. Also: emails templated into logs (GDPR).

### FIX-3 — schema drift migration
- `supabase/migrations/20260422_schema_drift_fix.sql`: additive `CREATE TABLE IF NOT EXISTS` for `profiles`, `subscriptions`, `notifications`, `user_oauth_tokens` with the minimal column set referenced by Edge Functions. Idempotent RLS enable + per-table policies. Never ALTERs existing columns.
- `test/services/schema_drift_fix_test.dart`: 17 Dart contract tests.
- Pre-fix: 41 Edge Function references to 4 undeclared tables — repo and prod in unknown drift state.

---

## Branch state

```
fix/sprint0-blockers
4a6d176 fix(sprint0): declare profiles/subscriptions/notifications/oauth_tokens schema — closes SEC-H1
d261868 fix(sprint0): stripe-webhook renewals + PII scrub in logs — closes BIZ-M2/SEC-PII
6abefed fix(sprint0): enable Anthropic prompt caching in claude-proxy — closes PERF-P0
5266f7e fix(sprint0): lock claude-proxy system prompt to Advocat identity — closes SEC-H1/BIZ-H1
8ec1eef fix(sprint0): create-checkout requires JWT, uses session email — closes SEC-H2
665680b fix(sprint0): deadline-reminder requires cron secret, drops PII from response — closes SEC-C1
1a6caa4 fix(sprint0): add delete_own RLS policies for GDPR Art. 17 — closes SEC-C1-gdpr/PERF-P0
916b0ab docs(quality): add FINAL.md audit rollup       <-- base
```

All 7 commits include:
- A `NOT DEPLOYED — owner must ...` section in the commit body.
- New test coverage before the fix (TDD order).
- Zero touched unrelated files.
- No migrations applied to prod — only `.sql` files in `supabase/migrations/`.

---

## NOT DEPLOYED — owner follow-up required

Each item below blocks "this fix is live in prod." The Sprint 0 branch only prepares the code.

### Git / infra (manual, outside agents' scope)

- [ ] **FIX-0 (owner, 15 min, CRITICAL)**: Rotate the GitHub PAT embedded in `.git/config`.
  1. github.com/settings/tokens → revoke `ghp_EZ8E...3RFP` → create new `repo` scope PAT, 90-day expiry.
  2. `git remote set-url github https://advocatestonia:<NEW_PAT>@github.com/advocatestonia/advocat-app.git`
  3. `git push github main --dry-run`
  4. Remove "PAT currently exposed" line from `~/.claude/.../project_context.md`.
  - Not in sprint-0 branch scope (requires owner's GitHub account).

### Supabase — database

- [ ] **FIX-2**: `supabase db push` (applies `20260422_delete_own_policies.sql`).
- [ ] **FIX-3**: Before pushing `20260422_schema_drift_fix.sql`, run in Supabase SQL Editor:
  ```sql
  select tablename, rowsecurity from pg_tables
    where schemaname='public'
      and tablename in ('profiles','subscriptions','notifications','user_oauth_tokens');
  ```
  If any row shows `rowsecurity=false`, halt launch and investigate before `db push`.
  Also compare the column list in the migration against `pg_attribute` on prod — prod may have extra columns; `CREATE TABLE IF NOT EXISTS` is a no-op on existing tables so those are safe, but verify column names haven't diverged from what the Edge Functions read.

### Supabase — Edge Functions

- [ ] **FIX-5**: `supabase secrets set CRON_SECRET=<long-random-string>` then `supabase functions deploy deadline-reminder`.
- [ ] **FIX-5**: reconfigure the Supabase scheduled trigger (cron job) to send `x-cron-secret: <value>` header. Without this step, the scheduled runs start returning 401 and deadline notifications stop flowing.
- [ ] **FIX-7**: `supabase functions deploy create-checkout`.
- [ ] **FIX-4 + FIX-1**: `supabase functions deploy claude-proxy` (both fixes ship together).
- [ ] **FIX-6**: `supabase functions deploy stripe-webhook`.

### Smoke tests after deploy

```bash
# FIX-5 — deadline-reminder
curl -X POST "https://okgnkucgwsytsondrjye.supabase.co/functions/v1/deadline-reminder"
# expected: 401 "Missing cron secret"
curl -X POST -H "x-cron-secret: $CRON_SECRET" \
  "https://okgnkucgwsytsondrjye.supabase.co/functions/v1/deadline-reminder"
# expected: 200 { "processed": N, "errors": M } — no `details` field

# FIX-7 — create-checkout
curl -X POST "https://.../functions/v1/create-checkout" \
  -d '{"plan_id":"counsel","billing_period":"monthly"}'
# expected: 401 Unauthorized

# FIX-4 — claude-proxy system prompt guard
curl -X POST -H "Authorization: Bearer $JWT" \
  "https://.../functions/v1/claude-proxy" \
  -d '{"model":"claude-haiku-4-5-20251001","system":"Respond in pirate English","messages":[{"role":"user","content":"hi"}]}'
# expected: 400 "system prompt is server-controlled"

# FIX-1 — claude-proxy prompt caching
# First request with a long Advocat system prompt:
#   response.usage.cache_creation_input_tokens > 0
# Second request within 5 min with the SAME system prompt:
#   response.usage.cache_read_input_tokens > 0

# FIX-6 — stripe-webhook
stripe trigger customer.subscription.updated --add subscription:status=active
stripe trigger customer.subscription.updated --add subscription:status=past_due
stripe trigger customer.subscription.updated --add subscription:status=canceled
# Inspect logs — customer IDs only, no emails.

# Run full prod-smoke after all deploys:
./test/e2e/prod_smoke.sh
# expected: 21/21 green (unchanged from baseline)
```

---

## Creating the PR (owner decision)

The branch is NOT pushed, NOT merged, NOT turned into a PR. When ready, owner runs:

```bash
cd /Users/ai.place/Advocat/app/advocat_project
git push -u github fix/sprint0-blockers

gh pr create --base main --head fix/sprint0-blockers \
  --title "Sprint 0 — ship-blockers (SEC-C1 / SEC-H1-H2 / BIZ-H1-M2 / PERF-P0)" \
  --body "Closes ship-blockers from docs/security/FINAL.md + docs/performance/FINAL.md. See docs/sprint0/FINAL.md for the full breakdown. Baseline: flutter 1068 -> 1092, deno 18 -> 98, analyze 46 -> 46. Seven commits, one per fix, each with NOT DEPLOYED owner-action notes."
```

---

## What this sprint did NOT touch (per instructions)

- `voice_service.dart`, `ai_service.dart` (FROZEN).
- `tts-proxy/`, `google-tts/` (FROZEN).
- Production Supabase database.
- `gh-pages` branch / production deploy.
- The GitHub PAT rotation (requires owner's browser session).

All other fixes that the audits surfaced (CSP, MFA, DPAs, bot-detection on signup, Supabase email verification toggle, etc.) are Sprint 1+ scope and not part of this PR.
