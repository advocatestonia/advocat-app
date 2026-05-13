// referral/__tests__/_fakes.ts
// -----------------------------------------------------------------------------
// Test doubles for the referral edge function unit tests:
//
//   makeFakeSb(state, opts) → a Supabase client stub that supports the
//                             subset of from()/select()/insert()/update()
//                             /rpc() calls used by handler.ts + conversion.ts.
//   fakeStripe()           → a StripeAdapter stub that records calls.
//   emptyState()           → a fresh, empty {referral_codes, ...} state.
//
// The stub is deliberately minimal: it covers exactly the call shapes used
// by the production code (verified by reading the handler/conversion source
// once and pinning the chain methods here). Extending it for a new shape is
// trivial — add the needed terminal method to selectChain.
// -----------------------------------------------------------------------------

import type { StripeAdapter } from "../conversion.ts";

/** In-memory tables backing {@link makeFakeSb}. */
export interface Tables {
  referral_codes: Array<{
    user_id: string;
    code: string;
    total_invites_sent: number;
    total_conversions: number;
    total_free_months_earned: number;
  }>;
  referral_attributions: Array<{
    id: string;
    inviter_user_id: string;
    referred_user_id: string;
    referral_code: string;
    attributed_at: string;
    converted_at: string | null;
    free_month_credited_at: string | null;
    status: string;
    // deno-lint-ignore no-explicit-any
    metadata: any;
  }>;
  profiles: Array<{ id: string; stripe_customer_id: string | null }>;
}

export interface FakeOpts {
  rpcImpl?: (name: string, args: Record<string, unknown>) => unknown;
}

export function emptyState(): Tables {
  return {
    referral_codes: [],
    referral_attributions: [],
    profiles: [],
  };
}

export function makeFakeSb(state: Tables, opts: FakeOpts = {}) {
  let nextId = 1;
  function newId() {
    return `00000000-0000-0000-0000-${String(nextId++).padStart(12, "0")}`;
  }

  function query(tableName: keyof Tables) {
    const filters: Array<(r: Record<string, unknown>) => boolean> = [];
    const selectChain = {
      eq(col: string, val: unknown) {
        filters.push((r) => (r as Record<string, unknown>)[col] === val);
        return selectChain;
      },
      not(col: string, _op: string, _val: unknown) {
        // Only "is.null" is used — encode "not null".
        filters.push((r) => (r as Record<string, unknown>)[col] != null);
        return selectChain;
      },
      maybeSingle() {
        const rows = (state[tableName] as Array<Record<string, unknown>>)
          .filter((r) => filters.every((f) => f(r)));
        return Promise.resolve({ data: rows[0] ?? null, error: null });
      },
      single() {
        const rows = (state[tableName] as Array<Record<string, unknown>>)
          .filter((r) => filters.every((f) => f(r)));
        if (rows.length === 0) {
          return Promise.resolve({
            data: null,
            error: { message: "no rows" },
          });
        }
        return Promise.resolve({ data: rows[0], error: null });
      },
      then(resolve: (v: unknown) => void) {
        const rows = (state[tableName] as Array<Record<string, unknown>>)
          .filter((r) => filters.every((f) => f(r)));
        resolve({ data: rows, error: null });
      },
    };

    return {
      select(_cols: string) {
        return selectChain;
      },
      insert(row: Record<string, unknown>) {
        return {
          select(_cols: string) {
            return {
              single() {
                if (tableName === "referral_attributions") {
                  const exists = state.referral_attributions.find(
                    (r) => r.referred_user_id === row.referred_user_id,
                  );
                  if (exists) {
                    return Promise.resolve({
                      data: null,
                      error: {
                        message: "unique violation: referred_user_id",
                      },
                    });
                  }
                  const full = {
                    id: newId(),
                    attributed_at: new Date().toISOString(),
                    converted_at: null,
                    free_month_credited_at: null,
                    metadata: {},
                    ...row,
                  };
                  state.referral_attributions.push(
                    full as Tables["referral_attributions"][number],
                  );
                  return Promise.resolve({ data: full, error: null });
                }
                return Promise.resolve({ data: null, error: null });
              },
            };
          },
        };
      },
      update(patch: Record<string, unknown>) {
        return {
          eq(col: string, val: unknown) {
            const rows = (state[tableName] as Array<Record<string, unknown>>)
              .filter((r) => r[col] === val);
            for (const r of rows) Object.assign(r, patch);
            return Promise.resolve({ data: rows, error: null });
          },
        };
      },
    };
  }

  return {
    rpc(name: string, args: Record<string, unknown>) {
      if (opts.rpcImpl) {
        return Promise.resolve({
          data: opts.rpcImpl(name, args),
          error: null,
        });
      }
      if (name === "get_or_create_referral_code") {
        const uid = args.p_user_id as string;
        const existing = state.referral_codes.find((c) => c.user_id === uid);
        if (existing) {
          return Promise.resolve({ data: existing.code, error: null });
        }
        const code = `c${String(state.referral_codes.length).padStart(7, "0")}`;
        state.referral_codes.push({
          user_id: uid,
          code,
          total_invites_sent: 0,
          total_conversions: 0,
          total_free_months_earned: 0,
        });
        return Promise.resolve({ data: code, error: null });
      }
      return Promise.resolve({ data: null, error: { message: "no rpc" } });
    },
    from(name: keyof Tables) {
      return query(name);
    },
  };
}

/** Fake StripeAdapter that records calls in arrays. */
export function fakeStripe(): StripeAdapter & {
  coupons: Array<{ id: string }>;
  attached: Array<{ customer: string; coupon: string }>;
  credits: Array<{ customer: string; amount: number; description: string }>;
} {
  const coupons: Array<{ id: string }> = [];
  const attached: Array<{ customer: string; coupon: string }> = [];
  const credits: Array<
    { customer: string; amount: number; description: string }
  > = [];
  return {
    coupons,
    attached,
    credits,
    async createReferredFriendCoupon() {
      const id = `coupon_${coupons.length}`;
      coupons.push({ id });
      return { id };
    },
    async attachCouponToCustomer(customer, coupon) {
      attached.push({ customer, coupon });
    },
    async creditCustomerBalance(customer, amount, description) {
      const id = `btxn_${credits.length}`;
      credits.push({ customer, amount, description });
      return { id };
    },
  };
}
