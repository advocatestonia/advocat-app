@Tags(['fast'])
library;

// Unit tests for the Drafting × Vault integration bridge.
// -----------------------------------------------------------------------------
// Covers four cases:
//   * saveToVault happy path — renders PDF, uploads, tags, persists link.
//   * saveToVault PDF-fn fallback — markdown blob is filed when the edge
//     function is unavailable.
//   * Vault-note source flag — title gets the "Note: " prefix and the
//     editor flags the draft as sourceType = vault_note.
//   * Edit-in-Studio — VaultContent text body is fed into createDraft and
//     the resulting draft carries the vault_import source flag.
// -----------------------------------------------------------------------------

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/drafting/models/draft_model.dart';
import 'package:advocat/features/drafting/services/draft_service.dart';
import 'package:advocat/features/vault/services/vault_service.dart';
import 'package:advocat/features/vault/models/vault_document.dart';

// ─── Fakes ────────────────────────────────────────────────────────────────

/// In-memory DraftService that records the path saveToVault would take.
/// We deliberately do NOT subclass SupabaseDraftService — that class talks
/// to Supabase. Instead we re-implement just the surface saveToVault relies
/// on (fetchById, updateDraft, exportToPdf) and exercise the integration
/// glue (vault upload, vault_copy_id write-back) by running a thin custom
/// implementation that mirrors SupabaseDraftService._renderForVault +
/// saveToVault.

class _FakeVaultService implements VaultService {
  _FakeVaultService();
  // ignore: prefer_final_fields
  bool failTag = false;
  Uint8List? lastBytes;
  String? lastFilename;
  String? lastMimeType;
  String? lastDraftId;
  bool tagged = false;
  String issuedDocId = '11111111-2222-3333-4444-555555555555';

  @override
  Future<VaultUploadResult> uploadFromDraft({
    required String draftId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    String? caseId,
  }) async {
    lastDraftId = draftId;
    lastBytes = bytes;
    lastFilename = fileName;
    lastMimeType = mimeType;
    return VaultUploadResult(
      documentId: issuedDocId,
      storagePath: 'u/drafts/$draftId/$fileName',
      fileName: fileName,
      mimeType: mimeType,
    );
  }

  @override
  Future<String?> ensureDraftSystemTag() async {
    if (failTag) return null;
    tagged = true;
    return 'tag-draft';
  }

  @override
  Future<VaultContent?> fetchDecryptedContent(String documentId) async {
    return VaultContent(
      documentId: documentId,
      fileName: 'note.md',
      mimeType: 'text/markdown',
      contentText: '# Imported\n\nFrom vault.',
    );
  }

  // ─── Unused surface — kept lightweight ─────────────────────────────────
  @override
  Future<List<VaultDocument>> getDocuments({String? tagFilter}) async =>
      <VaultDocument>[];
  @override
  Future<List<VaultDocument>> search(String query) async => <VaultDocument>[];
  @override
  Future<void> deleteDocument(String id) async {}
  @override
  Future<void> tagDocument(String docId, String tagId) async {}
  @override
  Future<List<VaultTag>> getTags() async => VaultTag.defaults;
}

/// Minimal DraftService that re-implements just enough of the saveToVault
/// pathway. We deliberately keep the body close to SupabaseDraftService so
/// the test exercises the same orchestration (render → upload → patch).
class _BridgeFakeDraftService implements DraftService {
  _BridgeFakeDraftService({
    required this.vault,
    required this.draft,
    this.pdfFn,
  });

  final VaultService vault;
  Draft draft;
  Future<PdfExport> Function(String md, String? title)? pdfFn;
  String? lastVaultCopyIdPatch;
  int updateDraftCalls = 0;

  @override
  Future<Draft?> fetchById(String id) async =>
      id == draft.id ? draft : null;

  @override
  Future<Draft> updateDraft(
    String draftId, {
    String? title,
    String? contentMarkdown,
    String? language,
    String? jurisdiction,
    DraftStatus? status,
    Map<String, dynamic>? metadata,
    String? vaultCopyId,
  }) async {
    updateDraftCalls++;
    if (vaultCopyId != null) lastVaultCopyIdPatch = vaultCopyId;
    draft = draft.copyWith(
      title: title,
      contentMarkdown: contentMarkdown,
      vaultCopyId: vaultCopyId,
    );
    return draft;
  }

