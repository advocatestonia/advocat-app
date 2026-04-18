import 'package:flutter/foundation.dart' show kIsWeb;

import 'stripe_web_redirect.dart' as web_redirect;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// ── Provider ──────────────────────────────────────────────────────────────

final stripeCheckoutServiceProvider = Provider<StripeCheckoutService>((ref) {
  return StripeCheckoutService();
});

// ── Plan mapping ──────────────────────────────────────────────────────────

/// Maps the UI plan IDs ('free', 'basic', 'premium') to Stripe plan IDs
/// used by the edge function ('counsel', 'representation').
class _PlanMapping {
  static const Map<String, String> toPlanId = {
    'basic': 'counsel',
    'premium': 'representation',
  };

  /// Determine the billing_period string for the edge function.
  static String billingPeriod({required bool isAnnual}) {
    return isAnnual ? 'yearly' : 'monthly';
  }
}

// ── Service ───────────────────────────────────────────────────────────────

class StripeCheckoutService {
  StripeCheckoutService();

  /// Whether the Supabase client is available for making edge function calls.
  bool get _isInitialized {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Opens a Stripe Checkout session for the given [uiPlanId]
  /// ('basic' or 'premium') and [isAnnual] billing toggle.
  ///
  /// Returns `true` if the checkout URL was opened successfully.
  /// Throws on network or Stripe errors.
  Future<bool> startCheckout({
    required String uiPlanId,
    required bool isAnnual,
    String? customerEmail,
  }) async {
    if (!_isInitialized) {
      throw Exception(
        'Supabase is not initialised. Cannot create checkout session.',
      );
    }

    final stripePlanId = _PlanMapping.toPlanId[uiPlanId];
    if (stripePlanId == null) {
      throw ArgumentError('No Stripe plan mapping for "$uiPlanId"');
    }

    final billingPeriod = _PlanMapping.billingPeriod(isAnnual: isAnnual);

    final body = <String, dynamic>{
      'plan_id': stripePlanId,
      'billing_period': billingPeriod,
      'success_url': 'https://advocat.ee/payment-success',
      'cancel_url': 'https://advocat.ee/payment-cancel',
    };

    if (customerEmail != null && customerEmail.isNotEmpty) {
      body['customer_email'] = customerEmail;
    }

    final dynamic response;
    try {
      response = await Supabase.instance.client.functions.invoke(
        'create-checkout',
        body: body,
      );
    } catch (e) {
      throw Exception(
        'Network error calling checkout: $e. '
        'Please check your connection and try again.',
      );
    }

    if (response.status != 200) {
      final errorMsg = response.data is Map
          ? (response.data['error'] ?? 'Unknown error')
          : 'Edge function returned status ${response.status}';
      throw Exception('Failed to create checkout session: $errorMsg');
    }

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw Exception(
        'Unexpected response format from checkout: ${data.runtimeType}',
      );
    }
    final checkoutUrl = data['url'] as String?;

    if (checkoutUrl == null || checkoutUrl.isEmpty) {
      throw Exception('Checkout URL was empty');
    }

    final uri = Uri.parse(checkoutUrl);

    // On web: always redirect current page. Cannot be blocked by any browser.
    // On native: use url_launcher.
    if (kIsWeb) {
      web_redirect.redirectToUrl(checkoutUrl);
    } else {
      await launchUrl(uri);
    }
    return true;
  }

  /// Opens a Stripe Checkout for founding member pricing.
  Future<bool> startFoundingCheckout({
    required String uiPlanId,
    String? customerEmail,
  }) async {
    if (!_isInitialized) {
      throw Exception(
        'Supabase is not initialised. Cannot create checkout session.',
      );
    }

    final stripePlanId = _PlanMapping.toPlanId[uiPlanId];
    if (stripePlanId == null) {
      throw ArgumentError('No Stripe plan mapping for "$uiPlanId"');
    }

    final body = <String, dynamic>{
      'plan_id': stripePlanId,
      'billing_period': 'founding',
      'success_url': 'https://advocat.ee/payment-success',
      'cancel_url': 'https://advocat.ee/payment-cancel',
    };

    if (customerEmail != null && customerEmail.isNotEmpty) {
      body['customer_email'] = customerEmail;
    }

    final dynamic response;
    try {
      response = await Supabase.instance.client.functions.invoke(
        'create-checkout',
        body: body,
      );
    } catch (e) {
      throw Exception(
        'Network error calling checkout: $e. '
        'Please check your connection and try again.',
      );
    }

    if (response.status != 200) {
      final errorMsg = response.data is Map
          ? (response.data['error'] ?? 'Unknown error')
          : 'Edge function returned status ${response.status}';
      throw Exception('Failed to create checkout session: $errorMsg');
    }

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw Exception(
        'Unexpected response format from checkout: ${data.runtimeType}',
      );
    }
    final checkoutUrl = data['url'] as String?;

    if (checkoutUrl == null || checkoutUrl.isEmpty) {
      throw Exception('Checkout URL was empty');
    }

    final uri = Uri.parse(checkoutUrl);

    if (kIsWeb) {
      web_redirect.redirectToUrl(checkoutUrl);
    } else {
      await launchUrl(uri);
    }
    return true;
  }
}
