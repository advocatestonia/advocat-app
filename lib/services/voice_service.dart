import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

// ---------------------------------------------------------------------------
// Voice gender preference for TTS
// ---------------------------------------------------------------------------

enum VoiceGender { female, male }

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

  /// Whether STT init was attempted on web but failed (needs user gesture).
  bool _webSttDeferred = false;

  /// Current TTS voice gender preference.
  VoiceGender _voiceGender = VoiceGender.female;

  final _partialController = StreamController<String>.broadcast();
  String _finalResult = '';

  // ── Getters ─────────────────────────────────────────────────────────────

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;

  /// Returns true when STT is ready, OR when running on web (lazy init).
  bool get isSttAvailable => _sttInitialized || _webSttDeferred;

  VoiceGender get voiceGender => _voiceGender;

  // ── Initialization ──────────────────────────────────────────────────────

  /// Initialize the speech-to-text engine. Returns true if available.
  ///
  /// On **web**, the Web Speech API often rejects `initialize()` when called
  /// without a preceding user gesture.  When that happens we mark the engine
  /// as *deferred* so the mic button is still shown; actual init will be
  /// retried lazily on the first tap (inside [startListening]).
  Future<bool> initSpeech() async {
    if (_sttInitialized) return true;
    try {
      _sttInitialized = await _stt.initialize(
        onError: (error) {
          if (kDebugMode) debugPrint('STT error: ${error.errorMsg}');
          _isListening = false;
        },
        onStatus: (status) {
          if (kDebugMode) debugPrint('STT status: $status');
          if (status == 'notListening' || status == 'done') {
            _isListening = false;
          }
        },
      );
      if (_sttInitialized) _webSttDeferred = false;
      return _sttInitialized;
    } catch (e) {
      if (kDebugMode) debugPrint('STT init failed: $e');
      // On web, mark as deferred so the button still appears.
      if (kIsWeb) {
        _webSttDeferred = true;
        return false;
      }
      return false;
    }
  }

  /// Try to lazily initialize STT (called from user gesture context on web).
  /// Returns true if initialization succeeded.
  Future<bool> _ensureSttInitialized() async {
    if (_sttInitialized) return true;
    try {
      _sttInitialized = await _stt.initialize(
        onError: (error) {
          if (kDebugMode) debugPrint('STT error: ${error.errorMsg}');
          _isListening = false;
        },
        onStatus: (status) {
          if (kDebugMode) debugPrint('STT status: $status');
          if (status == 'notListening' || status == 'done') {
            _isListening = false;
          }
        },
      );
      if (_sttInitialized) _webSttDeferred = false;
      return _sttInitialized;
    } catch (e) {
      if (kDebugMode) debugPrint('STT lazy init failed: $e');
      return false;
    }
  }

  /// Initialize the text-to-speech engine with natural voice settings.
  Future<void> initTTS() async {
    if (_ttsInitialized) return;
    try {
      await _tts.setVolume(1.0);
      // Slower rate for more natural pacing (default ~0.5 is too fast).
      await _tts.setSpeechRate(0.45);
      // Slightly lower pitch for a warmer, less robotic tone.
      await _tts.setPitch(0.9);

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
        if (kDebugMode) debugPrint('TTS error: $msg');
        _isSpeaking = false;
      });

      _ttsInitialized = true;

      // Select the best available voice after init.
      await _selectBestVoice();
    } catch (e) {
      if (kDebugMode) debugPrint('TTS init failed: $e');
    }
  }

  // ── Voice selection ───────────────────────────────────────────────────

  /// Preferred voice name substrings ordered by quality (best first).
  static const _preferredFemaleVoices = [
    'premium',
    'enhanced',
    'Google UK English Female',
    'Microsoft Zira',
    'Samantha',
    'Karen',
    'Moira',
    'Tessa',
    'Google US English',
  ];

  static const _preferredMaleVoices = [
    'premium',
    'enhanced',
    'Google UK English Male',
    'Microsoft David',
    'Daniel',
    'Alex',
    'Tom',
    'Google US English',
  ];

  /// Switch between male and female TTS voice.
  Future<void> setVoiceGender(VoiceGender gender) async {
    _voiceGender = gender;
    // Re-adjust pitch: lower for male, normal-ish for female.
    await _tts.setPitch(gender == VoiceGender.male ? 0.85 : 0.95);
    await _selectBestVoice();
  }

  /// Attempts to pick a high-quality voice from the available list.
  Future<void> _selectBestVoice() async {
    try {
      final voices = await _tts.getVoices;
      if (voices == null || voices is! List) return;

      final voiceList = List<Map<Object?, Object?>>.from(voices);
      if (voiceList.isEmpty) return;

      if (kDebugMode) {
        debugPrint('TTS: ${voiceList.length} voices available');
      }

      final preferred = _voiceGender == VoiceGender.male
          ? _preferredMaleVoices
          : _preferredFemaleVoices;

      // Try each preferred keyword in order.
      for (final keyword in preferred) {
        final lowerKeyword = keyword.toLowerCase();
        for (final v in voiceList) {
          final name = (v['name'] ?? '').toString().toLowerCase();
          final locale = (v['locale'] ?? '').toString().toLowerCase();
          if (name.contains(lowerKeyword) || locale.contains(lowerKeyword)) {
            await _tts.setVoice({
              'name': v['name'].toString(),
              'locale': v['locale'].toString(),
            });
            if (kDebugMode) {
              debugPrint('TTS: selected voice "${v['name']}" (${v['locale']})');
            }
            return;
          }
        }
      }

      if (kDebugMode) debugPrint('TTS: using default system voice');
    } catch (e) {
      if (kDebugMode) debugPrint('TTS voice selection failed: $e');
    }
  }

  // ── Speech-to-Text ─────────────────────────────────────────────────────

  /// Start listening. Returns a stream of partial recognition results.
  /// [langCode] should be one of the 17 app language codes (e.g. 'fi', 'en').
  ///
  /// On web, if STT was not yet initialized (deferred), we try a lazy init
  /// here since this is called from a user gesture context.
  Stream<String> startListening({String langCode = 'en'}) {
    if (_isListening) return _partialController.stream;

    // Lazy init on web — called inside a user gesture (tap).
    if (!_sttInitialized && _webSttDeferred) {
      _ensureSttInitialized().then((ok) {
        if (ok) {
          _beginListening(langCode);
        } else {
          _partialController.addError('Speech recognition unavailable');
        }
      });
      return _partialController.stream;
    }

    if (!_sttInitialized) return _partialController.stream;

    _beginListening(langCode);
    return _partialController.stream;
  }

  void _beginListening(String langCode) {
    _finalResult = '';
    _isListening = true;

    final sttLocale = _sttLocaleMap[langCode] ?? 'en-US';
    if (kDebugMode) debugPrint('STT: starting with langCode=$langCode, sttLocale=$sttLocale');

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
    if (kDebugMode) debugPrint('TTS: speaking with langCode=$langCode, ttsLocale=$ttsLocale');
    await _tts.setLanguage(ttsLocale);

    // Re-select best voice for the target language when it changes.
    await _selectBestVoiceForLocale(ttsLocale);

    _isSpeaking = true;
    await _tts.speak(text);
  }

  /// Try to find a premium/enhanced voice for a specific locale.
  Future<void> _selectBestVoiceForLocale(String locale) async {
    try {
      final voices = await _tts.getVoices;
      if (voices == null || voices is! List) return;

      final voiceList = List<Map<Object?, Object?>>.from(voices);
      if (voiceList.isEmpty) return;

      final localeLower = locale.toLowerCase();
      final genderKeywords = _voiceGender == VoiceGender.male
          ? ['male', 'david', 'daniel', 'alex', 'tom']
          : ['female', 'zira', 'samantha', 'karen', 'moira'];

      // First pass: find premium/enhanced voice matching locale & gender.
      for (final v in voiceList) {
        final name = (v['name'] ?? '').toString().toLowerCase();
        final vLocale = (v['locale'] ?? '').toString().toLowerCase();
        if (!vLocale.startsWith(localeLower.split('-').first)) continue;

        final isPremium = name.contains('premium') ||
            name.contains('enhanced') ||
            name.contains('neural');
        final matchesGender =
            genderKeywords.any((kw) => name.contains(kw));

        if (isPremium && matchesGender) {
          await _tts.setVoice({
            'name': v['name'].toString(),
            'locale': v['locale'].toString(),
          });
          return;
        }
      }

      // Second pass: any premium voice for that locale.
      for (final v in voiceList) {
        final name = (v['name'] ?? '').toString().toLowerCase();
        final vLocale = (v['locale'] ?? '').toString().toLowerCase();
        if (!vLocale.startsWith(localeLower.split('-').first)) continue;
        if (name.contains('premium') ||
            name.contains('enhanced') ||
            name.contains('neural')) {
          await _tts.setVoice({
            'name': v['name'].toString(),
            'locale': v['locale'].toString(),
          });
          return;
        }
      }
      // Otherwise fall through to the default voice for the locale.
    } catch (e) {
      if (kDebugMode) debugPrint('TTS locale voice selection failed: $e');
    }
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
