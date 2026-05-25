-- =====================================================================
-- mark_b2b_modal_shown RPC — Flutter calls this after rendering the
-- B2B lead modal (either on dismiss OR on "Learn more" navigate).
-- Sets b2b_modal_shown_at=now() and b2b_modal_pending=false so the
-- modal does not fire again. Companion to record_b2b_signal in
-- 20260525223000_b2b_signals.sql.
--
-- Idempotent: re-calling is a no-op if already set. SECURITY DEFINER
-- so authenticated users can flip their own row without granting
-- direct UPDATE on profiles.
-- =====================================================================

create or replace function public.mark_b2b_modal_shown(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Defence-in-depth: refuse cross-user marks. auth.uid() must equal
  -- the target. Service-role bypasses this via grant.
  if auth.uid() is not null and auth.uid() <> p_user_id then
    raise exception 'cross_user_mark_forbidden';
  end if;

  update public.profiles
     set b2b_modal_shown_at = coalesce(b2b_modal_shown_at, now()),
         b2b_modal_pending  = false
   where id = p_user_id
     and (b2b_modal_shown_at is null or b2b_modal_pending = true);
end;
$$;

revoke all on function public.mark_b2b_modal_shown(uuid) from public;
grant execute on function public.mark_b2b_modal_shown(uuid) to authenticated, service_role;

comment on function public.mark_b2b_modal_shown(uuid) is
  'Flutter calls after rendering B2B lead modal. Idempotent. Sets b2b_modal_shown_at + clears pending flag.';

-- Hot-reload PostgREST schema cache so the new RPC is callable from
-- the Flutter client without a project restart.
notify pgrst, 'reload schema';
