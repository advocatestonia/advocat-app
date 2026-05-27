// IapService — Apple StoreKit (iOS) + Google Play Billing (Android stub).
// -----------------------------------------------------------------------------
// Why this exists: the mobile install funnel was broken — iPhone users could
// only pay via Stripe web checkout (browser bounce ~⅔ drop-off). This service
// wires the platform-native IAP path next to Stripe so the mobile flow stays
// in-app (App Store Guideline 3.1.1 actually REQUIRES IAP for digital goods
// purchased in iOS apps; Stripe-only would be a rejection-on-review risk).
//
// Coexistence with Stripe:
//   - Web + Android (until Play config lands) → Stripe Checkout (unchanged).
//   - iOS native → Apple IAP via StoreKit.
//   - subscription_screen.dart shows EITHER the Stripe CTA OR the Apple CTA,
//     never both, because App Store rules forbid offering an alternative
//     payment for the same item ("anti-steering"). If a user is already on
//     Apple IAP, the Stripe button hides.
//
// Server-side validation:
//   purchaseStream → apple-iap-verify edge function (HMAC-protected, JWT,
//   rate-limited). The edge fn calls Apple's verifyReceipt (sandbox-first,
//   then production) and on success upserts profiles + subscriptions rows
//   in the SAME shape stripe-webhook does. The 5-layer activation pattern
//   (webhook write + idempotency + verify + reconcile + frontend isPro) is
//   preserved so the rest of the app (check-ai-quota, isProActive UI gate)
//   keeps working transparently regardless of payment source.
//
// App Store Connect product IDs (OWNER ACTION — must match exactly):
//   - counsel_monthly  → €19.99/month, Auto-Renewable Subscription
//   - counsel_annual   → €159.99/year, Auto-Renewable Subscription
//   - pro_monthly      → €29.99/month, Auto-Renewable Subscription
//   - pro_annual       → €249.99/year, Auto-Renewable Subscription
// Subscription group: "Advocat Subscriptions" (single group so the user
// can upgrade/downgrade in StoreKit without re-purchasing).
// -----------------------------------------------------------------------------

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Plan identifiers the UI passes in. Maps onto App Store Connect product IDs
/// 1:1; we keep them as separate constants so the mapping is greppable.
enum IapPlanId {
  counselMonthly,
  counselAnnual,
  proMonthly,
  proAnnual,
}

/// String key passed to StoreKit. MUST match App Store Connect exactly.
extension IapPlanIdProduct on IapPlanId {
  String get productId {
    switch (this) {
      case IapPlanId.counselMonthly:
        return 'counsel_monthly';
      case IapPlanId.counselAnnual:
        return 'counsel_annual';
      case IapPlanId.proMonthly:
        return 'pro_monthly';
      case IapPlanId.proAnnual:
        return 'pro_annual';
    }
  }
}

/// All product IDs we offer. Loaded from StoreKit at service init so the
/// price/title shown in-app comes from the App Store, not a hardcoded
/// constant (Apple requires this).
const Set<String> kIapProductIds = <String>{
  'counsel_monthly',
  'counsel_annual',
  'pro_monthly',
  'pro_annual',
};

/// Result envelope for purchase / restore calls. Plain data so the UI can
/// switch on `kind` without depending on the in_app_purchase package types.
class IapResult {
  const IapResult._({
    required this.kind,
    this.productId,
    this.transactionId,
    this.message,
  });

  const IapResult.success({String? productId, String? transactionId})
      : this._(
          kind: IapResultKind.success,
          productId: productId,
          transactionId: transactionId,
        );
  const IapResult.cancelled() : this._(kind: IapResultKind.cancelled);
  const IapResult.error(String message)
      : this._(kind: IapResultKind.error, message: message);
  const IapResult.noActive() : this._(kind: IapResultKind.noActive);
  const IapResult.notSupported() : this._(kind: IapResultKind.notSupported);

  final IapResultKind kind;
  final String? productId;
  final String? transactionId;
  final String? message;
}

enum IapResultKind {
  success,
  cancelled,
  error,
  noActive,
  notSupported,
}

/// Android Play Billing path is intentionally a stub. Flip this to true
/// when the Play Console product config (counsel_monthly etc) ships AND
/// the equivalent google-play-iap-verify edge fn is deployed.
///
/// TODO(android-iap, 2026-06): wire Play Billing once Console config exists.
const bool kAndroidIapEnabled = false;

/// Backend edge function that validates an Apple receipt and activates the
/// user's subscription (same DB shape stripe-webhook writes).
const String _kAppleVerifyFn = 'apple-iap-verify';

/// Test-only seam: production code goes through InAppPurchase.instance; tests
/// inject a fake InAppPurchasePlatform via the constructor.
class IapService {
  IapService({InAppPurchase? iap}) : _iap = iap ?? InAppPurchase.instance;

  final InAppPurchase _iap;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  final StreamController<IapResult> _resultController =
      StreamController<IapResult>.broadcast();
  bool _initialized = false;

  /// Emits the outcome of every purchase / restore (one event per
  /// PurchaseDetails completion). UI subscribes to surface snackbars.
  Stream<IapResult> get results => _resultController.stream;

