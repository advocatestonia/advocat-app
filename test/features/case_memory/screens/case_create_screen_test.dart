import 'package:advocat/features/case_memory/data/case_repository.dart';
import 'package:advocat/features/case_memory/screens/case_create_screen.dart';
import 'package:advocat/features/case_memory/state/active_case_provider.dart';
import 'package:advocat/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/case_repository_test.dart';

Widget _wrap({required CaseRepository repo, required GoRouter router}) {
  return ProviderScope(
    overrides: [
      caseRepositoryProvider.overrideWithValue(repo),
    ],
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
  );
}

GoRouter _router() => GoRouter(
      initialLocation: '/cases-v2/new',
      routes: [
        GoRoute(
          path: '/cases-v2/new',
          builder: (_, __) => const CaseCreateScreen(),
        ),
        GoRoute(
          path: '/cases-v2/:id',
          builder: (_, state) => Scaffold(
            body: Text('DETAIL_${state.pathParameters['id']}'),
          ),
        ),
      ],
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('CaseCreateScreen — validation', () {
    testWidgets('does not submit when title is empty', (tester) async {
      final repo = FakeCaseRepository();
      await tester.pumpWidget(_wrap(repo: repo, router: _router()));
      await tester.pumpAndSettle();

      // Tap submit without entering anything.
      await tester.tap(find.byKey(const Key('create-case-submit')));
      await tester.pumpAndSettle();

      expect(repo.lastCreatePayload, isNull,
          reason: 'createCase must not fire on empty title');
    });

    testWidgets('submits with provided fields and navigates to detail',
        (tester) async {
      final repo = FakeCaseRepository();
      await tester.pumpWidget(_wrap(repo: repo, router: _router()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'My new case');
      await tester.tap(find.byKey(const Key('create-case-submit')));
      await tester.pumpAndSettle();

      expect(repo.lastCreatePayload, isNotNull);
      expect(repo.lastCreatePayload!['title'], 'My new case');
      expect(repo.lastCreatePayload!['jurisdiction'], 'EE');
      expect(repo.lastCreatePayload!['case_type'], 'other');
      expect(repo.lastCreatePayload!['language'], 'ru');

      // We were navigated to the detail screen for the new case.
      expect(find.textContaining('DETAIL_'), findsOneWidget);
    });

    testWidgets('marks created case as active', (tester) async {
      final repo = FakeCaseRepository();
      // Capture the ActiveCaseNotifier through a probe widget.
      final container = ProviderContainer(overrides: [
        caseRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: _router(),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'Active probe');
      await tester.tap(find.byKey(const Key('create-case-submit')));
      await tester.pumpAndSettle();

      final active = container.read(activeCaseProvider).activeCase;
      expect(active, isNotNull);
      expect(active!.title, 'Active probe');
    });

    testWidgets('shows error snack-bar when repo throws', (tester) async {
      final repo = FakeCaseRepository()
        ..raiseOnCreate = Exception('insert failed');
      await tester.pumpWidget(_wrap(repo: repo, router: _router()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'will fail');
      await tester.tap(find.byKey(const Key('create-case-submit')));
      await tester.pump(); // start submit
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('insert failed'), findsOneWidget);
    });
  });
}
