// drafting/services/draft_service.dart — Pkg 7 Drafting Studio MVP.
// -----------------------------------------------------------------------------
// Thin CRUD layer over the `user_drafts` and `draft_versions` Postgres tables.
// All methods are RLS-protected on the server; this client wrapper just shapes
// the rows for the Flutter UI and centralises the autosave logic.
//
// Keeping IO behind a service interface lets widget tests inject a fake.
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/draft_model.dart';

/// Provider for the default implementation. Tests can override via
/// `ref.read(draftServiceProvider.overrideWithValue(FakeDraftService()))`.
final draftServiceProvider = Provider<DraftService>((ref) {
  return SupabaseDraftService();
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

/// Production implementation backed by Supabase.
class SupabaseDraftService implements DraftService {
  SupabaseDraftService({SupabaseClient? client, Uuid? uuid})
      : _client = client ?? Supabase.instance.client,
        _uuid = uuid ?? const Uuid();

  final SupabaseClient _client;
  final Uuid _uuid;

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
  Future<void> flush() async {
    if (!_dirty) return;
    if (_inFlight != null) {
      // Coalesce — wait for in-flight save then re-check.
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
    _inFlight = fut.then((_) {}).catchError((Object e, StackTrace st) {
      // On failure, mark dirty again so the next tick retries.
      _dirty = true;
    });
    await _inFlight;
    _inFlight = null;
    // _clock is not yet consumed in MVP — placeholder for fixed-interval
    // pulse-based saves once the editor supports collaborative drafts.
    _clock?.listen((_) {});
  }

  void dispose() {
    _timer?.cancel();
  }
}
