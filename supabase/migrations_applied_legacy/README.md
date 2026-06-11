# Legacy migrations — already applied to prod, non-standard filenames

These 5 files have non-14-digit version prefixes (`20260509_01_*`, `20260520_*`,
`20260522_*`, `20260525_*`). The Supabase CLI (v2.84.2) truncates them to 8-digit
versions (`20260509`, `20260520` x2, `20260522`, `20260525`), which created
duplicate/malformed rows in `supabase migration list` and blocked `supabase db push`.

Their CONTENT IS ALREADY APPLIED on prod (verified 2026-06-11 via read-only
PostgREST probes / remote migration history):

| file                                 | evidence applied (all probes confirmed read-only 2026-06-11)                                |
| ------------------------------------ | ------------------------------------------------------------------------------------------- |
| `20260509_01_patch_case_facts.sql`   | fn `patch_case_facts` exists in pg_proc + remote history row `20260509` (truncated version) |
| `20260520_alert_tick_cron.sql`       | cron job `alert-tick-every-minute` exists in `cron.job`                                     |
| `20260520_user_oauth_tokens_rls.sql` | 4 `user_oauth_tokens_*_own` policies exist in pg_policies                                   |
| `20260522_spend_provider.sql`        | `anthropic_daily_spend.provider` column exists                                              |
| `20260525_consilium_telemetry.sql`   | `consilium_runs` table exists                                                               |

They were MOVED (not renamed) on purpose: renaming to fresh 14-digit versions would
queue them for re-execution by `db push`. Do NOT move them back and do NOT renumber
them. The orphan remote history row `20260509` is cleaned up by
`scripts/migration_history_repair.sh` (`migration repair --status reverted 20260509`).

Note: `001_complete_schema.sql`, `002_seed_data.sql`, `20260417_ai_usage.sql` also
have short versions but stay in `migrations/` — they are recorded identically in
BOTH local and remote history, so the CLI is in sync on them; moving them would
orphan their remote rows and re-block `db push`.
