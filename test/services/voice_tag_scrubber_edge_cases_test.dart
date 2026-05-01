// voice_tag_scrubber_edge_cases_test.dart
//
// OMEGA pre-launch QA expansion (2026-04-29). The existing
// `voice_tag_state_machine_test.dart` covers happy-path tag stripping +
// the three named prod regressions. This file adds adversarial /
// pathological inputs the production model can produce when the
// system prompt drifts or a user pastes unusual text:
//
//   • zero-length / whitespace-only chunks across the stream lifecycle
//   • empty `[]` brackets
//   • repeated `[[[` opens
//   • malformed nested tags `[warmth[thoughtful]]`
//   • upper-case + mixed-case tag bodies
//   • Cyrillic / Estonian tag bodies (must NOT be stripped — voice tags
//     are ASCII-only by spec)
//   • emoji inside the bracket body
//   • whitelist tag followed by punctuation (`.`, `,`, `:` — the regex
//     pattern `\]\s*` only swallows ONE whitespace, so punctuation must
//     pass through)
//   • feeding a single chunk per character through the entire mixed
//     pipeline reproduces the byte-level streaming behaviour
//
// All tests assert two invariants:
//   1. The scrubber NEVER drops user text — anything that isn't a
//      whitelisted voice tag survives (possibly verbatim with brackets).
//   2. The output of the streaming path equals the output of feeding
//      the same string in one shot.
//
// @Tags(['fast'])

@Tags(['fast'])
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/voice_tag_stream_scrubber.dart';

