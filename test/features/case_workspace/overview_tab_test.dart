// Phase 2 Pkg 4 — OverviewTab widget tests.

import 'package:advocat/features/case_memory/data/case_deadline_repository.dart';
import 'package:advocat/features/case_memory/models/case_deadline.dart';
import 'package:advocat/features/case_memory/models/user_case.dart';
import 'package:advocat/features/case_workspace/tabs/overview_tab.dart';
import 'package:advocat/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements CaseDeadlineRepository {
  _FakeRepo({this.list = const <CaseDeadline>[]});
  final List<CaseDeadline> list;

  @override
  Future<List<CaseDeadline>> listForCase(String caseId) async => list;

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

UserCase _mk({
  String? summary,
  List<TimelineEntry> timeline = const [],
}) {
  final now = DateTime.utc(2026, 5, 6);
  return UserCase(
    id: 'c-1',
    userId: 'u-1',
    title: 'Sulga FI',
    jurisdiction: 'FI',
    caseType: 'deportation',
    summary: summary,
    timeline: timeline,
    createdAt: now,
    updatedAt: now,
  );
}

Widget _wrap(Widget child, {List<CaseDeadline> deadlines = const []}) {
  return ProviderScope(
    overrides: [
      caseDeadlineRepositoryProvider
          .overrideWithValue(_FakeRepo(list: deadlines)),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('et'), Locale('ru')],
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('OverviewTab — renders empty state when no summary or events',
      (tester) async {
    await tester.pumpWidget(_wrap(OverviewTab(userCase: _mk())));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('workspace-overview-empty')), findsOneWidget);
  });

  testWidgets('OverviewTab — shows summary section when summary is present',
      (tester) async {
    await tester.pumpWidget(_wrap(OverviewTab(
      userCase: _mk(summary: 'Asylum deportation appeal in Helsinki'),
    )));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('workspace-overview-tab')), findsOneWidget);
    expect(find.text('Asylum deportation appeal in Helsinki'), findsOneWidget);
  });

  testWidgets('OverviewTab — shows last 5 timeline events', (tester) async {
    final entries = List.generate(
      8,
      (i) => TimelineEntry(date: '2026-05-0$i', event: 'Event $i'),
    );
    await tester.pumpWidget(_wrap(OverviewTab(userCase: _mk(timeline: entries))));
    await tester.pumpAndSettle();
    // Last 5 = first five in the list (timeline is already chronologically
    // ordered by Pkg 1.C). Event 0..4 must show; Event 5..7 must not.
    expect(find.text('2026-05-00 — Event 0'), findsOneWidget);
    expect(find.text('2026-05-04 — Event 4'), findsOneWidget);
    expect(find.text('2026-05-05 — Event 5'), findsNothing);
    expect(find.text('2026-05-07 — Event 7'), findsNothing);
  });

  testWidgets('OverviewTab — surfaces top active deadline', (tester) async {
    final now = DateTime.now();
    final dl = CaseDeadline(
      id: 'd-1',
      caseId: 'c-1',
      userId: 'u-1',
      title: 'File appeal',
      deadlineAt: now.add(const Duration(days: 3)),
      anchorKey: 'manual',
      holidayShifted: false,
      source: CaseDeadlineSource.manual,
      createdAt: now,
      updatedAt: now,
      priority: CaseDeadlinePriority.high,
      status: CaseDeadlineStatus.active,
    );
    await tester.pumpWidget(_wrap(
      OverviewTab(userCase: _mk(summary: 'short')),
      deadlines: [dl],
    ));
    await tester.pumpAndSettle();
    expect(find.text('File appeal'), findsOneWidget);
  });
}
