import 'dart:typed_data';

import 'package:advocat/features/case_memory/data/case_repository.dart';
import 'package:advocat/features/case_memory/models/case_document.dart';
import 'package:advocat/features/case_memory/models/user_case.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory [CaseRepository] used by upstream tests (state, screens).
/// We test it here as a contract suite: any new repo implementation can
/// reuse the same suite to prove behavioural parity.
class FakeCaseRepository implements CaseRepository {
  FakeCaseRepository({this.cases = const [], this.documents = const []});

  List<UserCase> cases;
  List<CaseDocument> documents;
  Exception? raiseOnList;
  Exception? raiseOnCreate;
  Exception? raiseOnUpdate;
  Exception? raiseOnArchive;
  Exception? raiseOnUpload;

  // Spies for assertion.
  CaseListFilter? lastListFilter;
  String? lastGetId;
  Map<String, dynamic>? lastCreatePayload;
  UserCase? lastUpdatePayload;
  String? lastArchiveId;
  String? lastCloseId;
  String? lastListDocumentsCaseId;
  final List<Map<String, Object?>> uploadedPayloads = [];

  @override
  Future<List<UserCase>> listCases({
    CaseListFilter filter = CaseListFilter.active,
  }) async {
    lastListFilter = filter;
    if (raiseOnList != null) throw raiseOnList!;
    if (filter == CaseListFilter.all) return List.of(cases);
    return cases.where((c) => c.status.dbValue == filter.value).toList();
  }

  @override
  Future<UserCase?> getCase(String id) async {
    lastGetId = id;
    return cases.firstWhere((c) => c.id == id, orElse: () => _missing());
  }

  static UserCase _missing() {
    throw StateError('case not found in fake');
  }

  @override
  Future<UserCase> createCase({
    required String title,
    required String jurisdiction,
    String? caseType,
    String language = 'ru',
  }) async {
    lastCreatePayload = {
      'title': title,
      'jurisdiction': jurisdiction,
      'case_type': caseType,
      'language': language,
    };
    if (raiseOnCreate != null) throw raiseOnCreate!;
    final now = DateTime.utc(2026, 5, 5, 12);
    final created = UserCase(
      id: 'new-${cases.length + 1}',
      userId: 'user-1',
      title: title,
      jurisdiction: jurisdiction,
      caseType: caseType,
      language: language,
      createdAt: now,
      updatedAt: now,
    );
    cases = [...cases, created];
    return created;
  }

  @override
  Future<UserCase> updateCase(UserCase updated) async {
    lastUpdatePayload = updated;
    if (raiseOnUpdate != null) throw raiseOnUpdate!;
    cases = cases.map((c) => c.id == updated.id ? updated : c).toList();
    return updated;
  }

  @override
  Future<void> archiveCase(String id) async {
    lastArchiveId = id;
    if (raiseOnArchive != null) throw raiseOnArchive!;
    cases = cases
        .map((c) =>
            c.id == id ? c.copyWith(status: CaseMemoryStatus.archived) : c)
        .toList();
  }

  @override
  Future<void> closeCase(String id) async {
    lastCloseId = id;
    cases = cases
        .map((c) =>
            c.id == id ? c.copyWith(status: CaseMemoryStatus.closed) : c)
        .toList();
  }

  @override
  Future<List<CaseDocument>> listDocuments(String caseId) async {
    lastListDocumentsCaseId = caseId;
    return documents.where((d) => d.caseId == caseId).toList();
  }

