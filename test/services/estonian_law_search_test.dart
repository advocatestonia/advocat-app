import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/estonian_law_search.dart';

/// Tests for [EstonianLawSearch] — asset loading, paragraph lookup,
/// keyword scoring, normalisation.
///
/// We stub `rootBundle.loadString` via [TestDefaultBinaryMessengerBinding] so
/// the test runs fully offline and deterministically regardless of which
/// acts are present in the actual app bundle.
void main() {
  const stubMks = '''
{
  "act": "MKS",
  "name": "Maksukorralduse seadus",
  "source": "https://www.riigiteataja.ee/akt/MKS",
  "sections": [
    {
      "paragraph": "§ 1",
      "title": "Seaduse reguleerimisala",
      "body": "Käesolev seadus sätestab maksumenetluse korralduse.",
      "subsections": []
    },
    {
      "paragraph": "§ 46",
      "title": "Vaide esitamise tähtaeg",
      "body": "Vaie tuleb esitada 30 päeva jooksul.",
      "subsections": [
        { "id": "lg 1", "text": "Vaide saab esitada 30 päeva jooksul." }
      ]
    },
    {
      "paragraph": "§ 116",
      "title": "Intress",
      "body": "Maksuvõla pealt arvestatakse intressi 0,06% päevas.",
      "subsections": []
    }
  ]
}
''';

  const stubKars = '''
{
  "act": "KarS",
  "name": "Karistusseadustik",
  "source": "https://www.riigiteataja.ee/akt/KarS",
  "sections": [
    {
      "paragraph": "§ 121",
      "title": "Tervisekahjustuse tekitamine",
      "body": "Teise inimese tervise kahjustamise eest karistatakse kuni 5 aasta vangistusega.",
      "subsections": []
    },
    {
      "paragraph": "§ 199",
      "title": "Vargus",
      "body": "Võõra vara varastamise eest karistatakse rahatrahvi või kuni 3 aasta vangistusega.",
      "subsections": []
    }
  ]
}
''';

  const manifestJson =
      '{"assets/legal/estonia/mks.json":[], "assets/legal/estonia/kars.json":[]}';

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    EstonianLawSearch.resetForTests();

    // Intercept rootBundle.loadString via binary messenger.
    TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
      final key = utf8.decode((message as ByteData).buffer.asUint8List());
      String? payload;
      if (key == 'assets/legal/estonia/mks.json') {
        payload = stubMks;
      } else if (key == 'assets/legal/estonia/kars.json') {
        payload = stubKars;
      } else if (key == 'AssetManifest.json') {
        payload = manifestJson;
      }
      if (payload == null) return null;
      final bytes = utf8.encode(payload);
      return ByteData.view(Uint8List.fromList(bytes).buffer);
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
    EstonianLawSearch.resetForTests();
  });

  // ── Paragraph lookup ──────────────────────────────────────────────────

  test('paragraph lookup returns exact § match', () async {
    final results = await EstonianLawSearch.search(
      query: '',
      paragraph: '§ 121',
      act: 'KarS',
    );
    expect(results, isNotEmpty);
    expect(results.first.paragraph, '§ 121');
    expect(results.first.act, 'KarS');
    expect(results.first.title, contains('Tervisekahjustuse'));
  });

  test('paragraph lookup is whitespace-insensitive', () async {
    final r1 = await EstonianLawSearch.search(query: '', paragraph: '§121');
    final r2 = await EstonianLawSearch.search(query: '', paragraph: '§ 121 ');
    expect(r1.first.paragraph, r2.first.paragraph);
  });

  test('paragraph lookup can prefix-match subsections', () async {
    final results = await EstonianLawSearch.search(
      query: '',
      paragraph: '§ 46',
    );
    expect(results, isNotEmpty);
    expect(results.first.act, 'MKS');
  });

  test('paragraph lookup filtered by act skips other acts', () async {
    final results = await EstonianLawSearch.search(
      query: '',
      paragraph: '§ 1',
      act: 'MKS',
    );
    expect(results.length, 1);
    expect(results.first.act, 'MKS');
  });

  // ── Keyword search ────────────────────────────────────────────────────

  test('keyword search finds matches by title word', () async {
    final results = await EstonianLawSearch.search(query: 'vargus');
    expect(results, isNotEmpty);
    expect(results.first.act, 'KarS');
    expect(results.first.paragraph, '§ 199');
  });

  test('keyword search finds matches by body word', () async {
    final results =
        await EstonianLawSearch.search(query: 'intressi päevas');
    expect(results, isNotEmpty);
    expect(results.any((r) => r.paragraph == '§ 116'), isTrue);
  });

  test('keyword search ranks title-hits higher than body-only hits',
      () async {
    final results = await EstonianLawSearch.search(query: 'vaide');
    expect(results.first.paragraph, '§ 46');
  });

  test('keyword search returns empty list for unknown terms', () async {
    final results =
        await EstonianLawSearch.search(query: 'totally_unrelated_zzz');
    expect(results, isEmpty);
  });

  test('keyword search supports Cyrillic / mixed-script queries', () async {
    // The word "maksu" appears in body — the tokenizer must not drop it
    // when given alongside a Cyrillic noise term.
    final results = await EstonianLawSearch.search(query: 'налог maksu');
    expect(results, isNotEmpty);
    expect(results.first.act, 'MKS');
  });

  // ── Guards ────────────────────────────────────────────────────────────

  test('search with both empty query and paragraph returns empty safely',
      () async {
    final results = await EstonianLawSearch.search(query: '');
    expect(results, isEmpty);
  });

  test('statistics returns a per-act count', () async {
    final stats = await EstonianLawSearch.statistics();
    expect(stats['MKS'], 3);
    expect(stats['KARS'], 2);
  });

  test('missing act file is silently skipped (no throw)', () async {
    // "HMS" asset is not stubbed; should not crash the index build.
    final stats = await EstonianLawSearch.statistics();
    expect(stats.containsKey('HMS'), isTrue);
    expect(stats['HMS'], 0);
  });
}
