import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Loads an ARB file and returns its key-value map.
Map<String, dynamic> _loadArb(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: 'ARB file not found: $path');
  final content = file.readAsStringSync();
  return jsonDecode(content) as Map<String, dynamic>;
}

/// Translation keys (not metadata keys starting with @).
Set<String> _translationKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

/// Metadata keys (starting with @ but not @@).
Set<String> _metadataKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => k.startsWith('@') && !k.startsWith('@@')).toSet();

/// The ICU named-placeholder arguments referenced by a value string. Matches
/// `{name}` interpolations AND the `{name, plural|select, ...}` argument name,
/// but NOT plain words inside plural/select branches (e.g. `=0{today}` or
/// `other{...}`) which are translatable literals, not placeholders.
Set<String> _placeholders(String value) {
  // The plural/select argument name(s), e.g. {count, plural, ...}.
  final arg = RegExp(r'\{([a-zA-Z][a-zA-Z0-9_]*),\s*(?:plural|select)');
  final args = arg.allMatches(value).map((m) => m.group(1)!).toSet();

  // Branch-body stripping only makes sense INSIDE an ICU plural/select
  // construct, where a selector (=0 / one / other / a word) is immediately
  // followed by a `{...}` body whose inner text is a translatable literal, not
  // a placeholder. In a PLAIN interpolation string (no plural/select), every
  // `{name}` is a real placeholder — and a leading translated word like
  // `Liko {days}` / `no {total}` must NOT be mistaken for a branch selector.
  // So only run the branch strip when the value actually contains plural/select.
  var stripped = value;
  if (args.isNotEmpty) {
    final branch = RegExp(r'(=\d+|[a-zA-Z]+)\s*\{[^{}]*\}');
    String prev;
    do {
      prev = stripped;
      stripped = stripped.replaceAll(branch, '');
    } while (stripped != prev);
  }

  // Whatever bare `{name}` remains is a real interpolation placeholder.
  final named = RegExp(r'\{([a-zA-Z][a-zA-Z0-9_]*)\}');
  final names = named.allMatches(stripped).map((m) => m.group(1)!).toSet();

  return {...args, ...names};
}

