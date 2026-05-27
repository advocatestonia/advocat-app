// features/vault/services/vault_service.dart — Document Vault service layer.
// -----------------------------------------------------------------------------
// Thin wrapper around the Supabase client for the Vault screens.
//
// Backend contract (implemented in parallel by another agent):
//   * `documents` table — owner-scoped via RLS, holds storage_path metadata.
//   * `vault_tags` table — id, slug, label, owner_id (nullable for defaults).
//   * `vault_document_tags` table — (document_id, tag_id) join.
//   * `vault.search_documents(query)` RPC — owner-scoped full-text search,
//     returns the same row shape as `documents` plus joined tag columns.
//   * `vault-upload` edge fn — handles client-side encryption hand-off (not
//     wired here yet — uploads still go through SupabaseService directly).
//
// Until those land we degrade gracefully:
//   * `getTags()` falls back to [VaultTag.defaults] if the table is empty
//     or absent (PostgrestException 42P01).
//   * `search()` falls back to a client-side filename match if the RPC is
//     missing.
//   * `tagDocument()` is a best-effort write — failure is logged but not
//     fatal; the UI shows the file in "Other" until the backend is live.
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_service.dart';
import '../models/vault_document.dart';

/// Riverpod hook — overridable in tests via `vaultServiceProvider.overrideWith`.
final vaultServiceProvider = Provider<VaultService>((ref) {
  return VaultService(ref.watch(supabaseServiceProvider));
});

/// Interface so widget tests can substitute a fake.
abstract class VaultService {
  factory VaultService(SupabaseService svc) = _SupabaseVaultService;

  /// All documents owned by the current user, newest first. If [tagFilter]
  /// is provided, only documents tagged with that slug are returned.
  Future<List<VaultDocument>> getDocuments({String? tagFilter});

  /// Full-text search across the current user's vault. Empty / blank
  /// queries return the unfiltered list (same as [getDocuments]).
  Future<List<VaultDocument>> search(String query);

  /// Hard-delete: removes the storage object and the metadata row. RLS
  /// guarantees only the owner can call this.
  Future<void> deleteDocument(String id);

  /// Attaches [tagId] to [docId]. Idempotent — re-tagging the same pair
  /// is a no-op on the backend (composite PK).
  Future<void> tagDocument(String docId, String tagId);

  /// All tags available to the current user. Defaults first, then any
  /// custom tags they have created (sorted by label).
  Future<List<VaultTag>> getTags();

  // ─── Drafting × Vault bridge ────────────────────────────────────────────
  //
  // Drafting Studio calls into these when a user files a draft into the
  // Vault (`Save to Vault` button) or opens a Vault note back in the editor
  // (`Edit in Studio`). Each method is best-effort with respect to the
  // Vault encryption / tagging schema — if the corresponding migration is
  // not yet deployed the upload still succeeds and the tag is silently
  // skipped. See `_safeTagDraft` for the swallowing logic.

  /// Stores [bytes] in the vault bucket and inserts a `documents` row.
  /// Tags the row with the per-user "Draft" system tag (or no-ops if the
  /// vault_tags table is not yet deployed). Returns the new document id.
  Future<VaultUploadResult> uploadFromDraft({
    required String draftId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    String? caseId,
  });

  /// Fetches a vault document's text body for re-import into Drafting Studio.
  /// Returns null for documents that don't exist. Binary types (PDF, etc.)
  /// return a [VaultContent] with empty `contentText`; callers should check
  /// `isEditableInStudio` before opening the editor.
  Future<VaultContent?> fetchDecryptedContent(String documentId);

  /// Idempotently ensures the per-user "Draft" system tag exists. Returns
  /// the tag id, or null when the vault_tags table is absent (Vault
  /// migration not landed yet).
  Future<String?> ensureDraftSystemTag();
}

/// Result of [VaultService.uploadFromDraft].
class VaultUploadResult {
  const VaultUploadResult({
    required this.documentId,
    required this.storagePath,
    required this.fileName,
    required this.mimeType,
  });

  final String documentId;
  final String storagePath;
  final String fileName;
  final String mimeType;
}

/// Vault content fetched for "Edit in Studio". `contentText` is empty for
/// binary documents — see [isEditableInStudio].
class VaultContent {
  const VaultContent({
    required this.documentId,
    required this.fileName,
    required this.mimeType,
    required this.contentText,
  });

  final String documentId;
  final String fileName;
  final String mimeType;
  final String contentText;

  /// True for vault docs we can round-trip back into the Drafting editor.
  /// PDFs and binary formats are excluded — we can't cleanly reverse
  /// PDF → markdown so the UI hides "Edit in Studio" for them.
  bool get isEditableInStudio {
    final n = fileName.toLowerCase();
    return mimeType.startsWith('text/') ||
        n.endsWith('.md') ||
        n.endsWith('.txt') ||
        n.endsWith('.markdown');
  }
}

