// =============================================================================
// doc_search_service.dart — client for Feature #4 (semantic search over the
// user's OWN documents).
// =============================================================================
//
// Talks to two edge functions:
//   * doc-semantic-search → embeds the query, RLS-scoped vector match, returns
//                           ranked chunks with highlight spans.
//   * doc-indexer         → indexes ONE document on demand (chunk + embed).
//
// RLS isolation is enforced server-side (match_user_doc_chunks uses auth.uid()
// and a dedicated user_doc_chunks table). The client never sees other tenants'
// chunks. See supabase/migrations/20260601100000_user_doc_embeddings.sql.
// =============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

/// One search hit: a chunk of one of the caller's own documents.
class DocSearchHit {
  const DocSearchHit({
    required this.chunkId,
    required this.sourceKind,
    required this.sourceId,
    required this.docTitle,
    required this.chunkIndex,
    required this.snippet,
    required this.similarity,
    this.highlightStart,
    this.highlightEnd,
  });

  final String chunkId;

  /// 'case_document' | 'vault_document'
  final String sourceKind;
  final String sourceId;
  final String? docTitle;
  final int chunkIndex;
  final String snippet;
  final double similarity;

  /// Char offsets WITHIN [snippet] of the matched phrase, for highlight.
  final int? highlightStart;
  final int? highlightEnd;

  bool get hasHighlight =>
      highlightStart != null &&
      highlightEnd != null &&
      highlightStart! >= 0 &&
      highlightEnd! <= snippet.length &&
      highlightStart! < highlightEnd!;

  factory DocSearchHit.fromJson(Map<String, dynamic> json) {
    final hl = json['highlight'];
    int? hlStart;
    int? hlEnd;
    if (hl is Map) {
      hlStart = (hl['start'] as num?)?.toInt();
      hlEnd = (hl['end'] as num?)?.toInt();
    }
    return DocSearchHit(
      chunkId: (json['chunk_id'] as String?) ?? '',
      sourceKind: (json['source_kind'] as String?) ?? 'vault_document',
      sourceId: (json['source_id'] as String?) ?? '',
      docTitle: json['doc_title'] as String?,
      chunkIndex: (json['chunk_index'] as num?)?.toInt() ?? 0,
      snippet: (json['snippet'] as String?) ?? '',
      similarity: (json['similarity'] as num?)?.toDouble() ?? 0.0,
      highlightStart: hlStart,
      highlightEnd: hlEnd,
    );
  }
}

/// Result of indexing one document.
class DocIndexResult {
  const DocIndexResult({required this.indexed, required this.tokens});
  final int indexed;
  final int tokens;

  factory DocIndexResult.fromJson(Map<String, dynamic> json) => DocIndexResult(
    indexed: (json['indexed'] as num?)?.toInt() ?? 0,
    tokens: (json['tokens'] as num?)?.toInt() ?? 0,
  );
}

/// Thrown when a backend call fails so the UI can show a friendly message.
class DocSearchException implements Exception {
  const DocSearchException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => 'DocSearchException($statusCode): $message';
}

class DocSearchService {
  DocSearchService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Semantic search over the caller's own documents.
  ///
  /// [query] free-text. Optional scope: [orgId] (one of the caller's orgs),
  /// [sourceKind]/[sourceId] to search within a single document.
  Future<List<DocSearchHit>> search(
    String query, {
    int matchCount = 8,
    String? orgId,
    String? sourceKind,
    String? sourceId,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const <DocSearchHit>[];

    final res = await _client.functions.invoke(
      'doc-semantic-search',
      body: <String, dynamic>{
        'query': trimmed,
        'match_count': matchCount,
        if (orgId != null) 'org_id': orgId,
        if (sourceKind != null) 'source_kind': sourceKind,
        if (sourceId != null) 'source_id': sourceId,
      },
    );
    final data = res.data;
    if (data is! Map) {
      throw const DocSearchException('Unexpected response from search');
    }
    final map = data.cast<String, dynamic>();
    final rawResults = map['results'];
    if (rawResults is! List) return const <DocSearchHit>[];
    return rawResults
        .whereType<Map>()
        .map((m) => DocSearchHit.fromJson(m.cast<String, dynamic>()))
        .toList(growable: false);
  }

  /// Index (or re-index) one document on demand. [sourceKind] is
  /// 'case_document' or 'vault_document'.
  Future<DocIndexResult> indexDocument({
    required String sourceKind,
    required String sourceId,
  }) async {
    final res = await _client.functions.invoke(
      'doc-indexer',
      body: <String, dynamic>{
        'source_kind': sourceKind,
        'source_id': sourceId,
      },
    );
    final data = res.data;
    if (data is! Map) {
      throw const DocSearchException('Unexpected response from indexer');
    }
    return DocIndexResult.fromJson(data.cast<String, dynamic>());
  }
}
