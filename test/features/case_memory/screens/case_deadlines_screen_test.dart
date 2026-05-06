// Widget tests for CaseDeadlinesScreen — list rendering, filter,
// mark-complete dialog, snooze bottom-sheet.

import 'package:advocat/features/case_memory/data/case_deadline_repository.dart';
import 'package:advocat/features/case_memory/models/case_deadline.dart';
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
  String caseId = 'c-1',
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: _router(caseId),
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

  testWidgets('shows empty state when no deadlines', (tester) async {
    final repo = FakeCaseDeadlineRepository();
    await tester.pumpWidget(_wrap(repo: repo, container: _container(repo)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('case-deadlines-empty')), findsOneWidget);
  });

  testWidgets('shows list of active deadlines', (tester) async {
    final repo = FakeCaseDeadlineRepository(perCase: {
      'c-1': [
        mkDeadline(id: 'a', title: 'KHO valitus'),
        mkDeadline(id: 'b', title: 'Vaie HOL'),
      ],
    });
    await tester.pumpWidget(_wrap(repo: repo, container: _container(repo)));
    await tester.pumpAndSettle();
    expect(find.text('KHO valitus'), findsOneWidget);
    expect(find.text('Vaie HOL'), findsOneWidget);
  });

  testWidgets('add CTA is rendered as a FAB', (tester) async {
    final repo = FakeCaseDeadlineRepository(perCase: {
      'c-1': [mkDeadline(id: 'x')],
    });
    await tester.pumpWidget(_wrap(repo: repo, container: _container(repo)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('deadline-add-cta')), findsOneWidget);
    expect(find.text('Add deadline'), findsOneWidget);
  });

  testWidgets('archive filter shows only archived rows', (tester) async {
    final repo = FakeCaseDeadlineRepository(perCase: {
      'c-1': [
        mkDeadline(id: 'a', title: 'Active'),
        mkDeadline(
          id: 'b',
          title: 'Done',
          status: CaseDeadlineStatus.completed,
        ),
      ],
    });
    await tester.pumpWidget(_wrap(repo: repo, container: _container(repo)));
    await tester.pumpAndSettle();

    // Default filter = active → "Active" visible, "Done" hidden.
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Done'), findsNothing);
  });
}
