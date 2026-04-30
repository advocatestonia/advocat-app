import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/ai_service.dart';

/// Regression test for the production chat-fallback bug discovered on
/// 2026-04-29.
///
/// Bug summary
/// -----------
/// `AIService.sendChatMessage` falls back to the proxy endpoint
/// `/ai/chat` when the direct Claude path errors out. Until this fix,
/// the fallback parsed the proxy body via `ChatResponse.fromJson`,
/// which expects the legacy `{message, suggested_actions, disclaimer}`
/// shape. In production the proxy actually forwards the raw Anthropic
/// Messages API response — `{content: [{type:"text", text:"..."}], ...}`
/// — so `json['message'] as String` cast-threw, the catch swallowed it,
/// and the user saw the hardcoded English "AI assistant is temporarily
/// unavailable…" message. Russian users typing in Russian thought the
/// product was broken.
///
/// These tests pin the parser behaviour for both shapes via the public
/// `@visibleForTesting` helper [AIService.parseProxyChatResponseForTest].
void main() {
  group('AIService.parseProxyChatResponse — Anthropic raw shape', () {
    test('extracts text from a single text content block (Russian)', () {
      final raw = <String, dynamic>{
        'id': 'msg_01ABC',
        'type': 'message',
        'role': 'assistant',
        'model': 'claude-sonnet-4-5',
        'content': [
          {'type': 'text', 'text': 'Привет'},
        ],
        'stop_reason': 'end_turn',
        'usage': {'input_tokens': 10, 'output_tokens': 5},
      };

      final response = AIService.parseProxyChatResponseForTest(raw);

      expect(response.message, 'Привет');
      expect(
        response.message,
        isNot(contains('AI assistant is temporarily unavailable')),
        reason: 'Russian users must NOT see the English fallback message.',
      );
    });

    test('joins multiple text blocks with newlines', () {
      final raw = <String, dynamic>{
        'content': [
          {'type': 'text', 'text': 'Line one.'},
          {'type': 'text', 'text': 'Line two.'},
        ],
        'stop_reason': 'end_turn',
      };

      final response = AIService.parseProxyChatResponseForTest(raw);

      expect(response.message, 'Line one.\nLine two.');
    });

    test('skips non-text blocks (e.g. tool_use)', () {
      final raw = <String, dynamic>{
        'content': [
          {'type': 'text', 'text': 'Calling tool…'},
          {
            'type': 'tool_use',
            'id': 'toolu_01',
            'name': 'web_search',
            'input': <String, dynamic>{},
          },
        ],
        'stop_reason': 'tool_use',
      };

      final response = AIService.parseProxyChatResponseForTest(raw);

      expect(response.message, 'Calling tool…');
    });

    test('returns empty string when content array is empty (graceful)', () {
      final raw = <String, dynamic>{
        'content': <dynamic>[],
        'stop_reason': 'end_turn',
      };

      final response = AIService.parseProxyChatResponseForTest(raw);

      expect(response.message, '');
      // Critically: it must NOT throw. Throwing here is what caused the
      // user-visible bug.
    });
  });

  group('AIService.parseProxyChatResponse — legacy shape', () {
    test('still parses {message, disclaimer} bodies', () {
      final raw = <String, dynamic>{
        'message': 'Hello from legacy proxy',
        'disclaimer': 'Not legal advice',
      };

      final response = AIService.parseProxyChatResponseForTest(raw);

      expect(response.message, 'Hello from legacy proxy');
      expect(response.disclaimer, 'Not legal advice');
    });

    test('preserves suggested_actions from legacy shape', () {
      final raw = <String, dynamic>{
        'message': 'Hi',
        'suggested_actions': ['action_a', 'action_b'],
      };

      final response = AIService.parseProxyChatResponseForTest(raw);

      expect(response.suggestedActions, ['action_a', 'action_b']);
    });
  });
}
