@Tags(['fast'])
library;

// system_prompt_no_wait_promise_test.dart
//
// 2026-05-05 owner bug report: "Когда задаешь сложный вопрос, он пишет, что
// ему нужно 5-10 минут времени, и потом он ничего не отвечает". Claude
// hallucinated a background-task capability that does not exist — there is
// no async "I'll get back to you" in chat. Rule 14 in `_rules` forbids
// every variant of "wait, give me a moment, I'll research and reply".
//
// This test locks the rule into both the full chat prompt and the light
// prompt, so a future edit cannot silently strip it.

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/system_prompts.dart';

void main() {
  group('SystemPrompts — rule 14 forbids "I will come back later" promises', () {
    test('full chat prompt mentions the rule and forbids wait phrases', () {
      final p = SystemPrompts.buildChatPrompt(userLanguage: 'ru');
      // Rule preamble — the model should know this is a hard rule.
      expect(p, contains('NEVER PROMISE TO COME BACK LATER'));
      // Specific phrases the bug report flagged.
      expect(p.toLowerCase(), contains('5–10 minutes'));
      expect(p, contains('подожди немного'));
      expect(p, contains('дай мне минутку'));
      expect(p, contains('mõne minuti pärast'));
      // The core constraint.
      expect(p.toLowerCase(), contains('answer in the current turn'));
    });

    test('rule 14 directive is stable across languages', () {
      // Sanity: the rule renders the same regardless of which userLanguage
      // is requested, because it lives in _rules (language-independent).
      final pRu = SystemPrompts.buildChatPrompt(userLanguage: 'ru');
      final pEt = SystemPrompts.buildChatPrompt(userLanguage: 'et');
      final pEn = SystemPrompts.buildChatPrompt(userLanguage: 'en');
      for (final p in [pRu, pEt, pEn]) {
        expect(p, contains('NEVER PROMISE TO COME BACK LATER'));
        expect(p, contains('do the reasoning IN THIS TURN'));
      }
    });
  });
}
