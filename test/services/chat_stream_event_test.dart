@Tags(['fast'])
library;

// =============================================================================
// chat_stream_event_test.dart — sealed-class roundtrip + extension tests.
// =============================================================================
//
// Reasoning Trail v1 (2026-05-05). Pins the typed event surface used by the
// chat streaming pipeline. SSE → event mapping is covered separately in
// claude_service_streaming_event_test.dart (uses canned SSE strings).
// =============================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/chat_stream_event.dart';

void main() {
  group('ChatStreamEvent — sealed class', () {
    test('TextDelta value equality', () {
      expect(const TextDelta('hello'), equals(const TextDelta('hello')));
      expect(const TextDelta('hello'), isNot(equals(const TextDelta('world'))));
    });

    test('ThinkingStart/Stop singletons compare equal', () {
      expect(const ThinkingStart(), equals(const ThinkingStart()));
      expect(const ToolUseStop(), equals(const ToolUseStop()));
    });

    test('ThinkingDelta carries text', () {
      const a = ThinkingDelta('searching the law');
      expect(a.text, 'searching the law');
      expect(a, equals(const ThinkingDelta('searching the law')));
      expect(a, isNot(equals(const ThinkingDelta('different'))));
    });

    test('ThinkingStop preserves signature', () {
      const a = ThinkingStop(signature: 'sig_abc123');
      expect(a.signature, 'sig_abc123');
      expect(a, equals(const ThinkingStop(signature: 'sig_abc123')));
      expect(a, isNot(equals(const ThinkingStop(signature: 'other'))));
      expect(a, isNot(equals(const ThinkingStop())));
    });

    test('ToolUseStart compares by (name, id)', () {
      const a = ToolUseStart('web_search', 'toolu_01');
      expect(a, equals(const ToolUseStart('web_search', 'toolu_01')));
      expect(a, isNot(equals(const ToolUseStart('web_search', 'toolu_02'))));
      expect(a, isNot(equals(const ToolUseStart('check_company', 'toolu_01'))));
    });

    test('ToolInputDelta compares by partialJson', () {
      const a = ToolInputDelta('{"q":"deport');
      expect(a, equals(const ToolInputDelta('{"q":"deport')));
      expect(a, isNot(equals(const ToolInputDelta('{}'))));
    });

    test('ToolResultReceived compares by map content', () {
      final a = ToolResultReceived({'ok': true, 'count': 3});
      final b = ToolResultReceived({'ok': true, 'count': 3});
      final c = ToolResultReceived({'ok': true, 'count': 4});
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('MessageDone carries metadata', () {
      const a = MessageDone(thinkingMs: 4200, sources: 2);
      expect(a.thinkingMs, 4200);
      expect(a.sources, 2);
      expect(a, equals(const MessageDone(thinkingMs: 4200, sources: 2)));
    });

    test('toString previews are debugger-friendly (truncated for long text)', () {
      final long = 'x' * 200;
      expect(TextDelta(long).toString().length, lessThan(60));
      expect(const TextDelta('short').toString(), contains('short'));
      expect(
        const ThinkingStop(signature: 'aaa').toString(),
        contains('<3b>'), // length, not contents — sig is private-ish
      );
    });
  });

  group('toTextStream() backwards-compat shim', () {
    test('filters non-text events out, preserves text', () async {
      final source = Stream<ChatStreamEvent>.fromIterable([
        const ThinkingStart(),
        const ThinkingDelta('thinking…'),
        const TextDelta('Hello '),
        const ToolUseStart('search_estonian_law', 'toolu_x'),
        const TextDelta('world'),
        const ToolUseStop(),
        const MessageDone(thinkingMs: 100, sources: 1),
      ]);

      final out = await source.toTextStream().toList();

      expect(out, ['Hello ', 'world']);
    });

    test('drops empty TextDelta', () async {
      final source = Stream<ChatStreamEvent>.fromIterable([
        const TextDelta(''),
        const TextDelta('a'),
        const TextDelta(''),
        const TextDelta('b'),
      ]);
      final out = await source.toTextStream().toList();
      expect(out, ['a', 'b']);
    });

    test('empty source yields empty stream', () async {
      final source = Stream<ChatStreamEvent>.empty();
      final out = await source.toTextStream().toList();
      expect(out, isEmpty);
    });
  });
}
