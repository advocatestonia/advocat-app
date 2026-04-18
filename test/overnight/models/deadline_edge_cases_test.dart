// Overnight isolated test suite — DOES NOT modify production code.
// Edge-case coverage for Deadline model.
import 'package:flutter_test/flutter_test.dart';
import 'package:advocat/models/deadline.dart';

void main() {
  group('Deadline overnight edge cases', () {
    test('all DeadlineType enum values round-trip', () {
      for (final t in DeadlineType.values) {
        final d = Deadline(
          id: 'd1',
          caseId: 'c1',
          userId: 'u1',
          title: 'T',
          dueDate: DateTime.utc(2024, 5, 1),
          type: t,
          createdAt: DateTime.utc(2024, 1, 1),
        );
        final decoded = Deadline.fromJson(d.toJson());
        expect(decoded.type, t, reason: 'round-trip failed for type=$t');
      }
    });

    test('all DeadlinePriority enum values round-trip', () {
      for (final p in DeadlinePriority.values) {
        final d = Deadline(
          id: 'd1',
          caseId: 'c1',
          userId: 'u1',
          title: 'T',
          dueDate: DateTime.utc(2024, 5, 1),
          priority: p,
          createdAt: DateTime.utc(2024, 1, 1),
        );
        final decoded = Deadline.fromJson(d.toJson());
        expect(decoded.priority, p, reason: 'round-trip failed for priority=$p');
      }
    });

    test('all DeadlineStatus enum values round-trip', () {
      for (final s in DeadlineStatus.values) {
        final d = Deadline(
          id: 'd1',
          caseId: 'c1',
          userId: 'u1',
          title: 'T',
          dueDate: DateTime.utc(2024, 5, 1),
          status: s,
          createdAt: DateTime.utc(2024, 1, 1),
        );
        final decoded = Deadline.fromJson(d.toJson());
        expect(decoded.status, s, reason: 'round-trip failed for status=$s');
      }
    });

    test('all DeadlineSource enum values round-trip', () {
      for (final src in DeadlineSource.values) {
        final d = Deadline(
          id: 'd1',
          caseId: 'c1',
          userId: 'u1',
          title: 'T',
          dueDate: DateTime.utc(2024, 5, 1),
          source: src,
          createdAt: DateTime.utc(2024, 1, 1),
        );
        final decoded = Deadline.fromJson(d.toJson());
        expect(decoded.source, src, reason: 'round-trip failed for source=$src');
      }
    });

    test('unknown strings fall back to documented defaults', () {
      final d = Deadline.fromJson({
        'id': 'd1',
        'case_id': 'c1',
        'user_id': 'u1',
        'title': 'Appeal',
        'due_date': '2024-05-01T00:00:00.000Z',
        'type': 'ghost_type',
        'priority': 'ghost_priority',
        'status': 'ghost_status',
        'source': 'ghost_source',
        'created_at': '2024-01-01T00:00:00.000Z',
      });
      expect(d.type, DeadlineType.appeal);
      expect(d.priority, DeadlinePriority.high);
      expect(d.status, DeadlineStatus.upcoming);
      expect(d.source, DeadlineSource.manual);
    });

    test('reminderDaysBefore default is 7', () {
      final d = Deadline.fromJson({
        'id': 'd1',
        'case_id': 'c1',
        'user_id': 'u1',
        'title': 'Appeal',
        'due_date': '2024-05-01T00:00:00.000Z',
        'created_at': '2024-01-01T00:00:00.000Z',
      });
      expect(d.reminderDaysBefore, 7);
      expect(d.notificationScheduled, false);
    });

    test('copyWith changes a single field only', () {
      final a = Deadline(
        id: 'd1',
        caseId: 'c1',
        userId: 'u1',
        title: 'Original',
        dueDate: DateTime.utc(2024, 5, 1),
        createdAt: DateTime.utc(2024, 1, 1),
      );
      final b = a.copyWith(title: 'Updated');
      expect(b.title, 'Updated');
      expect(b.dueDate, a.dueDate);
      expect(b.id, a.id);
    });

    test('status enum length is 4 (stable contract)', () {
      expect(DeadlineStatus.values.length, 4);
    });

    test('priority enum length is 4 (stable contract)', () {
      expect(DeadlinePriority.values.length, 4);
    });
  });
}
