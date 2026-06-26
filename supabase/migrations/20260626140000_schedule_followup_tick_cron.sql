-- Schedule the followup-tick cron (Smart Case Follow-ups, Feature #2).
-- -----------------------------------------------------------------------------
-- Bug (found in the 2026-06-26 full audit): the followup-tick edge function was
-- deployed with a working x-cron-secret gate and --no-verify-jwt, and the
-- case_followups migration (20260614100000) even builds a dedicated cron-scan
-- index (case_followups_cron_scan_idx ... where status='open' and
-- reminded_at is null) for it — but NO migration ever registered a pg_cron
-- schedule. So the T-1-day "your follow-up is due tomorrow" reminder never
-- fired automatically; the feature only worked if invoked manually.
--
-- Cadence: daily at 08:00 UTC. The function selects OPEN follow-ups due
-- tomorrow or already overdue and stamps reminded_at, so it is idempotent and
-- cron drift is harmless (a row is never nudged twice). Daily is the right
-- granularity for a T-1-day reminder window.
--
-- Same caller path as the other ticks: public.invoke_edge_cron(text) reads the
-- supabase_functions_url + cron_secret from vault and attaches the
-- x-cron-secret header the gate requires. Fail-soft: if vault is unpopulated,
-- invoke_edge_cron logs a NOTICE and no-ops.
--
-- Idempotent: drop-then-schedule + pg_cron presence guard.
-- -----------------------------------------------------------------------------
do $$
declare jid bigint;
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    -- Replace any prior entry so re-running this migration never errors on dup name.
    for jid in select jobid from cron.job where jobname = 'followup-tick-daily' loop
      perform cron.unschedule(jid);
    end loop;

    perform cron.schedule(
      'followup-tick-daily',
      '0 8 * * *',
      $cron$select public.invoke_edge_cron('followup-tick');$cron$
    );
  else
    raise notice 'pg_cron not installed; skipping followup-tick schedule';
  end if;
end$$;
