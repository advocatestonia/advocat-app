// =====================================================================
// pdf_parser_soft_case_test.dart — P0 first-touch upload coverage.
//
// Pins the soft-case-shell behaviour added in PdfParserService:
//
//   * authenticated user + null activeCaseId
//        → service calls ensureSoftCaseForUser RPC
//        → returned id is forwarded to pdf-parser as case_id
//        → ParsedOk.softCaseId is set and equals the shell id
//        → deadline-extractor handoff (via pdf-parser) now has a real
//          case_id to attach the 10-day appeal deadline to
//
//   * anonymous (no user) caller
//        → RPC is NOT called, the old documentId='' / forbidden path
//          remains intact
//
//   * authenticated user + non-null activeCaseId
//        → RPC is NOT called (no shell needed)
//        → softCaseId stays null on the result
//
//   * authenticated user + null activeCaseId + RPC returns null
//        → fall back to the legacy null path (no crash, file still
//          uploaded under "general" segment)
//
// Hermetic — no Supabase emulator, no network. The fake supabase service
// records every call and returns scripted responses.
// =====================================================================

@Tags(['fast'])
library;

import 'dart:typed_data';

import 'package:advocat/features/case_memory/services/pdf_parser_service.dart';
import 'package:advocat/services/supabase_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _userId = 'user-1';
const _shellCaseId = '8a7d2e3a-4b56-4c89-9d0e-1f2a3b4c5d6e';
const _existingCaseId = '550e8400-e29b-41d4-a716-446655440000';

// =====================================================================
// Fakes — extended _FakeSupabaseService with ensureSoftCaseForUser spy
// =====================================================================

class _FakeSupabaseService implements SupabaseService {
  _FakeSupabaseService({
    this.userId = _userId,
    this.response,
    this.softCaseId,
    this.throwsOnEnsure = false,
  });

  // Demo mode is irrelevant to the soft-case shell path — those code
  // paths short-circuit before the RPC. We omit the parameter here to
  // keep the fake surface lean; the parent pdf_parser_service_test.dart
  // covers demo-mode behaviour.
  String? userId;
  Map<String, dynamic>? response;
  String? softCaseId;
  bool throwsOnEnsure;

  // Spies
  String? lastFunctionName;
  Map<String, dynamic>? lastBody;
  int callCount = 0;
  int ensureSoftCaseCallCount = 0;

  @override
  bool get isDemo => false;

  @override
  String? get currentUserId => userId;

