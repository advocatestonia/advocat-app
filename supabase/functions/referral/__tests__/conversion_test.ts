// referral/__tests__/conversion_test.ts
// -----------------------------------------------------------------------------
// Tests for conversion.ts — uses both a fake Supabase client and a fake
// StripeAdapter so we can exercise the full credit lifecycle without
// hitting api.stripe.com.
//
// Run:
//   deno test --allow-read --allow-env \
//     supabase/functions/referral/__tests__/conversion_test.ts
// -----------------------------------------------------------------------------

import {
  assertEquals,
  assertExists,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  creditInviterForReferred,
  processConversionForReferred,
} from "../conversion.ts";
import { emptyState, fakeStripe, makeFakeSb } from "./_fakes.ts";

// ─── processConversionForReferred ───────────────────────────────────────────

Deno.test("CONV-T01 — non-referred user is a noop", async () => {
  const sb = makeFakeSb(emptyState());
  const out = await processConversionForReferred(
    sb,
    fakeStripe(),
    "u1",
    "cus_1",
  );
  assertEquals(out.kind, "noop");
});

Deno.test("CONV-T02 — referred user gets coupon + status flips to converted", async () => {
  const state = emptyState();
  state.referral_codes.push({
    user_id: "inv-1",
    code: "abc12345",
    total_invites_sent: 1,
    total_conversions: 0,
    total_free_months_earned: 0,
  });
  state.referral_attributions.push({
    id: "a1",
    inviter_user_id: "inv-1",
    referred_user_id: "ref-1",
    referral_code: "abc12345",
    attributed_at: "2026-05-01",
    converted_at: null,
    free_month_credited_at: null,
    status: "attributed",
    metadata: {},
  });
  const sb = makeFakeSb(state);
  const stripe = fakeStripe();
  const out = await processConversionForReferred(
    sb,
    stripe,
    "ref-1",
    "cus_ref1",
  );
  assertEquals(out.kind, "converted");
  if (out.kind === "converted") {
    assertEquals(out.inviterUserId, "inv-1");
    assertStringIncludes(out.couponId, "coupon_");
  }
  assertEquals(state.referral_attributions[0].status, "converted");
  assertEquals(state.referral_codes[0].total_conversions, 1);
  assertEquals(stripe.coupons.length, 1);
  assertEquals(stripe.attached.length, 1);
});

Deno.test("CONV-T03 — already converted is a noop", async () => {
  const state = emptyState();
  state.referral_attributions.push({
    id: "a1",
    inviter_user_id: "inv-1",
    referred_user_id: "ref-1",
    referral_code: "abc12345",
    attributed_at: "2026-05-01",
    converted_at: "2026-05-02",
    free_month_credited_at: null,
    status: "converted",
    metadata: {},
  });
  const sb = makeFakeSb(state);
  const out = await processConversionForReferred(
    sb,
    fakeStripe(),
    "ref-1",
    "cus_ref1",
  );
  assertEquals(out.kind, "noop");
  if (out.kind === "noop") {
    assertStringIncludes(out.reason, "already_converted");
  }
});

// ─── creditInviterForReferred ───────────────────────────────────────────────

Deno.test("CREDIT-T01 — credits inviter and bumps free_months counter", async () => {
  const state = emptyState();
  state.referral_codes.push({
    user_id: "inv-1",
    code: "abc12345",
    total_invites_sent: 1,
    total_conversions: 1,
    total_free_months_earned: 0,
  });
  state.referral_attributions.push({
    id: "a1",
    inviter_user_id: "inv-1",
    referred_user_id: "ref-1",
    referral_code: "abc12345",
    attributed_at: "2026-05-01",
    converted_at: "2026-05-02",
    free_month_credited_at: null,
    status: "converted",
    metadata: {},
  });
  state.profiles.push({ id: "inv-1", stripe_customer_id: "cus_inv1" });

  const sb = makeFakeSb(state);
  const stripe = fakeStripe();
  const out = await creditInviterForReferred(sb, stripe, "ref-1", {
    currency: "eur",
    amountCents: 1999,
  });

  assertEquals(out.kind, "credited");
  if (out.kind === "credited") {
    assertEquals(out.amountCents, 1999);
  }
  assertEquals(state.referral_attributions[0].status, "credited");
  assertExists(state.referral_attributions[0].free_month_credited_at);
  assertEquals(state.referral_codes[0].total_free_months_earned, 1);
  assertEquals(stripe.credits.length, 1);
  assertEquals(stripe.credits[0].amount, -1999);
});

Deno.test("CREDIT-T02 — inviter without stripe_customer_id deferred", async () => {
  const state = emptyState();
  state.referral_attributions.push({
    id: "a1",
    inviter_user_id: "inv-1",
    referred_user_id: "ref-1",
    referral_code: "abc12345",
    attributed_at: "2026-05-01",
    converted_at: "2026-05-02",
    free_month_credited_at: null,
    status: "converted",
    metadata: {},
  });
  const sb = makeFakeSb(state);
  const out = await creditInviterForReferred(sb, fakeStripe(), "ref-1", {
    currency: "eur",
    amountCents: 1999,
  });
  assertEquals(out.kind, "noop");
  if (out.kind === "noop") {
    assertStringIncludes(out.reason, "inviter_no_stripe_customer");
  }
  assertEquals(state.referral_attributions[0].status, "converted");
});

