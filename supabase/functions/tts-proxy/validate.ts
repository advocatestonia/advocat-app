// tts-proxy input validator
// -----------------------------------------------------------------------------
// The voice id is interpolated into the ElevenLabs request path
//   https://api.elevenlabs.io/v1/text-to-speech/${voiceId}
// so it must be an opaque alphanumeric token. An attacker-controlled value with
// "/", "?", "#" or "." could inject path segments or query params and hit other
// ElevenLabs endpoints with our billed API key. ElevenLabs voice ids are
// 20-char alphanumeric (e.g. "21m00Tcm4TlvDq8ikWAM"); we accept 16–40 [A-Za-z0-9]
// to stay forward-compatible without ever permitting a path separator.
//
// Own module so the test can import the invariant without booting serve().
// -----------------------------------------------------------------------------

export function isValidVoiceId(id: unknown): id is string {
  return typeof id === "string" && /^[A-Za-z0-9]{16,40}$/.test(id);
}
