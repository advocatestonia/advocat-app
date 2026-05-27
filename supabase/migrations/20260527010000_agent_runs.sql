-- agent_runs — server-side multi-turn agent loop state.
--
-- Pattern: claude-proxy loops up to MAX_AGENT_ITERATIONS=5 calling tools.
-- READ tools (list_inbox, read_thread_full, run_pdf_parser, run_consilium)
-- execute inline. When the model requests a WRITE tool (send_email,
-- generate_pdf, etc.) the loop STOPS, writes one agent_runs row with
-- status='awaiting_approval' + the pending write action, emits an
-- awaiting_approval SSE event, returns to Flutter. The user reviews +
-- taps Approve → /agent-approve verifies the HMAC action_id, looks up
-- this row, dispatches the write, marks status='completed'.
--
-- write_pending JSONB shape:
--   {
--     "tool_use_id": "tu_abc123",
--     "tool_name": "send_email",
--     "tool_input": { ...original Anthropic tool_use.input... },
--     "args_sha256": "hex",          -- binds approval to exact args
--     "action_id": "base64url.hex"    -- the signed token sent to UI
--   }
--
-- audit_trail JSONB shape:
--   [
--     { iter: 1, tool: "list_inbox", result_summary: "5 threads" },
--     { iter: 2, tool: "read_thread_full", ... },
--     ...
--   ]
--
-- RLS: owner-only (user_id = auth.uid()). Edge fns use service role.

create table if not exists public.agent_runs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  status text not null check (status in (
    'in_progress',         -- loop running
    'awaiting_approval',   -- write tool requested, sheet shown
    'completed',           -- final reply delivered
    'rejected',            -- user declined the write
    'errored',             -- HTTP/loop failure
    'expired'              -- approval window passed
  )),
  started_at timestamptz not null default now(),
  completed_at timestamptz null,
  -- Iteration count when the loop exited (0-based).
  iterations int not null default 0,
  -- The user's original message that started this turn (truncated 1000 chars).
  user_message text null,
  -- Pending write action — JSON envelope (see file header).
  write_pending jsonb null,
  -- Per-iteration trail — JSON array of { iter, tool, summary }.
  audit_trail jsonb not null default '[]'::jsonb,
  -- Cost rollup (cents). recordSpend already books per-iter; this is the
  -- aggregate for the agent_runs dashboard.
  total_cost_cents int not null default 0,
  -- Optional case linkage when the agent ran in a case context.
  case_id uuid null,
  updated_at timestamptz not null default now()
);

create index if not exists agent_runs_user_idx
  on public.agent_runs (user_id, started_at desc);

create index if not exists agent_runs_status_idx
  on public.agent_runs (status, started_at desc)
  where status in ('in_progress', 'awaiting_approval');

create index if not exists agent_runs_awaiting_approval_idx
  on public.agent_runs (user_id, started_at desc)
  where status = 'awaiting_approval';

alter table public.agent_runs enable row level security;

drop policy if exists "agent_runs owner read" on public.agent_runs;
create policy "agent_runs owner read"
  on public.agent_runs
  for select
  using (user_id = auth.uid());

drop policy if exists "agent_runs no client write" on public.agent_runs;
create policy "agent_runs no client write"
  on public.agent_runs
  for insert
  with check (false);

drop policy if exists "agent_runs no client update" on public.agent_runs;
create policy "agent_runs no client update"
  on public.agent_runs
  for update
  using (false);

comment on table public.agent_runs is
  'Server-side multi-turn agent loop state (claude-proxy Day 4 2026-05-27). Records pending write-tool approvals + audit trail.';
comment on column public.agent_runs.write_pending is
  'JSON envelope: {tool_use_id, tool_name, tool_input, args_sha256, action_id}. NULL once the action is executed or rejected.';
comment on column public.agent_runs.audit_trail is
  'Per-iteration log: [{iter, tool, summary}]. Tail-appended each loop iteration.';
