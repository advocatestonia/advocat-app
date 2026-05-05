@Tags(['fast'])
library;

// =============================================================================
// reasoning_caption_mapper_test.dart — pure caption logic pin.
// =============================================================================
//
// Reasoning Trail v1 (2026-05-05). Asserts the mapping from ChatStreamEvent
// → caption string is stable, sanitises thinking text correctly, and never
// leaks raw chain-of-thought past the 60-char cap.
// =============================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/chat/widgets/reasoning_caption_mapper.dart';
import 'package:advocat/l10n/app_localizations.dart';
import 'package:advocat/l10n/app_localizations_en.dart';
import 'package:advocat/services/chat_stream_event.dart';

Future<AppLocalizations> _loadEn() async {
  return AppLocalizationsEn();
}

void main() {
  group('captionForEvent — tool name → l10n key mapping', () {
    late AppLocalizations l;
    setUpAll(() async {
      l = await _loadEn();
    });

    test('search_estonian_law → reasoningPillSearchingLaw', () {
      final caption = captionForEvent(
        const ToolUseStart('search_estonian_law', 't1'),
        l,
      );
      expect(caption, l.reasoningPillSearchingLaw);
      expect(caption, 'Searching Estonian law…');
    });

    test('search_finnish_law and search_knowledge → same SearchingLaw', () {
      expect(
        captionForEvent(const ToolUseStart('search_finnish_law', 't'), l),
        l.reasoningPillSearchingLaw,
      );
      expect(
        captionForEvent(const ToolUseStart('search_knowledge', 't'), l),
        l.reasoningPillSearchingLaw,
      );
    });

    test('web_search → SearchingWeb', () {
      expect(
        captionForEvent(const ToolUseStart('web_search', 't'), l),
        l.reasoningPillSearchingWeb,
      );
    });

    test('check_company → CheckingCompany', () {
      expect(
        captionForEvent(const ToolUseStart('check_company', 't'), l),
        l.reasoningPillCheckingCompany,
      );
    });

    test('check_vehicle → CheckingVehicle', () {
      expect(
        captionForEvent(const ToolUseStart('check_vehicle', 't'), l),
        l.reasoningPillCheckingVehicle,
      );
    });

    test('analyze_document, read_document, list_documents, analyze_contract → ReadingDocument', () {
      for (final t in [
        'analyze_document',
        'read_document',
        'list_documents',
        'analyze_contract',
      ]) {
        expect(
          captionForEvent(ToolUseStart(t, 't'), l),
          l.reasoningPillReadingDocument,
          reason: 'tool $t',
        );
      }
    });

    test('generate_draft → Drafting', () {
      expect(
        captionForEvent(const ToolUseStart('generate_draft', 't'), l),
        l.reasoningPillDrafting,
      );
    });

    test('send_email and draft_email → PreparingEmail', () {
      expect(
        captionForEvent(const ToolUseStart('send_email', 't'), l),
        l.reasoningPillPreparingEmail,
      );
      expect(
        captionForEvent(const ToolUseStart('draft_email', 't'), l),
        l.reasoningPillPreparingEmail,
      );
    });

    test('find_lawyer → FindingLawyer', () {
      expect(
        captionForEvent(const ToolUseStart('find_lawyer', 't'), l),
        l.reasoningPillFindingLawyer,
      );
    });

    test('unknown tool → falls back to Thinking (never leaks raw name)', () {
      final caption = captionForEvent(
        const ToolUseStart('quantum_summon_3000', 't'),
        l,
      );
      expect(caption, l.reasoningPillThinking);
      expect(caption!.contains('quantum'), isFalse);
    });
  });

  group('captionForEvent — ThinkingDelta → first sentence, capped', () {
    late AppLocalizations l;
    setUpAll(() async {
      l = await _loadEn();
    });

    test('full short sentence preserved (no punctuation in output)', () {
      final cap = captionForEvent(
        const ThinkingDelta('Looking at the deportation order.'),
        l,
      );
      expect(cap, 'Looking at the deportation order');
    });

    test('first sentence only when multiple', () {
      final cap = captionForEvent(
        const ThinkingDelta('Reading the law. Then I will check sources.'),
        l,
      );
      expect(cap, 'Reading the law');
    });

    test('60-char cap with word-boundary truncation', () {
      const long = 'I am thinking very carefully about a complicated legal question that goes on and on';
      final cap = captionForEvent(const ThinkingDelta(long), l)!;
      expect(cap.length, lessThanOrEqualTo(60 + 1)); // + ellipsis
      expect(cap.endsWith('…'), isTrue);
    });

    test('whitespace-only delta falls back to generic Thinking', () {
      final cap = captionForEvent(const ThinkingDelta('   \n\t  '), l);
      expect(cap, l.reasoningPillThinking);
    });

    test('empty delta falls back to generic Thinking', () {
      expect(
        captionForEvent(const ThinkingDelta(''), l),
        l.reasoningPillThinking,
      );
    });

    test('multiline collapsed to single space', () {
      final cap = captionForEvent(
        const ThinkingDelta('Step\n  one.'),
        l,
      );
      expect(cap, 'Step one');
    });

    test('NEVER leaks raw chain-of-thought past 60 chars (security pin)', () {
      // Fake long verbatim CoT — must be truncated, not passed through.
      const cot = 'The user wants me to analyze their deportation case carefully and I should think about what the Aliens Act says about appeal deadlines but also remember the recent constitutional court decision from 2024 about due process which is relevant here';
      final cap = captionForEvent(const ThinkingDelta(cot), l)!;
      expect(cap.length, lessThanOrEqualTo(61));
      expect(cap, isNot(contains('constitutional court')));
    });
  });

  group('captionForEvent — non-caption events return null', () {
    late AppLocalizations l;
    setUpAll(() async {
      l = await _loadEn();
    });

    test('TextDelta returns null (don\'t rotate caption mid-text)', () {
      expect(captionForEvent(const TextDelta('hello'), l), isNull);
    });

    test('ToolUseStop returns null (caption stays on running tool)', () {
      expect(captionForEvent(const ToolUseStop(), l), isNull);
    });

    test('ToolInputDelta returns null (no signal)', () {
      expect(captionForEvent(const ToolInputDelta('{}'), l), isNull);
    });

    test('ThinkingStop returns null (caption stays on last thought)', () {
      expect(
        captionForEvent(const ThinkingStop(signature: 'sig'), l),
        isNull,
      );
    });

    test('ThinkingStart yields generic Thinking caption', () {
      expect(
        captionForEvent(const ThinkingStart(), l),
        l.reasoningPillThinking,
      );
    });

    test('ToolResultReceived flips to Finalising', () {
      expect(
        captionForEvent(ToolResultReceived(const {}), l),
        l.reasoningPillFinalising,
      );
    });

    test('MessageDone flips to Finalising', () {
      expect(
        captionForEvent(const MessageDone(), l),
        l.reasoningPillFinalising,
      );
    });
  });
}
