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

/// Which cloud TTS engine owns a particular language.
///
/// The routing decision is **deterministic per language** and must be made
/// BEFORE `speak()` starts playing audio. Within a single AI reply we never
/// switch engines — that's what caused the owner-reported "разные голоса
/// посреди ответа" regression (2026-04-22..23).
///
/// See `docs/tts-audit/02-voice-switching-root-cause.md`.
enum TtsEngine {
  /// ElevenLabs v3 via Supabase `tts-proxy`. Used for RU / EN / UK where
  /// owner confirmed the neutral-European voices (Charlotte / George)
  /// sound native. FROZEN 2026-04-21.
  elevenLabs,

  /// Google TTS via Supabase `google-tts` (Chirp3-HD for Estonian + preview
  /// languages; Gemini 3.1 Flash TTS for GA languages). Used for every
  /// language NOT in `VoiceService.preferElevenLabsSet`.
  google,
}

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
/// For Russian and English we prefer voices with a **neutral/European** accent
/// so multilingual synthesis in eleven_v3 sounds native rather than
/// American-accented (Rachel/Adam sounded off on Russian per user feedback
/// 2026-04-21).
///
/// Charlotte (Swedish/neutral female, warm) and George (British male, warm)
/// carry Russian and Ukrainian much better than US-accent premades.
const _elevenLabsVoices = {
  VoiceGender.female: 'XB0fDUnXU5powFXDhCwa', // Charlotte — neutral, warm
  VoiceGender.male: 'JBFqnCBsd6RMkjVDRZzb', // George — British, mature
};

/// Languages where ElevenLabs (eleven_v3) is noticeably more natural than
/// Google Chirp3-HD / Gemini 3.1. Keep Estonian on Google — the user is
/// happy with Chirp3-HD-Kore there and ElevenLabs has no native Estonian
/// training data.
///
/// Exposed as `VoiceService.preferElevenLabsSet` for the routing audit
/// tests. FROZEN by owner choice 2026-04-21.
const _preferElevenLabsFor = {
  'en', 'ru', 'uk',
};

/// Normalises `en-US` / `RU` / `et_EE` style language codes to their
/// lowercase base (`en`, `ru`, `et`) so routing is consistent regardless
/// of how the UI passes the locale.
String _normaliseLangBase(String langCode) =>
    langCode.toLowerCase().split(RegExp('[-_]')).first;

bool _shouldPreferElevenLabs(String langCode) {
  return _preferElevenLabsFor.contains(_normaliseLangBase(langCode));
}

// ---------------------------------------------------------------------------
// Voice Service
// ---------------------------------------------------------------------------

class VoiceService {
  VoiceService();

  // ── Public routing API ─────────────────────────────────────────────────
  //
  // `ttsEngineFor` returns which cloud TTS engine owns a given app locale.
  // The decision is a pure function of the language code — NOT runtime
  // state — so the whole AI reply can be synthesised by one engine in one
  // fetch, avoiding the "voice switches mid-response" regression.
  //
  // Contract locked by test/services/voice_routing_matrix_test.dart.

  /// The frozen set of languages that route to ElevenLabs. RU / EN / UK
  /// chosen by owner on 2026-04-21 — do not flip without explicit
  /// approval (red-line change, see `docs/tts-audit/02-…`).
  static Set<String> get preferElevenLabsSet => _preferElevenLabsFor;

  /// Which cloud TTS engine owns [langCode]. Accepts both base codes
  /// ("ru") and BCP-47 styles ("ru-RU", "en_US"). Unknown codes fall
  /// back to [TtsEngine.google] because Google Chirp3-HD / Gemini
  /// covers more languages than ElevenLabs SUPPORTED_LANGS.
  static TtsEngine ttsEngineFor(String langCode) {
    final base = _normaliseLangBase(langCode);
    return _preferElevenLabsFor.contains(base)
        ? TtsEngine.elevenLabs
        : TtsEngine.google;
  }

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

  /// Whether we are using the Whisper STT fallback path.
  /// Enabled when Web Speech API is unsupported (iOS Safari, Firefox).
  bool _useWhisperFallback = false;

  /// Whether STT init was attempted on web but failed (needs user gesture).
  bool _webSttDeferred = false;

  /// Current TTS voice gender preference.
  VoiceGender _voiceGender = VoiceGender.female;

  final _partialController = StreamController<String>.broadcast();
  String _finalResult = '';

  /// Last text emitted to the partial stream (to avoid duplicate emissions).
  String _lastEmittedResult = '';

  /// Timer used to poll JS STT recognition state on web.
  Timer? _sttPollTimer;

