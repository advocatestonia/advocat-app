// Pure subscription-status router for stripe-webhook (Sprint 0 — FIX-6).
// -----------------------------------------------------------------------------
// Ref: docs/security/07-business-logic.md M2 — pre-FIX-6 the function only
// reacted to status=canceled|unpaid on customer.subscription.updated, which
// meant monthly renewals were silently ignored. Paying customers hit
// `subscription_expires_at < now()` after 30 days and got downgraded to
// free even though Stripe was still charging them.
//
// FIX-6: route by status to one of three actions:
//   - active / trialing          -> extend/upgrade tier (renewal)
//   - past_due                   -> flag, but do NOT downgrade (grace period)
//   - canceled / unpaid          -> downgrade to free
//   - anything else              -> ignore (Stripe has ~30 statuses)
//
// Also: PII scrub in logs. Pre-FIX-6 the checkout.session.completed branch
// logged `Updated user ${customerEmail}: ...` — emails in logs are a common
// GDPR violation. All logs now reference `customer.id` only.
// -----------------------------------------------------------------------------

export type SubAction =
  | {
    kind: "extend";
    tier: string;
    expires_at: string;
  }
  | { kind: "mark_past_due" }
  | { kind: "downgrade" }
  | { kind: "ignore"; reason: string };

/** Plan mapping kept here so the test can exercise it directly. */
export const PLAN_MAPPING: Record<string, string> = {
  counsel: "basic",
  representation: "premium",
};

/**
 * Decide the action for a customer.subscription.updated event.
 * Pure function — takes the Stripe subscription object, returns the
 * desired DB action.
 */
export function routeSubscriptionUpdate(
  subscription: {
    status?: string;
    current_period_end?: number;
    metadata?: { plan_id?: string };
  },
): SubAction {
  const status = subscription.status;
  if (status === "active" || status === "trialing") {
    // Renewal — extend access. Resolve tier from metadata (set on the
    // original checkout session by create-checkout.ts).
    const planId = subscription.metadata?.plan_id;
    const tier = (planId && PLAN_MAPPING[planId]) || "basic";
    const periodEnd = subscription.current_period_end;
    if (!periodEnd || periodEnd <= 0) {
      return {
        kind: "ignore",
        reason: "active status but no current_period_end",
      };
    }
    return {
      kind: "extend",
      tier,
      expires_at: new Date(periodEnd * 1000).toISOString(),
    };
  }
  if (status === "past_due") {
    return { kind: "mark_past_due" };
  }
  if (status === "canceled" || status === "unpaid") {
    return { kind: "downgrade" };
  }
  return { kind: "ignore", reason: `status=${status ?? "unknown"}` };
}

/**
 * Sanitise a log string so we don't accidentally leak PII. Replaces
 * anything that looks like an email with a redacted marker. Conservative
 * pattern — false positives on "RFC 5321-like" is fine; we only lose log
 * colour, not correctness.
 */
export function scrubPIIFromLog(s: string): string {
  return s.replace(
    /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g,
    "[email-redacted]",
  );
}
