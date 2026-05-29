-- Schedule the two dead cron jobs: deadline-radar-tick + agent-intentions-cron
-- -----------------------------------------------------------------------------
-- Bug (launch blocker, 2026-05-29): both edge functions were deployed with a
-- working x-cron-secret gate (checkCronSecret) and --no-verify-jwt, but NO
-- migration ever registered a pg_cron schedule for them. They simply never
-- fired. Effect for a PAID feature:
--
--   • deadline-radar-tick — case_deadlines were scanned by nobody, so users
--     paying for Deadline Radar got ZERO push / in-app / email reminders.
--   • agent-intentions-cron — long-horizon follow-up intentions never matured.
--
-- Why the gateway is fine
-- -----------------------
-- build-and-deploy.sh deploys every function with `--no-verify-jwt`, so the
-- platform never demands a JWT. Auth is entirely the in-code checkCronSecret
-- gate, which compares the `x-cron-secret` header to the CRON_SECRET env var.
--
-- Why invoke_edge_cron is the right caller
-- ----------------------------------------
-- pg_cron's net.http_post cannot read the cron secret on its own. The existing
-- public.invoke_edge_cron(text) RPC (migration 20260528060000) reads
-- `supabase_functions_url` + `cron_secret` from vault.decrypted_secrets and
-- attaches the x-cron-secret header — exactly what these gates require. This is
-- the SAME path alert-tick / spend-snapshot-hourly already use successfully
-- (migration 20260520_alert_tick_cron.sql).
--
-- Cadence (from each function's own header docs):
--   • deadline-radar-tick   — every 15 minutes
--   • agent-intentions-cron — hourly
--
-- Fail-soft: if the vault entries are not yet populated, invoke_edge_cron logs
-- a NOTICE and no-ops. Re-running this migration is safe (drop-then-schedule).
-- -----------------------------------------------------------------------------

-- Drop any prior entries so re-running replaces rather than errors on dup name.
do $$
declare jid bigint;
begin
  for jid in select jobid from cron.job where jobname = 'deadline-radar-tick-15min' loop
    perform cron.unschedule(jid);
  end loop;
  for jid in select jobid from cron.job where jobname = 'agent-intentions-cron-hourly' loop
    perform cron.unschedule(jid);
  end loop;
end$$;

-- Deadline radar: every 15 minutes. The function de-dupes its own fan-out via
-- the notification ledger, so cron drift is harmless.
select cron.schedule(
  'deadline-radar-tick-15min',
  '*/15 * * * *',
  $$select public.invoke_edge_cron('deadline-radar-tick');$$
);

-- Agent intentions: top of every hour.
select cron.schedule(
  'agent-intentions-cron-hourly',
  '0 * * * *',
  $$select public.invoke_edge_cron('agent-intentions-cron');$$
);
