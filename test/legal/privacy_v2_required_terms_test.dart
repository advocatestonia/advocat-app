@Tags(['fast'])
library;

// =============================================================================
// privacy_v2_required_terms_test.dart — privacy.html required-terms regression
// =============================================================================
//
// 2026-05-06 — Track B-3 of Pkg 0. Pins the contract that the public privacy
// policy at `web/privacy.html` includes the legally-required terms in every
// supported locale (EN/ET/RU at MVP scope; remaining 13 langs ship in a
// separate l10n PR).
//
// Required terms per locale (reconciled 2026-05-06 against actual privacy
// v3.1 wording — Track B-1 has landed):
//   EN: "Art. 9", "Art. 22", "Anthropic", "OpenAI", "dpo@advocat.ee",
//       "sub-processor"
//   ET: "artikkel 9", "artikkel 22", "Anthropic", "OpenAI", "dpo@advocat.ee"
//   RU: "ст. 9", "ст. 22", "Anthropic", "OpenAI", "dpo@advocat.ee"
//
// Comparison is case-insensitive: every term must appear verbatim (modulo
// case) inside privacy.html. Adding a term you cannot guarantee is a
// regression vector.
// =============================================================================

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Locale → required terms. Phrasing matches actual privacy.html v3.1
/// (EN uses GDPR-canonical "Art. 9 / Art. 22"; ET uses "artikkel 9 /
/// artikkel 22"; RU uses Russian-canonical "ст. 9 / ст. 22").
const Map<String, List<String>> _requiredTerms = {
  'EN': [
    'Art. 9', // GDPR special-category data
    'Art. 22', // GDPR right to opt out of automated decisions
    'Anthropic', // primary AI sub-processor (Claude)
    'OpenAI', // STT (Whisper) sub-processor
    'dpo@advocat.ee', // DPO contact for GDPR requests
    'sub-processor', // section heading must be present (case-insensitive)
  ],
  'ET': [
    'artikkel 9',
    'artikkel 22',
    'Anthropic',
    'OpenAI',
    'dpo@advocat.ee',
  ],
  'RU': [
    'ст. 9',
    'ст. 22',
    'Anthropic',
    'OpenAI',
    'dpo@advocat.ee',
  ],
};

void main() {
  // Resolve the privacy.html path. `flutter test` runs from the package
  // root, so this is a stable relative path. We avoid an absolute path so
  // the suite is portable to CI where the workspace lives elsewhere.
  final privacyFile = File('web/privacy.html');

  group('Privacy v2 — required terms per locale', () {
    late String htmlLower;

    setUpAll(() {
      if (!privacyFile.existsSync()) {
        fail(
          'web/privacy.html missing at ${privacyFile.absolute.path}. '
          'Privacy v2 must ship as a static file at the site root.',
        );
      }
      // Lower-case once, contains() for every term — case-insensitive
      // match is enough for "term is present in policy at all".
      htmlLower = privacyFile.readAsStringSync().toLowerCase();
    });

    test('file is non-trivial (sanity)', () {
      // Anything under ~5 KB is structurally too short to contain
      // 3 locales of full GDPR text. Catches an accidental truncation
      // or an empty-file deploy.
      expect(htmlLower.length, greaterThan(5000),
          reason: 'privacy.html unexpectedly short');
    });

    _requiredTerms.forEach((locale, terms) {
      group('$locale required terms', () {
        for (final term in terms) {
          test('contains: "$term"', () {
            expect(
              htmlLower,
              contains(term.toLowerCase()),
              reason: '$locale required term missing from web/privacy.html: '
                  '"$term"',
            );
          });
        }
      });
    });
  });
}
