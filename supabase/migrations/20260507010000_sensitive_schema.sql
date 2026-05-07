-- =====================================================================
-- sensitive schema + case_documents_sensitive — Pkg 0 / Track B-2
--
-- Purpose:
--   Column-level encrypted storage for GDPR Art. 9 (health) / Art. 10
--   (criminal) data extracted from uploaded PDFs (police reports,
--   medical records, court decisions). pgcrypto AES-symmetric on the
--   payload columns; key fetched from Supabase Vault per call.
--
-- Why a separate schema:
--   * `revoke usage on schema sensitive from authenticated/anon` makes
--     the schema invisible to PostgREST regardless of RLS, eliminating
--     the "client constructs URL and bypasses RLS" risk entirely.
--   * Only service_role and SECURITY DEFINER functions can touch it.
--
-- Migration of existing public.case_documents.parsed_text:
--   * NOT performed here. A separate operational migration backfills
--     after the Vault key `sensitive_doc_key` is provisioned by the
--     owner. This migration only creates structure.
--
-- Vault dependency:
--   * Reads the symmetric key from `vault.decrypted_secrets` where
--     name = 'sensitive_doc_key'. Owner must `select vault.create_secret('<key>', 'sensitive_doc_key')`
--     before the RPC can succeed; the RPC raises 'key_not_provisioned'
--     until then. Edge-function fallback (env var) is documented but
--     not implemented in this DB-only migration.
--
-- Apply prerequisites:
--   * Function owned by postgres for SECURITY DEFINER vault access.
--     Apply via service-role/postgres connection so the
--     `alter function ... owner to postgres` at the bottom succeeds.
-- =====================================================================

create extension if not exists pgcrypto;

create schema if not exists sensitive;

-- Lock down schema visibility.
revoke all on schema sensitive from public;
revoke all on schema sensitive from authenticated;
revoke all on schema sensitive from anon;
grant usage on schema sensitive to service_role;

-- =====================================================================
-- sensitive.case_documents_sensitive
--   1:1 with public.case_documents.id (FK + unique).
--   New rows for new uploads; existing rows backfilled by separate PR.
-- =====================================================================
create table if not exists sensitive.case_documents_sensitive (
    id                       uuid primary key default gen_random_uuid(),
    document_id              uuid not null references public.case_documents(id) on delete cascade,
    parsed_text_encrypted    bytea,
    key_extractions_encrypted bytea,
    encryption_key_version   int not null default 1,
    created_at               timestamptz not null default now()
);

create unique index if not exists sensitive_case_documents_doc_id_idx
    on sensitive.case_documents_sensitive (document_id);

alter table sensitive.case_documents_sensitive enable row level security;
-- No policies — RLS denies all access except service_role / SECURITY DEFINER.

-- =====================================================================
-- RPC: read_sensitive_doc
--   Owner-only decrypted read with audit-log side effect.
--
-- Auth chain:
--   1. auth.uid() must match public.case_documents.user_id for p_doc_id.
--   2. Vault key must exist.
--   3. Existence check FIRST — only insert audit row + return decrypted
--      payload if the sensitive row exists. A NOT FOUND probe by an
--      authorised owner of an empty doc returns an empty result set
--      with no audit entry (no fake-positive forensic noise).
--
-- Returns: (parsed_text text, key_extractions jsonb).
-- =====================================================================
create or replace function public.read_sensitive_doc(p_doc_id uuid)
returns table (parsed_text text, key_extractions jsonb)
language plpgsql
security definer
set search_path = public, sensitive
as $$
declare
    v_owner uuid;
    v_key   text;
    v_found boolean;
begin
    if auth.uid() is null then
        raise exception 'unauthorized' using errcode = '42501';
    end if;

    -- Ownership check via case_documents.user_id (set by RLS-protected insert).
    select cd.user_id
      into v_owner
      from public.case_documents cd
     where cd.id = p_doc_id;

    if v_owner is null or v_owner <> auth.uid() then
        raise exception 'forbidden' using errcode = '42501';
    end if;

    -- Vault-stored symmetric key. Owner provisions via:
    --   select vault.create_secret('<aes-256-passphrase>', 'sensitive_doc_key');
    select decrypted_secret
      into v_key
      from vault.decrypted_secrets
     where name = 'sensitive_doc_key'
     limit 1;

    if v_key is null then
        raise exception 'key_not_provisioned';
    end if;

    -- Existence check FIRST. Audit + return only if a sensitive row exists.
    select exists (
        select 1
          from sensitive.case_documents_sensitive
         where document_id = p_doc_id
    ) into v_found;

    if v_found then
        insert into public.audit_log (user_id, action, target_table, target_id, details)
        values (
            auth.uid(),
            'read_sensitive',
            'sensitive.case_documents_sensitive',
            p_doc_id,
            '{}'::jsonb
        );

        return query
        select
            pgp_sym_decrypt(s.parsed_text_encrypted,    v_key)::text,
            pgp_sym_decrypt(s.key_extractions_encrypted, v_key)::text::jsonb
          from sensitive.case_documents_sensitive s
         where s.document_id = p_doc_id;
    end if;
    -- NOT FOUND: return empty result set, no audit row.
end;
$$;

grant execute on function public.read_sensitive_doc(uuid) to authenticated;

-- B5: pin owner so SECURITY DEFINER runs as the role that holds vault
-- read access. Migration apply must be over a service-role / postgres
-- connection or this ALTER will fail loudly (preferred over silent
-- mis-ownership).
alter function public.read_sensitive_doc(uuid) owner to postgres;

-- NOTE: the encryption-side helper that writes ciphertext is owned by
-- the edge function that performs PDF parsing (Pkg 2). It uses the
-- service_role key, bypasses RLS, and writes to sensitive.* directly
-- with `pgp_sym_encrypt(plain, vault_key)`. Not a DB-side concern.

notify pgrst, 'reload schema';
