# Payment Runbook — Stripe Disaster Recovery

**Audience:** on-call engineer for Advocat
**Scope:** Stripe live mode (`acct_1TKI1MH9x6e7e9ho` — display name "Advocat.ee")
**Last live state captured:** 2026-05-15

This is the recovery procedure for every payment-flow failure mode that has actually happened to us or that the 5-layer activation pipeline was designed to catch. The architecture itself is documented at the top of `supabase/functions/stripe-webhook/index.ts` and in `memory: reference_payment_flow_state`.

---

## 0. Pre-flight: know your tools

```bash
# Verify live-mode access
stripe config --list | grep display_name              # → 'Advocat.ee'
stripe subscriptions list --limit 5 --live            # 200 + JSON

# Verify Supabase Management API access
[[ -n "$SUPABASE_ACCESS_TOKEN" ]] && echo ok

# Run the read-only smoke
bash scripts/stripe_smoke.sh
```

The smoke is the single command to check whether the payment plumbing is healthy. Run it first; the rest of this document is what to do when it warns or fails.

---

## 1. Five sources of truth (keep in sync)

| Where                                  | Field                       | What it gates                         |
|----------------------------------------|-----------------------------|---------------------------------------|
| `public.profiles.is_pro`               | bool                        | **THE PRO GATE** — `check-ai-quota` reads only this |
| `public.profiles.subscription_tier`    | `free` / `basic` / `premium`| UI label only                         |
| `public.profiles.subscription_expires_at` | timestamptz              | Display + future expiry checks        |
| `public.subscriptions.status`          | `active` / `trialing` / `past_due` / `canceled` | Secondary Pro path in `check-ai-quota.detectPlan` |
| `public.subscriptions.current_period_end` | timestamptz              | Mirrored expiry                       |
| `public.subscriptions.stripe_subscription_id` | text (canonical `sub_*`) | Canonical link to Stripe              |

Mapping (`stripe-webhook/subscription_router.ts` → `PLAN_MAPPING`):

| plan_id metadata     | Tier      | Monthly price | Yearly price |
|----------------------|-----------|---------------|--------------|
| `counsel`            | `basic`   | €19.99        | €159.99      |
| `representation`     | `premium` | €29.99        | €249.99      |

