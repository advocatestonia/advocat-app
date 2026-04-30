-- 20260430102338_message_feedback.sql
--
-- Pre-launch feature: thumbs-up / thumbs-down feedback under every AI message.
--
-- Captures rating (-1 = down, +1 = up), optional free-text comment, and a
-- snapshot of the surrounding context (user msg preview, AI response preview,
-- system prompt hash, language, model). The (user_id, message_id) unique
-- constraint enforces "one rating per message per user" — toggling a rating
-- is implemented client-side as an upsert.
--
-- RLS: users can read/write only their own feedback rows. Service role
-- bypasses RLS by default and can pull aggregate data for prompt tuning.
--
-- Notes:
--   * case_id is nullable because the "general" chat (no case) uses no UUID.
--   * message_id is text (not uuid) because chat_messages may use synthetic
--     ids (timestamp-based) in older code paths and we want to capture
--     feedback on those too.
--   * system_prompt_hash is sha256 of the first 1000 chars of the prompt —
--     lets us bucket feedback per prompt revision without storing the prompt.

create table if not exists public.message_feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  case_id uuid,
  message_id text not null,
  rating smallint not null check (rating in (-1, 1)),
  comment text,
  ai_response_preview text,
  user_message_preview text,
  system_prompt_hash text,
  language text,
  model text,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null,
  unique (user_id, message_id)
);

create index if not exists idx_message_feedback_user
  on public.message_feedback(user_id, created_at desc);

create index if not exists idx_message_feedback_rating
  on public.message_feedback(rating, created_at desc);

-- updated_at trigger
create or replace function public.tg_message_feedback_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_message_feedback_updated_at on public.message_feedback;
create trigger trg_message_feedback_updated_at
  before update on public.message_feedback
  for each row execute function public.tg_message_feedback_set_updated_at();

-- RLS
alter table public.message_feedback enable row level security;

drop policy if exists "Users can read their own feedback" on public.message_feedback;
create policy "Users can read their own feedback"
  on public.message_feedback for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert their own feedback" on public.message_feedback;
create policy "Users can insert their own feedback"
  on public.message_feedback for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update their own feedback" on public.message_feedback;
create policy "Users can update their own feedback"
  on public.message_feedback for update
  using (auth.uid() = user_id);

drop policy if exists "Users can delete their own feedback" on public.message_feedback;
create policy "Users can delete their own feedback"
  on public.message_feedback for delete
  using (auth.uid() = user_id);

-- PGRST schema cache reload (pitfall: chat infra)
notify pgrst, 'reload schema';
