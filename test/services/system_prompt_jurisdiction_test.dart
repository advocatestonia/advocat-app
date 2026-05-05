@Tags(['fast'])
library;

// system_prompt_jurisdiction_test.dart
//
// Pre-launch BUG fix (2026-05-05): Russian-speakers in Estonia (the primary
// market) were getting Russian Federation law (УК РФ, ТК РФ) by default
// when the query was generic, because the model defaulted to RF based on
// language alone. This is a serious legal product bug — Estonian law must
// be the default for Russian/Ukrainian users unless the user explicitly
// names a Russian case.
//
// QA agent observed today: "RU response cited 'Трудовому кодексу РФ'
// (Russian Federation labor code) instead of Estonia — but query was
// generic so model defaulted to RF."
//
// This test pins the new "JURISDICTION ANCHOR" rule into both the full
// chat prompt and the lightweight prompt so a future refactor cannot
// silently regress it.

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/system_prompts.dart';

void main() {
  group('SystemPrompts — jurisdiction anchor for Russian-speaking users', () {
    test('full prompt for ru contains the JURISDICTION ANCHOR header', () {
      final p = SystemPrompts.buildChatPrompt(userLanguage: 'ru');
      expect(p, contains('JURISDICTION ANCHOR'),
          reason:
              'The anchor rule must be visibly headed so the model spots it');
    });

    test('full prompt for ru forbids citing Russian Federation codes', () {
      final p = SystemPrompts.buildChatPrompt(userLanguage: 'ru');
      // The model must not cite Russian Federation codes by default.
      expect(p, contains('УК РФ'));
      expect(p, contains('ТК РФ'));
      expect(p, contains('NEVER cite'));
    });

    test(
        'full prompt for ru tells the model these users live in Estonia/EU, '
        'not the Russian Federation', () {
      final p = SystemPrompts.buildChatPrompt(userLanguage: 'ru');
      expect(p.contains('Estonia (primary market)'), isTrue);
      // It must explicitly defuse the language=jurisdiction shortcut.
      expect(p.toLowerCase(), contains('never means russian federation'));
    });

    test('full prompt for ru offers an Estonian-law default with KarS/VÕS/TLS',
        () {
      final p = SystemPrompts.buildChatPrompt(userLanguage: 'ru');
      expect(p, contains('KarS'));
      expect(p, contains('VÕS'));
      expect(p, contains('TLS'));
    });

    test('full prompt for ru tells the model to ASK if jurisdiction unclear',
        () {
      final p = SystemPrompts.buildChatPrompt(userLanguage: 'ru');
      // Russian wording — so the model copies it verbatim into the chat.
      expect(p, contains('В какой стране у вас правовой вопрос?'));
    });

    test('full prompt for uk (Ukrainian) carries the same anchor', () {
      final p = SystemPrompts.buildChatPrompt(userLanguage: 'uk');
      expect(p, contains('JURISDICTION ANCHOR'));
      expect(p, contains('NEVER cite'));
      expect(p, contains('УК РФ'));
    });

    test('light prompt for ru contains the inverse-of-FI clause for RU/UK',
        () {
      final p = SystemPrompts.buildLightPrompt(userLanguage: 'ru');
      // The light prompt is ~300 chars so we keep the rule short, but
      // it MUST forbid RF codes.
      expect(p, contains('NEVER cite УК РФ'));
    });

    test('light prompt for uk also forbids RF codes', () {
      final p = SystemPrompts.buildLightPrompt(userLanguage: 'uk');
      expect(p, contains('NEVER cite УК РФ'));
    });

    test('full prompt for et does NOT carry the RU/UK anchor (no leakage)',
        () {
      // Estonian-speaking users already get Estonian law by default;
      // the anchor section is RU/UK-specific to keep token budget tight.
      final p = SystemPrompts.buildChatPrompt(userLanguage: 'et');
      // The header should not appear for Estonian users.
      expect(p.contains('JURISDICTION ANCHOR'), isFalse);
    });

    test('full prompt for en does NOT carry the RU/UK anchor', () {
      final p = SystemPrompts.buildChatPrompt(userLanguage: 'en');
      expect(p.contains('JURISDICTION ANCHOR'), isFalse);
    });
  });
}
