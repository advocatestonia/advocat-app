import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/l10n/app_localizations.dart';

/// launch/wave1 UX-Tier-A regression tests (Agent 1-2).
///
/// We don't boot the full app here — we just validate that the new
/// localisation keys exist in all three canonical locales (en/et/ru) and
/// aren't empty. If a coder later removes the key from one .arb, the
/// chat upgrade banner and payment-success dialog would silently fall
/// back to English again — this test catches that regression.
void main() {
  group('UX-Tier-A: localisation keys present', () {
    test('upgradeBannerTitle / upgradeBannerCta defined in en/et/ru', () async {
      for (final locale in const [Locale('en'), Locale('et'), Locale('ru')]) {
        final l = await AppLocalizations.delegate.load(locale);
        expect(l.upgradeBannerTitle, isNotEmpty,
            reason: 'upgradeBannerTitle missing for ${locale.languageCode}');
        expect(l.upgradeBannerCta, isNotEmpty,
            reason: 'upgradeBannerCta missing for ${locale.languageCode}');
      }
    });

    test('paymentSuccessTitle / paymentSuccessBody / commonOk in en/et/ru',
        () async {
      for (final locale in const [Locale('en'), Locale('et'), Locale('ru')]) {
        final l = await AppLocalizations.delegate.load(locale);
        expect(l.paymentSuccessTitle, isNotEmpty,
            reason: 'paymentSuccessTitle missing for ${locale.languageCode}');
        expect(l.paymentSuccessBody, isNotEmpty,
            reason: 'paymentSuccessBody missing for ${locale.languageCode}');
        expect(l.commonOk, isNotEmpty,
            reason: 'commonOk missing for ${locale.languageCode}');
      }
    });

    test('Estonian upgrade strings actually differ from English', () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final et = await AppLocalizations.delegate.load(const Locale('et'));
      expect(en.upgradeBannerTitle, isNot(et.upgradeBannerTitle),
          reason: 'et upgradeBannerTitle is still English — translate it');
    });
  });
}
