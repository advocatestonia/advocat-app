import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session_storage.dart';

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

  /// Build from the JSON we wrote to sessionStorage. Validates via the
  /// same allow-list as [fromQuery] so a tampered storage value can't
  /// inject an arbitrary `plan_id` into the Edge function.
  static PendingCheckout? fromJsonString(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final plan = decoded['planId'];
      final billing = decoded['billingPeriod'];
      if (plan is! String || billing is! String) return null;
      if (!_validPlanIds.contains(plan)) return null;
      if (!_validBillingPeriods.contains(billing)) return null;
      return PendingCheckout(planId: plan, billingPeriod: billing);
    } catch (_) {
      return null;
    }
  }

  /// Serialise to the JSON shape persisted in sessionStorage.
  Map<String, dynamic> toJson() => {
        'planId': planId,
        'billingPeriod': billingPeriod,
      };

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

/// Riverpod state for [PendingCheckout]. Initialised from `Uri.base` on web,
/// then from `window.sessionStorage` as a fallback so the Stripe redirect
/// → return bounce (or a hard refresh on the success page) doesn't lose
/// the user's intent.
class PendingCheckoutNotifier extends StateNotifier<PendingCheckout?> {
  PendingCheckoutNotifier() : super(_load()) {
    // If we restored from URL on construction, mirror it to sessionStorage
    // so a refresh during the auth bounce can recover it.
    final v = state;
    if (v != null) _persist(v);
  }

  /// sessionStorage key. Versioned so a future schema change can ignore
  /// stale entries from older builds.
  static const String _storageKey = 'pending_checkout';

  /// Load order: URL query (?plan=...&billing=...) → sessionStorage.
  /// URL wins because it represents the user's *current* intent — if
  /// they're on a fresh ?plan= URL we should trust that over any older
  /// stored value.
  static PendingCheckout? _load() {
    if (!kIsWeb) return null;
    try {
      final fromUrl = PendingCheckout.fromQuery(Uri.base.queryParameters);
      if (fromUrl != null) return fromUrl;
    } catch (_) {}
    try {
      final raw = SessionStorage.read(_storageKey);
      if (raw != null) {
        return PendingCheckout.fromJsonString(raw);
      }
    } catch (_) {}
    return null;
  }

  /// Mirror the active checkout to sessionStorage. Web-only; a no-op on
  /// native via the stub.
  static void _persist(PendingCheckout value) {
    if (!kIsWeb) return;
    SessionStorage.write(_storageKey, jsonEncode(value.toJson()));
  }

  static void _clearPersisted() {
    if (!kIsWeb) return;
    SessionStorage.remove(_storageKey);
  }

  /// Replace the current pending checkout. Mirrors the new value to
  /// sessionStorage so it survives the Stripe redirect bounce.
  // ignore: use_setters_to_change_properties
  void set(PendingCheckout value) {
    state = value;
    _persist(value);
  }

  /// Read the pending checkout and clear it. Returns `null` if there is
  /// no pending checkout (or it was already consumed). Clears the
  /// sessionStorage entry so a subsequent reload does not re-trigger
  /// Stripe Checkout — the caller is committing to redirect right now.
  PendingCheckout? consume() {
    final value = state;
    if (value != null) {
      state = null;
      _clearPersisted();
    }
    return value;
  }

  /// Manually clear without consuming (e.g. if the user is already Pro,
  /// or dismissed the upgrade dialog). Drops the sessionStorage entry so
  /// they aren't bounced back into Checkout on the next page load.
  void clear() {
    state = null;
    _clearPersisted();
  }
}

/// Provider wired into the auth-aware screens. Each screen that may receive
/// post-landing traffic (login, home) should `ref.read` and call [consume]
/// after the user is authenticated.
final pendingCheckoutProvider =
    StateNotifierProvider<PendingCheckoutNotifier, PendingCheckout?>((ref) {
  return PendingCheckoutNotifier();
});
