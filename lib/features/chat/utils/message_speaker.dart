// message_speaker.dart
//
// Owner-reported regression (2026-04-22..23): the AI voice switched
// mid-response as if "different people were speaking". The audit in
// `docs/tts-audit/` found two independent causes — this helper plugs the
// one that lives in the chat UI layer.
//
// Contract enforced here:
//
//   * A single AI reply = ONE voiceService.speak() call.
//   * Streaming chunks are accumulated into a buffer and only spoken after
//     `onStreamComplete()` fires.
//   * If a new reply starts while the previous audio is still playing,
//     we stop it first so the two replies do not blend into each other.
//   * Text cleanup (markdown, expressive tags, emoji severity markers) is
//     done ONCE immediately before `speak()` so every engine — ElevenLabs,
//     Google Chirp3-HD/Gemini, Browser — receives the same clean string.
//
// The helper takes a [VoiceSpeaker] interface rather than the concrete
// [VoiceService] so tests can drive it with an in-memory recorder.
// Widget/integration tests live in
// `test/features/chat/voice_single_utterance_test.dart`.

import '../../../services/voice_service.dart';

/// Minimal TTS surface the chat UI needs. Implemented by [VoiceService]
/// in production and by fakes in tests.
abstract class VoiceSpeaker {
  Future<void> speak(String text, {String langCode});
  Future<void> stopSpeaking();
  bool get isSpeaking;
}

/// Adapter: treat the full [VoiceService] as a [VoiceSpeaker].
class VoiceServiceSpeaker implements VoiceSpeaker {
  VoiceServiceSpeaker(this._service);
  final VoiceService _service;

  @override
  Future<void> speak(String text, {String langCode = 'en'}) =>
      _service.speak(text, langCode: langCode);

  @override
  Future<void> stopSpeaking() => _service.stopSpeaking();

  @override
  bool get isSpeaking => _service.isSpeaking;
}

/// Accumulates streamed chunks and speaks the full reply exactly once.
class MessageSpeaker {
  MessageSpeaker({
    required this.speaker,
    required this.langCode,
    this.enabled = true,
  });

  final VoiceSpeaker speaker;
  final String langCode;
  final bool enabled;

  final StringBuffer _buffer = StringBuffer();
  bool _spoken = false;

  /// Append a streamed chunk. No audio is produced here — we wait for
  /// [onStreamComplete] so the TTS engine gets the whole reply in a
  /// single fetch and produces one continuous voice.
  void onChunk(String chunk) {
    if (!enabled) return;
    _buffer.write(chunk);
  }

  /// Called when the LLM finishes streaming. Speaks the accumulated
  /// buffer exactly once. Calling this twice is a no-op (idempotent).
  Future<void> onStreamComplete() async {
    if (!enabled) return;
    if (_spoken) return;
    final text = cleanTextForTts(_buffer.toString()).trim();
    if (text.isEmpty) {
      _spoken = true;
      return;
    }
    _spoken = true;
    await _speakOnce(text);
  }

  /// Non-streaming path: when the full reply arrives at once (e.g. the
  /// tool-use fallback in chat_screen.dart) speak it immediately — still
  /// exactly once per reply.
  Future<void> speakFullResponse(String fullText) async {
    if (!enabled) return;
    if (_spoken) return;
    final text = cleanTextForTts(fullText).trim();
    if (text.isEmpty) {
      _spoken = true;
      return;
    }
    _spoken = true;
    await _speakOnce(text);
  }

  /// Reset the helper so it can be reused for the next AI reply.
  void reset() {
    _buffer.clear();
    _spoken = false;
  }

  Future<void> _speakOnce(String text) async {
    // If audio from a previous reply is still playing, stop it first.
    // `VoiceService.speak()` also does this defensively, but doing it
    // here makes the contract explicit at the feature boundary.
    if (speaker.isSpeaking) {
      await speaker.stopSpeaking();
    }
    await speaker.speak(text, langCode: langCode);
  }
}

/// Strip markdown, expressive audio tags, emoji severity markers, and
/// collapse whitespace so the TTS engine reads natural prose.
///
/// Kept in `message_speaker.dart` (not `chat_screen.dart`) so tests can
/// pin the behaviour without rendering a widget tree.
String cleanTextForTts(String text) {
  // Expressive audio tags like [warmth] — Gemini 3.1 parses them, every
  // other engine would read "bracket warmth bracket" literally. The
  // VoiceService does this again as defence-in-depth.
  var clean = VoiceService.stripExpressiveTags(text);
  // Bold / italic markers.
  clean = clean.replaceAll(RegExp(r'\*{1,3}'), '');
  // Headers.
  clean = clean.replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '');
  // Bullet points.
  clean = clean.replaceAll(RegExp(r'^[-•]\s*', multiLine: true), '');
  // Numbered lists — keep text.
  clean = clean.replaceAll(RegExp(r'^\d+\.\s*', multiLine: true), '');
  // Code blocks.
  clean = clean.replaceAll(RegExp(r'```\w*\n?'), '');
  // Inline code — keep text inside.
  clean = clean.replaceAll(RegExp(r'`([^`]+)`'), r'$1');
  // Blockquotes.
  clean = clean.replaceAll(RegExp(r'^>\s*', multiLine: true), '');
  // Markdown links — keep the visible text.
  clean = clean.replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'$1');
  // Emoji severity markers and common UI glyphs.
  clean = clean.replaceAll(
      RegExp(r'[🔴🟡🔵🟢⚠️📋🔍🚗📷📅📝✉️⚖️📊🌐⚙️✅❌ℹ️]'), '');
  // § → "paragrahv" for Estonian-style citations.
  clean = clean.replaceAll(RegExp(r'§\s*'), 'paragrahv ');
  // If, after formatting stripped, we have no visible characters left,
  // bail out early — no point turning pure whitespace into a lone ". ".
  if (clean.trim().isEmpty) return '';
  // Newlines → natural pauses.
  clean = clean.replaceAll(RegExp(r'\n{2,}'), '. ');
  clean = clean.replaceAll(RegExp(r'\n'), '. ');
  clean = clean.replaceAll(RegExp(r'\s{2,}'), ' ');
  return clean.trim();
}
