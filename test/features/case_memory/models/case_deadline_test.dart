// Pure-Dart unit tests for the CaseDeadline model: enum mapping,
// urgency band, daysUntil, fromActiveRow vs fromCaseRow.

import 'package:advocat/features/case_memory/models/case_deadline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CaseDeadline.fromActiveRow', () {
    test('maps the active_deadlines RPC projection correctly', () {
      final row = {
        'id': 'd-1',
        'case_id': 'c-1',
        'case_title': 'Sulga FI',
        'title': 'Appeal',
        'statute_basis': 'HOL §164',
        'anchor_key': 'fi_hol_2019_808_khoa',
        'deadline_at': '2026-06-05T16:00:00Z',
        'priority': 'critical',
        'delta_days': 3,
        'holiday_shifted': true,
        'holiday_shift_note': 'moved from Sat 2026-06-04 → Mon 2026-06-06',
        'source': 'pdf',
      };
      final d = CaseDeadline.fromActiveRow(row);
      expect(d.id, 'd-1');
      expect(d.caseTitle, 'Sulga FI');
      expect(d.statuteBasis, 'HOL §164');
      expect(d.priority, CaseDeadlinePriority.critical);
      expect(d.deltaDaysOverride, 3);
      expect(d.holidayShifted, isTrue);
      expect(d.holidayShiftNote, contains('Sat 2026-06-04'));
      expect(d.source, CaseDeadlineSource.pdf);
      expect(d.status, CaseDeadlineStatus.active,
          reason: 'active_deadlines is filtered to status=active server-side');
    });

    test('falls back gracefully on unknown enum values', () {
      final d = CaseDeadline.fromActiveRow({
        'id': 'd-2',
        'case_id': 'c-1',
        'title': 't',
        'deadline_at': '2026-06-05T00:00:00Z',
        'priority': 'galaxy_brain', // unknown
        'source': 'space_alien', // unknown
      });
      expect(d.priority, CaseDeadlinePriority.high,
          reason: 'unknown priorities default to high (table default)');
      expect(d.source, CaseDeadlineSource.manual,
          reason: 'unknown sources default to manual');
    });
  });

  group('CaseDeadline.fromCaseRow', () {
    test('parses the full row from case_deadlines_for', () {
      final row = {
        'id': 'd-3',
        'case_id': 'c-1',
        'user_id': 'u-1',
        'title': 'Vaie',
        'description': 'detail',
        'statute_basis': 'HMS §75',
        'anchor_key': 'ee_hms_75_vaie',
        'service_date': '2026-05-01',
        'service_basis': 'HMS §27',
        'deadline_at': '2026-06-05T16:00:00Z',
        'holiday_shifted': false,
        'source': 'intake',
        'status': 'completed',
        'priority': 'high',
        'completed_at': '2026-05-15T08:00:00Z',
        'completed_note': 'filed',
      };
      final d = CaseDeadline.fromCaseRow(row);
      expect(d.title, 'Vaie');
      expect(d.serviceDate?.year, 2026);
      expect(d.serviceDate?.month, 5);
      expect(d.serviceDate?.day, 1);
      expect(d.status, CaseDeadlineStatus.completed);
      expect(d.completedAt, DateTime.utc(2026, 5, 15, 8));
      expect(d.completedNote, 'filed');
    });
  });

  group('daysUntil', () {
    test('uses server override when [now] is null and override present', () {
      final d = CaseDeadline.fromActiveRow({
        'id': '1',
        'case_id': 'c',
        'title': 't',
        'deadline_at': '2099-01-01T00:00:00Z',
        'delta_days': 7,
      });
      expect(d.daysUntil(), 7);
    });

    test('same calendar day → 0 ("today")', () {
      final now = DateTime.utc(2026, 5, 6, 0, 1);
      final at = DateTime.utc(2026, 5, 6, 23, 59);
      final d = CaseDeadline.fromActiveRow({
        'id': '1',
        'case_id': 'c',
        'title': 't',
        'deadline_at': at.toIso8601String(),
      });
      expect(d.daysUntil(now: now), 0,
          reason: 'same calendar day → "today" not "1 day"');
    });

    test('next calendar day → 1 ("tomorrow")', () {
      final now = DateTime.utc(2026, 5, 6, 12);
      final at = DateTime.utc(2026, 5, 7, 9);
      final d = CaseDeadline.fromActiveRow({
        'id': '1',
        'case_id': 'c',
        'title': 't',
        'deadline_at': at.toIso8601String(),
      });
      expect(d.daysUntil(now: now), 1);
    });

    test('negative when overdue', () {
      final now = DateTime.utc(2026, 5, 6, 12);
      final at = now.subtract(const Duration(days: 2, hours: 1));
      final d = CaseDeadline.fromActiveRow({
        'id': '1',
        'case_id': 'c',
        'title': 't',
        'deadline_at': at.toIso8601String(),
      });
      expect(d.daysUntil(now: now), lessThan(0));
    });
  });

  group('urgency', () {
    test('classifies the four bands', () {
      final now = DateTime.utc(2026, 5, 6, 12);
      CaseDeadline mk(int hours) => CaseDeadline.fromActiveRow({
            'id': '1',
            'case_id': 'c',
            'title': 't',
            'deadline_at': now
                .add(Duration(hours: hours))
                .toIso8601String(),
          });
      expect(mk(20).urgency(now: now), CaseDeadlineUrgency.critical);
      expect(mk(48).urgency(now: now), CaseDeadlineUrgency.high);
      expect(mk(24 * 5).urgency(now: now), CaseDeadlineUrgency.medium);
      expect(mk(24 * 14).urgency(now: now), CaseDeadlineUrgency.info);
    });
  });
}