  @override
  Future<String> uploadDocument({
    required String caseId,
    required String filename,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    if (raiseOnUpload != null) throw raiseOnUpload!;
    uploadedPayloads.add({
      'caseId': caseId,
      'filename': filename,
      'sizeBytes': bytes.length,
      'mimeType': mimeType,
    });
    final id = 'doc-${uploadedPayloads.length}';
    documents = [
      ...documents,
      CaseDocument(
        id: id,
        caseId: caseId,
        userId: 'user-1',
        filename: filename,
        storagePath: 'fake/$caseId/$filename',
        mimeType: mimeType,
        sizeBytes: bytes.length,
        uploadedAt: DateTime.utc(2026, 5, 5, 12),
      ),
    ];
    return id;
  }
}

UserCase _mkCase({
  String id = 'c-1',
  String title = 'Test',
  String jurisdiction = 'EE',
  String? caseType = 'civil',
  CaseMemoryStatus status = CaseMemoryStatus.active,
  DateTime? updatedAt,
}) {
  final now = DateTime.utc(2026, 5, 5, 12);
  return UserCase(
    id: id,
    userId: 'user-1',
    title: title,
    jurisdiction: jurisdiction,
    caseType: caseType,
    status: status,
    createdAt: now,
    updatedAt: updatedAt ?? now,
  );
}

void main() {
  group('CaseRepository contract — listCases', () {
    test('default filter is active', () async {
      final repo = FakeCaseRepository(cases: [
        _mkCase(id: 'a', status: CaseMemoryStatus.active),
        _mkCase(id: 'b', status: CaseMemoryStatus.archived),
      ]);
      final list = await repo.listCases();
      expect(repo.lastListFilter, CaseListFilter.active);
      expect(list.map((c) => c.id), ['a']);
    });

    test('filter=archived returns only archived', () async {
      final repo = FakeCaseRepository(cases: [
        _mkCase(id: 'a', status: CaseMemoryStatus.active),
        _mkCase(id: 'b', status: CaseMemoryStatus.archived),
      ]);
      final list = await repo.listCases(filter: CaseListFilter.archived);
      expect(list.map((c) => c.id), ['b']);
    });

    test('filter=all returns everything', () async {
      final repo = FakeCaseRepository(cases: [
        _mkCase(id: 'a', status: CaseMemoryStatus.active),
        _mkCase(id: 'b', status: CaseMemoryStatus.closed),
      ]);
      final list = await repo.listCases(filter: CaseListFilter.all);
      expect(list, hasLength(2));
    });

    test('rethrows backend error', () async {
      final repo = FakeCaseRepository()..raiseOnList = Exception('network');
      expect(repo.listCases(), throwsA(isA<Exception>()));
    });
  });

  group('CaseRepository contract — createCase', () {
    test('returns case with generated id and provided fields', () async {
      final repo = FakeCaseRepository();
      final c = await repo.createCase(
        title: 'My Sulga case',
        jurisdiction: 'FI',
        caseType: 'deportation',
        language: 'ru',
      );
      expect(c.id, isNotEmpty);
      expect(c.title, 'My Sulga case');
      expect(c.jurisdiction, 'FI');
      expect(c.caseType, 'deportation');
      expect(c.language, 'ru');
    });

    test('omits case_type when null', () async {
      final repo = FakeCaseRepository();
      await repo.createCase(title: 'T', jurisdiction: 'EE');
      expect(repo.lastCreatePayload!['case_type'], isNull);
    });

    test('rethrows backend error', () async {
      final repo = FakeCaseRepository()..raiseOnCreate = Exception('boom');
      expect(
        repo.createCase(title: 't', jurisdiction: 'EE'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('CaseRepository contract — updateCase', () {
    test('replaces matching case in store', () async {
      final repo = FakeCaseRepository(cases: [_mkCase(id: 'c-1', title: 'A')]);
      final updated = (await repo.listCases()).first.copyWith(title: 'B');
      final back = await repo.updateCase(updated);
      expect(back.title, 'B');
      final after = await repo.listCases();
      expect(after.single.title, 'B');
    });
  });

  group('CaseRepository contract — archiveCase', () {
    test('flips status to archived', () async {
      final repo = FakeCaseRepository(cases: [_mkCase(id: 'c-1')]);
      await repo.archiveCase('c-1');
      final all = await repo.listCases(filter: CaseListFilter.all);
      expect(all.single.status, CaseMemoryStatus.archived);
    });
  });

  group('CaseRepository contract — listDocuments', () {
    test('filters by case id', () async {
      final docs = [
        CaseDocument(
          id: 'd-1',
          caseId: 'c-1',
          userId: 'u',
          filename: 'a.pdf',
          storagePath: 'p',
          uploadedAt: DateTime.utc(2026, 5, 5),
        ),
        CaseDocument(
          id: 'd-2',
          caseId: 'c-2',
          userId: 'u',
          filename: 'b.pdf',
          storagePath: 'p',
          uploadedAt: DateTime.utc(2026, 5, 5),
        ),
      ];
      final repo = FakeCaseRepository(documents: docs);
      final list = await repo.listDocuments('c-1');
      expect(list.single.id, 'd-1');
      expect(repo.lastListDocumentsCaseId, 'c-1');
    });
  });
}
