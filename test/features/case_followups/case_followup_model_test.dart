@Tags(['fast'])
library;

// Unit tests for Smart Case Follow-ups (Feature #2) client model.
// -----------------------------------------------------------------------------
// Pure-data tests — no widget pump. Verifies:
//   * CaseFollowup.fromJson wire-format mapping + enum fallbacks.
//   * isOverdue / isDone derived flags.
//   * FollowupSuggestion.fromJson + dueAtFrom offset math.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/case_followups/case_followup_model.dart';

void main() {
  group('CaseFollowup.fromJson', () {
    test('maps a full row', () {
      final f = CaseFollowup.fromJson({
        'id': 'fid',
        'case_id': 'cid',
        'title': 'Send records request',
        'detail': 'Cite JulkL 14§',
        'due_at': '2026-06-20T10:00:00.000Z',
        'status': 'open',
        'source': 'ai',
        'snooze_count': 2,
        'created_at': '2026-06-14T09:00:00.000Z',
      });
      expect(f.id, 'fid');
      expect(f.caseId, 'cid');
      expect(f.title, 'Send records request');
      expect(f.detail, 'Cite JulkL 14§');
      expect(f.status, FollowupStatus.open);
      expect(f.source, FollowupSource.ai);
      expect(f.snoozeCount, 2);
      expect(f.dueAt, isNotNull);
    });

    test('tolerates null optional fields', () {
      final f = CaseFollowup.fromJson({
        'id': 'fid',
        'case_id': 'cid',
        'title': 'Collect receipts',
      });
      expect(f.detail, isNull);
      expect(f.dueAt, isNull);
      expect(f.snoozeCount, 0);
      expect(f.status, FollowupStatus.open);
      expect(f.source, FollowupSource.manual);
    });

    test('unknown status/source fall back to safe defaults', () {
      final f = CaseFollowup.fromJson({
        'id': 'x',
        'case_id': 'c',
        'title': 't',
        'status': 'gibberish',
        'source': 'gibberish',
      });
      expect(f.status, FollowupStatus.open);
      expect(f.source, FollowupSource.manual);
    });

    test('maps done / snoozed / dismissed statuses', () {
      CaseFollowup withStatus(String s) => CaseFollowup.fromJson(
            {'id': 'x', 'case_id': 'c', 'title': 't', 'status': s},
          );
      expect(withStatus('done').status, FollowupStatus.done);
      expect(withStatus('snoozed').status, FollowupStatus.snoozed);
      expect(withStatus('dismissed').status, FollowupStatus.dismissed);
    });
  });

  group('derived flags', () {
    test('isDone reflects status', () {
      final done = CaseFollowup.fromJson(
          {'id': 'x', 'case_id': 'c', 'title': 't', 'status': 'done'});
      expect(done.isDone, isTrue);
    });

    test('isOverdue true for a past due_at on an open task', () {
      final past = DateTime.now()
          .subtract(const Duration(days: 2))
          .toUtc()
          .toIso8601String();
      final f = CaseFollowup.fromJson(
          {'id': 'x', 'case_id': 'c', 'title': 't', 'due_at': past});
      expect(f.isOverdue, isTrue);
    });

    test('isOverdue false for a future due_at', () {
      final future = DateTime.now()
          .add(const Duration(days: 2))
          .toUtc()
          .toIso8601String();
      final f = CaseFollowup.fromJson(
          {'id': 'x', 'case_id': 'c', 'title': 't', 'due_at': future});
      expect(f.isOverdue, isFalse);
    });

    test('isOverdue false when done even if date passed', () {
      final past = DateTime.now()
          .subtract(const Duration(days: 2))
          .toUtc()
          .toIso8601String();
      final f = CaseFollowup.fromJson({
        'id': 'x',
        'case_id': 'c',
        'title': 't',
        'due_at': past,
        'status': 'done',
      });
      expect(f.isOverdue, isFalse);
    });

    test('isOverdue false when no due_at (someday task)', () {
      final f =
          CaseFollowup.fromJson({'id': 'x', 'case_id': 'c', 'title': 't'});
      expect(f.isOverdue, isFalse);
    });
  });

  group('copyWith', () {
    test('flips status and bumps snooze independently', () {
      final base = CaseFollowup.fromJson(
          {'id': 'x', 'case_id': 'c', 'title': 't'});
      final snoozed = base.copyWith(status: FollowupStatus.snoozed, snoozeCount: 1);
      expect(snoozed.status, FollowupStatus.snoozed);
      expect(snoozed.snoozeCount, 1);
      // Original untouched (immutability).
      expect(base.status, FollowupStatus.open);
      expect(base.snoozeCount, 0);
    });
  });

  group('FollowupSuggestion', () {
    test('fromJson maps offset', () {
      final s = FollowupSuggestion.fromJson(
          {'title': 'Call landlord', 'detail': null, 'due_offset_days': 7});
      expect(s.title, 'Call landlord');
      expect(s.detail, isNull);
      expect(s.dueOffsetDays, 7);
    });

    test('dueAtFrom returns null for a zero offset', () {
      final s = const FollowupSuggestion(title: 'x', dueOffsetDays: 0);
      expect(s.dueAtFrom(DateTime(2026, 6, 14)), isNull);
    });

    test('dueAtFrom adds N days for a positive offset', () {
      final s = const FollowupSuggestion(title: 'x', dueOffsetDays: 3);
      expect(s.dueAtFrom(DateTime(2026, 6, 14)), DateTime(2026, 6, 17));
    });

    test('missing due_offset_days defaults to 0 / someday', () {
      final s = FollowupSuggestion.fromJson({'title': 'x'});
      expect(s.dueOffsetDays, 0);
      expect(s.dueAtFrom(DateTime(2026, 6, 14)), isNull);
    });
  });
}
