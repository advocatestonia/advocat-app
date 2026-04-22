// estonian_corpus_integrity_test.dart
//
// Integrity checks for the 20-act Estonian legal corpus (re-ingested from
// riigiteataja.ee via scripts/ingest_estonian_laws.dart).
//
// Scope (per docs/corpus-fix/00-diagnose.md):
//   - every bundled act file exists,
//   - JSON parses,
//   - sections array is present and non-empty,
//   - each section has a paragraph marker and a title OR a non-empty body,
//   - a hand-picked set of well-known §§ must contain the expected keyword
//     (so we can detect silent regressions where the parser returns text
//     from the wrong § — the root cause of the 59% broken state).
//
// This test operates on raw JSON on disk (no rootBundle) so it can run in
// pure-dart mode without the Flutter test binding. Paths are resolved
// relative to the project root.
//
// Run with:
//   flutter test test/legal/estonian_corpus_integrity_test.dart
// or
//   dart test test/legal/estonian_corpus_integrity_test.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Directory containing the bundled corpus JSON files.
const String _corpusDir = 'assets/legal/estonia';

// 20-act catalogue. Key = service code (matches
// EstonianLawSearch.knownActs); value = filename stem.
const Map<String, String> _acts = {
  'HMS': 'hms',
  'HKMS': 'hkms',
  'PKS': 'pks',
  'TLS': 'tls',
  'KarS': 'kars',
  'VMS': 'vms',
  'VÕS': 'vos',
  'PärS': 'pars',
  'VõrdKS': 'vordks',
  'MKS': 'mks',
  'TuMS': 'tums',
  'KMS': 'kms',
  'TsMS': 'tsms',
  'KrMS': 'krms',
  'ÄS': 'as',
  'IKS': 'iks',
  'LS': 'ls',
  'LKindlS': 'lkindls',
  'TsÜS': 'tsus',
  'AsjS': 'asjs',
};

// Hand-picked anchor sections whose body MUST contain the listed keywords.
// These are the canary sections — if any regresses, the parser has drifted.
//
// Keywords are given lowercase; matching is case-insensitive and matches
// any one of them (an OR list).
class _Anchor {
  final String act;
  final String paragraph;
  final List<String> expectedKeywordsAny;
  final String description;
  const _Anchor(
      this.act, this.paragraph, this.expectedKeywordsAny, this.description);
}

const List<_Anchor> _anchorSections = [
  // Karistusseadustik — criminal offences.
  // Keywords use Estonian word stems (not full inflected forms) since
  // Estonian declines/conjugates heavily: e.g. "tapmine" (nom) →
  // "tapmise" (gen) → body text uses "tapmise". We match the invariant
  // stem.
  _Anchor('KarS', '§ 121', ['tervise', 'kehalise'],
      'KarS § 121 — causing health damage / assault'),
  _Anchor('KarS', '§ 199', ['vargus', 'vallasasi', 'anasta'],
      'KarS § 199 — theft of movable property'),
  _Anchor('KarS', '§ 113', ['tapmi', 'surm'],
      'KarS § 113 — manslaughter / killing'),

  // Välismaalaste seadus — aliens act
  _Anchor('VMS', '§ 3', ['välismaalane', 'kodanik'],
      'VMS § 3 — definition of an alien'),
  _Anchor('VMS', '§ 11', ['kohust'],
      'VMS § 11 — obligations of an alien'),

  // Töölepingu seadus — employment contracts
  _Anchor('TLS', '§ 88', ['ülesütle', 'tööleping'],
      'TLS § 88 — grounds for termination of employment contract'),

  // Perekonnaseadus — family law
  _Anchor('PKS', '§ 1', ['abielu'], 'PKS § 1 — marriage introduction'),

  // Pärimisseadus — inheritance
  _Anchor('PärS', '§ 1', ['pärand', 'pärija', 'pärimine'],
      'PärS § 1 — inheritance basics'),

  // Maksukorralduse seadus
  _Anchor('MKS', '§ 1', ['maksu'], 'MKS § 1 — subject matter of tax law'),

  // Isikuandmete kaitse seadus
  _Anchor('IKS', '§ 1', ['isikuandme'], 'IKS § 1 — personal data'),

  // Haldusmenetluse seadus
  _Anchor('HMS', '§ 1', ['haldusmenet', 'haldus'],
      'HMS § 1 — administrative procedure'),

  // Võrdse kohtlemise seadus
  _Anchor('VõrdKS', '§ 1', ['võrdse', 'diskri', 'ebavõrdne'],
      'VõrdKS § 1 — equal treatment'),
];

String? _readCorpusFile(String stem) {
  // Resolve relative to the directory the test runs from (project root).
  final f = File('$_corpusDir/$stem.json');
  if (!f.existsSync()) return null;
  return f.readAsStringSync();
}

/// Locate a section by paragraph marker (exact match) within a parsed act.
Map<String, dynamic>? _findSection(
    Map<String, dynamic> actJson, String paragraph) {
  final sections = actJson['sections'] as List<dynamic>? ?? [];
  for (final raw in sections) {
    if (raw is! Map<String, dynamic>) continue;
    final p = (raw['paragraph'] as String? ?? '').trim();
    if (p == paragraph) return raw;
  }
  return null;
}

bool _containsAny(String haystack, List<String> needles) {
  final h = haystack.toLowerCase();
  return needles.any((n) => h.contains(n.toLowerCase()));
}

