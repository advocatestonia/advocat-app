// Source-contract tests for the refund policy section of the Terms of
// Service (Pricing Phase 6).
//
// The business-critical rule for the Founder's Beta is the dual cutoff:
// 14 days from purchase OR the 7th AI response, whichever comes first.
// This is anchored in EU Consumer Rights Directive Arts. 9 and 16(m);
// if the ToS copy drifts from the in-app consent modal, the Art. 16(m)
// waiver becomes legally vulnerable.
//
// These tests pin the authoritative copy in both ToS surfaces (the
// in-app Flutter screen and the static web page).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _readScreen() => File(
      'lib/features/legal/screens/terms_of_service_screen.dart',
    ).readAsStringSync();

String _readWebTerms() => File('web/terms.html').readAsStringSync();

void main() {
  group('ToS (Flutter screen) — Founder\'s Beta refund policy', () {
    test('references the 14-day withdrawal window', () {
      final src = _readScreen();
      expect(src.contains('14 days'), isTrue,
          reason: 'Must state the 14-day withdrawal window');
    });

    test('references the 7th AI response waiver', () {
      final src = _readScreen();
      expect(
        src.contains('7th AI response'),
        isTrue,
        reason:
            'Must state the second cutoff (7 AI responses) — without it '
            'the Art. 16(m) waiver is not disclosed',
      );
    });

    test('cites Article 9 of the CRD (withdrawal window)', () {
      final src = _readScreen();
      expect(
        RegExp(r'Article\s*9').hasMatch(src),
        isTrue,
        reason: 'Must cite Art. 9 for the 14-day window',
      );
    });

    test('cites Article 16(m) of the CRD (digital content waiver)', () {
      final src = _readScreen();
      expect(
        RegExp(r'Article\s*16\(m\)').hasMatch(src),
        isTrue,
        reason:
            'Must cite Art. 16(m) for the early waiver on digital content',
      );
    });

    test('mentions the in-app consent modal as the waiver collection point',
        () {
      final src = _readScreen();
      expect(
        src.contains('consent modal') || src.contains('consent-modal'),
        isTrue,
        reason: 'Must name the consent modal so users can find where '
            'they gave the Art. 16(m) waiver',
      );
    });
  });

  group('ToS (web/terms.html) — Founder\'s Beta refund policy', () {
    test('English section mentions both cutoffs', () {
      final html = _readWebTerms();
      // Find the English card.
      expect(html.contains('14 days'), isTrue);
      expect(html.contains('7th AI response'), isTrue);
    });

    test('English section cites CRD Arts. 9 and 16(m)', () {
      final html = _readWebTerms();
      expect(
        RegExp(r'Art[s.]*\.?\s*9\s*and\s*16\(m\)').hasMatch(html),
        isTrue,
      );
    });

    test('Russian section mentions both cutoffs', () {
      final html = _readWebTerms();
      expect(html.contains('14 дней'), isTrue);
      expect(html.contains('7-го ответа AI'), isTrue);
    });

    test('Estonian section mentions both cutoffs', () {
      final html = _readWebTerms();
      expect(html.contains('14 paeva'), isTrue);
      expect(html.contains('7. AI vastuseni'), isTrue);
    });
  });
}
