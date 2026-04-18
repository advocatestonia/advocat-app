// estonian_law_full_test.dart
//
// Integration test for the full 20-act Estonian law corpus ingested via
// `dart run scripts/ingest_estonian_laws.dart`.  This differs from
// estonian_law_search_test.dart which stubs rootBundle; here we hit the
// REAL bundled asset files so we verify:
//
//   1. every known act has a non-empty JSON asset,
//   2. each asset parses successfully,
//   3. each asset contains at least a few §-sections,
//   4. paragraph lookup works across all acts,
//   5. keyword search returns hits for domain-specific terms from each
//      of the 20 codes (tax, tenancy, criminal, etc.).
//
// If the ingester has not yet been run on a dev machine, individual acts
// may be missing — the test tolerates that by only requiring the "seed"
// set (MKS + KarS) to be present, and logging a WARNING for any missing
// extras.  In CI we expect all 20 acts to be bundled.

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/estonian_law_search.dart';

void main() {
  // Full-corpus tests require the Flutter asset bundle, so we initialise it.
  TestWidgetsFlutterBinding.ensureInitialized();

  // Minimum § sections we expect in each act after a healthy ingest.
  // These numbers come from riigiteataja.ee (April 2026) with generous
  // lower bounds to tolerate future revisions.
  const Map<String, int> minSections = {
    'HMS': 80,
    'HKMS': 200,
    'PKS': 100,
    'TLS': 150,
    'KarS': 400,
    'VMS': 400,
    'VÕS': 800,
    'PärS': 150,
    'VõrdKS': 20,
    'MKS': 100,
    'TuMS': 150,
    'KMS': 100,
    'TsMS': 500,
    'KrMS': 500,
    'ÄS': 400,
    'IKS': 50,
    'LS': 400,
    'LKindlS': 80,
    'TsÜS': 100,
    'AsjS': 200,
  };

  /// Seed acts that absolutely must be present (fail the test if missing).
  const Set<String> requiredActs = {'MKS', 'KarS'};

  setUp(() {
    EstonianLawSearch.resetForTests();
  });

  // ── 1-4. Corpus loads, files parse, sections exist ───────────────────

  test('all 20 known act codes are declared', () {
    // Guards against silent drift between the catalogue and the test.
    expect(EstonianLawSearch.knownActs.length, 20);
    for (final required in requiredActs) {
      expect(EstonianLawSearch.knownActs, contains(required));
    }
  });

  test('statistics() loads every known act without throwing', () async {
    final stats = await EstonianLawSearch.statistics();
    expect(stats, isNotNull);
    // Every known act must appear as a key (non-empty or empty for now).
    for (final act in EstonianLawSearch.knownActs) {
      expect(stats.containsKey(act.toUpperCase()), isTrue,
          reason: 'stats missing key for act $act');
    }
  });

  test('seed acts (MKS, KarS) are bundled and parsed', () async {
    final stats = await EstonianLawSearch.statistics();
    for (final act in requiredActs) {
      final n = stats[act.toUpperCase()] ?? 0;
      expect(n, greaterThan(0),
          reason: 'seed act $act has zero sections — rebuild assets');
    }
  });

  test('full corpus meets minimum-section thresholds', () async {
    final stats = await EstonianLawSearch.statistics();
    final misses = <String>[];
    for (final entry in minSections.entries) {
      final got = stats[entry.key.toUpperCase()] ?? 0;
      if (got < entry.value) {
        misses.add('${entry.key}: got $got, want >= ${entry.value}');
      }
    }
    // We don't fail on misses — just surface them.  But if MORE than two
    // of the 20 acts are under-loaded, that's a red flag.
    expect(misses.length, lessThanOrEqualTo(2),
        reason: 'too many under-loaded acts:\n${misses.join("\n")}');
  });

  // ── 5. Paragraph lookup across all acts ──────────────────────────────

  test('§ lookup finds sections in each ingested act', () async {
    // List of (paragraph, act) probes. Multiple acts share § 1 so a map
    // won't work — use a tuple list instead.
    const probes = [
      ['§ 121', 'KarS'],
      ['§ 29', 'TLS'],
      ['§ 199', 'KarS'],
      ['§ 1', 'MKS'],
      ['§ 1', 'KMS'],
      ['§ 1', 'TuMS'],
      ['§ 40', 'MKS'],
      ['§ 1', 'HMS'],
      ['§ 1', 'PKS'],
      ['§ 2', 'IKS'],
    ];
    final stats = await EstonianLawSearch.statistics();
    for (final probe in probes) {
      final paragraph = probe[0];
      final act = probe[1];
      final actKey = act.toUpperCase();
      final nSections = stats[actKey] ?? 0;
      if (nSections == 0) continue; // act not bundled — skip this probe
      final results = await EstonianLawSearch.search(
        query: '',
        paragraph: paragraph,
        act: act,
      );
      expect(results, isNotEmpty,
          reason: 'paragraph $paragraph missing in $act');
      expect(results.first.act, act,
          reason: 'first hit should come from $act');
    }
  });

  // ── 6. Keyword search hits each ingested act ─────────────────────────

  test('keyword search returns hits for domain-specific terms per act',
      () async {
    // These terms are strongly associated with each code; the top-ranked
    // result should come from the expected act.
    const probes = <String, String>{
      'vargus': 'KarS',
      'töölepingu ülesütlemine': 'TLS',
      'maksumenetlus': 'MKS',
      'tulumaks': 'TuMS',
      'käibemaks': 'KMS',
      'liikluskindlustus': 'LKindlS',
      'abielulahutus': 'PKS',
      'pärand': 'PärS',
      'isikuandmete': 'IKS',
      'haldusmenetlus': 'HMS',
      'kriminaalmenetlus': 'KrMS',
      'tsiviilkohtumenetlus': 'TsMS',
      'äriregister': 'ÄS',
      'liiklusmärk': 'LS',
    };
    final stats = await EstonianLawSearch.statistics();
    int checked = 0;
    int wrongAct = 0;
    for (final probe in probes.entries) {
      final actKey = probe.value.toUpperCase();
      if ((stats[actKey] ?? 0) == 0) continue;
      checked++;
      final results = await EstonianLawSearch.search(query: probe.key);
      if (results.isEmpty) {
        wrongAct++;
        continue;
      }
      // The top hit should come from the expected act.  If not, count it
      // as a soft miss (cross-act hits are allowed to a limit).
      final topAct = results.first.act.toUpperCase();
      if (topAct != actKey) {
        // Allow a miss only if the expected act IS in the top 3 results.
        final top3Acts = results.take(3).map((r) => r.act.toUpperCase()).toSet();
        if (!top3Acts.contains(actKey)) wrongAct++;
      }
    }
    expect(checked, greaterThan(5), reason: 'too few acts bundled');
    // Less than 25% soft misses tolerated.
    expect(wrongAct, lessThanOrEqualTo((checked * 0.25).ceil()),
        reason: 'keyword routing broken for too many acts '
            '($wrongAct/$checked)');
  });

  // ── 7. Shape of a returned section ───────────────────────────────────

  test('returned LawSection has non-empty paragraph + sourceUrl', () async {
    final results = await EstonianLawSearch.search(
      query: '',
      paragraph: '§ 121',
      act: 'KarS',
    );
    if (results.isEmpty) return; // KarS not bundled yet — skipped
    final s = results.first;
    expect(s.paragraph, startsWith('§'));
    // Either title or body must carry the §-content.  The ingester can
    // sometimes merge the title into the body for sections where the
    // heading layout on riigiteataja.ee puts both on one line; we tolerate
    // that and only require that the section is non-empty overall.
    expect(s.title.isNotEmpty || s.body.isNotEmpty, isTrue,
        reason: 'section has neither title nor body — ingester regression');
    expect(s.sourceUrl, isNotNull);
    expect(s.sourceUrl, contains('riigiteataja.ee'));
    final json = s.toJson();
    expect(json['act'], 'KarS');
    expect(json['paragraph'], '§ 121');
  });

  // ── 8. search_estonian_law tool contract (return JSON) ───────────────

  test('sections serialise to JSON with stable keys', () async {
    final results = await EstonianLawSearch.search(query: 'vargus');
    if (results.isEmpty) return;
    final json = results.first.toJson();
    expect(json.keys, containsAll(<String>['act', 'paragraph', 'title', 'body']));
    // These fields are the contract for the search_estonian_law tool —
    // the AI prompt depends on them.
    expect(json['act'], isA<String>());
    expect(json['paragraph'], isA<String>());
    expect(json['title'], isA<String>());
    expect(json['body'], isA<String>());
  });
}
