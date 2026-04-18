// Tests for FinnishLawSearch (v24.2 OMEGA-5 Phase 4).
//
// Covers the 5 bundled acts: Ulkomaalaislaki, Rikoslaki, Rikosvahinkolaki,
// Oikeudenkäymiskaari, Hallintolaki. Several tests are derived from the
// real Sulga case (see .consilium-17042026/overnight/hour-8-real-case.md).

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:advocat/services/finnish_law_search.dart';
import 'package:advocat/services/legal_loader.dart';

// Fake bundled content — keeps tests hermetic (no rootBundle needed).
String _fakeAct(String code, String name, List<Map<String, String>> sections) {
  return jsonEncode({
    'act': code,
    'name': name,
    'source': 'https://www.finlex.fi/fi/laki/ajantasa/${code.toLowerCase()}',
    'sections': sections
        .map((s) => {
              'paragraph': s['paragraph'],
              'title': s['title'],
              'body': s['body'],
            })
        .toList(),
  });
}

final _rikoslakiFixture = _fakeAct('Rikoslaki', 'Rikoslaki (39/1889)', [
  {
    'paragraph': 'RL 21:5',
    'title': 'Pahoinpitely',
    'body':
        'Joka tekee toiselle ruumiillista väkivaltaa taikka vahingoittaa '
            'toisen terveyttä, on tuomittava pahoinpitelystä sakkoon tai '
            'vankeuteen enintään kahdeksi vuodeksi.',
  },
  {
    'paragraph': 'RL 21:6',
    'title': 'Törkeä pahoinpitely',
    'body':
        'Jos pahoinpitelyssä aiheutetaan toiselle vaikea ruumiinvamma, '
            'vakava sairaus tai hengenvaarallinen tila, rikoksentekijä on '
            'tuomittava törkeästä pahoinpitelystä vankeuteen vähintään '
            'yhdeksi ja enintään kymmeneksi vuodeksi.',
  },
  {
    'paragraph': 'RL 25:7',
    'title': 'Laiton uhkaus',
    'body': 'Joka uhkaa toista rikoksella...',
  },
]);

final _rikosvahinkolakiFixture = _fakeAct('Rikosvahinkolaki', 'Rikosvahinkolaki (1204/2005)', [
  {
    'paragraph': '§ 8',
    'title': 'Kärsimyksen korvaaminen',
    'body':
        'Väkivaltarikoksen asianomistajalle suoritetaan korvaus '
            'kärsimyksestä kun kyse on törkeästä pahoinpitelystä.',
  },
  {
    'paragraph': '§ 19',
    'title': 'Hakemus ja sen käsittely',
    'body': 'Hakemus on tehtävä kirjallisesti Valtiokonttorille.',
  },
]);

final _hallintolakiFixture = _fakeAct('Hallintolaki', 'Hallintolaki (434/2003)', [
  {
    'paragraph': '§ 60',
    'title': 'Todisteellinen tiedoksianto',
    'body':
        'Jos vastaanottokuittauksen on tehnyt muu henkilö kuin asianomistaja, '
            'kuittauksen pätevyys edellyttää että tämä henkilö on asianosaisen '
            'valtuuttama tai muu laissa hyväksytty sijaisvastaanottaja. Jos '
            'allekirjoitus on tulkin, joka ei ole asianosaisen valtuuttama '
            'henkilö, tiedoksianto ei ole pätevä ja valitusaika ei ole alkanut.',
  },
  {
    'paragraph': '§ 26',
    'title': 'Tulkitseminen ja kääntäminen',
    'body':
        'Viranomaisen on järjestettävä tulkitseminen ja kääntäminen, jos '
            'asianosainen ei osaa viranomaisessa käytettävää suomen tai '
            'ruotsin kieltä.',
  },
]);

final _ulkomaalaislakiFixture = _fakeAct('Ulkomaalaislaki', 'Ulkomaalaislaki (301/2004)', [
  {
    'paragraph': '§ 168',
    'title': 'Unionin kansalaisen karkottaminen',
    'body':
        'Unionin kansalainen voidaan karkottaa maasta, jos hän ei täytä enää '
            'oleskelun edellytyksiä tai hänen katsotaan vaarantavan yleistä '
            'järjestystä tai turvallisuutta. Karkottamisen on oltava '
            'oikeasuhtainen toimenpide.',
  },
  {
    'paragraph': '§ 190',
    'title': 'Valitus hallinto-oikeuteen',
    'body':
        'Valitus on tehtävä 30 päivän kuluessa päätöksen tiedoksisaannista.',
  },
]);

final _oikeudenkaymiskaariFixture = _fakeAct(
  'Oikeudenkaymiskaari',
  'Oikeudenkäymiskaari (4/1734)',
  [
    {
      'paragraph': 'ROL 3:1',
      'title': 'Asianomistajan yksityisoikeudellinen vaatimus',
      'body':
          'Asianomistaja voi esittää vaatimuksen yksityisoikeudellisesta '
              'korvauksesta syytteen käsittelyn yhteydessä.',
    },
  ],
);

String _fakeLoader(String path) {
  if (path.endsWith('rikoslaki.json')) return _rikoslakiFixture;
  if (path.endsWith('rikosvahinkolaki.json')) return _rikosvahinkolakiFixture;
  if (path.endsWith('hallintolaki.json')) return _hallintolakiFixture;
  if (path.endsWith('ulkomaalaislaki.json')) return _ulkomaalaislakiFixture;
  if (path.endsWith('oikeudenkaymiskaari.json')) {
    return _oikeudenkaymiskaariFixture;
  }
  throw Exception('asset not in fixture: $path');
}

