// voice_tag_state_machine_test.dart
//
// BUG#2 anti-regression (2026-04-29 pre-launch fix). The streaming voice-tag
// scrubber in AIService.sendChatStreaming used a condition-based heuristic
// (`pending.lastIndexOf('[')` plus `contains(']')` plus `contains(' ')`)
// that broke on three known edge cases:
//
//   1. Cross-chunk: `[war` arrives, then `mth] hello` — the heuristic
//      flushed `[war` early because the open bracket tail had no close yet.
//   2. Mid-tag space: `[war mth]` — the heuristic saw the space and flushed
//      the entire pending buffer, leaving the LITERAL `[war mth]` in the UI.
//   3. Stream-end with unclosed `[` — final flush would emit `[` raw.
//
// The new code is an explicit state machine: OUTSIDE_TAG ⇄ INSIDE_TAG with
// a strict known-tag whitelist (synced with VoiceService._geminiTagRegex).
// A bracket whose body is not in the whitelist is preserved verbatim — that
// protects legal citations like `[Article 26]` and `[HMS § 40]`.
//
// We test the pure state machine (no streaming infrastructure needed).
// The integration is exercised by ai_service_voice_tag_strip_test.dart.
//
// @Tags(['fast'])

@Tags(['fast'])
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/voice_tag_stream_scrubber.dart';

void main() {
  group('VoiceTagStreamScrubber — state machine', () {
    test('emits plain text unchanged', () {
      final s = VoiceTagStreamScrubber();
      expect(s.feed('Hello world'), 'Hello world');
      expect(s.flush(), '');
    });

    test('strips a known tag at the start of a single chunk', () {
      final s = VoiceTagStreamScrubber();
      // The leading whitespace after `]` is consumed too — matches the
      // existing VoiceService.stripExpressiveTags contract.
      expect(s.feed('[warmth] Hello'), 'Hello');
      expect(s.flush(), '');
    });

    test('strips a known tag mid-text', () {
      final s = VoiceTagStreamScrubber();
      expect(s.feed('Привет [thoughtful] как дела?'),
          'Привет как дела?');
      expect(s.flush(), '');
    });

    test('cross-chunk: [war then mth] hello → emits "hello"', () {
      // The scrubber holds the partial `[war` until the closing `]` arrives.
      // Nothing flushed before that, then "hello" flushed cleanly.
      final s = VoiceTagStreamScrubber();
      final part1 = s.feed('[war');
      expect(part1, '',
          reason: 'Open bracket without close must NOT flush yet');
      final part2 = s.feed('mth] hello');
      expect(part2, 'hello');
      expect(s.flush(), '');
    });

    test('cross-chunk where prefix arrived with normal text', () {
      final s = VoiceTagStreamScrubber();
      expect(s.feed('Listen up [warm'), 'Listen up ');
      expect(s.feed('th] really'), 'really');
      expect(s.flush(), '');
    });

    test('mid-tag space: [war mth] is preserved as-is (NOT a known tag)', () {
      // Voice tags never contain spaces. So `[war mth]` looks like a
      // citation or weird brace block — keep it verbatim. This was the
      // exact condition that triggered the prod regression.
      final s = VoiceTagStreamScrubber();
      expect(s.feed('[war mth] hello'), '[war mth] hello');
      expect(s.flush(), '');
    });

    test('legal bracket [Article 26] is preserved verbatim', () {
      final s = VoiceTagStreamScrubber();
      expect(s.feed('See [Article 26] for the rule.'),
          'See [Article 26] for the rule.');
      expect(s.flush(), '');
    });

    test('legal bracket [HMS § 40] survives across chunks', () {
      final s = VoiceTagStreamScrubber();
      expect(s.feed('Apply [HMS '), 'Apply ');
      expect(s.feed('§ 40] now'), '[HMS § 40] now');
      expect(s.flush(), '');
    });

    test('mixed input: [warmth] [Article 26] [thoughtful] text → "[Article 26] text"', () {
      final s = VoiceTagStreamScrubber();
      // Single chunk so we exercise the full intra-chunk path.
      final out = s.feed('[warmth] [Article 26] [thoughtful] text');
      expect(out, '[Article 26] text');
      expect(s.flush(), '');
    });

    test('case-insensitive: [Warmth] is stripped', () {
      final s = VoiceTagStreamScrubber();
      expect(s.feed('[Warmth] hi'), 'hi');
    });

    test('all known tags: every voice tag in the whitelist is stripped', () {
      const knownTags = [
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
      ];
      for (final tag in knownTags) {
        final s = VoiceTagStreamScrubber();
        expect(s.feed('[$tag] body'), 'body',
            reason: 'Tag $tag must be stripped');
      }
    });

    test('unclosed bracket at stream end → flushed verbatim (never lost)', () {
      // Edge case: model dies mid-tag. We must not silently drop user text.
      // Flush emits whatever is in the buffer raw — the user can see the
      // truncation rather than nothing.
      final s = VoiceTagStreamScrubber();
      expect(s.feed('hello [warm'), 'hello ');
      expect(s.flush(), '[warm');
    });

    test('two consecutive tags collapse cleanly', () {
      final s = VoiceTagStreamScrubber();
      expect(s.feed('[warmth][thoughtful]hello'), 'hello');
    });

    test('idempotent on already-clean text in tiny chunks', () {
      final s = VoiceTagStreamScrubber();
      final out = StringBuffer();
      for (final c in 'Hello world'.split('')) {
        out.write(s.feed(c));
      }
      out.write(s.flush());
      expect(out.toString(), 'Hello world');
    });

    test('does not concatenate previously-emitted text on new chunks', () {
      // The streaming consumer concatenates chunk outputs. The scrubber
      // must NEVER re-emit text it already emitted.
      final s = VoiceTagStreamScrubber();
      final a = s.feed('Привет ');
      final b = s.feed('мир');
      expect(a + b, 'Привет мир');
    });

    test('strips a tag whose body crosses a chunk boundary on every char', () {
      // Reproduce the original prod regression by feeding one byte at a time.
      final s = VoiceTagStreamScrubber();
      final out = StringBuffer();
      for (final c in '[warmth] Hello'.split('')) {
        out.write(s.feed(c));
      }
      out.write(s.flush());
      expect(out.toString(), 'Hello');
    });
  });
}
