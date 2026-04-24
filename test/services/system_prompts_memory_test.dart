@Tags(['fast'])
library;

// TDD tests for SystemPrompts memory-block injection (ADR-001 Tier 1).
// -----------------------------------------------------------------------------
// Ref: docs/memory-tier1/integration_patch.md §1
//      lib/services/system_prompts.dart
//      lib/services/user_memory_service.dart
//
// These tests lock down the contract for the new `memoryBlock` parameter
// on SystemPrompts.buildChatPrompt(): the block must appear verbatim in
// the output, it must NOT inject whitespace when empty, and it must be
// positioned before the case context / knowledge sections so the model
// sees "who the user is" before "what the law says".
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/system_prompts.dart';

void main() {
  group('SystemPrompts.buildChatPrompt memoryBlock', () {
    test('includes the memory block verbatim when provided', () {
      const memoryBlock = '=== WHAT WE KNOW ABOUT YOU ===\n'
          '(Use these to personalise tone and anticipate needs.)\n'
          '- [Tone] You prefer short replies.\n'
          '- [People you mentioned] Your wife is Sofia.\n';

      final prompt = SystemPrompts.buildChatPrompt(
        userLanguage: 'en',
        memoryBlock: memoryBlock,
      );

      expect(prompt, contains('=== WHAT WE KNOW ABOUT YOU ==='));
      expect(prompt, contains('- [Tone] You prefer short replies.'));
      expect(prompt, contains('- [People you mentioned] Your wife is Sofia.'));
    });

    test('omits the memory header entirely when memoryBlock is empty', () {
      final prompt = SystemPrompts.buildChatPrompt(
        userLanguage: 'en',
        memoryBlock: '',
      );

      // No memory header means no "WHAT WE KNOW ABOUT YOU" anywhere.
      expect(prompt, isNot(contains('WHAT WE KNOW ABOUT YOU')));
      // Should not introduce a stray triple-newline from an empty block.
      expect(prompt, isNot(contains('\n\n\n\n')));
    });

    test('defaults memoryBlock to empty (backwards compatible)', () {
      // Call without memoryBlock — existing call-sites must keep working.
      final prompt = SystemPrompts.buildChatPrompt(userLanguage: 'en');
      expect(prompt, isNot(contains('WHAT WE KNOW ABOUT YOU')));
      expect(prompt.isNotEmpty, isTrue);
    });

    test(
      'memory block sits before the legal knowledge base section',
      () {
        const memoryBlock = '=== WHAT WE KNOW ABOUT YOU ===\n'
            '- [Tone] Short replies preferred.\n';

        final prompt = SystemPrompts.buildChatPrompt(
          userLanguage: 'en',
          memoryBlock: memoryBlock,
        );

        final memIdx = prompt.indexOf('WHAT WE KNOW ABOUT YOU');
        final kbIdx = prompt.indexOf('# LEGAL KNOWLEDGE BASE');

        expect(memIdx, greaterThanOrEqualTo(0),
            reason: 'memory block must be present');
        expect(kbIdx, greaterThanOrEqualTo(0),
            reason: 'legal KB header must be present');
        expect(memIdx, lessThan(kbIdx),
            reason: 'memory block must precede the legal KB');
      },
    );

    test('memory block sits before the case-context section when both set',
        () {
      const memoryBlock = '=== WHAT WE KNOW ABOUT YOU ===\n'
          '- [People you mentioned] Your wife is Sofia.\n';
      const caseContext = 'Case: appeal against deportation decision from PPA.';

      final prompt = SystemPrompts.buildChatPrompt(
        userLanguage: 'en',
        memoryBlock: memoryBlock,
        caseContext: caseContext,
      );

      final memIdx = prompt.indexOf('WHAT WE KNOW ABOUT YOU');
      final caseIdx = prompt.indexOf('# CURRENT CASE CONTEXT');

      expect(memIdx, greaterThanOrEqualTo(0));
      expect(caseIdx, greaterThanOrEqualTo(0));
      expect(memIdx, lessThan(caseIdx),
          reason: 'memory must come before per-case context');
    });
  });
}
