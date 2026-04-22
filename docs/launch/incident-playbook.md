# Incident response playbook — Advocat v24.2.3

**Audience:** Sulga (owner / on-call). For a 1-person ops team, simplicity beats completeness.

---

## Emergency contacts

- **Owner:** Sulga — `aiplacest@gmail.com` / `support@advocat.ee`
- **Support inbox:** `support@advocat.ee` (auto-forwards to owner)
- **Hosting (Supabase):** https://supabase.com/dashboard/support (raise a ticket; paid tier has 24h SLA)
- **Payments (Stripe):** `https://support.stripe.com` (live chat 24/7)
- **AI provider (Anthropic):** `support@anthropic.com` (email, 1-2 business days)
- **Voice (ElevenLabs):** account dashboard chat, `support@elevenlabs.io`
- **GitHub:** `https://github.com/advocatestonia/advocat-app` (repo must remain PUBLIC — private breaks gh-pages deploy)

## Know before launch

| Fact                                            | Value                                         |
|-------------------------------------------------|-----------------------------------------------|
| Production URL                                  | `https://advocat.ee` (landing), `/app.html` (app) |
| Deploy script                                   | `./scripts/build-and-deploy.sh`               |
| Rollback script                                 | `./scripts/rollback.sh <tag>`                 |
| Last known-good tag                             | `v24.2-frozen-2026-04-20` → gh-pages `06e4d226` |
| Smoke test                                      | `./test/e2e/prod_smoke.sh` (21 checks)        |
| Supabase project ref                            | `okgnkucgwsytsondrjye`                        |
| Main Supabase region                            | `eu-central-1` (Frankfurt) — VERIFY pre-launch |
| Edge functions in prod                          | 13 (claude-proxy, create-checkout, customer-portal, check-company, check-vehicle, check-ai-quota, send-email, stripe-webhook, deadline-reminder, email-proxy, google-tts, tts-proxy, whisper-stt) |
| Bundle size floor                               | main.dart.js must be **5-8.5 MB** (smaller = SUPABASE_ANON_KEY not baked) |
| Stripe mode                                     | LIVE                                          |

---

## Smoke test (run before and after every deploy)

```bash
cd /Users/ai.place/Advocat/app/advocat_project
./test/e2e/prod_smoke.sh
```

Expected: `21/21 GREEN`. Anything less = DO NOT DEPLOY / rollback.

---

## Rollback procedures

### Full rollback to last known good (30 seconds)

```bash
cd /Users/ai.place/Advocat/app/advocat_project
./scripts/rollback.sh v24.2-frozen-2026-04-20
```

This restores gh-pages to commit `06e4d226` byte-for-byte. Verify by hitting `advocat.ee` and looking for the version string in the footer.

### Partial rollback of a single edge function

```bash
cd /Users/ai.place/Advocat/app/advocat_project
# Check out the previous good version of the function
git checkout v24.2-frozen-2026-04-20 -- supabase/functions/<function-name>/
# Deploy
supabase functions deploy <function-name> --project-ref okgnkucgwsytsondrjye
# Return working tree to current branch
git checkout HEAD -- supabase/functions/<function-name>/
```

### Rollback a DB migration (**destructive — use only if necessary**)

We don't have an automatic rollback for `.sql` migrations. For the Wave 1 telemetry migration, manual undo is:

```sql
drop table if exists public.app_errors cascade;
```

Run in Supabase SQL Editor. The rest of the app does not depend on this table.

---

## Common incidents and first actions

### 1. "Site is down" (landing or app returns 404 / 500)

1. Open `https://advocat.ee` in a private window.
2. Check `https://status.supabase.com` and `https://www.githubstatus.com`.
3. If both green, the issue is ours. Run the smoke test.
4. If smoke fails on checks 1-5 (landing/app reachability), rollback immediately.
5. If smoke fails on checks 16-21 (edge functions), see §2.

### 2. "AI chat returns errors"

1. Check Supabase edge function logs: Dashboard → Edge Functions → `claude-proxy` → Logs.
2. Common causes:
   - **Anthropic rate limit** — Anthropic dashboard → Usage. If burnt through the daily budget, raise the limit or wait.
   - **Anthropic outage** — check `https://status.anthropic.com`.
   - **Expired prompt cache** — short-lived, self-heals in minutes.
   - **System prompt too large** — check `SystemPrompts.buildChatPrompt` did not blow past model context window.
3. Mitigation: if persistent, flip the `DEGRADED_AI_MODE` flag (currently not implemented — **TODO post-launch**) to show "Our AI is temporarily unavailable, try again in a few minutes" instead of raw errors.

