// vault_service_test.dart — unit tests for the Vault UI service interface.
// -----------------------------------------------------------------------------
// Covers the surface the UI calls through:
//   * getDocuments({tagFilter}) — tag filter respected, "other" matches null.
//   * search() — empty query falls through to getDocuments.
//   * deleteDocument() — fake forwards the call.
//   * tagDocument() — fake stores the tuple.
//   * getTags() — defaults available when backend silent.
//
// The class under test is a small abstraction; we use a hand-rolled fake
// rather than mocking the Supabase client so the tests run without any
// network / SDK stubs (matches the pattern used in
// test/features/drafting/draft_service_test.dart).
// -----------------------------------------------------------------------------

@Tags(['fast'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/vault/models/vault_document.dart';
import 'package:advocat/features/vault/services/vault_service.dart';
import 'package:flutter/foundation.dart';

class _FakeVaultService implements VaultService {
  _FakeVaultService(this._seed);

  final List<VaultDocument> _seed;
  final List<String> deletes = <String>[];
  final List<(String, String)> tags = <(String, String)>[];

  @override
  Future<List<VaultDocument>> getDocuments({String? tagFilter}) async {
    if (tagFilter == null) return _seed;
    if (tagFilter == 'other') {
      return _seed
          .where((d) => d.tagSlug == null || d.tagSlug == 'other')
          .toList();
    }
    return _seed.where((d) => d.tagSlug == tagFilter).toList();
  }

  @override
  Future<List<VaultDocument>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getDocuments();
    return _seed
        .where((d) => d.fileName.toLowerCase().contains(q))
        .toList();
  }

  @override
  Future<void> deleteDocument(String id) async {
    deletes.add(id);
    _seed.removeWhere((d) => d.id == id);
  }

  @override
  Future<void> tagDocument(String docId, String tagId) async {
    tags.add((docId, tagId));
  }

  @override
  Future<List<VaultTag>> getTags() async => VaultTag.defaults;

  @override
  Future<VaultUploadResult> uploadFromDraft({
    required String draftId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    String? caseId,
  }) async {
    return VaultUploadResult(
      documentId: 'fake-$draftId',
      storagePath: 'fake/$draftId/$fileName',
      fileName: fileName,
      mimeType: mimeType,
    );
  }

  @override
  Future<VaultContent?> fetchDecryptedContent(String documentId) async => null;

  @override
  Future<String?> ensureDraftSystemTag() async => 'draft-tag-id';
}

VaultDocument _doc({
  required String id,
  String fileName = 'file.pdf',
  String? tagSlug,
}) {
  return VaultDocument(
    id: id,
    fileName: fileName,
    storagePath: 'u/c/$fileName',
    mimeType: 'application/pdf',
    createdAt: DateTime.utc(2026, 1, 1),
    tagSlug: tagSlug,
  );
}

void main() {
  group('VaultDocument.fromJson', () {
    test('parses a minimal documents row', () {
      final d = VaultDocument.fromJson({
        'id': 'abc',
        'file_name': 'evidence.pdf',
        'storage_path': 'u/c/evidence.pdf',
        'mime_type': 'application/pdf',
        'created_at': '2026-05-27T10:00:00Z',
      });
      expect(d.id, 'abc');
      expect(d.fileName, 'evidence.pdf');
      expect(d.tagSlug, isNull);
      expect(d.encrypted, isFalse);
    });

    test('parses joined tag columns when present', () {
      final d = VaultDocument.fromJson({
        'id': 'abc',
        'file_name': 'lease.pdf',
        'storage_path': 'u/c/lease.pdf',
        'mime_type': 'application/pdf',
        'created_at': '2026-05-27T10:00:00Z',
        'tag_id': 't1',
        'tag_slug': 'contract',
        'tag_label': 'Contract',
        'encrypted': true,
      });
      expect(d.tagSlug, 'contract');
      expect(d.tagLabel, 'Contract');
      expect(d.encrypted, isTrue);
    });

    test('tolerates malformed created_at by falling back to epoch zero', () {
      final d = VaultDocument.fromJson({
        'id': 'abc',
        'file_name': 'x.pdf',
        'storage_path': 'u/c/x.pdf',
        'mime_type': 'application/pdf',
        'created_at': 'not-a-date',
      });
      expect(d.createdAt.millisecondsSinceEpoch, 0);
    });
  });

  group('VaultService (fake) — surface', () {
    test('getDocuments() without filter returns full list', () async {
      final svc = _FakeVaultService(<VaultDocument>[
        _doc(id: '1', tagSlug: 'contract'),
        _doc(id: '2', tagSlug: 'receipt'),
      ]);
      final all = await svc.getDocuments();
      expect(all.map((d) => d.id), ['1', '2']);
    });

    test('getDocuments(tagFilter: contract) filters by slug', () async {
      final svc = _FakeVaultService(<VaultDocument>[
        _doc(id: '1', tagSlug: 'contract'),
        _doc(id: '2', tagSlug: 'receipt'),
        _doc(id: '3', tagSlug: 'contract'),
      ]);
      final hits = await svc.getDocuments(tagFilter: 'contract');
      expect(hits.map((d) => d.id), ['1', '3']);
    });

    test('getDocuments(tagFilter: other) matches null + "other"', () async {
      final svc = _FakeVaultService(<VaultDocument>[
        _doc(id: '1', tagSlug: 'contract'),
        _doc(id: '2'), // null
        _doc(id: '3', tagSlug: 'other'),
      ]);
      final hits = await svc.getDocuments(tagFilter: 'other');
      expect(hits.map((d) => d.id), ['2', '3']);
    });

    test('search() with empty query falls through to getDocuments', () async {
      final svc = _FakeVaultService(<VaultDocument>[
        _doc(id: '1'),
        _doc(id: '2'),
      ]);
      final hits = await svc.search('   ');
      expect(hits.length, 2);
    });

    test('search() matches filenames case-insensitively', () async {
      final svc = _FakeVaultService(<VaultDocument>[
        _doc(id: '1', fileName: 'Lease.pdf'),
        _doc(id: '2', fileName: 'invoice.pdf'),
      ]);
      final hits = await svc.search('LEASE');
      expect(hits.map((d) => d.id), ['1']);
    });

    test('deleteDocument() removes the doc', () async {
      final svc = _FakeVaultService(<VaultDocument>[
        _doc(id: 'keep'),
        _doc(id: 'drop'),
      ]);
      await svc.deleteDocument('drop');
      expect(svc.deletes, ['drop']);
      final remaining = await svc.getDocuments();
      expect(remaining.map((d) => d.id), ['keep']);
    });

    test('tagDocument() records the (doc,tag) tuple', () async {
      final svc = _FakeVaultService(<VaultDocument>[_doc(id: '1')]);
      await svc.tagDocument('1', 'contract');
      expect(svc.tags, [('1', 'contract')]);
    });

    test('getTags() falls back to defaults when backend silent', () async {
      final svc = _FakeVaultService(<VaultDocument>[]);
      final tags = await svc.getTags();
      expect(tags.length, VaultTag.defaults.length);
      expect(tags.map((t) => t.slug),
          containsAll(['contract', 'receipt', 'email', 'evidence',
            'id_passport', 'other']));
    });
  });

  group('VaultTag.defaults', () {
    test('has exactly six entries in stable order', () {
      expect(VaultTag.defaults.length, 6);
      expect(VaultTag.defaults.first.slug, 'contract');
      expect(VaultTag.defaults.last.slug, 'other');
    });

    test('slugs are unique', () {
      final slugs = VaultTag.defaults.map((t) => t.slug).toList();
      expect(slugs.toSet().length, slugs.length);
    });
  });

  // Sanity — verify the test harness picks up flutter/foundation symbols.
  test('debug-mode flag accessible from tests', () {
    expect(kDebugMode, isA<bool>());
  });
}
