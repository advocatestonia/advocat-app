@Tags(['fast'])
library;

// =============================================================================
// system_prompts_upl_substitution_test.dart — pin W11 substitution behaviour
// =============================================================================
//
// W11 (2026-05-06): the literal token `{uplDisclaimerFooter}` was reaching
// the Anthropic API as part of the system prompt because the placeholder
// inside `_uplRules` was never substituted at build time. The model
// occasionally echoed the token verbatim in its replies.
//
// `buildChatPrompt` now substitutes the placeholder with the user-locale
// footer string from `_uplFooters` (mirrored from `lib/l10n/app_*.arb`).
// These tests pin that contract: the literal must NEVER ship, and the
// localised string MUST appear for every supported locale.
// =============================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/system_prompts.dart';

void main() {
  group('SystemPrompts — UPL footer placeholder substitution', () {
    test('UPL placeholder is substituted, not literal (en)', () {
      final p = SystemPrompts.buildChatPrompt(userLanguage: 'en');
      expect(p, isNot(contains('{uplDisclaimerFooter}')),
          reason: 'literal placeholder must never ship to the model');
      expect(p, contains('Advocat is not a law firm'));
    });

    test('UPL footer in Estonian (et)', () {
      final p = SystemPrompts.buildChatPrompt(userLanguage: 'et');
      expect(p, isNot(contains('{uplDisclaimerFooter}')));
      expect(p, contains('Advocat ei ole advokaadibüroo'));
    });

    test('UPL footer in Russian (ru)', () {
      final p = SystemPrompts.buildChatPrompt(userLanguage: 'ru');
      expect(p, isNot(contains('{uplDisclaimerFooter}')));
      expect(p, contains('Advocat не является юридической фирмой'));
    });

    test('UPL footer in Finnish (fi)', () {
      final p = SystemPrompts.buildChatPrompt(userLanguage: 'fi');
      expect(p, isNot(contains('{uplDisclaimerFooter}')));
      expect(p, contains('Advocat ei ole asianajotoimisto'));
    });

    test('UPL footer falls back to English when language is null', () {
      final p = SystemPrompts.buildChatPrompt();
      expect(p, isNot(contains('{uplDisclaimerFooter}')));
      expect(p, contains('Advocat is not a law firm'));
    });

    test('UPL footer falls back to English for unsupported locale', () {
      // German is a supported app locale but the UPL footer hardcoded
      // map covers en/et/ru/fi only — unsupported locales must fall
      // back to the English string rather than ship the literal.
      final p = SystemPrompts.buildChatPrompt(userLanguage: 'de');
      expect(p, isNot(contains('{uplDisclaimerFooter}')));
      expect(p, contains('Advocat is not a law firm'));
    });
  });

  // ---------------------------------------------------------------------------
  // G6 — UPL block presence in chat prompt (security-review gate)
  // ---------------------------------------------------------------------------
  //
  // Distinct from substitution: this asserts the entire UPL RULES section
  // is part of every chat prompt and carries the multilingual forbidden-
  // archetype examples ("Soovitan", "Рекомендую") that the model must NOT
  // emit. A regression that drops these examples is silent — the model
  // would still see "UPL RULES" but lose the cross-language anchor and
  // start emitting Estonian / Russian directive recommendations.
  group('SystemPrompts — UPL block presence (G6)', () {
    test('buildChatPrompt contains UPL RULES section (en)', () {
      final p = SystemPrompts.buildChatPrompt(userLanguage: 'en');
      expect(p, contains('UPL RULES'),
          reason: 'UPL RULES header must appear in every chat prompt');
    });

    test('buildChatPrompt contains UPL RULES section (et)', () {
      final p = SystemPrompts.buildChatPrompt(userLanguage: 'et');
      expect(p, contains('UPL RULES'));
    });

    test('buildChatPrompt contains UPL RULES section (ru)', () {
      final p = SystemPrompts.buildChatPrompt(userLanguage: 'ru');
      expect(p, contains('UPL RULES'));
    });

    test('UPL block lists forbidden Estonian directive ("Soovitan")', () {
      // The model needs to see the Estonian example so it doesn't
      // produce "Soovitan esitada hagi" in Estonian replies.
      final p = SystemPrompts.buildChatPrompt(userLanguage: 'et');
      expect(p, contains('Soovitan'),
          reason: 'UPL block must carry the Estonian forbidden archetype');
    });

    test('UPL block lists forbidden Russian directive ("Рекомендую")', () {
      final p = SystemPrompts.buildChatPrompt(userLanguage: 'ru');
      expect(p, contains('Рекомендую'),
          reason: 'UPL block must carry the Russian forbidden archetype');
    });

    test('UPL block names a green-list non-directive alternative', () {
      // The block must not just ban — it must also offer the rewrite
      // template ("you may consider"). Without this, the model strips
      // the directive and the sentence is half-formed.
      final p = SystemPrompts.buildChatPrompt(userLanguage: 'en');
      expect(p, contains('you may consider'));
    });
  });
}
