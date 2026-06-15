// renewable_document.dart — model for the Permit/Document Renewal Radar.
// -----------------------------------------------------------------------------
// One personal document the user wants the radar to watch for expiry. Maps to
// the public.renewable_documents table (migration 202606110000000_renewals.sql).
// Pure data + derived helpers; no Flutter/Supabase imports so it is trivially
// unit-testable.
// -----------------------------------------------------------------------------

/// Kind of renewable document. String values match the Postgres
/// `renewable_doc_type` enum exactly.
enum RenewableDocType {
  residencePermit('residence_permit'),
  passport('passport'),
  idCard('id_card'),
  visa('visa'),
  drivingLicence('driving_licence'),
  insurance('insurance'),
  workPermit('work_permit'),
  other('other');

  const RenewableDocType(this.wire);

  /// The string stored in the database.
  final String wire;

  static RenewableDocType fromWire(String? value) {
    for (final t in RenewableDocType.values) {
      if (t.wire == value) return t;
    }
    return RenewableDocType.other;
  }

  /// Document types that benefit from a "how to renew" guide + doc-collection
  /// link (residence/work permits + visa — the immigration-heavy ones).
  bool get hasRenewalGuide =>
      this == RenewableDocType.residencePermit ||
      this == RenewableDocType.workPermit ||
      this == RenewableDocType.visa;
}

/// Urgency band derived purely from days-to-expiry, mirroring the 90/30/7
/// reminder windows so the UI colour matches the next reminder that will fire.
enum RenewalUrgency { expired, critical, soon, upcoming, distant }

class RenewableDocument {
  const RenewableDocument({
    required this.id,
    required this.docType,
    required this.label,
    this.docNumber,
    this.jurisdiction,
    required this.expiresOn,
    this.remindersSent = const [],
    this.notificationsEnabled = true,
    this.notes,
    this.createdAt,
  });

  final String id;
  final RenewableDocType docType;
  final String label;
  final String? docNumber;

  /// ISO-3166 alpha-2 issuing jurisdiction, e.g. 'FI', 'EE'.
  final String? jurisdiction;

  /// Date-only (time component ignored). The anchor for all reminder windows.
  final DateTime expiresOn;

  /// Windows already dispatched: subset of {'90','30','7'}.
  final List<String> remindersSent;
  final bool notificationsEnabled;
  final String? notes;
  final DateTime? createdAt;

  /// Whole days until expiry, computed at date granularity (today = 0,
  /// past = negative). [now] is injectable for testing.
  int daysUntilExpiry([DateTime? now]) {
    final ref = now ?? DateTime.now();
    final today = DateTime.utc(ref.year, ref.month, ref.day);
    final exp = DateTime.utc(expiresOn.year, expiresOn.month, expiresOn.day);
    return exp.difference(today).inDays;
  }

  /// Urgency band for colour/sort, aligned to the 90/30/7 windows.
  RenewalUrgency urgency([DateTime? now]) {
    final d = daysUntilExpiry(now);
    if (d < 0) return RenewalUrgency.expired;
    if (d <= 7) return RenewalUrgency.critical;
    if (d <= 30) return RenewalUrgency.soon;
    if (d <= 90) return RenewalUrgency.upcoming;
    return RenewalUrgency.distant;
  }

  factory RenewableDocument.fromJson(Map<String, dynamic> json) {
    final reminders = json['reminders_sent'];
    return RenewableDocument(
      id: json['id'] as String,
      docType: RenewableDocType.fromWire(json['doc_type'] as String?),
      label: (json['label'] as String?) ?? '',
      docNumber: json['doc_number'] as String?,
      jurisdiction: json['jurisdiction'] as String?,
      expiresOn: DateTime.parse(json['expires_on'] as String),
      remindersSent: reminders is List
          ? reminders.map((e) => e.toString()).toList()
          : const [],
      notificationsEnabled: (json['notifications_enabled'] as bool?) ?? true,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  /// Insert/update payload. `expires_on` is sent date-only (YYYY-MM-DD) so the
  /// Postgres `date` column never picks up a timezone shift.
  Map<String, dynamic> toInsert() => {
        'doc_type': docType.wire,
        'label': label,
        if (docNumber != null && docNumber!.isNotEmpty) 'doc_number': docNumber,
        if (jurisdiction != null && jurisdiction!.isNotEmpty)
          'jurisdiction': jurisdiction,
        'expires_on': dateOnly(expiresOn),
        'notifications_enabled': notificationsEnabled,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };

  /// Format a [DateTime] as a date-only 'YYYY-MM-DD' string (timezone-safe).
  static String dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
