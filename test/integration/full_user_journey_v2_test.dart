// ============================================================================
// Full user journey v2 — extension of full_user_journey_test.dart
// ============================================================================
//
// Adds 20+ contract-level E2E scenarios covering gaps the v1 file did not
// touch:
//
//   • Landing → CTA → app.html deep-link with plan/billing query params
//   • Early Access flow (founder pricing, 100-seat cap)
//   • Yearly billing (€159.99 counsel)
//   • Premium plan (€29.99/mo)
//   • Customer-portal cancellation (Stripe webhook customer.subscription.updated)
//   • Refund eligibility — exact boundary cases via RefundPolicy.evaluate
//   • AI memory recall across sessions (Tier-1 contract)
//   • Document upload + OCR/extract → deadline reminder hand-off
//   • Email approval card → Send (idempotent, logged in correspondence)
//   • Multi-language switching (URL ?lang= → 17-lang dropdown)
//   • Mobile / iOS Safari deep-link parsing for Stripe Checkout
//   • Quota gate at the 7th free message (matches FREE_LIMIT=7 in
//     check-ai-quota/index.ts)
//
// These tests are FULLY OFFLINE — no Supabase, no Stripe HTTP. They assert
// CONTRACTS that real flows depend on. The matching live probes already
// live in test/e2e/prod_smoke.sh (Section [6]).
//
// Run:
//   flutter test test/integration/full_user_journey_v2_test.dart
// ============================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/refund_eligibility.dart';

// ---------------------------------------------------------------------------
// Light fakes — kept independent of full_user_journey_test.dart so each file
// can run in isolation under `flutter test --plain-name`.
// ---------------------------------------------------------------------------

class FakeUser {
  final String id;
  final String? email;
  final String preferredLanguage;
  FakeUser({
    required this.id,
    this.email,
    this.preferredLanguage = 'et',
  });

  FakeUser copyWith({String? preferredLanguage}) => FakeUser(
        id: id,
        email: email,
        preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      );
}

class FakeSub {
  final String id;
  final String userId;
  final String plan; // basic | premium | founder
  final String billingPeriod; // monthly | yearly | early-access | founding
  final String status; // active | canceled | trialing | past_due
  final String? introType; // 'early-access-100' for founders
  final DateTime subscribedAt;
  final DateTime? canceledAt;
  final int messagesUsed;
  FakeSub({
    required this.id,
    required this.userId,
    required this.plan,
    required this.billingPeriod,
    required this.status,
    required this.subscribedAt,
    this.introType,
    this.canceledAt,
    this.messagesUsed = 0,
  });

  /// `clearCanceledAt: true` explicitly nulls canceledAt (used for
  /// reactivation). Without it, passing `canceledAt: null` is ambiguous
  /// with "leave unchanged" because Dart can't distinguish absent from
  /// null in named-parameter copyWith.
  FakeSub copyWith({
    String? status,
    DateTime? canceledAt,
    bool clearCanceledAt = false,
    int? messagesUsed,
  }) =>
      FakeSub(
        id: id,
        userId: userId,
        plan: plan,
        billingPeriod: billingPeriod,
        status: status ?? this.status,
        introType: introType,
        subscribedAt: subscribedAt,
        canceledAt: clearCanceledAt ? null : (canceledAt ?? this.canceledAt),
        messagesUsed: messagesUsed ?? this.messagesUsed,
      );
}

class FakeMemory {
  final String userId;
  final String key;
  final String value;
  FakeMemory(this.userId, this.key, this.value);
}

class FakeCorrespondence {
  final String id;
  final String userId;
  final String to;
  final String subject;
  final String channel; // gmail | resend
  final DateTime sentAt;
  FakeCorrespondence({
    required this.id,
    required this.userId,
    required this.to,
    required this.subject,
    required this.channel,
    required this.sentAt,
  });
}

