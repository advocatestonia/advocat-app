// Stub implementation for non-web platforms.
// These functions are never called on mobile/desktop.

bool webSpeechSupported() => false;

bool webSpeechStart(String locale) => false;

void webSpeechStop() {}

String webSpeechGetResult() => '';

bool webSpeechIsFinal() => false;

bool webSpeechIsActive() => false;

String webSpeechGetError() => '';

// ElevenLabs TTS stubs for non-web platforms.
void webTtsPlayBlob(dynamic blob) {}
void webTtsStopAudio() {}
bool webTtsIsSpeaking() => false;
void webTtsPlayBase64(String base64Audio) {}
