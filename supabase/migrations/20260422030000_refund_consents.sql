-- =============================================================================
-- Migration: refund_consents table
-- Date: 2026-04-22
-- Task: feature/founder-beta-pricing
-- =============================================================================
--
-- Audit log of EU CRD Art. 16(m) waivers. Each row is a single consent event
-- ("I understand that starting AI usage may waive my 14-day refund after 7
-- responses"), collected by the first-session modal.
--
-- Inserts are service-role only via the log-refund-consent Edge Function —
-- never from the client — so the row is tamper-evident from the user's POV.
--
-- Privacy:
--   - ip_hash stores SHA-256(client IP + server-side pepper), never the raw
--     IP. Enough to detect abuse patterns, not enough to re-identify a
--     single user once the pepper rotates.
--   - user_agent kept for fraud investigation only. GDPR retention: 2
--     years (contract period + statute of limitations for CRD disputes).
-- =============================================================================

create table if not exists public.refund_consents (
  id            uuid        primary key default gen_random_uuid(),
  user_id       uuid        not null references auth.users(id) on delete cascade,
  consented_at  timestamptz not null default now(),
  ip_hash       text,
  user_agent    text,
  created_at    timestamptz not null default now()
);

create index if not exists idx_refund_consents_user
  on public.refund_consents (user_id, consented_at desc);

alter table public.refund_consents enable row level security;

-- Users may see their own consent history (support workflows, GDPR Art. 15
-- data subject access). No update/delete/insert policy: Edge Function with
-- service role is the only writer.
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename  = 'refund_consents'
      and policyname = 'refund_consents_select_own'
  ) then
    create policy "refund_consents_select_own"
      on public.refund_consents
      for select
      using (auth.uid() = user_id);
  end if;
end$$;

comment on table public.refund_consents is
  'Audit log of EU CRD Art. 16(m) waivers (refund-consent modal). Service-role writes only. Retention: 2 years.';
