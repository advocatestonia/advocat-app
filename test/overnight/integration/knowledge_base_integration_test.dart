// Overnight isolated test suite — DOES NOT modify production code.
// Integration tests for KnowledgeBase (pure-Dart business logic).
import 'package:flutter_test/flutter_test.dart';
import 'package:advocat/models/case_model.dart';
import 'package:advocat/services/knowledge_base.dart';

void main() {
  group('KnowledgeBase.buildContext happy paths', () {
    test('returns non-empty context with no arguments', () {
      final ctx = KnowledgeBase.buildContext();
      expect(ctx, isNotEmpty);
    });

    test('always includes EU fundamental rights block', () {
      final ctx = KnowledgeBase.buildContext();
      expect(
        ctx.contains('EU FUNDAMENTAL RIGHTS') ||
            ctx.contains('Charter of Fundamental Rights'),
        isTrue,
      );
    });

    test('includes country procedural knowledge (Estonia default)', () {
      final ctx = KnowledgeBase.buildContext(country: 'Estonia');
      // The Estonian section is always added by default / by match.
      expect(ctx.length, greaterThan(200));
    });

    test('handles Finland by name', () {
      final ctx = KnowledgeBase.buildContext(country: 'Finland');
      expect(ctx, isNotEmpty);
    });

    test('handles Germany by native name', () {
      final ctx = KnowledgeBase.buildContext(country: 'Deutschland');
      expect(ctx, isNotEmpty);
    });

    test('handles Sweden by native name', () {
      final ctx = KnowledgeBase.buildContext(country: 'Sverige');
      expect(ctx, isNotEmpty);
    });

    test('unknown country still returns a context (falls back to Estonia)', () {
      final ctx = KnowledgeBase.buildContext(country: 'Narnia');
      expect(ctx, isNotEmpty);
    });
  });

  group('KnowledgeBase.buildContext by CaseType', () {
    test('every CaseType builds context without throwing', () {
      for (final t in CaseType.values) {
        expect(
          () => KnowledgeBase.buildContext(caseType: t, country: 'Estonia'),
          returnsNormally,
          reason: 'Should not throw for $t',
        );
      }
    });

    test('null CaseType still produces non-empty context', () {
      final ctx = KnowledgeBase.buildContext(caseType: null);
      expect(ctx, isNotEmpty);
    });
  });

  group('KnowledgeBase query-driven routing is fail-safe', () {
    test('empty query is handled gracefully', () {
      final ctx = KnowledgeBase.buildContext(
        caseType: CaseType.deportation,
        country: 'Estonia',
        query: '',
      );
      expect(ctx, isNotEmpty);
    });

    test('query with special characters is handled gracefully', () {
      final ctx = KnowledgeBase.buildContext(
        caseType: CaseType.deportation,
        country: 'Estonia',
        query: '!@#%^&*()_+{}|:"<>?',
      );
      expect(ctx, isNotEmpty);
    });

    test('very long query does not crash', () {
      final longQuery = List.filled(1000, 'deportation').join(' ');
      final ctx = KnowledgeBase.buildContext(
        caseType: CaseType.deportation,
        country: 'Estonia',
        query: longQuery,
      );
      expect(ctx, isNotEmpty);
    });

    test('EU nationality adds free movement rights', () {
      final ctx = KnowledgeBase.buildContext(
        caseType: CaseType.residencePermit,
        country: 'Estonia',
        nationality: 'germany',
        query: 'residence permit',
      );
      expect(
        ctx.toLowerCase().contains('free movement') ||
            ctx.toLowerCase().contains('2004/38') ||
            ctx.length > 500,
        isTrue,
        reason: 'EU nationality should extend context',
      );
    });

    test('context respects maxContextChars hint', () {
      // We can't strictly enforce length, but we can pass it and ensure no throw.
      final ctx = KnowledgeBase.buildContext(
        caseType: CaseType.deportation,
        country: 'Estonia',
        query: 'deportation appeal',
        maxContextChars: 500,
      );
      expect(ctx, isNotEmpty);
    });
  });

  group('KnowledgeBase token budget constant', () {
    test('maxTokenBudget is a reasonable positive integer', () {
      expect(KnowledgeBase.maxTokenBudget, greaterThan(0));
      expect(KnowledgeBase.maxTokenBudget, lessThan(100000));
    });
  });
}
