// Phase 2 Pkg 4 — TimelineTab widget tests.

import 'package:advocat/features/case_memory/models/user_case.dart';
import 'package:advocat/features/case_workspace/tabs/timeline_tab.dart';
import 'package:advocat/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

UserCase _mk({List<TimelineEntry> timeline = const []}) {
  final now = DateTime.utc(2026, 5, 6);
  return UserCase(
    id: 'c-1',
    userId: 'u-1',
    title: 'Sulga FI',
    jurisdiction: 'FI',
    timeline: timeline,
    createdAt: now,
    updatedAt: now,
  );
}

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('et'), Locale('ru')],
      home: Scaffold(body: child),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TimelineTab — empty state when no entries', (tester) async {
    await tester.pumpWidget(_wrap(TimelineTab(userCase: _mk())));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('workspace-timeline-empty')), findsOneWidget);
    expect(find.text('No events yet.'), findsOneWidget);
  });

  testWidgets('TimelineTab — renders all entries when present',
      (tester) async {
    const entries = [
      TimelineEntry(date: '2026-04-15', event: 'Police interview'),
      TimelineEntry(date: '2026-05-01', event: 'Filed appeal'),
      TimelineEntry(date: '2026-05-06', event: 'Deportation hearing'),
    ];
    await tester.pumpWidget(
      _wrap(TimelineTab(userCase: _mk(timeline: entries))),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('workspace-timeline-tab')), findsOneWidget);
    expect(find.text('Police interview'), findsOneWidget);
    expect(find.text('Filed appeal'), findsOneWidget);
    expect(find.text('Deportation hearing'), findsOneWidget);
  });
}
