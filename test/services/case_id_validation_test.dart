@Tags(['fast'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:advocat/services/supabase_service.dart';
import 'package:advocat/services/errors/invalid_case_id_error.dart';

/// Anti-regression tests for Rule 5: caseId='general' (non-UUID synthetic id)
/// must never reach Postgres. The strict UUID regex + [requireUuid] give
/// callers a typed way to fail fast when a genuine UUID is required.
void main() {
  group('caseId validation', () {
    final sb = SupabaseService();

    test('rejects "general"', () {
      expect(sb.isRealUuidForTest('general'), isFalse);
    });
    test('rejects empty', () {
      expect(sb.isRealUuidForTest(''), isFalse);
    });
    test('rejects uuid-looking but not real', () {
      expect(sb.isRealUuidForTest('not-a-uuid-really'), isFalse);
    });
    test('accepts a real UUID v4', () {
      expect(
        sb.isRealUuidForTest('550e8400-e29b-41d4-a716-446655440000'),
        isTrue,
      );
    });
    test('accepts UUID with uppercase', () {
      expect(
        sb.isRealUuidForTest('550E8400-E29B-41D4-A716-446655440000'),
        isTrue,
      );
    });
    test('requireUuid throws InvalidCaseIdError for synthetic', () {
      expect(
        () => sb.requireUuid('general', 'test context'),
        throwsA(isA<InvalidCaseIdError>()),
      );
    });
    test('requireUuid passes for real UUID', () {
      expect(
        () => sb.requireUuid('550e8400-e29b-41d4-a716-446655440000', 'ctx'),
        returnsNormally,
      );
    });
    test('InvalidCaseIdError includes context', () {
      final err = InvalidCaseIdError('general', 'upload');
      expect(err.toString(), contains('upload'));
      expect(err.toString(), contains('general'));
    });
  });
}
