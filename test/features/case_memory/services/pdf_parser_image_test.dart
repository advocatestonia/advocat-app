// =====================================================================
// Tests for [PdfParserService] image-path support — P0 fix 2026-05-25.
//
// The base-class hard-rejected anything that wasn't application/pdf
// before this fix, breaking the photo-upload UX (user snaps a phone
// pic of a paper letter, app refuses at step 1). These tests pin the
// MIME acceptance matrix for the JPEG/PNG/HEIC/HEIF/WebP path and
// verify the canonical MIME flows through to the upload + edge body.
//
// Hermetic — same fake [SupabaseService] + [PdfStorageUploader] seam
// as `pdf_parser_service_test.dart`.
// =====================================================================

@Tags(['fast'])
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:advocat/features/case_memory/services/pdf_parser_service.dart';
import 'package:advocat/services/supabase_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _validCaseId = '550e8400-e29b-41d4-a716-446655440000';
const _userId = 'user-1';

class _FakeSupabaseService implements SupabaseService {
  _FakeSupabaseService({
    this.demo = false,
    this.userId = _userId,
    this.response,
  });

  bool demo;
  String? userId;
  Map<String, dynamic>? response;

  String? lastFunctionName;
  Map<String, dynamic>? lastBody;
  int callCount = 0;

  @override
  bool get isDemo => demo;

  @override
  String? get currentUserId => userId;

  @override
  Future<Map<String, dynamic>?> callEdgeFunction(
    String functionName, {
    Map<String, dynamic>? body,
    String? traceId,
  }) async {
    callCount++;
    lastFunctionName = functionName;
    lastBody = body;
    return response;
  }

  @override
  dynamic noSuchMethod(Invocation i) {
    throw UnimplementedError(
      '_FakeSupabaseService.${i.memberName.toString()} not stubbed',
    );
  }
}

class _FakeUploader {
  String? lastBucket;
  String? lastPath;
  Uint8List? lastBytes;
  String? lastContentType;
  int callCount = 0;

