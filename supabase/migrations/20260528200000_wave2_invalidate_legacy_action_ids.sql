-- Wave 2 W2-09: invalidate legacy pending action_ids before HMAC-canonical deploy.
-- -----------------------------------------------------------------------------
-- The hashToolInput contract changed (2026-05-28):
--   - OLD: JSON.stringify(toolInput) — insertion-order, full input.
--   - NEW: canonicalJsonStringify(visibleProjectionForTool(toolName, input))
--          — deep-sorted keys, projection of user-visible fields.
--
-- Any agent_runs row with status='awaiting_approval' issued BEFORE this
-- deploy holds an action_id that:
--   a. Was signed over the old args_sha256, AND
--   b. Has a payload missing the new `aud`/`purpose` fields.
--
-- Verifying such a token after deploy returns 409 (malformed_payload or
-- args_sha256_mismatch). The user's Approve tap would 409 silently.
--
-- Mitigation choice (per W2-09 spec option (b)):
--   Auto-invalidate all pending approvals older than 1 hour. Real-world
--   approvals resolve within minutes (the approval sheet TTL is 5 min);
--   the 1-hour window is a generous safety net for in-flight sheets at
--   deploy time. Newer in-flight approvals (<1h) will see action_id
--   verification fail and the user can re-issue by asking the agent
--   again — minor UX papercut, no data loss.
--
-- Production impact at deploy time (2026-05-28):
--   - 2 paying users (per CHECKPOINT FULL OFFENSIVE memory).
--   - agent_runs has 0 historical pending rows expected (agent MVP
--     shipped 2026-05-27, ~24h ago, and the approval window is 5 min).
--   - Migration is effectively a no-op on small-scale prod data but
--     guards future deploys touching the HMAC scheme.
-- -----------------------------------------------------------------------------

begin;

-- Invalidate any pending agent_runs row whose action_id was issued
-- under the legacy HMAC scheme. We mark them 'invalidated' (a new
-- terminal status — does NOT trigger the write tool, does NOT count
-- against quota retro-actively).
--
-- We don't fail if the status check column constraint rejects this
-- value (older deployments may not include 'invalidated' in the
-- agent_run_status check). Use the simpler 'rejected' status as a
-- compatible fallback.

do $$
declare
  v_count int;
begin
  -- Try to add 'invalidated' to the status check constraint if it
  -- exists. The check constraint is defined as a CHECK on the column;
  -- we drop and re-add it with the new value.
  begin
    alter table public.agent_runs
      drop constraint if exists agent_runs_status_check;
    -- Superset of the existing prod constraint (which carries in_progress +
    -- expired, both live statuses the agent loop uses) PLUS the new
    -- 'invalidated' terminal status. Must not narrow the allowed set.
    alter table public.agent_runs
      add constraint agent_runs_status_check
      check (status in (
        'in_progress',
        'awaiting_approval',
        'completed',
        'errored',
        'rejected',
        'expired',
        'invalidated'
      ));
  exception
    when others then
      -- If the constraint doesn't exist or shape differs, fall through
      -- to using 'rejected' below.
      raise notice 'agent_runs_status_check rewrite skipped: %', sqlerrm;
  end;

  -- Mark stale pending rows as invalidated. 1-hour window — the
  -- approval TTL is 5 min, so anything past 1h is dead anyway.
  update public.agent_runs
  set
    status = case
      when exists (
        select 1 from pg_constraint c
        where c.conname = 'agent_runs_status_check'
          and pg_get_constraintdef(c.oid) like '%invalidated%'
      ) then 'invalidated'
      else 'rejected'
    end,
    write_pending = null,
    completed_at = now(),
    updated_at = now(),
    audit_trail = coalesce(audit_trail, '[]'::jsonb) || jsonb_build_array(
      jsonb_build_object(
        'iter', coalesce(jsonb_array_length(audit_trail), 0) + 1,
        'tool', coalesce(write_pending->>'tool_name', 'unknown'),
        'decision', 'invalidated_legacy_hmac',
        'at', now()::text,
        'reason', 'W2-09 HMAC canonical-JSON deploy'
      )
    )
  where status = 'awaiting_approval'
    and (started_at < now() - interval '1 hour'
      or updated_at < now() - interval '1 hour');

  get diagnostics v_count = row_count;
  raise notice 'W2-09: invalidated % stale pending agent_runs rows', v_count;
end$$;

commit;

-- -----------------------------------------------------------------------------
-- Rollback note:
--   This migration is forward-only. Reverting the HMAC code without
--   reverting this migration is safe — invalidated rows stay
--   invalidated and the user simply re-asks the agent. There is no
--   data loss because write_pending was metadata, not user content.
-- -----------------------------------------------------------------------------
