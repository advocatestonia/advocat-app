// calc_rates_provider.dart — fetches versioned rates with offline fallback.
// -----------------------------------------------------------------------------
// Calls the `calc-rates` edge function for the requested jurisdiction. On ANY
// failure (network, demo mode, malformed payload) it returns the baked-in
// `kFallbackRates` bundle so the calculators always have numbers to work with.
// The `fromNetwork` flag lets the UI show whether figures are live or cached.
// -----------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';
import 'calc_rates.dart';

/// Resolved rates for a jurisdiction ('FI' / 'EE'). Never throws — falls back
/// to baked-in defaults on error.
final calcRatesProvider =
    FutureProvider.family<CalcRates, String>((ref, jurisdiction) async {
  final fallback = fallbackFor(jurisdiction);
  final supabase = ref.watch(supabaseServiceProvider);
  try {
    final res = await supabase.callEdgeFunction(
      'calc-rates',
      body: {'jurisdiction': jurisdiction.toUpperCase()},
    );
    if (res == null || res['error'] != null || res['rates'] == null) {
      return fallback;
    }
    return CalcRates.fromEdge(res, fallback);
  } catch (_) {
    return fallback;
  }
});
