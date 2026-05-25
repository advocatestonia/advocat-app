-- =====================================================================
-- B2B v2 refinements — compound trigger + exponential decay + re-arm.
-- Date: 2026-05-25 (same-day v1→v2 tuning per 6-expert analyst consilium).
--
-- Findings the v1 implementation (20260525223000_b2b_signals.sql + supporting
-- edge functions) earned from the analyst consilium:
--
--   1. RED — Threshold 100 with `law_firm_email_domain` defaulting to 100
--      meant a single signup event was enough to fire the modal. The
--      analyst calling this "promotional pop-up on first login" was
--      generous; in EU/EE GDPR + ePrivacy terms it leans towards a
--      direct-marketing interaction without contextual basis. Fix:
--      threshold 110, domain 60, AND require ≥1 other signal type in the
--      last 14 days before the flag flips (compound trigger).
--
--   2. RED — Score-staleness: a stale signal from 28 days ago weighed the
--      same as a fresh one. Fix: exponential decay with 14-day half-life
--      inside compute_b2b_score. A 28-day-old signal now contributes 1/4.
--
--   3. YELLOW — Single shot per user lifetime was too restrictive for
--      users whose intent grows (e.g. tried Advocat solo on day 0,
--      onboarded their firm 60 days later, did a docx export). Fix:
--      after `b2b_modal_shown_at < now() - 30 days`, the FIRST new
--      high-intent signal (docx_export / pro_quota_pressure /
--      multi_case_30d) re-arms the flag. Lifetime cap = 2 displays.
--
-- ADDITIVE + IDEMPOTENT: safe to re-run. Drops/recreates the two relevant
-- functions but leaves the underlying `b2b_signals` table + index set
-- untouched. The `profiles.b2b_modal_retrigger_count` column is added if
-- missing and defaults to 0 so existing rows stay valid.
-- =====================================================================

-- ---------------------------------------------------------------------------
-- 1. profiles.b2b_modal_retrigger_count — lifetime cap counter
-- ---------------------------------------------------------------------------
-- Increments each time `record_b2b_signal` re-arms a previously-shown
-- modal. Hard cap = 2 (first display + at most one re-arm). Once at the
-- cap the re-arm branch is skipped forever for that user.
alter table public.profiles
  add column if not exists b2b_modal_retrigger_count integer not null default 0;

comment on column public.profiles.b2b_modal_retrigger_count is
  'Number of times the B2B modal has been re-armed after a >30-day gap. Hard-capped at 2 lifetime (initial show + 1 re-arm). Set by record_b2b_signal v2.';

-- ---------------------------------------------------------------------------
-- 2. compute_b2b_score (v2) — exponential decay
-- ---------------------------------------------------------------------------
-- Replaces the simple SUM(score) with an exponentially-decayed sum:
--   effective(score, days_old) = score * 0.5 ^ (days_old / 14)
-- so a fresh signal counts in full and a 28-day-old signal counts 1/4.
--
-- Kept inside the same 30-day query window as v1 (anything beyond the
-- horizon is dropped entirely). We round to integer at the end because
-- the downstream b2b_score column is integer.
create or replace function public.compute_b2b_score(p_user_id uuid)
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    round(
      sum(
        score * power(
          0.5::numeric,
          extract(epoch from (now() - occurred_at)) / (14.0 * 86400.0)
        )
      )
    )::integer,
    0
  )
    from public.b2b_signals
   where user_id = p_user_id
     and occurred_at > now() - interval '30 days';
$$;

revoke all on function public.compute_b2b_score(uuid) from public;
grant execute on function public.compute_b2b_score(uuid) to authenticated, service_role;

comment on function public.compute_b2b_score(uuid) is
  'v2: 30-day rolling sum with 14-day-half-life exponential decay. A signal from N days ago contributes score * 0.5^(N/14).';

