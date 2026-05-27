-- apple_iap_transactions — ledger of every Apple IAP receipt we processed.
-- ---------------------------------------------------------------------------
-- Mirrors what stripe-webhook does for Stripe events: one canonical row per
-- transaction so we can replay / audit activations. The edge fn
-- `apple-iap-verify` upserts here on every successful verifyReceipt call.
--
-- Idempotency: transaction_id is the primary key, NOT a synthetic UUID. Apple
-- guarantees transaction_id is unique per purchase, and a /restorePurchases
-- replay surfaces the SAME transaction_id — so an upsert is a no-op on
-- restore. This is the equivalent of Stripe's event.id idempotency check in
-- stripe-webhook/idempotency.ts.
--
-- raw_receipt: the full base64-decoded JSON Apple returned (latest_receipt_info
-- entry for the active subscription). Kept verbatim for audit + future
-- introspection (e.g. detecting downgrade-in-cycle without round-tripping
-- Apple).
--
-- RLS: deny-all writes. Only the edge fn (service-role) writes. Owner SELECT
-- is allowed so the user can see their own purchase history if we surface it
-- in a future "Billing history" screen.
-- ---------------------------------------------------------------------------

create table if not exists public.apple_iap_transactions (
  -- Apple's TransactionId. Unique per purchase event (including restores
  -- which replay the original id). Stored as text since Apple returns a
  -- numeric string and we don't want to lose leading zeros / future format
  -- changes.
  transaction_id text primary key,

  -- Owner. ON DELETE CASCADE so GDPR Art. 17 (account-delete) sweeps these.
  user_id uuid not null references auth.users(id) on delete cascade,

  -- The App Store Connect product id, e.g. counsel_monthly / pro_annual.
  product_id text not null,

  -- For auto-renewable subscriptions Apple emits a new transaction_id every
  -- renewal but keeps original_transaction_id stable across the whole
  -- subscription chain. Use this to group "renewal of subscription X".
  original_transaction_id text not null,

  -- When Apple says the subscription period ends (UTC). The 5-layer
  -- activation pattern reads this into profiles.subscription_expires_at
  -- mirroring stripe-webhook.
  expires_at timestamptz not null,

  -- Environment the receipt was validated against (sandbox vs production).
  -- Apple recommends sandbox-first probing (status 21007) so we record
  -- which endpoint actually accepted the receipt.
  environment text not null check (environment in ('sandbox', 'production')),

  -- The full verifyReceipt response chunk for this transaction (the entry
  -- from latest_receipt_info that matched transaction_id). Kept verbatim
  -- for audit + replay.
  raw_receipt jsonb not null,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Lookup pattern: "what's the user's active subscription?" → join on
-- user_id ORDER BY expires_at DESC LIMIT 1. The composite index makes
-- that an index-only scan.
create index if not exists apple_iap_transactions_user_expires_idx
  on public.apple_iap_transactions (user_id, expires_at desc);

-- Lookup pattern: "find every renewal of original subscription X" — used
-- by the restore flow to verify the chain is intact.
create index if not exists apple_iap_transactions_original_idx
  on public.apple_iap_transactions (original_transaction_id);

-- ---------------------------------------------------------------------------
-- RLS — deny-all writes (service-role only), owner SELECT only.
-- ---------------------------------------------------------------------------
alter table public.apple_iap_transactions enable row level security;

drop policy if exists "apple_iap_transactions owner select"
  on public.apple_iap_transactions;
create policy "apple_iap_transactions owner select"
  on public.apple_iap_transactions
  for select
  using (auth.uid() = user_id);

drop policy if exists "apple_iap_transactions no client insert"
  on public.apple_iap_transactions;
create policy "apple_iap_transactions no client insert"
  on public.apple_iap_transactions
  for insert
  with check (false);

drop policy if exists "apple_iap_transactions no client update"
  on public.apple_iap_transactions;
create policy "apple_iap_transactions no client update"
  on public.apple_iap_transactions
  for update
  using (false);

drop policy if exists "apple_iap_transactions no client delete"
  on public.apple_iap_transactions;
create policy "apple_iap_transactions no client delete"
  on public.apple_iap_transactions
  for delete
  using (false);

-- ---------------------------------------------------------------------------
-- Touch updated_at on every update (matches the pattern used by
-- subscriptions / profiles).
-- ---------------------------------------------------------------------------
create or replace function public.touch_apple_iap_transactions_updated_at()
returns trigger
language plpgsql
as $function$
begin
  new.updated_at := now();
  return new;
end;
$function$;

drop trigger if exists apple_iap_transactions_updated_at
  on public.apple_iap_transactions;
create trigger apple_iap_transactions_updated_at
  before update on public.apple_iap_transactions
  for each row
  execute function public.touch_apple_iap_transactions_updated_at();

comment on table public.apple_iap_transactions is
  'Ledger of every Apple StoreKit transaction validated server-side. Primary '
  'key = Apple TransactionId so /restorePurchases is naturally idempotent.';
