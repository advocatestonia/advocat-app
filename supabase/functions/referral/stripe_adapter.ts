// supabase/functions/referral/stripe_adapter.ts
// -----------------------------------------------------------------------------
// Concrete StripeAdapter that talks to api.stripe.com via fetch().
//
// Stripe SDKs are heavyweight in the Deno edge runtime; we only need three
// HTTP calls so we hit the REST API directly with x-www-form-urlencoded.
//
// All methods throw on non-2xx — the caller (conversion.ts) catches those
// for the coupon path (best-effort) and lets credit failures bubble so
// Stripe retries via the webhook.
// -----------------------------------------------------------------------------

import type { StripeAdapter } from "./conversion.ts";

const STRIPE_API = "https://api.stripe.com/v1";

/** Build the Authorization header. */
function authHeader(apiKey: string): Record<string, string> {
  return { Authorization: `Bearer ${apiKey}` };
}

/** Encode a flat object as form-encoded body. Skips null/undefined. */
function form(body: Record<string, string | number | undefined | null>): string {
  const params = new URLSearchParams();
  for (const [k, v] of Object.entries(body)) {
    if (v === undefined || v === null) continue;
    params.set(k, String(v));
  }
  return params.toString();
}

/** Idempotency key — Stripe dedupes mutating requests on this. */
function idempKey(prefix: string, ...parts: string[]): string {
  return `${prefix}-${parts.join("-")}`;
}

/** Factory — returns an adapter bound to a Stripe secret key. */
export function makeStripeAdapter(apiKey: string): StripeAdapter {
  return {
    async createReferredFriendCoupon() {
      const res = await fetch(`${STRIPE_API}/coupons`, {
        method: "POST",
        headers: {
          ...authHeader(apiKey),
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: form({
          percent_off: 100,
          duration: "repeating",
          // 1 month of 100%-off — Stripe applies one cycle then the user
          // pays full price. "duration_in_months=1" + "repeating".
          duration_in_months: 1,
          name: "Advocat — Friend referral (1 month free)",
        }),
      });
      if (!res.ok) {
        const t = await res.text();
        throw new Error(`stripe.coupons.create ${res.status}: ${t}`);
      }
      const body = (await res.json()) as { id?: string };
      if (!body.id) throw new Error("stripe.coupons.create: missing id");
      return { id: body.id };
    },

    async attachCouponToCustomer(customerId, couponId) {
      const res = await fetch(`${STRIPE_API}/customers/${customerId}`, {
        method: "POST",
        headers: {
          ...authHeader(apiKey),
          "Content-Type": "application/x-www-form-urlencoded",
          "Idempotency-Key": idempKey("attach-coupon", customerId, couponId),
        },
        body: form({ coupon: couponId }),
      });
      if (!res.ok) {
        const t = await res.text();
        throw new Error(
          `stripe.customers.update(coupon) ${res.status}: ${t}`,
        );
      }
    },

    async creditCustomerBalance(customerId, amountCents, description) {
      // Stripe expects amount in MINOR units. Negative = credit toward
      // the next invoice. We also pass currency=eur to scope it.
      const res = await fetch(
        `${STRIPE_API}/customers/${customerId}/balance_transactions`,
        {
          method: "POST",
          headers: {
            ...authHeader(apiKey),
            "Content-Type": "application/x-www-form-urlencoded",
            "Idempotency-Key": idempKey(
              "ref-credit",
              customerId,
              String(amountCents),
              new Date().toISOString().slice(0, 10), // 1 credit/day max
            ),
          },
          body: form({
            amount: amountCents,
            currency: "eur",
            description: description.slice(0, 350),
          }),
        },
      );
      if (!res.ok) {
        const t = await res.text();
        throw new Error(
          `stripe.balance_transactions.create ${res.status}: ${t}`,
        );
      }
      const body = (await res.json()) as { id?: string };
      if (!body.id) {
        throw new Error("stripe.balance_transactions.create: missing id");
      }
      return { id: body.id };
    },
  };
}
