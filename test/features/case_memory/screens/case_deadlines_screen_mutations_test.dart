// Mutation-flow tests for CaseDeadlinesScreen — kept in a separate
// file from the layout tests because dialogs and bottom sheets leave
// residual Navigator state when the next test in the same file
// rebuilds the GoRouter, causing flaky cross-test interference. Each
// of these tests passes in isolation; running them in the same file
// means the Navigator's overlay isn't fully torn down between tests.

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

GoRouter _router(String caseId) => GoRouter(
      initialLocation: '/cases-v2/$caseId/deadlines',
      routes: [
        GoRoute(
          path: '/cases-v2/:id/deadlines',
          builder: (_, state) => CaseDeadlinesScreen(
            caseId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/cases-v2/:id/deadlines/new',
          builder: (_, __) =>
              const Scaffold(body: Text('NEW_DEADLINE')),
        ),
      ],
    );

Widget _wrap({
  required FakeCaseDeadlineRepository repo,
  required ProviderContainer container,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: _router('c-1'),
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

ProviderContainer _container(FakeCaseDeadlineRepository repo) {
  final c = ProviderContainer(overrides: [
    caseDeadlineRepositoryProvider.overrideWithValue(repo),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('mark-complete prompts for note then calls repo',
      (tester) async {
    final repo = FakeCaseDeadlineRepository(perCase: {
      'c-1': [mkDeadline(id: 'a', title: 'Appeal')],
    });
    await tester.pumpWidget(_wrap(repo: repo, container: _container(repo)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('deadline-card-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark complete'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('deadline-complete-save')), findsOneWidget);
    await tester.tap(find.byKey(const Key('deadline-complete-save')));
    await tester.pumpAndSettle();

    expect(repo.lastMarkedComplete, 'a');
  });
}
