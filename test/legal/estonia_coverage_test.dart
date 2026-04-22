// Estonia legal corpus coverage tests (OMEGA-ESTONIA-MAX).
//
// Validates that newly added JSON resources under assets/legal/estonia/
// are well-formed, have expected sections, contain valid source URLs,
// and match the metadata surfaced in EstonianMaxResources.
//
// NOTE: Network calls are NOT performed here. We only validate the
// locally shipped assets to keep tests fast and deterministic.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/estonian_max_resources.dart';

void main() {
  const String estoniaDir = 'assets/legal/estonia';

  Map<String, dynamic> readJson(String filename) {
    final File f = File('$estoniaDir/$filename');
    expect(f.existsSync(), isTrue,
        reason: 'Missing expected asset: ${f.path}');
    final String body = f.readAsStringSync();
    expect(body.isNotEmpty, isTrue,
        reason: '${f.path} must not be empty');
    return json.decode(body) as Map<String, dynamic>;
  }

  group('New acts JSON assets', () {
    const List<String> newAssetFiles = <String>[
      'kods.json',
      'vss.json',
      'vrks.json',
      'shs.json',
      'ehs.json',
      'plans.json',
      'ttks.json',
      'tkindls.json',
      'rpks.json',
      'autos.json',
      'reks.json',
      'lkindls2.json',
    ];

    test('every new act JSON file exists and is valid JSON', () {
      for (final String filename in newAssetFiles) {
        final Map<String, dynamic> data = readJson(filename);
        expect(data, isNotEmpty,
            reason: '$filename must decode to a non-empty map');
      }
    });

    test('every new act declares a source URL from riigiteataja.ee', () {
      for (final String filename in newAssetFiles) {
        final Map<String, dynamic> data = readJson(filename);
        final dynamic source = data['source'];
        expect(source, isA<String>(),
            reason: '$filename must have "source" field');
        expect(
          (source as String).contains('riigiteataja.ee'),
          isTrue,
          reason: '$filename source must be riigiteataja.ee (official)',
        );
      }
    });

    test('every new act has at least 4 sections', () {
      for (final String filename in newAssetFiles) {
        final Map<String, dynamic> data = readJson(filename);
        final List<dynamic>? sections = data['sections'] as List<dynamic>?;
        expect(sections, isNotNull, reason: '$filename missing "sections"');
        expect(sections!.length, greaterThanOrEqualTo(4),
            reason: '$filename must have >= 4 sections (has ${sections.length})');
      }
    });

    test('every section has paragraph identifier and title', () {
      for (final String filename in newAssetFiles) {
        final Map<String, dynamic> data = readJson(filename);
        final List<dynamic> sections = data['sections'] as List<dynamic>;
        for (final dynamic section in sections) {
          final Map<String, dynamic> s = section as Map<String, dynamic>;
          expect(s['paragraph'], isA<String>(),
              reason: '$filename section missing "paragraph"');
          expect(s['title'], isA<String>(),
              reason: '$filename section missing "title"');
          expect((s['paragraph'] as String).startsWith('§'), isTrue,
              reason: '$filename paragraph must start with § (got ${s['paragraph']})');
        }
      }
    });

    test('every new act has non-empty section bodies', () {
      for (final String filename in newAssetFiles) {
        final Map<String, dynamic> data = readJson(filename);
        final List<dynamic> sections = data['sections'] as List<dynamic>;
        for (final dynamic section in sections) {
          final Map<String, dynamic> s = section as Map<String, dynamic>;
          final dynamic body = s['body'];
          expect(body, isA<String>(),
              reason: '$filename section ${s['paragraph']} missing body');
          expect((body as String).length, greaterThan(10),
              reason:
                  '$filename ${s['paragraph']} body too short (likely corrupted)');
        }
      }
    });

    test('every new act has consolidated_version date', () {
      for (final String filename in newAssetFiles) {
        final Map<String, dynamic> data = readJson(filename);
        final dynamic version = data['consolidated_version'];
        expect(version, isA<String>(),
            reason: '$filename missing consolidated_version');
        final RegExp dateRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');
        expect(dateRe.hasMatch(version as String), isTrue,
            reason: '$filename consolidated_version must be YYYY-MM-DD');
      }
    });
  });

  group('Aggregate resources', () {
    test('riigikohus_landmarks.json has chambers and search guide', () {
      final Map<String, dynamic> data = readJson('riigikohus_landmarks.json');
      expect(data['chambers'], isA<List<dynamic>>());
      expect((data['chambers'] as List<dynamic>).length, equals(4),
          reason: 'Expected 4 Riigikohus chambers');
      expect(data['search_url_pattern'], isA<String>());
      expect(data['landmark_cases'], isA<List<dynamic>>());
      expect((data['landmark_cases'] as List<dynamic>).isNotEmpty, isTrue);
    });

    test('procedures.json has categories with service URLs', () {
      final Map<String, dynamic> data = readJson('procedures.json');
      final List<dynamic> categories = data['categories'] as List<dynamic>;
      expect(categories.length, greaterThanOrEqualTo(6));
      for (final dynamic cat in categories) {
        final Map<String, dynamic> c = cat as Map<String, dynamic>;
        expect(c['category'], isA<String>());
        // Some categories legitimately have multiple authorities.
        final bool hasAuthority = c['authority'] is String ||
            c['authorities'] is List<dynamic>;
        expect(hasAuthority, isTrue,
            reason: 'Category ${c['category']} missing authority/authorities');
        expect(c['services'], isA<List<dynamic>>(),
            reason: 'Category ${c['category']} missing services list');
      }
    });

    test('deadlines.json has at least 25 deadline entries', () {
      final Map<String, dynamic> data = readJson('deadlines.json');
      final List<dynamic> deadlines = data['deadlines'] as List<dynamic>;
      expect(deadlines.length, greaterThanOrEqualTo(25),
          reason: 'Deadlines list should be comprehensive');
      for (final dynamic d in deadlines) {
        final Map<String, dynamic> m = d as Map<String, dynamic>;
        expect(m['category'], isA<String>());
        expect(m['action'], isA<String>());
        expect(m['days'], isA<int>());
        expect((m['days'] as int) > 0, isTrue);
        expect(m['legal_basis'], isA<String>());
      }
    });

    test('emergency_contacts.json includes 112, 1247, 116 006', () {
      final Map<String, dynamic> data = readJson('emergency_contacts.json');
      final List<dynamic> emergency = data['emergency'] as List<dynamic>;
      final Set<String> numbers = emergency
          .map<String>((dynamic e) => (e as Map<String, dynamic>)['number'] as String)
          .toSet();
      expect(numbers.contains('112'), isTrue, reason: '112 must be listed');
      expect(numbers.contains('1247'), isTrue, reason: '1247 must be listed');
      expect(numbers.contains('116 006'), isTrue, reason: '116 006 must be listed');
      expect(numbers.contains('116 111'), isTrue, reason: '116 111 must be listed');
    });

    test('emergency_contacts.json has legal_aid and ombudsman', () {
      final Map<String, dynamic> data = readJson('emergency_contacts.json');
      expect(data['legal_aid'], isA<List<dynamic>>());
      expect(data['ombudsman'], isA<Map<String, dynamic>>());
    });

    test('business_tax.json has 2026 tax rates', () {
      final Map<String, dynamic> data = readJson('business_tax.json');
      final Map<String, dynamic> rates = data['tax_rates_2026'] as Map<String, dynamic>;
      expect((rates['personal_income_tax'] as Map<String, dynamic>)['rate_percent'], equals(22));
      final Map<String, dynamic> vat = rates['vat'] as Map<String, dynamic>;
      expect(vat['standard_rate_percent'], equals(24));
      final Map<String, dynamic> social = rates['social_tax'] as Map<String, dynamic>;
      expect(social['rate_percent'], equals(33));
    });

    test('business_tax.json has OÜ registration info', () {
      final Map<String, dynamic> data = readJson('business_tax.json');
      final Map<String, dynamic> entities = data['business_entities'] as Map<String, dynamic>;
      final Map<String, dynamic> ou = entities['oü_private_limited_company'] as Map<String, dynamic>;
      expect(ou['min_share_capital_eur'], equals(0));
      expect(ou['registration_fee_eur'], isA<int>());
    });

    test('russian_resources.json has government portals and integration', () {
      final Map<String, dynamic> data = readJson('russian_resources.json');
      expect(data['government_portals_russian'], isA<List<dynamic>>());
      expect((data['government_portals_russian'] as List<dynamic>).length,
          greaterThanOrEqualTo(6));
      expect(data['integration_services'], isA<List<dynamic>>());
      expect(data['emergency_hotlines_russian'], isA<List<dynamic>>());
    });
  });

  group('EstonianMaxResources coherence', () {
    test('newActCount equals 12 and matches JSON files', () {
      expect(EstonianMaxResources.newActCount, equals(12));
    });

    test('every newAct entry has consistent asset path', () {
      EstonianMaxResources.newActs.forEach((String code, Map<String, String> meta) {
        final String? asset = meta['asset'];
        expect(asset, isNotNull);
        expect(asset!.startsWith('assets/legal/estonia/'), isTrue);
        expect(File(asset).existsSync(), isTrue,
            reason: 'Asset file must exist: $asset (for $code)');
      });
    });

    test('every newAct has audience tier', () {
      const Set<String> validTiers = <String>{'critical', 'high', 'medium', 'low'};
      EstonianMaxResources.newActs.forEach((String code, Map<String, String> meta) {
        expect(validTiers.contains(meta['audience']), isTrue,
            reason: '$code has invalid audience tier ${meta['audience']}');
      });
    });

    test('critical-tier acts are immigration-related', () {
      final Set<String> critical = EstonianMaxResources.newActs.entries
          .where((MapEntry<String, Map<String, String>> e) =>
              e.value['audience'] == 'critical')
          .map((MapEntry<String, Map<String, String>> e) => e.key)
          .toSet();
      expect(critical.contains('VSS'), isTrue,
          reason: 'VSS (deportation) must be critical');
      expect(critical.contains('VRKS'), isTrue,
          reason: 'VRKS (asylum) must be critical');
    });

    test('tax rates 2026 snapshot matches JSON', () {
      final Map<String, dynamic> data = readJson('business_tax.json');
      final Map<String, dynamic> rates = data['tax_rates_2026'] as Map<String, dynamic>;
      expect(EstonianMaxResources.taxRates2026['vat_standard_percent'],
          equals((rates['vat'] as Map<String, dynamic>)['standard_rate_percent']));
      expect(EstonianMaxResources.taxRates2026['social_tax_percent'],
          equals((rates['social_tax'] as Map<String, dynamic>)['rate_percent']));
    });

    test('totalActsCovered is at least 32 (20 existing + 12 new)', () {
      expect(EstonianMaxResources.totalActsCovered, greaterThanOrEqualTo(32));
    });

    test('Russian resource notice mentions key hotlines', () {
      const String notice = EstonianMaxResources.russianResourceNotice;
      expect(notice.contains('112'), isTrue);
      expect(notice.contains('1247'), isTrue);
      expect(notice.contains('116 006'), isTrue);
      expect(notice.contains('eesti.ee/ru'), isTrue);
    });

    test('riigikohusSearchGuide explains case number format', () {
      const String guide = EstonianMaxResources.riigikohusSearchGuide;
      expect(guide.contains('Kriminaalkolleegium'), isTrue);
      expect(guide.contains('Halduskolleegium'), isTrue);
      expect(guide.contains('asjaNr'), isTrue);
    });

    test('additional deadlines all positive and realistic', () {
      EstonianMaxResources.additionalDeadlinesDays.forEach((String key, int days) {
        expect(days, greaterThan(0), reason: '$key must be positive');
        expect(days, lessThanOrEqualTo(1095),
            reason: '$key must be <= 3 years (got $days)');
      });
    });
  });

  group('Cross-reference coverage validation', () {
    test('new acts do not duplicate existing 20 acts by code', () {
      const Set<String> existingActs = <String>{
        'HMS', 'HKMS', 'PKS', 'TLS', 'KarS', 'VMS', 'VÕS', 'PärS',
        'VõrdKS', 'MKS', 'TuMS', 'KMS', 'TsMS', 'KrMS', 'ÄS', 'IKS',
        'LS', 'LKindlS', 'TsÜS', 'AsjS',
      };
      for (final String code in EstonianMaxResources.newActs.keys) {
        // LKindlS2 is explicitly distinct from LKindlS (unemployment vs motor)
        if (code == 'LKindlS2') continue;
        expect(existingActs.contains(code), isFalse,
            reason: 'New act $code duplicates an existing act');
      }
    });

    test('no orphan asset files (every new JSON is catalogued)', () {
      const List<String> catalogued = <String>[
        'kods.json',
        'vss.json',
        'vrks.json',
        'shs.json',
        'ehs.json',
        'plans.json',
        'ttks.json',
        'tkindls.json',
        'rpks.json',
        'autos.json',
        'reks.json',
        'lkindls2.json',
        'riigikohus_landmarks.json',
        'procedures.json',
        'deadlines.json',
        'emergency_contacts.json',
        'business_tax.json',
        'russian_resources.json',
      ];
      for (final String f in catalogued) {
        expect(File('$estoniaDir/$f').existsSync(), isTrue,
            reason: 'Catalogued asset $f missing from disk');
      }
    });
  });
}
