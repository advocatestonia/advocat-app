// lib/features/lawyer_partnership/models/lawyer_partnership_state.dart
// -----------------------------------------------------------------------------
// Plain-data models for the lawyer-partnership feature (Day2-E).
//
// Five pieces:
//
//   * BookingTopic                — fixed set of bucketed topics for the
//                                   booking form. "other" accepts free-form
//                                   user-typed text.
//   * BookingRequest              — what the user is about to POST when
//                                   creating a booking.
//   * LawyerBooking               — server-returned booking row.
//   * BookingStatus               — lifecycle state mirror of the DB column.
//   * PartnerLawyerProfile        — anonymised directory card.
//
// All types are immutable; the screens rebuild copies via copyWith.
// -----------------------------------------------------------------------------

/// Fixed set of bucketed topics the booking screen offers. Anything the
/// user types that doesn't match is sent as the canonical string itself
/// (i.e. `BookingTopic.other` is the catch-all bucket with a free-text
/// override field; the server keeps the free-form string verbatim).
enum BookingTopic {
  immigration('immigration'),
  contract('contract'),
  family('family'),
  employment('employment'),
  tenancy('tenancy'),
  criminal('criminal'),
  civil('civil'),
  tax('tax'),
  consumer('consumer'),
  other('other');

  const BookingTopic(this.token);
  final String token;

  static BookingTopic? tryParse(String? raw) {
    if (raw == null) return null;
    final lower = raw.toLowerCase();
    for (final v in BookingTopic.values) {
      if (v.token == lower) return v;
    }
    return null;
  }

  /// Short user-facing label. The screen overrides this with localised
  /// copy when ARB integration ships in the next batch.
  String get label {
    switch (this) {
      case BookingTopic.immigration:
        return 'Immigration';
      case BookingTopic.contract:
        return 'Contract';
      case BookingTopic.family:
        return 'Family';
      case BookingTopic.employment:
        return 'Employment';
      case BookingTopic.tenancy:
        return 'Tenancy';
      case BookingTopic.criminal:
        return 'Criminal';
      case BookingTopic.civil:
        return 'Civil';
      case BookingTopic.tax:
        return 'Tax';
      case BookingTopic.consumer:
        return 'Consumer';
      case BookingTopic.other:
        return 'Other';
    }
  }
}

/// Lifecycle of a booking. Mirrors `lawyer_bookings.status` server-side.
enum BookingStatus {
  /// User submitted — no lawyer assigned yet, no slot locked.
  requested,

  /// A lawyer has been assigned but the slot is not yet confirmed.
  assigned,

  /// Slot + lawyer locked. AI brief generation queued.
  confirmed,

  /// Call happened. Lawyer filled the outcome form.
  completed,

  /// Either side cancelled before the call.
  cancelled,

  /// User did not show up.
  noShow;

  static BookingStatus parse(String? raw) {
    switch (raw) {
      case 'requested':
        return BookingStatus.requested;
      case 'assigned':
        return BookingStatus.assigned;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'no_show':
        return BookingStatus.noShow;
      default:
        return BookingStatus.requested;
    }
  }

  bool get isFinal =>
      this == BookingStatus.completed ||
      this == BookingStatus.cancelled ||
      this == BookingStatus.noShow;

  bool get isUpcoming =>
      this == BookingStatus.requested ||
      this == BookingStatus.assigned ||
      this == BookingStatus.confirmed;
}

/// Form payload — what the user is about to POST to /lawyer-booking.
class BookingRequest {
  const BookingRequest({
    this.topic,
    this.freeFormTopic = '',
    this.language = 'et',
    this.lawyerId,
    this.caseId,
    this.scheduledAt,
    this.timePreference = '',
    this.userBrief = '',
  });

  final BookingTopic? topic;

  /// Filled when [topic] == `BookingTopic.other`. Server-side validator
  /// caps at 100 chars.
  final String freeFormTopic;

  final String language;
  final String? lawyerId;
  final String? caseId;
  final DateTime? scheduledAt;

  /// Free-text "weekday mornings" hint when no specific slot is picked.
  final String timePreference;

  /// What the user wants covered on the call. Capped at 4000 chars.
  final String userBrief;

  /// Client-side gate. The Edge Function does authoritative validation.
  bool get isComplete {
    if (topic == null) return false;
    if (topic == BookingTopic.other && freeFormTopic.trim().length < 3) {
      return false;
    }
    if (language.length != 2) return false;
    // Either a slot OR a time preference must be present so the lawyer
    // knows when to expect the call.
    if (scheduledAt == null && timePreference.trim().isEmpty) return false;
    if (userBrief.length > 4000) return false;
    if (timePreference.length > 200) return false;
    return true;
  }

  BookingRequest copyWith({
    BookingTopic? topic,
    String? freeFormTopic,
    String? language,
    String? lawyerId,
    String? caseId,
    DateTime? scheduledAt,
    String? timePreference,
    String? userBrief,
  }) {
    return BookingRequest(
      topic: topic ?? this.topic,
      freeFormTopic: freeFormTopic ?? this.freeFormTopic,
      language: language ?? this.language,
      lawyerId: lawyerId ?? this.lawyerId,
      caseId: caseId ?? this.caseId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      timePreference: timePreference ?? this.timePreference,
      userBrief: userBrief ?? this.userBrief,
    );
  }

