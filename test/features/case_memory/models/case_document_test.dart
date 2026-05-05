import 'package:advocat/features/case_memory/models/case_document.dart';
import 'package:flutter_test/flutter_test.dart';

/// Round-trip JSON for [CaseDocument].
///
/// The model deliberately omits `parsed_text` and `embedding` — those
/// stay server-side. The list view never needs them, and shipping a
/// 1536-d vector to the client is wasted bandwidth (per migration
/// load_active_case RPC contract).
void main() {
  group('CaseDocument round-trip', () {
    test('decodes a minimal Supabase row (no parsed_text/embedding)', () {
      final row = {
        'id': '33333333-3333-3333-3333-333333333333',
        'case_id': '11111111-1111-1111-1111-111111111111',
        'user_id': '22222222-2222-2222-2222-222222222222',
        'filename': 'epicrisis.pdf',
        'storage_path': 'user-002/case-001/epicrisis.pdf',
        'mime_type': 'application/pdf',
        'size_bytes': 2048,
        'doc_type': 'medical',
        'doc_date': '2025-09-01',
        'parsed_summary': 'F43.1 PTSD diagnosis, CAPS=108',
        'key_extractions': {
          'doc_type': 'medical',
          'diagnoses': ['F43.1'],
          'caps_score': 108,
        },
        'uploaded_at': '2026-05-05T12:00:00Z',
      };

      final d = CaseDocument.fromJson(row);

      expect(d.id, '33333333-3333-3333-3333-333333333333');
      expect(d.caseId, '11111111-1111-1111-1111-111111111111');
      expect(d.userId, '22222222-2222-2222-2222-222222222222');
      expect(d.filename, 'epicrisis.pdf');
      expect(d.storagePath, 'user-002/case-001/epicrisis.pdf');
      expect(d.mimeType, 'application/pdf');
      expect(d.sizeBytes, 2048);
      expect(d.docType, 'medical');
      expect(d.docDate, DateTime.utc(2025, 9, 1));
      expect(d.parsedSummary, 'F43.1 PTSD diagnosis, CAPS=108');
      expect(d.keyExtractions, isNotNull);
      expect(d.keyExtractions!['caps_score'], 108);
    });

    test('ignores parsed_text and embedding fields if server includes them',
        () {
      // load_active_case RPC strips these, but be defensive.
      final row = {
        'id': '33333333-3333-3333-3333-333333333333',
        'case_id': '11111111-1111-1111-1111-111111111111',
        'user_id': '22222222-2222-2222-2222-222222222222',
        'filename': 'doc.pdf',
        'storage_path': 'p',
        'mime_type': 'application/pdf',
        'size_bytes': 100,
        'doc_type': 'other',
        'doc_date': null,
        'parsed_summary': null,
        'key_extractions': null,
        'uploaded_at': '2026-05-05T12:00:00Z',
        // hostile fields — must be silently dropped:
        'parsed_text': 'a' * 100000,
        'embedding': List.filled(1536, 0.1),
      };

      final d = CaseDocument.fromJson(row);
      final back = d.toJson();
      expect(back.containsKey('parsed_text'), isFalse,
          reason: 'parsed_text must NOT be serialized client-side');
      expect(back.containsKey('embedding'), isFalse,
          reason: 'embedding must NOT be serialized client-side');
    });

    test('toJson round-trip preserves user-controlled fields', () {
      final row = {
        'id': '33333333-3333-3333-3333-333333333333',
        'case_id': '11111111-1111-1111-1111-111111111111',
        'user_id': '22222222-2222-2222-2222-222222222222',
        'filename': 'doc.pdf',
        'storage_path': 'path',
        'mime_type': 'application/pdf',
        'size_bytes': 1024,
        'doc_type': 'court_decision',
        'doc_date': '2025-12-01',
        'parsed_summary': 'sum',
        'key_extractions': {'k': 'v'},
        'uploaded_at': '2026-05-05T12:00:00Z',
      };
      final d = CaseDocument.fromJson(row);
      final back = d.toJson();
      expect(back['filename'], row['filename']);
      expect(back['doc_type'], row['doc_type']);
      expect(back['doc_date'], row['doc_date']);
      expect(back['parsed_summary'], row['parsed_summary']);
      expect(back['key_extractions'], row['key_extractions']);
    });

    test('handles null doc_date and parsed_summary gracefully', () {
      final row = {
        'id': '33333333-3333-3333-3333-333333333333',
        'case_id': '11111111-1111-1111-1111-111111111111',
        'user_id': '22222222-2222-2222-2222-222222222222',
        'filename': 'doc.pdf',
        'storage_path': 'p',
        'mime_type': null,
        'size_bytes': null,
        'doc_type': null,
        'doc_date': null,
        'parsed_summary': null,
        'key_extractions': null,
        'uploaded_at': '2026-05-05T12:00:00Z',
      };
      final d = CaseDocument.fromJson(row);
      expect(d.docDate, isNull);
      expect(d.parsedSummary, isNull);
      expect(d.keyExtractions, isNull);
    });
  });
}