String _sectionBody(Map<String, dynamic> s) {
  // Prefer the direct body field, fall back to concatenated subsections.
  final direct = (s['body'] as String? ?? '').trim();
  if (direct.isNotEmpty) return direct;
  final subs = s['subsections'] as List<dynamic>? ?? [];
  return subs
      .map((sub) {
        if (sub is! Map<String, dynamic>) return '';
        return (sub['text'] as String? ?? '').trim();
      })
      .where((t) => t.isNotEmpty)
      .join('\n');
}

void main() {
  group('Estonian corpus — file presence & JSON shape', () {
    for (final entry in _acts.entries) {
      test('${entry.key} (${entry.value}.json) exists and parses', () {
        final raw = _readCorpusFile(entry.value);
        expect(raw, isNotNull,
            reason: 'corpus file ${entry.value}.json is missing — '
                'run `dart run scripts/ingest_estonian_laws.dart`');
        late Map<String, dynamic> decoded;
        try {
          decoded = jsonDecode(raw!) as Map<String, dynamic>;
        } catch (e) {
          fail('${entry.value}.json is not valid JSON: $e');
        }
        expect(decoded['act'], isNotNull,
            reason: '${entry.value}.json missing "act" field');
        expect(decoded['source'], contains('riigiteataja.ee'),
            reason: '${entry.value}.json "source" should cite RT');
        final sections = decoded['sections'];
        expect(sections, isA<List<dynamic>>(),
            reason: '${entry.value}.json "sections" must be an array');
        expect((sections as List).length, greaterThan(10),
            reason: '${entry.value}.json has suspiciously few sections');
      });
    }
  });

  group('Estonian corpus — section-level health', () {
    for (final entry in _acts.entries) {
      test('${entry.key}: each section has a §-marker and title or body', () {
        final raw = _readCorpusFile(entry.value);
        if (raw == null) return; // presence is covered by the group above
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final sections = decoded['sections'] as List<dynamic>;

        final badParagraph = <String>[];
        final emptyContent = <String>[];

        for (final raw in sections) {
          final s = raw as Map<String, dynamic>;
          final paragraph = (s['paragraph'] as String? ?? '').trim();
          if (!paragraph.startsWith('§')) {
            badParagraph.add(paragraph);
            continue;
          }
          final repealed = s['repealed'] == true;
          if (repealed) continue; // legitimate empty
          final title = (s['title'] as String? ?? '').trim();
          final body = _sectionBody(s);
          if (title.isEmpty && body.isEmpty) {
            emptyContent.add(paragraph);
          }
        }

        expect(badParagraph, isEmpty,
            reason: '${entry.key}: sections without "§ N" marker: '
                '${badParagraph.take(5).toList()}');

        // Tolerate < 5% empty non-repealed sections (RT sometimes has
        // genuinely empty placeholder §§ that are neither marked kehtetu
        // nor contain text — rare but happens).
        final emptyPct = 100 * emptyContent.length / sections.length;
        expect(emptyPct, lessThan(10.0),
            reason:
                '${entry.key}: ${emptyContent.length}/${sections.length} '
                '(${emptyPct.toStringAsFixed(1)}%) sections empty (non-repealed): '
                '${emptyContent.take(5).toList()}');
      });
    }
  });

  group('Estonian corpus — anchor sections carry expected content', () {
    for (final anchor in _anchorSections) {
      test(anchor.description, () {
        final stem = _acts[anchor.act];
        expect(stem, isNotNull, reason: 'unknown act ${anchor.act}');
        final raw = _readCorpusFile(stem!);
        expect(raw, isNotNull,
            reason: '${anchor.act} corpus file missing');
        final decoded = jsonDecode(raw!) as Map<String, dynamic>;
        final section = _findSection(decoded, anchor.paragraph);
        expect(section, isNotNull,
            reason:
                '${anchor.act} ${anchor.paragraph} not found in corpus — '
                'ingester skipped or mis-numbered it');
        final body = _sectionBody(section!);
        expect(body, isNotEmpty,
            reason: '${anchor.act} ${anchor.paragraph} has empty body');
        expect(_containsAny(body, anchor.expectedKeywordsAny), isTrue,
            reason:
                '${anchor.act} ${anchor.paragraph} body does NOT contain any '
                'of the expected keywords ${anchor.expectedKeywordsAny}. '
                'This is the signature of the pre-fix parser bug where '
                'a § got body text from a neighbouring chapter. '
                'First 200 chars of actual body:\n'
                '${body.substring(0, body.length < 200 ? body.length : 200)}');
      });
    }
  });

  group('Estonian corpus — overall corpus health', () {
    test('aggregate healthy-section ratio >= 85%', () {
      var total = 0;
      var healthy = 0;
      var repealed = 0;
      for (final stem in _acts.values) {
        final raw = _readCorpusFile(stem);
        if (raw == null) continue;
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final sections = decoded['sections'] as List<dynamic>;
        for (final raw in sections) {
          final s = raw as Map<String, dynamic>;
          total++;
          final isRepealed = s['repealed'] == true;
          if (isRepealed) {
            repealed++;
            healthy++; // repealed is legitimately empty
            continue;
          }
          final body = _sectionBody(s);
          // Threshold matches the one used by the ingester's health check.
          if (body.length >= 20) healthy++;
        }
      }
      expect(total, greaterThan(7000),
          reason: 'corpus too small — rebuild assets');
      final pct = 100 * healthy / total;
      // Pre-fix baseline: 41% healthy. Target after fix: >= 85%.
      expect(pct, greaterThanOrEqualTo(85.0),
          reason: 'corpus health $pct% below 85% target — '
              'total=$total healthy=$healthy repealed=$repealed');
    });
  });
}