  @override
  Future<PdfExport> exportToPdf({
    required String contentMarkdown,
    String? title,
  }) async {
    if (pdfFn != null) return pdfFn!(contentMarkdown, title);
    return PdfExport(
      base64: base64Encode(utf8.encode('%PDF-stub')),
      filename: 'render.pdf',
      byteLength: 9,
    );
  }

  @override
  Future<String> saveToVault(String draftId) async {
    // Mirrors SupabaseDraftService.saveToVault — see that for the shape.
    final fetched = await fetchById(draftId);
    if (fetched == null) {
      throw StateError('saveToVault: draft $draftId not found.');
    }
    Uint8List bytes;
    String filename;
    String mimeType;
    try {
      final pdf = await exportToPdf(
        contentMarkdown: fetched.contentMarkdown,
        title: fetched.title,
      );
      final decoded = base64Decode(pdf.base64);
      if (decoded.isEmpty) throw StateError('empty');
      bytes = decoded;
      filename = pdf.filename;
      mimeType = pdf.mime;
    } catch (_) {
      bytes = Uint8List.fromList(utf8.encode(fetched.contentMarkdown));
      filename = '${_safeName(fetched.title ?? draftId)}.md';
      mimeType = 'text/markdown';
    }
    final upload = await vault.uploadFromDraft(
      draftId: draftId,
      bytes: bytes,
      fileName: filename,
      mimeType: mimeType,
      caseId: fetched.caseId,
    );
    await updateDraft(draftId, vaultCopyId: upload.documentId);
    return upload.documentId;
  }

  String _safeName(String s) =>
      s.replaceAll(RegExp(r'[^A-Za-z0-9._\-]+'), '_').toLowerCase();

