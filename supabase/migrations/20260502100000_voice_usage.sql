-- =============================================================================
-- Migration: voice_usage table + atomic quota RPCs (whisper-stt cost control)
-- Date: 2026-05-02
-- Task: voice rate-limit + cost protection (OPENAI_API_KEY now live in prod)
-- =============================================================================
--
-- Server-side enforcement of monthly audio-minute quota for the OpenAI
-- Whisper STT path. Sits next to ai_usage (text chat counter) but tracks
-- minutes-of-audio rather than message count, because Whisper bills per
-- minute (~$0.006/min) and a single API call can be 25 MB / 30 min.
--
-- Tier limits (enforced in supabase/functions/whisper-stt/index.ts):
--   free        →   0 min/month  (voice is a paid feature)
--   basic       → 300 min/month  (Counsel — 5 hours)
--   premium     → 1200 min/month (Representation — 20 hours)
--
-- Tier source of truth: subscriptions.tier (set by stripe-webhook via
-- PLAN_MAPPING in supabase/functions/stripe-webhook/subscription_router.ts).
--
-- Data model:
--   voice_usage (
--     user_id      uuid PK
--     month        date           -- first day of the current calendar month (UTC)
--     seconds_used integer        -- audio seconds consumed this month (precise; minutes derived)
--     updated_at   timestamptz
--   )
--
-- We store SECONDS, not minutes, so partial uses (a 47-second clip) are
-- billed accurately rather than always rounding up to a full minute. The
-- RPC and the client both convert to minutes for display.
--
-- Concurrency:
--   add_voice_usage(p_seconds) does an UPSERT ... RETURNING so two concurrent
--   Whisper calls from the same user always see a strictly monotonic total.
--   Postgres row locks handle the race (same pattern as increment_ai_usage).
-- =============================================================================

-- Table --------------------------------------------------------------------

create table if not exists public.voice_usage (
  user_id      uuid primary key references auth.users(id) on delete cascade,
  month        date not null default date_trunc('month', now())::date,
  seconds_used integer not null default 0,
  updated_at   timestamptz not null default now(),
  constraint voice_usage_seconds_nonneg check (seconds_used >= 0)
);

comment on table public.voice_usage is
  'Server-side enforcement of the monthly Whisper STT minute quota. One row per user, reset monthly. Seconds (not minutes) for billing accuracy.';

create index if not exists idx_voice_usage_month on public.voice_usage(month);

-- Row-Level Security -------------------------------------------------------

alter table public.voice_usage enable row level security;

-- Users can read their own row only.
drop policy if exists voice_usage_read_own on public.voice_usage;
create policy voice_usage_read_own
  on public.voice_usage
  for select
  using (auth.uid() = user_id);

-- NO direct insert/update/delete policies on purpose — writes go via the
-- SECURITY DEFINER functions below.

-- RPC: get_voice_usage -----------------------------------------------------
--
-- Returns the current month's seconds_used (0 if no row). Read-only.

create or replace function public.get_voice_usage()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid;
  v_month date := date_trunc('month', now())::date;
  v_seconds integer;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'authentication required';
  end if;

  select seconds_used into v_seconds
    from public.voice_usage
   where user_id = v_uid
     and month = v_month;

  return coalesce(v_seconds, 0);
end;
$$;

grant execute on function public.get_voice_usage() to authenticated;

comment on function public.get_voice_usage is
  'Read-only: returns the current calendar-month total seconds of Whisper STT audio consumed by the calling user. 0 if no row exists or row is from a previous month.';

-- RPC: add_voice_usage(p_seconds) ------------------------------------------
--
-- Atomically:
--   1. Ensures the row exists for the current calendar month (resets across
--      month boundaries — never carries seconds forward).
--   2. Adds p_seconds to seconds_used.
--   3. Returns the new total.
--
-- The function is SECURITY DEFINER so it can write to the table even though
-- no end-user policy allows it. It always operates on auth.uid() — the
-- caller cannot spoof another user's row.
--
-- Caller is the whisper-stt Edge Function, which records seconds AFTER a
-- successful OpenAI Whisper response (failed transcriptions are NOT billed).

create or replace function public.add_voice_usage(p_seconds integer)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid;
  v_month date := date_trunc('month', now())::date;
  v_total integer;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'authentication required';
  end if;
  if p_seconds is null or p_seconds < 0 then
    raise exception 'p_seconds must be a non-negative integer';
  end if;

  insert into public.voice_usage (user_id, month, seconds_used, updated_at)
  values (v_uid, v_month, p_seconds, now())
  on conflict (user_id) do update
    set seconds_used = case
                         when public.voice_usage.month = v_month
                         then public.voice_usage.seconds_used + p_seconds
                         else p_seconds
                       end,
        month        = v_month,
        updated_at   = now()
  returning seconds_used into v_total;

  return v_total;
end;
$$;

grant execute on function public.add_voice_usage(integer) to authenticated;

comment on function public.add_voice_usage is
  'Atomically adds p_seconds to the current user''s monthly Whisper STT counter and returns the new total. Resets at month boundary. Called by whisper-stt Edge Function only on successful transcription.';

-- Helper view for admin auditing (not exposed via API by default) ----------

create or replace view public.voice_usage_current_month as
  select user_id, seconds_used, (seconds_used / 60.0) as minutes_used, updated_at
    from public.voice_usage
   where month = date_trunc('month', now())::date;
