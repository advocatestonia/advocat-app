// Widget tests for DeadlineRadarWidget — empty state, list, permission
// soft-ask gating, "View all" link visibility.

import 'package:advocat/features/case_memory/data/case_deadline_repository.dart';
import 'package:advocat/features/case_memory/models/case_deadline.dart';
import 'package:advocat/features/case_memory/widgets/deadline_radar_widget.dart';
import 'package:advocat/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/case_deadline_repository_fake.dart';

GoRouter _router({Widget? home}) => GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, __) => Scaffold(
            body: SingleChildScrollView(
              child: home ?? const DeadlineRadarWidget(),
            ),
          ),
        ),
        GoRoute(
          path: '/cases-v2/:id/deadlines',
          builder: (_, state) =>
              Scaffold(body: Text('DEADLINES_${state.pathParameters['id']}')),
        ),
        GoRoute(
          path: '/deadlines',
          builder: (_, __) => const Scaffold(body: Text('LEGACY_DEADLINES')),
        ),
      ],
    );

Widget _wrap({required FakeCaseDeadlineRepository repo, Widget? home}) {
  return ProviderScope(
    overrides: [
      caseDeadlineRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp.router(
      routerConfig: _router(home: home),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders empty state when no deadlines', (tester) async {
    final repo = FakeCaseDeadlineRepository();
    await tester.pumpWidget(_wrap(repo: repo));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('deadline-radar-empty')), findsOneWidget);
    expect(find.text('No upcoming deadlines'), findsOneWidget);
  });

  testWidgets('renders critical deadline in red', (tester) async {
    final critical = mkDeadline(
      id: 'd-1',
      title: 'KHO valitus',
      caseTitle: 'Sulga FI',
      deltaDaysOverride: 1,
      priority: CaseDeadlinePriority.critical,
      deadlineAt: DateTime.now().add(const Duration(hours: 20)),
    );
    final repo = FakeCaseDeadlineRepository(active: [critical]);
    await tester.pumpWidget(_wrap(repo: repo));
    await tester.pumpAndSettle();

    expect(find.text('KHO valitus'), findsOneWidget);
    expect(find.text('Sulga FI'), findsOneWidget);
  });

  testWidgets('hides permission soft-ask after Later tap', (tester) async {
    final repo =
        FakeCaseDeadlineRepository(active: [mkDeadline(id: 'd-1')]);
    await tester.pumpWidget(_wrap(repo: repo));
    await tester.pumpAndSettle();

    // Soft-ask visible.
    expect(find.byKey(const Key('deadline-permission-soft-ask')),
        findsOneWidget);

    await tester.tap(find.byKey(const Key('deadline-permission-later')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('deadline-permission-soft-ask')),
        findsNothing);
  });

  testWidgets(
      'soft-ask is hidden when no deadlines (do not ask for permission '
      'we do not need yet)', (tester) async {
    final repo = FakeCaseDeadlineRepository();
    await tester.pumpWidget(_wrap(repo: repo));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('deadline-permission-soft-ask')),
        findsNothing);
  });

  testWidgets('shows "View all" only when more than display limit',
      (tester) async {
    // 6 rows so list overflows the 5-cap.
    final repo = FakeCaseDeadlineRepository(active: [
      for (var i = 0; i < 6; i++) mkDeadline(id: 'd-$i'),
    ]);
    await tester.pumpWidget(_wrap(repo: repo));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('deadline-radar-view-all')), findsOneWidget);
  });

  testWidgets('does NOT show "View all" when exactly at the cap',
      (tester) async {
    final repo = FakeCaseDeadlineRepository(active: [
      for (var i = 0; i < kRadarDisplayLimit; i++) mkDeadline(id: 'd-$i'),
    ]);
    await tester.pumpWidget(_wrap(repo: repo));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('deadline-radar-view-all')), findsNothing);
  });

  testWidgets('soft-ask hidden when permission persisted as "later"',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'advocat.deadline_permission.v1': 'later',
    });
    final repo =
        FakeCaseDeadlineRepository(active: [mkDeadline(id: 'd-1')]);
    await tester.pumpWidget(_wrap(repo: repo));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('deadline-permission-soft-ask')),
        findsNothing);
  });
}
