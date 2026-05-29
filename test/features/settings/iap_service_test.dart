@Tags(['fast'])
library;

// =============================================================================
// IapService — source + contract tests.
//
// Mocking the full in_app_purchase platform interface in a unit test is
// brittle (the abstract class evolves between minor versions and our mock
// would silently drift). Instead we lock down the things that matter for
// the iOS install funnel:
//
//   T01 Enum → App Store Connect product-id mapping is stable. A rename in
//       Dart without a matching App Store Connect rename would silently
//       break iOS purchases.
//   T02 kIapProductIds covers every IapPlanId (no orphans, no missing).
//   T03 IapResult factories produce the documented kind/payload combos —
//       UI relies on `kind` switching for snackbar text.
//   T04 Android stub is OFF until Play Console + google-play-iap-verify
//       ship. Flipping this without those parts in place would hit a
//       non-existent endpoint and never activate.
//   T05 The 5 IAP ARB keys exist in EVERY locale (17 files). A missing
//       translation in any locale means the UI crashes on that locale
//       when reading l10n.iapPayWithApple.
//   T06 subscription_screen.dart routes through IapService on iOS — source
//       contract guard so a future refactor doesn't quietly revert to
//       Stripe-only.
//   T07 The Apple verify edge function path is referenced from
//       iap_service.dart (catches a renamed function name on the server
//       side that would silently break receipt validation).
// =============================================================================

import 'dart:convert';
import 'dart:io';

