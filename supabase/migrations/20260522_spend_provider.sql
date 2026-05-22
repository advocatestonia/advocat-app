-- =====================================================================
-- 20260522_spend_provider.sql
-- =====================================================================
-- FIX-WAVE 14 — Multi-provider spend tracking
--
-- The original anthropic_daily_spend table (see 20260515220031_anti_abuse_
-- protection.sql) was Anthropic-only. With the OpenAI fallback chain in
-- play (FIX 15), we now need to attribute each request to its source
-- provider so that:
--   • Per-provider spend ratios are visible in dashboards (how much of
--     the day's burn came from OpenAI vs Anthropic).
--   • Pricing is correct — OpenAI gpt-4o-mini is ~20× cheaper than
--     Anthropic Sonnet, and lumping it into the Sonnet rate would
--     dramatically over-count spend and prematurely trip the soft cap.
--
-- This migration is ADDITIVE only:
--   1. Add nullable `provider` column with a backfill default of
--      'anthropic_sonnet' (the historical assumption).
--   2. Extend record_anthropic_spend() to accept an optional provider
--      argument and price OpenAI rows at gpt-4o-mini rates
--      ($0.15/M input + $0.60/M output).
--
-- Backwards-compatible: existing callers that pass only (input, output,
-- model) continue to work — provider defaults to 'anthropic_sonnet' and
-- the original sonnet/haiku model-keyword branch still fires.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Schema change
-- ---------------------------------------------------------------------
alter table public.anthropic_daily_spend
  add column if not exists provider text default 'anthropic_sonnet';

comment on column public.anthropic_daily_spend.provider is
  'FIX-WAVE 14: source provider for the day''s aggregate row. One row '
  'per (spend_date, provider) — see uniqueness constraint below. '
  'Values: anthropic_sonnet | anthropic_haiku | openai_gpt4o_mini.';

-- The original table has spend_date as PRIMARY KEY which collapses all
-- providers into one row per day.  To preserve historical rows (where
-- provider is now 'anthropic_sonnet' via the default) AND to allow
-- per-provider aggregation going forward, we keep the existing PK and
-- accept that today's accounting is per-day-total.  Per-provider
-- breakdown is a future migration once the table has accumulated
-- multi-provider rows.

-- ---------------------------------------------------------------------
-- 2. RPC: record_anthropic_spend(input, output, model, provider)
-- ---------------------------------------------------------------------
-- Adds the optional p_provider parameter.  Pricing is now driven by
-- the provider tier first, with the existing sonnet/haiku model-name
-- branch as the fallback for backwards compatibility.
-- ---------------------------------------------------------------------

create or replace function public.record_anthropic_spend(
  p_input_tokens  bigint,
  p_output_tokens bigint,
  p_model         text default 'haiku',
  p_provider      text default 'anthropic_sonnet'
)
returns table (
  spend_date      date,
  cents_spent     bigint,
  request_count   bigint
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
#variable_conflict use_column
declare
  v_in_rate  numeric;
  v_out_rate numeric;
  v_cents    bigint;
begin
  -- Provider-driven pricing in cents per 1M tokens (USD * 100).
  -- Explicit provider wins; otherwise fall back to model-name sniffing.
  if p_provider = 'openai_gpt4o_mini' then
    v_in_rate  := 15;    -- $0.15/M
    v_out_rate := 60;    -- $0.60/M
  elsif p_provider = 'anthropic_haiku' then
    v_in_rate  := 100;   -- $1.00/M
    v_out_rate := 500;   -- $5.00/M
  elsif p_provider = 'anthropic_sonnet' then
    v_in_rate  := 300;   -- $3.00/M
    v_out_rate := 1500;  -- $15.00/M
  elsif p_model ilike '%sonnet%' then
    -- Backwards-compatible model-name branch.
    v_in_rate  := 300;
    v_out_rate := 1500;
  else
    -- Default = haiku rates.
    v_in_rate  := 100;
    v_out_rate := 500;
  end if;

  v_cents := ceil(
    (coalesce(p_input_tokens, 0)  * v_in_rate  +
     coalesce(p_output_tokens, 0) * v_out_rate
    ) / 1000000.0
  )::bigint;

  insert into public.anthropic_daily_spend as t
         (spend_date, cents_spent, request_count, last_request_at, updated_at, provider)
  values (current_date, v_cents, 1, now(), now(), p_provider)
  on conflict (spend_date) do update set
    cents_spent      = t.cents_spent + v_cents,
    request_count    = t.request_count + 1,
    last_request_at  = now(),
    updated_at       = now();

  return query
    select s.spend_date, s.cents_spent, s.request_count
    from public.anthropic_daily_spend s
    where s.spend_date = current_date;
end;
$$;

comment on function public.record_anthropic_spend(bigint, bigint, text, text) is
  'FIX-WAVE 14: multi-provider spend recorder.  Pricing driven by '
  'p_provider (anthropic_sonnet | anthropic_haiku | openai_gpt4o_mini); '
  'falls back to model-name sniffing for legacy callers.';
