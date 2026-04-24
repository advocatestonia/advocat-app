@Tags(['fast'])
library;

// =============================================================================
// AI quality — adaptive response length (Bug 2 from owner)
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:advocat/services/claude_service.dart';
import 'package:advocat/services/system_prompts.dart';

void main() {
  group('system_prompts — ADAPTIVE RESPONSE LENGTH rule is present', () {
    test('buildChatPrompt includes an adaptive-length section', () {
      final prompt = SystemPrompts.buildChatPrompt(
        country: 'Estonia',
        userLanguage: 'ru',
        query: 'any',
      );
      expect(prompt, contains('ADAPTIVE RESPONSE LENGTH'));
      expect(prompt.toLowerCase(), contains('yes/no'));
      expect(prompt.toLowerCase(), contains('list'));
    });

    test('buildLightPrompt also carries a short-answer directive', () {
      final prompt = SystemPrompts.buildLightPrompt(userLanguage: 'ru');
      expect(prompt.toLowerCase(), contains('short'));
    });
  });

  group('ClaudeService.isShortQuery — detects yes/no, list, and commands', () {
    const yesNoQuestions = [
      'Да или нет: могу ли я подать жалобу?',
      'могу ли я обжаловать решение',
      'Yes or no: can I appeal?',
      'is it legal?',
      'can I file an appeal?',
      'Kas ma saan kaebuse esitada?',
      'kas see on seaduslik?',
      'Voiko minä valittaa?',
    ];
    for (final q in yesNoQuestions) {
      test('yes/no: "\$q"', () {
        expect(ClaudeService.isShortQuery(q), isTrue,
            reason: '"\$q" must be classified as short (yes/no)');
      });
    }

    const listRequests = [
      'Составь список документов для подачи иска',
      'List the documents I need',
      'give me a checklist of what to prepare',
      'koosta nimekiri dokumentidest',
    ];
    for (final q in listRequests) {
      test('list request: "\$q"', () {
        expect(ClaudeService.isShortQuery(q), isTrue,
            reason: '"\$q" must be classified as short (list)');
      });
    }

    const commands = [
      'Продли срок на неделю',
      'Extend the deadline by one week',
      'pikenda tähtaega',
    ];
    for (final q in commands) {
      test('command: "\$q"', () {
        expect(ClaudeService.isShortQuery(q), isTrue,
            reason: '"\$q" must be classified as short (command)');
      });
    }

    const longQueries = [
      'Объясни мне подробно как работает процесс обжалования депортации '
          'и какие документы мне нужно подготовить для суда.',
      'Walk me through step-by-step the procedure for appealing '
          'a deportation decision under Finnish law with all the nuances.',
    ];
    for (final q in longQueries) {
      test('long query: "\${q.substring(0, 30)}…"', () {
        expect(ClaudeService.isShortQuery(q), isFalse,
            reason:
                'explicit verbosity marker must NOT be classified short');
      });
    }
  });

  group('ClaudeService.maxTokensForShortQuery — tight budget', () {
    test('short query returns <=300 tokens', () {
      expect(ClaudeService.maxTokensForShortQuery(), lessThanOrEqualTo(300));
    });
  });
}