  /// Returns true if IAP is supported on this device (iOS only for now —
  /// Android is gated behind kAndroidIapEnabled and currently false).
  bool get isSupportedOnPlatform {
    if (kIsWeb) return false;
    if (Platform.isIOS) return true;
    if (Platform.isAndroid) return kAndroidIapEnabled;
    return false;
  }

  /// Connect to the platform store and start listening for purchase updates.
  /// Idempotent — safe to call from multiple widgets.
  Future<bool> initialize() async {
    if (_initialized) return true;
    if (!isSupportedOnPlatform) return false;
    final available = await _iap.isAvailable();
    if (!available) return false;
    _purchaseSub = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _purchaseSub?.cancel(),
      onError: (Object e) {
        _resultController.add(IapResult.error(e.toString()));
      },
    );
    _initialized = true;
    return true;
  }

  Future<void> dispose() async {
    await _purchaseSub?.cancel();
    _purchaseSub = null;
    await _resultController.close();
  }

  /// Load product metadata (title, formatted price string) from the
  /// platform store. Returns an empty set if any product is missing —
  /// usually means App Store Connect config is incomplete.
  Future<Set<ProductDetails>> loadProducts() async {
    if (!await initialize()) return <ProductDetails>{};
    final response = await _iap.queryProductDetails(kIapProductIds);
    if (response.notFoundIDs.isNotEmpty) {
      // We still return the products we DID find so the UI can render
      // partial pricing while owner finishes App Store Connect config.
      debugPrint(
        '[IapService] Missing App Store products: ${response.notFoundIDs}',
      );
    }
    return response.productDetails.toSet();
  }

  /// Start a buy flow. Resolves immediately after StoreKit shows the sheet —
  /// the actual outcome lands on `results` via `_onPurchaseUpdate`.
  Future<void> buy(IapPlanId plan) async {
    if (!await initialize()) {
      _resultController.add(const IapResult.notSupported());
      return;
    }
    final response = await _iap.queryProductDetails({plan.productId});
    if (response.productDetails.isEmpty) {
      _resultController.add(
        IapResult.error('Product not configured: ${plan.productId}'),
      );
      return;
    }
    final pd = response.productDetails.first;
    // Auto-renewable subscriptions go via buyNonConsumable on iOS in v3.x.
    // (Apple treats subscriptions as a non-consumable from the store API's
    // perspective; the renewal lifecycle is handled by StoreKit.)
    final purchaseParam = PurchaseParam(productDetails: pd);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Replay finished purchases (App Store Guideline 3.1.1 requires a
  /// "Restore Purchases" button reachable from within the app). The
  /// purchaseStream re-delivers historic transactions, which we then
  /// validate server-side just like a fresh purchase.
  Future<void> restore() async {
    if (!await initialize()) {
      _resultController.add(const IapResult.notSupported());
      return;
    }
    await _iap.restorePurchases();
    // restorePurchases never resolves with the historic items directly —
    // they arrive via purchaseStream. _onPurchaseUpdate handles them.
    // If nothing comes through, the UI surfaces a "no previous purchases"
    // message after a short timeout (handled in subscription_screen.dart).
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.pending:
          // StoreKit is waiting on the user — no action.
          break;
        case PurchaseStatus.canceled:
          _resultController.add(const IapResult.cancelled());
          await _completeIfNeeded(p);
          break;
        case PurchaseStatus.error:
          _resultController.add(
            IapResult.error(p.error?.message ?? 'Purchase failed'),
          );
          await _completeIfNeeded(p);
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final verified = await _verifyWithServer(p);
          if (verified) {
            _resultController.add(
              IapResult.success(
                productId: p.productID,
                transactionId: p.purchaseID,
              ),
            );
          } else {
            _resultController.add(
              const IapResult.error(
                'Receipt verification failed — please contact support',
              ),
            );
          }
          await _completeIfNeeded(p);
          break;
      }
    }
  }

  Future<void> _completeIfNeeded(PurchaseDetails p) async {
    if (p.pendingCompletePurchase) {
      try {
        await _iap.completePurchase(p);
      } catch (e) {
        debugPrint('[IapService] completePurchase failed: $e');
      }
    }
  }

  /// POST the receipt to apple-iap-verify. The edge fn does Apple's
  /// verifyReceipt round-trip, mirrors the Stripe activation write-shape,
  /// and is idempotent on transaction_id (so a restore is safe to call
  /// repeatedly).
  Future<bool> _verifyWithServer(PurchaseDetails p) async {
    try {
      // serverVerificationData is the base64 receipt blob StoreKit hands us.
      final receiptData = p.verificationData.serverVerificationData;
      if (receiptData.isEmpty) {
        debugPrint('[IapService] empty serverVerificationData');
        return false;
      }
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        // No JWT — user is signed out. Verification cannot happen without
        // a user to attach the subscription to.
        return false;
      }
      final response = await Supabase.instance.client.functions.invoke(
        _kAppleVerifyFn,
        method: HttpMethod.post,
        body: {
          'receipt_data': receiptData,
          'product_id': p.productID,
          'transaction_id': p.purchaseID,
          'source': p.status == PurchaseStatus.restored ? 'restore' : 'purchase',
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data['ok'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('[IapService] verify error: $e');
      return false;
    }
  }
}