  Map<String, dynamic> toJson() {
    final t = topic;
    final topicStr = (t == null || t == BookingTopic.other)
        ? freeFormTopic.trim()
        : t.token;
    return <String, dynamic>{
      'op': 'create',
      'topic': topicStr,
      'language': language,
      if (lawyerId != null && lawyerId!.isNotEmpty) 'lawyer_id': lawyerId,
      if (caseId != null && caseId!.isNotEmpty) 'case_id': caseId,
      if (scheduledAt != null)
        'scheduled_at': scheduledAt!.toUtc().toIso8601String(),
      if (timePreference.trim().isNotEmpty)
        'time_preference': timePreference.trim(),
      if (userBrief.trim().isNotEmpty) 'user_brief': userBrief.trim(),
    };
  }
}

/// Server-returned booking row.
class LawyerBooking {
  const LawyerBooking({
    required this.id,
    required this.userId,
    this.lawyerId,
    required this.topic,
    this.caseId,
    required this.language,
    this.userBrief,
    this.scheduledAt,
    required this.durationMinutes,
    this.meetLink,
    this.aiBriefMd,
    this.aiBriefAt,
    this.outcomeSummary,
    this.outcomeAt,
    this.userRating,
    this.userFeedback,
    required this.status,
    required this.quotaQuarter,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String? lawyerId;
  final String topic;
  final String? caseId;
  final String language;
  final String? userBrief;
  final DateTime? scheduledAt;
  final int durationMinutes;
  final String? meetLink;
  final String? aiBriefMd;
  final DateTime? aiBriefAt;
  final String? outcomeSummary;
  final DateTime? outcomeAt;
  final int? userRating;
  final String? userFeedback;
  final BookingStatus status;
  final String quotaQuarter;
  final DateTime createdAt;

  static LawyerBooking fromJson(Map<String, dynamic> j) {
    DateTime? parseTs(dynamic v) {
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      return null;
    }

    return LawyerBooking(
      id: j['id'] as String,
      userId: j['user_id'] as String,
      lawyerId: j['lawyer_id'] as String?,
      topic: j['topic'] as String? ?? 'other',
      caseId: j['case_id'] as String?,
      language: j['language'] as String? ?? 'et',
      userBrief: j['user_brief'] as String?,
      scheduledAt: parseTs(j['scheduled_at']),
      durationMinutes: (j['duration_minutes'] as num?)?.toInt() ?? 15,
      meetLink: j['meet_link'] as String?,
      aiBriefMd: j['ai_brief_md'] as String?,
      aiBriefAt: parseTs(j['ai_brief_at']),
      outcomeSummary: j['outcome_summary'] as String?,
      outcomeAt: parseTs(j['outcome_at']),
      userRating: (j['user_rating'] as num?)?.toInt(),
      userFeedback: j['user_feedback'] as String?,
      status: BookingStatus.parse(j['status'] as String?),
      quotaQuarter: j['quota_quarter'] as String? ?? _nowQuarter(),
      createdAt: parseTs(j['created_at']) ?? DateTime.now().toUtc(),
    );
  }

  static String _nowQuarter() {
    final n = DateTime.now().toUtc();
    final q = ((n.month - 1) ~/ 3) + 1;
    return '${n.year}-Q$q';
  }
}

/// Sealed result of POST /lawyer-booking (op=create).
sealed class BookingOutcome {
  const BookingOutcome();
}

final class BookingCreated extends BookingOutcome {
  const BookingCreated({required this.booking, required this.quotaRemaining});
  final LawyerBooking booking;
  final int quotaRemaining;
}

final class BookingRejected extends BookingOutcome {
  const BookingRejected({
    required this.reasonCode,
    this.statusCode,
    this.message,
  });
  final String reasonCode;
  final int? statusCode;
  final String? message;
}

/// Anonymised partner-lawyer directory card.
class PartnerLawyerProfile {
  const PartnerLawyerProfile({
    required this.lawyerId,
    required this.publicBlurb,
    required this.country,
    required this.specialties,
    required this.languages,
    this.avgRating,
    this.bookingsCompleted = 0,
  });

  final String lawyerId;
  final String publicBlurb;
  final String country;
  final List<String> specialties;
  final List<String> languages;
  final double? avgRating;
  final int bookingsCompleted;

  static PartnerLawyerProfile fromJson(Map<String, dynamic> j) {
    return PartnerLawyerProfile(
      lawyerId: j['lawyer_id'] as String,
      publicBlurb: j['public_blurb'] as String? ?? '',
      country: j['country'] as String? ?? 'EE',
      specialties: (j['specialties'] as List?)?.cast<String>() ?? const [],
      languages: (j['languages'] as List?)?.cast<String>() ?? const ['et'],
      avgRating: (j['avg_rating'] as num?)?.toDouble(),
      bookingsCompleted:
          (j['bookings_completed'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Quota snapshot for the booking screen header.
class BookingQuota {
  const BookingQuota({
    required this.quotaTotal,
    required this.quotaUsed,
    required this.quarter,
  });

  final int quotaTotal;
  final int quotaUsed;
  final String quarter;

  int get remaining => (quotaTotal - quotaUsed).clamp(0, quotaTotal);
  bool get canBook => remaining > 0;
}
