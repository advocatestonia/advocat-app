import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
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

  /// Dio instance for ElevenLabs TTS proxy calls.
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    responseType: ResponseType.bytes,
  ));

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

  /// Timer used to poll JS recognition state on web.
  Timer? _webPollTimer;

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

    // On web, first check if native Web Speech API is available.
    if (kIsWeb) {
      final nativeSupported = web_speech.webSpeechSupported();
      if (kDebugMode) {
        debugPrint('STT: native Web Speech API supported = $nativeSupported');
      }

      // Try the plugin first.
      try {
        _sttInitialized = await _stt.initialize(
          onError: (error) {
            if (kDebugMode) debugPrint('STT plugin error: ${error.errorMsg}');
            _isListening = false;
          },
          onStatus: (status) {
            if (kDebugMode) debugPrint('STT plugin status: $status');
            if (status == 'notListening' || status == 'done') {
              _isListening = false;
            }
          },
        );
      } catch (e) {
        if (kDebugMode) debugPrint('STT plugin init failed on web: $e');
        _sttInitialized = false;
      }

      // If the plugin worked, great.
      if (_sttInitialized) {
        if (kDebugMode) debugPrint('STT: using speech_to_text plugin on web');
        _webSttDeferred = false;
        return true;
      }

      // Plugin failed -- fall back to native JS if available.
      if (nativeSupported) {
        _useNativeWebSpeech = true;
        _webSttDeferred = false;
        if (kDebugMode) {
          debugPrint('STT: falling back to native Web Speech API via JS');
        }
        return true; // Report as available; will use JS on startListening.
      }

      // Neither works -- defer for lazy retry on tap.
      _webSttDeferred = true;
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

  /// Try to lazily initialize STT (called from user gesture context on web).
  Future<bool> _ensureSttInitialized() async {
    if (_sttInitialized) return true;
    if (_useNativeWebSpeech) return true;

    // On web, try the plugin once more from user gesture context.
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
      if (_sttInitialized) {
        _webSttDeferred = false;
        return true;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('STT lazy init plugin failed: $e');
    }

    // Last resort: try native JS.
    if (kIsWeb && web_speech.webSpeechSupported()) {
      _useNativeWebSpeech = true;
      _webSttDeferred = false;
      if (kDebugMode) {
        debugPrint('STT: lazy fallback to native Web Speech API');
      }
      return true;
    }

    return false;
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

    // ── Web: native JS Speech API fallback ──
    if (kIsWeb && _useNativeWebSpeech) {
      _beginNativeWebListening(sttLocale);
      return _partialController.stream;
    }

    // ── Web: lazy init for deferred plugin ──
    if (!_sttInitialized && _webSttDeferred) {
      _ensureSttInitialized().then((ok) {
        if (ok && _useNativeWebSpeech) {
          // Fell back to native during lazy init.
          _beginNativeWebListening(sttLocale);
        } else if (ok) {
          _beginListening(langCode);
        } else {
          _partialController.addError('Speech recognition unavailable');
        }
      });
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
  void _beginNativeWebListening(String sttLocale) {
    _finalResult = '';
    _isListening = true;

    if (kDebugMode) {
      debugPrint('STT: starting native Web Speech API with locale=$sttLocale');
    }

    final started = web_speech.webSpeechStart(sttLocale);
    if (!started) {
      _isListening = false;
      final error = web_speech.webSpeechGetError();
      if (kDebugMode) debugPrint('STT: native web start failed: $error');
      _partialController
          .addError('Speech recognition failed: ${error.isNotEmpty ? error : "unknown error"}');
      return;
    }

    // Poll the JS global state every 150ms for results.
    _webPollTimer?.cancel();
    _webPollTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      final result = web_speech.webSpeechGetResult();
      final isFinal = web_speech.webSpeechIsFinal();
      final isActive = web_speech.webSpeechIsActive();
      final error = web_speech.webSpeechGetError();

      if (error.isNotEmpty && error != 'done') {
        if (kDebugMode) debugPrint('STT: native web error: $error');
        // "no-speech" is not a real error -- just means user was silent.
        if (error != 'no-speech') {
          _partialController.addError('Speech error: $error');
        }
        _isListening = false;
        timer.cancel();
        return;
      }

      if (result.isNotEmpty) {
        _finalResult = result;
        _partialController.add(result);
      }

      if (isFinal || !isActive) {
        _isListening = false;
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
    _webPollTimer?.cancel();
    _webPollTimer = null;

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

  /// Speak the given text aloud.
  /// [langCode] should be one of the 17 app language codes.
  ///
  /// On web with Supabase configured, uses ElevenLabs premium TTS via the
  /// `tts-proxy` Edge Function. Falls back to browser SpeechSynthesis on
  /// failure or when ElevenLabs is unavailable.
  Future<void> speak(String text, {String langCode = 'en'}) async {
    if (!_ttsInitialized || text.isEmpty) return;

    // Try ElevenLabs first on web when Supabase proxy is available.
    if (_elevenLabsAvailable) {
      final ok = await _speakWithElevenLabs(text, langCode: langCode);
      if (ok) return;
      // ElevenLabs failed -- fall through to browser TTS.
      if (kDebugMode) {
        debugPrint('TTS: ElevenLabs failed, falling back to browser TTS');
      }
    }

    // Browser / native TTS fallback.
    await _speakWithBrowserTts(text, langCode: langCode);
  }

  /// Attempt to speak using ElevenLabs via the Supabase tts-proxy function.
  /// Returns true on success.
  Future<bool> _speakWithElevenLabs(
    String text, {
    String langCode = 'en',
  }) async {
    try {
      final voiceId = _elevenLabsVoices[_voiceGender] ??
          _elevenLabsVoices[VoiceGender.female]!;

      const url = '${AppConfig.supabaseUrl}/functions/v1/tts-proxy';

      if (kDebugMode) {
        debugPrint('TTS: calling ElevenLabs proxy, voice=$voiceId, '
            'lang=$langCode, textLen=${text.length}');
      }

      final response = await _dio.post<List<int>>(
        url,
        data: jsonEncode({
          'text': text,
          'voice_id': voiceId,
          'language': langCode,
        }),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          },
          responseType: ResponseType.bytes,
        ),
      );

      if (response.statusCode != 200 || response.data == null) {
        if (kDebugMode) {
          debugPrint('TTS: ElevenLabs proxy returned ${response.statusCode}');
        }
        return false;
      }

      final audioBytes = response.data!;
      if (audioBytes.isEmpty) return false;

      // On web, create a Blob and play through JS.
      if (kIsWeb) {
        _isSpeaking = true;
        _playAudioBytesOnWeb(audioBytes);
        return true;
      }

      return false; // Non-web not supported for ElevenLabs yet.
    } catch (e) {
      if (kDebugMode) debugPrint('TTS: ElevenLabs error: $e');
      return false;
    }
  }

  /// Play raw MP3 bytes on web via JS interop (speech.js advocatPlayBlob).
  void _playAudioBytesOnWeb(List<int> bytes) {
    if (!kIsWeb) return;
    try {
      // Use JS interop to create a Blob and play it.
      // We pass the bytes as a base64 string and decode in JS.
      _playBase64AudioOnWeb(base64Encode(bytes));
    } catch (e) {
      if (kDebugMode) debugPrint('TTS: web audio play failed: $e');
      _isSpeaking = false;
    }
  }

  /// Play base64-encoded MP3 audio on web via inline JS.
  void _playBase64AudioOnWeb(String base64Audio) {
    if (!kIsWeb) return;
    try {
      // Use dart:js_interop to call a helper that decodes and plays.
      web_speech.webTtsPlayBase64(base64Audio);
      _isSpeaking = true;
      // Poll for completion.
      _pollElevenLabsSpeaking();
    } catch (e) {
      if (kDebugMode) debugPrint('TTS: base64 play failed: $e');
      _isSpeaking = false;
    }
  }

  /// Poll JS state to detect when ElevenLabs audio finishes.
  void _pollElevenLabsSpeaking() {
    _webPollTimer?.cancel();
    _webPollTimer =
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
    // Stop ElevenLabs audio on web.
    if (kIsWeb) {
      web_speech.webTtsStopAudio();
    }
    await _tts.stop();
    _isSpeaking = false;
  }

  // ── Cleanup ─────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    _webPollTimer?.cancel();
    _webPollTimer = null;
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