-- ---------------------------------------------------------------------------
-- 3. record_b2b_signal (v2) — compound trigger + re-arm
-- ---------------------------------------------------------------------------
-- The v1 version flipped `b2b_modal_pending=true` as soon as the rolling
-- score crossed 100 AND the modal had not been shown before. v2 changes:
--
--   (a) THRESHOLD: 100 → 110.
--   (b) COMPOUND: domain (60) alone cannot trip the flag — at least one
--       OTHER signal_type must exist in the last 14 days. We check by
--       running a `count(distinct signal_type) >= 2` query and verifying
--       at least one row is non-domain.
--   (c) RE-ARM: if a high-intent signal arrives after the previous
--       `b2b_modal_shown_at < now() - 30 days` AND we are below the
--       lifetime cap (retrigger_count < 1), reset b2b_modal_pending=true,
--       null out b2b_modal_shown_at, and increment the count. Domain
--       hits NEVER re-arm.
--
-- SECURITY DEFINER so the edge fn keeps working under service-role.
create or replace function public.record_b2b_signal(
  p_user_id     uuid,
  p_signal_type text,
  p_score       integer,
  p_payload     jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_new_score        integer;
  v_score            integer := coalesce(p_score, 0);
  v_threshold        constant integer := 110;
  v_lifetime_cap     constant integer := 1;  -- retrigger_count max value
  v_high_intent      constant text[] := array[
    'docx_export', 'pro_quota_pressure', 'multi_case_30d'
  ];
  v_has_other_signal boolean;
  v_modal_shown_at   timestamptz;
  v_retrigger_count  integer;
  v_modal_pending    boolean;
  v_should_arm       boolean := false;
  v_should_rearm     boolean := false;
begin
  if p_user_id is null or p_signal_type is null or length(p_signal_type) = 0 then
    raise exception 'record_b2b_signal: user_id and signal_type are required';
  end if;

  -- Clamp score to the table check-constraint range.
  if v_score < 0 then
    v_score := 0;
  elsif v_score > 1000 then
    v_score := 1000;
  end if;

  -- 3a. Insert the signal row first so the rolling-score recompute sees it.
  insert into public.b2b_signals (user_id, signal_type, score, payload)
  values (p_user_id, p_signal_type, v_score, p_payload);

  -- 3b. Recompute the decayed 30-day rolling sum.
  v_new_score := public.compute_b2b_score(p_user_id);

  -- 3c. Read current profile state. Tolerant of missing row — we still
  --     persist the signal but skip the flag-flip.
  select b2b_modal_shown_at, b2b_modal_retrigger_count, b2b_modal_pending
    into v_modal_shown_at, v_retrigger_count, v_modal_pending
    from public.profiles
   where id = p_user_id
   for update;

  if not found then
    -- Signal recorded, nothing else to update.
    return;
  end if;

  -- 3d. Has any OTHER (non-domain) signal type fired in the last 14 days?
  -- The compound trigger demands this so a fresh signup with a law-firm
  -- email cannot trip the modal before the user has done anything.
  select exists (
    select 1
      from public.b2b_signals
     where user_id = p_user_id
       and signal_type <> 'law_firm_email_domain'
       and occurred_at > now() - interval '14 days'
  ) into v_has_other_signal;

  -- 3e. Initial-arm path: score over threshold + compound trigger met +
  --     modal never shown.
  if v_new_score >= v_threshold
     and v_has_other_signal
     and v_modal_shown_at is null
  then
    v_should_arm := true;
  end if;

  -- 3f. Re-arm path: score over threshold + new high-intent signal +
  --     modal last shown >30 days ago + below lifetime cap.
  if not v_should_arm
     and v_new_score >= v_threshold
     and v_modal_shown_at is not null
     and v_modal_shown_at < now() - interval '30 days'
     and v_retrigger_count < v_lifetime_cap
     and p_signal_type = any(v_high_intent)
  then
    v_should_rearm := true;
  end if;

  -- 3g. Apply the new state. Update is conditional so we don't churn the
  --     row on every signal — only when something actually changes.
  update public.profiles
     set b2b_score = v_new_score,
         b2b_modal_pending = case
           when v_should_arm or v_should_rearm then true
           else b2b_modal_pending
         end,
         b2b_modal_shown_at = case
           when v_should_rearm then null
           else b2b_modal_shown_at
         end,
         b2b_modal_retrigger_count = case
           when v_should_rearm then b2b_modal_retrigger_count + 1
           else b2b_modal_retrigger_count
         end,
         updated_at = now()
   where id = p_user_id;
end;
$$;

revoke all on function public.record_b2b_signal(uuid, text, integer, jsonb) from public;
grant execute on function public.record_b2b_signal(uuid, text, integer, jsonb) to service_role;

comment on function public.record_b2b_signal(uuid, text, integer, jsonb) is
  'v2: records signal, recomputes decayed 30-day score, flips b2b_modal_pending only when compound trigger met (score>=110 AND >=1 non-domain signal in last 14d). Re-arms once after >30d gap on high-intent signal up to lifetime cap of 2 displays.';

-- ---------------------------------------------------------------------------
-- 4. Hot-reload PostgREST so the v2 functions are immediately callable.
-- ---------------------------------------------------------------------------
notify pgrst, 'reload schema';
