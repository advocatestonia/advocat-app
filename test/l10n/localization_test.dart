import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Loads an ARB file and returns its key-value map.
/// Filters out metadata keys (starting with '@' or '@@').
Map<String, dynamic> _loadArb(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: 'ARB file not found: $path');
  final content = file.readAsStringSync();
  final Map<String, dynamic> json = jsonDecode(content) as Map<String, dynamic>;
  return json;
}

/// Returns only translation keys (not metadata keys starting with @).
Set<String> _translationKeys(Map<String, dynamic> arb) {
  return arb.keys.where((k) => !k.startsWith('@')).toSet();
}

/// Returns metadata keys (starting with @ but not @@).
Set<String> _metadataKeys(Map<String, dynamic> arb) {
  return arb.keys.where((k) => k.startsWith('@') && !k.startsWith('@@')).toSet();
}

void main() {
  // Resolve path relative to the test file location
  // Tests run from the project root, so lib/l10n/ is accessible directly
  final basePath = 'lib/l10n';

  late Map<String, dynamic> enArb;
  late Map<String, dynamic> fiArb;
  late Map<String, dynamic> ruArb;

  late Set<String> enKeys;
  late Set<String> fiKeys;
  late Set<String> ruKeys;

  setUpAll(() {
    enArb = _loadArb('$basePath/app_en.arb');
    fiArb = _loadArb('$basePath/app_fi.arb');
    ruArb = _loadArb('$basePath/app_ru.arb');

    enKeys = _translationKeys(enArb);
    fiKeys = _translationKeys(fiArb);
    ruKeys = _translationKeys(ruArb);
  });

  group('ARB file existence', () {
    test('English ARB exists', () {
      expect(File('$basePath/app_en.arb').existsSync(), isTrue);
    });

    test('Finnish ARB exists', () {
      expect(File('$basePath/app_fi.arb').existsSync(), isTrue);
    });

    test('Russian ARB exists', () {
      expect(File('$basePath/app_ru.arb').existsSync(), isTrue);
    });
  });

  group('Locale identifiers', () {
    test('English ARB has correct locale', () {
      expect(enArb['@@locale'], 'en');
    });

    test('Finnish ARB has correct locale', () {
      expect(fiArb['@@locale'], 'fi');
    });

    test('Russian ARB has correct locale', () {
      expect(ruArb['@@locale'], 'ru');
    });
  });

  group('Key completeness — no missing translations', () {
    test('Finnish has all English keys', () {
      final missingInFi = enKeys.difference(fiKeys);
      expect(missingInFi, isEmpty,
          reason:
              'Finnish is missing ${missingInFi.length} keys: ${missingInFi.take(10).join(", ")}');
    });

    test('Russian has all English keys', () {
      final missingInRu = enKeys.difference(ruKeys);
      expect(missingInRu, isEmpty,
          reason:
              'Russian is missing ${missingInRu.length} keys: ${missingInRu.take(10).join(", ")}');
    });

    test('English has all Finnish keys', () {
      final missingInEn = fiKeys.difference(enKeys);
      expect(missingInEn, isEmpty,
          reason:
              'English is missing ${missingInEn.length} keys from Finnish: ${missingInEn.take(10).join(", ")}');
    });

    test('English has all Russian keys', () {
      final missingInEn = ruKeys.difference(enKeys);
      expect(missingInEn, isEmpty,
          reason:
              'English is missing ${missingInEn.length} keys from Russian: ${missingInEn.take(10).join(", ")}');
    });

    test('All three locales have the same key set', () {
      expect(enKeys, equals(fiKeys),
          reason: 'English and Finnish key sets differ');
      expect(enKeys, equals(ruKeys),
          reason: 'English and Russian key sets differ');
    });
  });

  group('No empty translation values', () {
    test('English has no empty values', () {
      for (final key in enKeys) {
        final value = enArb[key];
        if (value is String) {
          expect(value.isNotEmpty, isTrue,
              reason: 'English key "$key" has an empty value');
        }
      }
    });

    test('Finnish has no empty values', () {
      for (final key in fiKeys) {
        final value = fiArb[key];
        if (value is String) {
          expect(value.isNotEmpty, isTrue,
              reason: 'Finnish key "$key" has an empty value');
        }
      }
    });

    test('Russian has no empty values', () {
      for (final key in ruKeys) {
        final value = ruArb[key];
        if (value is String) {
          expect(value.isNotEmpty, isTrue,
              reason: 'Russian key "$key" has an empty value');
        }
      }
    });
  });

  group('Key naming conventions', () {
    test('all keys use camelCase', () {
      for (final key in enKeys) {
        // camelCase: starts with lowercase letter, no underscores, no spaces
        expect(key, matches(RegExp(r'^[a-z][a-zA-Z0-9]*$')),
            reason: 'Key "$key" is not in camelCase');
      }
    });
  });

  group('Critical UI strings present', () {
    test('login-related keys exist', () {
      expect(enKeys, contains('logIn'));
      expect(enKeys, contains('signIn'));
      expect(enKeys, contains('email'));
      expect(enKeys, contains('password'));
      expect(enKeys, contains('forgotPassword'));
    });

    test('register-related keys exist', () {
      expect(enKeys, contains('createAccount'));
      expect(enKeys, contains('signUp'));
      expect(enKeys, contains('confirmPassword'));
      expect(enKeys, contains('fullName'));
    });

    test('settings-related keys exist', () {
      expect(enKeys, contains('settings'));
      expect(enKeys, contains('language'));
      expect(enKeys, contains('signOut'));
      expect(enKeys, contains('deleteAccount'));
    });

    test('navigation-related keys exist', () {
      expect(enKeys, contains('home'));
      expect(enKeys, contains('cases'));
      expect(enKeys, contains('deadlines'));
      expect(enKeys, contains('settings'));
    });

    test('checker-related keys exist', () {
      expect(enKeys, contains('checkCompany'));
      expect(enKeys, contains('checkVehicle'));
      expect(enKeys, contains('checkerTitle'));
    });

    test('document-related keys exist', () {
      expect(enKeys, contains('documents'));
      expect(enKeys, contains('scanDocument'));
      expect(enKeys, contains('uploadDocument'));
    });

    test('GDPR-related keys exist', () {
      expect(enKeys, contains('gdprIntro'));
      expect(enKeys, contains('gdprChat'));
      expect(enKeys, contains('gdprDocs'));
      expect(enKeys, contains('gdprStorage'));
      expect(enKeys, contains('gdprDelete'));
      expect(enKeys, contains('privacyPolicy'));
    });

    test('error and feedback keys exist', () {
      expect(enKeys, contains('error'));
      expect(enKeys, contains('loading'));
      expect(enKeys, contains('retry'));
      expect(enKeys, contains('cancel'));
      expect(enKeys, contains('confirm'));
    });

    test('legal entity information keys exist', () {
      expect(enKeys, contains('legalEntityName'));
      expect(enKeys, contains('legalRegistryCode'));
      expect(enKeys, contains('legalAddress'));
      expect(enKeys, contains('legalEmail'));
    });
  });

  group('Metadata integrity for parameterized strings', () {
    test('all parameterized English strings have @-metadata', () {
      // Strings with {param} placeholders should have corresponding @key metadata
      final metaKeys = _metadataKeys(enArb);
      for (final key in enKeys) {
        final value = enArb[key];
        if (value is String && value.contains(RegExp(r'\{[a-zA-Z]+\}'))) {
          final metaKey = '@$key';
          expect(metaKeys, contains(metaKey),
              reason:
                  'Parameterized key "$key" is missing @-metadata entry');
        }
      }
    });
  });

  group('Reasonable translation lengths', () {
    test('no translation is excessively long (>2000 chars)', () {
      for (final key in enKeys) {
        final value = enArb[key];
        if (value is String) {
          expect(value.length, lessThan(2000),
              reason: 'English key "$key" is excessively long: ${value.length} chars');
        }
      }
    });
  });
}