### 3. "Deadline reminders not firing"

1. Wave 1 fixed the enum bug — verify `deadline-reminder` edge function is deployed at the v2+ version (checklist item 1.4).
2. Invoke manually to test:
   ```bash
   curl -X POST https://okgnkucgwsytsondrjye.supabase.co/functions/v1/deadline-reminder \
     -H "Authorization: Bearer $SERVICE_ROLE_KEY"
   ```
   Expected: `{"checked": N, "notifications": M, ...}`.
3. If `"fetch_failed"`, check `deadlines.status` enum values in SQL Editor — must be `upcoming`/`overdue`/`completed`/`cancelled`.

### 4. "Payments failing"

1. Check Stripe dashboard → Events → Filter: last 1h, failed.
2. Cross-check `stripe-webhook` edge function logs for 500s.
3. If webhook fails: users may be charged but not see Pro features. Manually reconcile via Stripe dashboard → Customer → Subscription → Sync with our DB.
4. If Stripe itself is down: users cannot upgrade; display "Payments temporarily unavailable" and rely on support@advocat.ee for manual sign-ups.

### 5. "User reports account deletion did not work"

1. In Supabase SQL Editor:
   ```sql
   select count(*) from chat_messages where user_id = '<user-uid>';
   select count(*) from documents where user_id = '<user-uid>';
   select count(*) from cases where user_id = '<user-uid>';
   select count(*) from deadlines where user_id = '<user-uid>';
   ```
   Any non-zero = incomplete deletion. This is a **GDPR Art. 17 incident** — 72h response window.
2. Complete deletion manually by running the same delete chain from `supabase_service.deleteAllUserData()` via SQL Editor.
3. Auth user deletion: Dashboard → Authentication → Users → Find by email → Delete.
4. Apologise via `support@advocat.ee`, confirm completion in writing. Log the incident in `docs/incidents/YYYY-MM-DD-gdpr-delete.md` for audit trail.

### 6. "Suspected data breach"

1. Immediately rotate: Supabase anon key, service_role key, all edge function secrets, Stripe restricted keys.
2. Deploy with new keys within 1 hour of detection.
3. GDPR Art. 33 notification: **72 hours** to notify the Estonian DPA (Andmekaitse Inspektsioon, `info@aki.ee`). Do NOT delay.
4. If any user data was actually exfiltrated: also notify affected users (Art. 34) without undue delay.
5. Template for DPA notification: https://www.aki.ee — search "rikkumisest teatamine".

---

## First-day-after-launch monitoring checklist

Run this once at launch time, again 6h later, again 24h later:

- [ ] Landing page loads (<2 s)
- [ ] Smoke test 21/21
- [ ] Supabase dashboard: no red error spikes in last 1h
- [ ] Stripe: successful charges visible, no webhook errors
- [ ] Anthropic usage: within expected envelope (estimate ~$5-$10/day for <1000 MAU)
- [ ] ElevenLabs credits burned: verify we are not hitting the 131k/month cap on day 1
- [ ] Check `app_errors` table (if owner has enabled telemetry + migration applied):
  ```sql
  select error_type, count(*) from app_errors
  where occurred_at > now() - interval '24 hours'
  group by error_type order by 2 desc limit 10;
  ```
- [ ] Scan `support@advocat.ee` for complaints.

---

## What the owner is NOT expected to do themselves

- Complex on-call rotation — no one else on the team yet.
- Automated paging (PagerDuty etc.) — overkill at <1000 users. UptimeRobot SMS to the owner's phone is sufficient.
- Sub-second response SLAs — this is a consumer legal-info product, not a 911 dispatcher. Best-effort response within 24h is documented in Terms §6.

---

## Known edge cases from dev

- **Apr 18 / Apr 20 outages** — both caused by hand-crafted `flutter build web` that did not bake the anon key. Fix: **always** use `./scripts/build-and-deploy.sh`, never `flutter build web` directly.
- **Landing preserved byte-for-byte** — the deploy script preserves `landing.html` because the v2 designer polish is not in the Flutter build. If we ever regenerate it, diff against `web/landing-v24-backup.html`.
- **ElevenLabs v3 burns credits ~2× v2** — planned; escalation path is Creator → Pro ($99) → Scale ($330) as DAU grows.
- **Private repo breaks gh-pages deploy** — if someone toggles the repo to private, the deploy goes red. Keep it public.
- **Finnish/Russian/English route through ElevenLabs v3 (Charlotte / George)** — per owner preference 2026-04-21. Do NOT swap back to Rachel/Adam without explicit owner approval.