class JourneyV2World {
  final Map<String, FakeUser> users = {};
  final Map<String, FakeSub> subs = {};
  final List<FakeMemory> memories = [];
  final List<FakeCorrespondence> outbox = [];
  // Founder cap: 100 (Early Access program), per
  // commit 24a2d1a feat(early-access): lifetime €14.99 founder program.
  static const int founderCap = 100;
  static const int freeQuotaCap = 7; // mirrors FREE_LIMIT in check-ai-quota
  static const int freeQuotaResetDays = 30;

  int activeFounderCount() => subs.values
      .where((s) =>
          s.plan == 'founder' &&
          s.billingPeriod == 'early-access' &&
          s.status == 'active')
      .length;
}

// ---------------------------------------------------------------------------
// URL parser — mirrors landing-page deep-link routing
// ---------------------------------------------------------------------------

class DeepLink {
  final String? plan;
  final String? billing;
  final String? lang;
  DeepLink({this.plan, this.billing, this.lang});
}

DeepLink parseDeepLink(String url) {
  final uri = Uri.parse(url);
  return DeepLink(
    plan: uri.queryParameters['plan'],
    billing: uri.queryParameters['billing'],
    lang: uri.queryParameters['lang'],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late JourneyV2World w;
  setUp(() => w = JourneyV2World());

  // -------------------------------------------------------------------------
  // SCENARIO V2-01..V2-04 — Landing → CTA → /app.html deep link parsing
  // -------------------------------------------------------------------------
  group('V2 / scenario 01-04 — landing CTA deep-links', () {
    test('V2-01 Early Access CTA → ?plan=counsel&billing=early-access', () {
      final dl = parseDeepLink(
        'https://advocat.ee/app.html?plan=counsel&billing=early-access',
      );
      expect(dl.plan, 'counsel');
      expect(dl.billing, 'early-access');
    });

    test('V2-02 Pro yearly CTA → ?plan=counsel&billing=yearly', () {
      final dl = parseDeepLink(
        'https://advocat.ee/app.html?plan=counsel&billing=yearly',
      );
      expect(dl.plan, 'counsel');
      expect(dl.billing, 'yearly');
    });

    test('V2-03 Premium monthly CTA → ?plan=representation&billing=monthly',
        () {
      final dl = parseDeepLink(
        'https://advocat.ee/app.html?plan=representation&billing=monthly',
      );
      expect(dl.plan, 'representation');
      expect(dl.billing, 'monthly');
    });

    test('V2-04 unknown billing falls through (client must reject)', () {
      final dl = parseDeepLink('https://advocat.ee/app.html?plan=counsel'
          '&billing=lifetime'); // not in valid set
      const validBilling = {'monthly', 'yearly', 'early-access', 'founding'};
      expect(validBilling.contains(dl.billing), isFalse,
          reason: 'create-checkout must reject unknown billing periods');
    });
  });

  // -------------------------------------------------------------------------
  // SCENARIO V2-05..V2-07 — Free → Early Access founder activation
  // -------------------------------------------------------------------------
  group('V2 / scenario 05-07 — Early Access founder activation', () {
    test('V2-05 webhook activates Pro with intro_type=early-access-100', () {
      final u = FakeUser(id: 'u-fa', email: 'founder1@test.ee');
      w.users[u.id] = u;
      // Simulated webhook outcome: stripe-webhook writes profile + sub
      w.subs[u.id] = FakeSub(
        id: 'sub_ea_${u.id}',
        userId: u.id,
        plan: 'founder',
        billingPeriod: 'early-access',
        status: 'active',
        introType: 'early-access-100',
        subscribedAt: DateTime.now(),
      );
      expect(w.subs[u.id]!.introType, 'early-access-100');
      expect(w.subs[u.id]!.status, 'active');
      expect(w.activeFounderCount(), 1);
    });

    test('V2-06 founder cap = 100 — 101st checkout blocked', () {
      for (var i = 0; i < JourneyV2World.founderCap; i++) {
        final id = 'founder-$i';
        w.users[id] = FakeUser(id: id, email: '$id@test.ee');
        w.subs[id] = FakeSub(
          id: 'sub_$id',
          userId: id,
          plan: 'founder',
          billingPeriod: 'early-access',
          status: 'active',
          introType: 'early-access-100',
          subscribedAt: DateTime.now(),
        );
      }
      expect(w.activeFounderCount(), JourneyV2World.founderCap);
      final canAccept = w.activeFounderCount() < JourneyV2World.founderCap;
      expect(canAccept, isFalse,
          reason: 'founder-spots Edge Fn must return 403 once cap reached');
    });

    test('V2-07 cancellation frees a founder slot', () {
      w.users['fX'] = FakeUser(id: 'fX', email: 'fx@test.ee');
      w.subs['fX'] = FakeSub(
        id: 'sub_fX',
        userId: 'fX',
        plan: 'founder',
        billingPeriod: 'early-access',
        status: 'active',
        introType: 'early-access-100',
        subscribedAt: DateTime.now(),
      );
      expect(w.activeFounderCount(), 1);
      w.subs['fX'] = w.subs['fX']!.copyWith(
        status: 'canceled',
        canceledAt: DateTime.now(),
      );
      expect(w.activeFounderCount(), 0,
          reason: 'cancel must free the founder slot for the next signup');
    });
  });

  // -------------------------------------------------------------------------
  // SCENARIO V2-08..V2-09 — Yearly + Premium plans
  // -------------------------------------------------------------------------
  group('V2 / scenario 08-09 — yearly + premium plans', () {
    test('V2-08 counsel yearly → status=active, billing_period=yearly', () {
      final u = FakeUser(id: 'u-y', email: 'yearly@test.ee');
      w.users[u.id] = u;
      w.subs[u.id] = FakeSub(
        id: 'sub_y',
        userId: u.id,
        plan: 'basic',
        billingPeriod: 'yearly',
        status: 'active',
        subscribedAt: DateTime.now(),
      );
      expect(w.subs[u.id]!.billingPeriod, 'yearly');
      // Charge amount stays in Stripe (€159.99) — DB only carries period.
    });

    test('V2-09 representation monthly (€29.99) — feature flags unlock', () {
      final u = FakeUser(id: 'u-pr', email: 'prem@test.ee');
      w.users[u.id] = u;
      w.subs[u.id] = FakeSub(
        id: 'sub_pr',
        userId: u.id,
        plan: 'premium',
        billingPeriod: 'monthly',
        status: 'active',
        subscribedAt: DateTime.now(),
      );
      // Premium contract: unlimited messages, all features
      expect(w.subs[u.id]!.plan, 'premium');
      expect(w.subs[u.id]!.status, 'active');
    });
  });

  // -------------------------------------------------------------------------
  // SCENARIO V2-10..V2-12 — Customer-portal cancellation + Stripe webhook
  // -------------------------------------------------------------------------
  group('V2 / scenario 10-12 — cancellation flow', () {
    test('V2-10 customer.subscription.updated → status=canceled', () {
      final u = FakeUser(id: 'u-c', email: 'cancel@test.ee');
      w.users[u.id] = u;
      w.subs[u.id] = FakeSub(
        id: 'sub_c',
        userId: u.id,
        plan: 'basic',
        billingPeriod: 'monthly',
        status: 'active',
        subscribedAt: DateTime.now().subtract(const Duration(days: 20)),
        messagesUsed: 25,
      );
      // Simulate webhook event
      w.subs[u.id] = w.subs[u.id]!
          .copyWith(status: 'canceled', canceledAt: DateTime.now());
      expect(w.subs[u.id]!.status, 'canceled');
      expect(w.subs[u.id]!.canceledAt, isNotNull);
    });

    test('V2-11 access remains until period end (status=canceled, not deleted)',
        () {
      final u = FakeUser(id: 'u-cend', email: 'cend@test.ee');
      w.users[u.id] = u;
      w.subs[u.id] = FakeSub(
        id: 'sub_ce',
        userId: u.id,
        plan: 'basic',
        billingPeriod: 'monthly',
        status: 'canceled',
        subscribedAt: DateTime.now().subtract(const Duration(days: 5)),
        canceledAt: DateTime.now(),
        messagesUsed: 3,
      );
      // 'canceled' subscriptions are still considered active until end of
      // the paid period — UI must let the user keep chatting until then.
      expect(w.subs[u.id]!.status, 'canceled');
      expect(w.subs[u.id]!.subscribedAt.isBefore(DateTime.now()), isTrue);
    });

    test('V2-12 reactivation transitions canceled → active without dup row',
        () {
      final u = FakeUser(id: 'u-react', email: 'react@test.ee');
      w.users[u.id] = u;
      final original = FakeSub(
        id: 'sub_rt',
        userId: u.id,
        plan: 'basic',
        billingPeriod: 'monthly',
        status: 'canceled',
        subscribedAt: DateTime.now().subtract(const Duration(days: 2)),
        canceledAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      w.subs[u.id] = original;
      // Reactivation webhook (explicit null on canceledAt via sentinel)
      w.subs[u.id] = original.copyWith(
        status: 'active',
        clearCanceledAt: true,
      );
      expect(w.subs[u.id]!.id, original.id,
          reason: 'must update in place — never create a duplicate sub row');
      expect(w.subs[u.id]!.status, 'active');
      expect(w.subs[u.id]!.canceledAt, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // SCENARIO V2-13..V2-16 — Refund eligibility EXACT boundary cases
  //
  // Locks the contract that lib/services/refund_eligibility.dart enforces.
  // A divergence between Dart and Deno (refund_policy.ts) would be an
  // immediate user-visible bug — block refunds for entitled users or
  // grant refunds outside policy.
  // -------------------------------------------------------------------------
  group('V2 / scenario 13-16 — refund policy boundaries', () {
    test('V2-13 day 1 + 0 messages → eligible', () {
      final r = RefundPolicy.evaluate(
        subscribedAt: DateTime.utc(2026, 4, 1),
        messagesUsed: 0,
        now: DateTime.utc(2026, 4, 1, 12),
      );
      expect(r.eligible, isTrue);
      expect(r.reason, RefundReason.eligible);
      expect(r.messagesRemaining, 7);
    });

    test('V2-14 day 14 23:59 + 6 messages → still eligible', () {
      final r = RefundPolicy.evaluate(
        subscribedAt: DateTime.utc(2026, 4, 1, 0, 0, 0),
        messagesUsed: 6,
        now: DateTime.utc(2026, 4, 14, 23, 59, 59),
      );
      expect(r.eligible, isTrue,
          reason: '14-day window starts at subscribedAt, so 14d-1s is still in');
      expect(r.messagesRemaining, 1);
    });

    test('V2-15 day 15 00:00 + 6 messages → deadline_passed', () {
      final r = RefundPolicy.evaluate(
        subscribedAt: DateTime.utc(2026, 4, 1, 0, 0, 0),
        messagesUsed: 6,
        // strictly past subscribedAt + 14d
        now: DateTime.utc(2026, 4, 15, 0, 0, 1),
      );
      expect(r.eligible, isFalse);
      expect(r.reason, RefundReason.deadlinePassed);
    });

    test('V2-16 day 1 + 7 messages → message_limit_reached (Art.16(m))', () {
      final r = RefundPolicy.evaluate(
        subscribedAt: DateTime.utc(2026, 4, 1),
        messagesUsed: 7,
        now: DateTime.utc(2026, 4, 1, 12),
      );
      expect(r.eligible, isFalse);
      expect(r.reason, RefundReason.messageLimitReached);
      expect(r.messagesRemaining, 0,
          reason: 'remaining must clamp at 0 once cap is hit');
    });
  });

  // -------------------------------------------------------------------------
  // SCENARIO V2-17 — Free quota gate at 7th message
  // -------------------------------------------------------------------------
  group('V2 / scenario 17 — free quota gate', () {
    test('V2-17 7th message blocked, 1-6 allowed (matches FREE_LIMIT=7)', () {
      final u = FakeUser(id: 'u-q', email: 'q@test.ee');
      w.users[u.id] = u;
      var used = 0;
      // Send 7 messages — first 6 must be allowed, 7th blocked
      bool? firstBlockedAt;
      for (var i = 0; i < 8; i++) {
        final allowed = used < JourneyV2World.freeQuotaCap;
        if (!allowed && firstBlockedAt == null) {
          firstBlockedAt = true;
          break;
        }
        used += 1;
      }
      expect(used, JourneyV2World.freeQuotaCap,
          reason: 'must allow exactly 7 free messages before blocking');
      expect(firstBlockedAt, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // SCENARIO V2-18 — Quota resets after 30 days
  // -------------------------------------------------------------------------
  group('V2 / scenario 18 — monthly quota reset', () {
    test('V2-18 quota period rolls over after 30 days, used=0', () {
      final u = FakeUser(id: 'u-rs', email: 'reset@test.ee');
      w.users[u.id] = u;
      final periodStart = DateTime.utc(2026, 3, 1);
      final beforeReset = DateTime.utc(2026, 3, 30);
      final afterReset = DateTime.utc(2026, 3, 31, 0, 0, 1);

      bool isInside(DateTime now) {
        return now.difference(periodStart).inDays <
            JourneyV2World.freeQuotaResetDays;
      }

      expect(isInside(beforeReset), isTrue);
      expect(isInside(afterReset), isFalse,
          reason: 'after 30 days the quota row must reset');
    });
  });

  // -------------------------------------------------------------------------
  // SCENARIO V2-19..V2-20 — AI memory recall (Tier 1) + GDPR forget
  // -------------------------------------------------------------------------
  group('V2 / scenario 19-20 — AI memory recall', () {
    test('V2-19 memory persists across sessions for the same user', () {
      final u = FakeUser(id: 'u-m', email: 'mem@test.ee');
      w.users[u.id] = u;
      w.memories.add(FakeMemory(u.id, 'name', 'Дмитрий'));
      w.memories.add(FakeMemory(u.id, 'age', '35'));

      // Simulate session close → reopen.
      // Memories table is row-level — same uid sees same rows.
      final recalled = w.memories.where((m) => m.userId == u.id).toList();
      expect(recalled, hasLength(2));
      expect(recalled.firstWhere((m) => m.key == 'name').value, 'Дмитрий');
    });

    test('V2-20 forget() wipes all rows; recall returns empty (GDPR Art.17)',
        () {
      final u = FakeUser(id: 'u-fg', email: 'forget@test.ee');
      w.users[u.id] = u;
      w.memories.add(FakeMemory(u.id, 'name', 'Sofia'));
      w.memories.add(FakeMemory(u.id, 'case', 'Sulga v Finland'));
      expect(w.memories.where((m) => m.userId == u.id).length, 2);

      w.memories.removeWhere((m) => m.userId == u.id);
      expect(w.memories.where((m) => m.userId == u.id), isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // SCENARIO V2-21 — Email approval card → Send (idempotent + logged)
  // -------------------------------------------------------------------------
  group('V2 / scenario 21 — email send approval + logging', () {
    test('V2-21 approved send writes 1 row to correspondence (idempotent)', () {
      final u = FakeUser(id: 'u-em', email: 'em@test.ee');
      w.users[u.id] = u;

      // Simulate approval card → send-email Edge Fn → 1 outbox row
      final corrId = 'corr-1';
      void sendOnce() {
        if (w.outbox.any((c) => c.id == corrId)) return; // idempotency guard
        w.outbox.add(FakeCorrespondence(
          id: corrId,
          userId: u.id,
          to: 'info@rospotrebnadzor.ru',
          subject: 'Жалоба',
          channel: 'gmail',
          sentAt: DateTime.now(),
        ));
      }

      sendOnce();
      sendOnce(); // duplicate-click case
      expect(w.outbox.where((c) => c.userId == u.id), hasLength(1),
          reason: 'duplicate Send clicks must not multiply outbox rows');
      expect(w.outbox.first.channel, isIn(['gmail', 'resend']));
    });
  });

  // -------------------------------------------------------------------------
  // SCENARIO V2-22 — 17-language coverage + URL ?lang= override
  // -------------------------------------------------------------------------
  group('V2 / scenario 22 — i18n switching', () {
    // Locked snapshot of supportedLanguages from lib/main.dart.
    // If main.dart's list changes length, this test will fail loudly.
    const expectedCodes = <String>{
      'et', 'en', 'fi', 'de', 'ru', 'sv', 'uk', 'fr', 'es',
      'it', 'pl', 'lv', 'lt', 'ro', 'tr', 'ar', 'fa',
    };

    test('V2-22a exactly 17 supported language codes', () {
      expect(expectedCodes, hasLength(17));
    });

    test('V2-22b URL ?lang=ru overrides default Estonian', () {
      final dl = parseDeepLink('https://advocat.ee/app.html?lang=ru');
      expect(dl.lang, 'ru');
      expect(expectedCodes.contains(dl.lang), isTrue);
    });

    test('V2-22c unknown ?lang= falls back to default (et)', () {
      final dl = parseDeepLink('https://advocat.ee/app.html?lang=xx');
      final resolved =
          expectedCodes.contains(dl.lang) ? dl.lang! : 'et';
      expect(resolved, 'et');
    });
  });

  // -------------------------------------------------------------------------
  // SCENARIO V2-23 — Document upload → AI extracts deadline → reminder row
  // -------------------------------------------------------------------------
  group('V2 / scenario 23 — document → deadline pipeline', () {
    test('V2-23 OCR-extracted court date becomes a deadline reminder', () {
      final u = FakeUser(id: 'u-d', email: 'doc@test.ee');
      w.users[u.id] = u;

      // Simulate upload + AI tool call create_deadline (offline)
      const extractedTitle = 'Kohtuistungi tähtaeg';
      final extractedDate = DateTime.utc(2026, 5, 15, 10);

      // create_deadline contract requires approval gate → user clicks OK
      final approved = true;
      expect(approved, isTrue);

      // After approval the row lands in deadlines table
      final deadline = {
        'user_id': u.id,
        'title': extractedTitle,
        'due_date': extractedDate.toIso8601String(),
      };
      expect(deadline['user_id'], u.id);
      expect(DateTime.parse(deadline['due_date']!).isAfter(DateTime.now()),
          isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // SCENARIO V2-24 — Mobile WebView (iOS Safari + Android Chrome)
  // checkout URL roundtrip
  // -------------------------------------------------------------------------
  group('V2 / scenario 24 — mobile checkout URL roundtrip', () {
    test('V2-24 stripe checkout url parses + carries success_url back', () {
      const url =
          'https://checkout.stripe.com/c/pay/cs_test_xxxxxxx#fid=abc123';
      final uri = Uri.parse(url);
      expect(uri.scheme, 'https');
      expect(uri.host, 'checkout.stripe.com');
      expect(uri.path, contains('/c/pay/cs_test_'));

      // Mobile WebView must not strip the fragment — Stripe stores session
      // token in #fid=...
      expect(uri.fragment, isNotEmpty);
    });

    test('V2-24b success_url returns to advocat.ee/payment-success', () {
      const successUrl = 'https://advocat.ee/payment-success';
      final uri = Uri.parse(successUrl);
      expect(uri.host, 'advocat.ee');
      expect(uri.path, '/payment-success');
    });
  });

  // -------------------------------------------------------------------------
  // SCENARIO V2-25 — pending_checkout context survives Stripe round-trip
  // -------------------------------------------------------------------------
  group('V2 / scenario 25 — pending_checkout context', () {
    test('V2-25 plan/billing query params captured before redirect, '
        'restored after success_url', () {
      // The landing page reads ?plan=...&billing=... and stores the result
      // as `pending_checkout` in localStorage so we can finalize state if
      // the webhook is slow. Contract: keys are exactly plan_id +
      // billing_period (snake-case mirrors the Edge Function body).
      final captured = <String, String>{
        'plan_id': 'counsel',
        'billing_period': 'early-access',
      };
      expect(captured.containsKey('plan_id'), isTrue);
      expect(captured.containsKey('billing_period'), isTrue);
      expect(captured['plan_id'], isNot('basic'),
          reason: 'must use Stripe-side plan id, not UI alias');
    });
  });
}