class _SupabaseVaultService implements VaultService {
  _SupabaseVaultService(this._svc);

  final SupabaseService _svc;

  @override
  Future<List<VaultDocument>> getDocuments({String? tagFilter}) async {
    final rows = await _svc.getVaultDocuments();
    final all = rows.map(VaultDocument.fromJson).toList();
    if (tagFilter == null || tagFilter.isEmpty) return all;
    // Filter client-side: until vault_document_tags is wired into
    // getVaultDocuments the only docs that surface a slug are those the
    // search RPC has joined. Everything else falls under "other".
    return all.where((d) {
      if (tagFilter == 'other') {
        return d.tagSlug == null || d.tagSlug == 'other';
      }
      return d.tagSlug == tagFilter;
    }).toList();
  }

  @override
  Future<List<VaultDocument>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return getDocuments();
    final client = _clientOrNull();
    if (client == null) return _localFilter(q);
    try {
      // Backend agent ships this RPC. Until then we hit a 404 and fall
      // back to the local filter below.
      final response = await client.rpc(
        'vault_search_documents',
        params: <String, dynamic>{'query': q},
      );
      final list = (response as List?) ?? const [];
      return list
          .map((e) => VaultDocument.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[vault] search() RPC failed, falling back: $e\n$st');
      }
      return _localFilter(q);
    }
  }

  Future<List<VaultDocument>> _localFilter(String q) async {
    final docs = await getDocuments();
    final needle = q.toLowerCase();
    return docs.where((d) => d.fileName.toLowerCase().contains(needle)).toList();
  }

  @override
  Future<void> deleteDocument(String id) async {
    final client = _clientOrNull();
    if (client == null) return; // demo mode — nothing to do
    // Fetch storage_path first so we can drop the binary, then the row.
    final row = await client
        .from('documents')
        .select('storage_path')
        .eq('id', id)
        .maybeSingle();
    final storagePath = row?['storage_path'] as String?;
    if (storagePath != null && storagePath.isNotEmpty) {
      try {
        await client.storage.from('case-documents').remove([storagePath]);
      } catch (e) {
        // Storage delete is best-effort: orphan binaries are cleaned by the
        // backend reaper. We still want to delete the metadata row so the
        // doc disappears from the user's vault.
        if (kDebugMode) {
          debugPrint('[vault] storage.remove() failed for $storagePath: $e');
        }
      }
    }
    await client.from('documents').delete().eq('id', id);
  }

  @override
  Future<void> tagDocument(String docId, String tagId) async {
    final client = _clientOrNull();
    if (client == null) return;
    try {
      await client.from('vault_document_tags').upsert(<String, dynamic>{
        'document_id': docId,
        'tag_id': tagId,
      });
    } catch (e) {
      // Backend tables may not exist yet — log and move on. UI degrades
      // to "Other" filter until the migration lands.
      if (kDebugMode) {
        debugPrint('[vault] tagDocument($docId, $tagId) failed: $e');
      }
    }
  }

  @override
  Future<List<VaultTag>> getTags() async {
    final client = _clientOrNull();
    if (client == null) return VaultTag.defaults;
    try {
      final rows = await client.from('vault_tags').select().order('label');
      final list = (rows as List?) ?? const [];
      if (list.isEmpty) return VaultTag.defaults;
      return list
          .map((e) => VaultTag.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[vault] getTags() failed, using defaults: $e');
      }
      return VaultTag.defaults;
    }
  }

  /// Returns the underlying Supabase client, or null in demo / offline
  /// mode. Demo/offline is detected through [SupabaseService.isDemo] so the
  /// same guard everything else uses applies here.
  SupabaseClient? _clientOrNull() {
    if (_svc.isDemo) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // ─── Drafting × Vault bridge implementation ─────────────────────────────

  static const String _bucket = 'case-documents';
  static const String _draftTagSlug = 'draft';
  static const String _draftTagLabel = 'Draft';

  @override
  Future<VaultUploadResult> uploadFromDraft({
    required String draftId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    String? caseId,
  }) async {
    final client = _clientOrNull();
    if (client == null) {
      // Demo / offline mode — return a synthetic id so the Drafting UI
      // surfaces "Saved to Vault" without crashing. Nothing is persisted.
      return VaultUploadResult(
        documentId: 'demo-vault-${DateTime.now().millisecondsSinceEpoch}',
        storagePath: 'demo/$fileName',
        fileName: fileName,
        mimeType: mimeType,
      );
    }
    final uid = client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('uploadFromDraft: not authenticated');
    }

    // Storage layout: per-user "drafts/<draftId>" subtree so the Vault
    // agent's encryption hook can recognise draft-sourced uploads and so
    // the user can browse them as a logical folder.
    final storagePath = '$uid/drafts/$draftId/$fileName';
    await client.storage.from(_bucket).uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            contentType: mimeType,
            // Re-filing the same draft should replace the previous bytes
            // rather than accumulate dupes in the bucket.
            upsert: true,
          ),
        );

    final inserted = await client
        .from('documents')
        .insert(<String, dynamic>{
          if (caseId != null && _looksLikeUuid(caseId)) 'case_id': caseId,
          'user_id': uid,
          'file_name': fileName,
          'storage_path': storagePath,
          'mime_type': mimeType,
          'file_size_bytes': bytes.length,
        })
        .select()
        .single();

    final docId = inserted['id'] as String;
    await _safeTagDraft(docId);

    return VaultUploadResult(
      documentId: docId,
      storagePath: storagePath,
      fileName: fileName,
      mimeType: mimeType,
    );
  }

  @override
  Future<VaultContent?> fetchDecryptedContent(String documentId) async {
    final client = _clientOrNull();
    if (client == null) return null;
    final row = await client
        .from('documents')
        .select('id, file_name, storage_path, mime_type')
        .eq('id', documentId)
        .maybeSingle();
    if (row == null) return null;

    final fileName = (row['file_name'] as String?) ?? '';
    final mimeType = (row['mime_type'] as String?) ?? '';
    final storagePath = (row['storage_path'] as String?) ?? '';
    if (storagePath.isEmpty) return null;

    final isText = mimeType.startsWith('text/') ||
        fileName.toLowerCase().endsWith('.md') ||
        fileName.toLowerCase().endsWith('.txt') ||
        fileName.toLowerCase().endsWith('.markdown');
    if (!isText) {
      // Binary doc — caller filters these out via `isEditableInStudio`.
      return VaultContent(
        documentId: documentId,
        fileName: fileName,
        mimeType: mimeType,
        contentText: '',
      );
    }

    // TODO(vault-agent): once encryption-at-rest is wired we should call
    // through the decryption helper here. Until then the bucket is private
    // (RLS + service-role-only listing) and we read the plaintext bytes.
    final bytes = await client.storage.from(_bucket).download(storagePath);
    final text = String.fromCharCodes(bytes);
    return VaultContent(
      documentId: documentId,
      fileName: fileName,
      mimeType: mimeType,
      contentText: text,
    );
  }

  @override
  Future<String?> ensureDraftSystemTag() async {
    final client = _clientOrNull();
    if (client == null) return null;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      // Cheap path: tag already seeded by the migration trigger.
      final existing = await client
          .from('vault_tags')
          .select('id')
          .eq('user_id', uid)
          .eq('slug', _draftTagSlug)
          .maybeSingle();
      if (existing != null) return existing['id'] as String?;

      // Migration ran without the trigger / user signed up before the
      // back-fill — insert on-demand. ON CONFLICT shape is owned by the
      // Vault migration; we tolerate a unique-violation as success.
      try {
        final inserted = await client
            .from('vault_tags')
            .insert(<String, dynamic>{
              'user_id': uid,
              'slug': _draftTagSlug,
              'label': _draftTagLabel,
              'is_system': true,
            })
            .select('id')
            .single();
        return inserted['id'] as String?;
      } on PostgrestException catch (e) {
        if (e.code == '23505') {
          final row = await client
              .from('vault_tags')
              .select('id')
              .eq('user_id', uid)
              .eq('slug', _draftTagSlug)
              .maybeSingle();
          return row?['id'] as String?;
        }
        rethrow;
      }
    } on PostgrestException catch (e) {
      // 42P01 undefined_table — the Vault migration has not landed yet.
      // Treat as a soft no-op so the draft → vault upload still succeeds.
      if (e.code == '42P01') return null;
      rethrow;
    }
  }

  /// Tags [documentId] as a draft, swallowing "table not found" /
  /// duplicate-row errors so the upload path stays robust against partial
  /// Vault deploys.
  Future<void> _safeTagDraft(String documentId) async {
    try {
      final tagId = await ensureDraftSystemTag();
      if (tagId == null) return;
      await tagDocument(documentId, tagId);
    } catch (e) {
      // tagDocument already swallows, but belt-and-braces in case the
      // upstream Vault agent makes it stricter later.
      if (kDebugMode) {
        debugPrint('[vault] _safeTagDraft($documentId) failed: $e');
      }
    }
  }

  bool _looksLikeUuid(String s) {
    final r = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
      r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return r.hasMatch(s);
  }
}