The legacy `intro_type` metadata column exists on `subscriptions` for grandfathered founder rows (e.g. Sofia's `€14.99`). New checkouts never set it.

---

## 2. Common failure modes

### 2.1. Customer paid, Pro not active ("Sofia bug")

**Symptom:** Stripe charge succeeded, customer still sees free tier.

**First, locate the user:**
```bash
EMAIL='customer@example.com'

# Stripe side
stripe customers list --email "$EMAIL" --live
stripe subscriptions list --customer cus_XXX --live

# DB side (replace UID below with the user_id)
curl -s -X POST "https://api.supabase.com/v1/projects/okgnkucgwsytsondrjye/database/query" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query":"select id, email, is_pro, subscription_tier, stripe_customer_id, subscription_expires_at from public.profiles where email = $$customer@example.com$$;"}'
```

**Resolution paths (escalate in order):**

1. **Re-deliver the webhook from Stripe.** Open the event in the Stripe Dashboard → Webhooks → click "Resend". This is the safest fix: the webhook is idempotent (`webhook_events.event_id`) and re-applies the full 5-layer write.
2. **Wait for the daily reconciler.** `reconcile-subscriptions-daily` (pg_cron `jobid=2`, runs 03:00 UTC) fixes drift within 24 h.
3. **Trigger reconcile immediately:**
   ```sql
   -- via Supabase SQL editor or Management API
   select public.invoke_edge_cron('reconcile-subscriptions');
   -- Poll: select * from net._http_response order by id desc limit 1;
   ```
4. **Manual activation (last resort, has caused drift):**
   ```sql
   -- get sub data from stripe first; replace UUID + prices + expiry below
   update public.profiles
     set is_pro = true,
         subscription_tier = 'basic',
         subscription_expires_at = '2026-06-07T19:40:18Z',
         stripe_customer_id = 'cus_UTUlP0DEFE5kx9'
   where id = 'e73dd48d-1591-43cc-8343-eceb92447320';

   insert into public.subscriptions
     (user_id, status, tier, current_period_end, stripe_subscription_id, updated_at)
   values
     ('e73dd48d-1591-43cc-8343-eceb92447320', 'active', 'basic',
      '2026-06-07T19:40:18Z', 'sub_1TUXmQH9x6e7e9ho7OfkYi2Y', now())
   on conflict (user_id) do update
     set status = excluded.status,
         tier = excluded.tier,
         current_period_end = excluded.current_period_end,
         stripe_subscription_id = excluded.stripe_subscription_id,
         updated_at = now();
   ```
   **CRITICAL:** Use the **real** `sub_*` ID from Stripe — never write a placeholder like `manual_activation_*` or `reconciled_from_stripe`. Past placeholders are still in the DB (2 rows as of 2026-05-15) and are a known anomaly: `reconcile-subscriptions` does not currently overwrite them because the other fields (`is_pro`, `status`) are already correct.

### 2.2. Stripe event stuck in `pending_webhooks`

**Symptom:** `stripe events list` shows `pending_webhooks > 0` on an event older than a few minutes. This means Stripe attempted delivery and got non-2xx (or no response in time).

```bash
stripe events retrieve evt_XXX --live
# Look for: pending_webhooks > 0
# Look at: data.object.metadata.user_id (so you know who's affected)
```

**Resolution:**
1. Read `webhook_events` for that `event_id`:
   ```sql
   select * from public.webhook_events where event_id = 'evt_XXX';
   ```
   - `status='error'` + `error_message` non-null → fix the underlying cause (see error message), then re-trigger from Stripe Dashboard.
   - No row → the request never reached the function (network or Stripe-side issue). Re-trigger from Stripe Dashboard.
   - `status='processing'` for >5 min → function timed out mid-write. Re-trigger; the idempotency layer (`checkAndMarkProcessing`) is safe against duplicates.
2. Reconcile will eventually paper over a missed `checkout.session.completed` for `active`/`trialing` subs within 24 h, but it does **not** fix `invoice.payment_failed` follow-up logic — those need the webhook to land.

**Known stuck events as of 2026-05-15** (Afanasjev checkout flow, 2026-05-07):
- `evt_1TUXn8H9x6e7e9hoRc1KEHAV` — `checkout.session.completed`
- `evt_1TUXn7H9x6e7e9hoRFi38v6i` — `customer.subscription.updated`
- `evt_1TUXmVH9x6e7e9ho0hrOqDAz` — `invoice.payment_failed`
- `evt_1TUXjDH9x6e7e9hoH8HBiIZc` — `invoice.payment_failed`

User is fine in DB (reconcile activated him), but the events are unprocessed. Re-deliver each from Stripe Dashboard. After re-delivery, expect 4 new `ok` rows in `webhook_events` and the `pending_webhooks` counter to drop to 0.

### 2.3. Subscription canceled in Stripe, user still Pro

**Symptom:** customer disputes a renewal charge or cancels via portal → Stripe marks `canceled`/`unpaid` → Pro should flip off.

**Expected behaviour:**
- `customer.subscription.deleted` event → `stripe-webhook` immediately flips `is_pro=false`, tier `free`, subscriptions `status='canceled'`.
- `customer.subscription.updated` with terminal status → same.
- Reconcile is **conservative**: only downgrades after `DOWNGRADE_GRACE_DAYS = 7` days in `canceled`/`past_due`/`unpaid` to prevent flapping during dunning. See `reconcile_logic.ts:DOWNGRADE_GRACE_DAYS`.

**Resolution if user is still Pro after >7 days canceled:**
1. Verify Stripe state: `stripe subscriptions retrieve sub_XXX --live` → check `status` and `canceled_at`.
2. Trigger reconcile manually (will downgrade within seconds):
   ```sql
   select public.invoke_edge_cron('reconcile-subscriptions');
   ```
3. If reconcile fails, run the manual downgrade SQL:
   ```sql
   update public.profiles
     set is_pro = false,
         subscription_tier = 'free',
         subscription_expires_at = null
     where id = '<uid>';
   update public.subscriptions
     set status = 'canceled', updated_at = now()
     where user_id = '<uid>';
   ```

### 2.4. Refund within 24 h

`stripe-webhook` does **not** currently listen for `charge.refunded` or `charge.dispute.created`. A refund inside Stripe will NOT auto-downgrade Pro. Two options:

1. **If you want instant downgrade**: also cancel the subscription in Stripe (`stripe subscriptions cancel sub_XXX --live`). That fires `customer.subscription.deleted` → downgrade lands in seconds.
2. **If subscription stays active** (e.g. partial refund / goodwill credit): no DB action needed — the user keeps Pro until the next billing cycle, at which point either (a) the next renewal charges normally or (b) it goes `past_due` and the dunning flow kicks in.

### 2.5. Webhook secret rotated

If `STRIPE_WEBHOOK_SECRET` rotates and you forget to update Supabase secrets, every webhook returns 401 (`Invalid signature`). All Stripe events queue up in `pending_webhooks` until Stripe gives up (default retry policy: 3 days).

**Recovery:**
```bash
# 1. Get new secret from Stripe Dashboard → Webhooks → endpoint → Signing secret → Reveal
# 2. Push to Supabase secrets
curl -X PATCH "https://api.supabase.com/v1/projects/okgnkucgwsytsondrjye/secrets" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '[{"name":"STRIPE_WEBHOOK_SECRET","value":"whsec_NEW_VALUE"}]'

# 3. Re-deliver every queued event from Stripe Dashboard (idempotency layer handles duplicates).
```

---

## 3. Test mode is **not** wired

As of 2026-05-15 the prod Supabase project has only `STRIPE_SECRET_KEY` + `STRIPE_WEBHOOK_SECRET` (both live mode). `prod_smoke.sh` section [6] expects `STRIPE_TEST_WEBHOOK_KEY` + `SMOKE_TEST_UID` + `SMOKE_TEST_JWT` + `SUPABASE_SERVICE_ROLE_KEY` to run an active synthetic activation test against the **live** webhook with a designated test user. Until those are provisioned, payment activation is exercised by **`scripts/stripe_smoke.sh`** (read-only) and the daily `reconcile-subscriptions` cron.

To wire test mode (recommended):

1. Create a dedicated test user in Supabase Auth (note its UUID + JWT).
2. Generate a long-lived service-role smoke webhook secret from Stripe (Dashboard → Webhooks → "Listen to test events" → reveal secret). Save as `STRIPE_TEST_WEBHOOK_KEY`.
3. Export the four env vars locally and run:
   ```bash
   STRIPE_TEST_WEBHOOK_KEY=whsec_test_xxx \
   SMOKE_TEST_UID=<uuid> \
   SMOKE_TEST_JWT=<long-lived service-role jwt> \
   SUPABASE_SERVICE_ROLE_KEY=<service-role> \
   bash test/e2e/prod_smoke.sh
   ```
4. Note: the synthetic events would still hit the **live** webhook endpoint — which validates against the **live** signing secret. The smoke-test design implies it expects a **separate test endpoint** to exist. Either (a) add a `stripe-webhook-test` edge function copy that reads `STRIPE_TEST_WEBHOOK_KEY`, or (b) accept that the smoke test mutates real DB rows for a designated test UID (current behaviour; see comment in section [6]).

**Real €1 charge is not possible** with current pricing (min subscription is €19.99/mo). The cheapest live verification is the standard €19.99 monthly checkout, refunded within minutes.

---

## 4. Known anomalies (state as of 2026-05-15)

These are open issues, not blockers — capture them so they don't surprise future on-call:

1. **Placeholder `stripe_subscription_id` rows.** Two rows have non-canonical values:
   - Sofia (`sofiaskutans@gmail.com`): `stripe_subscription_id = 'manual_activation_sofia'`, real sub is `sub_1TPeN6H9x6e7e9hotD8mqGAM`.
   - Afanasjev (`afanasjevervin@gmail.com`): `stripe_subscription_id = 'reconciled_from_stripe'`, real sub is `sub_1TUXmQH9x6e7e9ho7OfkYi2Y`.

   Reconcile does not currently fix this (logic in `reconcile_logic.ts:decideForActiveSub` doesn't check the column). If left, future `customer.subscription.deleted` events resolved by `customer_id` will succeed, but `subscription.id`-based lookups will fail. **Fix:** add `stripe_subscription_id` mismatch to the drift list in `decideForActiveSub`. Until then, run the manual `update public.subscriptions set stripe_subscription_id = '<real sub_*>' where user_id = '<uuid>';` from §2.1 step 4.

2. **One internal premium user has no Stripe link.** UID `91c404a0-bd17-4f12-9f1f-09f259242295` is `is_pro=true tier=premium expires=2026-06-14` with `stripe_customer_id=null`. Reconcile correctly ignores it (no matching Stripe sub). Confirm with the owner that this is an internal/admin grant before any retention purges.

3. **4 Stripe events stuck in `pending_webhooks` from 2026-05-07.** All on Afanasjev. User entitlement is correct via reconcile, but the events should be re-delivered from Stripe Dashboard for accounting completeness. See §2.2.

4. **`subscriptions.updated_at` is NULL for all 3 rows.** Indicates none of these rows has been written by the webhook in its current form (writes set `updated_at: new Date().toISOString()`); they're products of manual fixes + reconcile. Not breaking anything, but a fresh `customer.subscription.updated` should populate it on next event.

5. **Stripe webhook endpoint subscribes to 4 event types only.** `checkout.session.completed`, `customer.subscription.updated`, `customer.subscription.deleted`, `invoice.payment_failed`. **Missing:** `charge.refunded`, `charge.dispute.created` — refund handling is currently manual (§2.4).

---

## 5. Quick reference

| Operation                       | Command                                                          |
|---------------------------------|------------------------------------------------------------------|
| Read-only health check          | `bash scripts/stripe_smoke.sh`                                   |
| Trigger reconcile               | `select public.invoke_edge_cron('reconcile-subscriptions');`     |
| Inspect Stripe event            | `stripe events retrieve evt_XXX --live`                          |
| Re-deliver webhook              | Stripe Dashboard → Developers → Events → click event → Resend    |
| Cancel sub immediately          | `stripe subscriptions cancel sub_XXX --live`                     |
| Refund a charge                 | `stripe refunds create --charge ch_XXX --live`                   |
| Update Supabase secret          | `PATCH /v1/projects/<ref>/secrets` (see §2.5 example)            |
| Manual Pro grant (last resort)  | `UPDATE profiles SET is_pro=true …` then `INSERT INTO subscriptions …` |

---

## 6. References

- `supabase/functions/stripe-webhook/index.ts` — webhook handler + 5-layer write contract
- `supabase/functions/stripe-webhook/idempotency.ts` — `webhook_events` gate + read-after-write verification
- `supabase/functions/reconcile-subscriptions/reconcile_logic.ts` — pure drift logic (`DOWNGRADE_GRACE_DAYS`, `matchProfile`, `decideForActiveSub`, `decideForCanceledSub`)
- `test/e2e/prod_smoke.sh` § [6] — active payment activation contract test (gated off)
- `scripts/stripe_smoke.sh` — passive Stripe ↔ DB cross-check (this file's runtime companion)
