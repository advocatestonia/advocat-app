// lib/features/referral/state/referral_providers.dart
// -----------------------------------------------------------------------------
// Riverpod providers that back the Referral screen.
//
//   referralStatsProvider — async stats (code, share_url, invites_sent,
//                           conversions, free_months_earned). Refreshed on
//                           pull-to-refresh.
//   referralCodeProvider  — bare code as a separate AsyncValue so the
//                           header copy/share buttons can render before
//                           stats finish loading.
//
// Both providers delegate to ReferralService and are auto-disposed when
// the screen leaves the tree.
// -----------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/referral_service.dart';
import '../models/referral_stats.dart';

final referralCodeProvider = FutureProvider.autoDispose<String>((ref) async {
  return ref.read(referralServiceProvider).fetchCode();
});

final referralStatsProvider =
    FutureProvider.autoDispose<ReferralStats>((ref) async {
  return ref.read(referralServiceProvider).fetchStats();
});
