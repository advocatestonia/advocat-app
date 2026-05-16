# Disaster recovery runbook — Advocat

**Audience:** Sulga (owner / on-call). One-person ops team. Read top-to-bottom before an incident; jump to "Recovery procedures" during one.

**Last drill:** see `public.backup_audit_log WHERE kind='drill' ORDER BY run_at DESC LIMIT 1;`

**RTO target:** 4 hours (database restored, app responding)
**RPO target:** 24 hours (max data loss = one nightly window)

---

## TL;DR — the 30-second answer

| Question | Answer |
| --- | --- |
| Where are the backups? | (a) Supabase Pro daily auto-backups (last 7 days, in-region), (b) our nightly dump on S3/R2 (last 14 days), (c) GitHub Actions artifact (last 7 runs) |
| How fresh? | < 24h (nightly @ 03:00 UTC) |
| Where is the runbook? | this file |
| When was the last verified restore? | `SELECT run_at FROM backup_audit_log WHERE kind='drill' AND status='success' ORDER BY run_at DESC LIMIT 1;` |
| Who decides "declare disaster"? | Owner (Sulga). No quorum needed — one-person team. |

---

## Backup layers (defence in depth)

| Layer | Source | Retention | Restore time (RTO) | Used when |
| --- | --- | --- | --- | --- |
| **L1** | Supabase Pro PITR (Point-In-Time Recovery) | 7 days, in-region | ~15 min for partial, ~1h full | Default: corruption / fat-finger DELETE |
| **L2** | Nightly pg_dump → R2/B2/S3 (scripts/db_dump.sh) | 14 days, off-provider | ~30 min download + ~1h restore | Supabase project deleted / billing lapse |
| **L3** | GitHub Actions artifact (last 7 workflow runs) | 7 days | ~10 min download + ~1h restore | Both Supabase AND object storage gone |
| **L4** | Local dump on owner's laptop (manual, `./scripts/db_dump.sh --local-only`) | discretionary | ~1h restore | Total provider catastrophe |

L1 is Supabase's responsibility. L2-L4 are ours. **All four must be reachable independently.**

---

## Trigger conditions — when to declare a disaster

Declare a recovery and start this runbook when **any** of the following is true:

1. `advocat.ee` returns 5xx for **> 15 minutes** AND Supabase status page shows incident
2. User reports data loss (deleted conversation, missing contract) that cannot be explained by user action
3. Supabase project is unreachable (DNS / auth) for **> 30 minutes**
4. Audit log shows `hours_since_last_good_backup() > 30`
5. Stripe webhook log shows orphan `checkout.session.completed` events (suggests DB write loss)
6. Owner sees suspicious activity (cryptocurrency mining workload, mass DELETE)

