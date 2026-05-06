// Widget tests for DeadlineCard — color bands, holiday-shift tooltip,
// action menu visibility.

import 'package:advocat/features/case_memory/models/case_deadline.dart';
import 'package:advocat/features/case_memory/widgets/deadline_card.dart';
import 'package:advocat/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data/case_deadline_repository_fake.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en')],
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('renders title + statute + days', (tester) async {
    final now = DateTime.utc(2026, 5, 6, 12);
    final d = mkDeadline(
      title: 'Appeal',
      statuteBasis: 'HOL §164',
      deadlineAt: now.add(const Duration(days: 3)),
      now: now,
    );
    await tester.pumpWidget(_wrap(DeadlineCard(deadline: d, now: now)));
    expect(find.text('Appeal'), findsOneWidget);
    expect(find.text('HOL §164'), findsOneWidget);
    expect(find.textContaining('3 days'), findsOneWidget);
  });

  testWidgets('shows "tomorrow" for 1-day delta', (tester) async {
    final now = DateTime.utc(2026, 5, 6, 12);
    final d = mkDeadline(
      deadlineAt: now.add(const Duration(hours: 30)),
      now: now,
    );
    await tester.pumpWidget(_wrap(DeadlineCard(deadline: d, now: now)));
    expect(find.text('tomorrow'), findsOneWidget);
  });

  testWidgets('shows "today" when deadline is later today', (tester) async {
    final now = DateTime.utc(2026, 5, 6, 12);
    final d = mkDeadline(
      deadlineAt: now.add(const Duration(hours: 6)),
      now: now,
    );
    await tester.pumpWidget(_wrap(DeadlineCard(deadline: d, now: now)));
    expect(find.text('today'), findsOneWidget);
  });

  testWidgets('shows "{n} days overdue" for negative delta',
      (tester) async {
    final now = DateTime.utc(2026, 5, 6, 12);
    final d = mkDeadline(
      deadlineAt: now.subtract(const Duration(days: 2, hours: 1)),
      now: now,
    );
    await tester.pumpWidget(_wrap(DeadlineCard(deadline: d, now: now)));
    expect(find.textContaining('overdue'), findsOneWidget);
  });

  testWidgets('shows holiday-shift tooltip badge when holidayShifted=true',
      (tester) async {
    final now = DateTime.utc(2026, 5, 6, 12);
    final d = mkDeadline(
      holidayShifted: true,
      holidayShiftNote:
          'moved from Sat 2026-06-13 → Mon 2026-06-15',
      now: now,
    );
    await tester.pumpWidget(_wrap(DeadlineCard(deadline: d, now: now)));
    expect(
      find.textContaining('moved from Sat 2026-06-13'),
      findsOneWidget,
    );
  });

  testWidgets('action menu shows mark-complete + snooze + edit + archive',
      (tester) async {
    final now = DateTime.utc(2026, 5, 6, 12);
    final d = mkDeadline(now: now);
    await tester.pumpWidget(_wrap(DeadlineCard(
      deadline: d,
      now: now,
      onMarkComplete: () {},
      onSnooze: () {},
      onEdit: () {},
      onArchive: () {},
    )));
    await tester.tap(find.byKey(const Key('deadline-card-menu')));
    await tester.pumpAndSettle();
    expect(find.text('Mark complete'), findsOneWidget);
    expect(find.text('Snooze'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Archive'), findsOneWidget);
  });

  testWidgets('action menu hidden in compact mode', (tester) async {
    final now = DateTime.utc(2026, 5, 6, 12);
    final d = mkDeadline(now: now);
    await tester.pumpWidget(_wrap(DeadlineCard(
      deadline: d,
      mode: DeadlineCardMode.compact,
      now: now,
      onMarkComplete: () {},
    )));
    expect(find.byKey(const Key('deadline-card-menu')), findsNothing);
  });

  testWidgets('completed deadline shows checkmark in chip + strikethrough',
      (tester) async {
    final now = DateTime.utc(2026, 5, 6, 12);
    final d = mkDeadline(
      now: now,
      status: CaseDeadlineStatus.completed,
    );
    await tester.pumpWidget(_wrap(DeadlineCard(deadline: d, now: now)));
    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}
