-- email_attachments — D3 sync downloads PDF/image attachment binaries.
-- D4 email-triage reads these rows via wiring.ts:loadInboundAttachmentTexts
-- and bridges them through pdf-parser to surface contents in Sonnet context.
-- D5 email-send re-attaches selected rows via multipart/mixed.
--
-- Caps:
--   * ≤10 attachments per thread (sync loop hard-caps; overflow logs+skips)
--   * ≤50 MB per file (mirrors pdf-parser MAX_PDF_BYTES)
--   * Storage path: case-documents/{user_id}/email_attachments/{attachment_id}/{filename}
--
-- RLS: owner-only (user_id matches auth.uid()). Service role bypasses for
-- the edge functions (sync, triage, send).

create table if not exists public.email_attachments (
  id uuid primary key default gen_random_uuid(),
  -- FK shape mirrors email_messages (uuid PK, not gmail_message_id string).
  message_id uuid not null references public.email_messages(id) on delete cascade,
  thread_id uuid not null references public.email_threads(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  filename text not null,
  mime text not null,
  size_bytes bigint not null check (size_bytes >= 0 and size_bytes <= 52428800), -- 50 MB
  storage_path text not null,
  -- Once pdf-parser has chewed this, parsed_text holds the extracted text
  -- (text-layer or Vision OCR), and parsed_at marks the parse time. Both
  -- NULL until D4 triage bridges through pdf-parser. parsed_meta is a
  -- small JSONB sidecar (page count, OCR vs text-layer, key extractions).
  parsed_text text null,
  parsed_meta jsonb null,
  parsed_at timestamptz null,
  downloaded_at timestamptz not null default now(),
  -- gmail_attachment_id lets sync_logic dedupe: if a thread is re-fetched
  -- and the same attachment reappears with the same id, we skip the
  -- download (Gmail attachment ids are stable per message).
  gmail_attachment_id text not null,

  constraint email_attachments_unique_per_msg
    unique (message_id, gmail_attachment_id)
);

create index if not exists email_attachments_thread_idx
  on public.email_attachments (thread_id, downloaded_at desc);

create index if not exists email_attachments_user_idx
  on public.email_attachments (user_id, downloaded_at desc);

-- Hot path for D4 triage: "give me PDFs for this thread that haven't been
-- parsed yet". Partial index keeps the index tiny.
create index if not exists email_attachments_unparsed_pdf_idx
  on public.email_attachments (thread_id)
  where parsed_text is null and mime = 'application/pdf';

alter table public.email_attachments enable row level security;

-- Owner read.
drop policy if exists "email_attachments owner read" on public.email_attachments;
create policy "email_attachments owner read"
  on public.email_attachments
  for select
  using (user_id = auth.uid());

-- No client-side write — edge functions use service role.
drop policy if exists "email_attachments owner no-write" on public.email_attachments;
create policy "email_attachments owner no-write"
  on public.email_attachments
  for insert
  with check (false);

drop policy if exists "email_attachments owner no-update" on public.email_attachments;
create policy "email_attachments owner no-update"
  on public.email_attachments
  for update
  using (false);

comment on table public.email_attachments is
  'D3 sync downloads PDF/image attachments here. D4 triage parses via pdf-parser. D5 send re-attaches via multipart/mixed.';
comment on column public.email_attachments.storage_path is
  'case-documents bucket path: {user_id}/email_attachments/{id}/{filename}';
comment on column public.email_attachments.gmail_attachment_id is
  'Gmail attachmentId from payload.body.attachmentId — stable per (messageId, partIndex).';
