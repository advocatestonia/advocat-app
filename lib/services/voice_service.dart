import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../config/app_config.dart';
import 'web_speech.dart' as web_speech;

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
// ElevenLabs Voice IDs
// ---------------------------------------------------------------------------

/// Premium ElevenLabs voice IDs.
/// Rachel (female) - warm, professional; Adam (male) - clear, confident.
const _elevenLabsVoices = {
  VoiceGender.female: '21m00Tcm4TlvDq8ikWAM', // Rachel
  VoiceGender.male: 'pNInz6obpgDQGcFmaJgB', // Adam
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

  /// Whether ElevenLabs TTS is available (web + Supabase configured).
  bool get _elevenLabsAvailable =>
      kIsWeb &&
      AppConfig.supabaseUrl.isNotEmpty &&
      AppConfig.supabaseAnonKey.isNotEmpty;

  /// Whether we are using the native JS Web Speech API fallback.
  bool _useNativeWebSpeech = false;

  /// Whether STT init was attempted on web but failed (needs user gesture).
  bool _webSttDeferred = false;

  /// Current TTS voice gender preference.
  VoiceGender _voiceGender = VoiceGender.female;

  final _partialController = StreamController<String>.broadcast();
  String _finalResult = '';

  /// Timer used to poll JS STT recognition state on web.
  Timer? _sttPollTimer;

  /// Timer used to poll ElevenLabs TTS speaking state on web.
  Timer? _ttsPollTimer;

  // ── Getters ─────────────────────────────────────────────────────────────

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;

  /// Returns true when STT is ready, OR when running on web (lazy init).
  bool get isSttAvailable =>
      _sttInitialized || _webSttDeferred || _useNativeWebSpeech;

  VoiceGender get voiceGender => _voiceGender;

  // ── Initialization ──────────────────────────────────────────────────────

  /// Initialize the speech-to-text engine. Returns true if available.
  ///
  /// On **web**, the Web Speech API often rejects `initialize()` when called
  /// without a preceding user gesture.  When that happens we check if the
  /// native Web Speech API is available via JS interop and use that instead.
  Future<bool> initSpeech() async {
    if (_sttInitialized) return true;

    // On web: ALWAYS use native JS Web Speech API. Skip Flutter plugin entirely.
    if (kIsWeb) {
      final nativeSupported = web_speech.webSpeechSupported();
      if (kDebugMode) {
        debugPrint('STT: web platform, native Speech API supported = $nativeSupported');
      }

      if (nativeSupported) {
        _useNativeWebSpeech = true;
        _webSttDeferred = false;
        _sttInitialized = false; // Don't use plugin on web
        return true;
      }

      // Web Speech API not supported (e.g. Firefox, iOS Safari)
      _webSttDeferred = false;
      return false;
    }

    // Non-web platforms: use the plugin directly.
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
      return _sttInitialized;
    } catch (e) {
      if (kDebugMode) debugPrint('STT init failed: $e');
      return false;
    }
  }

  /// Initialize the text-to-speech engine with natural voice settings.
  Future<void> initTTS() async {
    if (_ttsInitialized) return;
    try {
      await _tts.setVolume(1.0);
      // Slower rate for more natural pacing (default ~0.5 is too fast).
      await _tts.setSpeechRate(kIsWeb ? 0.9 : 0.45);
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

      // On web, ensure volume is explicitly set again after init.
      if (kIsWeb) {
        await _tts.setVolume(1.0);
      }

      // Select the best available voice after init.
      await _selectBestVoice();
    } catch (e) {
      if (kDebugMode) debugPrint('TTS init failed: $e');
      // On web, mark as initialized anyway -- SpeechSynthesis often works
      // even if getVoices or setVoice throws during setup.
      if (kIsWeb) _ttsInitialized = true;
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

    final sttLocale = _sttLocaleMap[langCode] ?? 'en-US';

    // ── Web: ALWAYS use native JS Speech API ──
    if (kIsWeb) {
      _beginNativeWebListening(sttLocale);
      return _partialController.stream;
    }

    if (!_sttInitialized) {
      if (kDebugMode) debugPrint('STT: not initialized, cannot listen');
      return _partialController.stream;
    }

    _beginListening(langCode);
    return _partialController.stream;
  }

  /// Start listening using the speech_to_text plugin.
  void _beginListening(String langCode) {
    _finalResult = '';
    _isListening = true;

    final sttLocale = _sttLocaleMap[langCode] ?? 'en-US';
    if (kDebugMode) {
      debugPrint(
          'STT: starting plugin with langCode=$langCode, sttLocale=$sttLocale');
    }

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

  /// Start listening using the native Web Speech API via JS interop.
  ///
  /// On mobile browsers, we first request microphone permission explicitly
  /// via `getUserMedia` to ensure the permission prompt fires reliably.
  void _beginNativeWebListening(String sttLocale) {
    _finalResult = '';
    _isListening = true;

    if (kDebugMode) {
      debugPrint('STT: starting native Web Speech API with locale=$sttLocale');
    }

    // Request mic permission first (important for mobile browsers).
    web_speech.webSpeechRequestMicPermission().then((granted) {
      if (!granted) {
        if (kDebugMode) debugPrint('STT: mic permission denied');
      }
      // Proceed even if permission request failed -- SpeechRecognition
      // will surface its own error if mic is not available.
      _startNativeRecognition(sttLocale);
    }).catchError((_) {
      // Fallback: try anyway.
      _startNativeRecognition(sttLocale);
    });
  }

  /// Actually starts the native JS SpeechRecognition after permission.
  void _startNativeRecognition(String sttLocale) {
    final started = web_speech.webSpeechStart(sttLocale);
    if (!started) {
      _isListening = false;
      final error = web_speech.webSpeechGetError();
      if (kDebugMode) debugPrint('STT: native web start failed: $error');

      // Provide user-friendly error messages.
      String userMessage;
      if (error == 'ios_safari_not_supported') {
        userMessage =
            'Voice input is not supported on this browser. Please use Chrome.';
      } else if (error == 'mic_permission_denied') {
        userMessage =
            'Microphone permission was denied. Please allow microphone access in your browser settings.';
      } else if (error == 'network_error') {
        userMessage =
            'Network error during speech recognition. Please check your connection.';
      } else {
        userMessage =
            'Speech recognition failed: ${error.isNotEmpty ? error : "unknown error"}';
      }
      _partialController.addError(userMessage);
      return;
    }

    // Poll the JS global state every 150ms for results.
    // In continuous mode, we keep polling until user explicitly stops
    // (which sets _isListening = false via stopListening()).
    _sttPollTimer?.cancel();
    _sttPollTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      // If stopListening() was called, stop polling.
      if (!_isListening) {
        timer.cancel();
        return;
      }

      final result = web_speech.webSpeechGetResult();
      final isActive = web_speech.webSpeechIsActive();
      final error = web_speech.webSpeechGetError();

      if (error.isNotEmpty && error != 'done') {
        if (kDebugMode) debugPrint('STT: native web error: $error');
        // "no-speech" is not a real error -- just means user was silent.
        if (error != 'no-speech' && error != 'aborted') {
          String errorMessage;
          if (error == 'no_recognition') {
            errorMessage =
                'Speech recognition could not detect audio. Please check your microphone and try again.';
          } else {
            errorMessage = 'Speech error: $error';
          }
          _partialController.addError(errorMessage);
          _isListening = false;
          timer.cancel();
          return;
        }
      }

      if (result.isNotEmpty) {
        _finalResult = result;
        _partialController.add(result);
      }

      // Only stop if JS side has deactivated (real error or user stop).
      if (!isActive && !_isListening) {
        timer.cancel();
      }
    });
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
    _sttPollTimer?.cancel();
    _sttPollTimer = null;

    if (_isListening) {
      if (kIsWeb && _useNativeWebSpeech) {
        web_speech.webSpeechStop();
      } else {
        await _stt.stop();
      }
      _isListening = false;
    }
    return _finalResult;
  }

  // ── Text-to-Speech ─────────────────────────────────────────────────────

  /// Whether Google TTS is available (web + Supabase configured).
  bool get _googleTtsAvailable =>
      kIsWeb &&
      AppConfig.supabaseUrl.isNotEmpty &&
      AppConfig.supabaseAnonKey.isNotEmpty;

  /// Speak the given text aloud.
  /// [langCode] should be one of the 17 app language codes.
  ///
  /// Priority order:
  /// 1. Google TTS (cheaper, better Estonian/multilingual support)
  /// 2. ElevenLabs premium TTS (fallback for premium voice quality)
  /// 3. Browser SpeechSynthesis (last resort)
  Future<void> speak(String text, {String langCode = 'en'}) async {
    if (!_ttsInitialized || text.isEmpty) return;

    // 1. Try Google TTS first (cheaper, better Estonian support).
    if (_googleTtsAvailable) {
      final ok = await _speakWithGoogleTTS(text, langCode: langCode);
      if (ok) return;
      if (kDebugMode) {
        debugPrint('TTS: Google TTS failed, trying ElevenLabs');
      }
    }

    // 2. Try ElevenLabs as premium fallback.
    if (_elevenLabsAvailable) {
      final ok = await _speakWithElevenLabs(text, langCode: langCode);
      if (ok) return;
      if (kDebugMode) {
        debugPrint('TTS: ElevenLabs failed, falling back to browser TTS');
      }
    }

    // 3. Browser TTS fallback — only for languages with reliable browser voices.
    const browserTtsReliable = {'en', 'ru', 'de', 'fr', 'es', 'it', 'pl', 'tr', 'et', 'fi', 'sv'};
    if (!browserTtsReliable.contains(langCode)) {
      if (kDebugMode) {
        debugPrint('TTS: skipping browser TTS for $langCode (no reliable voice)');
      }
      return;
    }

    await _speakWithBrowserTts(text, langCode: langCode);
  }

  /// Attempt to speak using Google TTS via the Supabase google-tts function.
  Future<bool> _speakWithGoogleTTS(
    String text, {
    String langCode = 'en',
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('TTS: calling Google TTS, '
            'lang=$langCode, textLen=${text.length}');
      }

      if (kIsWeb) {
        _isSpeaking = true;
        final ok = await web_speech.webTtsSpeakGoogleTts(
          text: text,
          langCode: langCode,
          supabaseUrl: AppConfig.supabaseUrl,
          anonKey: AppConfig.supabaseAnonKey,
        );
        if (ok) {
          _pollCloudTtsSpeaking();
          return true;
        }
        _isSpeaking = false;
        return false;
      }

      return false; // Non-web not supported yet.
    } catch (e) {
      if (kDebugMode) debugPrint('TTS: Google TTS error: $e');
      _isSpeaking = false;
      return false;
    }
  }

  /// Poll JS state to detect when cloud TTS audio (Google/ElevenLabs) finishes.
  void _pollCloudTtsSpeaking() {
    _ttsPollTimer?.cancel();
    _ttsPollTimer =
        Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!web_speech.webTtsIsSpeaking()) {
        _isSpeaking = false;
        timer.cancel();
      }
    });
  }

  /// Attempt to speak using ElevenLabs via the Supabase tts-proxy function.
  /// On web, the entire fetch+play flow runs in JS (speech.js) to avoid
  /// Dart↔JS interop issues with large binary data.
  Future<bool> _speakWithElevenLabs(
    String text, {
    String langCode = 'en',
  }) async {
    try {
      final voiceId = _elevenLabsVoices[_voiceGender] ??
          _elevenLabsVoices[VoiceGender.female]!;

      if (kDebugMode) {
        debugPrint('TTS: calling ElevenLabs, voice=$voiceId, '
            'lang=$langCode, textLen=${text.length}');
      }

      if (kIsWeb) {
        // Run entirely in JS to avoid Dart↔JS binary data issues.
        _isSpeaking = true;
        final ok = await web_speech.webTtsSpeakElevenLabs(
          text: text,
          voiceId: voiceId,
          langCode: langCode,
          supabaseUrl: AppConfig.supabaseUrl,
          anonKey: AppConfig.supabaseAnonKey,
        );
        if (ok) {
          _pollElevenLabsSpeaking();
          return true;
        }
        _isSpeaking = false;
        return false;
      }

      return false; // Non-web not supported for ElevenLabs yet.
    } catch (e) {
      if (kDebugMode) debugPrint('TTS: ElevenLabs error: $e');
      _isSpeaking = false;
      return false;
    }
  }

  /// Poll JS state to detect when ElevenLabs audio finishes.
  void _pollElevenLabsSpeaking() {
    _ttsPollTimer?.cancel();
    _ttsPollTimer =
        Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!web_speech.webTtsIsSpeaking()) {
        _isSpeaking = false;
        timer.cancel();
      }
    });
  }

  /// Fallback: speak using browser SpeechSynthesis / native TTS.
  Future<void> _speakWithBrowserTts(
    String text, {
    String langCode = 'en',
  }) async {
    final ttsLocale = _ttsLocaleMap[langCode] ?? 'en-US';
    if (kDebugMode) {
      debugPrint(
          'TTS: speaking with langCode=$langCode, ttsLocale=$ttsLocale');
    }
    await _tts.setLanguage(ttsLocale);

    // Ensure volume is set on web before every speak call.
    if (kIsWeb) {
      await _tts.setVolume(1.0);
    }

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

  /// Stop any ongoing speech (both ElevenLabs and browser TTS).
  Future<void> stopSpeaking() async {
    _ttsPollTimer?.cancel();
    _ttsPollTimer = null;
    // Stop ElevenLabs audio on web.
    if (kIsWeb) {
      web_speech.webTtsStopAudio();
    }
    await _tts.stop();
    _isSpeaking = false;
  }

  // ── Cleanup ─────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    _sttPollTimer?.cancel();
    _sttPollTimer = null;
    _ttsPollTimer?.cancel();
    _ttsPollTimer = null;
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
