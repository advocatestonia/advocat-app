// ---------------------------------------------------------------------------
// Document-Collection Checklist (Feature #4) — service layer.
//
// Thin, self-contained wrapper around the Supabase client. Kept inside the
// feature folder (rather than extending the shared SupabaseService) so the
// feature touches no shared files. Talks to:
//   * RPC  get_doc_requirements(p_problem_type, p_jurisdiction)
//   * RPC  toggle_doc_requirement(p_requirement_id, p_problem_type,
//                                 p_collected, p_document_id)
//   * edge fn `doc-requirements` (action:"suggest") for the AI top-up
//   * `documents` table (read-only) for the file-link picker
// All scoped per-user by RLS / SECURITY DEFINER + auth.uid().
// ---------------------------------------------------------------------------

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/doc_requirement.dart';

/// Riverpod hook — overridable in tests via `overrideWith`.
final docCollectionServiceProvider = Provider<DocCollectionService>((ref) {
  return _SupabaseDocCollectionService();
});

/// One of the user's already-uploaded documents, offered in the link picker.
@immutable
class LinkableDocument {
  const LinkableDocument({
    required this.id,
    required this.fileName,
    this.createdAt,
  });

  final String id;
  final String fileName;
  final DateTime? createdAt;

  factory LinkableDocument.fromJson(Map<String, dynamic> j) {
    return LinkableDocument(
      id: (j['id'] as String?) ?? '',
      fileName: (j['file_name'] as String?) ?? 'Document',
      createdAt: DateTime.tryParse((j['created_at'] as String?) ?? ''),
    );
  }
}

/// Interface so widget/provider tests can substitute a fake.
abstract class DocCollectionService {
  /// Base set + caller progress for a (problemType, jurisdiction).
  Future<DocRequirementSet> getRequirements(
    DocProblemType problemType, {
    String jurisdiction = '*',
  });

  /// Upsert one requirement's progress. [documentId] links an uploaded file
  /// (must be owned by the caller); pass null to leave / clear it.
  /// Returns true on success.
  Future<bool> toggleRequirement({
    required DocProblemType problemType,
    required String requirementId,
    required bool collected,
    String? documentId,
  });

  /// Ask the AI top-up for EXTRA documents for a non-standard [situation].
  /// Returns [] on any error / when the backend is unconfigured.
  Future<List<DocSuggestion>> suggestExtra({
    required DocProblemType problemType,
    required String situation,
    String jurisdiction = '*',
  });

  /// The caller's uploaded documents, newest first, for the link picker.
  Future<List<LinkableDocument>> listDocuments();
}

class _SupabaseDocCollectionService implements DocCollectionService {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<DocRequirementSet> getRequirements(
    DocProblemType problemType, {
    String jurisdiction = '*',
  }) async {
    try {
      final res = await _client.rpc(
        'get_doc_requirements',
        params: {
          'p_problem_type': problemType.key,
          'p_jurisdiction': jurisdiction,
        },
      );
      return DocRequirementSet.fromRpc(res);
    } catch (e) {
      debugPrint('doc-collection getRequirements error: $e');
      return DocRequirementSet.empty;
    }
  }

  @override
  Future<bool> toggleRequirement({
    required DocProblemType problemType,
    required String requirementId,
    required bool collected,
    String? documentId,
  }) async {
    try {
      final res = await _client.rpc(
        'toggle_doc_requirement',
        params: {
          'p_requirement_id': requirementId,
          'p_problem_type': problemType.key,
          'p_collected': collected,
          'p_document_id': documentId,
        },
      );
      return res is Map && res['ok'] == true;
    } catch (e) {
      debugPrint('doc-collection toggleRequirement error: $e');
      return false;
    }
  }

  @override
  Future<List<DocSuggestion>> suggestExtra({
    required DocProblemType problemType,
    required String situation,
    String jurisdiction = '*',
  }) async {
    try {
      final response = await _client.functions.invoke(
        'doc-requirements',
        body: {
          'action': 'suggest',
          'problem_type': problemType.key,
          'jurisdiction': jurisdiction,
          'situation': situation,
        },
      );
      final data = response.data;
      if (data is Map && data['suggestions'] is List) {
        return (data['suggestions'] as List)
            .whereType<Map>()
            .map((e) => DocSuggestion.fromJson(Map<String, dynamic>.from(e)))
            .where((s) => s.title.isNotEmpty)
            .toList();
      }
      return const [];
    } catch (e) {
      debugPrint('doc-collection suggestExtra error: $e');
      return const [];
    }
  }

  @override
  Future<List<LinkableDocument>> listDocuments() async {
    try {
      final rows = await _client
          .from('documents')
          .select('id, file_name, created_at')
          .order('created_at', ascending: false)
          .limit(100);
      return (rows as List)
          .whereType<Map>()
          .map((e) => LinkableDocument.fromJson(Map<String, dynamic>.from(e)))
          .where((d) => d.id.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('doc-collection listDocuments error: $e');
      return const [];
    }
  }
}
