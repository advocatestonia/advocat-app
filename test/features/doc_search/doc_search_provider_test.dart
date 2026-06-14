// doc_search_provider_test.dart — Feature #4 provider + model tests.
// -----------------------------------------------------------------------------
// Run:
//   flutter test test/features/doc_search/doc_search_provider_test.dart
//
// Scope:
//   T01 DocSearchHit.fromJson parses fields + highlight
//   T02 DocSearchHit.hasHighlight validates bounds
//   T03 provider: short query → idle, no service call
//   T04 provider: happy path → results
//   T05 provider: empty backend → empty status
//   T06 provider: backend exception → error status with message
//   T07 provider: stale slow response is ignored (race guard)
//   T08 provider: clear resets to idle
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/doc_search/providers/doc_search_provider.dart';
import 'package:advocat/features/doc_search/services/doc_search_service.dart';

/// Fake service driven per-test.
class _FakeService implements DocSearchService {
  _FakeService();

  List<DocSearchHit> Function(String query)? onSearch;
  Object? throwOnSearch;
  Completer<List<DocSearchHit>>? gate;
  final List<String> queries = [];

  @override
  Future<List<DocSearchHit>> search(
    String query, {
    int matchCount = 8,
    String? orgId,
    String? sourceKind,
    String? sourceId,
  }) async {
    queries.add(query);
    if (gate != null) return gate!.future;
    if (throwOnSearch != null) throw throwOnSearch!;
    return onSearch?.call(query) ?? const <DocSearchHit>[];
  }

  @override
  Future<DocIndexResult> indexDocument({
    required String sourceKind,
    required String sourceId,
  }) async =>
      const DocIndexResult(indexed: 0, tokens: 0);
}

DocSearchHit _hit({double sim = 0.8}) => DocSearchHit(
      chunkId: 'c1',
      sourceKind: 'vault_document',
      sourceId: 's1',
      docTitle: 'lease.pdf',
      chunkIndex: 0,
      snippet: 'The deposit is held in escrow.',
      similarity: sim,
      highlightStart: 4,
      highlightEnd: 11,
    );

ProviderContainer _container(_FakeService svc) {
  return ProviderContainer(
    overrides: [docSearchServiceProvider.overrideWithValue(svc)],
  );
}

void main() {
  test('T01 DocSearchHit.fromJson parses fields + highlight', () {
    final hit = DocSearchHit.fromJson({
      'chunk_id': 'abc',
      'source_kind': 'case_document',
      'source_id': 'sid',
      'doc_title': 'court.pdf',
      'chunk_index': 3,
      'snippet': 'termination clause here',
      'similarity': 0.42,
      'highlight': {'start': 0, 'end': 11},
    });
    expect(hit.chunkId, 'abc');
    expect(hit.sourceKind, 'case_document');
    expect(hit.chunkIndex, 3);
    expect(hit.similarity, 0.42);
    expect(hit.highlightStart, 0);
    expect(hit.highlightEnd, 11);
    expect(hit.hasHighlight, true);
  });

  test('T02 hasHighlight validates bounds', () {
    expect(_hit().hasHighlight, true);
    // out-of-bounds end
    const bad = DocSearchHit(
      chunkId: 'c',
      sourceKind: 'vault_document',
      sourceId: 's',
      docTitle: null,
      chunkIndex: 0,
      snippet: 'short',
      similarity: 0.5,
      highlightStart: 2,
      highlightEnd: 99,
    );
    expect(bad.hasHighlight, false);
    // null highlight
    const none = DocSearchHit(
      chunkId: 'c',
      sourceKind: 'vault_document',
      sourceId: 's',
      docTitle: null,
      chunkIndex: 0,
      snippet: 'short',
      similarity: 0.5,
    );
    expect(none.hasHighlight, false);
  });

  test('T03 short query → idle, no service call', () async {
    final svc = _FakeService();
    final c = _container(svc);
    addTearDown(c.dispose);
    final n = c.read(docSearchProvider.notifier);
    n.setQuery('a');
    await n.search();
    expect(c.read(docSearchProvider).status, DocSearchStatus.idle);
    expect(svc.queries, isEmpty);
  });

  test('T04 happy path → results', () async {
    final svc = _FakeService()..onSearch = (_) => [_hit()];
    final c = _container(svc);
    addTearDown(c.dispose);
    final n = c.read(docSearchProvider.notifier);
    n.setQuery('deposit');
    await n.search();
    final s = c.read(docSearchProvider);
    expect(s.status, DocSearchStatus.results);
    expect(s.hits.length, 1);
    expect(svc.queries.single, 'deposit');
  });

  test('T05 empty backend → empty status', () async {
    final svc = _FakeService()..onSearch = (_) => const <DocSearchHit>[];
    final c = _container(svc);
    addTearDown(c.dispose);
    final n = c.read(docSearchProvider.notifier);
    n.setQuery('nothing matches');
    await n.search();
    expect(c.read(docSearchProvider).status, DocSearchStatus.empty);
  });

  test('T06 backend exception → error status', () async {
    final svc = _FakeService()
      ..throwOnSearch = const DocSearchException('boom', statusCode: 500);
    final c = _container(svc);
    addTearDown(c.dispose);
    final n = c.read(docSearchProvider.notifier);
    n.setQuery('deposit');
    await n.search();
    final s = c.read(docSearchProvider);
    expect(s.status, DocSearchStatus.error);
    expect(s.errorMessage, 'boom');
  });

  test('T07 stale slow response ignored (race guard)', () async {
    final svc = _FakeService();
    final c = _container(svc);
    addTearDown(c.dispose);
    final n = c.read(docSearchProvider.notifier);

    // First search gated open (slow).
    final gate1 = Completer<List<DocSearchHit>>();
    svc.gate = gate1;
    n.setQuery('first');
    final f1 = n.search();

    // Second search starts and finishes first.
    svc.gate = null;
    svc.onSearch = (_) => [_hit(sim: 0.9)];
    n.setQuery('second');
    await n.search();
    expect(c.read(docSearchProvider).status, DocSearchStatus.results);

    // Now the stale first resolves — must NOT overwrite.
    gate1.complete([_hit(sim: 0.1)]);
    await f1;
    expect(c.read(docSearchProvider).hits.single.similarity, 0.9);
  });

  test('T08 clear resets to idle', () async {
    final svc = _FakeService()..onSearch = (_) => [_hit()];
    final c = _container(svc);
    addTearDown(c.dispose);
    final n = c.read(docSearchProvider.notifier);
    n.setQuery('deposit');
    await n.search();
    expect(c.read(docSearchProvider).status, DocSearchStatus.results);
    n.clear();
    final s = c.read(docSearchProvider);
    expect(s.status, DocSearchStatus.idle);
    expect(s.query, '');
    expect(s.hits, isEmpty);
  });
}