**Do NOT declare** for:
- Single-user complaints (90% are PEBKAC — check `claude-proxy` logs first)
- One failed nightly backup (the table will fire an alert; investigate, don't restore)
- Supabase < 5min outages (transient)

---

## Communication plan

Within 10 minutes of declaring:

1. **Update status page** (manual): edit `index.html` line 1 banner → push to gh-pages → 1-2 min propagation.
   ```bash
   cd /Users/ai.place/Advocat/app/advocat_project
   # quick banner edit, then:
   ./scripts/canary-deploy.sh --staging-only  # skip canary, push direct
   ```
2. **Email blast** to active users (last 30 days) via `send-email` edge fn:
   ```bash
   # Template: docs/templates/incident-email.md (TODO)
   # Subject: "Advocat — service interruption — restoring now"
   ```
3. **Telegram channel** (if `TELEGRAM_BOT_TOKEN` set): automatic via db_dump.sh failure path.
4. **Discord / Twitter** (manual, optional): "We're restoring from backup, ETA 4h, all data is safe."

**Do NOT** promise zero data loss. RPO is 24h — be honest.

---

## Recovery procedures

### Procedure A — Single-user data loss (most common, low-stakes)

> "User says their conversation from yesterday is gone."

1. Verify via `audit.log` (if it exists) or `conversations` table:
   ```sql
   SELECT id, user_id, created_at, updated_at, deleted_at
   FROM public.conversations
   WHERE user_id = '<uuid>'
   ORDER BY created_at DESC
   LIMIT 20;
   ```
2. If `deleted_at IS NOT NULL` → soft delete, restore via:
   ```sql
   UPDATE public.conversations SET deleted_at = NULL WHERE id = '<conv-id>';
   ```
3. If truly missing → restore the row from a recent dump:
   ```bash
   cd /Users/ai.place/Advocat/app/advocat_project
   # download latest nightly
   aws --endpoint-url $AWS_ENDPOINT_URL s3 cp \
     s3://advocat-backups/advocat_$(date -u -v-1d +%Y-%m-%d).sql.gz \
     ./backups/restore_tmp/

   # extract just the rows you need (don't restore the whole DB!)
   gunzip -c ./backups/restore_tmp/advocat_*.sql.gz \
     | grep -A 1000 "COPY public.conversations" \
     | grep "<user-uuid>"

   # then INSERT them back into prod via psql
   ```

**RTO: 30 min. No outage required.**

---

### Procedure B — Schema-level corruption (medium-stakes)

> "A bad migration broke the conversations table" / "ai_usage rows have NULL totals everywhere"

1. **Stop writes** (puts the app in read-only mode):
   ```bash
   # Edit claude-proxy to return 503 for POST requests:
   cd app/advocat_project/supabase/functions/claude-proxy
   # Insert at top of handler:
   #   if (req.method === 'POST') return new Response('READ_ONLY', { status: 503 })
   supabase functions deploy claude-proxy --no-verify-jwt
   ```
2. **Use Supabase PITR** (L1, fastest path):
   - Dashboard → Project Settings → Database → Backups → Point-in-time recovery
   - Pick a timestamp **before** the bad migration
   - Restore to a **new project** first (NEVER overwrite prod on first attempt)
   - Verify counts + spot-check
   - Then either: (a) cutover DNS to new project, or (b) export-import the affected table
3. **Re-enable writes** + run prod smoke.

**RTO: 1-2 hours. Brief outage (writes off, reads on).**

---

### Procedure C — Total project loss (worst case)

> "Supabase project is gone (deleted by mistake / billing / region outage)"

1. **Provision a new Supabase project** (same region: `eu-central-1`):
   ```bash
   # Manual via dashboard — there is no CLI for project create.
   # Note the new project ref. Set as STAGING_DB_URL.
   ```
2. **Restore from L2 (R2/B2/S3 dump)**:
   ```bash
   cd /Users/ai.place/Advocat/app/advocat_project
   STAGING_DB_URL='postgres://...new-project...' \
   SUPABASE_SERVICE_KEY=$NEW_SERVICE_KEY \
     ./scripts/restore_drill.sh
   # This restores the latest nightly dump and verifies counts.
   ```
3. **Restore corpus data** (the 36K law chunks are EXCLUDED from nightly dumps):
   ```bash
   # The corpus is reproducible from source. Re-ingest:
   cd /Users/ai.place/Advocat/app/advocat_project
   deno run --allow-all scripts/ingest_law_corpus.ts
   # Time: ~30 min for ET + EU + FI. Cost: ~$0.50 in OpenAI embeddings.
   ```
4. **Re-deploy edge functions**:
   ```bash
   cd /Users/ai.place/Advocat/app/advocat_project
   supabase link --project-ref <new-ref>
   for fn in supabase/functions/*/; do
     name=$(basename "$fn")
     supabase functions deploy "$name" --no-verify-jwt
   done
   ```
5. **Update DNS** (if URL changed):
   - `app/advocat_project/.env.prod` → new `SUPABASE_URL` + `SUPABASE_ANON_KEY`
   - Rebuild + canary-deploy
6. **Auth users**: Supabase auth.users table is **separate** from public schema. PITR (L1) is the only source. If lost entirely, users must re-register and we owe them a credit. RPO worst case = 7 days (Pro plan).

**RTO: 4 hours. Full outage. RPO: 24h.**

---

### Procedure D — Auth.users specifically

Supabase auth schema is **not** in our nightly dumps (we dump `--schema=public` only). It is covered exclusively by:
- L1 (Supabase PITR)
- The owner's manual export via `supabase db dump --schema auth` (TODO: add to a separate weekly workflow)

**Mitigation:** every new user gets a confirmation email — those are recoverable proof of registration. Combined with Stripe customer records, we can manually rebuild ~80% of paying users in a worst-case auth wipeout.

---

## Owner contact ladder

For the actual disaster, in order:

1. **Self** (Sulga) — most incidents
2. **Supabase support** — paid tier ticket: https://supabase.com/dashboard/support (24h SLA)
3. **Stripe support** — only if payments affected: https://support.stripe.com (live chat)
4. **Cloudflare** — if R2 backup destination is down: https://dash.cloudflare.com/?to=/:account/support
5. **Anthropic** — only if `claude-proxy` API key compromised: support@anthropic.com

Friends / external advice (no formal SLA, ask politely):
- Discord: Supabase community (#help channel), usually responsive
- Telegram: r/SaaS / r/sideproject communities

---

## Drill schedule

Run `scripts/restore_drill.sh` against a staging project on a regular cadence:

| Frequency | Trigger | Who |
| --- | --- | --- |
| **Monthly** | Calendar reminder, first Monday | Owner |
| **Before any risky migration** | manual: `./scripts/db_dump.sh --kind pre_migration` then `./scripts/restore_drill.sh` | Owner |
| **After GitHub Actions workflow change** | the workflow itself runs `restore_drill.sh --dry-run` as a smoke check | CI |

Record outcome in `backup_audit_log`. If `hours_since_last_good_drill() > 60 days` → put it on next week's agenda.

---

## Known gaps (be honest)

1. **Auth users only in L1.** A separate weekly `supabase db dump --schema auth` is on the TODO list. Until then, RPO for auth.users = 7 days from Supabase PITR.
2. **Storage bucket (PDF uploads).** Not backed up at all. PDFs are user-uploaded contracts; they re-upload on next session. Acceptable for v1.
3. **Edge function source.** Lives in git. If GitHub is also down (extremely unlikely), recovery requires `supabase functions list` + manual extraction from a Supabase dashboard cache.
4. **Stripe webhook deliveries during outage.** Stripe retries for 72h. We must process the backlog on recovery — see `customer-portal` retry queue.
5. **No tested cross-region recovery.** Supabase project is `eu-central-1` only. If Frankfurt goes dark, we are dark.
6. **Telegram bot not yet configured.** Owner action: create bot via @BotFather, store TELEGRAM_BOT_TOKEN + TELEGRAM_CHAT_ID in GitHub secrets + Supabase env.

---

## Audit log queries

Useful one-liners (run as service_role):

```sql
-- Last 7 days of backup runs
SELECT run_at, kind, status, pg_size_pretty(dump_bytes), duration_seconds
FROM public.backup_audit_log
WHERE run_at > NOW() - INTERVAL '7 days'
ORDER BY run_at DESC;

-- Are we current?
SELECT public.hours_since_last_good_backup();
-- > 30 → fire an alarm.

-- Drift over time
SELECT
  DATE(run_at) AS day,
  (table_counts->>'profiles')::INTEGER AS profiles,
  (table_counts->>'conversations')::INTEGER AS conversations,
  (table_counts->>'ai_usage')::INTEGER AS ai_usage
FROM public.backup_audit_log
WHERE kind = 'nightly' AND status = 'success'
ORDER BY run_at DESC
LIMIT 30;

-- Last successful drill
SELECT run_at, duration_seconds, notes
FROM public.backup_audit_log
WHERE kind = 'drill' AND status = 'success'
ORDER BY run_at DESC LIMIT 1;
```

---

## Change history

- **2026-05-15** — Initial runbook. Backup layers L1-L4, restore drill script, audit log table created. P4 of Bentley batch.
