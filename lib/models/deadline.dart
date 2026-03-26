class Deadline {
  final String id;
  final String caseId;
  final String userId;
  final String title;
  final String? description;
  final DateTime dueDate;
  final DeadlineType type;
  final DeadlinePriority priority;
  final DeadlineStatus status;
  final bool notificationScheduled;
  final int reminderDaysBefore;
  final DeadlineSource source;
  final String? sourceDocumentId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Deadline({
    required this.id,
    required this.caseId,
    required this.userId,
    required this.title,
    this.description,
    required this.dueDate,
    this.type = DeadlineType.appeal,
    this.priority = DeadlinePriority.high,
    this.status = DeadlineStatus.upcoming,
    this.notificationScheduled = false,
    this.reminderDaysBefore = 7,
    this.source = DeadlineSource.manual,
    this.sourceDocumentId,
    required this.createdAt,
    this.updatedAt,
  });

  Deadline copyWith({
    String? id,
    String? caseId,
    String? userId,
    String? title,
    String? description,
    DateTime? dueDate,
    DeadlineType? type,
    DeadlinePriority? priority,
    DeadlineStatus? status,
    bool? notificationScheduled,
    int? reminderDaysBefore,
    DeadlineSource? source,
    String? sourceDocumentId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Deadline(
      id: id ?? this.id,
      caseId: caseId ?? this.caseId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      notificationScheduled: notificationScheduled ?? this.notificationScheduled,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      source: source ?? this.source,
      sourceDocumentId: sourceDocumentId ?? this.sourceDocumentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Deadline.fromJson(Map<String, dynamic> json) {
    return Deadline(
      id: json['id'] as String,
      caseId: json['case_id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: DateTime.parse(json['due_date'] as String),
      type: _typeFromJson(json['type'] as String?),
      priority: _priorityFromJson(json['priority'] as String?),
      status: _statusFromJson(json['status'] as String?),
      notificationScheduled: json['notification_scheduled'] as bool? ?? false,
      reminderDaysBefore: json['reminder_days_before'] as int? ?? 7,
      source: _sourceFromJson(json['source'] as String?),
      sourceDocumentId: json['source_document_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'case_id': caseId,
      'user_id': userId,
      'title': title,
      'description': description,
      'due_date': dueDate.toIso8601String(),
      'type': _typeToJson(type),
      'priority': _priorityToJson(priority),
      'status': _statusToJson(status),
      'notification_scheduled': notificationScheduled,
      'reminder_days_before': reminderDaysBefore,
      'source': _sourceToJson(source),
      'source_document_id': sourceDocumentId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static DeadlineType _typeFromJson(String? value) {
    switch (value) {
      case 'appeal': return DeadlineType.appeal;
      case 'hearing': return DeadlineType.hearing;
      case 'document_submission': return DeadlineType.documentSubmission;
      case 'response_required': return DeadlineType.responseRequired;
      case 'permit_expiry': return DeadlineType.permitExpiry;
      case 'court_date': return DeadlineType.courtDate;
      case 'other': return DeadlineType.other;
      default: return DeadlineType.appeal;
    }
  }

  static String _typeToJson(DeadlineType type) {
    switch (type) {
      case DeadlineType.appeal: return 'appeal';
      case DeadlineType.hearing: return 'hearing';
      case DeadlineType.documentSubmission: return 'document_submission';
      case DeadlineType.responseRequired: return 'response_required';
      case DeadlineType.permitExpiry: return 'permit_expiry';
      case DeadlineType.courtDate: return 'court_date';
      case DeadlineType.other: return 'other';
    }
  }

  static DeadlinePriority _priorityFromJson(String? value) {
    switch (value) {
      case 'critical': return DeadlinePriority.critical;
      case 'high': return DeadlinePriority.high;
      case 'medium': return DeadlinePriority.medium;
      case 'low': return DeadlinePriority.low;
      default: return DeadlinePriority.high;
    }
  }

  static String _priorityToJson(DeadlinePriority priority) {
    switch (priority) {
      case DeadlinePriority.critical: return 'critical';
      case DeadlinePriority.high: return 'high';
      case DeadlinePriority.medium: return 'medium';
      case DeadlinePriority.low: return 'low';
    }
  }

  static DeadlineStatus _statusFromJson(String? value) {
    switch (value) {
      case 'upcoming': return DeadlineStatus.upcoming;
      case 'overdue': return DeadlineStatus.overdue;
      case 'completed': return DeadlineStatus.completed;
      case 'cancelled': return DeadlineStatus.cancelled;
      default: return DeadlineStatus.upcoming;
    }
  }

  static String _statusToJson(DeadlineStatus status) {
    switch (status) {
      case DeadlineStatus.upcoming: return 'upcoming';
      case DeadlineStatus.overdue: return 'overdue';
      case DeadlineStatus.completed: return 'completed';
      case DeadlineStatus.cancelled: return 'cancelled';
    }
  }

  static DeadlineSource _sourceFromJson(String? value) {
    switch (value) {
      case 'ai_extracted': return DeadlineSource.aiExtracted;
      case 'email_extracted': return DeadlineSource.emailExtracted;
      default: return DeadlineSource.manual;
    }
  }

  static String _sourceToJson(DeadlineSource source) {
    switch (source) {
      case DeadlineSource.manual: return 'manual';
      case DeadlineSource.aiExtracted: return 'ai_extracted';
      case DeadlineSource.emailExtracted: return 'email_extracted';
    }
  }
}

enum DeadlineType {
  appeal,
  hearing,
  documentSubmission,
  responseRequired,
  permitExpiry,
  courtDate,
  other,
}

enum DeadlinePriority {
  critical,
  high,
  medium,
  low,
}

enum DeadlineStatus {
  upcoming,
  overdue,
  completed,
  cancelled,
}

enum DeadlineSource {
  manual,
  aiExtracted,
  emailExtracted,
}
