// Widget tests for DeadlineBanner — visibility logic, dismissal
// persistence, escalation re-show.

import 'package:advocat/features/case_memory/data/case_deadline_repository.dart';
import 'package:advocat/features/case_memory/data/case_repository.dart';
import 'package:advocat/features/case_memory/state/active_case_provider.dart';
import 'package:advocat/features/case_memory/widgets/deadline_banner.dart';
import 'package:advocat/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../case_memory/data/case_repository_test.dart';
import '../data/case_deadline_repository_fake.dart';

GoRouter _router({DateTime? now}) => GoRouter(
      initialLocation: '/test',
      routes: [
        GoRoute(
          path: '/test',
          builder: (_, __) => Scaffold(
            body: DeadlineBanner(now: now),
          ),
        ),
        GoRoute(
          path: '/cases-v2/:id/deadlines',
          builder: (_, state) =>
              Scaffold(body: Text('NAV_${state.pathParameters['id']}')),
        ),
      ],
    );

Widget _wrap({
  required FakeCaseDeadlineRepository deadlineRepo,
  required FakeCaseRepository caseRepo,
  required String activeCaseId,
  DateTime? now,
}) {
  final container = ProviderContainer(overrides: [
    caseDeadlineRepositoryProvider.overrideWithValue(deadlineRepo),
    caseRepositoryProvider.overrideWithValue(caseRepo),
  ]);
  // Seed the active case synchronously by writing prefs.
  SharedPreferences.setMockInitialValues({
    'advocat.active_case_id.v1': activeCaseId,
  });
  // Force the active-case provider to set the case directly so the
  // banner sees it without waiting for prefs rehydrate.
  final theCase = caseRepo.cases.firstWhere(
    (c) => c.id == activeCaseId,
    orElse: () => throw StateError('seed case missing'),
  );
  container.read(activeCaseProvider.notifier).setActiveCase(theCase);

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: _router(now: now),
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

  testWidgets('hides when no active case', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(body: DeadlineBanner()),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('deadline-banner')), findsNothing);
  });

  testWidgets('hides when active case has no critical deadline',
      (tester) async {
    final now = DateTime.utc(2026, 5, 6, 12);
    final caseRepo = FakeCaseRepository(cases: [
      mkUserCase(id: 'c-1', title: 'Sulga FI'),
    ]);
    final deadlineRepo = FakeCaseDeadlineRepository(
      perCase: {
        'c-1': [
          mkDeadline(
            id: 'd-1',
            caseId: 'c-1',
            deadlineAt: now.add(const Duration(days: 14)),
          )
        ],
      },
    );
    await tester.pumpWidget(_wrap(
      deadlineRepo: deadlineRepo,
      caseRepo: caseRepo,
      activeCaseId: 'c-1',
      now: now,
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('deadline-banner')), findsNothing);
  });

  testWidgets('shows when deadline ≤ 3 days', (tester) async {
    final now = DateTime.utc(2026, 5, 6, 12);
    final caseRepo = FakeCaseRepository(cases: [
      mkUserCase(id: 'c-1', title: 'Sulga FI'),
    ]);
    final deadlineRepo = FakeCaseDeadlineRepository(
      perCase: {
        'c-1': [
          mkDeadline(
            id: 'd-1',
            caseId: 'c-1',
            title: 'KHO',
            deadlineAt: now.add(const Duration(days: 2)),
          )
        ],
      },
    );
    await tester.pumpWidget(_wrap(
      deadlineRepo: deadlineRepo,
      caseRepo: caseRepo,
      activeCaseId: 'c-1',
      now: now,
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('deadline-banner')), findsOneWidget);
  });

  testWidgets('dismiss persists; same band stays hidden',
      (tester) async {
    final now = DateTime.utc(2026, 5, 6, 12);
    final caseRepo = FakeCaseRepository(cases: [
      mkUserCase(id: 'c-1', title: 'Sulga FI'),
    ]);
    final deadlineRepo = FakeCaseDeadlineRepository(
      perCase: {
        'c-1': [
          mkDeadline(
            id: 'd-1',
            caseId: 'c-1',
            deadlineAt: now.add(const Duration(days: 2)),
          )
        ],
      },
    );
    await tester.pumpWidget(_wrap(
      deadlineRepo: deadlineRepo,
      caseRepo: caseRepo,
      activeCaseId: 'c-1',
      now: now,
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('deadline-banner')), findsOneWidget);

    await tester.tap(find.byKey(const Key('deadline-banner-dismiss')));
    await tester.pumpAndSettle();

    // After dismiss, banner gone.
    expect(find.byKey(const Key('deadline-banner')), findsNothing);

    // Persistence: SharedPreferences has the dismiss-band entry.
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('advocat.deadline_banner_dismissed.d-1'),
      'high',
      reason: '2 days = high urgency band',
    );
  });

  testWidgets(
      'dismissed at "high" band re-shows when urgency escalates to '
      '"critical"', (tester) async {
    SharedPreferences.setMockInitialValues({
      // User dismissed earlier at the "high" band.
      'advocat.deadline_banner_dismissed.d-1': 'high',
      'advocat.active_case_id.v1': 'c-1',
    });
    final now = DateTime.utc(2026, 5, 6, 12);
    final caseRepo = FakeCaseRepository(cases: [
      mkUserCase(id: 'c-1', title: 'Sulga FI'),
    ]);
    final deadlineRepo = FakeCaseDeadlineRepository(
      perCase: {
        'c-1': [
          mkDeadline(
            id: 'd-1',
            caseId: 'c-1',
            // Now 16h away → critical band.
            deadlineAt: now.add(const Duration(hours: 16)),
          )
        ],
      },
    );
    await tester.pumpWidget(_wrap(
      deadlineRepo: deadlineRepo,
      caseRepo: caseRepo,
      activeCaseId: 'c-1',
      now: now,
    ));
    await tester.pumpAndSettle();
    // Critical > high → banner re-appears.
    expect(find.byKey(const Key('deadline-banner')), findsOneWidget);
  });
}
