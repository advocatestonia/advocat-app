-- ============================================================================
-- Advocat App — Complete Supabase Schema
-- Migration 001: All tables, RLS policies, indexes, triggers, storage
-- Deploy with: supabase db push
-- ============================================================================

-- --------------------------------------------------------------------------
-- 0. Extensions
-- --------------------------------------------------------------------------
create extension if not exists "pgcrypto";
create extension if not exists "uuid-ossp";

-- --------------------------------------------------------------------------
-- 1. CUSTOM TYPES (enums)
-- --------------------------------------------------------------------------

create type subscription_tier as enum ('free', 'basic', 'premium');

create type case_type as enum (
  'deportation', 'asylum', 'residence_permit', 'family_reunification',
  'citizenship', 'work_permit', 'labor_dispute', 'tenant_rights',
  'debt_collection', 'discrimination', 'police_misconduct',
  'social_benefits', 'other'
);

create type case_status as enum (
  'active', 'pending_decision', 'appeal_filed', 'in_court',
  'resolved', 'closed'
);

create type document_category as enum (
  'decision', 'appeal', 'correspondence', 'identity', 'evidence',
  'medical', 'employment', 'court_filing', 'other'
);

create type document_processing_status as enum (
  'pending', 'processing', 'completed', 'failed'
);

create type correspondence_direction as enum ('incoming', 'outgoing');

create type correspondence_channel as enum ('email', 'postal', 'portal');

create type deadline_type as enum (
  'appeal', 'hearing', 'document_submission', 'response_required',
  'permit_expiry', 'court_date', 'other'
);

create type deadline_priority as enum ('critical', 'high', 'medium', 'low');

create type deadline_status as enum ('upcoming', 'overdue', 'completed', 'cancelled');

create type deadline_source as enum ('manual', 'ai_extracted', 'email_extracted');

create type chat_role as enum ('user', 'assistant', 'system');

create type checker_type as enum ('company', 'vehicle');

create type risk_level as enum ('low', 'medium', 'high');

create type email_provider as enum ('gmail', 'outlook');

-- --------------------------------------------------------------------------
-- 2. UTILITY: updated_at trigger function
-- --------------------------------------------------------------------------

create or replace function set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- --------------------------------------------------------------------------
-- 3. TABLES
-- --------------------------------------------------------------------------

-- 3.1 USERS (public profile, linked to auth.users)
create table public.users (
  id              uuid primary key references auth.users(id) on delete cascade,
  full_name       text not null default '',
  email           text not null,
  phone           text,
  preferred_language varchar(5) not null default 'en',
  subscription_tier  subscription_tier not null default 'free',
  subscription_expires_at timestamptz,
  stripe_customer_id text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz
);

create trigger users_updated_at
  before update on public.users
  for each row execute function set_updated_at();

