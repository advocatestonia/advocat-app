// Minimal Stripe REST client used by reconcile-subscriptions.
// -----------------------------------------------------------------------------
// We don't pull in the official Stripe SDK because:
//   - Edge Functions cold-start matters; the SDK is heavy.
//   - We only need two endpoints (list subs, get customer).
//   - Hand-rolling lets us inject a `fetchImpl` for tests.
// -----------------------------------------------------------------------------

import type { StripeCustomer, StripeSubscription } from "./reconcile_logic.ts";

/** Stripe API version we pin to. Match the version used in the Stripe Dashboard. */
export const STRIPE_API_VERSION = "2024-06-20";

/** Subset of `fetch` we depend on — lets tests stub the network. */
export type FetchLike = (
  input: string,
  init?: RequestInit,
) => Promise<Response>;

export interface StripeClientOptions {
  apiKey: string;
  fetchImpl?: FetchLike;
  apiBase?: string;
}

/** List ALL subscriptions in a given status, paging through `has_more`. */
export async function listSubscriptionsByStatus(
  status: "active" | "trialing" | "canceled" | "past_due" | "unpaid",
  opts: StripeClientOptions,
): Promise<StripeSubscription[]> {
  const fetchImpl = opts.fetchImpl ?? fetch;
  const base = opts.apiBase ?? "https://api.stripe.com";
  const out: StripeSubscription[] = [];

  let startingAfter: string | null = null;
  // Hard page cap to prevent runaway loops if Stripe ever returns has_more=true
  // forever (paranoia; we have only ~hundreds of subs).
  const MAX_PAGES = 50;
  for (let page = 0; page < MAX_PAGES; page++) {
    const qs = new URLSearchParams({ status, limit: "100" });
    if (startingAfter) qs.set("starting_after", startingAfter);
    // expand[]=data.customer so we get the customer object inline and avoid
    // a per-row second fetch (saves N HTTP calls per run).
    qs.append("expand[]", "data.customer");

    const res = await fetchImpl(
      `${base}/v1/subscriptions?${qs.toString()}`,
      {
        method: "GET",
        headers: {
          "Authorization": `Bearer ${opts.apiKey}`,
          "Stripe-Version": STRIPE_API_VERSION,
        },
      },
    );

    if (!res.ok) {
      const detail = (await res.text()).slice(0, 200);
      throw new Error(
        `Stripe list subscriptions failed: ${res.status} ${detail}`,
      );
    }
    const body = await res.json() as {
      data: StripeSubscription[];
      has_more: boolean;
    };
    if (!body.data || body.data.length === 0) break;
    out.push(...body.data);
    if (!body.has_more) break;
    startingAfter = body.data[body.data.length - 1].id;
  }
  return out;
}

/** Resolve a customer reference (string id OR inline object) to a customer. */
export async function resolveCustomer(
  ref: string | StripeCustomer,
  opts: StripeClientOptions,
): Promise<StripeCustomer> {
  if (typeof ref !== "string") return ref;
  const fetchImpl = opts.fetchImpl ?? fetch;
  const base = opts.apiBase ?? "https://api.stripe.com";
  const res = await fetchImpl(`${base}/v1/customers/${ref}`, {
    method: "GET",
    headers: {
      "Authorization": `Bearer ${opts.apiKey}`,
      "Stripe-Version": STRIPE_API_VERSION,
    },
  });
  if (!res.ok) {
    const detail = (await res.text()).slice(0, 200);
    throw new Error(`Stripe get customer failed: ${res.status} ${detail}`);
  }
  return await res.json() as StripeCustomer;
}
