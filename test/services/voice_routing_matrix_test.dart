@Tags(['fast'])
library;

// voice_routing_matrix_test.dart
//
// TTS routing audit (2026-04-21) — task from owner: "весь ответ на любом
// языке должен звучать одним голосом без перескоков".
//
// Contract locked here:
//
//   * VoiceService.ttsEngineFor(langCode) returns exactly ONE of:
//       - TtsEngine.elevenLabs   (RU / EN / UK — owner-frozen choice)
//       - TtsEngine.google       (ET + every other language)
//     i.e. the routing decision is deterministic per language and does
//     NOT depend on runtime state. This means within a single AI reply
//     the chosen engine never changes mid-playback.
//
//   * _preferElevenLabsFor is FROZEN to {'en','ru','uk'} — flipping it
//     is a red-line change per owner 2026-04-21.
//
//   * All 17 app locales (en, fi, sv, de, fr, es, it, pl, ro, lt, lv,
//     et, ru, uk, tr, ar, fa) resolve to a known engine.
//
// These tests are PURE — no HTTP, no plugin channels — so they run on
// any host and pin the contract every CI run.

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/voice_service.dart';

void main() {
  const appLocales = <String>[
    'en', 'fi', 'sv', 'de', 'fr', 'es', 'it', 'pl', 'ro',
    'lt', 'lv', 'et', 'ru', 'uk', 'tr', 'ar', 'fa',
  ];

  group('VoiceService.ttsEngineFor — deterministic per language', () {
    test('covers exactly 17 app locales', () {
      expect(appLocales, hasLength(17));
    });

    test('ru → ElevenLabs (owner-frozen)', () {
      expect(VoiceService.ttsEngineFor('ru'), TtsEngine.elevenLabs);
    });

    test('en → ElevenLabs (owner-frozen)', () {
      expect(VoiceService.ttsEngineFor('en'), TtsEngine.elevenLabs);
    });

    test('uk → ElevenLabs (owner-frozen)', () {
      expect(VoiceService.ttsEngineFor('uk'), TtsEngine.elevenLabs);
    });

    test('et → Google (Chirp3-HD-Kore — owner is happy, FROZEN)', () {
      expect(VoiceService.ttsEngineFor('et'), TtsEngine.google);
    });

    test('all non-EL/UK/RU locales → Google', () {
      const googleLocales = <String>[
        'fi', 'sv', 'de', 'fr', 'es', 'it', 'pl', 'ro',
        'lt', 'lv', 'et', 'tr', 'ar', 'fa',
      ];
      for (final lang in googleLocales) {
        expect(
          VoiceService.ttsEngineFor(lang),
          TtsEngine.google,
          reason: '$lang must route to Google, not ElevenLabs',
        );
      }
    });

    test('every app locale resolves to a non-null engine', () {
      for (final lang in appLocales) {
        final engine = VoiceService.ttsEngineFor(lang);
        expect(engine, anyOf(TtsEngine.elevenLabs, TtsEngine.google),
            reason: '$lang returned $engine');
      }
    });

    test('routing is pure — same input, same output', () {
      for (final lang in appLocales) {
        final a = VoiceService.ttsEngineFor(lang);
        final b = VoiceService.ttsEngineFor(lang);
        expect(a, b, reason: 'routing for $lang is not deterministic');
      }
    });

    test('accepts BCP-47 style (en-US, ru-RU) — only base code counts', () {
      expect(VoiceService.ttsEngineFor('en-US'), TtsEngine.elevenLabs);
      expect(VoiceService.ttsEngineFor('ru-RU'), TtsEngine.elevenLabs);
      expect(VoiceService.ttsEngineFor('et-EE'), TtsEngine.google);
      expect(VoiceService.ttsEngineFor('fi-FI'), TtsEngine.google);
    });

    test('uppercase / mixed case is normalised', () {
      expect(VoiceService.ttsEngineFor('RU'), TtsEngine.elevenLabs);
      expect(VoiceService.ttsEngineFor('Et'), TtsEngine.google);
    });

    test('unknown language falls through to Google (safe default)', () {
      // If a future locale is added to the UI before _preferElevenLabsFor,
      // we prefer Google over ElevenLabs because Google covers more
      // languages via Chirp3-HD/Gemini 3.1 and never speaks bracket tags.
      expect(VoiceService.ttsEngineFor('zz'), TtsEngine.google);
      expect(VoiceService.ttsEngineFor(''), TtsEngine.google);
    });
  });

  group('VoiceService.preferElevenLabsSet — FROZEN contract', () {
    test('is exactly {en, ru, uk} (owner choice 2026-04-21)', () {
      expect(VoiceService.preferElevenLabsSet, {'en', 'ru', 'uk'});
    });

    test('does NOT contain et — Estonian is pinned to Google Chirp3-HD', () {
      expect(VoiceService.preferElevenLabsSet.contains('et'), isFalse);
    });

    test('size is exactly 3', () {
      expect(VoiceService.preferElevenLabsSet, hasLength(3));
    });
  });
}
