// voice_tag_stream_scrubber.dart
// -----------------------------------------------------------------------------
// BUG#2 fix (2026-04-29 pre-launch). Streaming-safe voice-tag stripper.
//
// Background.
//   System prompts permit Claude to emit Gemini-style expressive tags such
//   as `[warmth]`, `[thoughtful]`, `[determination]` — these are consumed
//   by the TTS pipeline and MUST NOT reach the chat bubble. The legacy
//   approach (AIService.sendChatStreaming, ai_service.dart:1379-1414) used
//   condition-based logic on `pending.lastIndexOf('[')`, which broke on
//   three real prod inputs:
//     • `[war` then `mth] hello`  — opens flushed early as literal `[war`.
//     • `[war mth]`               — heuristic saw the space and flushed
//                                   the buffer raw, exposing `[war mth]`.
//     • `[Article 26]`            — heuristic stripped legal citations.
//
// Design.
//   Explicit two-state machine:
//     OUTSIDE_TAG  — emit chars until we hit `[` then transition.
//     INSIDE_TAG   — buffer chars; on `]` close, decide whitelist vs. raw.
//   A whitelist of KNOWN voice tags (synced with VoiceService._geminiTagRegex)
//   determines whether a closed `[...]` is dropped or preserved verbatim.
//   Anything not in the whitelist (including legal citations like
//   `[Article 26]` or `[HMS § 40]`) is emitted as-is.
//
// Streaming contract.
//   • [feed] takes a chunk and returns text safe to forward to the UI.
//   • Bytes consumed inside a partial tag are held back until close.
//   • [flush] emits any buffered tail (e.g. an unclosed `[warm` at the
//     end of stream) verbatim — better visible truncation than a
//     silent drop. Mirrors the legacy "never lose user text" guarantee
//     from ai_service.dart:1410-1414.
//
// Tests live in test/services/voice_tag_state_machine_test.dart and pin
// the contract for every edge case above.
// -----------------------------------------------------------------------------

/// Stateful scrubber for streamed Claude output.
///
/// Use one instance per stream. Call [feed] for each delta from the SSE
/// pipe; concatenate the results. After the stream completes, call
/// [flush] once to drain any partial tag that never closed.
class VoiceTagStreamScrubber {
  VoiceTagStreamScrubber();

  /// Whitelist of voice-engine tags the LLM is permitted to emit.
  /// Anything here gets stripped (along with one trailing whitespace
  /// character if present, mirroring `VoiceService._geminiTagRegex`).
  ///
  /// Kept in sync with `VoiceService._geminiTagRegex` in voice_service.dart.
  /// If you add a tag to that regex, add it here too — and to the
  /// "all known tags" test in voice_tag_state_machine_test.dart.
  static const Set<String> _knownVoiceTags = <String>{
    'warmth',
    'thoughtful',
    'determination',
    'sigh',
    'reassuring',
    'whispers',
    'laughs',
    'excitement',
    'enthusiasm',
    'shouts',
    'sarcastic',
    'calm',
    'confident',
    'empathetic',
    'serious',
    'gentle',
    'firm',
    'curious',
    'hopeful',
    'concerned',
  };

  /// State: are we currently buffering chars inside a `[...]` block?
  bool _insideTag = false;

  /// When [_insideTag] is true, the body collected so far (without the
  /// opening `[`).
  final StringBuffer _tagBuffer = StringBuffer();

  /// True after a known tag was just stripped — used to consume one
  /// optional trailing whitespace, matching the regex pattern `\]\s*`
  /// in voice_service.dart.
  bool _consumeOneTrailingSpace = false;

  /// Feed a streamed chunk and return text safe to forward to the UI.
  ///
  /// May return `''` when every char is buffered inside a partial tag.
  String feed(String chunk) {
    if (chunk.isEmpty) return '';
    final out = StringBuffer();

    for (var i = 0; i < chunk.length; i++) {
      final ch = chunk[i];

      // Optional whitespace consumption immediately after a stripped tag.
      if (_consumeOneTrailingSpace) {
        _consumeOneTrailingSpace = false;
        if (ch == ' ' || ch == '\t') {
          continue; // swallow exactly one whitespace char
        }
        // No whitespace to swallow — fall through to the normal handler.
      }

      if (!_insideTag) {
        if (ch == '[') {
          _insideTag = true;
          _tagBuffer.clear();
          continue;
        }
        out.write(ch);
        continue;
      }

      // Inside a tag.
      if (ch == ']') {
        // Close — decide whitelist vs. preserve.
        final body = _tagBuffer.toString();
        _insideTag = false;
        _tagBuffer.clear();

        if (_knownVoiceTags.contains(body.toLowerCase())) {
          // Strip — and consume one optional trailing whitespace next char.
          _consumeOneTrailingSpace = true;
        } else {
          // Not a voice tag → emit verbatim, including the brackets.
          out.write('[');
          out.write(body);
          out.write(']');
        }
        continue;
      }

      if (ch == '[') {
        // A second `[` while inside an open tag means the first `[` was
        // never a voice tag (voice tags are `[a-z]+`, no nesting). Flush
        // the partial buffer literally and restart with this `[` as a
        // new candidate.
        out.write('[');
        out.write(_tagBuffer.toString());
        _tagBuffer.clear();
        // _insideTag stays true — this is the new opener.
        continue;
      }

      _tagBuffer.write(ch);
    }

    return out.toString();
  }

  /// Drain any buffered tail. Call once after the stream completes.
  ///
  /// If we ended mid-tag (open `[` with no matching `]`), the buffered
  /// text is returned verbatim so the user sees a visible truncation
  /// rather than a silent drop. Matches the legacy behaviour from
  /// ai_service.dart:1411-1414.
  String flush() {
    if (!_insideTag) return '';
    final tail = '[${_tagBuffer.toString()}';
    _insideTag = false;
    _tagBuffer.clear();
    _consumeOneTrailingSpace = false;
    return tail;
  }
}
