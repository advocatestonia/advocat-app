@Tags(['fast'])
library;

// voice_engine_pinning_test.dart
//
// Anti-regression test for Rule 7:
//   "One AI response streams through exactly ONE TTS engine."
//
// Previous bug (fixed in dd57d25 + f06a50e via MessageSpeaker):
//   VoiceService.speak() had engine fallback (ElevenLabs → Google →
//   Browser) that could trigger mid-response, causing two voices in one
//   reply. The fix pins the engine via ttsEngineFor(lang) BEFORE any
//   audio starts.
//
// This file complements voice_routing_matrix_test.dart — it focuses
// narrowly on:
//   * DETERMINISM across repeated calls (same lang → same engine every
//     call, not just pairs of calls).
//   * The FROZEN preferElevenLabsSet contract ({en, ru, uk}).
//   * Determinism for unknown languages (so the fallback engine pick
//     stays stable across a single reply).
//
// Note on API shape: the task spec imagined top-level helpers, but in
// this codebase `ttsEngineFor` / `preferElevenLabsSet` are static
// members on `VoiceService`, and `TtsEngine` is a top-level enum. We
// wrap the statics in local closures so the test reads like the spec.

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/voice_service.dart';

TtsEngine ttsEngineFor(String lang) => VoiceService.ttsEngineFor(lang);
Set<String> get preferElevenLabsSet => VoiceService.preferElevenLabsSet;

void main() {
  group('TTS engine routing is deterministic per language', () {
    test('ttsEngineFor("en") same every call', () {
      final first = ttsEngineFor('en');
      for (var i = 0; i < 5; i++) {
        expect(ttsEngineFor('en'), first);
      }
    });

    test('en routes to ElevenLabs', () {
      expect(ttsEngineFor('en'), TtsEngine.elevenLabs);
    });

    test('ru routes to ElevenLabs', () {
      expect(ttsEngineFor('ru'), TtsEngine.elevenLabs);
    });

    test('uk routes to ElevenLabs', () {
      expect(ttsEngineFor('uk'), TtsEngine.elevenLabs);
    });

    test('et routes to Google', () {
      expect(ttsEngineFor('et'), TtsEngine.google);
    });

    test('preferElevenLabsSet frozen at {en, ru, uk}', () {
      expect(preferElevenLabsSet, containsAll({'en', 'ru', 'uk'}));
      expect(preferElevenLabsSet.length, 3);
    });

    test('unknown lang routes to deterministic engine', () {
      final e1 = ttsEngineFor('xx');
      final e2 = ttsEngineFor('xx');
      expect(e1, e2);
    });
  });
}
