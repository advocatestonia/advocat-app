class LegalCase {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final CaseType type;
  final CaseStatus status;
  final String? migriReferenceNumber;
  final String? courtCaseNumber;
  final String? nationality;
  final DateTime? decisionDate;
  final DateTime? appealDeadline;
  final DateTime? hearingDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int documentCount;
  final int unreadMessages;

  const LegalCase({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.type = CaseType.deportation,
    this.status = CaseStatus.active,
    this.migriReferenceNumber,
    this.courtCaseNumber,
    this.nationality,
    this.decisionDate,
    this.appealDeadline,
    this.hearingDate,
    required this.createdAt,
    this.updatedAt,
    this.documentCount = 0,
    this.unreadMessages = 0,
  });

  LegalCase copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    CaseType? type,
    CaseStatus? status,
    String? migriReferenceNumber,
    String? courtCaseNumber,
    String? nationality,
    DateTime? decisionDate,
    DateTime? appealDeadline,
    DateTime? hearingDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? documentCount,
    int? unreadMessages,
  }) {
    return LegalCase(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      migriReferenceNumber: migriReferenceNumber ?? this.migriReferenceNumber,
      courtCaseNumber: courtCaseNumber ?? this.courtCaseNumber,
      nationality: nationality ?? this.nationality,
      decisionDate: decisionDate ?? this.decisionDate,
      appealDeadline: appealDeadline ?? this.appealDeadline,
      hearingDate: hearingDate ?? this.hearingDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      documentCount: documentCount ?? this.documentCount,
      unreadMessages: unreadMessages ?? this.unreadMessages,
    );
  }

  factory LegalCase.fromJson(Map<String, dynamic> json) {
    return LegalCase(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: _caseTypeFromJson(json['type'] as String?),
      status: _caseStatusFromJson(json['status'] as String?),
      migriReferenceNumber: json['migri_reference_number'] as String?,
      courtCaseNumber: json['court_case_number'] as String?,
      nationality: json['nationality'] as String?,
      decisionDate: json['decision_date'] != null
          ? DateTime.parse(json['decision_date'] as String)
          : null,
      appealDeadline: json['appeal_deadline'] != null
          ? DateTime.parse(json['appeal_deadline'] as String)
          : null,
      hearingDate: json['hearing_date'] != null
          ? DateTime.parse(json['hearing_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      documentCount: json['document_count'] as int? ?? 0,
      unreadMessages: json['unread_messages'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'type': _caseTypeToJson(type),
      'status': _caseStatusToJson(status),
      'migri_reference_number': migriReferenceNumber,
      'court_case_number': courtCaseNumber,
      'nationality': nationality,
      'decision_date': decisionDate?.toIso8601String(),
      'appeal_deadline': appealDeadline?.toIso8601String(),
      'hearing_date': hearingDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'document_count': documentCount,
      'unread_messages': unreadMessages,
    };
  }

  static CaseType _caseTypeFromJson(String? value) {
    switch (value) {
      case 'deportation': return CaseType.deportation;
      case 'asylum': return CaseType.asylum;
      case 'residence_permit': return CaseType.residencePermit;
      case 'family_reunification': return CaseType.familyReunification;
      case 'citizenship': return CaseType.citizenship;
      case 'work_permit': return CaseType.workPermit;
      case 'labor_dispute': return CaseType.laborDispute;
      case 'tenant_rights': return CaseType.tenantRights;
      case 'debt_collection': return CaseType.debtCollection;
      case 'discrimination': return CaseType.discrimination;
      case 'police_misconduct': return CaseType.policeMisconduct;
      case 'social_benefits': return CaseType.socialBenefits;
      case 'domestic_violence': return CaseType.domesticViolence;
      case 'consumer_protection': return CaseType.consumerProtection;
      case 'other': return CaseType.other;
      default: return CaseType.deportation;
    }
  }

  static String _caseTypeToJson(CaseType type) {
    switch (type) {
      case CaseType.deportation: return 'deportation';
      case CaseType.asylum: return 'asylum';
      case CaseType.residencePermit: return 'residence_permit';
      case CaseType.familyReunification: return 'family_reunification';
      case CaseType.citizenship: return 'citizenship';
      case CaseType.workPermit: return 'work_permit';
      case CaseType.laborDispute: return 'labor_dispute';
      case CaseType.tenantRights: return 'tenant_rights';
      case CaseType.debtCollection: return 'debt_collection';
      case CaseType.discrimination: return 'discrimination';
      case CaseType.policeMisconduct: return 'police_misconduct';
      case CaseType.socialBenefits: return 'social_benefits';
      case CaseType.domesticViolence: return 'domestic_violence';
      case CaseType.consumerProtection: return 'consumer_protection';
      case CaseType.other: return 'other';
    }
  }

  static CaseStatus _caseStatusFromJson(String? value) {
    switch (value) {
      case 'active': return CaseStatus.active;
      case 'pending_decision': return CaseStatus.pendingDecision;
      case 'appeal_filed': return CaseStatus.appealFiled;
      case 'in_court': return CaseStatus.inCourt;
      case 'resolved': return CaseStatus.resolved;
      case 'closed': return CaseStatus.closed;
      default: return CaseStatus.active;
    }
  }

  static String _caseStatusToJson(CaseStatus status) {
    switch (status) {
      case CaseStatus.active: return 'active';
      case CaseStatus.pendingDecision: return 'pending_decision';
      case CaseStatus.appealFiled: return 'appeal_filed';
      case CaseStatus.inCourt: return 'in_court';
      case CaseStatus.resolved: return 'resolved';
      case CaseStatus.closed: return 'closed';
    }
  }
}

enum CaseType {
  deportation,
  asylum,
  residencePermit,
  familyReunification,
  citizenship,
  workPermit,
  laborDispute,
  tenantRights,
  debtCollection,
  discrimination,
  policeMisconduct,
  socialBenefits,
  domesticViolence,
  consumerProtection,
  other,
}

enum CaseStatus {
  active,
  pendingDecision,
  appealFiled,
  inCourt,
  resolved,
  closed,
}
