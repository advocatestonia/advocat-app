@Tags(['fast'])
library;

// voice_tts_tag_strip_test.dart
//
// Post-launch BUG 2 fix (2026-04-22):
//
// The system prompt instructs Claude to insert Gemini-style expressive
// audio tags like `[warmth]`, `[thoughtful]`, `[determination]` before
// emotionally charged phrases.  Those tags are supposed to be:
//   * Stripped before ElevenLabs (already was — but only for that engine)
//   * Interpreted by Gemini 3.1 Flash TTS natively
//   * Stripped for every OTHER engine (Google Chirp3-HD, browser TTS)
//
// Before this fix, tags were only stripped on the ElevenLabs path, so
// Estonian / Finnish / Ukrainian responses (which route through Google
// Chirp3-HD) got the literal "[warmth]" read aloud — breaking voice
// output. Owner reported: "AI perestal govorit' golosom."
//
// This test locks the contract: VoiceService.stripExpressiveTags() is
// public, pure, and covers every tag the system prompt can emit.

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/voice_service.dart';

void main() {
  group('VoiceService.stripExpressiveTags', () {
    test('removes [warmth] tag and leading whitespace', () {
      expect(
        VoiceService.stripExpressiveTags('[warmth] Tere, aitäh'),
        'Tere, aitäh',
      );
    });

    test('removes [thoughtful] tag mid-sentence', () {
      expect(
        VoiceService.stripExpressiveTags('Kuule, [thoughtful] asi on selles'),
        'Kuule, asi on selles',
      );
    });

    test('removes multiple tags in one response', () {
      expect(
        VoiceService.stripExpressiveTags(
          '[warmth] Я вас понимаю. [determination] Закон на вашей стороне.',
        ),
        'Я вас понимаю. Закон на вашей стороне.',
      );
    });

    test('leaves text without tags unchanged', () {
      expect(
        VoiceService.stripExpressiveTags('Hei, kiitos avustasi.'),
        'Hei, kiitos avustasi.',
      );
    });

    test('tag names are case-insensitive', () {
      expect(
        VoiceService.stripExpressiveTags('[WARMTH] hello'),
        'hello',
      );
      expect(
        VoiceService.stripExpressiveTags('[Thoughtful] test'),
        'test',
      );
    });

    test('handles all tag vocabulary from system_prompts.dart', () {
      const tags = [
        'warmth', 'thoughtful', 'determination', 'sigh', 'reassuring',
        'whispers', 'laughs', 'excitement', 'enthusiasm', 'shouts',
        'sarcastic', 'calm', 'confident', 'empathetic', 'serious',
        'gentle', 'firm', 'curious', 'hopeful', 'concerned',
      ];
      for (final tag in tags) {
        final input = '[$tag] text';
        final out = VoiceService.stripExpressiveTags(input);
        expect(out, 'text', reason: 'Tag [$tag] was not stripped');
      }
    });

    test('preserves non-tag brackets (legal citations)', () {
      // Legal text may contain bracketed references — do not strip them.
      expect(
        VoiceService.stripExpressiveTags('See [section 26] and [HMS § 40]'),
        'See [section 26] and [HMS § 40]',
      );
    });

    test('empty string stays empty', () {
      expect(VoiceService.stripExpressiveTags(''), '');
    });
  });
}
