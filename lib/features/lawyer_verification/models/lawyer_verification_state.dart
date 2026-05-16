// lib/features/lawyer_verification/models/lawyer_verification_state.dart
// -----------------------------------------------------------------------------
// Plain-data model for the lawyer verification flow.
//
// Three orthogonal pieces:
//
//   1. LawyerVerificationApplication — what the user is about to POST.
//   2. LawyerVerificationOutcome    — what /verify-lawyer returned.
//   3. LawyerVerificationStatus     — what the profile row currently says
//                                     (for the Settings panel).
//
// All three are immutable; the screen rebuilds copies via copyWith.
// -----------------------------------------------------------------------------

/// Two-letter country code of the bar association.
enum LawyerBarCountry {
  /// Finland — Asianajajaliitto.
  fi('FI'),

  /// Estonia — Advokatuur.
  ee('EE');

  const LawyerBarCountry(this.code);
  final String code;

  static LawyerBarCountry? tryParse(String? raw) {
    if (raw == null) return null;
    final upper = raw.toUpperCase();
    for (final v in LawyerBarCountry.values) {
      if (v.code == upper) return v;
    }
    return null;
  }
}

/// Lifecycle of a lawyer-verification application. Mirrors
/// profiles.lawyer_verification_status server-side.
enum LawyerVerificationLifecycle {
  /// No application on file.
  none,

  /// Submitted; queued for manual review.
  pending,

  /// Auto-approved (verified now).
  autoApproved,

  /// Manually approved by the owner (verified now).
  manuallyApproved,

  /// Rejected at submission time (registry miss).
  rejected,

  /// Was verified, then revoked (e.g. removed from bar).
  revoked;

  /// True when the user currently enjoys premium_lawyer benefits.
  bool get isCurrentlyVerified =>
      this == LawyerVerificationLifecycle.autoApproved ||
      this == LawyerVerificationLifecycle.manuallyApproved;

  static LawyerVerificationLifecycle parse(String? raw) {
    switch (raw) {
      case 'pending':
        return LawyerVerificationLifecycle.pending;
      case 'auto_approved':
        return LawyerVerificationLifecycle.autoApproved;
      case 'manually_approved':
        return LawyerVerificationLifecycle.manuallyApproved;
      case 'rejected':
        return LawyerVerificationLifecycle.rejected;
      case 'revoked':
        return LawyerVerificationLifecycle.revoked;
      default:
        return LawyerVerificationLifecycle.none;
    }
  }
}

/// Form payload — what the user types on /lawyers.
class LawyerVerificationApplication {
  const LawyerVerificationApplication({
    this.country,
    this.barId = '',
    this.fullName = '',
    this.email = '',
    this.practiceUrl = '',
  });

  final LawyerBarCountry? country;
  final String barId;
  final String fullName;
  final String email;
  final String practiceUrl;

  /// True only when every required field is non-empty AND well-formed.
  /// The Edge Function does the authoritative validation, but a client
  /// gate avoids round-trips for obvious typos.
  bool get isComplete {
    if (country == null) return false;
    if (barId.trim().isEmpty || barId.length > 64) return false;
    if (fullName.trim().length < 2 || !fullName.contains(' ')) return false;
    if (!_looksLikeEmail(email)) return false;
    if (practiceUrl.isNotEmpty) {
      final lower = practiceUrl.toLowerCase();
      if (!(lower.startsWith('http://') || lower.startsWith('https://'))) {
        return false;
      }
      if (practiceUrl.length > 500) return false;
    }
    return true;
  }

  LawyerVerificationApplication copyWith({
    LawyerBarCountry? country,
    String? barId,
    String? fullName,
    String? email,
    String? practiceUrl,
  }) {
    return LawyerVerificationApplication(
      country: country ?? this.country,
      barId: barId ?? this.barId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      practiceUrl: practiceUrl ?? this.practiceUrl,
    );
  }

  /// Map to the JSON body expected by /verify-lawyer.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'country': country?.code,
        'bar_id': barId.trim(),
        'name': fullName.trim(),
        'email': email.trim().toLowerCase(),
        if (practiceUrl.trim().isNotEmpty) 'practice_url': practiceUrl.trim(),
      };

  static bool _looksLikeEmail(String s) {
    final t = s.trim();
    final at = t.indexOf('@');
    if (at <= 0 || at == t.length - 1) return false;
    final dot = t.indexOf('.', at);
    return dot > at && dot < t.length - 1;
  }
}

/// What /verify-lawyer returned.
sealed class LawyerVerificationOutcome {
  const LawyerVerificationOutcome();
}

/// Auto-approved: profile is already updated server-side.
final class LawyerVerificationApproved extends LawyerVerificationOutcome {
  const LawyerVerificationApproved({required this.verifiedAt});
  final DateTime verifiedAt;
}

/// Queued for manual review.
final class LawyerVerificationQueued extends LawyerVerificationOutcome {
  const LawyerVerificationQueued();
}

/// Registry miss / validation failure / 409 already-verified. The UI maps
/// the [reasonCode] to a localised message; the [statusCode] is for
/// telemetry.
final class LawyerVerificationRejected extends LawyerVerificationOutcome {
  const LawyerVerificationRejected({
    required this.reasonCode,
    this.statusCode,
    this.message,
  });
  final String reasonCode;
  final int? statusCode;
  final String? message;
}

/// Status pulled from profiles — drives the Settings panel and the
/// "you're already verified" gate on the /lawyers form.
class LawyerVerificationStatus {
  const LawyerVerificationStatus({
    required this.lifecycle,
    this.verifiedAt,
    this.barCountry,
    this.barId,
  });

  /// Convenience constant for not-yet-applied users.
  static const LawyerVerificationStatus none = LawyerVerificationStatus(
    lifecycle: LawyerVerificationLifecycle.none,
  );

  final LawyerVerificationLifecycle lifecycle;
  final DateTime? verifiedAt;
  final LawyerBarCountry? barCountry;
  final String? barId;

  bool get isVerified => lifecycle.isCurrentlyVerified;

  bool get hasOpenApplication =>
      lifecycle == LawyerVerificationLifecycle.pending;
}