  /// Timer used to poll ElevenLabs TTS speaking state on web.
  Timer? _ttsPollTimer;

  // ── Getters ─────────────────────────────────────────────────────────────

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;

  /// Returns true when STT is ready, OR when running on web (lazy init).
  bool get isSttAvailable =>
      _sttInitialized ||
      _webSttDeferred ||
      _useNativeWebSpeech ||
      _useWhisperFallback;

  /// Current microphone RMS level (0-1) during active Whisper recording.
  /// Useful for waveform visualisation.  Returns 0 when not recording.
  double get voiceLevel =>
      (kIsWeb && _isListening) ? web_speech.webGetVoiceLevel() : 0;

  VoiceGender get voiceGender => _voiceGender;

  // ── Initialization ──────────────────────────────────────────────────────

  /// Initialize the speech-to-text engine. Returns true if available.
  ///
  /// On **web**, the Web Speech API often rejects `initialize()` when called
  /// without a preceding user gesture.  When that happens we check if the
  /// native Web Speech API is available via JS interop and use that instead.
  Future<bool> initSpeech() async {
    if (_sttInitialized) return true;

    // On web: prefer native Web Speech API, fall back to Whisper via
    // MediaRecorder (iOS Safari, Firefox, or if owner forces Whisper).
    if (kIsWeb) {
      final nativeSupported = web_speech.webSpeechSupported();
      final whisperSupported = web_speech.webWhisperSupported() &&
          AppConfig.supabaseUrl.isNotEmpty &&
          AppConfig.supabaseAnonKey.isNotEmpty;

      if (kDebugMode) {
        debugPrint('STT: web platform, native Speech API = $nativeSupported, '
            'Whisper fallback = $whisperSupported');
      }

      if (nativeSupported) {
        _useNativeWebSpeech = true;
        _useWhisperFallback = false;
        _webSttDeferred = false;
        _sttInitialized = false;
        return true;
      }

      if (whisperSupported) {
        // iOS Safari, Firefox, or any browser without Web Speech API but
        // with MediaRecorder — use Whisper over HTTPS.
        _useNativeWebSpeech = false;
        _useWhisperFallback = true;
        _webSttDeferred = false;
        _sttInitialized = false;
        return true;
      }

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

    // ── Web: choose path based on platform support ──
    if (kIsWeb) {
      if (_useWhisperFallback) {
        _beginWhisperListening(langCode);
      } else {
        _beginNativeWebListening(sttLocale);
      }
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
    _lastEmittedResult = '';
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

  /// Start Whisper STT via MediaRecorder + Supabase whisper-stt function.
  ///
  /// This is the iOS-Safari-and-Firefox-compatible path.  Runs entirely
  /// in JS (see `web/speech.js::advocatWhisperStart`) and sets the same
  /// `_advocatSpeechResult` / `_advocatSpeechActive` globals that the
  /// native Web Speech path uses, so the Dart poller treats both paths
  /// identically.
  void _beginWhisperListening(String langCode) {
    _finalResult = '';
    _lastEmittedResult = '';
    _isListening = true;

    if (kDebugMode) {
      debugPrint('STT: starting Whisper fallback (lang=$langCode)');
    }

    // `language = null` → Whisper auto-detects, which is critical for
    // users who switch between ET/RU/EN mid-sentence.  Passing a fixed
    // language locks the model into that locale and hurts WER.  For very
    // short utterances (single command) the auto-detect works poorly, so
    // we pass the UI's language as a HINT only.
    final hint = langCode;

    web_speech
        .webWhisperStart(
      supabaseUrl: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
      language: hint,
      maxSeconds: 15,
      silenceMs: 1500,
    )
        .then((started) {
      if (!started) {
        _isListening = false;
        final error = web_speech.webSpeechGetError();
        _partialController
            .addError(_humanizeWhisperError(error.isEmpty ? 'start_failed' : error));
        return;
      }
      _pollWhisperResults();
    }).catchError((e) {
      _isListening = false;
      _partialController.addError('Speech error: $e');
    });
  }

  String _humanizeWhisperError(String err) {
    switch (err) {
      case 'mic_permission_denied':
        return 'Microphone permission was denied. Please allow microphone '
            'access in your browser settings.';
      case 'no_media_devices':
        return 'This browser cannot access the microphone.';
      case 'whisper_not_configured':
        return 'Voice transcription is not configured. Please contact support.';
      case 'whisper_fetch_failed':
        return 'Voice transcription service is unreachable. Check your connection.';
      case 'no_audio':
        return 'No speech detected. Please try again.';
      default:
        return 'Speech error: $err';
    }
  }

  /// Poll JS state during Whisper recording.  Whisper produces a single
  /// final transcript when recording stops (not interim), so this poller
  /// waits for `_advocatSpeechFinal = true`.
  void _pollWhisperResults() {
    _sttPollTimer?.cancel();
    _sttPollTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!_isListening) {
        timer.cancel();
        return;
      }

      final isActive = web_speech.webSpeechIsActive();
      final error = web_speech.webSpeechGetError();
      final isFinal = web_speech.webSpeechIsFinal();
      final result = web_speech.webSpeechGetResult();

      // Always mirror interim voice level to partial consumers by
      // re-emitting the current text (may be empty before final).
      if (result.isNotEmpty && result != _lastEmittedResult) {
        _lastEmittedResult = result;
        _finalResult = result;
        _partialController.add(result);
      }

      if (error.isNotEmpty && error != 'done') {
        _partialController.addError(_humanizeWhisperError(error));
        _isListening = false;
        timer.cancel();
        return;
      }

      if (isFinal || !isActive) {
        // Recording complete.
        _finalResult = result;
        _isListening = false;
        timer.cancel();
      }
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
        if (result != _lastEmittedResult) {
          _lastEmittedResult = result;
          _partialController.add(result);
        }
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
      if (kIsWeb && _useWhisperFallback) {
        web_speech.webWhisperStop();
      } else if (kIsWeb && _useNativeWebSpeech) {
        web_speech.webSpeechStop();
      } else {
        await _stt.stop();
      }
      _isListening = false;
    }
    _lastEmittedResult = '';
    return _finalResult;
  }

  // ── Text-to-Speech ─────────────────────────────────────────────────────

  /// Whether Google TTS is available (web + Supabase configured).
  bool get _googleTtsAvailable =>
      kIsWeb &&
      AppConfig.supabaseUrl.isNotEmpty &&
      AppConfig.supabaseAnonKey.isNotEmpty;

  /// Pre-warm the Google TTS Edge Function to avoid cold start delays.
  /// Fire-and-forget: speaks a dot then immediately stops playback.
  Future<void> warmUp() async {
    if (!_googleTtsAvailable || !_ttsInitialized) return;
    try {
      final ok = await _speakWithGoogleTTS('.', langCode: 'en');
      if (ok) {
        // Stop immediately — we only wanted to wake up the Edge Function.
        await stopSpeaking();
      }
    } catch (_) {}
  }

  /// Speak the given text aloud.
  ///
  /// Contract (locked 2026-04-21, rewritten after owner-reported
  /// "voice switches mid-response" regression):
  ///
  ///   ONE reply → ONE engine → ONE fetch → ONE audio blob → ONE voice.
  ///
  /// The engine is picked *up front* by [ttsEngineFor] based on
  /// [langCode]. We attempt the primary engine. If and ONLY if the
  /// primary engine failed to start audio (returned false without
  /// playing a single sample), we fall back to the other cloud engine.
  /// Once audio is actually playing, we never switch — even if the
  /// `<audio>` element errors mid-playback.
  ///
  /// Fallback order:
  ///   RU/EN/UK:  ElevenLabs → (if never started) Google → Browser
  ///   others:    Google     → (if never started) ElevenLabs → Browser
  ///
  /// Never throws — always exits with [_isSpeaking] correctly reflecting
  /// whether an engine is actively playing.
  Future<void> speak(String text, {String langCode = 'en'}) async {
    // Post-bug-2 safety: even if the caller forgot to clean the text,
    // we strip the expressive tags here too so every route is safe.
    final cleaned = stripExpressiveTags(text).trim();
    if (!_ttsInitialized || cleaned.isEmpty) {
      if (kDebugMode) {
        debugPrint('TTS: speak() skipped — initialized=$_ttsInitialized, '
            'textEmpty=${cleaned.isEmpty}');
      }
      return;
    }
    text = cleaned;

    // Stop any audio still playing from a previous reply before we start
    // a new one. This is defence-in-depth — `advocatPlayBlob` also does
    // it — and plugs the race where two fetches from rapid sends both
    // complete and both try to play.
    await stopSpeaking();

    final engine = ttsEngineFor(langCode);

    // Primary: the engine that owns this language.
    final primaryStarted = await _tryEngine(engine, text, langCode: langCode);
    if (primaryStarted) return;

    // Primary never started audio — safe to try the other cloud engine
    // as a fallback. This is NOT mid-response switching: no sample has
    // been produced yet, so the user hears one engine start to finish.
    final other = engine == TtsEngine.elevenLabs
        ? TtsEngine.google
        : TtsEngine.elevenLabs;
    final otherStarted = await _tryEngine(other, text, langCode: langCode);
    if (otherStarted) return;

    // Last resort: browser SpeechSynthesis. Better than silence.
    try {
      await _speakWithBrowserTts(text, langCode: langCode);
    } catch (e) {
      if (kDebugMode) debugPrint('TTS: Browser TTS exception: $e');
    }
  }

  /// Attempts to start audio on [engine]. Returns true only if the engine
  /// successfully launched playback. Swallows exceptions so the caller
  /// can decide whether to fall back.
  Future<bool> _tryEngine(
    TtsEngine engine,
    String text, {
    required String langCode,
  }) async {
    switch (engine) {
      case TtsEngine.elevenLabs:
        if (!_elevenLabsAvailable) return false;
        try {
          return await _speakWithElevenLabs(text, langCode: langCode);
        } catch (e) {
          if (kDebugMode) debugPrint('TTS: ElevenLabs exception: $e');
          return false;
        }
      case TtsEngine.google:
        if (!_googleTtsAvailable) return false;
        try {
          return await _speakWithGoogleTTS(text, langCode: langCode);
        } catch (e) {
          if (kDebugMode) debugPrint('TTS: Google TTS exception: $e');
          return false;
        }
    }
  }

  /// Attempt to speak using Google TTS via the Supabase google-tts function.
  Future<bool> _speakWithGoogleTTS(
    String rawText, {
    String langCode = 'en',
  }) async {
    try {
      // Strip expressive tags (post-launch bug 2 fix). Google Chirp3-HD
      // does not parse [warmth], [thoughtful] etc and would speak the
      // literal bracket text, breaking the voice output for Estonian /
      // Finnish / and every other non-ElevenLabs language.
      final text = stripExpressiveTags(rawText);

      if (kDebugMode) {
        debugPrint('TTS: calling Google TTS, '
            'lang=$langCode, textLen=${text.length}');
      }

      if (kIsWeb) {
        _isSpeaking = true;
        final ok = await web_speech.webTtsSpeakGoogleTts(
          text: text,
          langCode: langCode,
          gender: _voiceGender == VoiceGender.male ? 'male' : 'female',
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
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!web_speech.webTtsIsSpeaking()) {
        _isSpeaking = false;
        timer.cancel();
      }
    });
  }

  /// Strip Gemini-style expressive tags like `[warmth]`, `[thoughtful]`
  /// before handing text to any TTS engine that does not natively support
  /// them (ElevenLabs, Google Chirp3-HD, browser SpeechSynthesis). The tag
  /// vocabulary is kept in sync with system_prompts.dart so every tag the
  /// LLM is permitted to emit is stripped here.
  ///
  /// Public so the chat UI can call it before building TTS-safe text and
  /// so tests can pin the contract.
  static final _geminiTagRegex = RegExp(
    r'\[(warmth|thoughtful|determination|sigh|reassuring|whispers|laughs|'
    r'excitement|enthusiasm|shouts|sarcastic|calm|confident|empathetic|'
    r'serious|gentle|firm|curious|hopeful|concerned)\]\s*',
    caseSensitive: false,
  );

  /// Public helper: removes every expressive audio tag from [text] and
  /// collapses any resulting double-whitespace.  Idempotent — a second
  /// call returns the same string.
  static String stripExpressiveTags(String text) {
    if (text.isEmpty) return text;
    final stripped = text.replaceAll(_geminiTagRegex, '');
    // Clean up residual double spaces that can appear after the regex
    // removes a leading tag followed by a space.
    return stripped.replaceAll(RegExp(r'  +'), ' ');
  }

  /// Attempt to speak using ElevenLabs via the Supabase tts-proxy function.
  /// On web, the entire fetch+play flow runs in JS (speech.js) to avoid
  /// Dart↔JS interop issues with large binary data.
  Future<bool> _speakWithElevenLabs(
    String rawText, {
    String langCode = 'en',
  }) async {
    try {
      final voiceId = _elevenLabsVoices[_voiceGender] ??
          _elevenLabsVoices[VoiceGender.female]!;

      final text = stripExpressiveTags(rawText);

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
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!web_speech.webTtsIsSpeaking()) {
        _isSpeaking = false;
        timer.cancel();
      }
    });
  }

  /// Fallback: speak using browser SpeechSynthesis / native TTS.
  Future<void> _speakWithBrowserTts(
    String rawText, {
    String langCode = 'en',
  }) async {
    // Browser TTS also cannot parse expressive tags — strip them.
    final text = stripExpressiveTags(rawText);
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
