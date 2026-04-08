import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

// ---------------------------------------------------------------------------
// Locale mapping for 17 supported languages
// ---------------------------------------------------------------------------

/// Maps our app language codes to the best STT/TTS locale identifiers.
const Map<String, String> _sttLocaleMap = {
  'en': 'en-US',
  'fi': 'fi-FI',
  'sv': 'sv-SE',
  'de': 'de-DE',
  'fr': 'fr-FR',
  'es': 'es-ES',
  'it': 'it-IT',
  'pl': 'pl-PL',
  'ro': 'ro-RO',
  'lt': 'lt-LT',
  'lv': 'lv-LV',
  'et': 'et-EE',
  'ru': 'ru-RU',
  'uk': 'uk-UA',
  'tr': 'tr-TR',
  'ar': 'ar-SA',
  'fa': 'fa-IR',
};

const Map<String, String> _ttsLocaleMap = {
  'en': 'en-US',
  'fi': 'fi-FI',
  'sv': 'sv-SE',
  'de': 'de-DE',
  'fr': 'fr-FR',
  'es': 'es-ES',
  'it': 'it-IT',
  'pl': 'pl-PL',
  'ro': 'ro-RO',
  'lt': 'lt-LT',
  'lv': 'lv-LV',
  'et': 'et-EE',
  'ru': 'ru-RU',
  'uk': 'uk-UA',
  'tr': 'tr-TR',
  'ar': 'ar-SA',
  'fa': 'fa-IR',
};

// ---------------------------------------------------------------------------
// Voice Service
// ---------------------------------------------------------------------------

class VoiceService {
  VoiceService();

  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _sttInitialized = false;
  bool _ttsInitialized = false;
  bool _isListening = false;
  bool _isSpeaking = false;

  final _partialController = StreamController<String>.broadcast();
  String _finalResult = '';

  // ── Getters ─────────────────────────────────────────────────────────────

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isSttAvailable => _sttInitialized;

  // ── Initialization ──────────────────────────────────────────────────────

  /// Initialize the speech-to-text engine. Returns true if available.
  Future<bool> initSpeech() async {
    if (_sttInitialized) return true;
    try {
      _sttInitialized = await _stt.initialize(
        onError: (error) {
          debugPrint('STT error: ${error.errorMsg}');
          _isListening = false;
        },
        onStatus: (status) {
          debugPrint('STT status: $status');
          if (status == 'notListening' || status == 'done') {
            _isListening = false;
          }
        },
      );
      return _sttInitialized;
    } catch (e) {
      debugPrint('STT init failed: $e');
      return false;
    }
  }

  /// Initialize the text-to-speech engine.
  Future<void> initTTS() async {
    if (_ttsInitialized) return;
    try {
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);

      _tts.setStartHandler(() {
        _isSpeaking = true;
      });
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
      });
      _tts.setCancelHandler(() {
        _isSpeaking = false;
      });
      _tts.setErrorHandler((msg) {
        debugPrint('TTS error: $msg');
        _isSpeaking = false;
      });

      _ttsInitialized = true;
    } catch (e) {
      debugPrint('TTS init failed: $e');
    }
  }

  // ── Speech-to-Text ─────────────────────────────────────────────────────

  /// Start listening. Returns a stream of partial recognition results.
  /// [langCode] should be one of the 17 app language codes (e.g. 'fi', 'en').
  Stream<String> startListening({String langCode = 'en'}) {
    if (!_sttInitialized || _isListening) return _partialController.stream;

    _finalResult = '';
    _isListening = true;

    final sttLocale = _sttLocaleMap[langCode] ?? 'en-US';
    debugPrint('STT: starting with langCode=$langCode, sttLocale=$sttLocale');

    _stt.listen(
      onResult: _onSpeechResult,
      localeId: sttLocale,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        cancelOnError: false,
        partialResults: true,
      ),
    );

    return _partialController.stream;
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    _finalResult = result.recognizedWords;
    _partialController.add(_finalResult);

    if (result.finalResult) {
      _isListening = false;
    }
  }

  /// Stop listening and return the final recognized text.
  Future<String> stopListening() async {
    if (_isListening) {
      await _stt.stop();
      _isListening = false;
    }
    return _finalResult;
  }

  // ── Text-to-Speech ─────────────────────────────────────────────────────

  /// Speak the given text aloud.
  /// [langCode] should be one of the 17 app language codes.
  Future<void> speak(String text, {String langCode = 'en'}) async {
    if (!_ttsInitialized || text.isEmpty) return;

    final ttsLocale = _ttsLocaleMap[langCode] ?? 'en-US';
    debugPrint('TTS: speaking with langCode=$langCode, ttsLocale=$ttsLocale');
    await _tts.setLanguage(ttsLocale);
    _isSpeaking = true;
    await _tts.speak(text);
  }

  /// Stop any ongoing speech.
  Future<void> stopSpeaking() async {
    await _tts.stop();
    _isSpeaking = false;
  }

  // ── Cleanup ─────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    await stopListening();
    await stopSpeaking();
    await _partialController.close();
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

final voiceServiceProvider = Provider<VoiceService>((ref) {
  final service = VoiceService();
  ref.onDispose(() => service.dispose());
  return service;
});
