// Unit tests for the create-org-checkout PURE validation slice.
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-net --allow-env --allow-read \
//     supabase/functions/create-org-checkout/
//
// This is a MONEY path: seats × unit_amount becomes the Stripe charge. We pin
// the per-plan seat min/max enforcement (previously inline + untested in
// serve()) and the computed unit_amount/quantity that would be charged.
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  OrgCheckoutValidation,
  PLAN_SEAT_BOUNDS,
  SEAT_PRICES,
  validateOrgCheckout,
} from "../validation.ts";

// Narrowing helpers so the failure type is asserted explicitly.
function expectOk(r: OrgCheckoutValidation): Extract<
  OrgCheckoutValidation,
  { ok: true }
> {
  assert(r.ok, `expected ok=true, got: ${JSON.stringify(r)}`);
  return r;
}
function expectErr(r: OrgCheckoutValidation): Extract<
  OrgCheckoutValidation,
  { ok: false }
> {
  assert(!r.ok, `expected ok=false, got: ${JSON.stringify(r)}`);
  return r;
}

const PLANS = ["starter", "firm", "enterprise"] as const;

// ── Seat bounds: below min rejected, per plan ────────────────────────────────

Deno.test("OCV-T01 — seats below min rejected (every plan)", () => {
  for (const plan of PLANS) {
    const { min } = PLAN_SEAT_BOUNDS[plan];
    const r = expectErr(
      validateOrgCheckout({ plan, billing_period: "monthly", seats: min - 1 }),
    );
    assertEquals(r.error, "Invalid seat count", `plan=${plan}`);
    assertEquals(r.status, 400, `plan=${plan}`);
    assertEquals(r.detail.reason, "invalid_seats", `plan=${plan}`);
    assertEquals(r.detail.min, min, `plan=${plan}`);
  }
});

// ── Seat bounds: above max rejected, per plan ────────────────────────────────

Deno.test("OCV-T02 — seats above max rejected (every plan)", () => {
  for (const plan of PLANS) {
    const { max } = PLAN_SEAT_BOUNDS[plan];
    const r = expectErr(
      validateOrgCheckout({ plan, billing_period: "monthly", seats: max + 1 }),
    );
    assertEquals(r.error, "Invalid seat count", `plan=${plan}`);
    assertEquals(r.status, 400, `plan=${plan}`);
    assertEquals(r.detail.reason, "invalid_seats", `plan=${plan}`);
    assertEquals(r.detail.max, max, `plan=${plan}`);
  }
});

// ── Boundaries accepted: exactly min and exactly max ─────────────────────────

Deno.test("OCV-T03 — seats at MIN boundary accepted (every plan)", () => {
  for (const plan of PLANS) {
    const { min } = PLAN_SEAT_BOUNDS[plan];
    const r = expectOk(
      validateOrgCheckout({ plan, billing_period: "monthly", seats: min }),
    );
    assertEquals(r.seats, min, `plan=${plan}`);
    assertEquals(r.quantity, min, `plan=${plan}`);
  }
});

Deno.test("OCV-T04 — seats at MAX boundary accepted (every plan)", () => {
  for (const plan of PLANS) {
    const { max } = PLAN_SEAT_BOUNDS[plan];
    const r = expectOk(
      validateOrgCheckout({ plan, billing_period: "yearly", seats: max }),
    );
    assertEquals(r.seats, max, `plan=${plan}`);
    assertEquals(r.quantity, max, `plan=${plan}`);
  }
});

// ── Mid-range accepted ───────────────────────────────────────────────────────

Deno.test("OCV-T05 — mid-range seat count accepted (every plan)", () => {
  for (const plan of PLANS) {
    const { min, max } = PLAN_SEAT_BOUNDS[plan];
    const mid = Math.floor((min + max) / 2);
    const r = expectOk(
      validateOrgCheckout({ plan, billing_period: "monthly", seats: mid }),
    );
    assertEquals(r.seats, mid, `plan=${plan}`);
  }
});

// ── Unknown plan rejected ────────────────────────────────────────────────────

Deno.test("OCV-T06 — unknown plan rejected", () => {
  const r = expectErr(
    validateOrgCheckout({ plan: "ultra", billing_period: "monthly", seats: 3 }),
  );
  assertEquals(r.error, "Invalid plan");
  assertEquals(r.status, 400);
  assertEquals(r.detail.reason, "invalid_plan");
});

