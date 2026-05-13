// =============================================================================
// contract_review_quota_service.dart
// =============================================================================
//
// Client-side reader for the Contract Review quota row in `public.user_quotas`.
// The authoritative gate is server-side (see contract-review/handler.ts —
// returns 402 when exceeded). This service exists ONLY to drive UI: showing
// "X reviews left this month" pill near the upload button, and selecting
// which CTA the upgrade dialog should highlight.
//
// Contract with the server:
//   - Free tier      : 1 lifetime review, NEVER rolls.
//   - Counsel (basic): 5 per 30-day window, rolls on expiry.
//   - Pro (premium)  : 20 per 30-day window, rolls on expiry.
//
// Memory: reference_pitfalls_chat_infra — RLS policy "own quota row" lets
// the authenticated user select their own row directly; no edge fn needed.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/user.dart';
import '../../auth/providers/auth_provider.dart';

/// Snapshot of a user's Contract Review quota.
///
/// `remaining` is the canonical UI input — pill text derives from it.
/// `tier` decides which upgrade CTA the dialog highlights.
class ContractReviewQuota {
  /// Lifetime cap for free tier.
  static const int freeLimit = 1;

  /// 30-day rolling cap for Counsel/basic tier.
  static const int counselLimit = 5;

  /// 30-day rolling cap for Pro/premium tier.
  static const int proLimit = 20;

  /// Hard wall: free counter never rolls. Counsel/Pro roll every 30 days.
  static const Duration windowDuration = Duration(days: 30);

  /// The user's current tier.
  final SubscriptionTier tier;

  /// How many reviews the user has used in the current window. For free
  /// this is the lifetime counter and never resets.
  final int used;

  /// The timestamp of the current 30-day window's start. For free this is
  /// the moment the trial was consumed (or now() if not yet used).
  final DateTime periodStart;

  const ContractReviewQuota({
    required this.tier,
    required this.used,
    required this.periodStart,
  });

  /// The quota cap for [tier].
  int get limit {
    switch (tier) {
      case SubscriptionTier.free:
        return freeLimit;
      case SubscriptionTier.basic:
        return counselLimit;
      case SubscriptionTier.premium:
        return proLimit;
    }
  }

  /// Whether the 30-day window has expired and would roll on next use.
  /// Always false for the free tier (lifetime cap, never rolls).
  bool windowExpired({DateTime? now}) {
    if (tier == SubscriptionTier.free) return false;
    final n = now ?? DateTime.now();
    return n.difference(periodStart) > windowDuration;
  }

  /// How many reviews the user has left in the current window. Free with
  /// 1 used returns 0 (permanently). Counsel/Pro returns full limit if
  /// the window has expired (server will roll on next call).
  int remaining({DateTime? now}) {
    if (windowExpired(now: now)) return limit;
    final r = limit - used;
    return r < 0 ? 0 : r;
  }

  /// Whether the user can run at least one more review without paying.
  bool get hasAny => remaining() > 0;

  /// True when remaining <= 1 AND the user has already consumed some of
  /// their quota (yellow-warning state in the pill). Free tier — whose
  /// limit is 1 — never enters near-limit: with 1 used it's exhausted,
  /// with 0 used the pill stays in the neutral "trial available" state.
  bool get isNearLimit {
    final r = remaining();
    if (r <= 0) return false;
    if (r > 1) return false;
    // Require visible consumption so a fresh paid user with 5/5 doesn't
    // see a yellow warning on day one.
    return used > 0;
  }

  /// True when remaining == 0 (red, inline upgrade CTA).
  bool get isExhausted => remaining() == 0;

  /// Initial state for a fresh user with no DB row yet.
  factory ContractReviewQuota.empty(SubscriptionTier tier) =>
      ContractReviewQuota(
        tier: tier,
        used: 0,
        periodStart: DateTime.now(),
      );
}

/// Riverpod provider exposing the current user's Contract Review quota.
///
/// Watches [currentUserProvider] for the tier and reads the
/// `public.user_quotas` row keyed by the authenticated user id. RLS
/// ensures the user can only read their own row. Returns the "empty"
/// snapshot if the row does not yet exist.
final contractReviewQuotaProvider =
    FutureProvider.autoDispose<ContractReviewQuota>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    return ContractReviewQuota.empty(SubscriptionTier.free);
  }
  final supabase = Supabase.instance.client;
  final res = await supabase
      .from('user_quotas')
      .select('contract_reviews_used, contract_reviews_period_start')
      .eq('user_id', user.id)
      .maybeSingle();
  if (res == null) {
    return ContractReviewQuota.empty(user.subscriptionTier);
  }
  final used = (res['contract_reviews_used'] as num?)?.toInt() ?? 0;
  final periodStartRaw = res['contract_reviews_period_start'] as String?;
  final periodStart = periodStartRaw != null
      ? DateTime.tryParse(periodStartRaw) ?? DateTime.now()
      : DateTime.now();
  return ContractReviewQuota(
    tier: user.subscriptionTier,
    used: used,
    periodStart: periodStart,
  );
});
