// Source-contract tests for the Founder's Beta v1.0 subscription screen
// changes (Pricing Phase 5).
//
// Running the full SubscriptionScreen widget requires a live Supabase
// client (currentUserProvider resolves via Supabase.auth), which is out
// of scope for unit tests. Instead we pin the behaviour at the source
// level — the plan list must not mention the premium €29.99 tier while
// the Founder's Beta cap is active, and the Founder's Beta badge widget
// must be referenced in the screen.
//
// These tests fail if someone accidentally re-adds the Pro tier without
// also flipping `app_config.beta_cap.active` to false.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _readScreen() {
  final file = File(
    'lib/features/settings/screens/subscription_screen.dart',
  );
  return file.readAsStringSync();
}

/// Strips // line comments and /* block */ comments so doc strings don't
/// produce false positives on the "no premium tier" checks below.
String _stripComments(String src) {
  return src
      .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
      .replaceAll(RegExp(r'^\s*//.*$', multiLine: true), '');
}

void main() {
  group('SubscriptionScreen — Founder\'s Beta v1.0 UI cleanup', () {
    test('plan list does not instantiate a premium _PlanCard', () {
      final src = _stripComments(_readScreen());
      // The pre-beta screen had three `planId: 'premium'` PlanCards in
      // _buildPlans. While the beta is active there should be NONE.
      expect(
        src.contains("planId: 'premium'"),
        isFalse,
        reason:
            'premium (€29.99) tier must be hidden during Founder\'s Beta v1.0',
      );
    });

    test('plan list does not reference the €29.99 monthly price', () {
      final src = _stripComments(_readScreen());
      // monthlyPrice: 29.99 / annualPrice: 249.99 were the Pro tier —
      // both must be removed from the active code path.
      expect(
        src.contains('monthlyPrice: 29.99'),
        isFalse,
        reason: 'Pro tier price must not appear in plan cards',
      );
      expect(
        src.contains('annualPrice: 249.99'),
        isFalse,
        reason: 'Pro tier annual price must not appear in plan cards',
      );
    });

    test('Founder\'s Beta badge widget is wired into the body', () {
      final src = _readScreen();
      expect(
        src.contains('_FounderBetaBadge'),
        isTrue,
        reason: 'Subscription screen must show the Founder\'s Beta badge',
      );
      // The badge must pull copy from l10n.founderBetaBadge.
      expect(
        src.contains('founderBetaBadge'),
        isTrue,
        reason: 'Badge must use the localised founderBetaBadge string',
      );
    });

    test('refund policy short line is surfaced on the screen', () {
      final src = _readScreen();
      expect(
        src.contains('refundPolicyShort'),
        isTrue,
        reason:
            'Refund policy line (14-day OR 7 responses) must be visible '
            'on the pricing screen during Founder\'s Beta',
      );
    });

    test('basic (€14.99) tier remains visible', () {
      // The remaining paid tier during the beta.
      final src = _stripComments(_readScreen());
      expect(
        src.contains("planId: 'basic'"),
        isTrue,
        reason: 'Basic (Legal Counsel) tier must still be offered',
      );
      expect(
        src.contains('monthlyPrice: 14.99'),
        isTrue,
        reason: 'Basic tier €14.99 price must still be listed',
      );
    });

    test('free tier remains visible', () {
      final src = _stripComments(_readScreen());
      expect(src.contains("planId: 'free'"), isTrue);
    });
  });
}