import 'package:advocat/features/settings/services/iap_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── T01 + T02 ─────────────────────────────────────────────────────────
  group('IapPlanId → App Store Connect product id', () {
    test('T01 maps every plan to the canonical product id', () {
      expect(IapPlanId.counselMonthly.productId, 'counsel_monthly');
      expect(IapPlanId.counselAnnual.productId, 'counsel_annual');
      expect(IapPlanId.proMonthly.productId, 'pro_monthly');
      expect(IapPlanId.proAnnual.productId, 'pro_annual');
    });

    test('T02 kIapProductIds covers every IapPlanId exactly', () {
      final fromEnum = IapPlanId.values.map((p) => p.productId).toSet();
      expect(fromEnum, kIapProductIds);
    });
  });

  // ── T03 ───────────────────────────────────────────────────────────────
  group('IapResult factories', () {
    test('T03a success carries productId + transactionId', () {
      const r = IapResult.success(
        productId: 'pro_monthly',
        transactionId: 'tx_1',
      );
      expect(r.kind, IapResultKind.success);
      expect(r.productId, 'pro_monthly');
      expect(r.transactionId, 'tx_1');
      expect(r.message, isNull);
    });

    test('T03b cancelled / noActive / notSupported set kind only', () {
      expect(const IapResult.cancelled().kind, IapResultKind.cancelled);
      expect(const IapResult.cancelled().productId, isNull);
      expect(const IapResult.noActive().kind, IapResultKind.noActive);
      expect(const IapResult.notSupported().kind, IapResultKind.notSupported);
    });

    test('T03c error carries diagnostic message', () {
      const r = IapResult.error('Apple sandbox down');
      expect(r.kind, IapResultKind.error);
      expect(r.message, 'Apple sandbox down');
    });
  });

  // ── T04 ───────────────────────────────────────────────────────────────
  test('T04 Android Play Billing path is OFF until Play Console ships', () {
    // Flipping this to true without writing a google-play-iap-verify edge
    // function would let Android users hit a non-existent endpoint and
    // never activate. The launch checklist explicitly defers Android.
    expect(kAndroidIapEnabled, isFalse);
  });

  // ── T05 ───────────────────────────────────────────────────────────────
  group('17-locale ARB contract (no missing translations)', () {
    const requiredKeys = [
      'iapPayWithApple',
      'iapRestorePurchases',
      'iapPurchaseFailed',
      'iapRestoreSuccess',
      'iapRestoreNoActive',
    ];

    test('T05 every l10n/*.arb file contains all 5 IAP keys', () {
      final l10nDir = Directory('lib/l10n');
      expect(l10nDir.existsSync(), isTrue,
          reason: 'lib/l10n must exist at the test cwd');
      final arbFiles = l10nDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.arb'))
          .toList();
      expect(arbFiles.length, greaterThanOrEqualTo(17),
          reason: 'Expected 17 locales (we currently ship 17)');

      for (final f in arbFiles) {
        final map = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        for (final key in requiredKeys) {
          expect(map.containsKey(key), isTrue,
              reason: 'Locale ${f.path} missing key "$key"');
          expect((map[key] as String).trim().isNotEmpty, isTrue,
              reason: 'Locale ${f.path} key "$key" is empty');
        }
      }
    });
  });

  // ── T06 ───────────────────────────────────────────────────────────────
  group('subscription_screen.dart source contract', () {
    late String src;
    setUpAll(() {
      src = File('lib/features/settings/screens/subscription_screen.dart')
          .readAsStringSync();
    });

    test('T06a imports IapService', () {
      expect(src, contains("import '../services/iap_service.dart'"));
    });

    test('T06b routes iOS purchases through Apple IAP, not Stripe', () {
      // The handler picks between Apple IAP and Stripe based on
      // _shouldShowAppleIap(). If a refactor accidentally removed the
      // Apple branch, this assertion catches it.
      expect(src, contains('_shouldShowAppleIap()'));
      expect(src, contains('_handleApplePurchase'));
    });

    test('T06c Restore Purchases button is wired (App Store 3.1.1)', () {
      // Apple App Store Guideline 3.1.1 requires a Restore Purchases
      // button reachable from within the app. We must call IapService.restore
      // on iOS (browser-only restore would not be sufficient for review).
      expect(src, contains('iap.restore()'));
    });

    test('T06d Stripe path coexists for web + Android', () {
      // We do NOT remove the Stripe checkout call — Android and web users
      // depend on it. A regression here would break payments on every
      // non-iOS surface.
      expect(src, contains('stripeService.startCheckout('));
    });
  });

  // ── T07 ───────────────────────────────────────────────────────────────
  test('T07 iap_service.dart references the apple-iap-verify edge fn', () {
    final src = File(
      'lib/features/settings/services/iap_service.dart',
    ).readAsStringSync();
    // Source contract: the function name string in the client must match
    // the directory name of the edge function exactly.
    expect(src, contains("'apple-iap-verify'"));
    final fnDir =
        Directory('supabase/functions/apple-iap-verify');
    expect(fnDir.existsSync(), isTrue,
        reason: 'apple-iap-verify edge fn directory must exist');
  });

  // ── T08 ───────────────────────────────────────────────────────────────
  test(
      'T08 a purchased/restored transaction is only completed on a VERIFIED '
      'server result (charged-not-Pro guard)', () {
    // The in_app_purchase plugin can only be exercised by overriding the
    // platform interface, which the header explains is brittle. Instead we
    // lock the critical invariant at the source level: completePurchase
    // (which finishes a StoreKit transaction and removes it from the queue
    // so purchaseStream never re-delivers it) must be GATED on a successful
    // server verify. Completing on a FAILED verify would leave the user
    // charged by Apple but never activated, with no automatic retry.
    final src = File(
      'lib/features/settings/services/iap_service.dart',
    ).readAsStringSync();

    // Isolate the purchased/restored arm of the status switch: from those
    // case labels up to the next `break;`.
    final arm = RegExp(
      r'case PurchaseStatus\.purchased:\s*'
      r'case PurchaseStatus\.restored:([\s\S]*?)break;',
    ).firstMatch(src);
    expect(arm, isNotNull,
        reason: 'purchased/restored switch arm must exist');
    final body = arm!.group(1)!;

    // The completion call must live INSIDE the `if (verified)` block, i.e.
    // appear before the `} else {`. If a refactor moves it after the else
    // (or back to an unconditional call after the if/else), this fails.
    final completeIdx = body.indexOf('_completeIfNeeded(p)');
    final elseIdx = body.indexOf('} else {');
    expect(completeIdx, greaterThan(-1),
        reason: 'verified branch must complete the purchase');
    expect(elseIdx, greaterThan(-1),
        reason: 'verify-failure branch must exist');
    expect(completeIdx, lessThan(elseIdx),
        reason: 'completePurchase must be gated inside the verified branch, '
            'never reached on a failed verify');

    // And there must be exactly one completion call in this arm (no stray
    // unconditional completion after the else).
    final occurrences =
        '_completeIfNeeded(p)'.allMatches(body).length;
    expect(occurrences, 1,
        reason: 'exactly one gated completion in the purchased/restored arm');
  });
}
