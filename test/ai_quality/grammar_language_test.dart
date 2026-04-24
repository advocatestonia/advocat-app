@Tags(['fast'])
library;

// =============================================================================
// AI quality — grammar / language quality reinforcement (Bug 3 from owner)
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:advocat/services/system_prompts.dart';

void main() {
  group('system_prompts — language instruction demands grammatical correctness',
      () {
    test('Russian user: instruction requires grammatically-correct Russian', () {
      final prompt = SystemPrompts.buildChatPrompt(
        country: 'Estonia',
        userLanguage: 'ru',
        query: 'любой вопрос',
      );
      final lower = prompt.toLowerCase();
      expect(
        lower.contains('grammatically correct') ||
            lower.contains('proofread') ||
            lower.contains('correct grammar'),
        isTrue,
      );
    });

    test('Estonian user: instruction requires grammatically-correct Estonian',
        () {
      final prompt = SystemPrompts.buildChatPrompt(
        country: 'Estonia',
        userLanguage: 'et',
        query: 'ükskõik mis',
      );
      final lower = prompt.toLowerCase();
      expect(
        lower.contains('grammatically correct') ||
            lower.contains('proofread') ||
            lower.contains('correct grammar'),
        isTrue,
      );
    });

    test('Light prompt also carries the grammar rule', () {
      final prompt = SystemPrompts.buildLightPrompt(userLanguage: 'ru');
      final lower = prompt.toLowerCase();
      expect(
        lower.contains('grammatically correct') ||
            lower.contains('proofread') ||
            lower.contains('correct grammar'),
        isTrue,
      );
    });
  });
}
