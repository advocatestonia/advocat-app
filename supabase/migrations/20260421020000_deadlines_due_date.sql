-- v24.2.1: ensure deadlines.due_date exists on prod DB
-- The column is defined in 001_complete_schema.sql but the prod database
-- drifted (observed during OMEGA-FREEZE 2026-04-20). Idempotent ALTER.

do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'deadlines'
      and column_name = 'due_date'
  ) then
    alter table public.deadlines add column due_date date;
    create index if not exists idx_deadlines_due_date
      on public.deadlines (due_date);
  end if;
end $$;