  Future<void> upload({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    callCount++;
    lastBucket = bucket;
    lastPath = path;
    lastBytes = bytes;
    lastContentType = contentType;
  }
}

Uint8List _bytes([int n = 64]) =>
    Uint8List.fromList(List<int>.generate(n, (i) => i & 0xFF));

Map<String, dynamic> _okResponse() => {
      'document_id': 'doc-1',
      'doc_type': 'correspondence',
      'parsed_summary': 'Photo of a letter',
      'key_extractions': {'doc_type': 'correspondence'},
      'page_count': 1,
      'lang_detected': ['fi'],
    };

void main() {
  group('PdfParserService — image MIME acceptance matrix', () {
    test('isImageMime accepts every supported MIME', () {
      for (final m in PdfParserService.supportedImageMimeTypes) {
        expect(
          PdfParserService.isImageMime(m),
          isTrue,
          reason: '$m should be accepted',
        );
        // Case-insensitive.
        expect(PdfParserService.isImageMime(m.toUpperCase()), isTrue);
        // Whitespace-tolerant.
        expect(PdfParserService.isImageMime('  $m  '), isTrue);
      }
    });

    test('isImageMime rejects PDFs and other types', () {
      for (final bad in <String>[
        'application/pdf',
        'image/gif',
        'image/tiff',
        'image/bmp',
        'text/plain',
        '',
      ]) {
        expect(
          PdfParserService.isImageMime(bad),
          isFalse,
          reason: '$bad should be rejected',
        );
      }
    });

    test('isPdfMime accepts only application/pdf', () {
      expect(PdfParserService.isPdfMime('application/pdf'), isTrue);
      expect(PdfParserService.isPdfMime('APPLICATION/PDF'), isTrue);
      expect(PdfParserService.isPdfMime('image/jpeg'), isFalse);
      expect(PdfParserService.isPdfMime('pdf'), isFalse);
    });
  });

  group('PdfParserService.uploadAndParse — image happy paths', () {
    Future<ParsedDocumentResult> runWith(String mime, String filename) async {
      final supa = _FakeSupabaseService(response: _okResponse());
      final up = _FakeUploader();
      final svc = PdfParserService.forTest(
        supabase: supa,
        uploader: up.upload,
      );
      final result = await svc.uploadAndParse(
        bytes: _bytes(),
        filename: filename,
        mimeType: mime,
        activeCaseId: _validCaseId,
      );
      // Sanity: upload + edge call both fired.
      expect(up.callCount, 1, reason: 'uploader must fire for $mime');
      expect(supa.callCount, 1, reason: 'edge fn must fire for $mime');
      // Spy lookups live on the fakes.
      _lastUp = up;
      _lastSupa = supa;
      return result;
    }

    test('JPEG → uploads with image/jpeg content type, edge fn sees image/jpeg',
        () async {
      final r = await runWith('image/jpeg', 'photo.jpg');
      expect(r, isA<ParsedOk>());
      expect(_lastUp.lastContentType, 'image/jpeg');
      expect(_lastSupa.lastBody?['mime_type'], 'image/jpeg');
    });

    test('image/jpg alias is canonicalized to image/jpeg', () async {
      final r = await runWith('image/jpg', 'photo.jpg');
      expect(r, isA<ParsedOk>());
      // Canonical spelling makes it to both upload + edge body.
      expect(_lastUp.lastContentType, 'image/jpeg');
      expect(_lastSupa.lastBody?['mime_type'], 'image/jpeg');
    });

    test('PNG screenshot → image/png passes through unchanged', () async {
      final r = await runWith('image/png', 'screen.png');
      expect(r, isA<ParsedOk>());
      expect(_lastUp.lastContentType, 'image/png');
      expect(_lastSupa.lastBody?['mime_type'], 'image/png');
    });

    test('HEIC (iOS) → image/heic passes through', () async {
      final r = await runWith('image/heic', 'IMG_0001.heic');
      expect(r, isA<ParsedOk>());
      expect(_lastUp.lastContentType, 'image/heic');
      expect(_lastSupa.lastBody?['mime_type'], 'image/heic');
    });

    test('HEIF → image/heif passes through', () async {
      final r = await runWith('image/heif', 'x.heif');
      expect(r, isA<ParsedOk>());
      expect(_lastUp.lastContentType, 'image/heif');
      expect(_lastSupa.lastBody?['mime_type'], 'image/heif');
    });

    test('WebP → image/webp passes through', () async {
      final r = await runWith('image/webp', 'x.webp');
      expect(r, isA<ParsedOk>());
      expect(_lastUp.lastContentType, 'image/webp');
      expect(_lastSupa.lastBody?['mime_type'], 'image/webp');
    });

    test('upper-case MIME normalises to canonical lower-case', () async {
      final r = await runWith('IMAGE/PNG', 'x.png');
      expect(r, isA<ParsedOk>());
      expect(_lastUp.lastContentType, 'image/png');
      expect(_lastSupa.lastBody?['mime_type'], 'image/png');
    });
  });

  group('PdfParserService.uploadAndParse — image rejection paths', () {
    test('image > 10 MB is rejected before upload', () async {
      final supa = _FakeSupabaseService(response: _okResponse());
      final up = _FakeUploader();
      final svc = PdfParserService.forTest(
        supabase: supa,
        uploader: up.upload,
      );
      final big = Uint8List(PdfParserService.maxImageBytes + 1);
      final r = await svc.uploadAndParse(
        bytes: big,
        filename: 'huge.jpg',
        mimeType: 'image/jpeg',
      );
      expect(r, isA<ParsedInvalidInput>());
      expect((r as ParsedInvalidInput).message, contains('Image too large'));
      expect(up.callCount, 0);
      expect(supa.callCount, 0);
    });

    test('PDF up to 50 MB is still allowed (no image-cap regression)',
        () async {
      final supa = _FakeSupabaseService(response: _okResponse());
      final up = _FakeUploader();
      final svc = PdfParserService.forTest(
        supabase: supa,
        uploader: up.upload,
      );
      // 11 MB PDF — would be rejected by the image cap, must pass the
      // PDF cap (50 MB) untouched.
      final r = await svc.uploadAndParse(
        bytes: Uint8List(11 * 1024 * 1024),
        filename: 'big.pdf',
        mimeType: 'application/pdf',
        activeCaseId: _validCaseId,
      );
      expect(r, isA<ParsedOk>());
      expect(up.callCount, 1);
    });

    test('unsupported MIME (gif) still rejected', () async {
      final supa = _FakeSupabaseService(response: _okResponse());
      final up = _FakeUploader();
      final svc = PdfParserService.forTest(
        supabase: supa,
        uploader: up.upload,
      );
      final r = await svc.uploadAndParse(
        bytes: _bytes(),
        filename: 'x.gif',
        mimeType: 'image/gif',
      );
      expect(r, isA<ParsedInvalidInput>());
      expect(up.callCount, 0);
      expect(supa.callCount, 0);
    });

    test('docx still rejected', () async {
      final svc = PdfParserService.forTest(
        supabase: _FakeSupabaseService(),
        uploader: _FakeUploader().upload,
      );
      final r = await svc.uploadAndParse(
        bytes: _bytes(),
        filename: 'x.docx',
        mimeType:
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      );
      expect(r, isA<ParsedInvalidInput>());
    });

    test('PDF path unchanged: 51 MB PDF still rejected at validator', () async {
      final svc = PdfParserService.forTest(
        supabase: _FakeSupabaseService(),
        uploader: _FakeUploader().upload,
      );
      final r = await svc.uploadAndParse(
        bytes: Uint8List(PdfParserService.maxBytes + 1),
        filename: 'huge.pdf',
        mimeType: 'application/pdf',
      );
      expect(r, isA<ParsedInvalidInput>());
      expect((r as ParsedInvalidInput).message, contains('PDF too large'));
    });
  });
}

// Module-level handles so the helper closure can expose the fakes to
// the test bodies. The alternative — passing them through return tuples
// — bloats every test by 4 extra lines.
late _FakeUploader _lastUp;
late _FakeSupabaseService _lastSupa;
