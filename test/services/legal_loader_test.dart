// Tests for LegalLoader — lazy LRU-cached loader for legal JSON assets.
// v24.2 OMEGA-5 Phase 3.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:advocat/services/legal_loader.dart';

/// Builds a fake act JSON payload with [sectionCount] sections.
String _fakeActJson(String name, {int sectionCount = 2}) {
  final sections = <Map<String, dynamic>>[];
  for (var i = 0; i < sectionCount; i++) {
    sections.add({
      'paragraph': '§ ${i + 1}',
      'title': 'Section ${i + 1}',
      'body': 'Body of section ${i + 1} in $name. '
          'Lorem ipsum legal text goes here.',
    });
  }
  return jsonEncode({
    'act': name,
    'name': name,
    'source': 'https://example.test/$name',
    'sections': sections,
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LegalLoader', () {
    test('T01 — returns null when asset file is missing', () async {
      final loader = LegalLoader(
        assetLoader: (_) async => throw Exception('asset not found'),
      );
      final act = await loader.loadAct(jurisdiction: 'ee', act: 'NOSUCH');
      expect(act, isNull);
    });

    test('T02 — parses a valid asset into a LegalAct with sections', () async {
      final loader = LegalLoader(
        assetLoader: (path) async => _fakeActJson('TestAct', sectionCount: 3),
      );
      final act = await loader.loadAct(jurisdiction: 'ee', act: 'TestAct');
      expect(act, isNotNull);
      expect(act!.code, 'TESTACT');
      expect(act.jurisdiction, 'ee');
      expect(act.sections, hasLength(3));
      expect(act.sections.first.paragraph, '§ 1');
      expect(act.sourceUrl, 'https://example.test/TestAct');
    });

    test('T03 — cache hit returns same instance on second call', () async {
      var calls = 0;
      final loader = LegalLoader(
        assetLoader: (path) async {
          calls++;
          return _fakeActJson('CachedAct');
        },
      );
      final a = await loader.loadAct(jurisdiction: 'ee', act: 'CachedAct');
      final b = await loader.loadAct(jurisdiction: 'ee', act: 'CachedAct');
      expect(identical(a, b), isTrue, reason: 'cached instance must be reused');
      expect(calls, 1, reason: 'asset loader called only once for a cache hit');
    });

    test('T04 — LRU evicts oldest entry when capacity exceeded', () async {
      final loader = LegalLoader(
        capacity: 2,
        assetLoader: (path) async => _fakeActJson(path),
      );
      await loader.loadAct(jurisdiction: 'ee', act: 'A');
      await loader.loadAct(jurisdiction: 'ee', act: 'B');
      await loader.loadAct(jurisdiction: 'ee', act: 'C'); // evicts A
      final keys = loader.cachedKeysForTest;
      expect(keys.length, 2);
      expect(keys.any((k) => k.endsWith(':A')), isFalse,
          reason: 'A should have been evicted as oldest');
      expect(keys.any((k) => k.endsWith(':B')), isTrue);
      expect(keys.any((k) => k.endsWith(':C')), isTrue);
    });

    test('T05 — accessing a cached entry bumps it to MRU slot', () async {
      final loader = LegalLoader(
        capacity: 2,
        assetLoader: (path) async => _fakeActJson(path),
      );
      await loader.loadAct(jurisdiction: 'ee', act: 'A');
      await loader.loadAct(jurisdiction: 'ee', act: 'B');
      // Touch A — now A is MRU, B is LRU
      await loader.loadAct(jurisdiction: 'ee', act: 'A');
      await loader.loadAct(jurisdiction: 'ee', act: 'C'); // should evict B
      final keys = loader.cachedKeysForTest;
      expect(keys.any((k) => k.endsWith(':B')), isFalse,
          reason: 'B should be evicted (LRU after A touched)');
      expect(keys.any((k) => k.endsWith(':A')), isTrue);
      expect(keys.any((k) => k.endsWith(':C')), isTrue);
    });

    test('T06 — parallel loads of the same act dedupe to one fetch', () async {
      var calls = 0;
      final completer = Completer<String>();
      final loader = LegalLoader(
        assetLoader: (path) async {
          calls++;
          return completer.future;
        },
      );
      final f1 = loader.loadAct(jurisdiction: 'ee', act: 'Parallel');
      final f2 = loader.loadAct(jurisdiction: 'ee', act: 'Parallel');
      final f3 = loader.loadAct(jurisdiction: 'ee', act: 'Parallel');
      // Let the scheduler spin so all three register as in-flight
      await Future<void>.delayed(Duration.zero);
      completer.complete(_fakeActJson('Parallel'));
      final results = await Future.wait([f1, f2, f3]);
      expect(calls, 1,
          reason: 'asset loader must be called exactly once for parallel reqs');
      expect(results[0], isNotNull);
      expect(identical(results[0], results[1]), isTrue);
      expect(identical(results[1], results[2]), isTrue);
    });

    test('T07 — jurisdiction case is normalised (FI vs fi vs Fi)', () async {
      final loader = LegalLoader(
        assetLoader: (path) async => _fakeActJson('Rikoslaki'),
      );
      final a = await loader.loadAct(jurisdiction: 'FI', act: 'Rikoslaki');
      final b = await loader.loadAct(jurisdiction: 'fi', act: 'Rikoslaki');
      final c = await loader.loadAct(jurisdiction: 'Fi', act: 'Rikoslaki');
      expect(identical(a, b), isTrue);
      expect(identical(b, c), isTrue);
    });

    test('T08 — act code case is normalised (KARS vs kars vs KarS)', () async {
      final loader = LegalLoader(
        assetLoader: (path) async => _fakeActJson('KarS'),
      );
      final a = await loader.loadAct(jurisdiction: 'ee', act: 'KARS');
      final b = await loader.loadAct(jurisdiction: 'ee', act: 'kars');
      final c = await loader.loadAct(jurisdiction: 'ee', act: 'KarS');
      expect(identical(a, b), isTrue);
      expect(identical(b, c), isTrue);
    });

    test('T09 — Estonian acts with Õ/Ä/Ö/Ü fold ASCII for filename', () async {
      final requestedPaths = <String>[];
      final loader = LegalLoader(
        assetLoader: (path) async {
          requestedPaths.add(path);
          // First attempt (lowercase with diacritics) misses; second (folded) hits
          if (path.contains('võrdks')) {
            throw Exception('not found');
          }
          return _fakeActJson('VõrdKS');
        },
      );
      final act = await loader.loadAct(jurisdiction: 'ee', act: 'VõrdKS');
      expect(act, isNotNull);
      // Both candidate filenames should have been attempted
      expect(requestedPaths.length, greaterThanOrEqualTo(2));
      expect(requestedPaths.any((p) => p.endsWith('vordks.json')), isTrue);
    });

    test('T10 — malformed JSON does not crash, returns null', () async {
      final loader = LegalLoader(
        assetLoader: (path) async => '{this is not valid json',
      );
      final act = await loader.loadAct(jurisdiction: 'ee', act: 'Bogus');
      expect(act, isNull);
    });

    test('T11 — clearCache empties the LRU but not the in-flight dedupe', () async {
      final loader = LegalLoader(
        assetLoader: (path) async => _fakeActJson(path),
      );
      await loader.loadAct(jurisdiction: 'ee', act: 'A');
      await loader.loadAct(jurisdiction: 'ee', act: 'B');
      expect(loader.cachedKeysForTest, hasLength(2));
      loader.clearCache();
      expect(loader.cachedKeysForTest, isEmpty);
      // New load after clear still works
      final a = await loader.loadAct(jurisdiction: 'ee', act: 'A');
      expect(a, isNotNull);
    });

    test('T12 — subsections are concatenated into body output', () async {
      final payload = jsonEncode({
        'name': 'ActWithSubs',
        'sections': [
          {
            'paragraph': '§ 1',
            'title': 'Title 1',
            'body': 'main body',
            'subsections': [
              {'id': '(1)', 'text': 'first sub'},
              {'id': '(2)', 'text': 'second sub'},
            ],
          },
        ],
      });
      final loader = LegalLoader(assetLoader: (_) async => payload);
      final act = await loader.loadAct(jurisdiction: 'ee', act: 'WithSubs');
      expect(act, isNotNull);
      expect(act!.sections, hasLength(1));
      expect(act.sections.first.body, contains('main body'));
      expect(act.sections.first.body, contains('(1) first sub'));
      expect(act.sections.first.body, contains('(2) second sub'));
    });
  });
}
