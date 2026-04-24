@Tags(['fast'])
library;

// Overnight isolated test suite — DOES NOT modify production code.
// Edge-case coverage for CaseDocument model.
import 'package:flutter_test/flutter_test.dart';
import 'package:advocat/models/document.dart';

void main() {
  group('CaseDocument overnight edge cases', () {
    test('all DocumentCategory enum values round-trip', () {
      for (final cat in DocumentCategory.values) {
        final d = CaseDocument(
          id: 'd1',
          caseId: 'c1',
          userId: 'u1',
          fileName: 'f.pdf',
          storagePath: '/tmp/f.pdf',
          mimeType: 'application/pdf',
          fileSizeBytes: 1024,
          category: cat,
          createdAt: DateTime.utc(2024, 1, 1),
        );
        final decoded = CaseDocument.fromJson(d.toJson());
        expect(decoded.category, cat, reason: 'round-trip fails for $cat');
      }
    });

    test('all DocumentProcessingStatus values round-trip', () {
      for (final st in DocumentProcessingStatus.values) {
        final d = CaseDocument(
          id: 'd1',
          caseId: 'c1',
          userId: 'u1',
          fileName: 'f.pdf',
          storagePath: '/tmp/f.pdf',
          mimeType: 'application/pdf',
          fileSizeBytes: 1024,
          processingStatus: st,
          createdAt: DateTime.utc(2024, 1, 1),
        );
        final decoded = CaseDocument.fromJson(d.toJson());
        expect(decoded.processingStatus, st, reason: 'round-trip fails for $st');
      }
    });

    test('unknown category/processing_status falls back to safe defaults', () {
      final d = CaseDocument.fromJson({
        'id': 'd1',
        'case_id': 'c1',
        'user_id': 'u1',
        'file_name': 'f.pdf',
        'storage_path': '/tmp/f.pdf',
        'mime_type': 'application/pdf',
        'file_size_bytes': 1024,
        'category': 'does_not_exist',
        'processing_status': 'nonsense',
        'created_at': '2024-01-01T00:00:00.000Z',
      });
      expect(d.category, DocumentCategory.other);
      expect(d.processingStatus, DocumentProcessingStatus.pending);
    });

    test('extractedEntities defaults to empty map when absent', () {
      final d = CaseDocument.fromJson({
        'id': 'd1',
        'case_id': 'c1',
        'user_id': 'u1',
        'file_name': 'f.pdf',
        'storage_path': '/tmp/f.pdf',
        'mime_type': 'application/pdf',
        'file_size_bytes': 1024,
        'created_at': '2024-01-01T00:00:00.000Z',
      });
      expect(d.extractedEntities, isA<Map<String, dynamic>>());
      expect(d.extractedEntities, isEmpty);
    });

    test('extractedEntities round-trip preserves nested JSON', () {
      final entities = {
        'dates': ['2024-05-01', '2024-06-01'],
        'refs': {'migri': 'A-123', 'case': 'B-456'},
        'count': 3,
      };
      final d = CaseDocument(
        id: 'd1',
        caseId: 'c1',
        userId: 'u1',
        fileName: 'f.pdf',
        storagePath: '/tmp/f.pdf',
        mimeType: 'application/pdf',
        fileSizeBytes: 1024,
        extractedEntities: entities,
        createdAt: DateTime.utc(2024, 1, 1),
      );
      final b = CaseDocument.fromJson(d.toJson());
      expect(b.extractedEntities['dates'], entities['dates']);
      expect((b.extractedEntities['refs'] as Map)['migri'], 'A-123');
      expect(b.extractedEntities['count'], 3);
    });

    test('file size of 0 is allowed (empty file edge case)', () {
      final d = CaseDocument(
        id: 'd1',
        caseId: 'c1',
        userId: 'u1',
        fileName: 'empty.pdf',
        storagePath: '/tmp/empty.pdf',
        mimeType: 'application/pdf',
        fileSizeBytes: 0,
        createdAt: DateTime.utc(2024, 1, 1),
      );
      expect(d.fileSizeBytes, 0);
      final b = CaseDocument.fromJson(d.toJson());
      expect(b.fileSizeBytes, 0);
    });

    test('large file size preserved (>2GB boundary)', () {
      const big = 3 * 1024 * 1024 * 1024; // 3 GB
      final d = CaseDocument(
        id: 'd1',
        caseId: 'c1',
        userId: 'u1',
        fileName: 'big.bin',
        storagePath: '/tmp/big.bin',
        mimeType: 'application/octet-stream',
        fileSizeBytes: big,
        createdAt: DateTime.utc(2024, 1, 1),
      );
      final b = CaseDocument.fromJson(d.toJson());
      expect(b.fileSizeBytes, big);
    });

    test('DocumentCategory length is 9 (stable contract)', () {
      expect(DocumentCategory.values.length, 9);
    });

    test('DocumentProcessingStatus length is 4 (stable contract)', () {
      expect(DocumentProcessingStatus.values.length, 4);
    });
  });
}
