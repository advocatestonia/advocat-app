import 'package:advocat/shared/utils/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppDateUtils', () {
    // ── formatDate ─────────────────────────────────────────────────────────

    group('formatDate', () {
      test('formats a typical date as dd.MM.yyyy', () {
        final date = DateTime(2026, 4, 15);
        expect(AppDateUtils.formatDate(date), '15.04.2026');
      });

      test('zero-pads single-digit day and month', () {
        final date = DateTime(2025, 1, 5);
        expect(AppDateUtils.formatDate(date), '05.01.2025');
      });

      test('handles last day of year', () {
        final date = DateTime(2027, 12, 31);
        expect(AppDateUtils.formatDate(date), '31.12.2027');
      });

      test('handles first day of year', () {
        final date = DateTime(2026, 1, 1);
        expect(AppDateUtils.formatDate(date), '01.01.2026');
      });
    });

    // ── formatDateTime ───────────────────────────────────────────────────

    group('formatDateTime', () {
      test('formats date and time as dd.MM.yyyy, HH:mm', () {
        final date = DateTime(2026, 4, 15, 14, 30);
        expect(AppDateUtils.formatDateTime(date), '15.04.2026, 14:30');
      });

      test('zero-pads hours and minutes', () {
        final date = DateTime(2026, 3, 1, 8, 5);
        expect(AppDateUtils.formatDateTime(date), '01.03.2026, 08:05');
      });

      test('handles midnight', () {
        final date = DateTime(2026, 6, 15, 0, 0);
        expect(AppDateUtils.formatDateTime(date), '15.06.2026, 00:00');
      });

      test('handles end of day', () {
        final date = DateTime(2026, 6, 15, 23, 59);
        expect(AppDateUtils.formatDateTime(date), '15.06.2026, 23:59');
      });
    });

    // ── formatShort ──────────────────────────────────────────────────────

    group('formatShort', () {
      test('formats as dd/MM/yyyy', () {
        final date = DateTime(2026, 4, 15);
        expect(AppDateUtils.formatShort(date), '15/04/2026');
      });

      test('zero-pads single digits', () {
        final date = DateTime(2025, 2, 3);
        expect(AppDateUtils.formatShort(date), '03/02/2025');
      });
    });

    // ── daysUntil ────────────────────────────────────────────────────────

    group('daysUntil', () {
      test('returns positive for a future date', () {
        final future = DateTime.now().add(const Duration(days: 5));
        expect(AppDateUtils.daysUntil(future), 5);
      });

      test('returns 0 for today', () {
        final today = DateTime.now();
        expect(AppDateUtils.daysUntil(today), 0);
      });

      test('returns negative for a past date', () {
        final past = DateTime.now().subtract(const Duration(days: 3));
        expect(AppDateUtils.daysUntil(past), -3);
      });

      test('ignores time component (only compares dates)', () {
        final now = DateTime.now();
        final todayLate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        expect(AppDateUtils.daysUntil(todayLate), 0);
      });

      test('returns 1 for tomorrow regardless of time', () {
        final now = DateTime.now();
        final tomorrowEarly =
            DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
        expect(AppDateUtils.daysUntil(tomorrowEarly), 1);
      });
    });

    // ── urgencyLabel ─────────────────────────────────────────────────────

    group('urgencyLabel', () {
      test('returns overdue indicator for past deadlines', () {
        final past = DateTime.now().subtract(const Duration(days: 2));
        expect(AppDateUtils.urgencyLabel(past), contains('-2d'));
      });

      test('returns today indicator for today', () {
        final today = DateTime.now();
        expect(AppDateUtils.urgencyLabel(today), contains('Täna'));
      });

      test('returns 1d for tomorrow', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        expect(AppDateUtils.urgencyLabel(tomorrow), contains('1d'));
      });

      test('returns day count for future deadlines', () {
        final future = DateTime.now().add(const Duration(days: 7));
        expect(AppDateUtils.urgencyLabel(future), contains('7d'));
      });

      test('overdue label starts with warning emoji', () {
        final past = DateTime.now().subtract(const Duration(days: 1));
        final label = AppDateUtils.urgencyLabel(past);
        expect(label, startsWith('\u26A0\uFE0F')); // warning emoji
      });

      test('today label starts with red circle emoji', () {
        final today = DateTime.now();
        final label = AppDateUtils.urgencyLabel(today);
        expect(label, startsWith('\uD83D\uDD34')); // red circle
      });

      test('tomorrow label starts with yellow circle emoji', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final label = AppDateUtils.urgencyLabel(tomorrow);
        expect(label, startsWith('\uD83D\uDFE1')); // yellow circle
      });

      test('future label starts with calendar emoji', () {
        final future = DateTime.now().add(const Duration(days: 10));
        final label = AppDateUtils.urgencyLabel(future);
        expect(label, startsWith('\uD83D\uDCC5')); // calendar
      });
    });
  });
}
