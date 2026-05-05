// =====================================================================
// CaseDocument — client-side model for `public.case_documents` rows.
//
// IMPORTANT: parsed_text and embedding are intentionally OMITTED.
//   * parsed_text can be megabytes per doc — the list view never needs
//     it. PDF parsing (Pkg 2) writes it server-side; chat (Pkg 1.B)
//     fetches it selectively via top-K similarity.
//   * embedding is a 1536-d vector — useless on the client and would
//     waste bandwidth.
// The `load_active_case` RPC strips both fields by contract; this model
// is also defensive — even if the server forgets to strip, fromJson
// silently drops them.
// =====================================================================

import 'package:flutter/foundation.dart';

@immutable
class CaseDocument {
  const CaseDocument({
    required this.id,
    required this.caseId,
    required this.userId,
    required this.filename,
    required this.storagePath,
    this.mimeType,
    this.sizeBytes,
    this.docType,
    this.docDate,
    this.parsedSummary,
    this.keyExtractions,
    required this.uploadedAt,
  });

  final String id;
  final String caseId;
  final String userId;
  final String filename;
  final String storagePath;
  final String? mimeType;
  final int? sizeBytes;
  final String? docType;
  final DateTime? docDate;
  final String? parsedSummary;
  final Map<String, dynamic>? keyExtractions;
  final DateTime uploadedAt;

  factory CaseDocument.fromJson(Map<String, dynamic> json) {
    final docDateRaw = json['doc_date'];
    DateTime? docDate;
    if (docDateRaw is String && docDateRaw.isNotEmpty) {
      // PostgREST returns DATE as 'yyyy-MM-dd'. We parse to UTC midnight
      // explicitly — `DateTime.parse('2025-09-01')` returns LOCAL midnight,
      // and `.toUtc()` then shifts the calendar day in non-UTC timezones
      // (a Tallinn box would render '2025-08-31'). Pure dates have no
      // timezone — pin to UTC midnight to keep the calendar intact.
      final parts = docDateRaw.split('-');
      if (parts.length == 3) {
        docDate = DateTime.utc(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      } else {
        docDate = DateTime.parse(docDateRaw);
      }
    }

    final extracted = json['key_extractions'];

    return CaseDocument(
      id: json['id'] as String,
      caseId: json['case_id'] as String,
      userId: json['user_id'] as String,
      filename: json['filename'] as String,
      storagePath: json['storage_path'] as String,
      mimeType: json['mime_type'] as String?,
      sizeBytes: (json['size_bytes'] as num?)?.toInt(),
      docType: json['doc_type'] as String?,
      docDate: docDate,
      parsedSummary: json['parsed_summary'] as String?,
      keyExtractions:
          extracted is Map ? Map<String, dynamic>.from(extracted) : null,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
      // parsed_text and embedding are deliberately not read.
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'case_id': caseId,
        'user_id': userId,
        'filename': filename,
        'storage_path': storagePath,
        'mime_type': mimeType,
        'size_bytes': sizeBytes,
        'doc_type': docType,
        'doc_date': docDate == null
            ? null
            : '${docDate!.year.toString().padLeft(4, '0')}-'
                '${docDate!.month.toString().padLeft(2, '0')}-'
                '${docDate!.day.toString().padLeft(2, '0')}',
        'parsed_summary': parsedSummary,
        'key_extractions': keyExtractions,
        'uploaded_at': uploadedAt.toIso8601String(),
        // parsed_text and embedding NEVER serialized.
      };
}
