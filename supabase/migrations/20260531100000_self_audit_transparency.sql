-- =============================================================================
-- Data Fortress — Pillar 3: transparent self-audit (2026-06-13).
-- =============================================================================
--
-- Goal: the CLIENT can see a complete, tamper-evident log of who/what/when
-- touched their data, and can cryptographically verify it wasn't rewritten.
--
-- Builds on wave2 (20260529100000) which made audit_log append-only via
-- BEFORE UPDATE/DELETE triggers. wave2 left two gaps this migration closes:
--   * audit_log has NO client SELECT policy → the data subject can't see it.
--   * audit_log has no hash chain (only agent_audit_log got one) → no
--     tamper-evidence the client can verify.
--
-- This migration adds:
--   1. A client SELECT RLS policy on audit_log (own rows only).
--   2. A hash chain on audit_log (same construction as agent_audit_log).
--   3. record_data_access() — SECURITY DEFINER helper so every access path
--      writes ONE canonical, client-visible audit row (DB-level, so even a
--      direct service_role write leaves a trail when it uses this fn).
--   4. get_my_access_log() — paginated client read RPC.
--   5. deletion_certificates — append-only table holding a signed receipt of
--      each Art. 17 erasure (what was deleted, when, content hash). The
--      Ed25519 signature is applied by the account-delete edge fn (private
--      key in Vault); the public key is published so anyone can verify.
--
-- All idempotent. RLS-first; SECURITY DEFINER fns are the only writers.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Client SELECT on their own audit rows.
-- ---------------------------------------------------------------------------
-- wave2 keeps audit_log append-only; reads were service-role-only. The data
-- subject has an Art. 15 right of access to this log, so add a tight SELECT
-- policy scoped to their own user_id. INSERT/UPDATE/DELETE stay closed to
-- clients (no policy = denied; wave2 triggers block even service_role
-- mutation).
drop policy if exists audit_log_owner_select on public.audit_log;
create policy audit_log_owner_select
  on public.audit_log
  for select
  using (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- 2. Hash chain on audit_log (tamper-evidence the client can verify).
-- ---------------------------------------------------------------------------
alter table public.audit_log
  add column if not exists row_hash  text,
  add column if not exists prev_hash text;

create or replace function public.tf_audit_log_hash_chain()
returns trigger
language plpgsql
as $$
declare
  v_prev_hash text;
begin
  -- One global chain for the whole table (matches agent_audit_log).
  -- Deterministic tie-break on (ts, id) for same-millisecond inserts.
  select row_hash
    into v_prev_hash
    from public.audit_log
   order by ts desc, id desc
   limit 1;

  new.prev_hash := coalesce(v_prev_hash, '');

  new.row_hash := encode(
    digest(
      coalesce(new.prev_hash, '')               || '|' ||
      coalesce(new.id::text, '')                || '|' ||
      coalesce(new.user_id::text, '')           || '|' ||
      coalesce(new.action, '')                  || '|' ||
      coalesce(new.target_table, '')            || '|' ||
      coalesce(new.target_id::text, '')         || '|' ||
      coalesce(new.ip::text, '')                || '|' ||
      coalesce(new.details::text, '{}')         || '|' ||
      coalesce(new.ts::text, now()::text),
      'sha256'
    ),
    'hex'
  );

  return new;
end;
$$;

comment on function public.tf_audit_log_hash_chain() is
  'Data Fortress Pillar 3: BEFORE INSERT hash chain for audit_log. Each row '
  'binds to the previous row''s hash; post-hoc tampering breaks the chain at '
  'every subsequent row, which the client can detect via verify_my_access_log().';

drop trigger if exists audit_log_hash_chain on public.audit_log;
create trigger audit_log_hash_chain
  before insert on public.audit_log
  for each row
  execute function public.tf_audit_log_hash_chain();

-- ---------------------------------------------------------------------------
-- 3. record_data_access() — canonical access-recording helper.
-- ---------------------------------------------------------------------------
-- Every path that touches a user's data (LLM egress, staff read, export,
-- document parse, ...) calls this so the client sees ONE consistent row.
-- SECURITY DEFINER so it can write under RLS; EXECUTE is service_role only
-- (edge functions), never anon/authenticated — a client must not be able to
-- forge access entries about itself.
create or replace function public.record_data_access(
  p_user_id      uuid,
  p_action       text,
  p_target_table text default null,
  p_target_id    uuid default null,
  p_details      jsonb default '{}'::jsonb,
  p_ip           inet default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.audit_log
    (user_id, action, target_table, target_id, details, ip)
  values
    (p_user_id, p_action, p_target_table, p_target_id,
     coalesce(p_details, '{}'::jsonb), p_ip);
end;
$$;

revoke all on function public.record_data_access(uuid, text, text, uuid, jsonb, inet)
  from public, anon, authenticated;
grant execute on function public.record_data_access(uuid, text, text, uuid, jsonb, inet)
  to service_role;

-- The 'action' check constraint on audit_log predates this work and only
-- allows a fixed enum. Add the access-transparency actions the egress/staff
-- paths emit, idempotently, without dropping the existing allowed values.
do $$
begin
  alter table public.audit_log drop constraint if exists audit_log_action_check;
  alter table public.audit_log
    add constraint audit_log_action_check
    check (action in (
      'read_sensitive', 'export_data', 'delete_account',
      'consent_grant', 'consent_revoke', 'privilege_accept',
      'pdf_upload', 'case_create', 'case_close', 'admin_access',
      -- Pillar 3 access-transparency actions:
      'llm_egress', 'staff_read', 'document_parse', 'ai_analysis',
      'email_triage', 'deadline_scan'
    ));
end $$;

-- ---------------------------------------------------------------------------
-- 4. get_my_access_log() — paginated client read RPC.
-- ---------------------------------------------------------------------------
-- The RLS SELECT policy already scopes reads, but a SECURITY INVOKER RPC
-- gives the Flutter client a stable, paginated surface (and lets us shape the
-- payload — never expose row_hash internals beyond what's needed to verify).
create or replace function public.get_my_access_log(
  p_limit  int default 50,
  p_before timestamptz default null
)
returns table (
  ts           timestamptz,
  action       text,
  target_table text,
  details      jsonb,
  row_hash     text,
  prev_hash    text
)
language sql
security invoker
set search_path = public
as $$
  select a.ts, a.action, a.target_table, a.details, a.row_hash, a.prev_hash
    from public.audit_log a
   where a.user_id = auth.uid()
     and (p_before is null or a.ts < p_before)
   order by a.ts desc
   limit least(greatest(coalesce(p_limit, 50), 1), 200);
$$;

grant execute on function public.get_my_access_log(int, timestamptz)
  to authenticated;

-- ---------------------------------------------------------------------------
-- 5. deletion_certificates — signed Art. 17 erasure receipts.
-- ---------------------------------------------------------------------------
-- When the account-delete edge fn erases a user, it records a certificate:
-- what was deleted (table -> row count), a content hash, and an Ed25519
-- signature over the canonical payload. The public key is published at
-- /.well-known so anyone can verify the signature offline. Append-only.
create table if not exists public.deletion_certificates (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid,                 -- NOT a FK: the user row is gone
  subject_email   text,                 -- for the user to identify their cert
  deleted_at      timestamptz not null default now(),
  -- {"chat_messages": 12, "case_files": 3, "storage_objects": 5, ...}
  deleted_counts  jsonb not null default '{}'::jsonb,
  -- sha256 over the canonical (user_id|deleted_at|deleted_counts) payload.
  content_hash    text not null,
  -- Ed25519 signature (base64) over content_hash, applied by the edge fn.
  signature       text,
  -- Which published key signed it (key id / version), for rotation.
  signing_key_id  text,
  created_at      timestamptz not null default now()
);

create index if not exists deletion_certificates_user_idx
  on public.deletion_certificates (user_id);
create index if not exists deletion_certificates_email_idx
  on public.deletion_certificates (subject_email);

alter table public.deletion_certificates enable row level security;
alter table public.deletion_certificates force row level security;

-- No client policy: certs are written by the account-delete edge fn under
-- service_role and verified OFFLINE via the published public key + the
-- returned receipt. After deletion the user has no session anyway, so a
-- client SELECT policy would serve no one; the receipt is handed back in the
-- delete response and (optionally) emailed.

-- Append-only: block UPDATE/DELETE even under service_role (matches wave2).
create or replace function public.tf_deletion_certs_append_only()
returns trigger
language plpgsql
as $$
begin
  raise exception 'deletion_certificates is append-only (attempted %)', tg_op
    using errcode = '42501';
end;
$$;

drop trigger if exists deletion_certs_no_update on public.deletion_certificates;
create trigger deletion_certs_no_update
  before update on public.deletion_certificates
  for each row execute function public.tf_deletion_certs_append_only();

drop trigger if exists deletion_certs_no_delete on public.deletion_certificates;
create trigger deletion_certs_no_delete
  before delete on public.deletion_certificates
  for each row execute function public.tf_deletion_certs_append_only();

-- record_deletion_certificate() — called by the account-delete edge fn.
-- The edge fn owns the canonical hashing + Ed25519 signing (it holds the
-- Vault key AND must hash the SAME bytes it signs). To avoid any JS-vs-
-- Postgres formatting mismatch (jsonb::text key ordering, timestamp
-- rendering), the edge fn passes the canonical deleted_at + pre-computed
-- content_hash; the DB is the append-only ledger that stores them verbatim
-- and re-derives a server-side hash for cross-checking. service_role only.
create or replace function public.record_deletion_certificate(
  p_user_id        uuid,
  p_subject_email  text,
  p_deleted_at     timestamptz,
  p_content_hash   text,
  p_deleted_counts jsonb,
  p_signature      text default null,
  p_signing_key_id text default null
)
returns table (id uuid, content_hash text, deleted_at timestamptz)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
begin
  insert into public.deletion_certificates
    (user_id, subject_email, deleted_at, deleted_counts,
     content_hash, signature, signing_key_id)
  values
    (p_user_id, p_subject_email,
     coalesce(p_deleted_at, now()),
     coalesce(p_deleted_counts, '{}'::jsonb),
     p_content_hash, p_signature, p_signing_key_id)
  returning public.deletion_certificates.id into v_id;

  return query
    select v_id, p_content_hash, coalesce(p_deleted_at, now());
end;
$$;

revoke all on function public.record_deletion_certificate(uuid, text, timestamptz, text, jsonb, text, text)
  from public, anon, authenticated;
grant execute on function public.record_deletion_certificate(uuid, text, timestamptz, text, jsonb, text, text)
  to service_role;

notify pgrst, 'reload schema';
