import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/l10n/app_localizations.dart';

/// launch/wave1 UPL-audit regression (Agent 1-4).
///
/// UPL = Unauthorised Practice of Law. Several EU jurisdictions (DE
/// under RDG, FR, IT, AT) forbid a non-lawyer service from
/// self-identifying as a "lawyer" / "Anwalt" / "asianajaja". We ship
/// Advocat as an AI *assistant* — the onboarding copy must never call
/// it a юрист / адвокат / lawyer in the product name.
///
/// This test catches the regressive Russian and Ukrainian onboarding
/// titles ("ИИ-юрист" / "ШІ-юрист") and any future relapse.
void main() {
  group('UPL audit — onboarding titles are UPL-safe', () {
    const forbiddenSubstrings = [
      'юрист', // Russian / Ukrainian "lawyer"
      'адвокат', // Russian / Ukrainian "attorney"
      'advokaat', // Estonian
      'asianajaja', // Finnish
      'Rechtsanwalt', // German — must never be self-applied
      'Anwalt', // German short form
    ];

    test('tutorialStep1Title contains no UPL-regulated profession word',
        () async {
      // We check every locale the app actually ships.
      const locales = [
        'en', 'et', 'ru', 'fi', 'de', 'fr', 'es', 'it',
        'sv', 'pl', 'lt', 'lv', 'uk', 'ar', 'tr', 'ro', 'fa',
      ];
      for (final code in locales) {
        final l = await AppLocalizations.delegate.load(Locale(code));
        final title = l.tutorialStep1Title.toLowerCase();
        for (final word in forbiddenSubstrings) {
          expect(title.contains(word.toLowerCase()), isFalse,
              reason:
                  'tutorialStep1Title for locale "$code" contains UPL-risk word "$word": got "${l.tutorialStep1Title}"');
        }
      }
    });

    test('Russian tutorialStep1Title no longer says ИИ-юрист', () async {
      final l = await AppLocalizations.delegate.load(const Locale('ru'));
      expect(l.tutorialStep1Title, isNot(equals('ИИ-юрист')));
      // And it should still say *something* about AI + legal help.
      final lower = l.tutorialStep1Title.toLowerCase();
      expect(
        lower.contains('ии') || lower.contains('ai') || lower.contains('ии-'),
        isTrue,
        reason: 'Russian title should still flag AI involvement: ${l.tutorialStep1Title}',
      );
    });

    test('Ukrainian tutorialStep1Title no longer says ШІ-юрист', () async {
      final l = await AppLocalizations.delegate.load(const Locale('uk'));
      expect(l.tutorialStep1Title, isNot(equals('ШІ-юрист')));
    });
  });
}
