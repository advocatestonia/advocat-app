// create-org-checkout — PURE validation slice
// -----------------------------------------------------------------------------
// Extracted from index.ts so the MONEY path (seats × unit_amount → Stripe
// charge) can be unit-tested without any I/O. This module holds the single
// source of truth for B2B per-seat pricing + seat bounds, and a pure
// validateOrgCheckout(body) that mirrors the inline checks index.ts used to
// run before building the Stripe session. Behaviour is byte-identical to the
// former inline block (same rejection conditions, error strings, status codes).
// -----------------------------------------------------------------------------

// Plan/period → unit_amount_cents per seat. Single source of truth for B2B
// pricing. Annual = 2 months free (16.7% discount).
export const SEAT_PRICES: Record<
  string,
  Record<string, { amount: number; interval: "month" | "year" }>
> = {
  starter: {
    monthly: { amount: 2900, interval: "month" }, // €29
    yearly: { amount: 29000, interval: "year" }, // €290 (10 × €29)
  },
  firm: {
    monthly: { amount: 4900, interval: "month" }, // €49
    yearly: { amount: 49000, interval: "year" },
  },
  enterprise: {
    monthly: { amount: 9900, interval: "month" }, // €99
    yearly: { amount: 99000, interval: "year" },
  },
};

export const PLAN_SEAT_BOUNDS: Record<string, { min: number; max: number }> = {
  starter: { min: 1, max: 5 },
  firm: { min: 3, max: 25 },
  enterprise: { min: 10, max: 1000 },
};

export interface OrgCheckoutBody {
  plan?: string;
  billing_period?: string;
  seats?: number;
}

export type OrgCheckoutValidation =
  | {
    ok: true;
    plan: string;
    period: string;
    seats: number;
    /** Per-seat unit_amount in cents (the Stripe line-item unit_amount). */
    unitAmount: number;
    /** Recurring interval for the Stripe price_data. */
    interval: "month" | "year";
    /** Quantity = seat count sent to Stripe as line_items[0][quantity]. */
    quantity: number;
  }
  | {
    ok: false;
    error: string;
    status: number;
    /** Extra fields mirroring the original jsonError detail payload. */
    detail: Record<string, unknown>;
  };

/**
 * Validate the plan / billing_period / seat-count of an org checkout request.
 *
 * Pure: no network, no DB, no env reads. Same rejection conditions, error
 * strings and status codes as the former inline block in index.ts:
 *   - unknown plan            → 400 "Invalid plan"          (invalid_plan)
 *   - unknown billing_period  → 400 "Invalid billing period" (invalid_billing_period)
 *   - non-integer / out-of-bounds seats
 *                             → 400 "Invalid seat count"     (invalid_seats)
 *
 * On success returns the resolved plan/period/seats plus the computed
 * unit_amount, interval and quantity that index.ts feeds into the Stripe
 * session — so the money math is asserted in one place.
 */
export function validateOrgCheckout(
  body: OrgCheckoutBody,
): OrgCheckoutValidation {
  const plan = (body.plan ?? "").toLowerCase();
  const billingPeriod = (body.billing_period ?? "").toLowerCase();
  const seats = Number(body.seats ?? 0);

  if (!SEAT_PRICES[plan]) {
    return {
      ok: false,
      error: "Invalid plan",
      status: 400,
      detail: { reason: "invalid_plan" },
    };
  }
  if (!SEAT_PRICES[plan][billingPeriod]) {
    return {
      ok: false,
      error: "Invalid billing period",
      status: 400,
      detail: { reason: "invalid_billing_period" },
    };
  }
  const bounds = PLAN_SEAT_BOUNDS[plan];
  if (!Number.isInteger(seats) || seats < bounds.min || seats > bounds.max) {
    return {
      ok: false,
      error: "Invalid seat count",
      status: 400,
      detail: { reason: "invalid_seats", min: bounds.min, max: bounds.max },
    };
  }

  const price = SEAT_PRICES[plan][billingPeriod];
  return {
    ok: true,
    plan,
    period: billingPeriod,
    seats,
    unitAmount: price.amount,
    interval: price.interval,
    quantity: seats,
  };
}
