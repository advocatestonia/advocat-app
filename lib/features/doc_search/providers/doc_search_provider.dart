// =============================================================================
// doc_search_provider.dart — Riverpod state for Feature #4 document search.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/doc_search_service.dart';

/// Phase of the search UI.
enum DocSearchStatus { idle, loading, results, empty, error }

/// Immutable state for the document-search screen.
class DocSearchState {
  const DocSearchState({
    this.status = DocSearchStatus.idle,
    this.query = '',
    this.hits = const <DocSearchHit>[],
    this.errorMessage,
  });

  final DocSearchStatus status;
  final String query;
  final List<DocSearchHit> hits;
  final String? errorMessage;

  DocSearchState copyWith({
    DocSearchStatus? status,
    String? query,
    List<DocSearchHit>? hits,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DocSearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      hits: hits ?? this.hits,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class DocSearchNotifier extends StateNotifier<DocSearchState> {
  DocSearchNotifier(this._service) : super(const DocSearchState());

  final DocSearchService _service;

  /// Monotonic token so a slow earlier request can't overwrite a newer one.
  int _seq = 0;

  void setQuery(String value) {
    state = state.copyWith(query: value, clearError: true);
  }

  /// Run the search. Optional scope narrows results to one org or one document.
  Future<void> search({
    String? orgId,
    String? sourceKind,
    String? sourceId,
  }) async {
    final q = state.query.trim();
    if (q.length < 2) {
      state = state.copyWith(
        status: DocSearchStatus.idle,
        hits: const <DocSearchHit>[],
        clearError: true,
      );
      return;
    }

    final mySeq = ++_seq;
    state = state.copyWith(status: DocSearchStatus.loading, clearError: true);

    try {
      final hits = await _service.search(
        q,
        orgId: orgId,
        sourceKind: sourceKind,
        sourceId: sourceId,
      );
      if (mySeq != _seq) return; // a newer search superseded this one
      state = state.copyWith(
        status: hits.isEmpty ? DocSearchStatus.empty : DocSearchStatus.results,
        hits: hits,
      );
    } on DocSearchException catch (e) {
      if (mySeq != _seq) return;
      state = state.copyWith(
        status: DocSearchStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      if (mySeq != _seq) return;
      state = state.copyWith(
        status: DocSearchStatus.error,
        errorMessage: 'Search failed. Please try again.',
      );
    }
  }

  void clear() {
    _seq++;
    state = const DocSearchState();
  }
}

/// Service provider — overridable in tests with a fake.
final docSearchServiceProvider = Provider<DocSearchService>((ref) {
  return DocSearchService();
});

final docSearchProvider =
    StateNotifierProvider<DocSearchNotifier, DocSearchState>((ref) {
      return DocSearchNotifier(ref.watch(docSearchServiceProvider));
    });