  @override
  Future<String?> ensureSoftCaseForUser() async {
    ensureSoftCaseCallCount++;
    if (throwsOnEnsure) throw StateError('rpc dead');
    return softCaseId;
  }

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

Map<String, dynamic> _okResponse({
  String docId = 'doc-1',
  String docType = 'police_report',
}) =>
    {
      'document_id': docId,
      'doc_type': docType,
      'parsed_summary': 'Käännytyspäätös, valitusaika 10 vrk',
      'key_extractions': {'doc_type': docType, 'deadline_days': 10},
      'page_count': 4,
      'lang_detected': ['fi', 'fi'],
    };

// =====================================================================
// Tests
// =====================================================================

void main() {
  group('PdfParserService — soft-case shell for first-touch uploads', () {
    test(
      'authenticated user + null activeCaseId → RPC called, shell id forwarded',
      () async {
        final supa = _FakeSupabaseService(
          softCaseId: _shellCaseId,
          response: _okResponse(),
        );
        final up = _FakeUploader();
        final svc = PdfParserService.forTest(supabase: supa, uploader: up.upload);

        final r = await svc.uploadAndParse(
          bytes: _bytes(),
          filename: 'paatos.pdf',
          mimeType: 'application/pdf',
          // activeCaseId intentionally null — first-touch upload.
        );

        // 1. RPC was called exactly once.
        expect(supa.ensureSoftCaseCallCount, 1,
            reason: 'ensureSoftCaseForUser must be called when '
                'activeCaseId is null and a user is signed in');

        // 2. The pdf-parser POST body forwards the shell id as case_id.
        expect(supa.lastBody?['case_id'], _shellCaseId,
            reason: 'shell id must replace the null case_id so '
                'deadline-extractor has a real case to attach to');

        // 3. Storage path uses the shell id segment, not "general".
        expect(up.lastPath, '$_userId/$_shellCaseId/paatos.pdf');

        // 4. Result carries the softCaseId for the rename banner.
        expect(r, isA<ParsedOk>());
        final ok = r as ParsedOk;
        expect(ok.softCaseId, _shellCaseId);
        expect(ok.documentId, 'doc-1',
            reason: 'documentId must NOT be empty for soft-shell uploads '
                '— that was the P0 regression');
      },
    );

    test(
      'authenticated user + null activeCaseId + RPC null → legacy fallback',
      () async {
        // Older DB without the migration: RPC returns null. Service must
        // not crash; it should fall back to the pre-fix null path so the
        // upload still succeeds (deadline extraction still misses, but
        // the user at least sees the parsed result).
        final supa = _FakeSupabaseService(
          softCaseId: null,
          response: _okResponse(docId: ''),
        );
        final up = _FakeUploader();
        final svc = PdfParserService.forTest(supabase: supa, uploader: up.upload);

        final r = await svc.uploadAndParse(
          bytes: _bytes(),
          filename: 'note.pdf',
          mimeType: 'application/pdf',
        );

        expect(supa.ensureSoftCaseCallCount, 1);
        expect(supa.lastBody?['case_id'], isNull);
        expect(up.lastPath, '$_userId/general/note.pdf');
        expect(r, isA<ParsedOk>());
        expect((r as ParsedOk).softCaseId, isNull);
      },
    );

    test(
      'authenticated user + valid activeCaseId → RPC skipped, no shell',
      () async {
        final supa = _FakeSupabaseService(
          softCaseId: _shellCaseId, // would be returned IF called
          response: _okResponse(docId: 'doc-2'),
        );
        final up = _FakeUploader();
        final svc = PdfParserService.forTest(supabase: supa, uploader: up.upload);

        final r = await svc.uploadAndParse(
          bytes: _bytes(),
          filename: 'evidence.pdf',
          mimeType: 'application/pdf',
          activeCaseId: _existingCaseId,
        );

        // Did NOT call ensureSoftCaseForUser — there's already an active case.
        expect(supa.ensureSoftCaseCallCount, 0,
            reason: 'shell creation must be skipped when the caller '
                'already has an active case');
        expect(supa.lastBody?['case_id'], _existingCaseId);
        expect(up.lastPath, '$_userId/$_existingCaseId/evidence.pdf');
        expect(r, isA<ParsedOk>());
        expect((r as ParsedOk).softCaseId, isNull,
            reason: 'softCaseId must be null when no shell was created');
      },
    );

    test('anonymous (no user) → RPC not called, ParsedForbidden returned',
        () async {
      final supa = _FakeSupabaseService(
        userId: null,
        softCaseId: _shellCaseId, // would leak if logic was wrong
      );
      final up = _FakeUploader();
      final svc = PdfParserService.forTest(supabase: supa, uploader: up.upload);

      final r = await svc.uploadAndParse(
        bytes: _bytes(),
        filename: 'leak.pdf',
        mimeType: 'application/pdf',
      );

      expect(r, isA<ParsedForbidden>(),
          reason: 'anon callers cannot persist anything — the service '
              'must short-circuit before touching the RPC');
      expect(supa.ensureSoftCaseCallCount, 0);
      expect(up.callCount, 0);
      expect(supa.callCount, 0);
    });

    test('RPC throws → fall back to legacy null path (never crashes)',
        () async {
      final supa = _FakeSupabaseService(
        throwsOnEnsure: true,
        response: _okResponse(docId: ''),
      );
      final up = _FakeUploader();
      final svc = PdfParserService.forTest(supabase: supa, uploader: up.upload);

      // Today the service catches the RPC error inside SupabaseService
      // (ensureSoftCaseForUser returns null in the production
      // implementation); in this test we want to assert the broader
      // contract — the upload still succeeds even if the RPC layer
      // throws (i.e. the service must not propagate). Since our fake
      // throws directly, we expect the service to either translate
      // that into a ParsedNetworkError OR continue with the legacy
      // null path. Either is acceptable; both are non-crash.
      late ParsedDocumentResult r;
      var threw = false;
      try {
        r = await svc.uploadAndParse(
          bytes: _bytes(),
          filename: 'paatos.pdf',
          mimeType: 'application/pdf',
        );
      } catch (_) {
        threw = true;
      }
      expect(threw, isFalse,
          reason: 'uploadAndParse MUST NOT throw — chat screens render '
              'errors inline. See sealed-result contract at top of file.');
      // Whichever branch we ended up on, the result must be one of the
      // sealed types and never bubble.
      expect(r, isA<ParsedDocumentResult>());
    });

    test('shell upload still progresses through 0.5 then 1.0', () async {
      final supa = _FakeSupabaseService(
        softCaseId: _shellCaseId,
        response: _okResponse(),
      );
      final svc = PdfParserService.forTest(
        supabase: supa,
        uploader: _FakeUploader().upload,
      );
      final progress = <double>[];
      await svc.uploadAndParse(
        bytes: _bytes(),
        filename: 'paatos.pdf',
        mimeType: 'application/pdf',
        onProgress: progress.add,
      );
      expect(progress, [0.5, 1.0]);
    });
  });
}
