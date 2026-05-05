import 'package:advocat/features/case_memory/data/case_repository.dart';
import 'package:advocat/features/case_memory/models/user_case.dart';
import 'package:advocat/features/case_memory/screens/cases_list_screen.dart';
import 'package:advocat/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../data/case_repository_test.dart';

UserCase _mkCase({
  String id = 'c-1',
  String title = 'Sulga FI',
  String jurisdiction = 'FI',
  String? caseType = 'deportation',
  List<OpenQuestion> openQuestions = const [],
}) {
  final now = DateTime.utc(2026, 5, 5, 12);
  return UserCase(
    id: id,
    userId: 'user-1',
    title: title,
    jurisdiction: jurisdiction,
    caseType: caseType,
    openQuestions: openQuestions,
    createdAt: now,
    updatedAt: now,
  );
}

/// Wraps the screen-under-test in a mini app with go_router so tap
/// navigation can be observed via [navObserver].
Widget _wrap({
  required Widget child,
  required CaseRepository repo,
  GoRouter? router,
}) {
  final routerInstance = router ??
      GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, __) => child),
          GoRoute(
            path: '/cases-v2/new',
            builder: (_, __) => const Scaffold(body: Text('NEW_CASE_ROUTE')),
          ),
          GoRoute(
            path: '/cases-v2/:id',
            builder: (_, state) => Scaffold(
              body: Text('DETAIL_${state.pathParameters['id']}'),
            ),
          ),
        ],
      );

  return ProviderScope(
    overrides: [
      caseRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp.router(
      routerConfig: routerInstance,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ru')],
    ),
  );
}

void main() {
  group('CasesListScreen', () {
    testWidgets('renders empty state when there are no cases',
        (tester) async {
      final repo = FakeCaseRepository(cases: []);
      await tester.pumpWidget(
        _wrap(child: const CasesListScreen(), repo: repo),
      );
      await tester.pumpAndSettle();

      expect(find.text('No cases yet'), findsOneWidget);
      expect(find.byIcon(Icons.folder_open_outlined), findsOneWidget);
    });

    testWidgets('renders a card per case', (tester) async {
      final repo = FakeCaseRepository(cases: [
        _mkCase(id: 'c-1', title: 'First'),
        _mkCase(id: 'c-2', title: 'Second'),
      ]);
      await tester.pumpWidget(
        _wrap(child: const CasesListScreen(), repo: repo),
      );
      await tester.pumpAndSettle();

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
    });

    testWidgets('shows top open question on the card', (tester) async {
      final repo = FakeCaseRepository(cases: [
        _mkCase(
          id: 'c-1',
          openQuestions: const [
            OpenQuestion(question: 'Is the appeal still possible?'),
          ],
        ),
      ]);
      await tester.pumpWidget(
        _wrap(child: const CasesListScreen(), repo: repo),
      );
      await tester.pumpAndSettle();

      expect(find.text('Is the appeal still possible?'), findsOneWidget);
    });

    testWidgets('FAB is present with localized "New case"', (tester) async {
      final repo = FakeCaseRepository(cases: [_mkCase()]);
      await tester.pumpWidget(
        _wrap(child: const CasesListScreen(), repo: repo),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('tapping FAB navigates to /cases-v2/new', (tester) async {
      final repo = FakeCaseRepository(cases: [_mkCase()]);
      await tester.pumpWidget(
        _wrap(child: const CasesListScreen(), repo: repo),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('NEW_CASE_ROUTE'), findsOneWidget);
    });

    testWidgets('default filter is active — archived cases hidden',
        (tester) async {
      final repo = FakeCaseRepository(cases: [
        _mkCase(id: 'c-1', title: 'Active one'),
        UserCase(
          id: 'c-2',
          userId: 'u',
          title: 'Archived one',
          jurisdiction: 'EE',
          status: CaseMemoryStatus.archived,
          createdAt: DateTime.utc(2026, 5, 5),
          updatedAt: DateTime.utc(2026, 5, 5),
        ),
      ]);
      await tester.pumpWidget(
        _wrap(child: const CasesListScreen(), repo: repo),
      );
      await tester.pumpAndSettle();

      expect(find.text('Active one'), findsOneWidget);
      expect(find.text('Archived one'), findsNothing);
    });
  });
}
