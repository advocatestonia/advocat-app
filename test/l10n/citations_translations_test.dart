@Tags(['fast'])
library;

// =============================================================================
// citations_translations_test.dart — Phase 2 Pkg 2 closeout
// =============================================================================
//
// 2026-05-06 — When the Pkg 2 frontend agent shipped citation chips +
// bottom sheet + footer, only en / et / fi / ru got curated translations.
// The other 13 locales (ar, de, es, fa, fr, it, lt, lv, pl, ro, sv, tr,
// uk) carried English placeholder text — visible to every user on those
// locales as untranslated chrome inside an otherwise localised app.
//
// This test pins the closeout: every citation key is present in every
// locale AND, for the locales we expect to be translated (everything
// except en), the value is not the English placeholder. Without the
// "differs from English" check the test would pass after a copy-paste of
// the English ARB into another locale — defeats the purpose.
//
// Two intentionally-untranslated values are whitelisted:
//   • The literal product noun "Riigi Teataja" is the Estonian Official
//     Journal's name and stays untranslated everywhere (so the link button
//     keeps the right word). Locales prepend a translated verb — e.g.
//     German "Im Riigi Teataja öffnen" — but the proper noun itself is
//     preserved verbatim.
//   • The {count} placeholder in plural-style strings is locale-agnostic
//     by design (Flutter intl substitutes at runtime).
//
// We also pin the contract that the @placeholders metadata for the
// {count} keys is identical across locales — Flutter's gen_l10n requires
// the placeholders block in EVERY locale ARB or it dies with a missing-
// metadata error.
// =============================================================================

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _basePath = 'lib/l10n';

/// All locales with an .arb file. Kept in sync with the ARB list (lib/l10n/).
const _allLocales = <String>[
  'ar', 'de', 'en', 'es', 'et', 'fa', 'fi', 'fr', 'it', 'lt',
  'lv', 'pl', 'ro', 'ru', 'sv', 'tr', 'uk',
];

/// Locales that fell back to English placeholders before the closeout —
/// EVERY one of these must now carry a translation distinct from English.
const _localesNeedingTranslation = <String>[
  'ar', 'de', 'es', 'fa', 'fr', 'it', 'lt',
  'lv', 'pl', 'ro', 'sv', 'tr', 'uk',
];

/// Citation-specific keys shipped by Pkg 2. Source of truth: app_en.arb
/// lines 1124-1166. 15 keys total (3 status badges, 3 status tooltips,
/// 1 RT link button, 2 snippet expand/collapse, 1 unverified sheet note,
/// 1 footer no-citations warning, 4 footer summary plurals).
const _citationKeys = <String>[
  'citationStatusVerifiedBadge',
  'citationStatusUnverifiedBadge',
  'citationStatusHistoricalBadge',
  'citationStatusVerifiedTooltip',
  'citationStatusUnverifiedTooltip',
  'citationStatusHistoricalTooltip',
  'citationOpenInRiigiTeataja',
  'citationSnippetExpand',
  'citationSnippetCollapse',
  'citationUnverifiedSheetNote',
  'citationFooterNoneWarning',
  'citationFooterSummaryTotal',
  'citationFooterSummaryVerified',
  'citationFooterSummaryUnverified',
  'citationFooterSummaryHistorical',
];

/// Plural-bearing keys whose @placeholders metadata block must mirror
/// English in every locale (Flutter gen_l10n requirement).
const _pluralCitationKeys = <String>[
  'citationFooterSummaryTotal',
  'citationFooterSummaryVerified',
  'citationFooterSummaryUnverified',
  'citationFooterSummaryHistorical',
];

Map<String, dynamic> _loadArb(String locale) {
  final file = File('$_basePath/app_$locale.arb');
  expect(file.existsSync(), isTrue,
      reason: 'ARB file missing: $_basePath/app_$locale.arb');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

void main() {
  late Map<String, Map<String, dynamic>> arbs;

  setUpAll(() {
    arbs = {for (final l in _allLocales) l: _loadArb(l)};
  });

  group('citation keys — presence in every locale', () {
    for (final locale in _allLocales) {
      test('$locale has all 15 citation keys', () {
        final arb = arbs[locale]!;
        for (final key in _citationKeys) {
          expect(arb.containsKey(key), isTrue,
              reason: '$locale is missing citation key "$key"');
          final v = arb[key];
          expect(v is String && v.isNotEmpty, isTrue,
              reason: '$locale citation key "$key" is empty/non-string');
        }
      });
    }
  });

  group('citation keys — translated (not the English placeholder)', () {
    final enArb = <String, dynamic>{};
    setUpAll(() => enArb.addAll(_loadArb('en')));

    for (final locale in _localesNeedingTranslation) {
      test('$locale citation strings differ from English (proper translation)', () {
        final arb = arbs[locale]!;
        // Identify which keys are still mirroring English. ANY key still
        // matching English is a closeout regression — except the
        // "Riigi Teataja" link, where the proper noun is preserved while
        // surrounding verb is translated. We require the FULL string not
        // to be byte-equal to English; a German translation that starts
        // with "Im Riigi Teataja..." counts as translated even though the
        // proper noun is shared.
        final stillEnglish = <String>[];
        for (final key in _citationKeys) {
          final localized = arb[key] as String?;
          final english = enArb[key] as String?;
          if (localized == null || english == null) continue;
          if (localized == english) {
            stillEnglish.add(key);
          }
        }
        expect(stillEnglish, isEmpty,
            reason: '$locale still uses English text for: '
                '${stillEnglish.join(", ")}');
      });
    }
  });

  group('plural placeholders — metadata mirrored across locales', () {
    for (final locale in _allLocales) {
      test('$locale declares @-metadata for every plural citation key', () {
        final arb = arbs[locale]!;
        for (final key in _pluralCitationKeys) {
          // Either the locale explicitly declares its own @-metadata, OR
          // it inherits from another locale via `@@locale` — but the safe,
          // forward-compatible contract is that every locale declares
          // its own block (matches en/et/fi/ru).
          final metaKey = '@$key';
          expect(arb.containsKey(metaKey), isTrue,
              reason: '$locale missing @-metadata for "$key" '
                  '(plural key requires {count: int} placeholders block)');
          final meta = arb[metaKey];
          expect(meta is Map, isTrue,
              reason: '$locale @-metadata for "$key" is not a Map');
          final placeholders =
              (meta as Map<String, dynamic>)['placeholders'] as Map?;
          expect(placeholders, isNotNull,
              reason: '$locale @-metadata for "$key" lacks "placeholders"');
          expect(placeholders!.containsKey('count'), isTrue,
              reason: '$locale @-metadata for "$key" missing "count" '
                  'placeholder');
        }
      });
    }
  });

  group('plural strings preserve {count} placeholder', () {
    for (final locale in _allLocales) {
      test('$locale plural strings still contain {count}', () {
        // A common translation mistake: the translator drops the literal
        // {count} (or replaces it with a number). Flutter's intl runtime
        // then renders the literal text instead of substituting — a
        // visible bug. This pins it to fail at lint time, not at user time.
        final arb = arbs[locale]!;
        for (final key in _pluralCitationKeys) {
          final v = arb[key] as String?;
          expect(v, isNotNull, reason: '$locale missing "$key"');
          expect(v!.contains('{count}'), isTrue,
              reason: '$locale "$key" lost the {count} placeholder: "$v"');
        }
      });
    }
  });
}
