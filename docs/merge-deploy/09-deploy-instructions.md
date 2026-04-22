# ФАЗА 9 — Deploy instructions for owner

**Дата создания инструкции:** 2026-04-22 19:45 EEST
**Target main SHA:** `9b44082`
**Target backup/rollback tag:** `v24.2-frozen-2026-04-20` (still valid)

This is the step-by-step playbook for owner to take the post-merge `main` to
production. Each step is numbered, has a rough time estimate, and a failure
branch. The automated portion is one command (`./scripts/build-and-deploy.sh`)
but there are prerequisites that require manual setup.

Total estimated owner time: **~50 min** (+ smoke).

---

## STEP 0 — (optional but recommended) tag a pre-deploy rollback anchor

```bash
cd /Users/ai.place/Advocat/app/advocat_project
git fetch github && git checkout main && git pull github main
git tag pre-deploy-$(date +%Y%m%d-%H%M%S)
git push github --tags
```

Why: gives a dedicated rollback point for this particular deploy, distinct
from the per-phase merge tags.

---

## STEP 1 — Rotate GitHub PAT (5 min) [CRITICAL SECURITY]

The current PAT is visible in the git remote URL and has been in plaintext
for weeks. It has full `repo` scope.

1. Go to https://github.com/settings/tokens
2. Find token starting with `ghp_EZ8E...3RFP` → Revoke
3. Generate new classic token:
   - Name: `advocat-app-deploy-2026`
   - Expiration: 90 days
   - Scopes: `repo` only
   - Copy the new value
4. Update the git remote:
   ```bash
   cd /Users/ai.place/Advocat/app/advocat_project
   git remote set-url github https://advocatestonia:<NEW_PAT>@github.com/advocatestonia/advocat-app.git
   git fetch github   # confirm it works
   ```

**Failure branch:** if auth fails, roll back `git remote set-url` to the
old token (but schedule rotation within 24h).

---

## STEP 2 — Supabase migrations preflight (5 min) [CRITICAL]

Three migrations are ready but not applied:
- `supabase/migrations/20260421_app_errors_telemetry.sql`
- `supabase/migrations/20260422_delete_own_policies.sql`
- `supabase/migrations/20260422_schema_drift_fix.sql` (idempotent but asserts schema)

Before applying, **verify 4 orphan tables already have RLS enabled in prod**:

Go to Supabase Dashboard → SQL Editor and run:

```sql
SELECT schemaname, tablename, rowsecurity
FROM pg_tables
WHERE tablename IN ('profiles','subscriptions','notifications','user_oauth_tokens')
ORDER BY tablename;
```

**Expected:** all 4 rows with `rowsecurity = t` (true).

**If any row shows `rowsecurity = false`:**
- **STOP. DO NOT PROCEED.**
- That table is wide-open; applying the migration does not retroactively
  protect data already readable/writable via the anon key.
- Escalate to security review before any deploy.

**If all green** → proceed to Step 3.

---

## STEP 3 — Apply migrations (3 min)

```bash
cd /Users/ai.place/Advocat/app/advocat_project
source ~/.zshrc                          # SUPABASE_ACCESS_TOKEN
supabase link --project-ref okgnkucgwsytsondrjye    # if not already
supabase db push
```

**Expected output:** "All migrations have been applied" or similar.

**Post-apply verification (Supabase SQL Editor):**

```sql
-- 1. delete_own policies exist
SELECT tablename, policyname FROM pg_policies
WHERE schemaname='public'
  AND tablename IN ('profiles','subscriptions','notifications',
                    'user_oauth_tokens','chat_messages','conversation_summaries')
  AND policyname ILIKE '%delete%own%';

-- 2. app_errors table exists and has RLS
SELECT relname, relrowsecurity FROM pg_class WHERE relname = 'app_errors';
```

**Failure branch:** migrations use `CREATE TABLE IF NOT EXISTS` + `DO`-guarded
policy creation — safe to re-run. If something permission-denied, ensure
`supabase link` is pointing at the right project and `supabase login` is current.

---

## STEP 4 — Set CRON_SECRET (2 min)

Required for deadline-reminder to stop accepting anonymous cron calls.

```bash
openssl rand -hex 32                     # generate, copy the output
supabase secrets set CRON_SECRET=<paste-here> --project-ref okgnkucgwsytsondrjye
supabase secrets list --project-ref okgnkucgwsytsondrjye    # verify present
```

**Failure branch:** if `secrets set` fails, the cron job will start returning
401 after Step 5 — fix before step 6.

---

## STEP 5 — Reconfigure deadline-reminder cron (3 min)

Supabase Dashboard → Database → Cron Jobs → `deadline-reminder`:

1. Edit the HTTP request
2. Add header: `x-cron-secret: <same value as STEP 4>`
3. Save

**Test it:** "Run now" → expect success log, not 401.

**Failure branch:** if still 401, double-check the secret value matches
exactly (no trailing newline from clipboard paste).

---

## STEP 6 — Deploy Flutter web + Edge Functions (10 min)

This is the **ONLY supported deploy path** after the Apr 18+20 outages
(see `docs/DEPLOY.md`).

```bash
cd /Users/ai.place/Advocat/app/advocat_project
./scripts/build-and-deploy.sh
```

