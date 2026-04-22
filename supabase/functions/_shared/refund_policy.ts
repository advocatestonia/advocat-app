// Shared refund-policy evaluator for Supabase Edge Functions.
// -----------------------------------------------------------------------------
// Deno-side counterpart to lib/services/refund_eligibility.dart. The two
// files MUST stay in lockstep — the unit tests on both sides use identical
// boundary cases (T01-T10 in refund_policy_test.ts; T01-T14 in
// refund_eligibility_test.dart).
//
// Pure function — no Supabase client, no crypto. The caller fetches the
// subscription state from the DB and passes it in.
//
// Policy (owner-confirmed 2026-04-21):
//   Refund available IFF:
//     · now <= subscribedAt + 14 days, AND
//     · messagesUsed < 7.
//
// Legal basis: EU CRD 2011/83/EU Art. 9 + Art. 16(m) waiver (consent modal).
// -----------------------------------------------------------------------------

/** Max AI responses before Art. 16(m) waiver closes the refund window. */
export const MESSAGE_CAP = 7;

/** Length of the EU CRD withdrawal window in days. */
export const WITHDRAWAL_DAYS = 14;

/** Categorised evaluation result. */
export type RefundReason =
  | "eligible"
  | "deadline_passed"
  | "message_limit_reached";

export interface RefundEvaluation {
  /** Whether a refund should be honoured at `now`. */
  eligible: boolean;
  /** Machine-readable reason (used in UI copy + analytics). */
  reason: RefundReason;
  /** Absolute deadline (subscribedAt + 14 days). Always populated. */
  deadline: Date;
  /** AI responses still available before the 7-message cap. Clamped at 0. */
  messagesRemaining: number;
  /** Messages consumed on this subscription. Clamped at 0. */
  messagesUsed: number;
}

export interface EvaluateRefundInput {
  /** Subscription creation timestamp (customer.subscription.created). */
  subscribedAt: Date;
  /** AI responses delivered on this subscription. */
  messagesUsed: number;
  /** Evaluation time. Usually `new Date()`. Injectable for tests. */
  now: Date;
}

/** Returns the absolute 14-day cutoff. */
export function computeDeadline(subscribedAt: Date): Date {
  return new Date(
    subscribedAt.getTime() + WITHDRAWAL_DAYS * 24 * 60 * 60 * 1000,
  );
}

/**
 * Evaluate the refund window for the given subscription state.
 *
 * Order of precedence when both clauses fail:
 *   1. message_limit_reached (Art. 16(m) waiver, backed by consent modal)
 *   2. deadline_passed (14-day CRD window)
 *
 * We report the message-cap reason first because it rests on explicit user
 * consent — the consent modal displays "7 ответов отменяют право на возврат"
 * before the first AI call, so when the cap is hit we can safely rely on the
 * waiver. The 14-day window is the weaker fallback (never reached in normal
 * flow because anyone engaged enough to get past 14 days has used > 7
 * messages).
 */
export function evaluateRefund(input: EvaluateRefundInput): RefundEvaluation {
  const deadline = computeDeadline(input.subscribedAt);
  const used = Math.max(0, input.messagesUsed | 0);
  const remaining = used >= MESSAGE_CAP ? 0 : MESSAGE_CAP - used;

  if (used >= MESSAGE_CAP) {
    return {
      eligible: false,
      reason: "message_limit_reached",
      deadline,
      messagesRemaining: 0,
      messagesUsed: used,
    };
  }

  if (input.now.getTime() > deadline.getTime()) {
    return {
      eligible: false,
      reason: "deadline_passed",
      deadline,
      messagesRemaining: remaining,
      messagesUsed: used,
    };
  }

  return {
    eligible: true,
    reason: "eligible",
    deadline,
    messagesRemaining: remaining,
    messagesUsed: used,
  };
}
