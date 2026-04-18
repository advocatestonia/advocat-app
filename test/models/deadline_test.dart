import 'package:advocat/models/deadline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

void main() {
  group('Deadline', () {
    // ── fromJson ──────────────────────────────────────────────────────────

    group('fromJson', () {
      test('parses a complete JSON map', () {
        final json = makeDeadlineJson(
          id: 'dl-1',
          caseId: 'c-1',
          userId: 'u-1',
          title: 'File appeal',
          description: 'Must file within 30 days',
          dueDate: fixtureFuture.toIso8601String(),
          type: 'hearing',
          priority: 'critical',
          status: 'overdue',
          notificationScheduled: true,
          reminderDaysBefore: 14,
          source: 'ai_extracted',
          sourceDocumentId: 'doc-123',
          createdAt: fixtureNow.toIso8601String(),
          updatedAt: fixtureNow.toIso8601String(),
        );

        final dl = Deadline.fromJson(json);

        expect(dl.id, 'dl-1');
        expect(dl.caseId, 'c-1');
        expect(dl.userId, 'u-1');
        expect(dl.title, 'File appeal');
        expect(dl.description, 'Must file within 30 days');
        expect(dl.dueDate, fixtureFuture);
        expect(dl.type, DeadlineType.hearing);
        expect(dl.priority, DeadlinePriority.critical);
        expect(dl.status, DeadlineStatus.overdue);
        expect(dl.notificationScheduled, isTrue);
        expect(dl.reminderDaysBefore, 14);
        expect(dl.source, DeadlineSource.aiExtracted);
        expect(dl.sourceDocumentId, 'doc-123');
        expect(dl.createdAt, fixtureNow);
        expect(dl.updatedAt, fixtureNow);
      });

      test('applies defaults for missing optional fields', () {
        final json = {
          'id': 'dl-2',
          'case_id': 'c-2',
          'user_id': 'u-2',
          'title': 'Minimal deadline',
          'due_date': fixtureFuture.toIso8601String(),
          'created_at': fixtureNow.toIso8601String(),
        };

        final dl = Deadline.fromJson(json);

        expect(dl.description, isNull);
        expect(dl.type, DeadlineType.appeal);
        expect(dl.priority, DeadlinePriority.high);
        expect(dl.status, DeadlineStatus.upcoming);
        expect(dl.notificationScheduled, isFalse);
        expect(dl.reminderDaysBefore, 7);
        expect(dl.source, DeadlineSource.manual);
        expect(dl.sourceDocumentId, isNull);
        expect(dl.updatedAt, isNull);
      });

      test('maps unknown type to appeal', () {
        final json = makeDeadlineJson(type: 'unknown');
        expect(Deadline.fromJson(json).type, DeadlineType.appeal);
      });

      test('maps unknown priority to high', () {
        final json = makeDeadlineJson(priority: 'unknown');
        expect(Deadline.fromJson(json).priority, DeadlinePriority.high);
      });

      test('maps unknown status to upcoming', () {
        final json = makeDeadlineJson(status: 'unknown');
        expect(Deadline.fromJson(json).status, DeadlineStatus.upcoming);
      });

      test('maps unknown source to manual', () {
        final json = makeDeadlineJson(source: 'unknown');
        expect(Deadline.fromJson(json).source, DeadlineSource.manual);
      });
    });

    // ── toJson ────────────────────────────────────────────────────────────

    group('toJson', () {
      test('serialises all fields', () {
        final dl = makeDeadline(
          id: 'dl-1',
          title: 'Court hearing',
          description: 'Room 5',
          type: DeadlineType.courtDate,
          priority: DeadlinePriority.critical,
          status: DeadlineStatus.completed,
          notificationScheduled: true,
          reminderDaysBefore: 3,
          source: DeadlineSource.emailExtracted,
          sourceDocumentId: 'doc-99',
        );

        final json = dl.toJson();

        expect(json['id'], 'dl-1');
        expect(json['title'], 'Court hearing');
        expect(json['description'], 'Room 5');
        expect(json['type'], 'court_date');
        expect(json['priority'], 'critical');
        expect(json['status'], 'completed');
        expect(json['notification_scheduled'], isTrue);
        expect(json['reminder_days_before'], 3);
        expect(json['source'], 'email_extracted');
        expect(json['source_document_id'], 'doc-99');
      });
    });

    // ── Round-trip ────────────────────────────────────────────────────────

    test('round-trip: fromJson(toJson(dl)) preserves data', () {
      final original = makeDeadline(
        id: 'rt-dl',
        type: DeadlineType.permitExpiry,
        priority: DeadlinePriority.low,
        status: DeadlineStatus.cancelled,
        source: DeadlineSource.aiExtracted,
      );

      final restored = Deadline.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.type, original.type);
      expect(restored.priority, original.priority);
      expect(restored.status, original.status);
      expect(restored.source, original.source);
    });

    // ── copyWith ──────────────────────────────────────────────────────────

    group('copyWith', () {
      test('changes specified fields', () {
        final dl = makeDeadline(status: DeadlineStatus.upcoming);
        final copy = dl.copyWith(
          status: DeadlineStatus.overdue,
          priority: DeadlinePriority.critical,
        );

        expect(copy.status, DeadlineStatus.overdue);
        expect(copy.priority, DeadlinePriority.critical);
        expect(copy.id, dl.id);
        expect(copy.title, dl.title);
      });

      test('copies with no changes', () {
        final dl = makeDeadline();
        final copy = dl.copyWith();
        expect(copy.id, dl.id);
        expect(copy.title, dl.title);
      });
    });

    // ── DeadlineType enum ────────────────────────────────────────────────

    group('DeadlineType enum', () {
      test('has 7 values', () {
        expect(DeadlineType.values.length, 7);
      });

      test('all values survive JSON round-trip', () {
        for (final t in DeadlineType.values) {
          final dl = makeDeadline(type: t);
          final restored = Deadline.fromJson(dl.toJson());
          expect(restored.type, t, reason: '${t.name} should round-trip');
        }
      });

      test('JSON string values', () {
        final expected = {
          DeadlineType.appeal: 'appeal',
          DeadlineType.hearing: 'hearing',
          DeadlineType.documentSubmission: 'document_submission',
          DeadlineType.responseRequired: 'response_required',
          DeadlineType.permitExpiry: 'permit_expiry',
          DeadlineType.courtDate: 'court_date',
          DeadlineType.other: 'other',
        };

        for (final entry in expected.entries) {
          final dl = makeDeadline(type: entry.key);
          expect(dl.toJson()['type'], entry.value);
        }
      });
    });

    // ── DeadlinePriority enum ────────────────────────────────────────────

    group('DeadlinePriority enum', () {
      test('has 4 values', () {
        expect(DeadlinePriority.values.length, 4);
      });

      test('all values survive JSON round-trip', () {
        for (final p in DeadlinePriority.values) {
          final dl = makeDeadline(priority: p);
          final restored = Deadline.fromJson(dl.toJson());
          expect(restored.priority, p, reason: '${p.name} should round-trip');
        }
      });
    });

    // ── DeadlineStatus enum ──────────────────────────────────────────────

    group('DeadlineStatus enum', () {
      test('has 4 values', () {
        expect(DeadlineStatus.values.length, 4);
      });

      test('all values survive JSON round-trip', () {
        for (final s in DeadlineStatus.values) {
          final dl = makeDeadline(status: s);
          final restored = Deadline.fromJson(dl.toJson());
          expect(restored.status, s, reason: '${s.name} should round-trip');
        }
      });
    });

    // ── DeadlineSource enum ──────────────────────────────────────────────

    group('DeadlineSource enum', () {
      test('has 3 values', () {
        expect(DeadlineSource.values.length, 3);
      });

      test('all values survive JSON round-trip', () {
        for (final src in DeadlineSource.values) {
          final dl = makeDeadline(source: src);
          final restored = Deadline.fromJson(dl.toJson());
          expect(restored.source, src, reason: '${src.name} should round-trip');
        }
      });

      test('JSON string values', () {
        final expected = {
          DeadlineSource.manual: 'manual',
          DeadlineSource.aiExtracted: 'ai_extracted',
          DeadlineSource.emailExtracted: 'email_extracted',
        };

        for (final entry in expected.entries) {
          final dl = makeDeadline(source: entry.key);
          expect(dl.toJson()['source'], entry.value);
        }
      });
    });
  });
}
