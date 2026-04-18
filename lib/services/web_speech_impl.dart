// Web implementation using dart:js_interop to call native Web Speech API
// defined in web/speech.js.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

bool webSpeechSupported() {
  try {
    final result = globalContext.callMethod('advocatIsSpeechSupported'.toJS);
    return (result as JSBoolean?)?.toDart ?? false;
  } catch (_) {
    return false;
  }
}

/// Request microphone permission before starting speech recognition.
/// Returns a [Future] that resolves to true if permission was granted.
/// On mobile browsers this triggers the native permission prompt.
Future<bool> webSpeechRequestMicPermission() async {
  try {
    final promise = globalContext.callMethod('advocatRequestMicPermission'.toJS);
    if (promise == null) return false;
    final result = await (promise as JSPromise).toDart;
    if (result is JSBoolean) return result.toDart;
    // Fallback: treat any non-null result as success.
    return result != null;
  } catch (_) {
    return false;
  }
}

bool webSpeechStart(String locale) {
  try {
    final result = globalContext.callMethod('advocatStartSpeech'.toJS, locale.toJS);
    return (result as JSBoolean?)?.toDart ?? false;
  } catch (_) {
    return false;
  }
}

void webSpeechStop() {
  try {
    globalContext.callMethod('advocatStopSpeech'.toJS);
  } catch (_) {}
}

String webSpeechGetResult() {
  try {
    final val = globalContext['_advocatSpeechResult'];
    return (val as JSString?)?.toDart ?? '';
  } catch (_) {
    return '';
  }
}

bool webSpeechIsFinal() {
  try {
    final val = globalContext['_advocatSpeechFinal'];
    return (val as JSBoolean?)?.toDart ?? false;
  } catch (_) {
    return false;
  }
}

bool webSpeechIsActive() {
  try {
    final val = globalContext['_advocatSpeechActive'];
    return (val as JSBoolean?)?.toDart ?? false;
  } catch (_) {
    return false;
  }
}

String webSpeechGetError() {
  try {
    final val = globalContext['_advocatSpeechError'];
    return (val as JSString?)?.toDart ?? '';
  } catch (_) {
    return '';
  }
}

// ---------------------------------------------------------------------------
// ElevenLabs TTS Audio Playback via JS
// ---------------------------------------------------------------------------

/// Play an audio Blob through the HTML5 Audio element defined in speech.js.
void webTtsPlayBlob(JSObject blob) {
  try {
    globalContext.callMethod('advocatPlayBlob'.toJS, blob);
  } catch (_) {}
}

/// Stop any currently playing ElevenLabs TTS audio.
void webTtsStopAudio() {
  try {
    globalContext.callMethod('advocatStopAudio'.toJS);
  } catch (_) {}
}

/// Returns true if ElevenLabs audio is currently playing.
bool webTtsIsSpeaking() {
  try {
    final val = globalContext['_advocatTtsSpeaking'];
    return (val as JSBoolean?)?.toDart ?? false;
  } catch (_) {
    return false;
  }
}

/// Play base64-encoded MP3 audio via the JS helper in speech.js.
void webTtsPlayBase64(String base64Audio) {
  try {
    globalContext.callMethod('advocatPlayBase64Audio'.toJS, base64Audio.toJS);
  } catch (_) {}
}

/// Full ElevenLabs TTS: fetch + play entirely in JS (avoids Dart↔JS data issues).
Future<bool> webTtsSpeakElevenLabs({
  required String text,
  required String voiceId,
  required String langCode,
  required String supabaseUrl,
  required String anonKey,
}) async {
  try {
    final json = '{"text":${_jsonEscape(text)},"voiceId":"$voiceId","langCode":"$langCode","supabaseUrl":"$supabaseUrl","anonKey":"$anonKey"}';
    final promise = globalContext.callMethod(
      'advocatSpeakElevenLabsJson'.toJS,
      json.toJS,
    );
    if (promise == null) return false;
    final result = await (promise as JSPromise).toDart;
    if (result is JSBoolean) return result.toDart;
    return result != null;
  } catch (_) {
    return false;
  }
}

/// Full Google TTS: fetch + play entirely in JS (same pattern as ElevenLabs).
Future<bool> webTtsSpeakGoogleTts({
  required String text,
  required String langCode,
  String gender = 'female',
  required String supabaseUrl,
  required String anonKey,
}) async {
  try {
    final json = '{"text":${_jsonEscape(text)},"langCode":"$langCode","gender":"$gender","supabaseUrl":"$supabaseUrl","anonKey":"$anonKey"}';
    final promise = globalContext.callMethod(
      'advocatSpeakGoogleTtsJson'.toJS,
      json.toJS,
    );
    if (promise == null) return false;
    final result = await (promise as JSPromise).toDart;
    if (result is JSBoolean) return result.toDart;
    return result != null;
  } catch (_) {
    return false;
  }
}

String _jsonEscape(String s) {
  return '"${s.replaceAll('\\', '\\\\').replaceAll('"', '\\"').replaceAll('\n', '\\n').replaceAll('\r', '\\r')}"';
}

// ---------------------------------------------------------------------------
// Whisper STT: MediaRecorder → Supabase whisper-stt → OpenAI Whisper
// ---------------------------------------------------------------------------

/// Whether the browser supports Whisper path (MediaRecorder + getUserMedia).
bool webWhisperSupported() {
  try {
    final result = globalContext.callMethod('advocatWhisperSupported'.toJS);
    return (result as JSBoolean?)?.toDart ?? false;
  } catch (_) {
    return false;
  }
}

/// Start Whisper recording with VAD auto-stop.
///
/// * [language] — ISO 639-1 code, or null for auto-detect (recommended for
///   multilingual users).
/// * [maxSeconds] — hard cap (default 15s).
/// * [silenceMs] — VAD silence threshold in ms (default 1500).
/// * [silenceLevel] — normalised RMS threshold (default 0.015).
Future<bool> webWhisperStart({
  required String supabaseUrl,
  required String anonKey,
  String? language,
  int maxSeconds = 15,
  int silenceMs = 1500,
  double silenceLevel = 0.015,
}) async {
  try {
    final langJson = language == null ? 'null' : '"$language"';
    final json = '{"supabaseUrl":"$supabaseUrl","anonKey":"$anonKey",'
        '"language":$langJson,"maxSeconds":$maxSeconds,'
        '"silenceMs":$silenceMs,"silenceLevel":$silenceLevel}';
    final promise = globalContext.callMethod(
      'advocatWhisperStart'.toJS,
      json.toJS,
    );
    if (promise == null) return false;
    final result = await (promise as JSPromise).toDart;
    if (result is JSBoolean) return result.toDart;
    return result != null;
  } catch (_) {
    return false;
  }
}

/// Stop any ongoing Whisper recording.
void webWhisperStop() {
  try {
    globalContext.callMethod('advocatWhisperStop'.toJS);
  } catch (_) {}
}

/// Current microphone RMS level (0-1), exposed by the VAD tick loop.
double webGetVoiceLevel() {
  try {
    final val = globalContext.callMethod('advocatGetVoiceLevel'.toJS);
    if (val is JSNumber) return val.toDartDouble;
    return 0;
  } catch (_) {
    return 0;
  }
}

