-- =====================================================================
-- sensitive.pii_redaction_map — Pkg 0 / Track B-2
--
-- Purpose:
--   Per-case mapping of redaction tokens → encrypted plaintext for
--   third-party PII discovered during PDF parsing. Tokens like
--   [PERSON_1], [ADDRESS_2], [PERSONAL_CODE_1] appear in parsed_summary
--   and the model context; only the case owner can un-redact via
--   the SECURITY DEFINER RPC `unredact`.
--
--   This protects bystanders (witnesses, officers, family) whose names
--   appear in police reports / court decisions but who are not the
--   data subject (the user). GDPR Art. 5(1)(c) data minimization.
--
-- Depends on:
--   * 20260507010000_sensitive_schema.sql — creates schema, pgcrypto, vault key.
--   * 20260507020000_audit_log.sql        — receives un-redact audit rows.
--
-- Idempotency:
--   * `if not exists` everywhere; safe to re-run with `supabase db push`.
-- =====================================================================

-- Schema/extension creation lives in 20260507010000_sensitive_schema.sql.
-- This re-issues `if not exists` guards in case migrations are applied
-- out of order (e.g. selective backfill). Both are no-ops when present.
create extension if not exists pgcrypto;
create schema if not exists sensitive;

create table if not exists sensitive.pii_redaction_map (
    case_id              uuid not null references public.user_cases(id) on delete cascade,
    token                text not null,
    plaintext_encrypted  bytea not null,
    category             text not null check (category in (
        'person', 'address', 'personal_code', 'plate', 'phone', 'email'
    )),
    created_at           timestamptz not null default now(),
    primary key (case_id, token)
);

alter table sensitive.pii_redaction_map enable row level security;
-- No policies — service_role / SECURITY DEFINER only.

-- =====================================================================
-- RPC: unredact
--   Owner-only un-redact with audit-log side effect. Returns plaintext
--   for a single (case_id, token) pair.
--
--   Audit semantics: a row is appended to public.audit_log ONLY when the
--   token actually existed and was decrypted. NOT FOUND probes (no such
--   token in the map) return NULL with no audit row, so the audit trail
--   tracks real disclosures and not user typos / probes.
-- =====================================================================
create or replace function public.unredact(p_case_id uuid, p_token text)
returns text
language plpgsql
security definer
set search_path = public, sensitive
as $$
declare
    v_owner uuid;
    v_key   text;
    v_plain text;
begin
    if auth.uid() is null then
        raise exception 'unauthorized' using errcode = '42501';
    end if;

    select user_id
      into v_owner
      from public.user_cases
     where id = p_case_id;

    if v_owner is null or v_owner <> auth.uid() then
        raise exception 'forbidden' using errcode = '42501';
    end if;

    select decrypted_secret
      into v_key
      from vault.decrypted_secrets
     where name = 'sensitive_doc_key'
     limit 1;

    if v_key is null then
        raise exception 'key_not_provisioned';
    end if;

    -- Decrypt FIRST. NULL means token not in map → return NULL, NO audit.
    select pgp_sym_decrypt(plaintext_encrypted, v_key)::text
      into v_plain
      from sensitive.pii_redaction_map
     where case_id = p_case_id
       and token   = p_token;

    if v_plain is null then
        return null;
    end if;

    -- Real disclosure happened — audit the read.
    insert into public.audit_log (user_id, action, target_table, target_id, details)
    values (
        auth.uid(),
        'read_sensitive',
        'sensitive.pii_redaction_map',
        p_case_id,
        jsonb_build_object('token', p_token)
    );

    return v_plain;
end;
$$;

grant execute on function public.unredact(uuid, text) to authenticated;

-- B5: pin owner on the SECURITY DEFINER RPC. Apply via service-role /
-- postgres connection so this ALTER succeeds. Function owned by postgres
-- for SECURITY DEFINER vault read access.
alter function public.unredact(uuid, text) owner to postgres;

notify pgrst, 'reload schema';
