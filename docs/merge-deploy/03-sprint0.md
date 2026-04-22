# ФАЗА 3 — merge fix/sprint0-blockers

**Дата:** 2026-04-22 18:43 EEST
**Risk:** MEDIUM (Edge Functions + DB migrations)
**Status:** ✅ MERGED (no-op for 5 of 8 commits due to cherry-pick equivalence)

## Merge details

- Source: `fix/sprint0-blockers` (8 commits ahead of main before rebase)
- After rebase: **3 commits** (5 detected as already-applied by git)
- Target: `main` (post-Phase 2)
- Strategy: `--no-ff` merge via `ort`
- Merge commit: `48637ba`
- Pushed to: `github/main`

## Git cherry-pick equivalence (5 skipped)

```
warning: skipped previously applied commit 1a6caa4  (GDPR delete_own RLS)
warning: skipped previously applied commit 665680b  (deadline-reminder cron secret)
warning: skipped previously applied commit 8ec1eef  (create-checkout JWT)
warning: skipped previously applied commit 5266f7e  (claude-proxy system prompt lock)
warning: skipped previously applied commit 6abefed  (claude-proxy prompt caching)
```

These were cherry-picked into `qa/omega-v1` earlier — content already in `main` from Phase 2.

## Unique content merged (3 commits)

| Commit (rebased) | Purpose | Files |
|---|---|---|
| `f4e107c` | **stripe-webhook renewals + PII scrub** (BIZ-M2, SEC-PII) | `subscription_router.ts` (+87), `index.ts` (+97/-20), `subscription_router_test.ts` (+224) |
| `485fb77` | **schema drift fix** for 4 orphan tables (SEC-H1) | `20260422_schema_drift_fix.sql` (idempotent), `schema_drift_fix_test.dart` (+210) |
| `55067c6` | docs(sprint0) FINAL.md rollup | `docs/sprint0/FINAL.md` |

## Regression gates

| Gate | Before | After | Δ |
|---|---|---|---|
| Flutter tests pass | 1109 | 1126 | **+17** |
| Skipped | 11 | 11 | 0 |
| Analyze errors | 0 | 0 | 0 |
| Analyze warnings | 1 | 1 | 0 |
| Analyze info | 47 | 47 | 0 |
| Analyze total | 48 | 48 | 0 |
| Deno tests | 78 | **98** | **+20** (stripe-webhook router) |
| main.dart.js | 6.49 MB | 6.49 MB | 0 |
| `flutter build web` | ✅ | ✅ | 25.8s |

## Migration safety check

`20260422_schema_drift_fix.sql` validated as idempotent:
- `CREATE TABLE IF NOT EXISTS` (never ALTER)
- `ENABLE ROW LEVEL SECURITY` (idempotent in Postgres)
- Policies created via `DO` blocks guarded by `pg_policies` existence check
- Explicit comment: "NOT DEPLOYED — owner must verify pg_tables rowsecurity first"

## Owner actions (NOT executed — documented for Phase 9)

1. **Supabase SQL preflight** (verify RLS state on prod):
   ```sql
   SELECT schemaname, tablename, rowsecurity FROM pg_tables
   WHERE tablename IN ('profiles','subscriptions','notifications','user_oauth_tokens');
   ```
   If any `rowsecurity=false` → HALT deploy.
2. **Apply migrations**:
   ```bash
   supabase db push   # applies 20260422_delete_own_policies + schema_drift_fix
   ```
3. **Generate CRON_SECRET**:
   ```bash
   supabase secrets set CRON_SECRET="$(openssl rand -hex 32)" --project-ref okgnkucgwsytsondrjye
   ```
4. **Deploy updated Edge Functions**:
   ```bash
   supabase functions deploy stripe-webhook deadline-reminder create-checkout claude-proxy \
     --project-ref okgnkucgwsytsondrjye
   ```
5. **Reconfigure deadline-reminder cron** to pass `x-cron-secret: <CRON_SECRET>` header.
6. **Stripe smoke** after deploy:
   ```bash
   stripe trigger customer.subscription.updated --add subscription:status=active
   ```

## Rollback point

Tag: `after-sprint0-20260422-184316` (pushed).

## Ok to proceed → Phase 4 (launch/wave1)
