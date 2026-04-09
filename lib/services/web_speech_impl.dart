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
