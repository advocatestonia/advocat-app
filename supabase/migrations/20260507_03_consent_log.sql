-- =====================================================================
-- consent_log — Pkg 0 / Track B-2 (GDPR-compliant Phase 2 schema)
--
-- Purpose:
--   Append-only audit trail of explicit consent under GDPR Art. 9 (special
--   categories — health), Art. 10 (criminal data), and US-transfer
--   acknowledgement, plus cookies/marketing for completeness.
--
-- Sister tables (this migration set):
--   * 20260507_01_sensitive_schema.sql              — encrypted parsed_text
--   * 20260507_02_audit_log.sql                     — generic audit trail
--   * 20260507_04_attorney_privilege_acceptance.sql — privilege disclaimer
--   * 20260507_05_pii_redaction_map.sql             — third-party PII tokens
--
-- Data lifecycle:
--   * INSERT only via SECURITY DEFINER RPC `grant_consent`.
--   * UPDATE permitted ONLY to set `revoked_at` (immutable everything else).
--   * DELETE forbidden (no policy = denied under RLS).
--
-- Idempotency:
--   * `if not exists` everywhere; safe to re-run with `supabase db push`.
-- =====================================================================

create table if not exists public.consent_log (
    id              uuid primary key default gen_random_uuid(),
    user_id         uuid not null references auth.users(id) on delete cascade,
    consent_type    text not null check (consent_type in (
        'art9_health', 'art10_criminal', 'us_transfer', 'cookies', 'marketing'
    )),
    granted         boolean not null,
    granted_at      timestamptz not null default now(),
    revoked_at      timestamptz,
    policy_version  text,
    ip              inet,
    user_agent      text
);

create index if not exists consent_log_user_idx
    on public.consent_log (user_id, consent_type, granted_at desc);

alter table public.consent_log enable row level security;

drop policy if exists "user reads own consent"   on public.consent_log;
drop policy if exists "no client insert"         on public.consent_log;
drop policy if exists "owner can revoke"         on public.consent_log;
drop policy if exists "owner can revoke own"     on public.consent_log;

-- READ: owner-only.
create policy "user reads own consent" on public.consent_log
    for select using (auth.uid() = user_id);

-- INSERT: forbidden from clients. Only SECURITY DEFINER RPC may insert.
create policy "no client insert" on public.consent_log
    for insert with check (false);

-- UPDATE: owner may modify their own row. The previous WITH CHECK pinned
-- (consent_type, granted, granted_at, policy_version) to NEW vs NEW, a
-- self-referential no-op that did NOT actually freeze anything. Real
-- enforcement now lives in the BEFORE UPDATE trigger
-- consent_log_immutable_fields below, which compares OLD vs NEW. Policy
-- keeps the auth scope; trigger keeps the data scope.
create policy "owner can revoke own" on public.consent_log
    for update
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

-- Trigger: only revoked_at may change on UPDATE. Any attempt to alter
-- user_id / consent_type / granted / granted_at / policy_version /
-- ip / user_agent raises an exception, so the row is effectively
-- append-only except for revocation timestamping.
create or replace function public.consent_log_immutability()
returns trigger
language plpgsql
as $$
begin
    if old.user_id is distinct from new.user_id then
        raise exception 'user_id is immutable';
    end if;
    if old.consent_type is distinct from new.consent_type then
        raise exception 'consent_type is immutable';
    end if;
    if old.granted is distinct from new.granted then
        raise exception 'granted is immutable (use revoked_at instead)';
    end if;
    if old.granted_at is distinct from new.granted_at then
        raise exception 'granted_at is immutable';
    end if;
    if old.policy_version is distinct from new.policy_version then
        raise exception 'policy_version is immutable';
    end if;
    if old.ip is distinct from new.ip then
        raise exception 'ip is immutable';
    end if;
    if old.user_agent is distinct from new.user_agent then
        raise exception 'user_agent is immutable';
    end if;
    return new;
end;
$$;

drop trigger if exists consent_log_immutable_fields on public.consent_log;
create trigger consent_log_immutable_fields
    before update on public.consent_log
    for each row
    execute function public.consent_log_immutability();

-- =====================================================================
-- RPC: grant_consent — single entry point for INSERT.
-- Called from Flutter consent modal after user clicks "Я согласен".
-- Returns the new row id so the client can store it for revocation.
-- =====================================================================
create or replace function public.grant_consent(
    p_consent_type   text,
    p_policy_version text,
    p_ip             inet,
    p_user_agent     text
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
    v_id uuid;
begin
    if auth.uid() is null then
        raise exception 'unauthorized' using errcode = '42501';
    end if;

    insert into public.consent_log (
        user_id, consent_type, granted, policy_version, ip, user_agent
    ) values (
        auth.uid(), p_consent_type, true, p_policy_version, p_ip, p_user_agent
    )
    returning id into v_id;

    return v_id;
end;
$$;

-- =====================================================================
-- RPC: check_consent — return true iff caller has granted (and not
-- revoked) ALL of `p_types`. Used by edge functions to gate Art. 9 /
-- Art. 10 / cross-border processing before processing user data.
-- =====================================================================
create or replace function public.check_consent(p_types text[])
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select coalesce(
        count(distinct consent_type) = array_length(p_types, 1),
        false
    )
    from public.consent_log
    where user_id     = auth.uid()
      and consent_type = any (p_types)
      and granted      = true
      and revoked_at   is null;
$$;

grant execute on function public.grant_consent(text, text, inet, text) to authenticated;
grant execute on function public.check_consent(text[])                  to authenticated;

-- B5: pin owners on the SECURITY DEFINER RPCs. Apply via service-role /
-- postgres connection so these ALTERs succeed; otherwise the migration
-- aborts loudly (preferred over silent mis-ownership). Function owned
-- by postgres for SECURITY DEFINER vault / audit_log access.
alter function public.grant_consent(text, text, inet, text) owner to postgres;
alter function public.check_consent(text[])                 owner to postgres;

-- PGRST schema cache reload — make new RPCs reachable after `db push`
-- (memory: reference_pitfalls_chat_infra).
notify pgrst, 'reload schema';
