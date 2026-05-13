// contract_review_period_reset.ts — Stripe webhook hook for Contract Review.
// -----------------------------------------------------------------------------
// When a user upgrades or downgrades, we reset the 30-day Contract Review
// window so they get the full new quota immediately rather than waiting up to
// 30 days from their previous period_start. This is a paid-feature courtesy:
// nobody pays €29.99 expecting to inherit 4 already-used reviews.
//
// Rules (pure policy — see decideQuotaReset()):
//
//   prev=free  → next=basic    : RESET to (used=0, periodStart=now)
//                               BUT: the lifetime free trial that has already
//                               been consumed (used=1) IS NOT credited back.
//                               The trial is permanently spent. We document
//                               this by resetting `used` to 0 in the new tier
//                               (the new tier has its own counter semantics).
//   prev=free  → next=premium  : RESET (same logic)
//   prev=basic → next=premium  : RESET (full 20 starts now)
//   prev=premium → next=basic  : RESET (5 starts now — neutral on user)
//   prev=any   → next=free     : RESET (free starts a fresh lifetime counter
//                               — downgrade is treated as a new lifecycle).
//   prev===next                : NO-OP (renewal, not a tier change).
//
// The implementation in index.ts must:
//   1. Look up the user's previous tier before applying the new one.
//   2. Call decideQuotaReset() to choose action.
//   3. If kind === "reset", update public.user_quotas SET used=0,
//      periodStart=now() WHERE user_id = userId.
// -----------------------------------------------------------------------------

export type Tier = "free" | "basic" | "premium";

export type QuotaResetAction =
  | { kind: "reset"; reason: string }
  | { kind: "noop"; reason: string };

/**
 * Decide whether the user's Contract Review counter+window should be reset
 * given a tier change. Pure — easy to unit-test.
 *
 * @param prev - The user's prior tier (the value about to be overwritten).
 * @param next - The user's new tier (what the webhook is setting).
 */
export function decideQuotaReset(
  prev: Tier,
  next: Tier,
): QuotaResetAction {
  if (prev === next) {
    return { kind: "noop", reason: "tier_unchanged" };
  }
  // Every real tier change resets the window. The "free → free" case is
  // filtered out by the prev===next check above, so we cannot accidentally
  // give a free user a refreshed lifetime trial through this path.
  return {
    kind: "reset",
    reason: `tier_changed:${prev}->${next}`,
  };
}

/**
 * Apply the reset side-effect using a Supabase admin client. The shape of
 * the client is left as `any` because we deliberately don't carry the
 * generated DB types in this repo (matches the pattern in
 * contract-review/index.ts).
 *
 * Idempotent: safe to call twice; the second call just rewrites identical
 * values.
 */
export async function resetContractReviewWindow(
  sb: { from: (table: string) => unknown },
  userId: string,
  nowIso: string,
): Promise<void> {
  const table = sb.from("user_quotas") as {
    upsert: (
      row: Record<string, unknown>,
      opts: { onConflict: string },
    ) => Promise<{ error?: { message: string } | null }>;
  };
  const { error } = await table.upsert({
    user_id: userId,
    contract_reviews_used: 0,
    contract_reviews_period_start: nowIso,
    updated_at: nowIso,
  }, { onConflict: "user_id" });
  if (error) {
    // Non-fatal — log only. The user might just have a stale counter for
    // up to 30 days; better than letting an upgrade webhook 500.
    console.warn(
      `[stripe-webhook] contract-review quota reset failed for user=${userId}: ${error.message}`,
    );
  }
}
