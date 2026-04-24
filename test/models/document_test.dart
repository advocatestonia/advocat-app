@Tags(['fast'])
library;

import 'package:advocat/models/document.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

void main() {
  group('CaseDocument', () {
    // ── fromJson ──────────────────────────────────────────────────────────

    group('fromJson', () {
      test('parses a complete JSON map', () {
        final json = makeDocumentJson(
          id: 'd-1',
          caseId: 'c-1',
          userId: 'u-1',
          fileName: 'decision.pdf',
          storagePath: 'u-1/c-1/decision.pdf',
          mimeType: 'application/pdf',
          fileSizeBytes: 2048,
          category: 'decision',
          language: 'et',
          ocrText: 'Otsus nr 123',
          aiSummary: 'Deportation decision summary',
          extractedEntities: {'date': '2026-01-01'},
          processingStatus: 'completed',
          createdAt: fixtureNow.toIso8601String(),
          updatedAt: fixtureNow.toIso8601String(),
        );

        final doc = CaseDocument.fromJson(json);

        expect(doc.id, 'd-1');
        expect(doc.caseId, 'c-1');
        expect(doc.userId, 'u-1');
        expect(doc.fileName, 'decision.pdf');
        expect(doc.storagePath, 'u-1/c-1/decision.pdf');
        expect(doc.mimeType, 'application/pdf');
        expect(doc.fileSizeBytes, 2048);
        expect(doc.category, DocumentCategory.decision);
        expect(doc.language, 'et');
        expect(doc.ocrText, 'Otsus nr 123');
        expect(doc.aiSummary, 'Deportation decision summary');
        expect(doc.extractedEntities, {'date': '2026-01-01'});
        expect(doc.processingStatus, DocumentProcessingStatus.completed);
        expect(doc.createdAt, fixtureNow);
        expect(doc.updatedAt, fixtureNow);
      });

      test('applies defaults for missing optional fields', () {
        final json = {
          'id': 'd-2',
          'case_id': 'c-2',
          'user_id': 'u-2',
          'file_name': 'photo.jpg',
          'storage_path': 'path/photo.jpg',
          'mime_type': 'image/jpeg',
          'file_size_bytes': 512,
          'created_at': fixtureNow.toIso8601String(),
        };

        final doc = CaseDocument.fromJson(json);

        expect(doc.category, DocumentCategory.other);
        expect(doc.language, isNull);
        expect(doc.ocrText, isNull);
        expect(doc.aiSummary, isNull);
        expect(doc.extractedEntities, isEmpty);
        expect(doc.processingStatus, DocumentProcessingStatus.pending);
        expect(doc.updatedAt, isNull);
      });

      test('maps unknown category to other', () {
        final json = makeDocumentJson(category: 'unknown_cat');
        expect(CaseDocument.fromJson(json).category, DocumentCategory.other);
      });

      test('maps null category to other', () {
        final json = makeDocumentJson();
        json['category'] = null;
        expect(CaseDocument.fromJson(json).category, DocumentCategory.other);
      });

      test('maps unknown processing_status to pending', () {
        final json = makeDocumentJson(processingStatus: 'unknown');
        expect(CaseDocument.fromJson(json).processingStatus,
            DocumentProcessingStatus.pending);
      });
    });

    // ── toJson ────────────────────────────────────────────────────────────

    group('toJson', () {
      test('serialises all fields', () {
        final doc = makeDocument(
          id: 'd-1',
          category: DocumentCategory.appeal,
          processingStatus: DocumentProcessingStatus.processing,
          language: 'fi',
          ocrText: 'OCR text',
          aiSummary: 'Summary',
          extractedEntities: {'key': 'value'},
        );

        final json = doc.toJson();

        expect(json['id'], 'd-1');
        expect(json['category'], 'appeal');
        expect(json['processing_status'], 'processing');
        expect(json['language'], 'fi');
        expect(json['ocr_text'], 'OCR text');
        expect(json['ai_summary'], 'Summary');
        expect(json['extracted_entities'], {'key': 'value'});
      });
    });

    // ── Round-trip ────────────────────────────────────────────────────────

    test('round-trip: fromJson(toJson(doc)) preserves data', () {
      final original = makeDocument(
        id: 'rt-doc',
        category: DocumentCategory.medical,
        processingStatus: DocumentProcessingStatus.failed,
        language: 'ru',
        ocrText: 'Medical report',
        aiSummary: 'Patient info',
      );

      final restored = CaseDocument.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.category, original.category);
      expect(restored.processingStatus, original.processingStatus);
      expect(restored.language, original.language);
      expect(restored.ocrText, original.ocrText);
      expect(restored.aiSummary, original.aiSummary);
    });

    // ── copyWith ──────────────────────────────────────────────────────────

    group('copyWith', () {
      test('changes specified fields', () {
        final doc = makeDocument(category: DocumentCategory.other);
        final copy = doc.copyWith(
          category: DocumentCategory.evidence,
          processingStatus: DocumentProcessingStatus.completed,
        );

        expect(copy.category, DocumentCategory.evidence);
        expect(copy.processingStatus, DocumentProcessingStatus.completed);
        expect(copy.id, doc.id);
        expect(copy.fileName, doc.fileName);
      });

      test('copies with no changes', () {
        final doc = makeDocument();
        final copy = doc.copyWith();
        expect(copy.id, doc.id);
        expect(copy.category, doc.category);
      });
    });

    // ── DocumentCategory enum ────────────────────────────────────────────

    group('DocumentCategory enum', () {
      test('has 9 values', () {
        expect(DocumentCategory.values.length, 9);
      });

      test('all values survive JSON round-trip', () {
        for (final cat in DocumentCategory.values) {
          final doc = makeDocument(category: cat);
          final json = doc.toJson();
          final restored = CaseDocument.fromJson(json);
          expect(restored.category, cat,
              reason: '${cat.name} should round-trip');
        }
      });

      test('JSON string values', () {
        final expected = {
          DocumentCategory.decision: 'decision',
          DocumentCategory.appeal: 'appeal',
          DocumentCategory.correspondence: 'correspondence',
          DocumentCategory.identity: 'identity',
          DocumentCategory.evidence: 'evidence',
          DocumentCategory.medical: 'medical',
          DocumentCategory.employment: 'employment',
          DocumentCategory.courtFiling: 'court_filing',
          DocumentCategory.other: 'other',
        };

        for (final entry in expected.entries) {
          final doc = makeDocument(category: entry.key);
          expect(doc.toJson()['category'], entry.value);
        }
      });
    });

    // ── DocumentProcessingStatus enum ────────────────────────────────────

    group('DocumentProcessingStatus enum', () {
      test('has 4 values', () {
        expect(DocumentProcessingStatus.values.length, 4);
      });

      test('all values survive JSON round-trip', () {
        for (final s in DocumentProcessingStatus.values) {
          final doc = makeDocument(processingStatus: s);
          final json = doc.toJson();
          final restored = CaseDocument.fromJson(json);
          expect(restored.processingStatus, s,
              reason: '${s.name} should round-trip');
        }
      });
    });
  });
}
