// lib/features/referral/models/referral_stats.dart
// -----------------------------------------------------------------------------
// Plain-data model returned by ReferralService.fetchStats().
// -----------------------------------------------------------------------------

class ReferralStats {
  const ReferralStats({
    required this.code,
    required this.shareUrl,
    required this.invitesSent,
    required this.conversions,
    required this.freeMonthsEarned,
  });

  /// 8-char alphanumeric code; empty string if the user has not yet
  /// generated one.
  final String code;

  /// Full share URL (`https://advocat.ee/r/<code>`); empty when no code.
  final String shareUrl;

  /// People who signed up using this user's code.
  final int invitesSent;

  /// Subset of [invitesSent] who reached a paid plan.
  final int conversions;

  /// Number of free months credited to this user as a result.
  final int freeMonthsEarned;

  bool get hasCode => code.isNotEmpty;
}
