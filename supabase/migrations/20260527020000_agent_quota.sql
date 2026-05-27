-- agent_quota — per-user daily cap for agent loop turns.
--
-- Each turn = one claude-proxy invocation that ran ≥1 iteration of the
-- agent loop (i.e. tool_use was returned). Read-only chat replies do NOT
-- count. Pro = 50/day, Counsel = 20/day, Free = 0/day.
--
-- Counter is rolled over daily (UTC). The increment fn is called from
-- claude-proxy AFTER the loop exits (success OR error — we book the
-- spend either way to defend against retry storms).
--
-- agent_audit_log — full per-iteration history for ops/forensics.
-- Even after agent_runs.audit_trail summarises a single run, this table
-- keeps the long-tail record for billing reconciliation + abuse review.

create table if not exists public.agent_quota (
  user_id uuid not null references auth.users(id) on delete cascade,
  day date not null default (current_date at time zone 'utc'),
  turns_used int not null default 0,
  last_turn_at timestamptz null,
  primary key (user_id, day)
);

create index if not exists agent_quota_day_idx on public.agent_quota (day);

alter table public.agent_quota enable row level security;

drop policy if exists "agent_quota owner read" on public.agent_quota;
create policy "agent_quota owner read"
  on public.agent_quota
  for select
  using (user_id = auth.uid());

drop policy if exists "agent_quota no client write" on public.agent_quota;
create policy "agent_quota no client write"
  on public.agent_quota
  for insert
  with check (false);

create table if not exists public.agent_audit_log (
  id uuid primary key default gen_random_uuid(),
  agent_run_id uuid null references public.agent_runs(id) on delete set null,
  user_id uuid not null references auth.users(id) on delete cascade,
  iter int not null,
  tool text not null,
  status text not null,
  input_tokens int not null default 0,
  output_tokens int not null default 0,
  cost_microcents int not null default 0,
  started_at timestamptz not null default now(),
  duration_ms int null,
  case_id uuid null,
  summary text null
);

create index if not exists agent_audit_log_user_idx
  on public.agent_audit_log (user_id, started_at desc);

create index if not exists agent_audit_log_run_idx
  on public.agent_audit_log (agent_run_id);

create index if not exists agent_audit_log_status_idx
  on public.agent_audit_log (status, started_at desc)
  where status <> 'ok';

alter table public.agent_audit_log enable row level security;

drop policy if exists "agent_audit_log owner read" on public.agent_audit_log;
create policy "agent_audit_log owner read"
  on public.agent_audit_log
  for select
  using (user_id = auth.uid());

drop policy if exists "agent_audit_log no client write" on public.agent_audit_log;
create policy "agent_audit_log no client write"
  on public.agent_audit_log
  for insert
  with check (false);

create or replace function public.check_and_increment_agent_quota(
  p_user_id uuid,
  p_tier_cap int
) returns table (turns_used int, tier_cap int, exhausted boolean)
language plpgsql
security definer
set search_path = 'public'
as $function$
declare
  v_today date := (current_date at time zone 'utc');
  v_used int;
begin
  insert into public.agent_quota (user_id, day, turns_used, last_turn_at)
  values (p_user_id, v_today, 1, now())
  on conflict (user_id, day) do update
    set turns_used = public.agent_quota.turns_used + 1,
        last_turn_at = now()
  returning public.agent_quota.turns_used into v_used;

  return query select v_used, p_tier_cap, v_used > p_tier_cap;
end;
$function$;

create or replace function public.record_agent_audit(
  p_agent_run_id uuid,
  p_user_id uuid,
  p_iter int,
  p_tool text,
  p_status text,
  p_input_tokens int default 0,
  p_output_tokens int default 0,
  p_cost_microcents int default 0,
  p_duration_ms int default null,
  p_case_id uuid default null,
  p_summary text default null
) returns uuid
language plpgsql
security definer
set search_path = 'public'
as $function$
declare
  v_id uuid;
begin
  insert into public.agent_audit_log (
    agent_run_id, user_id, iter, tool, status,
    input_tokens, output_tokens, cost_microcents,
    duration_ms, case_id, summary
  ) values (
    p_agent_run_id, p_user_id, p_iter, p_tool, p_status,
    p_input_tokens, p_output_tokens, p_cost_microcents,
    p_duration_ms, p_case_id, p_summary
  ) returning id into v_id;
  return v_id;
end;
$function$;

comment on table public.agent_quota is
  'Per-user daily turn cap for the agent loop (Day 9 2026-05-27). Pro 50, Counsel 20, Free 0 — enforced at the start of every claude-proxy turn.';
comment on table public.agent_audit_log is
  'Per-iteration history of every agent loop run for ops + billing reconciliation + abuse review.';
