// ai_service_voice_tag_strip_test.dart
//
// Anti-regression for the 2026-04-29 prod incident:
//
//   Voice-engine tags such as `[warmth]`, `[thoughtful]`, `[empathetic]`
//   were leaking into the visible chat bubble on advocat.ee. The tags
//   are intentional in the system prompt — Claude emits them so the TTS
//   pipeline can render expressive audio — but they MUST be stripped
//   before the text is shown in the UI.
//
//   The newly added `parseProxyChatResponseForTest` (commit d305dc1)
//   parses Anthropic content blocks correctly but did not run them
//   through `VoiceService.stripExpressiveTags`. This test pins the
//   contract at that boundary and protects against future regressions.
//
// Companion to:
//   • test/services/no_leaked_voice_tags_test.dart  (regex-level golden)
//   • test/services/voice_tts_tag_strip_test.dart   (TTS path golden)
//
// @Tags(['fast'])

@Tags(['fast'])
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/ai_service.dart';

void main() {
  group('AIService.parseProxyChatResponseForTest — voice-tag stripping', () {
    test('strips a leading [warmth] tag from a single text block', () {
      final raw = <String, dynamic>{
        'content': [
          {'type': 'text', 'text': '[warmth] Привет, как дела?'},
        ],
        'stop_reason': 'end_turn',
      };

      final response = AIService.parseProxyChatResponseForTest(raw);

      expect(response.message, 'Привет, как дела?');
      expect(response.message, isNot(contains('[warmth]')));
      expect(response.message, isNot(contains('warmth')));
    });

    test('strips multiple expressive tags interleaved in the text', () {
      final raw = <String, dynamic>{
        'content': [
          {
            'type': 'text',
            'text': '[empathetic] Понимаю. [thoughtful] Важно знать ваши права.',
          },
        ],
        'stop_reason': 'end_turn',
      };

      final response = AIService.parseProxyChatResponseForTest(raw);

      expect(response.message, isNot(contains('[empathetic]')));
      expect(response.message, isNot(contains('[thoughtful]')));
      // The substantive content is preserved.
      expect(response.message, contains('Понимаю.'));
      expect(response.message, contains('Важно знать ваши права.'));
    });

    test('strips tags case-insensitively', () {
      final raw = <String, dynamic>{
        'content': [
          {'type': 'text', 'text': '[Warmth] hi'},
        ],
        'stop_reason': 'end_turn',
      };

      final response = AIService.parseProxyChatResponseForTest(raw);

      expect(response.message.trim(), 'hi');
    });

    test('preserves non-tag legal-citation brackets verbatim', () {
      // Legal citations contain spaces and § characters that the voice-tag
      // regex deliberately does NOT match. They MUST survive.
      final raw = <String, dynamic>{
        'content': [
          {
            'type': 'text',
            'text': 'See [section 26] and [HMS § 40] for details.',
          },
        ],
        'stop_reason': 'end_turn',
      };

      final response = AIService.parseProxyChatResponseForTest(raw);

      expect(response.message, contains('[section 26]'));
      expect(response.message, contains('[HMS § 40]'));
    });

    test('strips tags that appear across multiple text blocks', () {
      final raw = <String, dynamic>{
        'content': [
          {'type': 'text', 'text': '[warmth] Line one.'},
          {'type': 'text', 'text': '[reassuring] Line two.'},
        ],
        'stop_reason': 'end_turn',
      };

      final response = AIService.parseProxyChatResponseForTest(raw);

      expect(response.message, isNot(contains('[warmth]')));
      expect(response.message, isNot(contains('[reassuring]')));
      expect(response.message, contains('Line one.'));
      expect(response.message, contains('Line two.'));
    });

    test('strips tags from legacy {message} shape too', () {
      // Belt-and-braces: the proxy fallback may still return the legacy
      // shape during a slow rollout. Tags must be stripped there as well
      // so the user never sees them regardless of which proxy version
      // answers.
      final raw = <String, dynamic>{
        'message': '[warmth] Hello from legacy proxy',
        'disclaimer': 'Not legal advice',
      };

      final response = AIService.parseProxyChatResponseForTest(raw);

      expect(response.message, 'Hello from legacy proxy');
      expect(response.message, isNot(contains('[warmth]')));
      // Disclaimer is metadata, not user-visible chat text — keep
      // unchanged so we don't accidentally rewrite legal copy.
      expect(response.disclaimer, 'Not legal advice');
    });
  });
}
