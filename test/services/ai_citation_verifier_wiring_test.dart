@Tags(['fast'])
library;

// =============================================================================
// ai_citation_verifier_wiring_test.dart — pin AIService → CitationVerifier
// =============================================================================
//
// Smart Agent v2 (2026-05-05): the [CitationVerifier] is wired into
// [AIService] via [applyCitationVerificationForTest]. These tests confirm
// the integration end-to-end:
//
//   • A response text containing a § citation that matches a tool call is
//     preserved verbatim.
//   • A response text whose § citation has NO matching tool call this turn
//     gets the unverified portion silently rewritten to "(уточню §)".
//   • Empty text and zero-citation text round-trip unchanged.
//
// Pure routing tests — no Claude API call.
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:advocat/services/agentic_loop.dart';
import 'package:advocat/services/ai_service.dart';
import 'package:advocat/services/citation_verifier.dart';

LoopToolCall _toolCall(String name, Map<String, dynamic> input) =>
    LoopToolCall(id: 'toolu_$name', name: name, input: input, isError: false);

void main() {
  group('AIService.applyCitationVerificationForTest', () {
    final service = AIService();

    test('verified citation preserved verbatim', () {
      const text = 'Согласно KarS § 121 — нападение.';
      final tools = [_toolCall('search_estonian_law', {'query': 'KarS § 121'})];

      final result = service.applyCitationVerificationForTest(text, tools);
      expect(result, equals(text));
    });

    test('unverified citation replaced with (уточню §)', () {
      const text = 'KarS § 999 предусматривает выдуманное наказание.';
      final tools = <LoopToolCall>[];

      final result = service.applyCitationVerificationForTest(text, tools);
      expect(result.contains('KarS § 999'), isFalse);
      expect(result.contains(CitationVerifier.unverifiedPlaceholder), isTrue);
    });

    test('empty text round-trips unchanged', () {
      final result = service.applyCitationVerificationForTest('', const []);
      expect(result, equals(''));
    });

    test('text with no citations round-trips unchanged', () {
      const text = 'Просто разговор без упоминания законов.';
      final result = service.applyCitationVerificationForTest(text, const []);
      expect(result, equals(text));
    });

    test('mixed verified + unverified — only unverified rewritten', () {
      const text = 'KarS § 121 (искали) и KarS § 999 (выдумано).';
      final tools = [_toolCall('search_estonian_law', {'query': 'KarS § 121'})];

      final result = service.applyCitationVerificationForTest(text, tools);
      expect(result.contains('KarS § 121'), isTrue,
          reason: 'verified citation must be preserved');
      expect(result.contains('KarS § 999'), isFalse,
          reason: 'unverified citation must be stripped');
    });
  });
}
