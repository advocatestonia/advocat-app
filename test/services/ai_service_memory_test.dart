@Tags(['fast'])
library;

// TDD tests for AIService ↔ UserMemoryService integration (ADR-001 Tier 1).
// -----------------------------------------------------------------------------
// Ref: docs/memory-tier1/integration_patch.md §2-3
//      lib/services/ai_service.dart
//      lib/services/user_memory_service.dart
//
// Covers the two seams the integration patch wires in:
//   §2  fetch memories + format a block BEFORE building the system prompt.
//   §3  kick off extract-memory (fire-and-forget) AFTER streaming completes,
//       but only when we have at least 4 turns in the history.
//
// ClaudeService is not exercised here — the memory seams are pure
// coordination logic we surface via @visibleForTesting helpers on
// AIService, so we can drive them with a fake UserMemoryService without
// hitting the network.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/models/user_memory.dart';
import 'package:advocat/services/ai_service.dart';
import 'package:advocat/services/user_memory_service.dart';

/// Fake UserMemoryService that records every call without touching the network.
class _FakeUserMemoryService implements UserMemoryService {
  _FakeUserMemoryService({
    List<UserMemory> memories = const [],
    this.throwOnFetch = false,
  }) : _memories = memories;

  final List<UserMemory> _memories;
  final bool throwOnFetch;

  int getMemoriesCalls = 0;
  final List<({List<({String role, String content})> messages, String? sessionId})>
      extractCalls = [];

  @override
  Future<List<UserMemory>> getMemories({int limit = 20}) async {
    getMemoriesCalls++;
    if (throwOnFetch) throw StateError('network down');
    return List.unmodifiable(_memories);
  }

  @override
  Future<Map<String, int>?> extractFromSession({
    required List<({String role, String content})> messages,
    String? sessionId,
    String? intake,
  }) async {
    extractCalls.add((messages: messages, sessionId: sessionId));
    return {'extracted': 1, 'stored': 1, 'duplicates': 0};
  }

  @override
  Future<void> forget(String memoryId) async {}

  @override
  Future<void> forgetAll() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

UserMemory _memory({
  required String id,
  required String key,
  required String text,
  double confidence = 0.9,
}) {
  final now = DateTime.utc(2026, 4, 23);
  return UserMemory(
    id: id,
    key: key,
    text: text,
    confidence: confidence,
    createdAt: now,
    lastReinforcedAt: now,
  );
}

void main() {
  group('AIService.fetchMemoryBlockForTest', () {
    test('returns empty string when no memoryService is configured', () async {
      final svc = AIService(); // no memoryService injected
      final block = await svc.fetchMemoryBlockForTest();
      expect(block, isEmpty);
    });

    test('returns formatted block when memories are present', () async {
      final fake = _FakeUserMemoryService(memories: [
        _memory(id: '1', key: 'tone', text: 'You prefer short replies'),
        _memory(
          id: '2',
          key: 'people',
          text: 'Your wife is Sofia',
          confidence: 0.85,
        ),
      ]);
      final svc = AIService(memoryService: fake);

      final block = await svc.fetchMemoryBlockForTest();

      expect(fake.getMemoriesCalls, 1);
      expect(block, contains('=== WHAT WE KNOW ABOUT YOU ==='));
      expect(block, contains('You prefer short replies'));
      expect(block, contains('Your wife is Sofia'));
    });

    test('returns empty string (no crash) when getMemories throws', () async {
      final fake = _FakeUserMemoryService(throwOnFetch: true);
      final svc = AIService(memoryService: fake);

      // Must degrade gracefully — chat must never fail because memory
      // fetching failed.
      final block = await svc.fetchMemoryBlockForTest();
      expect(block, isEmpty);
    });

    test('returns empty when service yields zero memories', () async {
      final fake = _FakeUserMemoryService(memories: const []);
      final svc = AIService(memoryService: fake);

      final block = await svc.fetchMemoryBlockForTest();
      expect(block, isEmpty);
      expect(fake.getMemoriesCalls, 1);
    });
  });

  group('AIService.triggerMemoryExtractionForTest', () {
    test('calls extractFromSession when at least 4 messages are present',
        () async {
      final fake = _FakeUserMemoryService();
      final svc = AIService(memoryService: fake);

      final messages = <({String role, String content})>[
        (role: 'user', content: 'Hi'),
        (role: 'assistant', content: 'Hello'),
        (role: 'user', content: 'What is HMS §40?'),
        (role: 'assistant', content: 'HMS §40 says...'),
      ];

      await svc.triggerMemoryExtractionForTest(
        sessionId: 'case-123',
        messages: messages,
      );

      expect(fake.extractCalls, hasLength(1));
      expect(fake.extractCalls.first.sessionId, 'case-123');
      expect(fake.extractCalls.first.messages, hasLength(4));
      expect(fake.extractCalls.first.messages.first.role, 'user');
    });

    test('skips extraction when message count is below 4', () async {
      final fake = _FakeUserMemoryService();
      final svc = AIService(memoryService: fake);

      final messages = <({String role, String content})>[
        (role: 'user', content: 'Hi'),
        (role: 'assistant', content: 'Hello'),
      ];

      await svc.triggerMemoryExtractionForTest(
        sessionId: 'case-1',
        messages: messages,
      );

      expect(fake.extractCalls, isEmpty);
    });

    test('is a safe no-op when memoryService is null', () async {
      final svc = AIService(); // no memoryService
      // Must not throw.
      await svc.triggerMemoryExtractionForTest(
        sessionId: 'case-1',
        messages: const [
          (role: 'user', content: 'a'),
          (role: 'assistant', content: 'b'),
          (role: 'user', content: 'c'),
          (role: 'assistant', content: 'd'),
        ],
      );
    });
  });
}
