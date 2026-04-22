// Refund eligibility policy for Founder's Beta pricing (v2).
// -----------------------------------------------------------------------------
// Pure evaluator — no Supabase, no HTTP, no provider dependency. Callers
// supply the raw state (subscribedAt, messagesUsed, now) and receive a typed
// result. This keeps the legal/business rule in one place and makes it
// trivially unit-testable.
//
// Legal basis:
//   - EU Consumer Rights Directive 2011/83/EU Art. 9 (14-day withdrawal).
//   - Art. 16(m) waiver once a user consents to begin digital-content use.
//
// Policy (owner-confirmed 2026-04-21):
//   Refund is available IFF:
//     · now <= subscribedAt + 14 days, AND
//     · messagesUsed < 7.
//   Whichever condition fails first closes the window.
//
// The first-session consent modal collects the Art. 16(m) waiver. Once the
// user sends their 7th message, the modal's disclosure ("7 ответов отменяют
// право на возврат") becomes binding and we can return `messageLimitReached`
// without violating CRD.
// -----------------------------------------------------------------------------

/// Reason a refund evaluation returned `eligible: false`. `eligible` is the
/// happy path; all others are terminal — once reached they do not "re-open".
enum RefundReason {
  /// Request is within policy — refund may be granted.
  eligible,

  /// 14-day withdrawal window has elapsed.
  deadlinePassed,

  /// User has consumed ≥ 7 AI responses; Art. 16(m) waiver kicks in.
  messageLimitReached,
}

/// Result of [RefundPolicy.evaluate]. Immutable value object.
class RefundEvaluation {
  const RefundEvaluation({
    required this.eligible,
    required this.reason,
    required this.deadline,
    required this.messagesRemaining,
  });

  /// Whether a refund would be honoured at [now].
  final bool eligible;

  /// Categorised reason. Always [RefundReason.eligible] when [eligible] is
  /// true; otherwise identifies which policy clause closed the window.
  final RefundReason reason;

  /// Absolute cutoff for the 14-day window. Useful for UI countdown text.
  /// Always `subscribedAt + 14 days`, regardless of current message count.
  final DateTime deadline;

  /// Messages the user may still receive before the 7-message cap triggers
  /// [RefundReason.messageLimitReached]. Clamped at 0.
  final int messagesRemaining;
}

/// Pure policy evaluator. No external dependencies.
class RefundPolicy {
  RefundPolicy._();

  /// Maximum AI responses allowed before refund is waived.
  static const int messageCap = 7;

  /// Length of the EU CRD withdrawal window.
  static const int withdrawalDays = 14;

  /// Returns the absolute deadline for the withdrawal window.
  static DateTime computeDeadline(DateTime subscribedAt) {
    return subscribedAt.add(const Duration(days: withdrawalDays));
  }

  /// Evaluate the refund window given the subscription state.
  ///
  /// [subscribedAt] — when the Stripe subscription was created. Use the
  ///   value from `customer.subscription.created` webhook, not the first
  ///   checkout session (trials are excluded from the 14-day window start
  ///   by design; we currently have no trials so this is moot).
  /// [messagesUsed] — count of AI responses delivered on this subscription.
  ///   Must be non-negative; negative values are clamped to 0.
  /// [now] — evaluation time (usually `DateTime.now()`). Injectable so tests
  ///   can exercise clock boundaries without fakeAsync.
  static RefundEvaluation evaluate({
    required DateTime subscribedAt,
    required int messagesUsed,
    required DateTime now,
  }) {
    final deadline = computeDeadline(subscribedAt);
    final used = messagesUsed < 0 ? 0 : messagesUsed;
    final remaining = used >= messageCap ? 0 : messageCap - used;

    // Art. 16(m) waiver — message cap reported FIRST. When both clauses
    // are breached we can't know which came first without a firstMessageAt
    // timestamp, and the message-cap reason is the one backed by explicit
    // user consent (modal checkbox), so it is the stronger legal position.
    if (used >= messageCap) {
      return RefundEvaluation(
        eligible: false,
        reason: RefundReason.messageLimitReached,
        deadline: deadline,
        messagesRemaining: 0,
      );
    }

    if (now.isAfter(deadline)) {
      return RefundEvaluation(
        eligible: false,
        reason: RefundReason.deadlinePassed,
        deadline: deadline,
        messagesRemaining: remaining,
      );
    }

    return RefundEvaluation(
      eligible: true,
      reason: RefundReason.eligible,
      deadline: deadline,
      messagesRemaining: remaining,
    );
  }
}
