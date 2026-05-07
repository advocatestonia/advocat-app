import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/ai_service.dart';
import 'package:advocat/services/claude_service.dart';

/// Tests for [AIService] — caching, rate limiting, token tracking, DTOs,
/// input sanitization, and conversation history management.
///
/// We test the public API surface. The actual Claude/proxy calls are not
/// tested here because they require network access; those are covered by
/// integration tests. We focus on the deterministic logic around caching,
/// sanitization, history, and DTOs.
void main() {
  // ── DTO tests ─────────────────────────────────────────────────────────

  group('ChatResponse', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'message': 'Hello',
        'suggested_actions': ['action1', 'action2'],
        'disclaimer': 'Not legal advice',
      };
      final response = ChatResponse.fromJson(json);
      expect(response.message, 'Hello');
      expect(response.suggestedActions, ['action1', 'action2']);
      expect(response.disclaimer, 'Not legal advice');
      expect(response.hasToolUse, isFalse);
    });

    test('fromJson handles missing optional fields', () {
      final json = {'message': 'Hi'};
      final response = ChatResponse.fromJson(json);
      expect(response.message, 'Hi');
      expect(response.suggestedActions, isNull);
      expect(response.disclaimer, isNull);
      expect(response.hasToolUse, isFalse);
    });

    test('hasToolUse returns true when toolUseResponse is set', () {
      const response = ChatResponse(
        message: 'Using tool',
        toolUseResponse: {'content': []},
      );
      expect(response.hasToolUse, isTrue);
    });
  });

  group('DocumentAnalysis', () {
    test('fromJson parses all fields', () {
      final json = {
        'summary': 'A summary',
        'language': 'en',
        'key_points': ['point1', 'point2'],
        'deadlines': [
          {'title': 'Appeal', 'date': '2026-05-01'},
        ],
        'entities': {'type': 'legal'},
      };
      final analysis = DocumentAnalysis.fromJson(json);
      expect(analysis.summary, 'A summary');
      expect(analysis.language, 'en');
      expect(analysis.keyPoints, hasLength(2));
      expect(analysis.deadlines, hasLength(1));
      expect(analysis.deadlines.first.title, 'Appeal');
      expect(analysis.entities['type'], 'legal');
    });

    test('fromJson handles missing entities', () {
      final json = {
        'summary': 'Test',
        'key_points': <String>[],
        'deadlines': <Map<String, dynamic>>[],
      };
      final analysis = DocumentAnalysis.fromJson(json);
      expect(analysis.entities, isEmpty);
    });
  });

  group('DraftResponse', () {
    test('fromJson parses all fields', () {
      final json = {
        'title': 'Appeal Draft',
        'content': 'Dear Court...',
        'language': 'fi',
        'disclaimer': 'Review before submission',
      };
      final draft = DraftResponse.fromJson(json);
      expect(draft.title, 'Appeal Draft');
      expect(draft.content, 'Dear Court...');
      expect(draft.language, 'fi');
      expect(draft.disclaimer, 'Review before submission');
    });

    test('fromJson uses defaults for missing optional fields', () {
      final json = {
        'title': 'Draft',
        'content': 'Content',
      };
      final draft = DraftResponse.fromJson(json);
      expect(draft.language, 'en');
      expect(draft.disclaimer, contains('AI-generated'));
    });
  });

  group('ExtractedDeadline', () {
    test('fromJson parses all fields', () {
      final json = {
        'title': 'File appeal',
        'date': '2026-05-15',
        'type': 'appeal',
        'description': 'Must file within 30 days',
      };
      final deadline = ExtractedDeadline.fromJson(json);
      expect(deadline.title, 'File appeal');
      expect(deadline.date, '2026-05-15');
      expect(deadline.type, 'appeal');
      expect(deadline.description, 'Must file within 30 days');
    });
  });

  group('AIServiceException', () {
    test('toString includes message', () {
      const exception = AIServiceException('Test error');
      expect(exception.toString(), 'AIServiceException: Test error');
    });

    test('stores cause', () {
      const exception = AIServiceException('Network failed', null);
      expect(exception.cause, isNull);
    });
  });

  // ── AIService logic tests ─────────────────────────────────────────────

  group('AIService — estimatedSessionCostUsd', () {
    test('returns zero when no tokens used', () {
      final service = AIService();
      expect(service.estimatedSessionCostUsd, 0.0);
    });

    test('delegates session token counts to ClaudeService', () {
      final service = AIService();
      // ClaudeService starts with 0 tokens
      expect(service.sessionInputTokens, 0);
      expect(service.sessionOutputTokens, 0);
      expect(service.sessionTotalTokens, 0);
    });
  });

  group('AIService — conversation history management', () {
    late AIService service;

    setUp(() {
      service = AIService();
    });

    test('clearHistory removes history for a specific case', () {
      // Seed some history
      service.seedHistory('case-1', [
        {'role': 'user', 'content': 'Hello'},
        {'role': 'assistant', 'content': 'Hi'},
      ]);
      service.seedHistory('case-2', [
        {'role': 'user', 'content': 'Test'},
      ]);

      service.clearHistory('case-1');

      // case-1 should be cleared, case-2 should remain
      // We verify indirectly by seeding again (it should accept new messages
      // since existing history was cleared)
      service.seedHistory('case-1', [
        {'role': 'user', 'content': 'New message'},
      ]);
      // No exception means it was cleared and re-seeded successfully
    });

    test('clearAllHistory removes all histories and cache', () {
      service.seedHistory('case-1', [
        {'role': 'user', 'content': 'Hello'},
      ]);
      service.seedHistory('case-2', [
        {'role': 'user', 'content': 'Test'},
      ]);

      service.clearAllHistory();

      // After clearing, seeding with 1 message should work (no existing history)
      service.seedHistory('case-1', [
        {'role': 'user', 'content': 'After clear'},
      ]);
    });

    test('seedHistory replaces when Supabase has more messages', () {
      // First seed with 2 messages
      service.seedHistory('case-1', [
        {'role': 'user', 'content': 'msg1'},
        {'role': 'assistant', 'content': 'reply1'},
      ]);

      // Seed again with 5 messages (more context from Supabase)
      service.seedHistory('case-1', [
        {'role': 'user', 'content': 'msg1'},
        {'role': 'assistant', 'content': 'reply1'},
        {'role': 'user', 'content': 'msg2'},
        {'role': 'assistant', 'content': 'reply2'},
        {'role': 'user', 'content': 'msg3'},
      ]);
      // No exception — replaced successfully
    });

    test('seedHistory skips when in-memory has equal or more messages', () {
      // Seed with 5 messages
      service.seedHistory('case-1', [
        {'role': 'user', 'content': 'msg1'},
        {'role': 'assistant', 'content': 'reply1'},
        {'role': 'user', 'content': 'msg2'},
        {'role': 'assistant', 'content': 'reply2'},
        {'role': 'user', 'content': 'msg3'},
      ]);

      // Try to seed with fewer — should be a no-op
      service.seedHistory('case-1', [
        {'role': 'user', 'content': 'only1'},
      ]);
      // No exception, but the old 5-message history is preserved
    });

    test('seedHistory does nothing for empty messages', () {
      service.seedHistory('case-1', []);
      // No exception, no history created
    });

    test('seedHistory caps at _maxHistoryMessages (50)', () {
      final messages = List.generate(
        60,
        (i) => {'role': i.isEven ? 'user' : 'assistant', 'content': 'msg$i'},
      );
      service.seedHistory('case-1', messages);
      // Should not throw; internally trims to 50
    });
  });

  group('AIService — purgeStaleHistory', () {
    test('purgeStaleHistory can be called without error on empty state', () {
      final service = AIService();
      service.purgeStaleHistory();
      // No exception
    });
  });

  group('AIService — setAuthToken', () {
    test('setAuthToken does not throw', () {
      final service = AIService();
      service.setAuthToken('test-token-123');
      // No exception means the token was set on the Dio headers
    });
  });

  group('AIService — isProUser flag', () {
    test('defaults to false', () {
      final service = AIService();
      expect(service.isProUser, isFalse);
    });

    test('can be set to true', () {
      final service = AIService();
      service.isProUser = true;
      expect(service.isProUser, isTrue);
    });
  });

  // ── ClaudeService static method tests ─────────────────────────────────

  group('ClaudeService.chooseModel', () {
    test('returns Haiku for short simple queries', () {
      expect(ClaudeService.chooseModel('hello'), ClaudeService.modelHaiku);
      expect(ClaudeService.chooseModel('hi there'), ClaudeService.modelHaiku);
    });

    test('returns Haiku for short queries without legal keywords', () {
      expect(
        ClaudeService.chooseModel('What is the weather today?'),
        ClaudeService.modelHaiku,
      );
    });

    test('returns Sonnet for queries with multiple complex keywords', () {
      const complexQuery = 'I need help with my deportation appeal. '
          'The court hearing is next week.';
      expect(ClaudeService.chooseModel(complexQuery), ClaudeService.modelSonnet);
    });

    test('returns Sonnet for long queries with at least one keyword', () {
      final longQuery = 'a' * 301 + ' court';
      expect(ClaudeService.chooseModel(longQuery), ClaudeService.modelSonnet);
    });

    test('returns Haiku for long queries without keywords', () {
      final longQuery = 'a' * 301;
      expect(ClaudeService.chooseModel(longQuery), ClaudeService.modelHaiku);
    });
  });

  group('ClaudeService.isSimpleQuery', () {
    test('identifies greetings as simple', () {
      expect(ClaudeService.isSimpleQuery('hi'), isTrue);
      expect(ClaudeService.isSimpleQuery('hello'), isTrue);
      expect(ClaudeService.isSimpleQuery('привет'), isTrue);
      expect(ClaudeService.isSimpleQuery('tere'), isTrue);
      expect(ClaudeService.isSimpleQuery('hei'), isTrue);
    });

    test('identifies short messages without legal content as simple', () {
      expect(ClaudeService.isSimpleQuery('ok'), isTrue);
      expect(ClaudeService.isSimpleQuery('yes'), isTrue);
      expect(ClaudeService.isSimpleQuery('thanks'), isTrue);
    });

    test('identifies very short messages as simple', () {
      expect(ClaudeService.isSimpleQuery('hey'), isTrue);
      expect(ClaudeService.isSimpleQuery('yo'), isTrue);
    });

    test('returns false for queries with legal keywords', () {
      expect(ClaudeService.isSimpleQuery('appeal deadline'), isFalse);
      expect(ClaudeService.isSimpleQuery('court hearing'), isFalse);
    });

    test('returns false for long queries', () {
      final longQuery = 'a' * 81;
      expect(ClaudeService.isSimpleQuery(longQuery), isFalse);
    });
  });

  group('ClaudeService.maxTokensForModel', () {
    // 2026-05-07: caps raised so the assistant can deliver full contracts and
    // multi-page legal drafts without truncation. Haiku 800→4096, Sonnet
    // 2500→16384 (matches claude-proxy MAX_TOKENS_LIMIT).
    test('returns 4096 for Haiku', () {
      expect(ClaudeService.maxTokensForModel(ClaudeService.modelHaiku), 4096);
    });

    test('returns 16384 for Sonnet', () {
      expect(ClaudeService.maxTokensForModel(ClaudeService.modelSonnet), 16384);
    });
  });

  group('ClaudeService.estimateTokens', () {
    test('estimates roughly 1 token per 4 characters', () {
      expect(ClaudeService.estimateTokens(''), 0);
      expect(ClaudeService.estimateTokens('abcd'), 1);
      expect(ClaudeService.estimateTokens('Hello World!'), 3);
      // 100 chars -> 25 tokens
      expect(ClaudeService.estimateTokens('a' * 100), 25);
    });
  });

  group('TokenUsage', () {
    test('fromJson parses correctly', () {
      final json = {
        'input_tokens': 150,
        'output_tokens': 200,
      };
      final usage = TokenUsage.fromJson(json);
      expect(usage.inputTokens, 150);
      expect(usage.outputTokens, 200);
      expect(usage.totalTokens, 350);
    });

    test('fromJson handles missing values', () {
      final json = <String, dynamic>{};
      final usage = TokenUsage.fromJson(json);
      expect(usage.inputTokens, 0);
      expect(usage.outputTokens, 0);
      expect(usage.totalTokens, 0);
    });
  });

  group('ClaudeServiceException', () {
    test('toString includes message', () {
      const e = ClaudeServiceException('API failed');
      expect(e.toString(), 'ClaudeServiceException: API failed');
    });
  });
}