The script will:
1. Preflight (branch, clean tree, SUPABASE_ACCESS_TOKEN, .env.prod, toolchain)
2. `flutter clean && flutter pub get && flutter build web --release --dart-define-from-file=.env.prod`
3. Size sanity (fails if main.dart.js < 5 MB or > 8.5 MB)
4. SUPABASE_ANON_KEY baked-in proof (greps for first 30 chars of JWT in bundle)
5. Deploy to gh-pages via `git worktree` (preserves landing files byte-for-byte)
6. Deploy all 13 Edge Functions
7. Run `test/e2e/prod_smoke.sh` (21 checks)

**Expected total time:** 5-8 min.

**If smoke fails:** the script returns non-zero. Immediately:
```bash
./scripts/rollback.sh v24.2-frozen-2026-04-20
```

---

## STEP 7 — Manual smoke (5 min)

Even though `prod_smoke.sh` covers critical endpoints, do a visual/UX check:

1. **Landing** — https://advocat.ee
   - Loads, no blank screen
   - Cookie banner appears at bottom (accept/reject/learn) — NEW in wave1-3
   - Blog links work

2. **App** — https://advocat.ee/app.html
   - Shell loads within 3s
   - Google OAuth login works
   - Send a test message in chat → response arrives
   - Copy button on AI message works (click copy icon in message footer) — NEW in fix/ai-quality
   - User message selectable (long-press or drag to select) — NEW in fix/ai-quality

3. **Voice** — on the chat screen
   - Tap microphone, say "Hello" in Russian or Estonian
   - Audio should come back in Chirp3-HD (et) or ElevenLabs v3 (ru/en/uk)

4. **Payment** (optional — only if testing Stripe flow)
   - Go to pricing/upgrade
   - Click Upgrade → Stripe Checkout opens in new tab
   - After Stripe test payment: webhook should update subscription status

If any of the above fails, check:
- Supabase Functions → Logs for the failing function
- Browser DevTools → Network for 4xx/5xx
- Rollback if critical: `./scripts/rollback.sh v24.2-frozen-2026-04-20`

---

## STEP 8 — Stripe webhook smoke (optional, 5 min)

Only if you want to validate the new renewal handling (BIZ-M2 fix):

```bash
stripe listen --forward-to https://okgnkucgwsytsondrjye.supabase.co/functions/v1/stripe-webhook &
stripe trigger customer.subscription.updated --add subscription:status=active
stripe trigger customer.subscription.updated --add subscription:status=past_due
stripe trigger customer.subscription.updated --add subscription:status=canceled
```

Each event should update the corresponding row in `public.subscriptions` with the
new `status`, `current_period_end`, and `plan`.

---

## STEP 9 — Confirm deploy in channel / commit notes

Record in owner's dev log:

```
Date: 2026-04-22
Version: main @ 9b44082 (post-merge: code-quality + qa + sprint0 + launch/wave1 + ai-quality)
Tests: 1181 flutter + 98 deno = 1279 total passing
Migrations applied: 20260421_app_errors, 20260422_delete_own_policies, 20260422_schema_drift_fix
Edge Functions deployed: claude-proxy, create-checkout, deadline-reminder, stripe-webhook + 9 others untouched
Smoke: 21/21 green
New features live:
  - GDPR cookie banner on landing
  - Copy icon on AI messages + SelectableText for user messages
  - Chat attachments reach AI
  - Adaptive response length (short queries → short answers)
  - UPL-safe onboarding titles (ru/uk)
  - Opt-in Sentry-lite telemetry
Rollback if needed: ./scripts/rollback.sh v24.2-frozen-2026-04-20
```

---

## Rollback cheat sheet

**Full prod rollback** (gh-pages only — does NOT revert migrations or Edge Functions):
```bash
cd /Users/ai.place/Advocat/app/advocat_project
./scripts/rollback.sh v24.2-frozen-2026-04-20
```

**Reset main to pre-merge state** (destructive, only if deploy catastrophic and you need to re-plan):
```bash
git fetch github
git checkout main
git reset --hard backup-before-merge-20260422-183143
git push github main --force-with-lease
```

**Revert a specific merge** (safer, keeps history):
```bash
# Example: revert the fix/ai-quality merge
git revert -m 1 9b44082
git push github main
```

Tags available (each is a known-green state after that phase):
- `backup-before-merge-20260422-183143` — pre-anything (baseline)
- `after-code-quality-20260422-183536`
- `after-qa-20260422-183851`
- `after-sprint0-20260422-184316`
- `after-launch-wave1-20260422-184730`
- `after-ai-quality-20260422-193708` (current state)

---

## Pre-deploy checklist (print and tick)

- [ ] STEP 0  pre-deploy tag pushed
- [ ] STEP 1  GitHub PAT rotated
- [ ] STEP 2  4 orphan tables verified `rowsecurity=true`
- [ ] STEP 3  `supabase db push` successful
- [ ] STEP 4  `CRON_SECRET` set via `supabase secrets set`
- [ ] STEP 5  Cron header configured
- [ ] STEP 6  `./scripts/build-and-deploy.sh` → exit 0 + smoke 21/21 green
- [ ] STEP 7  Manual smoke: landing + app + chat + voice + copy button
- [ ] STEP 8  (optional) Stripe webhook smoke
- [ ] STEP 9  Dev log updated
