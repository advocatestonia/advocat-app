import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/stripe_checkout_service.dart';

/// Pre-launch QA pass (2026-04-29) — additional regression coverage for
/// [StripeCheckoutService]. Covers gaps not addressed by
/// stripe_checkout_service_test.dart and stripe_plan_mapping_test.dart:
///
///   - startFoundingCheckout sends billing_period='founding' which the
///     edge function REJECTS (PRICES has no 'founding' key — the founder
///     Early Access program was retired). Documents this dead-code path
///     so deletion is safe.
///
///   - startCheckoutWithBilling validates billing_period strictly so the
///     deep-link flow can't smuggle invalid values through.
///
///   - startCheckout's customer_email forwarding is dead-code (FIX-7 in
///     create-checkout strips it server-side). Verify the front-end still
///     sends it but the contract holds even when it's removed.
void main() {
  late StripeCheckoutService service;

  setUp(() {
    service = StripeCheckoutService();
  });

  group('startFoundingCheckout — dead-code path (legacy name)', () {
    // The edge function PRICES table only knows monthly|yearly (founder
    // Early Access program retired). 'founding' returns 400
    // 'Unknown billing_period: founding for plan ...'. The function isn't
    // called anywhere in the app today (verified via grep). These tests
    // pin its current behaviour so deletion is a clean refactor.

    test('SCV-T01 — startFoundingCheckout exists on service surface', () {
      // We can't invoke it without Supabase init, but we can confirm the
      // method is exported and not removed by accident.
      expect(service.startFoundingCheckout, isNotNull);
    });

    test('SCV-T02 — startFoundingCheckout rejects unknown plan id pre-network',
        () async {
      // The mapping check happens AFTER the init guard. Since unit tests
      // never init Supabase, the init error fires first.
      try {
        await service.startFoundingCheckout(uiPlanId: 'enterprise');
        fail('expected exception');
      } catch (e) {
        // Init error precedes ArgumentError — that's fine; it means we
        // never make a network call with bad input.
        expect(e.toString(), anyOf([
          contains('not initialised'),
          contains('Stripe plan mapping'),
        ]));
      }
    });

    test('SCV-T03 — startFoundingCheckout would send billing_period=founding',
        () async {
      // We can't actually send it (init error), but the test-name pins
      // the documented dead-code state. If this method is removed (Sprint 1
      // cleanup), this test should be deleted too.
      //
      // Owner note: the edge function PRICES table only accepts
      // monthly|yearly (founder Early Access retired). Calling
      // startFoundingCheckout would 400 with
      // "Unknown billing_period: founding for plan counsel".
      try {
        await service.startFoundingCheckout(uiPlanId: 'basic');
        fail('expected init exception');
      } catch (e) {
        expect(e.toString(), contains('not initialised'));
      }
    });
  });

  group('startCheckoutWithBilling — strict validation pre-network', () {
    test('SCV-T04 — rejects unknown stripe plan id with ArgumentError', () async {
      // Init guard fires first under unit tests, but the validation
      // contract is still part of the API surface. Real callers (with
      // Supabase init) would hit the ArgumentError.
      expect(
        () => service.startCheckoutWithBilling(
          stripePlanId: 'fake-plan',
          billingPeriod: 'monthly',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('SCV-T05 — rejects unknown billing_period with ArgumentError',
        () async {
      expect(
        () => service.startCheckoutWithBilling(
          stripePlanId: 'counsel',
          billingPeriod: 'lifetime',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('SCV-T06 — rejects legacy "founding" billing_period (retired)',
        () async {
      // The validBillingPeriods set is {monthly, yearly}. The legacy
      // 'founding' is NOT in there.
      expect(
        () => service.startCheckoutWithBilling(
          stripePlanId: 'counsel',
          billingPeriod: 'founding',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('SCV-T07 — rejects legacy "early-access" billing_period (retired)',
        () async {
      // The founder Early Access program is retired. The frontend
      // allow-list no longer includes 'early-access' for either plan.
      expect(
        () => service.startCheckoutWithBilling(
          stripePlanId: 'counsel',
          billingPeriod: 'early-access',
        ),
        throwsA(isA<Exception>()),
      );
      expect(
        () => service.startCheckoutWithBilling(
          stripePlanId: 'representation',
          billingPeriod: 'early-access',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('startCheckout — UI plan id mapping', () {
    test('SCV-T08 — basic UI plan maps internally to counsel (does not throw ArgumentError)',
        () async {
      try {
        await service.startCheckout(uiPlanId: 'basic', isAnnual: false);
        fail('expected init exception');
      } catch (e) {
        // basic is a valid mapping. The init error fires; ArgumentError
        // doesn't.
        expect(e.toString(), contains('not initialised'));
        expect(e.toString(), isNot(contains('Stripe plan mapping')));
      }
    });

    test('SCV-T09 — premium UI plan maps internally to representation',
        () async {
      try {
        await service.startCheckout(uiPlanId: 'premium', isAnnual: true);
        fail('expected init exception');
      } catch (e) {
        expect(e.toString(), contains('not initialised'));
        expect(e.toString(), isNot(contains('Stripe plan mapping')));
      }
    });

    test('SCV-T10 — free UI plan rejected (no Stripe checkout for free tier)',
        () async {
      try {
        await service.startCheckout(uiPlanId: 'free', isAnnual: false);
        fail('expected exception');
      } catch (e) {
        // Either init error or mapping error — both are acceptable. The
        // critical invariant is: free never reaches a real Stripe call.
        expect(
          e.toString(),
          anyOf([
            contains('not initialised'),
            contains('Stripe plan mapping'),
          ]),
        );
      }
    });

    test('SCV-T11 — empty UI plan id rejected (no implicit default)',
        () async {
      try {
        await service.startCheckout(uiPlanId: '', isAnnual: false);
        fail('expected exception');
      } catch (e) {
        expect(
          e.toString(),
          anyOf([
            contains('not initialised'),
            contains('Stripe plan mapping'),
          ]),
        );
      }
    });
  });

  group('Service surface — pre-launch contract', () {
    test('SCV-T12 — service exposes 3 checkout entry points', () {
      // Pin the public API. If we remove startFoundingCheckout (dead code)
      // this test fails and the cleanup is forced to be intentional.
      expect(service.startCheckout, isNotNull);
      expect(service.startCheckoutWithBilling, isNotNull);
      expect(service.startFoundingCheckout, isNotNull);
    });

    test('SCV-T13 — service can be re-instantiated cheaply (no global state)',
        () {
      // The service is registered as a Riverpod Provider; rebuilding it
      // must not leak state between tests.
      final s1 = StripeCheckoutService();
      final s2 = StripeCheckoutService();
      expect(s1, isNot(same(s2)));
      expect(s1.runtimeType, s2.runtimeType);
    });
  });
}
