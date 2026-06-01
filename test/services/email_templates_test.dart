// Pure-Dart regression for EmailTemplateRepository — the static lookup +
// placeholder-fill API behind the in-app "send a ready-made letter" feature.
//
// These templates get filled with user data and shown/sent verbatim, so the
// lookup contract (case-insensitive country, missing → null, no throw) and the
// [..]-placeholder substitution are worth locking. No Supabase/Flutter binding
// needed — everything here is pure.

import 'package:advocat/services/email_templates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmailTemplateRepository.get', () {
    test('finds a known (country, type) pair', () {
      final t = EmailTemplateRepository.get('FI', 'appeal');
      expect(t, isNotNull);
      expect(t!.country, 'FI');
      expect(t.type, 'appeal');
    });

    test('country lookup is case-insensitive (upper-cased internally)', () {
      final lower = EmailTemplateRepository.get('fi', 'appeal');
      final upper = EmailTemplateRepository.get('FI', 'appeal');
      expect(lower, isNotNull);
      expect(lower!.country, upper!.country);
      expect(lower.subject, upper.subject);
    });

    test('unknown pair → null (no throw)', () {
      expect(EmailTemplateRepository.get('ZZ', 'appeal'), isNull);
      expect(EmailTemplateRepository.get('FI', 'no_such_type'), isNull);
    });
  });

  group('EmailTemplateRepository.getByCountry / getByType', () {
    test('getByCountry is case-insensitive and non-empty for FI', () {
      final fi = EmailTemplateRepository.getByCountry('fi');
      expect(fi, isNotEmpty);
      expect(fi.every((t) => t.country == 'FI'), isTrue);
    });

    test('getByType filters to exactly that type', () {
      final appeals = EmailTemplateRepository.getByType('appeal');
      expect(appeals, isNotEmpty);
      expect(appeals.every((t) => t.type == 'appeal'), isTrue);
    });

    test('availableCountries / availableTypes are sorted + deduped', () {
      final countries = EmailTemplateRepository.availableCountries;
      final types = EmailTemplateRepository.availableTypes;
      expect(countries, equals([...countries]..sort()));
      expect(types, equals([...types]..sort()));
      expect(countries.toSet().length, countries.length);
      expect(types.toSet().length, types.length);
    });
  });

  group('EmailTemplateRepository.getLanguageForCountry', () {
    test('returns the language for a known country', () {
      expect(EmailTemplateRepository.getLanguageForCountry('FI'), 'fi');
    });

    test('unknown country → null (no throw)', () {
      expect(EmailTemplateRepository.getLanguageForCountry('ZZ'), isNull);
    });
  });

  group('EmailTemplateRepository.fillTemplate', () {
    test('substitutes [Key] placeholders in subject and body', () {
      final filled = EmailTemplateRepository.fillTemplate('FI', 'appeal', {
        'Nimi': 'Dmitri Sulga',
        'Asianumero': '5500/R/75170/25',
      });
      expect(filled, isNotNull);
      // FI/appeal subject is "...[Nimi], [Asianumero]" — both must resolve.
      expect(filled!.subject, contains('Dmitri Sulga'));
      expect(filled.subject, contains('5500/R/75170/25'));
      expect(filled.subject, isNot(contains('[Nimi]')));
      expect(filled.subject, isNot(contains('[Asianumero]')));
    });

    test('leaves untouched placeholders intact (partial fill)', () {
      final filled = EmailTemplateRepository.fillTemplate('FI', 'appeal', {
        'Nimi': 'Jane Doe',
      });
      expect(filled, isNotNull);
      // Asianumero was not provided → its bracket token survives verbatim.
      expect(filled!.subject, contains('Jane Doe'));
      expect(filled.subject, contains('[Asianumero]'));
    });

    test('preserves non-filled metadata (country/type/recipient/language)', () {
      final base = EmailTemplateRepository.get('FI', 'appeal')!;
      final filled =
          EmailTemplateRepository.fillTemplate('FI', 'appeal', const {})!;
      expect(filled.country, base.country);
      expect(filled.type, base.type);
      expect(filled.recipientHint, base.recipientHint);
      expect(filled.language, base.language);
      // Empty placeholder map → subject/body unchanged.
      expect(filled.subject, base.subject);
      expect(filled.body, base.body);
    });

    test('unknown pair → null (no throw)', () {
      expect(
        EmailTemplateRepository.fillTemplate('ZZ', 'appeal', const {}),
        isNull,
      );
    });
  });

  group('data integrity', () {
    test('every template has the core fields populated', () {
      for (final t in EmailTemplateRepository.allTemplates) {
        expect(t.country, isNotEmpty, reason: 'country must be set');
        expect(t.type, isNotEmpty, reason: 'type must be set');
        expect(t.subject, isNotEmpty, reason: '${t.country}/${t.type} subject');
        expect(t.body, isNotEmpty, reason: '${t.country}/${t.type} body');
        expect(t.language, isNotEmpty, reason: '${t.country}/${t.type} lang');
      }
    });

    test('(country, type) pairs are unique — get() is unambiguous', () {
      final seen = <String>{};
      for (final t in EmailTemplateRepository.allTemplates) {
        final key = '${t.country}/${t.type}';
        expect(seen.add(key), isTrue, reason: 'duplicate template $key');
      }
    });
  });
}