Deno.test("CREDIT-T03 — abuse cap of 12/year enforced", async () => {
  const state = emptyState();
  state.referral_attributions.push({
    id: "a-new",
    inviter_user_id: "inv-1",
    referred_user_id: "ref-new",
    referral_code: "abc12345",
    attributed_at: "2026-05-01",
    converted_at: "2026-05-02",
    free_month_credited_at: null,
    status: "converted",
    metadata: {},
  });
  const now = Date.now();
  for (let i = 0; i < 12; i++) {
    state.referral_attributions.push({
      id: `a-old-${i}`,
      inviter_user_id: "inv-1",
      referred_user_id: `ref-old-${i}`,
      referral_code: "abc12345",
      attributed_at: "2025-12-01",
      converted_at: "2025-12-02",
      free_month_credited_at: new Date(now - i * 24 * 60 * 60 * 1000)
        .toISOString(),
      status: "credited",
      metadata: {},
    });
  }
  state.profiles.push({ id: "inv-1", stripe_customer_id: "cus_inv1" });

  const sb = makeFakeSb(state);
  const stripe = fakeStripe();
  const out = await creditInviterForReferred(sb, stripe, "ref-new", {
    currency: "eur",
    amountCents: 1999,
  });
  assertEquals(out.kind, "abuse_blocked");
  if (out.kind === "abuse_blocked") {
    assertEquals(out.recentCreditCount, 12);
  }
  const newRow = state.referral_attributions.find((r) => r.id === "a-new")!;
  assertEquals(newRow.status, "abuse_blocked");
  assertEquals(stripe.credits.length, 0);
});

Deno.test("CREDIT-T04 — non-converted status is a noop", async () => {
  const state = emptyState();
  state.referral_attributions.push({
    id: "a1",
    inviter_user_id: "inv-1",
    referred_user_id: "ref-1",
    referral_code: "abc12345",
    attributed_at: "2026-05-01",
    converted_at: null,
    free_month_credited_at: null,
    status: "attributed",
    metadata: {},
  });
  const sb = makeFakeSb(state);
  const out = await creditInviterForReferred(sb, fakeStripe(), "ref-1", {
    currency: "eur",
    amountCents: 1999,
  });
  assertEquals(out.kind, "noop");
});

Deno.test("CREDIT-T05 — already-credited is a noop (idempotent)", async () => {
  const state = emptyState();
  state.referral_attributions.push({
    id: "a1",
    inviter_user_id: "inv-1",
    referred_user_id: "ref-1",
    referral_code: "abc12345",
    attributed_at: "2026-05-01",
    converted_at: "2026-05-02",
    free_month_credited_at: "2026-05-03",
    status: "credited",
    metadata: {},
  });
  state.profiles.push({ id: "inv-1", stripe_customer_id: "cus_inv1" });
  const sb = makeFakeSb(state);
  const stripe = fakeStripe();
  const out = await creditInviterForReferred(sb, stripe, "ref-1", {
    currency: "eur",
    amountCents: 1999,
  });
  assertEquals(out.kind, "noop");
  if (out.kind === "noop") {
    assertStringIncludes(out.reason, "already_credited");
  }
  assertEquals(stripe.credits.length, 0);
});

Deno.test("CREDIT-T06 — Stripe credit uses the attribution id as idempotency token", async () => {
  const state = emptyState();
  state.referral_codes.push({
    user_id: "inv-1",
    code: "abc12345",
    total_invites_sent: 1,
    total_conversions: 1,
    total_free_months_earned: 0,
  });
  state.referral_attributions.push({
    id: "attrib-xyz",
    inviter_user_id: "inv-1",
    referred_user_id: "ref-1",
    referral_code: "abc12345",
    attributed_at: "2026-05-01",
    converted_at: "2026-05-02",
    free_month_credited_at: null,
    status: "converted",
    metadata: {},
  });
  state.profiles.push({ id: "inv-1", stripe_customer_id: "cus_inv1" });
  const sb = makeFakeSb(state);
  const stripe = fakeStripe();
  await creditInviterForReferred(sb, stripe, "ref-1", {
    currency: "eur",
    amountCents: 1999,
  });
  assertEquals(stripe.credits.length, 1);
  // The per-attribution token is what lets Stripe dedupe a webhook retry
  // WITHOUT colliding two distinct referrals by the same inviter.
  assertEquals(stripe.credits[0].token, "attrib-xyz");
});

Deno.test("CREDIT-T07 — CAS race: a lost claim issues NO Stripe credit", async () => {
  // Simulate the race: between our read (status='converted') and the
  // conditional UPDATE, a concurrent writer already flipped the row to
  // 'credited'. The .eq('status','converted') guard then matches 0 rows.
  const state = emptyState();
  state.referral_attributions.push({
    id: "a1",
    inviter_user_id: "inv-1",
    referred_user_id: "ref-1",
    referral_code: "abc12345",
    attributed_at: "2026-05-01",
    converted_at: "2026-05-02",
    free_month_credited_at: null,
    status: "converted",
    metadata: {},
  });
  state.profiles.push({ id: "inv-1", stripe_customer_id: "cus_inv1" });

  const realSb = makeFakeSb(state);
  const stripe = fakeStripe();
  // Wrap from() so the FIRST conditional update (the CAS claim) sees the row
  // as already-credited (the concurrent winner got there first).
  let flipped = false;
  const sb = {
    ...realSb,
    from(name: string) {
      const q = realSb.from(name as never);
      if (name !== "referral_attributions") return q;
      return {
        ...q,
        update(patch: Record<string, unknown>) {
          if (!flipped && patch.status === "credited") {
            flipped = true;
            // Concurrent winner already moved it out of 'converted'.
            state.referral_attributions[0].status = "credited";
          }
          return q.update(patch);
        },
      };
    },
  };

  const out = await creditInviterForReferred(sb as never, stripe, "ref-1", {
    currency: "eur",
    amountCents: 1999,
  });
  assertEquals(out.kind, "noop");
  if (out.kind === "noop") assertStringIncludes(out.reason, "already_credited");
  // The critical assertion: the loser of the race must NOT issue real money.
  assertEquals(stripe.credits.length, 0);
});