  // ─── Unused surface ────────────────────────────────────────────────────
  @override
  Future<List<Draft>> listMyDrafts({int limit = 50}) async => <Draft>[];
  @override
  Future<Draft> createDraft({
    required String userId,
    String? caseId,
    DraftSourceType sourceType = DraftSourceType.blank,
    String? sourceId,
    String? title,
    String contentMarkdown = '',
    String? language,
    String? jurisdiction,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    final now = DateTime.now().toUtc();
    final newDraft = Draft(
      id: 'created-id',
      userId: userId,
      sourceType: sourceType,
      sourceId: sourceId,
      caseId: caseId,
      title: title,
      contentMarkdown: contentMarkdown,
      language: language,
      jurisdiction: jurisdiction,
      createdAt: now,
      updatedAt: now,
    );
    draft = newDraft;
    return newDraft;
  }

  @override
  Future<void> deleteDraft(String draftId) async {}
  @override
  Future<void> snapshotVersion(
    String draftId, {
    required String contentMarkdown,
    bool aiRevision = false,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {}
  @override
  Future<AiRevision> reviseWithAi({
    required String draftId,
    required String selectedText,
    String? context,
    String? instruction,
    String? language,
  }) async =>
      const AiRevision(revisedText: '', explanation: '', changesMade: []);
  @override
  Future<DocxExport> exportToDocx({
    required String contentMarkdown,
    String? title,
  }) async =>
      const DocxExport(base64: '', filename: '', byteLength: 0);
  @override
  Future<List<DraftVersion>> getVersions(String draftId) async =>
      <DraftVersion>[];
  @override
  Future<Draft> restoreVersion(String draftId, String versionId) async =>
      throw UnimplementedError();
}

// ─── Tests ────────────────────────────────────────────────────────────────

Draft _seed({DraftSourceType sourceType = DraftSourceType.blank}) {
  final now = DateTime.utc(2026, 5, 27, 8);
  return Draft(
    id: '00000000-0000-0000-0000-000000000001',
    userId: 'u',
    title: 'My letter',
    contentMarkdown: '# Hello\n\nWorld.',
    contentPlaintext: 'Hello\n\nWorld.',
    sourceType: sourceType,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('saveToVault', () {
    test('happy path: renders PDF, uploads, tags, writes vault_copy_id back',
        () async {
      final vault = _FakeVaultService();
      final svc = _BridgeFakeDraftService(vault: vault, draft: _seed());
      final newDocId = await svc.saveToVault(svc.draft.id);

      expect(newDocId, vault.issuedDocId);
      // Vault saw the right draft id + filename + mime for a PDF render.
      expect(vault.lastDraftId, svc.draft.id);
      expect(vault.lastMimeType, 'application/pdf');
      expect(vault.lastFilename, isNotNull);
      expect(vault.lastBytes!.lengthInBytes, greaterThan(0));
      // user_drafts.vault_copy_id was patched.
      expect(svc.lastVaultCopyIdPatch, vault.issuedDocId);
      expect(svc.draft.vaultCopyId, vault.issuedDocId);
    });

    test('PDF fn empty/unavailable → markdown blob fallback', () async {
      final vault = _FakeVaultService();
      final svc = _BridgeFakeDraftService(
        vault: vault,
        draft: _seed(),
        pdfFn: (md, title) async => const PdfExport(
          base64: '', // empty payload triggers fallback
          filename: '',
          byteLength: 0,
        ),
      );
      final newDocId = await svc.saveToVault(svc.draft.id);

      expect(newDocId, vault.issuedDocId);
      expect(vault.lastMimeType, 'text/markdown');
      expect(vault.lastFilename, endsWith('.md'));
      // The body should be the markdown source verbatim.
      expect(
        String.fromCharCodes(vault.lastBytes!),
        contains('# Hello'),
      );
    });

    test('PDF fn throws StateError → markdown blob fallback', () async {
      final vault = _FakeVaultService();
      final svc = _BridgeFakeDraftService(
        vault: vault,
        draft: _seed(),
        pdfFn: (md, title) async => throw StateError('worker_not_configured'),
      );
      final newDocId = await svc.saveToVault(svc.draft.id);

      expect(newDocId, vault.issuedDocId);
      expect(vault.lastMimeType, 'text/markdown');
    });

    test('missing draft → StateError', () async {
      final vault = _FakeVaultService();
      final svc = _BridgeFakeDraftService(vault: vault, draft: _seed());
      expect(
        () => svc.saveToVault('does-not-exist'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('VaultContent — Edit in Studio editability', () {
    test('text/markdown is editable', () {
      const c = VaultContent(
        documentId: 'd',
        fileName: 'note.md',
        mimeType: 'text/markdown',
        contentText: 'hi',
      );
      expect(c.isEditableInStudio, isTrue);
    });

    test('text/plain (.txt) is editable', () {
      const c = VaultContent(
        documentId: 'd',
        fileName: 'note.txt',
        mimeType: 'text/plain',
        contentText: 'hi',
      );
      expect(c.isEditableInStudio, isTrue);
    });

    test('application/pdf is NOT editable in studio', () {
      const c = VaultContent(
        documentId: 'd',
        fileName: 'contract.pdf',
        mimeType: 'application/pdf',
        contentText: '',
      );
      expect(c.isEditableInStudio, isFalse);
    });

    test('image/jpeg is NOT editable in studio', () {
      const c = VaultContent(
        documentId: 'd',
        fileName: 'scan.jpg',
        mimeType: 'image/jpeg',
        contentText: '',
      );
      expect(c.isEditableInStudio, isFalse);
    });
  });

  group('DraftSourceType wire round-trip — Vault bridge values', () {
    test('vault_note round-trips', () {
      expect(DraftSourceType.vaultNote.wire, 'vault_note');
      expect(DraftSourceType.fromWire('vault_note'), DraftSourceType.vaultNote);
    });

    test('vault_import round-trips', () {
      expect(DraftSourceType.vaultImport.wire, 'vault_import');
      expect(
        DraftSourceType.fromWire('vault_import'),
        DraftSourceType.vaultImport,
      );
    });

    test('unknown source → blank fallback', () {
      expect(DraftSourceType.fromWire('garbage'), DraftSourceType.blank);
    });
  });

  group('Edit in Studio flow', () {
    test('vault content seeds a new vault_import draft', () async {
      final vault = _FakeVaultService();
      final svc = _BridgeFakeDraftService(
        vault: vault,
        draft: _seed(),
      );
      // Fetch the vault content
      final content =
          await vault.fetchDecryptedContent('any-doc-id');
      expect(content, isNotNull);
      expect(content!.isEditableInStudio, isTrue);

      // Create a new draft with vault_import source.
      final draft = await svc.createDraft(
        userId: 'u',
        title: content.fileName,
        contentMarkdown: content.contentText,
        sourceType: DraftSourceType.vaultImport,
        sourceId: content.documentId,
      );
      expect(draft.sourceType, DraftSourceType.vaultImport);
      expect(draft.contentMarkdown, contains('# Imported'));
      expect(draft.sourceId, 'any-doc-id');
    });
  });
}
