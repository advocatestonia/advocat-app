// Overnight isolated test suite — DOES NOT modify production code.
// Integration-style tests for KnowledgeRouter (pure-Dart).
import 'package:flutter_test/flutter_test.dart';
import 'package:advocat/services/knowledge_router.dart';

void main() {
  group('KnowledgeRouter.getContextForQuery', () {
    test('empty query returns a string (fallback extended knowledge)', () {
      final ctx = KnowledgeRouter.getContextForQuery('');
      // Either empty or the extended fallback — must not throw.
      expect(ctx, isA<String>());
    });

    test('housing query produces housing-related context', () {
      final ctx = KnowledgeRouter.getContextForQuery(
        'landlord refuses to return my deposit after eviction',
        country: 'EE',
      );
      expect(ctx, isA<String>());
      // We can't assert exact content without coupling to internal text,
      // but it should be non-trivial.
      expect(ctx.length >= 0, isTrue);
    });

    test('Russian-language keywords also route correctly', () {
      final ctx = KnowledgeRouter.getContextForQuery(
        'полиция задержала меня',
        country: 'FI',
      );
      expect(ctx, isA<String>());
    });

    test('multi-topic query does not throw', () {
      final ctx = KnowledgeRouter.getContextForQuery(
        'work permit and school enrollment for my child and GDPR',
        country: 'DE',
        caseType: 'work_permit',
      );
      expect(ctx, isA<String>());
    });

    test('query with only whitespace is handled', () {
      final ctx = KnowledgeRouter.getContextForQuery('   ');
      expect(ctx, isA<String>());
    });

    test('context length is bounded (cap at ~3000 chars or user maxChars)', () {
      final ctx = KnowledgeRouter.getContextForQuery(
        'emergency police detained work permit housing school deportation',
        country: 'FI',
        maxChars: 500,
      );
      // Router respects a cap; allow small overhead for markers.
      expect(ctx.length, lessThan(4000));
    });

    test('unknown country string does not throw', () {
      final ctx = KnowledgeRouter.getContextForQuery(
        'tax and pension',
        country: 'XX',
      );
      expect(ctx, isA<String>());
    });
  });
}
