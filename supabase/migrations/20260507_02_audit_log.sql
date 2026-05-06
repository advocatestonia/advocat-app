-- =====================================================================
-- audit_log — Pkg 0 / Track B-2
--
-- Purpose:
--   Append-only audit trail of all sensitive operations. Written by edge
--   functions and SECURITY DEFINER RPCs (e.g. read_sensitive_doc,
--   unredact, grant_consent). Used for GDPR Art. 30 records-of-processing
--   and for incident forensics.
--
-- Access model:
--   * NO RLS policies = RLS denies all client access. Service role
--     (edge functions, scheduled jobs) is the only writer/reader.
--   * Owner-self read RPC is deferred to a later migration if needed —
--     for now the data is operational, not user-facing.
--
-- Idempotency:
--   * `if not exists` everywhere; safe to re-run with `supabase db push`.
-- =====================================================================

create table if not exists public.audit_log (
    id            uuid primary key default gen_random_uuid(),
    user_id       uuid references auth.users(id) on delete set null,
    action        text not null check (action in (
        'read_sensitive', 'export_data', 'delete_account',
        'consent_grant', 'consent_revoke', 'privilege_accept',
        'pdf_upload', 'case_create', 'case_close', 'admin_access'
    )),
    target_table  text,
    target_id     uuid,
    ip            inet,
    user_agent    text,
    details       jsonb not null default '{}'::jsonb,
    ts            timestamptz not null default now()
);

create index if not exists audit_log_user_ts_idx
    on public.audit_log (user_id, ts desc);

create index if not exists audit_log_action_ts_idx
    on public.audit_log (action, ts desc);

alter table public.audit_log enable row level security;

-- Intentionally NO policies — RLS denies all client access. Only
-- service_role (which bypasses RLS) and SECURITY DEFINER functions
-- can read/write this table. SECURITY DEFINER functions in sister
-- migrations (read_sensitive_doc, unredact, grant_consent, ...)
-- insert audit rows by bypassing RLS via their owning role.

notify pgrst, 'reload schema';
