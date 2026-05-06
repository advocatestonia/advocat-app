// =====================================================================
// CaseRepository — thin Supabase wrapper for case-memory CRUD.
//
// RLS handles ownership (own cases / own case docs). The repo never
// inserts user_id explicitly — Supabase auth context owns that, and
// the migration's RLS policy enforces auth.uid() = user_id.
//
// Pkg 1.D scope: list / create / update / archive / get / list docs.
// Pkg 3 adds [uploadDocument] used by the intake wizard's step 5 to
// upload bytes to Storage and create a `case_documents` row with
// parsed_text=null (Pkg 2's PDF parser fills parsed_text via a
// separate edge function). The dual-write pattern means Pkg 3 ships
// without depending on Pkg 2 deployment.
// =====================================================================

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/case_document.dart';
import '../models/user_case.dart';

/// Provider for [CaseRepository]. Override in tests to inject a fake
/// Supabase-shaped backend.
final caseRepositoryProvider = Provider<CaseRepository>((ref) {
  return SupabaseCaseRepository(Supabase.instance.client);
});

/// Status filter for [CaseRepository.listCases].
enum CaseListFilter {
  active('active'),
  archived('archived'),
  closed('closed'),
  all('all');

  const CaseListFilter(this.value);
  final String value;
}

abstract class CaseRepository {
  Future<List<UserCase>> listCases({CaseListFilter filter = CaseListFilter.active});
  Future<UserCase?> getCase(String id);
  Future<UserCase> createCase({
    required String title,
    required String jurisdiction,
    String? caseType,
    String language = 'ru',
  });
  Future<UserCase> updateCase(UserCase updated);
  Future<void> archiveCase(String id);
  Future<void> closeCase(String id);
  Future<List<CaseDocument>> listDocuments(String caseId);

  /// Pkg 3 — uploads [bytes] to Supabase Storage under
  /// `<userId>/<caseId>/<filename>` and creates a `case_documents` row
  /// with `parsed_text` left null (Pkg 2 fills it asynchronously when
  /// deployed). Returns the freshly-created document id.
  Future<String> uploadDocument({
    required String caseId,
    required String filename,
    required Uint8List bytes,
    required String mimeType,
  });
}

class SupabaseCaseRepository implements CaseRepository {
  SupabaseCaseRepository(this._client);

  final SupabaseClient _client;

  static const _table = 'user_cases';
  static const _docsTable = 'case_documents';

  @override
  Future<List<UserCase>> listCases({
    CaseListFilter filter = CaseListFilter.active,
  }) async {
    final query = _client.from(_table).select();

    final filtered = filter == CaseListFilter.all
        ? query
        : query.eq('status', filter.value);

    final rows = await filtered.order('updated_at', ascending: false);

    return (rows as List)
        .map((r) => UserCase.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList(growable: false);
  }

  @override
  Future<UserCase?> getCase(String id) async {
    final rows = await _client.from(_table).select().eq('id', id).limit(1);
    final list = rows as List;
    if (list.isEmpty) return null;
    return UserCase.fromJson(Map<String, dynamic>.from(list.first as Map));
  }

  @override
  Future<UserCase> createCase({
    required String title,
    required String jurisdiction,
    String? caseType,
    String language = 'ru',
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('createCase: no authenticated user');
    }

    final payload = <String, dynamic>{
      'user_id': userId,
      'title': title,
      'jurisdiction': jurisdiction,
      if (caseType != null) 'case_type': caseType,
      'language': language,
      'status': 'active',
    };

    final inserted =
        await _client.from(_table).insert(payload).select().single();
    return UserCase.fromJson(Map<String, dynamic>.from(inserted));
  }

  @override
  Future<UserCase> updateCase(UserCase updated) async {
    final row = await _client
        .from(_table)
        .update(updated.toUpdateJson())
        .eq('id', updated.id)
        .select()
        .single();
    return UserCase.fromJson(Map<String, dynamic>.from(row));
  }

  @override
  Future<void> archiveCase(String id) async {
    await _client.from(_table).update({'status': 'archived'}).eq('id', id);
  }

  @override
  Future<void> closeCase(String id) async {
    await _client.from(_table).update({'status': 'closed'}).eq('id', id);
  }

  @override
  Future<List<CaseDocument>> listDocuments(String caseId) async {
    // We deliberately pick columns and EXCLUDE parsed_text + embedding —
    // those are server-side only (see CaseDocument model docstring).
    const cols = 'id,case_id,user_id,filename,storage_path,mime_type,'
        'size_bytes,doc_type,doc_date,parsed_summary,key_extractions,'
        'uploaded_at';

    final rows = await _client
        .from(_docsTable)
        .select(cols)
        .eq('case_id', caseId)
        .order('uploaded_at', ascending: false);

    return (rows as List)
        .map((r) => CaseDocument.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList(growable: false);
  }

  @override
  Future<String> uploadDocument({
    required String caseId,
    required String filename,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('uploadDocument: no authenticated user');
    }
    // Sanitize filename — Storage path keys reject some chars.
    final safeName = filename.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final ts = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$userId/$caseId/${ts}_$safeName';

    await _client.storage.from('case-documents').uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(contentType: mimeType),
        );

    final inserted = await _client
        .from(_docsTable)
        .insert({
          'case_id': caseId,
          'user_id': userId,
          'filename': filename,
          'storage_path': storagePath,
          'mime_type': mimeType,
          'size_bytes': bytes.length,
          // parsed_text intentionally null — Pkg 2 fills it async.
        })
        .select('id')
        .single();

    return inserted['id'] as String;
  }
}
