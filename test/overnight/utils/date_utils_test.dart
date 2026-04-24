@Tags(['fast'])
library;

// Overnight isolated test suite — DOES NOT modify production code.
// Pure-Dart tests for AppDateUtils.
import 'package:flutter_test/flutter_test.dart';
import 'package:advocat/shared/utils/date_utils.dart';

void main() {
  group('AppDateUtils.formatDate/formatDateTime/formatShort', () {
    test('formatDate produces dd.MM.yyyy', () {
      expect(AppDateUtils.formatDate(DateTime(2025, 3, 7)), '07.03.2025');
      expect(AppDateUtils.formatDate(DateTime(2024, 12, 31)), '31.12.2024');
    });

    test('formatDateTime produces dd.MM.yyyy, HH:mm', () {
      expect(
        AppDateUtils.formatDateTime(DateTime(2025, 3, 7, 9, 5)),
        '07.03.2025, 09:05',
      );
    });

    test('formatShort produces dd/MM/yyyy', () {
      expect(AppDateUtils.formatShort(DateTime(2025, 3, 7)), '07/03/2025');
    });
  });

  group('AppDateUtils.daysUntil', () {
    test('same day returns 0', () {
      final now = DateTime.now();
      expect(AppDateUtils.daysUntil(now), 0);
    });

    test('tomorrow returns 1', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(AppDateUtils.daysUntil(tomorrow), 1);
    });

    test('yesterday returns -1', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(AppDateUtils.daysUntil(yesterday), -1);
    });

    test('seven days out returns 7', () {
      final d = DateTime.now().add(const Duration(days: 7));
      expect(AppDateUtils.daysUntil(d), 7);
    });

    test('ignores time-of-day component', () {
      final now = DateTime.now();
      // 23:59 today should still be 0 days away.
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      expect(AppDateUtils.daysUntil(endOfDay), 0);
    });
  });

  group('AppDateUtils.urgencyLabel', () {
    test('past deadline shows overdue prefix', () {
      final d = DateTime.now().subtract(const Duration(days: 3));
      final label = AppDateUtils.urgencyLabel(d);
      expect(label.contains('-'), isTrue);
    });

    test('today returns "today" label', () {
      final label = AppDateUtils.urgencyLabel(DateTime.now());
      // The label for today is a non-empty string that we don't assert
      // on its exact glyphs (emoji+localized text), but it must not be empty.
      expect(label, isNotEmpty);
    });

    test('tomorrow returns a 1-day label', () {
      final label = AppDateUtils.urgencyLabel(
        DateTime.now().add(const Duration(days: 1)),
      );
      expect(label.contains('1d'), isTrue);
    });

    test('far future returns Nd format', () {
      final label = AppDateUtils.urgencyLabel(
        DateTime.now().add(const Duration(days: 42)),
      );
      expect(label.contains('42d'), isTrue);
    });
  });
}
