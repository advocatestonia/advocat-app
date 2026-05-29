// drafting/services/draft_service.dart — Pkg 7 Drafting Studio MVP.
// -----------------------------------------------------------------------------
// Thin CRUD layer over the `user_drafts` and `draft_versions` Postgres tables.
// All methods are RLS-protected on the server; this client wrapper just shapes
// the rows for the Flutter UI and centralises the autosave logic.
//
// Keeping IO behind a service interface lets widget tests inject a fake.
// -----------------------------------------------------------------------------

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../vault/services/vault_service.dart';
import '../models/draft_model.dart';

/// Provider for the default implementation. Tests can override via
/// `ref.read(draftServiceProvider.overrideWithValue(FakeDraftService()))`.
final draftServiceProvider = Provider<DraftService>((ref) {
  return SupabaseDraftService(
    vaultService: ref.watch(vaultServiceProvider),
  );
});

/// Public surface used by the UI. Pure async; no Riverpod state.
abstract class DraftService {
  /// Returns drafts owned by the current user, most-recent first.
  Future<List<Draft>> listMyDrafts({int limit = 50});

  /// Fetches a single draft by id. Returns null when not found / not yours.
  Future<Draft?> fetchById(String draftId);

  /// Creates a new draft and returns the persisted row.
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
  });

  /// Patches an existing draft. Rebuilds plaintext from markdown on the
  /// client so the index stays accurate even between autosaves.
  Future<Draft> updateDraft(
    String draftId, {
    String? title,
    String? contentMarkdown,
    String? language,
    String? jurisdiction,
    DraftStatus? status,
    Map<String, dynamic>? metadata,
    String? vaultCopyId,
  });

  /// Permanently deletes a draft. RLS prevents deleting other users' rows.
  Future<void> deleteDraft(String draftId);

  /// Snapshots the current draft body into `draft_versions`. The DB trigger
  /// caps history at the last 10 rows per draft.
  Future<void> snapshotVersion(
    String draftId, {
    required String contentMarkdown,
    bool aiRevision = false,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  });

  /// Lists historical snapshots for [draftId], newest first. Capped to 10
  /// rows by the trigger on `draft_versions`.
  Future<List<DraftVersion>> getVersions(String draftId);

  /// Atomically restores [versionId] into the draft body.
  ///
  /// 1. Snapshots the *current* draft body so the restore is reversible.
  /// 2. Reads the target version's `content_snapshot`.
  /// 3. Updates `user_drafts.content_markdown` (+ plaintext mirror).
  ///
  /// Returns the updated [Draft].
  Future<Draft> restoreVersion(String draftId, String versionId);

  /// Calls the `draft-ai-revise` Edge Function and returns the suggestion.
  Future<AiRevision> reviseWithAi({
    required String draftId,
    required String selectedText,
    String? context,
    String? instruction,
    String? language,
  });

  /// Calls `draft-export-docx` and returns the base64-encoded DOCX bytes
  /// plus a sanitised filename suggested by the server.
  Future<DocxExport> exportToDocx({
    required String contentMarkdown,
    String? title,
  });

  /// Calls `draft-export-pdf` and returns the base64-encoded PDF bytes plus
  /// a sanitised filename and the MIME the client should set on the share
  /// envelope. Throws [StateError] when the Typst worker is unavailable
  /// (HTTP 503 worker_not_configured) so the host screen can surface a
  /// clear "PDF export unavailable — try DOCX" message.
  Future<PdfExport> exportToPdf({
    required String contentMarkdown,
    String? title,
  });

  /// Files [draftId] into the encrypted Vault. Renders the markdown to PDF
  /// via the `draft-export-pdf` edge function (falls back to a `text/markdown`
  /// blob if the worker isn't deployed yet), uploads via
  /// `VaultService.uploadFromDraft`, tags the new doc with the "Draft" system
  /// tag, writes the resulting document id back onto
  /// `user_drafts.vault_copy_id`, and returns it.
  ///
  /// Throws [StateError] if the draft does not exist (or RLS denies it).
  Future<String> saveToVault(String draftId);
}

/// Result of a server-side DOCX export.
class DocxExport {
  const DocxExport({
    required this.base64,
    required this.filename,
    required this.byteLength,
  });
  final String base64;
  final String filename;
  final int byteLength;
}

/// Result of a server-side PDF export.
class PdfExport {
  const PdfExport({
    required this.base64,
    required this.filename,
    required this.byteLength,
    this.mime = 'application/pdf',
  });
  final String base64;
  final String filename;
  final int byteLength;
  final String mime;
}

