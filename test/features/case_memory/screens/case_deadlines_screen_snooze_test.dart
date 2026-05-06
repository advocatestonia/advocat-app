// Snooze-flow test for CaseDeadlinesScreen — separate file (see
// case_deadlines_screen_mutations_test.dart for the rationale).

import 'package:advocat/features/case_memory/data/case_deadline_repository.dart';
import 'package:advocat/features/case_memory/screens/case_deadlines_screen.dart';
import 'package:advocat/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/case_deadline_repository_fake.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('snooze 3-day option calls repo with deadline+3d',
      (tester) async {
    final at = DateTime.utc(2026, 6, 1, 16);
    final repo = FakeCaseDeadlineRepository(perCase: {
      'c-1': [
        mkDeadline(id: 'a', title: 'Appeal', deadlineAt: at),
      ],
    });
    final container = ProviderContainer(overrides: [
      caseDeadlineRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/cases-v2/c-1/deadlines',
      routes: [
        GoRoute(
          path: '/cases-v2/:id/deadlines',
          builder: (_, state) => CaseDeadlinesScreen(
            caseId: state.pathParameters['id']!,
          ),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('deadline-card-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Snooze'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('deadline-snooze-3d')));
    await tester.pumpAndSettle();

    expect(repo.lastSnoozedId, 'a');
    expect(repo.lastSnoozedAt, at.add(const Duration(days: 3)));
  });
}
