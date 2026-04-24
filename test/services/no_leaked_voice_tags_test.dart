// no_leaked_voice_tags_test.dart
//
// Anti-regression Rule 6 (2026-04-23):
//
// Voice engines (ElevenLabs v3, Gemini TTS) use expressive inline tags
// such as `[warmth]`, `[pause]`, `[tone:soft]`. Those tags MUST be
// stripped before any chat text is rendered in the UI AND before any
// TTS fetch — otherwise the user literally sees or hears "[warmth]"
// preceding the actual sentence.
//
// On 2026-04-22 the owner reported seeing `[warmth] Ну, ок, сейчас…`
// leak into the visible chat bubble (fixed in ai_service.dart by
// calling VoiceService.stripExpressiveTags on both streaming and
// non-streaming paths).
//
// This test is a GOLDEN regex test that pins the contract at the
// function boundary: whatever tag vocabulary the model emits, the
// returned string must not contain any `[tag]`-shaped artefacts that
// match the generic tag shape `\[[a-zA-Z][a-zA-Z0-9_:]*\]`.
//
// Complements voice_tts_tag_strip_test.dart which locks the named
// vocabulary contract (and the legal-citation exemption for brackets
// containing spaces, e.g. `[section 26]`).
//
// @Tags(['fast'])

@Tags(['fast'])
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/voice_service.dart';

void main() {
  group('VoiceService.stripExpressiveTags', () {
    // Known tag patterns that have leaked OR could leak.
    final cases = {
      '[warmth] Hello': 'Hello',
      '[pause] How are you?': 'How are you?',
      '[tone:soft] Greetings': 'Greetings',
      '[TONE:SOFT] CAPS test': 'CAPS test',
      'Middle [warmth] text': 'Middle text',
      'Double [warmth][pause] tags': 'Double tags',
      '[a_b_c] underscored': 'underscored',
      'No tags plain text': 'No tags plain text',
      '': '',
      '   [pause]   spaced   ': 'spaced',
    };
    for (final entry in cases.entries) {
      test('strips "${entry.key}"', () {
        expect(
          VoiceService.stripExpressiveTags(entry.key)
              .trim()
              .replaceAll(RegExp(r'\s+'), ' '),
          entry.value.trim(),
        );
      });
    }

    test('regression: 2026-04-22 [warmth] leak', () {
      // Reproduce exact text from the bug report.
      const leaked = '[warmth] Ну, ок, сейчас все хорошо с голосами';
      final clean = VoiceService.stripExpressiveTags(leaked);
      expect(clean, isNot(contains('[')));
      expect(clean, isNot(contains('warmth')));
    });

    test('generic tag pattern catches unknown future tags', () {
      const novel = '[emphasis:high] Important news';
      final clean = VoiceService.stripExpressiveTags(novel);
      expect(clean, isNot(contains('[emphasis')));
    });
  });
}
