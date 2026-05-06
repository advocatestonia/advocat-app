// =====================================================================
// Tests for [PdfParserService] — Pkg 2 client.
//
// Hermetic: a fake [SupabaseService] overrides callEdgeFunction +
// currentUserId + isDemo, and a fake uploader records bucket/path/bytes.
// No network, no Storage emulator, no platform channels.
// =====================================================================

@Tags(['fast'])
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:advocat/features/case_memory/data/case_repository.dart';
import 'package:advocat/features/case_memory/models/case_document.dart';
import 'package:advocat/features/case_memory/models/user_case.dart';
import 'package:advocat/features/case_memory/services/pdf_parser_service.dart';
import 'package:advocat/features/case_memory/state/cases_list_provider.dart';
import 'package:advocat/services/supabase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _validCaseId = '550e8400-e29b-41d4-a716-446655440000';
const _userId = 'user-1';

// =====================================================================
// Fakes
// =====================================================================

class _FakeSupabaseService implements SupabaseService {
  _FakeSupabaseService({
    this.demo = false,
    this.userId = _userId,
    this.response,
    this.throwsOnCall = false,
  });

  bool demo;
  String? userId;
  Map<String, dynamic>? response;
  bool throwsOnCall;

  // Spy
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
  }) async {
    callCount++;
    lastFunctionName = functionName;
    lastBody = body;
    if (throwsOnCall) throw StateError('boom');
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
  Object? throwOnUpload;

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
    if (throwOnUpload != null) throw throwOnUpload!;
  }
}

class _FakeCaseRepository implements CaseRepository {
  _FakeCaseRepository(this.cases);
  final List<UserCase> cases;
  int listCallCount = 0;
  int getCallCount = 0;

  @override
  Future<List<UserCase>> listCases({CaseListFilter filter = CaseListFilter.active}) async {
    listCallCount++;
    return cases;
  }

  @override
  Future<UserCase?> getCase(String id) async {
    getCallCount++;
    return cases.cast<UserCase?>().firstWhere(
          (c) => c?.id == id,
          orElse: () => null,
        );
  }

  @override
  Future<UserCase> createCase({
    required String title,
    required String jurisdiction,
    String? caseType,
    String language = 'ru',
  }) async => throw UnimplementedError();

  @override
  Future<UserCase> updateCase(UserCase updated) async => throw UnimplementedError();

  @override
  Future<void> archiveCase(String id) async => throw UnimplementedError();

  @override
  Future<void> closeCase(String id) async => throw UnimplementedError();

  @override
  Future<List<CaseDocument>> listDocuments(String caseId) async => const [];

  // Pkg 3 added this for the intake wizard's step 5. Pkg 2 doesn't use it
  // — we go straight to Storage + the pdf-parser edge fn — but the
  // interface contract demands an implementation.
  @override
  dynamic noSuchMethod(Invocation i) {
    throw UnimplementedError(
      '_FakeCaseRepository.${i.memberName.toString()} not stubbed',
    );
  }
}

UserCase _stubCase(String id) => UserCase(
      id: id,
      userId: _userId,
      title: 'Test',
      jurisdiction: 'EE',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );

Uint8List _bytes([int n = 64]) =>
    Uint8List.fromList(List<int>.generate(n, (i) => i & 0xFF));

Map<String, dynamic> _okResponse({
  String docId = 'doc-1',
  String docType = 'police_report',
  int pageCount = 3,
  List<String> langs = const ['fi', 'fi', 'fi'],
}) =>
    {
      'document_id': docId,
      'doc_type': docType,
      'parsed_summary': 'Summary text',
      'key_extractions': {
        'doc_type': docType,
        'parties': [
          {'name': 'Sofia', 'role': 'victim'},
        ],
      },
      'page_count': pageCount,
      'lang_detected': langs,
    };

// =====================================================================
// Tests
// =====================================================================

