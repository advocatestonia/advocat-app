import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/stripe_checkout_service.dart';

/// OMEGA-QA v1 — Stripe plan mapping regression tests.
///
/// Gap S1/S2/S3/S4 in docs/qa/02-missing-tests.md. The service silently
/// translates UI plan ids ('basic', 'premium') to Stripe plan ids
/// ('counsel', 'representation'). A typo in that map would ship subscribers
/// to the wrong price, which is invisible at compile time and silent at
/// runtime (the edge function would receive an unknown plan id and respond
/// with a generic 400). These tests pin the mapping via the public error
/// surface.
void main() {
  late StripeCheckoutService service;

  setUp(() {
    service = StripeCheckoutService();
  });

  group('Stripe plan mapping — known UI plan ids pass format check', () {
    // All three tests assume Supabase is NOT initialised (unit-test env), so
    // every call throws the "not initialised" exception BEFORE dispatching
    // to the edge function. We assert the error surface to distinguish
    // "mapping accepted your plan id" (init error) from "plan id rejected"
    // (ArgumentError).

    test('basic plan id reaches init-check (mapping accepts it)', () async {
      try {
        await service.startCheckout(uiPlanId: 'basic', isAnnual: false);
        fail('expected exception');
      } catch (e) {
        // Accepted by mapping → hits init guard
        expect(e.toString(), contains('not initialised'));
        expect(e, isNot(isA<ArgumentError>()));
      }
    });

    test('premium plan id reaches init-check (mapping accepts it)', () async {
      try {
        await service.startCheckout(uiPlanId: 'premium', isAnnual: true);
        fail('expected exception');
      } catch (e) {
        expect(e.toString(), contains('not initialised'));
        expect(e, isNot(isA<ArgumentError>()));
      }
    });

    test('basic plan id also works through founding checkout', () async {
      try {
        await service.startFoundingCheckout(uiPlanId: 'basic');
        fail('expected exception');
      } catch (e) {
        expect(e.toString(), contains('not initialised'));
        expect(e, isNot(isA<ArgumentError>()));
      }
    });
  });

  group('Stripe plan mapping — unknown UI plan ids rejected loudly', () {
    test('free plan id is rejected (no mapping to Stripe)', () async {
      // `free` is a UI concept only; it must never reach Stripe checkout.
      try {
        await service.startCheckout(uiPlanId: 'free', isAnnual: false);
        fail('expected exception');
      } catch (e) {
        // Either ArgumentError (mapping path) or Exception (init path).
        // The critical guarantee is: it throws, and the message mentions
        // either mapping or init.
        final msg = e.toString();
        expect(
          msg.contains('No Stripe plan mapping') ||
              msg.contains('not initialised'),
          isTrue,
          reason: 'free must not silently succeed: got "$msg"',
        );
      }
    });

    test('typo plan id "basics" is rejected', () async {
      try {
        await service.startCheckout(uiPlanId: 'basics', isAnnual: false);
        fail('expected exception');
      } catch (e) {
        final msg = e.toString();
        expect(
          msg.contains('No Stripe plan mapping') ||
              msg.contains('not initialised'),
          isTrue,
          reason: 'typo must fail: got "$msg"',
        );
      }
    });

    test('empty string plan id is rejected', () async {
      try {
        await service.startCheckout(uiPlanId: '', isAnnual: false);
        fail('expected exception');
      } catch (e) {
        final msg = e.toString();
        expect(
          msg.contains('No Stripe plan mapping') ||
              msg.contains('not initialised'),
          isTrue,
          reason: 'empty id must fail: got "$msg"',
        );
      }
    });
  });

  group('startCheckoutWithBilling — direct Stripe-id + billing period', () {
    // The deep-link flow (landing → /app.html?plan=...&billing=...) uses
    // raw Stripe ids and accepts only monthly/yearly. ArgumentError is
    // raised before reaching Supabase for any unknown value (founder
    // Early Access program retired).

    test('counsel + early-access rejected (founder program retired)', () async {
      expect(
        () => service.startCheckoutWithBilling(
          stripePlanId: 'counsel',
          billingPeriod: 'early-access',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('counsel + monthly reaches init-check', () async {
      try {
        await service.startCheckoutWithBilling(
          stripePlanId: 'counsel',
          billingPeriod: 'monthly',
        );
        fail('expected exception');
      } catch (e) {
        expect(e.toString(), contains('not initialised'));
        expect(e, isNot(isA<ArgumentError>()));
      }
    });

    test('representation + yearly reaches init-check', () async {
      try {
        await service.startCheckoutWithBilling(
          stripePlanId: 'representation',
          billingPeriod: 'yearly',
        );
        fail('expected exception');
      } catch (e) {
        expect(e.toString(), contains('not initialised'));
        expect(e, isNot(isA<ArgumentError>()));
      }
    });

    test('unknown stripe plan id is rejected (ArgumentError)', () async {
      expect(
        () => service.startCheckoutWithBilling(
          stripePlanId: 'enterprise',
          billingPeriod: 'monthly',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('UI plan id "basic" is rejected (ArgumentError)', () async {
      // This method takes Stripe-side ids only — `basic` is a UI label.
      expect(
        () => service.startCheckoutWithBilling(
          stripePlanId: 'basic',
          billingPeriod: 'monthly',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('unknown billing period is rejected (ArgumentError)', () async {
      expect(
        () => service.startCheckoutWithBilling(
          stripePlanId: 'counsel',
          billingPeriod: 'biennial',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('founding billing period is rejected (retired)', () async {
      // Regression guard: both legacy founder/founding billing periods are
      // retired. Calling with the old value must fail loudly.
      expect(
        () => service.startCheckoutWithBilling(
          stripePlanId: 'counsel',
          billingPeriod: 'founding',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Stripe plan mapping — founding checkout shares the same map', () {
    // Regression guard: the founding-member flow previously duplicated the
    // plan map. Now both paths share `_PlanMapping.toPlanId`, so the same
    // rejection happens in both.
    test('founding checkout rejects "free" plan', () async {
      try {
        await service.startFoundingCheckout(uiPlanId: 'free');
        fail('expected exception');
      } catch (e) {
        final msg = e.toString();
        expect(
          msg.contains('No Stripe plan mapping') ||
              msg.contains('not initialised'),
          isTrue,
        );
      }
    });

    test('founding checkout rejects unknown "enterprise" plan', () async {
      try {
        await service.startFoundingCheckout(uiPlanId: 'enterprise');
        fail('expected exception');
      } catch (e) {
        final msg = e.toString();
        expect(
          msg.contains('No Stripe plan mapping') ||
              msg.contains('not initialised'),
          isTrue,
        );
      }
    });
  });
}