Deno.test("OCV-T07 — missing plan rejected as invalid_plan", () => {
  const r = expectErr(
    validateOrgCheckout({ billing_period: "monthly", seats: 3 }),
  );
  assertEquals(r.error, "Invalid plan");
  assertEquals(r.detail.reason, "invalid_plan");
});

Deno.test("OCV-T08 — plan is case-insensitive (STARTER → starter)", () => {
  const r = expectOk(
    validateOrgCheckout({ plan: "STARTER", billing_period: "MONTHLY", seats: 2 }),
  );
  assertEquals(r.plan, "starter");
  assertEquals(r.period, "monthly");
});

// ── Invalid billing period rejected ──────────────────────────────────────────

Deno.test("OCV-T09 — invalid billing period rejected", () => {
  const r = expectErr(
    validateOrgCheckout({ plan: "firm", billing_period: "weekly", seats: 5 }),
  );
  assertEquals(r.error, "Invalid billing period");
  assertEquals(r.status, 400);
  assertEquals(r.detail.reason, "invalid_billing_period");
});

Deno.test("OCV-T10 — missing billing period rejected", () => {
  const r = expectErr(validateOrgCheckout({ plan: "firm", seats: 5 }));
  assertEquals(r.error, "Invalid billing period");
  assertEquals(r.detail.reason, "invalid_billing_period");
});

// ── Non-integer / zero / negative seats rejected ─────────────────────────────

Deno.test("OCV-T11 — non-integer seats rejected", () => {
  const r = expectErr(
    validateOrgCheckout({ plan: "starter", billing_period: "monthly", seats: 2.5 }),
  );
  assertEquals(r.error, "Invalid seat count");
  assertEquals(r.detail.reason, "invalid_seats");
});

Deno.test("OCV-T12 — zero seats rejected (below every plan min)", () => {
  const r = expectErr(
    validateOrgCheckout({ plan: "starter", billing_period: "monthly", seats: 0 }),
  );
  assertEquals(r.error, "Invalid seat count");
  assertEquals(r.detail.reason, "invalid_seats");
});

Deno.test("OCV-T13 — missing seats defaults to 0 and is rejected", () => {
  const r = expectErr(
    validateOrgCheckout({ plan: "starter", billing_period: "monthly" }),
  );
  assertEquals(r.error, "Invalid seat count");
  assertEquals(r.detail.reason, "invalid_seats");
});

Deno.test("OCV-T14 — negative seats rejected", () => {
  const r = expectErr(
    validateOrgCheckout({ plan: "enterprise", billing_period: "yearly", seats: -10 }),
  );
  assertEquals(r.error, "Invalid seat count");
  assertEquals(r.detail.reason, "invalid_seats");
});

Deno.test("OCV-T15 — NaN seats rejected (Number.isInteger guard)", () => {
  const r = expectErr(
    validateOrgCheckout({
      plan: "firm",
      billing_period: "monthly",
      seats: Number("not-a-number"),
    }),
  );
  assertEquals(r.error, "Invalid seat count");
  assertEquals(r.detail.reason, "invalid_seats");
});

// ── MONEY assertion: computed charge matches SEAT_PRICES ──────────────────────

Deno.test("OCV-T16 — valid case computes unit_amount/quantity matching SEAT_PRICES", () => {
  // firm/yearly @ 10 seats: €490/seat/yr × 10 = €4900/yr charged at checkout.
  const r = expectOk(
    validateOrgCheckout({ plan: "firm", billing_period: "yearly", seats: 10 }),
  );
  const price = SEAT_PRICES.firm.yearly;
  assertEquals(r.unitAmount, price.amount); // 49000 cents per seat
  assertEquals(r.interval, price.interval); // "year"
  assertEquals(r.quantity, 10);
  // The total the customer would be charged = unit_amount × quantity.
  assertEquals(r.unitAmount * r.quantity, 49000 * 10);
});

Deno.test("OCV-T17 — every valid plan×period pins unit_amount + interval", () => {
  for (const plan of PLANS) {
    for (const period of ["monthly", "yearly"] as const) {
      const { min } = PLAN_SEAT_BOUNDS[plan];
      const r = expectOk(
        validateOrgCheckout({ plan, billing_period: period, seats: min }),
      );
      const price = SEAT_PRICES[plan][period];
      assertEquals(r.unitAmount, price.amount, `${plan}/${period} amount`);
      assertEquals(r.interval, price.interval, `${plan}/${period} interval`);
      assertEquals(r.quantity, min, `${plan}/${period} quantity`);
    }
  }
});
