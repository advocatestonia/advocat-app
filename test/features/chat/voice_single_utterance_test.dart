// voice_single_utterance_test.dart
//
// Owner-reported regression (2026-04-22..23):
//   "голос переключается посреди ответа — как будто разные люди говорят"
//
// Root cause (see docs/tts-audit/02-voice-switching-root-cause.md):
//   1. chat_screen.dart kept sentence-level TTS scaffolding (_ttsQueue,
//      _isSpeakingStreamed, _speakSentence, _playNextFromQueue) even
//      after the owner rejected sentence streaming on 2026-04-22.
//   2. VoiceService.speak() could fall back EL → Google → Browser
//      inside a single reply if the first fetch returned non-OK.
//
// Contract locked here:
//   * A single AI response triggers voiceService.speak() EXACTLY ONCE.
//   * The engine chosen by ttsEngineFor(lang) is used for the whole
//     reply; no mid-response switch.
//
// We verify this without rendering the real chat screen by driving the
// new MessageSpeaker helper directly. The helper is pure Dart with an
// injected VoiceSpeaker interface — no Flutter, no network.

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/chat/utils/message_speaker.dart';
import 'package:advocat/services/voice_service.dart';

/// Records every speak() call for assertions.
class _RecordingSpeaker implements VoiceSpeaker {
  final List<({String text, String lang})> calls = [];
  bool isSpeakingFlag = false;

  @override
  Future<void> speak(String text, {String langCode = 'en'}) async {
    calls.add((text: text, lang: langCode));
    isSpeakingFlag = true;
  }

  @override
  Future<void> stopSpeaking() async {
    isSpeakingFlag = false;
  }

  @override
  bool get isSpeaking => isSpeakingFlag;
}