-- Auto-create a user profile row when someone signs up via Supabase Auth
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.users (id, email, full_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', '')
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 3.2 CASES
create table public.cases (
  id                     uuid primary key default gen_random_uuid(),
  user_id                uuid not null references public.users(id) on delete cascade,
  title                  text not null,
  description            text,
  type                   case_type not null default 'deportation',
  status                 case_status not null default 'active',
  migri_reference_number text,
  court_case_number      text,
  nationality            text,
  decision_date          date,
  appeal_deadline        date,
  hearing_date           date,
  ai_summary             text,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz
);

create trigger cases_updated_at
  before update on public.cases
  for each row execute function set_updated_at();

-- 3.3 DOCUMENTS
create table public.documents (
  id                  uuid primary key default gen_random_uuid(),
  case_id             uuid not null references public.cases(id) on delete cascade,
  user_id             uuid not null references public.users(id) on delete cascade,
  file_name           text not null,
  storage_path        text not null,
  mime_type           text not null default 'application/octet-stream',
  file_size_bytes     integer not null default 0,
  category            document_category not null default 'other',
  language            varchar(5),
  ocr_text            text,
  ai_summary          text,
  extracted_entities  jsonb not null default '{}'::jsonb,
  processing_status   document_processing_status not null default 'pending',
  created_at          timestamptz not null default now(),
  updated_at          timestamptz
);

create trigger documents_updated_at
  before update on public.documents
  for each row execute function set_updated_at();

-- 3.4 CORRESPONDENCE
create table public.correspondence (
  id                     uuid primary key default gen_random_uuid(),
  case_id                uuid not null references public.cases(id) on delete cascade,
  user_id                uuid not null references public.users(id) on delete cascade,
  direction              correspondence_direction not null default 'incoming',
  channel                correspondence_channel not null default 'email',
  sender                 text not null default '',
  recipient              text not null default '',
  subject                text not null default '',
  body                   text not null default '',
  ai_summary             text,
  extracted_action_items jsonb not null default '[]'::jsonb,
  attachment_ids         jsonb not null default '[]'::jsonb,
  is_read                boolean not null default false,
  email_message_id       text,
  sent_at                timestamptz not null default now(),
  created_at             timestamptz not null default now()
);

-- 3.5 DEADLINES
create table public.deadlines (
  id                      uuid primary key default gen_random_uuid(),
  case_id                 uuid not null references public.cases(id) on delete cascade,
  user_id                 uuid not null references public.users(id) on delete cascade,
  title                   text not null,
  description             text,
  due_date                date not null,
  type                    deadline_type not null default 'appeal',
  priority                deadline_priority not null default 'high',
  status                  deadline_status not null default 'upcoming',
  notification_scheduled  boolean not null default false,
  reminder_days_before    integer not null default 7,
  source                  deadline_source not null default 'manual',
  source_document_id      uuid references public.documents(id) on delete set null,
  created_at              timestamptz not null default now(),
  updated_at              timestamptz
);

create trigger deadlines_updated_at
  before update on public.deadlines
  for each row execute function set_updated_at();

-- 3.6 CHAT_MESSAGES
create table public.chat_messages (
  id          uuid primary key default gen_random_uuid(),
  case_id     uuid not null references public.cases(id) on delete cascade,
  user_id     uuid not null references public.users(id) on delete cascade,
  role        chat_role not null default 'user',
  content     text not null,
  created_at  timestamptz not null default now()
);

-- 3.7 CHECKER_REPORTS
create table public.checker_reports (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references public.users(id) on delete cascade,
  checker_type  checker_type not null,
  query         text not null,
  country       varchar(5),
  result_data   jsonb not null default '{}'::jsonb,
  risk_level    risk_level,
  ai_summary    text,
  price_paid    numeric(10, 2) not null default 0,
  created_at    timestamptz not null default now()
);

-- 3.8 EMAIL_CONNECTIONS
create table public.email_connections (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references public.users(id) on delete cascade,
  provider         email_provider not null,
  email_address    text not null,
  tokens_encrypted text,
  last_sync_at     timestamptz,
  created_at       timestamptz not null default now()
);

-- 3.9 WAITLIST (public — no auth required)
create table public.waitlist (
  id          uuid primary key default gen_random_uuid(),
  email       text not null,
  language    varchar(5) default 'en',
  source      text,
  created_at  timestamptz not null default now()
);

-- Prevent duplicate waitlist entries
create unique index waitlist_email_unique on public.waitlist (lower(email));

-- --------------------------------------------------------------------------
-- 4. INDEXES for common queries
-- --------------------------------------------------------------------------

-- Users
create index idx_users_email on public.users (email);
create index idx_users_stripe on public.users (stripe_customer_id) where stripe_customer_id is not null;

-- Cases
create index idx_cases_user_id on public.cases (user_id);
create index idx_cases_user_status on public.cases (user_id, status);
create index idx_cases_created_at on public.cases (created_at desc);

-- Documents
create index idx_documents_case_id on public.documents (case_id);
create index idx_documents_user_id on public.documents (user_id);
create index idx_documents_created_at on public.documents (created_at desc);

-- Correspondence
create index idx_correspondence_case_id on public.correspondence (case_id);
create index idx_correspondence_user_id on public.correspondence (user_id);
create index idx_correspondence_sent_at on public.correspondence (sent_at desc);

-- Deadlines
create index idx_deadlines_case_id on public.deadlines (case_id);
create index idx_deadlines_user_id on public.deadlines (user_id);
create index idx_deadlines_due_date on public.deadlines (due_date);
create index idx_deadlines_user_status on public.deadlines (user_id, status);

-- Chat messages
create index idx_chat_messages_case_id on public.chat_messages (case_id);
create index idx_chat_messages_user_id on public.chat_messages (user_id);
create index idx_chat_messages_created_at on public.chat_messages (case_id, created_at);

-- Checker reports
create index idx_checker_reports_user_id on public.checker_reports (user_id);
create index idx_checker_reports_created_at on public.checker_reports (created_at desc);

-- Email connections
create index idx_email_connections_user_id on public.email_connections (user_id);

-- --------------------------------------------------------------------------
-- 5. ROW LEVEL SECURITY (RLS)
-- --------------------------------------------------------------------------

-- Enable RLS on all tables
alter table public.users enable row level security;
alter table public.cases enable row level security;
alter table public.documents enable row level security;
alter table public.correspondence enable row level security;
alter table public.deadlines enable row level security;
alter table public.chat_messages enable row level security;
alter table public.checker_reports enable row level security;
alter table public.email_connections enable row level security;
alter table public.waitlist enable row level security;

-- 5.1 USERS — users can read/update their own profile
create policy "users_select_own"
  on public.users for select
  using (auth.uid() = id);

create policy "users_update_own"
  on public.users for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- 5.2 CASES — users can CRUD their own cases
create policy "cases_select_own"
  on public.cases for select
  using (auth.uid() = user_id);

create policy "cases_insert_own"
  on public.cases for insert
  with check (auth.uid() = user_id);

create policy "cases_update_own"
  on public.cases for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "cases_delete_own"
  on public.cases for delete
  using (auth.uid() = user_id);

-- 5.3 DOCUMENTS — users can CRUD their own documents
create policy "documents_select_own"
  on public.documents for select
  using (auth.uid() = user_id);

create policy "documents_insert_own"
  on public.documents for insert
  with check (auth.uid() = user_id);

create policy "documents_update_own"
  on public.documents for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "documents_delete_own"
  on public.documents for delete
  using (auth.uid() = user_id);

-- 5.4 CORRESPONDENCE — users can CRUD their own correspondence
create policy "correspondence_select_own"
  on public.correspondence for select
  using (auth.uid() = user_id);

create policy "correspondence_insert_own"
  on public.correspondence for insert
  with check (auth.uid() = user_id);

create policy "correspondence_update_own"
  on public.correspondence for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "correspondence_delete_own"
  on public.correspondence for delete
  using (auth.uid() = user_id);

-- 5.5 DEADLINES — users can CRUD their own deadlines
create policy "deadlines_select_own"
  on public.deadlines for select
  using (auth.uid() = user_id);

create policy "deadlines_insert_own"
  on public.deadlines for insert
  with check (auth.uid() = user_id);

create policy "deadlines_update_own"
  on public.deadlines for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "deadlines_delete_own"
  on public.deadlines for delete
  using (auth.uid() = user_id);

-- 5.6 CHAT_MESSAGES — users can read/insert their own messages
create policy "chat_messages_select_own"
  on public.chat_messages for select
  using (auth.uid() = user_id);

create policy "chat_messages_insert_own"
  on public.chat_messages for insert
  with check (auth.uid() = user_id);

-- 5.7 CHECKER_REPORTS — users can read/insert their own reports
create policy "checker_reports_select_own"
  on public.checker_reports for select
  using (auth.uid() = user_id);

create policy "checker_reports_insert_own"
  on public.checker_reports for insert
  with check (auth.uid() = user_id);

-- 5.8 EMAIL_CONNECTIONS — users can CRUD their own connections
create policy "email_connections_select_own"
  on public.email_connections for select
  using (auth.uid() = user_id);

create policy "email_connections_insert_own"
  on public.email_connections for insert
  with check (auth.uid() = user_id);

create policy "email_connections_update_own"
  on public.email_connections for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "email_connections_delete_own"
  on public.email_connections for delete
  using (auth.uid() = user_id);

-- 5.9 WAITLIST — anyone can insert (anonymous), no one can read via API
create policy "waitlist_insert_anon"
  on public.waitlist for insert
  with check (true);

-- --------------------------------------------------------------------------
-- 6. STORAGE BUCKET for case documents
-- --------------------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'case-documents',
  'case-documents',
  false,
  52428800, -- 50 MB
  array[
    'application/pdf',
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/heic',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  ]
)
on conflict (id) do nothing;

-- Storage RLS: users can upload to their own folder (user_id/*)
create policy "storage_upload_own"
  on storage.objects for insert
  with check (
    bucket_id = 'case-documents'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Storage RLS: users can read their own files
create policy "storage_read_own"
  on storage.objects for select
  using (
    bucket_id = 'case-documents'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Storage RLS: users can delete their own files
create policy "storage_delete_own"
  on storage.objects for delete
  using (
    bucket_id = 'case-documents'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- --------------------------------------------------------------------------
-- 7. HELPER VIEWS
-- --------------------------------------------------------------------------

-- View: cases with document counts (avoids N+1 in list queries)
create or replace view public.cases_with_counts as
select
  c.*,
  coalesce(d.doc_count, 0) as document_count,
  coalesce(m.unread_count, 0) as unread_messages
from public.cases c
left join lateral (
  select count(*) as doc_count
  from public.documents
  where documents.case_id = c.id
) d on true
left join lateral (
  select count(*) as unread_count
  from public.correspondence
  where correspondence.case_id = c.id
    and correspondence.is_read = false
    and correspondence.direction = 'incoming'
) m on true;

-- --------------------------------------------------------------------------
-- Done.
-- --------------------------------------------------------------------------
