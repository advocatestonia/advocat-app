// lib/features/referral/models/referral_stats.dart
// -----------------------------------------------------------------------------
// Plain-data model returned by ReferralService.fetchStats().
//
// Mirrors the JSON shape from POST /referral/stats:
//   {
//     code: "abc12345",
//     share_url: "https://advocat.ee/r/abc12345",
//     invites_sent: 7,
//     conversions: 3,
//     free_months_earned: 3,
//     recent_activity: [
//       { invited_at: "...", converted_at: "...", status: "credited" },
//       ...
//     ]
//   }
//
// `recent_activity` is anonymised (no names, no emails) — the UI renders each
// row as "invited 3 days ago → activated 2 days ago". The backend is still
// rolling this out, so the field is optional and we fall back to an empty
// list when missing.
// -----------------------------------------------------------------------------

class ReferralStats {
  const ReferralStats({
    required this.code,
    required this.shareUrl,
    required this.invitesSent,
    required this.conversions,
    required this.freeMonthsEarned,
    this.recentActivity = const <ReferralActivity>[],
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

  /// Anonymised recent referral activity, newest first. May be empty —
  /// in which case the UI shows the empty-state copy.
  final List<ReferralActivity> recentActivity;

  bool get hasCode => code.isNotEmpty;

  bool get hasActivity => recentActivity.isNotEmpty;
}

/// One row in the anonymised "recent activity" list. Both timestamps are UTC.
/// `convertedAt` is null when the invitee hasn't activated a paid plan yet.
class ReferralActivity {
  const ReferralActivity({
    required this.invitedAt,
    this.convertedAt,
    this.status = 'attributed',
  });

  /// When the invitee signed up (referral_attributions.attributed_at).
  final DateTime invitedAt;

  /// When the invitee upgraded to paid, if at all
  /// (referral_attributions.converted_at).
  final DateTime? convertedAt;

  /// Server-side row status: `attributed` | `converted` | `credited` |
  /// `abuse_blocked`.
  final String status;

  bool get hasConverted => convertedAt != null;

  /// Parse one row from the backend `recent_activity` array. Tolerant —
  /// unknown shapes return null so a single bad row never sinks the screen.
  static ReferralActivity? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final invitedRaw = raw['invited_at'] ?? raw['attributed_at'];
    if (invitedRaw is! String || invitedRaw.isEmpty) return null;
    final invited = DateTime.tryParse(invitedRaw);
    if (invited == null) return null;
    final convertedRaw = raw['converted_at'];
    final converted = convertedRaw is String && convertedRaw.isNotEmpty
        ? DateTime.tryParse(convertedRaw)
        : null;
    final status = raw['status'] is String
        ? raw['status'] as String
        : 'attributed';
    return ReferralActivity(
      invitedAt: invited,
      convertedAt: converted,
      status: status,
    );
  }
}
