/// Reporting period for the usage stats screen.
enum UsagePeriod {
  currentMonth('current_month', 'Current month'),
  last30Days('last_30_days', 'Last 30 days'),
  currentYear('current_year', 'Current year'),
  custom('custom', 'Custom range');

  const UsagePeriod(this.wire, this.label);
  final String wire;
  final String label;
}

/// A single (date, value) sample for a daily-activity chart.
class UsageDataPoint {
  const UsageDataPoint({required this.date, required this.value});
  final DateTime date;
  final double value;

  factory UsageDataPoint.fromJson(Map<String, dynamic> json) {
    return UsageDataPoint(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      value: (json['value'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Per-member volume aggregate (used by the bar-chart drill-down).
class MemberUsage {
  const MemberUsage({
    required this.userId,
    required this.displayName,
    required this.messages,
    required this.documents,
    required this.cases,
  });
  final String userId;
  final String displayName;
  final int messages;
  final int documents;
  final int cases;

  factory MemberUsage.fromJson(Map<String, dynamic> json) {
    return MemberUsage(
      userId: json['user_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? json['email'] as String? ?? 'User',
      messages: (json['messages'] as num?)?.toInt() ?? 0,
      documents: (json['documents'] as num?)?.toInt() ?? 0,
      cases: (json['cases'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Aggregated org-wide usage for a single period.
///
/// Backed by the `org-usage-stats` edge function, which queries
/// `org_usage_counters` + per-day rollups.
class UsageStats {
  const UsageStats({
    required this.period,
    required this.periodStart,
    required this.periodEnd,
    required this.messagesSent,
    required this.documentsUploaded,
    required this.casesCreated,
    required this.apiCalls,
    required this.messagesDelta,
    required this.documentsDelta,
    required this.casesDelta,
    required this.apiDelta,
    required this.dailyActivity,
    required this.perMember,
    required this.apiCallsByDay,
  });

  final UsagePeriod period;
  final DateTime periodStart;
  final DateTime periodEnd;

  final int messagesSent;
  final int documentsUploaded;
  final int casesCreated;
  final int apiCalls;

  /// Percent delta vs prior equivalent period (e.g. +0.12 = +12%).
  final double messagesDelta;
  final double documentsDelta;
  final double casesDelta;
  final double apiDelta;

  final List<UsageDataPoint> dailyActivity;
  final List<MemberUsage> perMember;
  final List<UsageDataPoint> apiCallsByDay;

  factory UsageStats.empty(UsagePeriod period) => UsageStats(
        period: period,
        periodStart: DateTime.now(),
        periodEnd: DateTime.now(),
        messagesSent: 0,
        documentsUploaded: 0,
        casesCreated: 0,
        apiCalls: 0,
        messagesDelta: 0,
        documentsDelta: 0,
        casesDelta: 0,
        apiDelta: 0,
        dailyActivity: const [],
        perMember: const [],
        apiCallsByDay: const [],
      );

  factory UsageStats.fromJson(Map<String, dynamic> json, UsagePeriod period) {
    List<T> _list<T>(dynamic v, T Function(Map<String, dynamic>) f) {
      if (v is! List) return <T>[];
      return v
          .whereType<Map<String, dynamic>>()
          .map(f)
          .toList(growable: false);
    }

    return UsageStats(
      period: period,
      periodStart:
          DateTime.tryParse(json['period_start'] as String? ?? '') ?? DateTime.now(),
      periodEnd:
          DateTime.tryParse(json['period_end'] as String? ?? '') ?? DateTime.now(),
      messagesSent: (json['messages_sent'] as num?)?.toInt() ?? 0,
      documentsUploaded: (json['documents_uploaded'] as num?)?.toInt() ?? 0,
      casesCreated: (json['cases_created'] as num?)?.toInt() ?? 0,
      apiCalls: (json['api_calls'] as num?)?.toInt() ?? 0,
      messagesDelta: (json['messages_delta'] as num?)?.toDouble() ?? 0,
      documentsDelta: (json['documents_delta'] as num?)?.toDouble() ?? 0,
      casesDelta: (json['cases_delta'] as num?)?.toDouble() ?? 0,
      apiDelta: (json['api_delta'] as num?)?.toDouble() ?? 0,
      dailyActivity: _list(json['daily_activity'], UsageDataPoint.fromJson),
      perMember: _list(json['per_member'], MemberUsage.fromJson),
      apiCallsByDay: _list(json['api_calls_by_day'], UsageDataPoint.fromJson),
    );
  }
}
