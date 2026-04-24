@Tags(['fast'])
library;

// Overnight isolated test suite — DOES NOT modify production code.
// Edge-case coverage for LegalCase / CaseType / CaseStatus.
import 'package:flutter_test/flutter_test.dart';
import 'package:advocat/models/case_model.dart';

void main() {
  group('LegalCase overnight edge cases', () {
    test('all CaseType enum values have stable string round-trip', () {
      for (final t in CaseType.values) {
        final c = LegalCase(
          id: 'c1',
          userId: 'u1',
          title: 'T',
          type: t,
          createdAt: DateTime.utc(2024, 1, 1),
        );
        final decoded = LegalCase.fromJson(c.toJson());
        expect(decoded.type, t, reason: 'round-trip fails for $t');
      }
    });

    test('all CaseStatus enum values have stable string round-trip', () {
      for (final s in CaseStatus.values) {
        final c = LegalCase(
          id: 'c1',
          userId: 'u1',
          title: 'T',
          status: s,
          createdAt: DateTime.utc(2024, 1, 1),
        );
        final decoded = LegalCase.fromJson(c.toJson());
        expect(decoded.status, s, reason: 'round-trip fails for $s');
      }
    });

    test('unknown type/status in JSON falls back to deportation/active', () {
      final c = LegalCase.fromJson({
        'id': 'c1',
        'user_id': 'u1',
        'title': 'Case',
        'type': 'not_a_real_type',
        'status': 'definitely_not_a_status',
        'created_at': '2024-01-01T00:00:00.000Z',
      });
      expect(c.type, CaseType.deportation);
      expect(c.status, CaseStatus.active);
    });

    test('document_count/unread_messages default to 0 when missing', () {
      final c = LegalCase.fromJson({
        'id': 'c1',
        'user_id': 'u1',
        'title': 'Case',
        'created_at': '2024-01-01T00:00:00.000Z',
      });
      expect(c.documentCount, 0);
      expect(c.unreadMessages, 0);
    });

    test('appealDeadline/hearingDate preserved on round-trip', () {
      final appeal = DateTime.utc(2025, 5, 10);
      final hearing = DateTime.utc(2025, 6, 20, 9, 30);
      final a = LegalCase(
        id: 'c1',
        userId: 'u1',
        title: 'T',
        appealDeadline: appeal,
        hearingDate: hearing,
        createdAt: DateTime.utc(2024, 1, 1),
      );
      final b = LegalCase.fromJson(a.toJson());
      expect(b.appealDeadline, appeal);
      expect(b.hearingDate, hearing);
    });

    test('copyWith preserves unset fields', () {
      final a = LegalCase(
        id: 'c1',
        userId: 'u1',
        title: 'Original',
        type: CaseType.asylum,
        status: CaseStatus.pendingDecision,
        createdAt: DateTime.utc(2024, 1, 1),
      );
      final b = a.copyWith(title: 'Updated');
      expect(b.title, 'Updated');
      expect(b.type, a.type);
      expect(b.status, a.status);
      expect(b.id, a.id);
    });

    test('fromJson requires user_id (throws TypeError on null)', () {
      expect(
        () => LegalCase.fromJson({
          'id': 'c1',
          'title': 'x',
          'created_at': '2024-01-01T00:00:00.000Z',
        }),
        throwsA(isA<TypeError>()),
      );
    });

    test('CaseType.values length matches expected coverage (16)', () {
      expect(CaseType.values.length, 16);
    });

    test('CaseStatus.values length matches expected coverage (6)', () {
      expect(CaseStatus.values.length, 6);
    });
  });
}