/// Internal helper type returned by `_renderForVault`. Carries either real
/// PDF bytes (when `draft-export-pdf` succeeded) or a markdown-blob fallback
/// — `mimeType` distinguishes the two so the caller picks the right
/// extension when filing into the Vault.
class DraftRender {
  const DraftRender({
    required this.bytes,
    required this.filename,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String filename;
  final String mimeType;

  bool get isPdf => mimeType == 'application/pdf';
}

/// Production implementation backed by Supabase.
class SupabaseDraftService implements DraftService {
  SupabaseDraftService({
    SupabaseClient? client,
    Uuid? uuid,
    VaultService? vaultService,
  })  : _client = client ?? Supabase.instance.client,
        _uuid = uuid ?? const Uuid(),
        _vault = vaultService;

  final SupabaseClient _client;
  final Uuid _uuid;
  // Nullable so unit tests and the legacy default constructor stay valid —
  // saveToVault throws a clear error if it's missing rather than NPE.
  final VaultService? _vault;

  @override
  Future<List<Draft>> listMyDrafts({int limit = 50}) async {
    final rows = await _client
        .from('user_drafts')
        .select()
        .order('updated_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(Draft.fromJson)
        .toList(growable: false);
  }

  @override
  Future<Draft?> fetchById(String draftId) async {
    final row = await _client
        .from('user_drafts')
        .select()
        .eq('id', draftId)
        .maybeSingle();
    if (row == null) return null;
    return Draft.fromJson(row);
  }

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
    final id = _uuid.v4();
    final now = DateTime.now().toUtc();
    final row = <String, dynamic>{
      'id': id,
      'user_id': userId,
      'case_id': caseId,
      'source_type': sourceType.wire,
      'source_id': sourceId,
      'title': title,
      'content_markdown': contentMarkdown,
      'content_plaintext': markdownToPlaintext(contentMarkdown),
      'language': language,
      'jurisdiction': jurisdiction,
      'status': DraftStatus.draft.wire,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'metadata': metadata,
    };
    final inserted = await _client
        .from('user_drafts')
        .insert(row)
        .select()
        .single();
    return Draft.fromJson(inserted);
  }

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
    final patch = <String, dynamic>{};
    if (title != null) patch['title'] = title;
    if (contentMarkdown != null) {
      patch['content_markdown'] = contentMarkdown;
      patch['content_plaintext'] = markdownToPlaintext(contentMarkdown);
    }
    if (language != null) patch['language'] = language;
    if (jurisdiction != null) patch['jurisdiction'] = jurisdiction;
    if (status != null) patch['status'] = status.wire;
    if (metadata != null) patch['metadata'] = metadata;
    if (vaultCopyId != null) patch['vault_copy_id'] = vaultCopyId;
    final row = await _client
        .from('user_drafts')
        .update(patch)
        .eq('id', draftId)
        .select()
        .single();
    return Draft.fromJson(row);
  }

  @override
  Future<void> deleteDraft(String draftId) async {
    await _client.from('user_drafts').delete().eq('id', draftId);
  }

  @override
  Future<void> snapshotVersion(
    String draftId, {
    required String contentMarkdown,
    bool aiRevision = false,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    await _client.from('draft_versions').insert(<String, dynamic>{
      'draft_id': draftId,
      'content_snapshot': contentMarkdown,
      'ai_revision': aiRevision,
      'metadata': metadata,
    });
  }

  @override
  Future<List<DraftVersion>> getVersions(String draftId) async {
    final rows = await _client
        .from('draft_versions')
        .select()
        .eq('draft_id', draftId)
        .order('created_at', ascending: false);
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(DraftVersion.fromJson)
        .toList(growable: false);
  }

  @override
  Future<Draft> restoreVersion(String draftId, String versionId) async {
    // 1. Read the current draft body so we can snapshot it before overwriting.
    final current = await fetchById(draftId);
    if (current == null) {
      throw StateError('Draft $draftId not found (or RLS denied).');
    }
    // 2. Resolve the target version's snapshot. Filter by draft_id as well so
    //    a cross-draft id can't sneak through.
    final targetRow = await _client
        .from('draft_versions')
        .select()
        .eq('id', versionId)
        .eq('draft_id', draftId)
        .maybeSingle();
    if (targetRow == null) {
      throw StateError('Version $versionId not found for draft $draftId.');
    }
    final target = DraftVersion.fromJson(targetRow);
    // 3. Save a snapshot of the current state BEFORE we overwrite, so the
    //    restore is itself reversible. Tag the snapshot in metadata so the
    //    UI can mark it as "before restore" later if we want.
    await snapshotVersion(
      draftId,
      contentMarkdown: current.contentMarkdown,
      aiRevision: false,
      metadata: <String, dynamic>{
        'reason': 'pre_restore',
        'restored_from': versionId,
      },
    );
    // 4. Apply the target snapshot to the live draft.
    return updateDraft(draftId, contentMarkdown: target.contentSnapshot);
  }

  @override
  Future<AiRevision> reviseWithAi({
    required String draftId,
    required String selectedText,
    String? context,
    String? instruction,
    String? language,
  }) async {
    final res = await _client.functions.invoke(
      'draft-ai-revise',
      body: <String, dynamic>{
        'draft_id': draftId,
        'selected_text': selectedText,
        if (context != null && context.isNotEmpty) 'context': context,
        if (instruction != null && instruction.isNotEmpty)
          'instruction': instruction,
        if (language != null) 'language': language,
      },
    );
    final data = res.data;
    if (data is! Map) {
      throw StateError('draft-ai-revise returned unexpected payload: $data');
    }
    return AiRevision.fromJson(data.cast<String, dynamic>());
  }

  @override
  Future<DocxExport> exportToDocx({
    required String contentMarkdown,
    String? title,
  }) async {
    final res = await _client.functions.invoke(
      'draft-export-docx',
      body: <String, dynamic>{
        'content_markdown': contentMarkdown,
        if (title != null) 'title': title,
      },
    );
    final data = res.data;
    if (data is! Map) {
      throw StateError('draft-export-docx returned unexpected payload: $data');
    }
    final m = data.cast<String, dynamic>();
    return DocxExport(
      base64: (m['docx_base64'] as String?) ?? '',
      filename: (m['filename'] as String?) ?? 'draft.docx',
      byteLength: (m['byte_length'] as int?) ?? 0,
    );
  }

  @override
  Future<PdfExport> exportToPdf({
    required String contentMarkdown,
    String? title,
  }) async {
    final res = await _client.functions.invoke(
      'draft-export-pdf',
      body: <String, dynamic>{
        'content_markdown': contentMarkdown,
        if (title != null) 'title': title,
      },
    );
    final data = res.data;
    if (data is! Map) {
      // The Functions client surfaces the JSON error body here too — turn
      // it into a typed StateError so the screen can show a clean message.
      throw StateError('draft-export-pdf returned unexpected payload: $data');
    }
    final m = data.cast<String, dynamic>();
    // Edge fn returns { error: "worker_not_configured" } with status 503
    // when the Typst worker isn't set up; the supabase-flutter client puts
    // that into the data map. Surface it as a typed failure.
    if (m.containsKey('error') && !m.containsKey('pdf_base64')) {
      throw StateError((m['error'] as String?) ?? 'pdf_export_failed');
    }
    return PdfExport(
      base64: (m['pdf_base64'] as String?) ?? '',
      filename: (m['filename'] as String?) ?? 'draft.pdf',
      byteLength: (m['byte_length'] as int?) ?? 0,
      mime: (m['mime'] as String?) ?? 'application/pdf',
    );
  }

  @override
  Future<String> saveToVault(String draftId) async {
    final vault = _vault;
    if (vault == null) {
      throw StateError(
        'saveToVault requires a VaultService — construct '
        'SupabaseDraftService(vaultService: …) or use the Riverpod provider.',
      );
    }
    // 1. Read the draft (title + body) so we know what to render. RLS
    //    enforces ownership; a null row means deleted / cross-user.
    final draft = await fetchById(draftId);
    if (draft == null) {
      throw StateError('saveToVault: draft $draftId not found.');
    }

    // 2. Render. We try the PDF edge fn first; on any failure (worker not
    //    configured, network 5xx, malformed payload) we fall back to a
    //    text/markdown blob so the file still lands in the Vault. The
    //    isPdf flag drives the filename extension.
    final render = await _renderForVault(
      draftId: draftId,
      title: draft.title,
      contentMarkdown: draft.contentMarkdown,
    );

    // 3. Upload via the Vault service. uploadFromDraft handles storage,
    //    `documents` row insert and "Draft" tagging in one transaction-ish
    //    sweep.
    final upload = await vault.uploadFromDraft(
      draftId: draftId,
      bytes: render.bytes,
      fileName: render.filename,
      mimeType: render.mimeType,
      caseId: draft.caseId,
    );

    // 4. Persist the link so a) the toolbar can show "View in Vault" on
    //    return visits and b) the Vault screen can offer "Edit draft" on
    //    the same row.
    await updateDraft(draftId, vaultCopyId: upload.documentId);

    return upload.documentId;
  }

  /// Render helper for [saveToVault]. Tries the PDF edge function first,
  /// falls back to a text/markdown blob. Kept top-level on the service so
  /// the public [exportToPdf] surface stays focused on a single content type.
  Future<DraftRender> _renderForVault({
    required String draftId,
    required String? title,
    required String contentMarkdown,
  }) async {
    final safeTitle = (title?.trim().isNotEmpty ?? false)
        ? title!.trim()
        : 'draft-$draftId';
    final sanitised = _sanitiseFilename(safeTitle);
    try {
      final pdf = await exportToPdf(
        contentMarkdown: contentMarkdown,
        title: title,
      );
      final bytes = base64Decode(pdf.base64);
      if (bytes.isEmpty) {
        // Edge fn answered without an error but produced no bytes —
        // treat as a soft failure and fall through to the markdown path.
        throw StateError('pdf_export_empty');
      }
      return DraftRender(
        bytes: bytes,
        filename: pdf.filename.isNotEmpty
            ? pdf.filename
            : '$sanitised.pdf',
        mimeType: pdf.mime,
      );
    } catch (_) {
      // Fallback: markdown blob. We still get an entry in the Vault and the
      // user can re-file once the PDF worker is back online.
      final mdBytes = Uint8List.fromList(utf8.encode(contentMarkdown));
      return DraftRender(
        bytes: mdBytes,
        filename: '$sanitised.md',
        mimeType: 'text/markdown',
      );
    }
  }

  String _sanitiseFilename(String s) {
    // Replace anything that isn't a safe filename char with '_', collapse
    // runs, trim leading/trailing underscores, cap length.
    final cleaned = s
        .replaceAll(RegExp(r'[^A-Za-z0-9._\- ]+'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final trimmed =
        cleaned.replaceAll(RegExp(r'^_+|_+$'), '').toLowerCase();
    if (trimmed.isEmpty) return 'draft';
    return trimmed.length > 80 ? trimmed.substring(0, 80) : trimmed;
  }
}

// ─── Autosave coordinator ──────────────────────────────────────────────────
//
// Debounces editor changes and pushes them to [DraftService.updateDraft]
// at most once every [interval]. The widget creates one of these per editor
// session and disposes it when the screen closes.
// -----------------------------------------------------------------------------

class AutosaveController {
  AutosaveController({
    required this.service,
    required this.draftId,
    this.interval = const Duration(seconds: 30),
    Stream<DateTime>? clock,
  }) : _clock = clock;

  final DraftService service;
  final String draftId;
  final Duration interval;
  final Stream<DateTime>? _clock;

  Timer? _timer;
  bool _dirty = false;
  String _pendingMarkdown = '';
  String? _pendingTitle;
  Future<void>? _inFlight;

  /// Marks the buffer dirty. Saves after [interval] of inactivity.
  void markDirty({required String markdown, String? title}) {
    _dirty = true;
    _pendingMarkdown = markdown;
    _pendingTitle = title;
    _timer?.cancel();
    _timer = Timer(interval, flush);
  }

  /// Force-flushes the buffer immediately (e.g. on screen exit, AI revise,
  /// manual Save button).
  ///
  /// Throws if the underlying write fails, so callers (manual Save, Save to
  /// Vault) can surface a "save failed" message instead of falsely showing
  /// "Saved". On failure the buffer is re-marked dirty so the next autosave
  /// tick retries.
  Future<void> flush() async {
    if (!_dirty) return;
    if (_inFlight != null) {
      // Coalesce — wait for in-flight save then re-check. If that save failed
      // it rethrows here, which is correct: this caller's edits aren't saved
      // either.
      await _inFlight;
      if (!_dirty) return;
    }
    final mdSnapshot = _pendingMarkdown;
    final titleSnapshot = _pendingTitle;
    _dirty = false;
    _timer?.cancel();
    final fut = service.updateDraft(
      draftId,
      contentMarkdown: mdSnapshot,
      title: titleSnapshot,
    );
    _inFlight = fut.then((_) {});
    try {
      await _inFlight;
    } catch (_) {
      // On failure, mark dirty again so the next tick retries, then rethrow
      // so the caller knows the save did not land.
      _dirty = true;
      rethrow;
    } finally {
      _inFlight = null;
    }
    // _clock is not yet consumed in MVP — placeholder for fixed-interval
    // pulse-based saves once the editor supports collaborative drafts.
    _clock?.listen((_) {});
  }

  /// Fire-and-forget final save for teardown (widget dispose), where we cannot
  /// await. Dispatches the pending write so an edit made inside the debounce
  /// window isn't silently lost on navigate-away. Errors are swallowed — the
  /// screen is already gone, so there's no UI to surface them to, and the next
  /// open re-loads from server. The DraftService is app-scoped, so the write
  /// outlives this controller.
  void flushBestEffort() {
    if (!_dirty) return;
    final mdSnapshot = _pendingMarkdown;
    final titleSnapshot = _pendingTitle;
    _dirty = false;
    _timer?.cancel();
    unawaited(() async {
      try {
        await service.updateDraft(draftId,
            contentMarkdown: mdSnapshot, title: titleSnapshot);
      } catch (_) {
        _dirty = true; // best-effort; nothing to surface, screen is gone
      }
    }());
  }

  void dispose() {
    _timer?.cancel();
  }
}
