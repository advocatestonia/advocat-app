import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pricing plan deep-link captured from the URL on app boot.
///
/// The marketing landing (`web/landing-v25-draft.html`) sends users into
/// the app with query params, e.g. `/app.html?plan=counsel&billing=monthly`.
/// Once captured this is held until either:
///   - the user authenticates, at which point the post-login flow consumes
///     it via [consume] and triggers Stripe Checkout, or
///   - the app session ends (page reload clears it).
///
/// Captured exactly once at process start. Unknown values are dropped so a
/// malformed URL never reaches the edge function.
class PendingCheckout {
  const PendingCheckout({required this.planId, required this.billingPeriod});

  /// Stripe-side plan id: `counsel` (Pro) or `representation` (Premium).
  final String planId;

  /// `monthly` or `yearly`. Mirrors create-checkout's price table —
  /// kept in sync via [_validBillingPeriods].
  final String billingPeriod;

  static const Set<String> _validPlanIds = {'counsel', 'representation'};
  static const Set<String> _validBillingPeriods = {
    'monthly',
    'yearly',
  };

  /// Build from a URL's query parameters. Returns `null` if either field
  /// is missing or not in the allow-list.
  static PendingCheckout? fromQuery(Map<String, String> q) {
    final plan = q['plan'];
    final billing = q['billing'];
    if (plan == null || billing == null) return null;
    if (!_validPlanIds.contains(plan)) return null;
    if (!_validBillingPeriods.contains(billing)) return null;
    return PendingCheckout(planId: plan, billingPeriod: billing);
  }

  @override
  bool operator ==(Object other) =>
      other is PendingCheckout &&
      other.planId == planId &&
      other.billingPeriod == billingPeriod;

  @override
  int get hashCode => Object.hash(planId, billingPeriod);

  @override
  String toString() =>
      'PendingCheckout(plan=$planId, billing=$billingPeriod)';
}

/// Riverpod state for [PendingCheckout]. Initialised from `Uri.base` on web.
class PendingCheckoutNotifier extends StateNotifier<PendingCheckout?> {
  PendingCheckoutNotifier() : super(_loadFromUrl());

  static PendingCheckout? _loadFromUrl() {
    if (!kIsWeb) return null;
    try {
      return PendingCheckout.fromQuery(Uri.base.queryParameters);
    } catch (_) {
      return null;
    }
  }

  /// Read the pending checkout and clear it. Returns `null` if there is
  /// no pending checkout (or it was already consumed).
  PendingCheckout? consume() {
    final value = state;
    if (value != null) state = null;
    return value;
  }

  /// Manually clear without consuming (e.g. if the user is already Pro).
  void clear() {
    state = null;
  }
}

/// Provider wired into the auth-aware screens. Each screen that may receive
/// post-landing traffic (login, home) should `ref.read` and call [consume]
/// after the user is authenticated.
final pendingCheckoutProvider =
    StateNotifierProvider<PendingCheckoutNotifier, PendingCheckout?>((ref) {
  return PendingCheckoutNotifier();
});
