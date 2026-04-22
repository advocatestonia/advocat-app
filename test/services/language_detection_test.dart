// language_detection_test.dart
//
// Tests for post-launch BUG 1: AI responded in the user's PROFILE language
// (set during onboarding) even when the current message was written in a
// different language.
//
// Owner report (2026-04-22): user wrote AI in Estonian, AI answered in
// Russian (profile default).
//
// The fix introduces a lightweight per-message language detector that runs
// in the Flutter client before the chat request is sent.  When the detected
// language of the CURRENT message differs from the user's stored preference,
// we override `userLanguage` so the Claude system prompt instructs the model
// to answer in the language of the message the user just typed.
//
// Detection is keyword + character-frequency based, not ML, so it has zero
// runtime cost and is deterministic on the test host.
//
// The detector lives in `lib/services/language_detector.dart`.

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/language_detector.dart';

void main() {
  group('LanguageDetector.detect — core languages', () {
    test('detects Estonian from keyword "tere"', () {
      expect(LanguageDetector.detect('Tere, aita mind palun'), 'et');
    });

    test('detects Estonian from keyword "sa oled"', () {
      expect(LanguageDetector.detect('Sa oled väga abivalmis'), 'et');
    });

    test('detects Estonian from keyword "aitäh"', () {
      expect(LanguageDetector.detect('Aitäh abi eest'), 'et');
    });

    test('detects Russian from keyword "привет"', () {
      expect(LanguageDetector.detect('Привет, помоги мне'), 'ru');
    });

    test('detects Russian from keyword "спасибо"', () {
      expect(LanguageDetector.detect('Спасибо большое'), 'ru');
    });

    test('detects Russian from Cyrillic script alone', () {
      expect(LanguageDetector.detect('мне не заплатили зарплату'), 'ru');
    });

    test('detects Ukrainian from "дякую"', () {
      expect(LanguageDetector.detect('Дякую за допомогу'), 'uk');
    });

    test('detects Finnish from "kiitos"', () {
      expect(LanguageDetector.detect('Kiitos paljon apua'), 'fi');
    });

    test('detects Finnish from "olen"', () {
      expect(LanguageDetector.detect('Olen saanut päätöksen'), 'fi');
    });

    test('detects English from common words', () {
      expect(LanguageDetector.detect('Hello, can you help me please'), 'en');
    });

    test('detects German from "bitte"', () {
      expect(LanguageDetector.detect('Bitte helfen Sie mir'), 'de');
    });
  });

  group('LanguageDetector.detect — mixed / short input', () {
    test('empty string returns null (no detection)', () {
      expect(LanguageDetector.detect(''), isNull);
    });

    test('whitespace-only returns null', () {
      expect(LanguageDetector.detect('   \n\t  '), isNull);
    });

    test('very short ambiguous input returns null (too short to guess)', () {
      // Single characters / one-letter inputs — refuse to guess.
      expect(LanguageDetector.detect('a'), isNull);
      expect(LanguageDetector.detect('ok'), isNull);
    });

    test('mixed ET+RU picks the dominant language (more ET tokens)', () {
      // 3 ET tokens vs 1 RU token → dominant ET
      expect(LanguageDetector.detect('Tere, sa oled aitäh помоги'), 'et');
    });

    test('mixed ET+RU picks dominant RU when RU wins', () {
      // 3 RU keywords vs 1 ET keyword → RU
      expect(
          LanguageDetector.detect('Привет спасибо пожалуйста tere'), 'ru');
    });

    test('digits only → null', () {
      expect(LanguageDetector.detect('12345'), isNull);
    });
  });

  group('LanguageDetector.resolveUserLanguage — override policy', () {
    // This is the integration point used by AIService before building the
    // Claude system prompt: given the user's profile preference + the current
    // message, decide which language to tell Claude to respond in.

    test('no profile pref, detectable message → use detected', () {
      final result = LanguageDetector.resolveUserLanguage(
        profileLanguage: null,
        message: 'Tere, aita mind',
      );
      expect(result, 'et');
    });

    test('profile=ru, message in Estonian → OVERRIDE to et', () {
      // This is the exact owner-reported symptom.
      final result = LanguageDetector.resolveUserLanguage(
        profileLanguage: 'ru',
        message: 'Tere, aita mind palun',
      );
      expect(result, 'et');
    });

    test('profile=et, message in Russian → OVERRIDE to ru', () {
      final result = LanguageDetector.resolveUserLanguage(
        profileLanguage: 'et',
        message: 'Привет, помоги мне пожалуйста',
      );
      expect(result, 'ru');
    });

    test('profile=ru, message also in Russian → keep ru (no override)', () {
      final result = LanguageDetector.resolveUserLanguage(
        profileLanguage: 'ru',
        message: 'Привет, помоги',
      );
      expect(result, 'ru');
    });

    test('profile=ru, message too short to detect → keep profile', () {
      // If we cannot detect reliably, respect the profile preference.
      final result = LanguageDetector.resolveUserLanguage(
        profileLanguage: 'ru',
        message: 'ok',
      );
      expect(result, 'ru');
    });

    test('profile=ru, message empty → keep profile', () {
      final result = LanguageDetector.resolveUserLanguage(
        profileLanguage: 'ru',
        message: '',
      );
      expect(result, 'ru');
    });

    test('profile=null, message too short → null (Claude falls back to prompt default)', () {
      final result = LanguageDetector.resolveUserLanguage(
        profileLanguage: null,
        message: 'ok',
      );
      expect(result, isNull);
    });

    test('mixed language message — dominant wins', () {
      // profile=ru, but message is clearly Estonian-dominant
      final result = LanguageDetector.resolveUserLanguage(
        profileLanguage: 'ru',
        message: 'Tere, sa oled aitäh abi eest',
      );
      expect(result, 'et');
    });
  });
}