void main() {
  const basePath = 'lib/l10n';

  // Every locale registered in supportedLanguages / AppLocalizations.
  // Keep in sync with lib/l10n/*.arb — the discovery test below asserts that.
  const allLocales = <String>[
    'ar', 'de', 'en', 'es', 'et', 'fa', 'fi', 'fr', 'it',
    'lt', 'lv', 'pl', 'ro', 'ru', 'sv', 'tr', 'uk',
  ];

  late Map<String, dynamic> enArb;
  late Set<String> enKeys;
  // locale -> arb map / translation key set
  final arbs = <String, Map<String, dynamic>>{};
  final keys = <String, Set<String>>{};

  setUpAll(() {
    enArb = _loadArb('$basePath/app_en.arb');
    enKeys = _translationKeys(enArb);
    for (final loc in allLocales) {
      final arb = _loadArb('$basePath/app_$loc.arb');
      arbs[loc] = arb;
      keys[loc] = _translationKeys(arb);
    }
  });

  group('Locale discovery', () {
    test('every app_*.arb on disk is in the tested allLocales set', () {
      final onDisk = Directory(basePath)
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .where((n) => n.startsWith('app_') && n.endsWith('.arb'))
          .map((n) => n.substring(4, n.length - 4))
          .toSet();
      expect(
        onDisk.difference(allLocales.toSet()),
        isEmpty,
        reason: 'New ARB file(s) not covered by the parity test — '
            'add them to allLocales.',
      );
      expect(
        allLocales.toSet().difference(onDisk),
        isEmpty,
        reason: 'allLocales references a locale with no ARB file.',
      );
    });

    test('each ARB declares its own @@locale', () {
      for (final loc in allLocales) {
        expect(arbs[loc]!['@@locale'], loc,
            reason: 'app_$loc.arb has wrong @@locale');
      }
    });
  });

  group('Key completeness — every locale matches the English template', () {
    test('no locale is missing any English key (silent en fallback)', () {
      final problems = <String>[];
      for (final loc in allLocales) {
        final missing = enKeys.difference(keys[loc]!);
        if (missing.isNotEmpty) {
          problems.add(
              '$loc missing ${missing.length}: ${missing.take(8).join(", ")}');
        }
      }
      expect(problems, isEmpty, reason: problems.join('\n'));
    });

    test('no locale carries a stale key absent from the template', () {
      final problems = <String>[];
      for (final loc in allLocales) {
        final extra = keys[loc]!.difference(enKeys);
        if (extra.isNotEmpty) {
          problems.add('$loc extra: ${extra.join(", ")}');
        }
      }
      expect(problems, isEmpty, reason: problems.join('\n'));
    });
  });

  group('No empty translation values', () {
    test('every locale value is a non-empty string', () {
      final problems = <String>[];
      for (final loc in allLocales) {
        final arb = arbs[loc]!;
        for (final key in keys[loc]!) {
          final v = arb[key];
          if (v is String && v.isEmpty) {
            problems.add('$loc."$key" is empty');
          }
        }
      }
      expect(problems, isEmpty, reason: problems.take(20).join('\n'));
    });
  });

  group('ICU placeholder integrity across locales', () {
    test('each locale preserves the English placeholder set per key', () {
      final problems = <String>[];
      for (final key in enKeys) {
        final en = enArb[key];
        if (en is! String) continue;
        final want = _placeholders(en);
        if (want.isEmpty) continue;
        for (final loc in allLocales) {
          if (loc == 'en') continue;
          final v = arbs[loc]![key];
          if (v is! String) continue;
          final got = _placeholders(v);
          if (!want.difference(got).isEmpty) {
            problems.add(
                '$loc."$key" lost placeholder(s) ${want.difference(got)} '
                '(want $want, got $got)');
          }
        }
      }
      expect(problems, isEmpty, reason: problems.take(20).join('\n'));
    });
  });

  group('Key naming conventions', () {
    test('all template keys use camelCase', () {
      for (final key in enKeys) {
        expect(key, matches(RegExp(r'^[a-z][a-zA-Z0-9]*$')),
            reason: 'Key "$key" is not camelCase');
      }
    });
  });

  group('Critical UI strings present in template', () {
    test('login/register/settings/nav/checker/docs/GDPR/error keys exist', () {
      const required = <String>[
        'logIn', 'signIn', 'email', 'password', 'forgotPassword',
        'createAccount', 'signUp', 'confirmPassword', 'fullName',
        'settings', 'language', 'signOut', 'deleteAccount',
        'home', 'cases', 'deadlines',
        'checkCompany', 'checkVehicle', 'checkerTitle',
        'documents', 'scanDocument', 'uploadDocument',
        'gdprIntro', 'gdprChat', 'gdprDocs', 'gdprStorage', 'gdprDelete',
        'privacyPolicy',
        'error', 'loading', 'retry', 'cancel', 'confirm',
        'legalEntityName', 'legalRegistryCode', 'legalAddress', 'legalEmail',
      ];
      for (final key in required) {
        expect(enKeys, contains(key), reason: 'missing critical key "$key"');
      }
    });
  });

  group('Metadata integrity for parameterized strings', () {
    test('every parameterized English string has @-metadata', () {
      final metaKeys = _metadataKeys(enArb);
      for (final key in enKeys) {
        final value = enArb[key];
        if (value is String && value.contains(RegExp(r'\{[a-zA-Z]+\}'))) {
          expect(metaKeys, contains('@$key'),
              reason: 'Parameterized key "$key" missing @-metadata');
        }
      }
    });
  });

  group('Reasonable translation lengths', () {
    test('no translation exceeds 2000 chars', () {
      for (final loc in allLocales) {
        final arb = arbs[loc]!;
        for (final key in keys[loc]!) {
          final v = arb[key];
          if (v is String) {
            expect(v.length, lessThan(2000),
                reason: '$loc."$key" excessively long: ${v.length}');
          }
        }
      }
    });
  });
}
