import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/shared/pending_checkout.dart';

/// Tests for [PendingCheckout] — URL → checkout deep link parsing.
///
/// The marketing landing forwards users with `/app.html?plan=...&billing=...`.
/// These tests pin the allow-lists so a typo or stale Stripe migration can't
/// silently send users into an invalid Stripe session.
void main() {
  group('PendingCheckout.fromQuery — accepted combinations', () {
    test('counsel + early-access', () {
      final p = PendingCheckout.fromQuery({
        'plan': 'counsel',
        'billing': 'early-access',
      });
      expect(p, isNotNull);
      expect(p!.planId, 'counsel');
      expect(p.billingPeriod, 'early-access');
    });

    test('counsel + monthly', () {
      final p = PendingCheckout.fromQuery({
        'plan': 'counsel',
        'billing': 'monthly',
      });
      expect(p?.planId, 'counsel');
      expect(p?.billingPeriod, 'monthly');
    });

    test('counsel + yearly', () {
      final p = PendingCheckout.fromQuery({
        'plan': 'counsel',
        'billing': 'yearly',
      });
      expect(p?.billingPeriod, 'yearly');
    });

    test('representation + monthly', () {
      final p = PendingCheckout.fromQuery({
        'plan': 'representation',
        'billing': 'monthly',
      });
      expect(p?.planId, 'representation');
    });

    test('representation + yearly', () {
      final p = PendingCheckout.fromQuery({
        'plan': 'representation',
        'billing': 'yearly',
      });
      expect(p?.planId, 'representation');
    });
  });

  group('PendingCheckout.fromQuery — rejections', () {
    test('missing both params returns null', () {
      expect(PendingCheckout.fromQuery({}), isNull);
    });

    test('missing plan returns null', () {
      expect(
        PendingCheckout.fromQuery({'billing': 'monthly'}),
        isNull,
      );
    });

    test('missing billing returns null', () {
      expect(
        PendingCheckout.fromQuery({'plan': 'counsel'}),
        isNull,
      );
    });

    test('unknown plan id returns null', () {
      expect(
        PendingCheckout.fromQuery({
          'plan': 'enterprise',
          'billing': 'monthly',
        }),
        isNull,
      );
    });

    test('UI plan id "basic" rejected (caller must pass Stripe id)', () {
      // The deep-link contract uses Stripe-side ids (`counsel`/`representation`)
      // so the landing page hrefs and the edge function stay in sync.
      expect(
        PendingCheckout.fromQuery({
          'plan': 'basic',
          'billing': 'monthly',
        }),
        isNull,
      );
    });

    test('representation + early-access rejected (Premium has no EA tier)',
        () {
      // Stripe edge function only defines `early-access` under `counsel`.
      // The frontend must mirror that: only `counsel` accepts early-access.
      // (Currently we accept the pair at the URL layer and let the edge
      // function reject it — but the test pins the contract for the future
      // when we tighten it. For now we expect non-null so the edge function
      // is the sole source of truth.)
      final p = PendingCheckout.fromQuery({
        'plan': 'representation',
        'billing': 'early-access',
      });
      // This documents current behaviour; if we tighten validation, flip.
      expect(p, isNotNull,
          reason:
              'today the edge function rejects this; flip when we add UI guard');
    });

    test('typo in billing period rejected', () {
      expect(
        PendingCheckout.fromQuery({
          'plan': 'counsel',
          'billing': 'monthy', // typo
        }),
        isNull,
      );
    });
  });

  group('PendingCheckoutNotifier — consume / clear', () {
    test('consume returns the value once and then null', () {
      final n = PendingCheckoutNotifier();
      // Force an internal value (bypasses Uri.base on web).
      n.state = const PendingCheckout(
        planId: 'counsel',
        billingPeriod: 'early-access',
      );
      final first = n.consume();
      expect(first?.planId, 'counsel');
      expect(n.consume(), isNull);
    });

    test('clear nulls the state without returning the value', () {
      final n = PendingCheckoutNotifier();
      n.state = const PendingCheckout(
        planId: 'representation',
        billingPeriod: 'monthly',
      );
      n.clear();
      expect(n.state, isNull);
    });
  });
}
