-- =====================================================================
-- attorney_privilege_acceptance — Pkg 0 / Track B-2
--
-- Purpose:
--   One-time onboarding acknowledgement that Advocat is NOT the user's
--   attorney and that no attorney-client privilege exists. Record stored
--   immutably with policy_version, ip, user_agent so we can replay the
--   exact disclaimer text the user agreed to.
--
-- Lifecycle:
--   * INSERT only via SECURITY DEFINER RPC `accept_privilege_disclaimer`.
--   * No UPDATE / DELETE policy (denied by RLS) — record is immutable.
--   * `on conflict (user_id) do nothing` makes the RPC idempotent: the
--     first acceptance wins; later calls return without error.
--
-- Idempotency:
--   * `if not exists` everywhere; safe to re-run with `supabase db push`.
-- =====================================================================

create table if not exists public.attorney_privilege_acceptance (
    user_id         uuid primary key references auth.users(id) on delete cascade,
    accepted_at     timestamptz not null default now(),
    policy_version  text not null,
    ip              inet,
    user_agent      text
);

alter table public.attorney_privilege_acceptance enable row level security;

drop policy if exists "owner reads own"     on public.attorney_privilege_acceptance;
drop policy if exists "no client insert"    on public.attorney_privilege_acceptance;

-- READ: owner-only.
create policy "owner reads own" on public.attorney_privilege_acceptance
    for select using (auth.uid() = user_id);

-- INSERT: forbidden from clients (RPC-only insert path).
create policy "no client insert" on public.attorney_privilege_acceptance
    for insert with check (false);

-- No UPDATE / DELETE policies — implicit deny. Record is append-only.

-- =====================================================================
-- RPC: accept_privilege_disclaimer
--   Called once during onboarding. Idempotent via on-conflict.
-- =====================================================================
create or replace function public.accept_privilege_disclaimer(
    p_policy_version text,
    p_ip             inet,
    p_user_agent     text
) returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    if auth.uid() is null then
        raise exception 'unauthorized' using errcode = '42501';
    end if;

    insert into public.attorney_privilege_acceptance (
        user_id, policy_version, ip, user_agent
    ) values (
        auth.uid(), p_policy_version, p_ip, p_user_agent
    )
    on conflict (user_id) do nothing;
end;
$$;

grant execute on function public.accept_privilege_disclaimer(text, inet, text) to authenticated;

-- B5: pin owner on the SECURITY DEFINER RPC. Apply via service-role /
-- postgres connection so this ALTER succeeds. Function owned by postgres
-- so SECURITY DEFINER runs with privileges sufficient for any future
-- audit_log insert / vault read.
alter function public.accept_privilege_disclaimer(text, inet, text) owner to postgres;

notify pgrst, 'reload schema';
