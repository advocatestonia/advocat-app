// TDD (RED) — Refund eligibility policy for launch pricing.
// -----------------------------------------------------------------------------
// Policy (owner-confirmed 2026-04-21):
//   A paying subscriber may request a full refund if BOTH:
//     1. Fewer than 14 calendar days have passed since the subscription was
//        created, AND
//     2. The user has received fewer than 7 AI responses on this subscription.
//   After EITHER condition fails, the refund window is closed.
//
// Legal basis: EU Consumer Rights Directive 2011/83/EU Art. 9 (14-day
// withdrawal) combined with Art. 16(m) waiver once digital-content usage
// begins. The 7-message threshold is our internal "meaningful use" trigger
// that the client must explicitly consent to via the first-session modal.
//
// These tests cover the PURE policy logic only — no Supabase, no HTTP.
// The Supabase-wired service is tested separately in a widget/integration
// test once the Edge Function and RPC exist.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/refund_eligibility.dart';

void main() {
  group('RefundPolicy — pure evaluation', () {
    final subscribedAt = DateTime.utc(2026, 4, 1, 12, 0, 0);

    test(
      'T01 — eligible within 14 days with 0 messages used',
      () {
        final result = RefundPolicy.evaluate(
          subscribedAt: subscribedAt,
          messagesUsed: 0,
          now: subscribedAt.add(const Duration(days: 1)),
        );
        expect(result.eligible, isTrue);
        expect(result.reason, RefundReason.eligible);
        expect(result.messagesRemaining, 7);
        expect(
          result.deadline,
          subscribedAt.add(const Duration(days: 14)),
        );
      },
    );

    test(
      'T02 — eligible within 14 days with 6 messages used (one to spare)',
      () {
        final result = RefundPolicy.evaluate(
          subscribedAt: subscribedAt,
          messagesUsed: 6,
          now: subscribedAt.add(const Duration(days: 5)),
        );
        expect(result.eligible, isTrue);
        expect(result.messagesRemaining, 1);
      },
    );

    test(
      'T03 — NOT eligible once 7th message is consumed (boundary)',
      () {
        // After the 7th AI response has been delivered, messagesUsed == 7.
        // Per owner spec: "до 7-го AI-ответа" means strictly before the 7th.
        final result = RefundPolicy.evaluate(
          subscribedAt: subscribedAt,
          messagesUsed: 7,
          now: subscribedAt.add(const Duration(days: 1)),
        );
        expect(result.eligible, isFalse);
        expect(result.reason, RefundReason.messageLimitReached);
        expect(result.messagesRemaining, 0);
      },
    );

    test(
      'T04 — NOT eligible with 8 messages used (over cap)',
      () {
        final result = RefundPolicy.evaluate(
          subscribedAt: subscribedAt,
          messagesUsed: 8,
          now: subscribedAt.add(const Duration(days: 1)),
        );
        expect(result.eligible, isFalse);
        expect(result.reason, RefundReason.messageLimitReached);
        expect(result.messagesRemaining, 0);
      },
    );

    test(
      'T05 — NOT eligible once 14-day deadline has passed (0 messages)',
      () {
        final result = RefundPolicy.evaluate(
          subscribedAt: subscribedAt,
          messagesUsed: 0,
          now: subscribedAt.add(const Duration(days: 15)),
        );
        expect(result.eligible, isFalse);
        expect(result.reason, RefundReason.deadlinePassed);
        // Messages are still tracked even after deadline for auditing.
        expect(result.messagesRemaining, 7);
      },
    );

    test(
      'T06 — exact 14-day boundary is still eligible (inclusive)',
      () {
        // 14 days from subscribedAt = deadline. Per spec, deadline is the
        // cutoff — anything strictly before is eligible. Stripe refund
        // windows conventionally use "within 14 days" meaning day 14 still
        // counts; we mirror that interpretation here.
        final result = RefundPolicy.evaluate(
          subscribedAt: subscribedAt,
          messagesUsed: 0,
          now: subscribedAt.add(const Duration(days: 14)),
        );
        expect(result.eligible, isTrue);
      },
    );

    test(
      'T07 — one microsecond past 14 days is NOT eligible',
      () {
        final result = RefundPolicy.evaluate(
          subscribedAt: subscribedAt,
          messagesUsed: 0,
          now: subscribedAt
              .add(const Duration(days: 14))
              .add(const Duration(microseconds: 1)),
        );
        expect(result.eligible, isFalse);
        expect(result.reason, RefundReason.deadlinePassed);
      },
    );

    test(
      'T08 — both conditions failed reports the earlier-breached reason',
      () {
        // Both days > 14 AND messages >= 7. We report the one that "closed"
        // the window first. If messages hit 7 on day 2, that's the reason
        // even if we query at day 30.
        //
        // Without a firstMessageAt timestamp the policy cannot know which
        // came first, so in this batch we document the documented behaviour:
        // messageLimitReached wins (message cap is the explicit consent
        // waiver per Art. 16(m)).
        final result = RefundPolicy.evaluate(
          subscribedAt: subscribedAt,
          messagesUsed: 10,
          now: subscribedAt.add(const Duration(days: 30)),
        );
        expect(result.eligible, isFalse);
        expect(result.reason, RefundReason.messageLimitReached);
      },
    );

    test(
      'T09 — zero messages and zero elapsed time is eligible',
      () {
        final result = RefundPolicy.evaluate(
          subscribedAt: subscribedAt,
          messagesUsed: 0,
          now: subscribedAt,
        );
        expect(result.eligible, isTrue);
        expect(result.messagesRemaining, 7);
      },
    );

    test(
      'T10 — negative elapsed time is treated as eligible (clock skew)',
      () {
        // Client-server clock skew can produce now < subscribedAt by a few
        // seconds. Policy should not fail closed in that case — otherwise a
        // legitimate refund request could be rejected for the wrong reason.
        final result = RefundPolicy.evaluate(
          subscribedAt: subscribedAt,
          messagesUsed: 0,
          now: subscribedAt.subtract(const Duration(seconds: 30)),
        );
        expect(result.eligible, isTrue);
      },
    );
  });

  group('RefundPolicy — deadline computation', () {
    test('T11 — deadline is exactly subscribedAt + 14 days (UTC-stable)', () {
      final subscribedAt = DateTime.utc(2026, 3, 15, 9, 30, 45);
      final deadline = RefundPolicy.computeDeadline(subscribedAt);
      expect(
        deadline,
        DateTime.utc(2026, 3, 29, 9, 30, 45),
      );
    });

    test(
      'T12 — deadline computation preserves local timezone',
      () {
        // Even if caller passes a local DateTime, the resulting offset is
        // still exactly 14 days. This matters because Stripe API returns
        // timestamps as integers (unix seconds, UTC), while Supabase stores
        // timestamptz — the policy must stay tz-agnostic.
        final local = DateTime(2026, 3, 15, 9, 30, 45);
        final deadline = RefundPolicy.computeDeadline(local);
        expect(deadline.difference(local), const Duration(days: 14));
      },
    );
  });

  group('RefundPolicy — constants', () {
    test('T13 — message cap is 7 (owner spec)', () {
      expect(RefundPolicy.messageCap, 7);
    });

    test('T14 — withdrawal window is 14 days (EU CRD)', () {
      expect(RefundPolicy.withdrawalDays, 14);
    });
  });
}