void main() {
  group('PdfParserService.uploadAndParse — input validation', () {
    test('rejects empty bytes without uploading', () async {
      final supa = _FakeSupabaseService();
      final up = _FakeUploader();
      final svc = PdfParserService.forTest(supabase: supa, uploader: up.upload);
      final r = await svc.uploadAndParse(
        bytes: Uint8List(0),
        filename: 'x.pdf',
        mimeType: 'application/pdf',
      );
      expect(r, isA<ParsedInvalidInput>());
      expect(up.callCount, 0);
      expect(supa.callCount, 0);
    });

    test('rejects oversize bytes (>50 MB) without uploading', () async {
      final supa = _FakeSupabaseService();
      final up = _FakeUploader();
      final svc = PdfParserService.forTest(supabase: supa, uploader: up.upload);
      // Build a sentinel without actually allocating 51MB (CI-friendly).
      // We rely on the service checking length before uploading; the
      // bytes themselves don't matter.
      final big = Uint8List(PdfParserService.maxBytes + 1);
      final r = await svc.uploadAndParse(
        bytes: big,
        filename: 'big.pdf',
        mimeType: 'application/pdf',
      );
      expect(r, isA<ParsedInvalidInput>());
      expect(up.callCount, 0);
      expect(supa.callCount, 0);
    });

    test('rejects empty filename', () async {
      final svc = PdfParserService.forTest(
        supabase: _FakeSupabaseService(),
        uploader: _FakeUploader().upload,
      );
      final r = await svc.uploadAndParse(
        bytes: _bytes(),
        filename: '   ',
        mimeType: 'application/pdf',
      );
      expect(r, isA<ParsedInvalidInput>());
    });

    test('rejects non-PDF mime type', () async {
      final svc = PdfParserService.forTest(
        supabase: _FakeSupabaseService(),
        uploader: _FakeUploader().upload,
      );
      final r = await svc.uploadAndParse(
        bytes: _bytes(),
        filename: 'x.docx',
        mimeType: 'application/vnd.openxmlformats',
      );
      expect(r, isA<ParsedInvalidInput>());
    });

    test('rejects non-UUID activeCaseId', () async {
      final svc = PdfParserService.forTest(
        supabase: _FakeSupabaseService(),
        uploader: _FakeUploader().upload,
      );
      final r = await svc.uploadAndParse(
        bytes: _bytes(),
        filename: 'x.pdf',
        mimeType: 'application/pdf',
        activeCaseId: 'general',
      );
      expect(r, isA<ParsedInvalidInput>());
    });

    test('demo mode skips without upload + call', () async {
      final supa = _FakeSupabaseService(demo: true);
      final up = _FakeUploader();
      final svc = PdfParserService.forTest(supabase: supa, uploader: up.upload);
      final r = await svc.uploadAndParse(
        bytes: _bytes(),
        filename: 'x.pdf',
        mimeType: 'application/pdf',
      );
      expect(r, isA<ParsedDemo>());
      expect(up.callCount, 0);
      expect(supa.callCount, 0);
    });

    test('forbidden when no authenticated user', () async {
      final supa = _FakeSupabaseService(userId: null);
      final up = _FakeUploader();
      final svc = PdfParserService.forTest(supabase: supa, uploader: up.upload);
      final r = await svc.uploadAndParse(
        bytes: _bytes(),
        filename: 'x.pdf',
        mimeType: 'application/pdf',
      );
      expect(r, isA<ParsedForbidden>());
      expect(up.callCount, 0);
    });
  });

  group('PdfParserService.uploadAndParse — upload + POST shape', () {
    test('uploads to case-documents/<uid>/<caseId>/<filename>', () async {
      final supa = _FakeSupabaseService(response: _okResponse());
      final up = _FakeUploader();
      final svc = PdfParserService.forTest(supabase: supa, uploader: up.upload);
      await svc.uploadAndParse(
        bytes: _bytes(),
        filename: 'protocol.pdf',
        mimeType: 'application/pdf',
        activeCaseId: _validCaseId,
      );
      expect(up.lastBucket, PdfParserService.storageBucket);
      expect(up.lastPath, '$_userId/$_validCaseId/protocol.pdf');
      expect(up.lastContentType, 'application/pdf');
      expect(up.lastBytes?.length, 64);
    });

    test('uploads under "general" segment when activeCaseId is null', () async {
      final supa = _FakeSupabaseService(response: _okResponse(docId: ''));
      final up = _FakeUploader();
      final svc = PdfParserService.forTest(supabase: supa, uploader: up.upload);
      await svc.uploadAndParse(
        bytes: _bytes(),
        filename: 'note.pdf',
        mimeType: 'application/pdf',
      );
      expect(up.lastPath, '$_userId/general/note.pdf');
    });

    test('POSTs {storage_path, case_id, mime_type, filename}', () async {
      final supa = _FakeSupabaseService(response: _okResponse());
      final svc = PdfParserService.forTest(
        supabase: supa,
        uploader: _FakeUploader().upload,
      );
      await svc.uploadAndParse(
        bytes: _bytes(),
        filename: 'protocol.pdf',
        mimeType: 'application/pdf',
        activeCaseId: _validCaseId,
      );
      expect(supa.lastFunctionName, PdfParserService.endpoint);
      expect(supa.lastBody?['storage_path'], '$_userId/$_validCaseId/protocol.pdf');
      expect(supa.lastBody?['case_id'], _validCaseId);
      expect(supa.lastBody?['mime_type'], 'application/pdf');
      expect(supa.lastBody?['filename'], 'protocol.pdf');
    });

    test('case_id is null in POST body when activeCaseId not set', () async {
      final supa = _FakeSupabaseService(response: _okResponse(docId: ''));
      final svc = PdfParserService.forTest(
        supabase: supa,
        uploader: _FakeUploader().upload,
      );
      await svc.uploadAndParse(
        bytes: _bytes(),
        filename: 'note.pdf',
        mimeType: 'application/pdf',
      );
      expect(supa.lastBody?['case_id'], isNull);
    });

    test('sanitizes filenames with path separators / spaces / ..', () async {
      final supa = _FakeSupabaseService(response: _okResponse());
      final up = _FakeUploader();
      final svc = PdfParserService.forTest(supabase: supa, uploader: up.upload);
      await svc.uploadAndParse(
        bytes: _bytes(),
        filename: '../../etc/passwd file with spaces.pdf',
        mimeType: 'application/pdf',
        activeCaseId: _validCaseId,
      );
      // No '..', no '/' or '\', no whitespace.
      expect(up.lastPath, isNot(contains('..')));
      expect(up.lastPath, isNot(contains(' ')));
      expect(up.lastPath, startsWith('$_userId/$_validCaseId/'));
    });
  });

  group('PdfParserService.uploadAndParse — happy path', () {
    test('returns ParsedOk with all fields populated', () async {
      final supa = _FakeSupabaseService(response: _okResponse());
      final svc = PdfParserService.forTest(
        supabase: supa,
        uploader: _FakeUploader().upload,
      );
      final r = await svc.uploadAndParse(
        bytes: _bytes(),
        filename: 'x.pdf',
        mimeType: 'application/pdf',
        activeCaseId: _validCaseId,
      );
      expect(r, isA<ParsedOk>());
      final ok = r as ParsedOk;
      expect(ok.documentId, 'doc-1');
      expect(ok.docType, 'police_report');
      expect(ok.parsedSummary, 'Summary text');
      expect(ok.pageCount, 3);
      expect(ok.langDetected, ['fi', 'fi', 'fi']);
      expect(ok.keyExtractions['doc_type'], 'police_report');
    });

    test('progress callback fires at 0.5 and 1.0', () async {
      final supa = _FakeSupabaseService(response: _okResponse());
      final svc = PdfParserService.forTest(
        supabase: supa,
        uploader: _FakeUploader().upload,
      );
      final progress = <double>[];
      await svc.uploadAndParse(
        bytes: _bytes(),
        filename: 'x.pdf',
        mimeType: 'application/pdf',
        activeCaseId: _validCaseId,
        onProgress: progress.add,
      );
      expect(progress, [0.5, 1.0]);
    });
  });

  group('PdfParserService.uploadAndParse — error mapping', () {
    test('upload failure → ParsedNetworkError without calling edge', () async {
      final supa = _FakeSupabaseService(response: _okResponse());
      final up = _FakeUploader()..throwOnUpload = StateError('storage 500');
      final svc = PdfParserService.forTest(supabase: supa, uploader: up.upload);
      final r = await svc.uploadAndParse(
        bytes: _bytes(),
        filename: 'x.pdf',
        mimeType: 'application/pdf',
        activeCaseId: _validCaseId,
      );
      expect(r, isA<ParsedNetworkError>());
      expect(supa.callCount, 0);
    });

    test('edge throws → ParsedNetworkError, never bubbles', () async {
      final supa = _FakeSupabaseService(throwsOnCall: true);
      final svc = PdfParserService.forTest(
        supabase: supa,
        uploader: _FakeUploader().upload,
      );
      final r = await svc.uploadAndParse(
        bytes: _bytes(),
        filename: 'x.pdf',
        mimeType: 'application/pdf',
        activeCaseId: _validCaseId,
      );
      expect(r, isA<ParsedNetworkError>());
    });

    test('null edge response → ParsedNetworkError', () async {
      final supa = _FakeSupabaseService(response: null);
      final svc = PdfParserService.forTest(
        supabase: supa,
        uploader: _FakeUploader().upload,
      );
      final r = await svc.uploadAndParse(
        bytes: _bytes(),
        filename: 'x.pdf',
        mimeType: 'application/pdf',
        activeCaseId: _validCaseId,
      );
      expect(r, isA<ParsedNetworkError>());
    });

    test('error: too_long → ParsedTooLong with parsed_pages', () async {
      final supa = _FakeSupabaseService(
        response: {'error': 'too_long', 'parsed_pages': 100},
      );
      final svc = PdfParserService.forTest(
        supabase: supa,
        uploader: _FakeUploader().upload,
      );
      final r = await svc.uploadAndParse(
        bytes: _bytes(),
        filename: 'x.pdf',
        mimeType: 'application/pdf',
        activeCaseId: _validCaseId,
      );
      expect(r, isA<ParsedTooLong>());
      expect((r as ParsedTooLong).parsedPages, 100);
    });

    test('error: scan_too_long → ParsedScanTooLong with suggestion', () async {
      final supa = _FakeSupabaseService(
        response: {'error': 'scan_too_long', 'suggestion': 'split it'},
      );
      final svc = PdfParserService.forTest(
        supabase: supa,
        uploader: _FakeUploader().upload,
      );
      final r = await svc.uploadAndParse(
        bytes: _bytes(),
        filename: 'x.pdf',
        mimeType: 'application/pdf',
        activeCaseId: _validCaseId,
      );
      expect(r, isA<ParsedScanTooLong>());
      expect((r as ParsedScanTooLong).suggestion, 'split it');
    });

    test('error: unreadable → ParsedUnreadable', () async {
      final supa = _FakeSupabaseService(
        response: {'error': 'unreadable', 'suggestion': 'try clearer scan'},
      );
      final svc = PdfParserService.forTest(
        supabase: supa,
        uploader: _FakeUploader().upload,
      );
      final r = await svc.uploadAndParse(
        bytes: _bytes(),
        filename: 'x.pdf',
        mimeType: 'application/pdf',
        activeCaseId: _validCaseId,
      );
      expect(r, isA<ParsedUnreadable>());
    });

    test('Unauthorized error string → ParsedForbidden', () async {
      final supa = _FakeSupabaseService(
        response: {'error': 'Unauthorized'},
      );
      final svc = PdfParserService.forTest(
        supabase: supa,
        uploader: _FakeUploader().upload,
      );
      final r = await svc.uploadAndParse(
        bytes: _bytes(),
        filename: 'x.pdf',
        mimeType: 'application/pdf',
        activeCaseId: _validCaseId,
      );
      expect(r, isA<ParsedForbidden>());
    });
  });

  group('PdfParserService.uploadAndParse — provider invalidation', () {
    test('invalidates caseByIdProvider + casesListProvider on parsed success',
        () async {
      final repo = _FakeCaseRepository([_stubCase(_validCaseId)]);
      final supa = _FakeSupabaseService(response: _okResponse());

      final container = ProviderContainer(overrides: [
        caseRepositoryProvider.overrideWithValue(repo),
        supabaseServiceProvider.overrideWithValue(supa),
        pdfParserServiceProvider.overrideWith(
          (ref) => PdfParserService(
            supabase: supa,
            ref: ref,
            uploader: _FakeUploader().upload,
          ),
        ),
      ]);
      addTearDown(container.dispose);

      // Prime providers.
      await container.read(caseByIdProvider(_validCaseId).future);
      await container.read(casesListProvider(CaseListFilter.active).future);
      final beforeGet = repo.getCallCount;
      final beforeList = repo.listCallCount;

      final svc = container.read(pdfParserServiceProvider);
      final r = await svc.uploadAndParse(
        bytes: _bytes(),
        filename: 'x.pdf',
        mimeType: 'application/pdf',
        activeCaseId: _validCaseId,
      );
      expect(r, isA<ParsedOk>());

      // Re-read — invalidation should have cleared cached results.
      await container.read(caseByIdProvider(_validCaseId).future);
      await container.read(casesListProvider(CaseListFilter.active).future);
      expect(repo.getCallCount, beforeGet + 1,
          reason: 'caseByIdProvider should have been invalidated');
      expect(repo.listCallCount, beforeList + 1,
          reason: 'casesListProvider should have been invalidated');
    });

    test('does NOT invalidate when activeCaseId is null', () async {
      final repo = _FakeCaseRepository([_stubCase(_validCaseId)]);
      // Server returns docId='' for the no-case path.
      final supa = _FakeSupabaseService(response: _okResponse(docId: ''));

      final container = ProviderContainer(overrides: [
        caseRepositoryProvider.overrideWithValue(repo),
        supabaseServiceProvider.overrideWithValue(supa),
        pdfParserServiceProvider.overrideWith(
          (ref) => PdfParserService(
            supabase: supa,
            ref: ref,
            uploader: _FakeUploader().upload,
          ),
        ),
      ]);
      addTearDown(container.dispose);

      // Prime providers.
      await container.read(caseByIdProvider(_validCaseId).future);
      await container.read(casesListProvider(CaseListFilter.active).future);
      final beforeGet = repo.getCallCount;
      final beforeList = repo.listCallCount;

      final svc = container.read(pdfParserServiceProvider);
      await svc.uploadAndParse(
        bytes: _bytes(),
        filename: 'x.pdf',
        mimeType: 'application/pdf',
      );

      // Re-read — invalidation should NOT have happened (no case to refresh).
      await container.read(caseByIdProvider(_validCaseId).future);
      await container.read(casesListProvider(CaseListFilter.active).future);
      expect(repo.getCallCount, beforeGet,
          reason: 'should NOT invalidate when there is no active case');
      expect(repo.listCallCount, beforeList,
          reason: 'should NOT invalidate when there is no active case');
    });
  });
}