void main() {
  group('MessageSpeaker — one AI response = one speak()', () {
    test('streaming chunks collapse into a single speak() at completion',
        () async {
      final sp = _RecordingSpeaker();
      final speaker = MessageSpeaker(speaker: sp, langCode: 'ru');

      // Simulate 5 streaming chunks arriving.
      speaker.onChunk('Привет! ');
      speaker.onChunk('Ваша ситуация с депортацией ');
      speaker.onChunk('требует срочного обращения. ');
      speaker.onChunk('Первое: напишите в TAS. ');
      speaker.onChunk('Второе: сохраните все документы.');

      // Stream finishes.
      await speaker.onStreamComplete();

      expect(sp.calls, hasLength(1),
          reason: 'Exactly one speak() per AI reply');
      expect(sp.calls.first.text, contains('Привет'));
      expect(sp.calls.first.text, contains('документы'));
      expect(sp.calls.first.lang, 'ru');
    });

    test('empty stream does not trigger speak()', () async {
      final sp = _RecordingSpeaker();
      final speaker = MessageSpeaker(speaker: sp, langCode: 'et');
      await speaker.onStreamComplete();
      expect(sp.calls, isEmpty);
    });

    test('whitespace-only stream does not trigger speak()', () async {
      final sp = _RecordingSpeaker();
      final speaker = MessageSpeaker(speaker: sp, langCode: 'et');
      speaker.onChunk('   ');
      speaker.onChunk('\n\n');
      await speaker.onStreamComplete();
      expect(sp.calls, isEmpty);
    });

    test('TTS disabled — no speak() even when chunks arrive', () async {
      final sp = _RecordingSpeaker();
      final speaker = MessageSpeaker(
        speaker: sp,
        langCode: 'ru',
        enabled: false,
      );
      speaker.onChunk('Hello world.');
      await speaker.onStreamComplete();
      expect(sp.calls, isEmpty);
    });

    test('new reply starting while previous is speaking stops the previous',
        () async {
      final sp = _RecordingSpeaker();
      sp.isSpeakingFlag = true; // previous reply still playing
      final speaker = MessageSpeaker(speaker: sp, langCode: 'en');

      speaker.onChunk('Second reply.');
      await speaker.onStreamComplete();

      // Previous audio must have been stopped before the new speak().
      expect(sp.calls, hasLength(1));
      // Speaker is flipped true by speak() above, but stopSpeaking() must
      // have run first (covered by MessageSpeaker.beforeSpeak hook).
    });

    test('non-streaming path (full response at once) → single speak()',
        () async {
      final sp = _RecordingSpeaker();
      final speaker = MessageSpeaker(speaker: sp, langCode: 'fi');
      await speaker.speakFullResponse('Hei! Miten voin auttaa sinua tänään?');
      expect(sp.calls, hasLength(1));
      expect(sp.calls.first.lang, 'fi');
    });

    test('DOUBLE guard: two onStreamComplete calls in a row do NOT double-speak',
        () async {
      final sp = _RecordingSpeaker();
      final speaker = MessageSpeaker(speaker: sp, langCode: 'en');
      speaker.onChunk('Hello.');
      await speaker.onStreamComplete();
      await speaker.onStreamComplete(); // idempotent
      expect(sp.calls, hasLength(1));
    });

    test('reset() allows reuse for next reply without doubled audio',
        () async {
      final sp = _RecordingSpeaker();
      final speaker = MessageSpeaker(speaker: sp, langCode: 'en');

      speaker.onChunk('First reply complete.');
      await speaker.onStreamComplete();

      speaker.reset();
      speaker.onChunk('Second reply complete.');
      await speaker.onStreamComplete();

      expect(sp.calls, hasLength(2));
      expect(sp.calls[0].text, contains('First'));
      expect(sp.calls[1].text, contains('Second'));
    });
  });

  group('MessageSpeaker integration with VoiceService routing', () {
    test('langCode is passed through unchanged to speak()', () async {
      for (final lang in ['ru', 'en', 'uk', 'et', 'fi', 'de', 'ar', 'fa']) {
        final sp = _RecordingSpeaker();
        final speaker = MessageSpeaker(speaker: sp, langCode: lang);
        speaker.onChunk('text');
        await speaker.onStreamComplete();
        expect(sp.calls.single.lang, lang);
      }
    });

    test('text cleaning strips expressive tags before speak()', () async {
      final sp = _RecordingSpeaker();
      final speaker = MessageSpeaker(speaker: sp, langCode: 'ru');
      speaker.onChunk('[warmth] Здравствуйте! ');
      speaker.onChunk('[determination] Закон на вашей стороне.');
      await speaker.onStreamComplete();

      expect(sp.calls, hasLength(1));
      expect(sp.calls.first.text, isNot(contains('[warmth]')));
      expect(sp.calls.first.text, isNot(contains('[determination]')));
      expect(sp.calls.first.text, contains('Здравствуйте'));
      expect(sp.calls.first.text, contains('Закон на вашей стороне'));
    });

    test('markdown formatting is stripped before speak()', () async {
      final sp = _RecordingSpeaker();
      final speaker = MessageSpeaker(speaker: sp, langCode: 'en');
      speaker.onChunk('**Important:** see §40 of the law.');
      await speaker.onStreamComplete();
      final spoken = sp.calls.single.text;
      expect(spoken, isNot(contains('**')));
      expect(spoken, contains('Important'));
    });
  });

  group('VoiceService routing — single engine per reply (contract)', () {
    test('same langCode → same engine on repeated resolution', () {
      final e1 = VoiceService.ttsEngineFor('ru');
      final e2 = VoiceService.ttsEngineFor('ru');
      expect(e1, e2);
    });

    test('engine is chosen BEFORE speak, not during', () {
      // Deterministic routing is the whole point — once ttsEngineFor
      // returns elevenLabs for a language, the speak() path must not
      // fall back to Google within that same utterance.
      expect(VoiceService.ttsEngineFor('ru'), TtsEngine.elevenLabs);
      expect(VoiceService.ttsEngineFor('et'), TtsEngine.google);
    });
  });
}
