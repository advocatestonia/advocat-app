-- 20260529150000_atomic_webhook_claim.sql
-- ---------------------------------------------------------------------------
-- Make the stripe-webhook idempotency gate ATOMIC.
--
-- Before: checkAndMarkProcessing() (idempotency.ts) did SELECT-then-UPSERT.
-- Two concurrent deliveries of the SAME event.id (Stripe retries while a
-- delivery is still in flight) could BOTH read "no ok row", BOTH upsert
-- status='processing', and BOTH return {kind:"process"} — double-firing the
-- side effects (referral credit, confirmation email). Subscription/profile
-- grants are idempotent upserts so Pro state was never double-granted, but
-- the referral credit + duplicate email were real.
--
-- After: a single SECURITY DEFINER function. The first caller INSERTs the row
-- (clean claim). Concurrent callers hit the conflict, then take an explicit
-- row lock (SELECT ... FOR UPDATE) and serialize there — exactly one of them
-- can flip a reclaimable row to 'processing'; the rest see 'ok' or a fresh
-- 'processing' and are told to skip.
--
-- Claim rules (returns the action the caller should take):
--   * no row                                   -> 'process' (we inserted it)
--   * status='ok'                              -> 'skip'   (already done)
--   * fresh 'processing' (< stale window)      -> 'skip'   (a sibling has it)
--   * 'error' OR stale 'processing'            -> 'process' (we reclaimed it)
--
-- The stale window (5 min) lets a crashed-mid-flight event be reclaimed on a
-- later Stripe retry instead of being wedged forever, while still rejecting a
-- truly-concurrent duplicate delivery (which arrives within seconds).
--
-- Idempotent: CREATE OR REPLACE.
-- ---------------------------------------------------------------------------

create or replace function public.claim_webhook_event(
  p_event_id      text,
  p_event_type    text,
  p_stale_seconds int default 300
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_status     text;
  v_updated_at timestamptz;
begin
  -- Fast path: first delivery ever. ON CONFLICT DO NOTHING means only the
  -- single inserting transaction gets a returned row; concurrent siblings
  -- get zero rows and fall through to the locked reclaim path below.
  insert into public.webhook_events (event_id, event_type, status, updated_at)
  values (p_event_id, p_event_type, 'processing', now())
  on conflict (event_id) do nothing;

  if found then
    return 'process';
  end if;

  -- Conflict path: a row exists. Take the row lock so concurrent duplicate
  -- deliveries serialize here — only one can observe a reclaimable state and
  -- flip it; the others block, then see 'processing' and skip.
  select status, updated_at
    into v_status, v_updated_at
    from public.webhook_events
   where event_id = p_event_id
     for update;

  if v_status = 'ok' then
    return 'skip';
  end if;

  -- Reclaim a failed attempt or a stale (crashed) processing row.
  if v_status = 'error'
     or (v_status = 'processing'
         and v_updated_at < now() - make_interval(secs => p_stale_seconds))
  then
    update public.webhook_events
       set status = 'processing', updated_at = now()
     where event_id = p_event_id;
    return 'process';
  end if;

  -- Otherwise a sibling is actively processing — do not double-fire.
  return 'skip';
end;
$$;

revoke all on function public.claim_webhook_event(text, text, int) from public;
grant execute on function public.claim_webhook_event(text, text, int) to service_role;

comment on function public.claim_webhook_event(text, text, int) is
  'Atomic Stripe-webhook idempotency claim. Returns process|skip. Serializes '
  'concurrent duplicate deliveries on the event_id PK row lock.';