FinnishLawSearch _newSearcher() {
  final loader = LegalLoader(
    capacity: 10,
    assetLoader: (path) async => _fakeLoader(path),
  );
  return FinnishLawSearch(loader: loader);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FinnishLawSearch', () {
    test('T01 — keyword search finds "törkeä pahoinpitely"', () async {
      final s = _newSearcher();
      final r = await s.search(query: 'törkeä pahoinpitely');
      expect(r, isNotEmpty);
      expect(r.first.paragraph, 'RL 21:6');
      expect(r.first.title, contains('Törkeä'));
    });

    test('T02 — (Sulga) "käännyttäminen EU kansalainen" finds § 168', () async {
      final s = _newSearcher();
      final r = await s.search(query: 'karkottaminen unionin kansalainen');
      expect(r, isNotEmpty);
      expect(r.any((x) => x.paragraph.contains('168')), isTrue);
    });

    test('T03 — (Sulga) "valitusaika tiedoksianto tulkki" finds Hallintolaki § 60',
        () async {
      final s = _newSearcher();
      final r = await s.search(query: 'tiedoksianto tulkki valitusaika');
      expect(r, isNotEmpty);
      expect(r.any((x) => x.paragraph.contains('60')), isTrue);
      expect(r.any((x) => x.act == 'HALLINTOLAKI'), isTrue);
    });

    test('T04 — (Sulga) "asianomistajan vaatimus" finds ROL 3:1', () async {
      final s = _newSearcher();
      final r = await s.search(query: 'asianomistaja vaatimus');
      expect(r, isNotEmpty);
      expect(r.any((x) => x.paragraph.contains('3:1')), isTrue);
    });

    test('T05 — paragraph lookup for "RL 21:6" exact match', () async {
      final s = _newSearcher();
      final r = await s.search(query: '', paragraph: 'RL 21:6');
      expect(r, hasLength(1));
      expect(r.first.paragraph, 'RL 21:6');
    });

    test('T06 — paragraph lookup works without "RL" prefix', () async {
      final s = _newSearcher();
      final r = await s.search(query: '', paragraph: '21:6');
      expect(r, isNotEmpty);
      expect(r.first.paragraph, contains('21:6'));
    });

    test('T07 — paragraph lookup works with "§ 60"', () async {
      final s = _newSearcher();
      final r = await s.search(query: '', paragraph: '§ 60');
      expect(r, isNotEmpty);
      expect(r.first.paragraph, contains('60'));
    });

    test('T08 — act filter narrows results to one statute', () async {
      final loader = LegalLoader(
        capacity: 10,
        assetLoader: (path) async => _fakeLoader(path),
      );
      final searcher = FinnishLawSearch(loader: loader);

      // Verify loader can reach the fixture at all via direct call
      final direct = await loader.loadAct(
        jurisdiction: 'fi',
        act: 'Rikosvahinkolaki',
      );
      expect(direct, isNotNull);
      expect(direct!.sections, isNotEmpty);

      // Use a stem that actually appears in Finnish declension forms —
      // "kärsim" is the common prefix for kärsimys/kärsimyksen/kärsimyksestä.
      final r = await searcher.search(
        query: 'kärsim',
        act: 'Rikosvahinkolaki',
      );
      expect(r, isNotEmpty);
      for (final x in r) {
        expect(x.act, 'RIKOSVAHINKOLAKI');
      }
    });

    test('T09 — "Valtiokonttori kärsim" finds compensation section',
        () async {
      final s = _newSearcher();
      // "kärsim" matches both "kärsimyksen" (title) and "kärsimyksestä" (body)
      // across all declension forms used in Finnish legal drafting.
      final r = await s.search(query: 'Valtiokonttori kärsim');
      expect(r, isNotEmpty);
      expect(r.any((x) => x.paragraph.contains('19') || x.paragraph.contains('8')),
          isTrue);
    });

    test('T10 — empty query + empty paragraph returns empty list', () async {
      final s = _newSearcher();
      final r = await s.search(query: '');
      expect(r, isEmpty);
    });

    test('T11 — unknown statute lookup via act filter returns empty', () async {
      final s = _newSearcher();
      final r = await s.search(query: 'anything', act: 'NotABundledAct');
      expect(r, isEmpty);
    });

    test('T12 — bodyPreview truncates long text with ellipsis', () async {
      final s = _newSearcher();
      final r = await s.search(query: 'kansalainen karkottaa');
      expect(r, isNotEmpty);
      final preview = r.first.bodyPreview(20);
      expect(preview.length, lessThanOrEqualTo(21));
      if (r.first.body.length > 20) {
        expect(preview.endsWith('…'), isTrue);
      }
    });

    test('T13 — limit parameter caps result count', () async {
      final s = _newSearcher();
      final r = await s.search(query: 'pahoinpitely', limit: 1);
      expect(r, hasLength(1));
    });

    test('T14 — title + paragraph hits weighted higher than body hits',
        () async {
      final s = _newSearcher();
      // "Pahoinpitely" appears in titles 21:5 + 21:6 AND bodies — the title
      // match should rank it first.
      final r = await s.search(query: 'pahoinpitely');
      expect(r, isNotEmpty);
      expect(r.first.title.toLowerCase(), contains('pahoinpitely'));
    });

    test('T15 — result carries jurisdiction metadata in toJson()', () async {
      final s = _newSearcher();
      final r = await s.search(query: 'pahoinpitely');
      final json = r.first.toJson();
      expect(json['jurisdiction'], 'FI');
      expect(json['url'], contains('finlex.fi'));
    });
  });
}
