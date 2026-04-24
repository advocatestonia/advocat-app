@Tags(['fast'])
library;

// system_prompt_language_test.dart
//
// Post-launch BUG 1 fix (2026-04-22): ensure both the full and light
// system prompts explicitly tell Claude to match the language of the
// CURRENT user message rather than blindly following the profile
// preference.
//
// If someone reverts the stronger wording by accident, this test fails.

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/system_prompts.dart';

void main() {
  group('SystemPrompts — language directive', () {
    test('light prompt instructs to match current message language', () {
      final p = SystemPrompts.buildLightPrompt(userLanguage: 'ru');
      expect(p.toLowerCase(), contains('match the language'));
      // The word "current" appears in our new rule.
      expect(p.toLowerCase(), contains('current message'));
    });

    test('full prompt no longer contains the absolute "MUST respond ONLY" clause', () {
      final p = SystemPrompts.buildChatPrompt(userLanguage: 'ru');
      // The old language: "You MUST respond ONLY in <lang>. This is non-negotiable."
      // We intentionally softened this so the model can follow the user's
      // actual message language.
      expect(p.contains('MUST respond ONLY'), isFalse,
          reason:
              'The absolute lock-in language has been replaced with a current-message-aware rule');
    });

    test('full prompt tells Claude to match current message language', () {
      final p = SystemPrompts.buildChatPrompt(userLanguage: 'ru');
      final lower = p.toLowerCase();
      expect(lower, contains('match the language'));
      expect(lower, contains("user's current message"));
    });

    test('full prompt mentions Estonian + Russian + Finnish heuristics', () {
      final p = SystemPrompts.buildChatPrompt(userLanguage: 'ru');
      // The prompt should list trigger words so Claude can self-detect.
      expect(p, contains('tere'));
      expect(p, contains('привет'));
      expect(p, contains('hei'));
    });

    test('full prompt still specifies the fallback profile language name', () {
      final p = SystemPrompts.buildChatPrompt(userLanguage: 'ru');
      // We still want the language name surfaced so Claude defaults to it.
      expect(p, contains('Russian'));
    });
  });
}
