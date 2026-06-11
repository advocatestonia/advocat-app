-- ROLLBACK for 20260529130000_schedule_dead_crons.sql
-- Unschedules the two cron jobs this migration registered. Safe inverse:
-- removing the schedules simply returns to the (buggy) pre-migration state
-- where the edge functions never fired. No data is touched.
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