void main() {
  group('VoiceTagStreamScrubber — pathological / adversarial inputs', () {
    test('empty chunk feeds return empty string and do not advance state', () {
      final s = VoiceTagStreamScrubber();
      expect(s.feed(''), '');
      expect(s.feed(''), '');
      expect(s.feed('hello'), 'hello');
      expect(s.flush(), '');
    });

    test('whitespace-only chunks pass through verbatim', () {
      final s = VoiceTagStreamScrubber();
      expect(s.feed('   '), '   ');
      expect(s.feed('\t\n'), '\t\n');
      expect(s.flush(), '');
    });

    test('empty `[]` is preserved verbatim (not a voice tag)', () {
      // Empty body is not in the whitelist, so the brackets must survive.
      final s = VoiceTagStreamScrubber();
      expect(s.feed('hi [] there'), 'hi [] there');
      expect(s.flush(), '');
    });

    test('triple open `[[[warmth]` resets twice and emits literal `[[`', () {
      // Each new `[` while inside a partial buffer flushes the prior `[body`
      // verbatim. Three opens = two flushes + one resetting opener.
      final s = VoiceTagStreamScrubber();
      final out = s.feed('[[[warmth] tail');
      // First `[` opens. Second `[` flushes empty body → `[`, restarts.
      // Third `[` flushes empty body → `[`, restarts. `warmth]` then
      // closes a known tag → stripped + 1 trailing space consumed.
      expect(out, '[[tail');
      expect(s.flush(), '');
    });

    test('nested-looking `[warmth[thoughtful]]` preserves outer brackets', () {
      // Inner `[` while inside outer flushes outer body literally and
      // restarts the inner. Inner `thoughtful]` closes a known tag →
      // stripped. The trailing `]` then has no opener → emitted verbatim.
      final s = VoiceTagStreamScrubber();
      final out = s.feed('[warmth[thoughtful]] end');
      // After flush of literal `[warmth`, `thoughtful]` is stripped (and
      // the next char is consumed as trailing space, but next char is `]`
      // not whitespace, so it survives). Then `] end` flows through.
      expect(out.contains('[warmth'), isTrue,
          reason: 'literal [warmth must survive when followed by another [');
      expect(out.contains('thoughtful'), isFalse,
          reason: 'known voice tag body must never reach the UI');
      expect(out.endsWith(' end'), isTrue);
    });

    test('uppercase and mixed-case voice tag is stripped', () {
      final s = VoiceTagStreamScrubber();
      expect(s.feed('[WARMTH] hi'), 'hi');
      expect(s.feed('[ThoughtFul] yo'), 'yo');
    });

    test('Cyrillic body inside brackets is NOT stripped', () {
      // Voice-tag whitelist is ASCII-only. Anything Cyrillic must pass
      // through verbatim.
      final s = VoiceTagStreamScrubber();
      expect(s.feed('[тепло] hi'), '[тепло] hi');
      expect(s.flush(), '');
    });

    test('Estonian body with õ inside brackets is NOT stripped', () {
      final s = VoiceTagStreamScrubber();
      expect(s.feed('[õigustus] body'), '[õigustus] body');
    });

    test('emoji inside brackets is preserved verbatim', () {
      final s = VoiceTagStreamScrubber();
      expect(s.feed('[😀warmth] hi'), '[😀warmth] hi');
    });

    test('voice tag followed by punctuation does not eat the punctuation', () {
      // Pattern `\]\s*` only consumes whitespace. Punctuation must survive.
      final s = VoiceTagStreamScrubber();
      expect(s.feed('[warmth].'), '.');
      // Reset for second case
      final s2 = VoiceTagStreamScrubber();
      expect(s2.feed('[warmth],hi'), ',hi');
      final s3 = VoiceTagStreamScrubber();
      expect(s3.feed('[warmth]:line'), ':line');
    });

    test('voice tag followed by tab swallows exactly one tab', () {
      final s = VoiceTagStreamScrubber();
      expect(s.feed('[warmth]\thello'), 'hello');
    });

    test('voice tag followed by two spaces swallows ONLY the first', () {
      final s = VoiceTagStreamScrubber();
      // Pattern `\]\s*` is regex-greedy in voice_service, but the streaming
      // scrubber pins to "one trailing whitespace" by design (see scrubber
      // header comment lines 84-86). Pin that contract.
      expect(s.feed('[warmth]  hi'), ' hi');
    });

    test('voice tag at very end of stream with no trailing char', () {
      // Tag closes at the last char — no whitespace to consume.
      final s = VoiceTagStreamScrubber();
      expect(s.feed('hi [warmth]'), 'hi ');
      expect(s.flush(), '');
    });

    test('legal citation [§ 40] survives across chunk boundary at `[`', () {
      // The `[` arrives in chunk 1, the body in chunk 2. Mirrors the
      // Sulga case template builder where the `§` symbol is emitted
      // mid-stream.
      final s = VoiceTagStreamScrubber();
      expect(s.feed('text '), 'text ');
      expect(s.feed('['), '');
      expect(s.feed('§ 40] continues'), '[§ 40] continues');
    });

    test(
        'streaming-byte-by-byte for mixed pipeline equals one-shot output',
        () {
      const input = 'Привет [warmth] [Article 26] world [thoughtful] tail';
      final oneShot = VoiceTagStreamScrubber();
      final oneShotOut = oneShot.feed(input) + oneShot.flush();

      final byteByByte = VoiceTagStreamScrubber();
      final buf = StringBuffer();
      // Use runes to avoid splitting multi-code-unit chars
      for (final cp in input.runes) {
        buf.write(byteByByte.feed(String.fromCharCode(cp)));
      }
      buf.write(byteByByte.flush());

      expect(buf.toString(), oneShotOut,
          reason:
              'Streaming output MUST equal one-shot output for the same input');
    });

    test('flush is idempotent — calling twice does not duplicate text', () {
      final s = VoiceTagStreamScrubber();
      expect(s.feed('hi [warm'), 'hi ');
      final first = s.flush();
      expect(first, '[warm');
      expect(s.flush(), '',
          reason: 'second flush must be a no-op');
    });

    test('many consecutive whitelisted tags collapse to nothing', () {
      // A model that emits 5 tags in a row (warmth, thoughtful, calm…) must
      // produce zero-length output, not stuck whitespace.
      final s = VoiceTagStreamScrubber();
      expect(
          s.feed('[warmth][thoughtful][calm][serious][gentle]'),
          '');
      expect(s.flush(), '');
    });

    test('every whitelist tag survives "tag, then body, then tag" sequence',
        () {
      // Belt-and-braces over the existing all-tags test: ensure mid-text
      // stripping plus trailing-space consumption holds for every tag.
      const tags = [
        'warmth', 'thoughtful', 'determination', 'sigh', 'reassuring',
        'whispers', 'laughs', 'excitement', 'enthusiasm', 'shouts',
        'sarcastic', 'calm', 'confident', 'empathetic', 'serious',
        'gentle', 'firm', 'curious', 'hopeful', 'concerned',
      ];
      for (final tag in tags) {
        final s = VoiceTagStreamScrubber();
        final out = s.feed('start [$tag] middle [$tag] end');
        expect(out, 'start middle end',
            reason: 'tag $tag failed mid-text stripping');
      }
    });

    test('scrubber output never re-emits previously buffered chars', () {
      // Regression on a hypothetical bug where the buffer is not cleared
      // after a flush. Feed two complete tags in a row across chunks.
      final s = VoiceTagStreamScrubber();
      final a = s.feed('Hi [war');
      final b = s.feed('mth] text [thoughtful]');
      final c = s.feed(' tail');
      expect(a, 'Hi ');
      expect(b, 'text ');
      expect(c, 'tail');
    });
  });
}
