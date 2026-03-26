import 'package:intl/intl.dart';

/// Date formatting utilities used across the app.
abstract final class AppDateUtils {
  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm');
  static final _shortDate = DateFormat('dd/MM/yyyy');

  static String formatDate(DateTime date) => _dateFormat.format(date);
  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);
  static String formatShort(DateTime date) => _shortDate.format(date);

  /// Returns the number of days until [date]. Negative if in the past.
  static int daysUntil(DateTime date) {
    final now = DateTime.now();
    return DateTime(date.year, date.month, date.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
  }

  /// Human-readable label for urgency, e.g. "3 days left", "Overdue".
  static String urgencyLabel(DateTime deadline) {
    final days = daysUntil(deadline);
    if (days < 0) return 'Overdue by ${-days} day${-days == 1 ? '' : 's'}';
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    return '$days days left';
  }
}
