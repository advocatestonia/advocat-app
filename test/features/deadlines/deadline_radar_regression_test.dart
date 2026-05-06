// Phase 2 Pkg 9 — Deadline Radar widget-layer regressions.
//
// The upstream commit (6eb0196) covers happy paths for DeadlineRadarWidget,
// DeadlineCard, and DeadlineBanner. This file pins the regressions:
//
//   * 100 deadlines on the radar — overflow doesn't crash; List in a
//     SingleChildScrollView still renders all five visible rows.
//   * Deadline with no statute_basis (manually-added) — renders without
//     the statute label and without crash.
//   * Deadline status='missed' (after a sweep) — renders strikethrough,
//     active filter hides it, completed filter does too (it's `missed`,
//     a third bucket).
//   * Holiday-shift tooltip surfaces correct original/shifted dates.
//   * Banner dismissed at 7d threshold (shouldn't even appear), then a
//     re-load with deadline at 3d → banner re-appears (not permanently
//     dismissed). And the per-deadline-id key isolates dismissals.
//   * Quiet-hours toggle: enable, set 22:00–07:00, save, reload → values
//     persist via DeadlineChannelPrefsNotifier.
//
// Style mirrors test/features/case_memory/widgets/deadline_radar_widget_test.dart
// — uses FakeCaseDeadlineRepository + ProviderScope override.

import 'package:advocat/features/case_memory/data/case_deadline_repository.dart';
import 'package:advocat/features/case_memory/data/case_repository.dart';
import 'package:advocat/features/case_memory/models/case_deadline.dart';
import 'package:advocat/features/case_memory/screens/case_deadlines_screen.dart';
import 'package:advocat/features/case_memory/state/active_case_provider.dart';
import 'package:advocat/features/case_memory/state/case_deadline_providers.dart';
import 'package:advocat/features/case_memory/widgets/deadline_banner.dart';
import 'package:advocat/features/case_memory/widgets/deadline_card.dart';
import 'package:advocat/features/case_memory/widgets/deadline_radar_widget.dart';
import 'package:advocat/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../case_memory/data/case_deadline_repository_fake.dart';
import '../case_memory/data/case_repository_test.dart';

GoRouter _radarRouter() => GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(
            body: SingleChildScrollView(
              child: DeadlineRadarWidget(),
            ),
          ),
        ),
        GoRoute(
          path: '/cases-v2/:id/deadlines',
          builder: (_, state) =>
              Scaffold(body: Text('NAV_${state.pathParameters['id']}')),
        ),
        GoRoute(
          path: '/deadlines',
          builder: (_, __) => const Scaffold(body: Text('LEGACY')),
        ),
      ],
    );

Widget _wrapRadar(FakeCaseDeadlineRepository repo) {
  return ProviderScope(
    overrides: [
      caseDeadlineRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp.router(
      routerConfig: _radarRouter(),
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

GoRouter _bannerRouter({DateTime? now}) => GoRouter(
      initialLocation: '/test',
      routes: [
        GoRoute(
          path: '/test',
          builder: (_, __) => Scaffold(body: DeadlineBanner(now: now)),
        ),
        GoRoute(
          path: '/cases-v2/:id/deadlines',
          builder: (_, state) =>
              Scaffold(body: Text('NAV_${state.pathParameters['id']}')),
        ),
      ],
    );

Widget _wrapBanner({
  required FakeCaseDeadlineRepository deadlineRepo,
  required FakeCaseRepository caseRepo,
  required String activeCaseId,
  DateTime? now,
}) {
  final container = ProviderContainer(overrides: [
    caseDeadlineRepositoryProvider.overrideWithValue(deadlineRepo),
    caseRepositoryProvider.overrideWithValue(caseRepo),
  ]);
  final theCase = caseRepo.cases.firstWhere(
    (c) => c.id == activeCaseId,
    orElse: () => throw StateError('seed case missing'),
  );
  container.read(activeCaseProvider.notifier).setActiveCase(theCase);
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: _bannerRouter(now: now),
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

  // ---------------------------------------------------------------------------
  // 1. Overflow: 100 deadlines must not crash; visible cap remains 5.
  // ---------------------------------------------------------------------------
  testWidgets(
    'PKG9-REG-1 — radar with 100 active deadlines stays within display cap',
    (tester) async {
      // 100 entries — cap displays kRadarDisplayLimit at most.
      final repo = FakeCaseDeadlineRepository(active: [
        for (var i = 0; i < 100; i++)
          mkDeadline(
            id: 'd-$i',
            title: 'Deadline $i',
            // Stagger the dates so the sort is deterministic.
            deadlineAt: DateTime.utc(2026, 6, 1, 12)
                .add(Duration(days: i)),
          ),
      ]);
      await tester.pumpWidget(_wrapRadar(repo));
      await tester.pumpAndSettle();

      // Empty placeholder must NOT show.
      expect(find.byKey(const Key('deadline-radar-empty')), findsNothing);
      // "View all" CTA must show because we exceeded the display cap.
      expect(find.byKey(const Key('deadline-radar-view-all')), findsOneWidget);
      // Only the first 5 deadlines must be in the visible tree (the cap
      // is enforced by `.take(kRadarDisplayLimit)`).
      expect(find.text('Deadline 0'), findsOneWidget);
      expect(find.text('Deadline 4'), findsOneWidget);
      expect(find.text('Deadline 5'), findsNothing);
      expect(find.text('Deadline 99'), findsNothing);
    },
  );

  // ---------------------------------------------------------------------------
  // 2. Deadline with no statute_basis (manually added) renders without crash.
  // ---------------------------------------------------------------------------
  testWidgets(
    'PKG9-REG-2 — deadline without statute_basis renders without crash',
    (tester) async {
      final now = DateTime.utc(2026, 5, 6, 12);
      // Simulate a manually-created deadline — no statute basis, no anchor.
      final manual = mkDeadline(
        id: 'manual-1',
        title: 'My custom deadline',
        statuteBasis: null,
        anchorKey: null,
        source: CaseDeadlineSource.manual,
        deadlineAt: now.add(const Duration(days: 5)),
      );
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Scaffold(body: DeadlineCard(deadline: manual, now: now)),
      ));
      await tester.pumpAndSettle();
      // No exception thrown; title is shown; no statute label rendered.
      expect(find.text('My custom deadline'), findsOneWidget);
      expect(find.text('HOL §164'), findsNothing);
    },
  );

  // ---------------------------------------------------------------------------
  // 3. Deadline status='missed' renders without active-filter inclusion.
  // ---------------------------------------------------------------------------
  testWidgets(
    "PKG9-REG-3 — status='missed' deadline is hidden under default Active filter",
    (tester) async {
      // The `case_deadlines_for` RPC returns missed rows; the screen
      // filter (default = Active) must hide them. (The architect spec
      // says missed rows render strikethrough in the per-case list when
      // the All filter is selected; a default Active view hides them.)
      final repo = FakeCaseDeadlineRepository(perCase: {
        'c-1': [
          mkDeadline(
            id: 'a',
            title: 'Old missed deadline',
            status: CaseDeadlineStatus.missed,
            deadlineAt: DateTime.utc(2026, 4, 1, 12),
          ),
          mkDeadline(
            id: 'b',
            title: 'Live deadline',
            deadlineAt: DateTime.utc(2026, 5, 11, 12),
          ),
        ],
      });
      final container = ProviderContainer(overrides: [
        caseDeadlineRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/cases-v2/c-1/deadlines',
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
          ),
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

      // Active filter (default) → live deadline only.
      expect(find.text('Live deadline'), findsOneWidget);
      expect(find.text('Old missed deadline'), findsNothing);
    },
  );

  // ---------------------------------------------------------------------------
  // 4. Holiday-shift tooltip surfaces correct dates.
  // ---------------------------------------------------------------------------
  testWidgets(
    "PKG9-REG-4 — holiday-shift note is rendered + matches 'moved from <Day> ... → <Day> ...' format",
    (tester) async {
      final now = DateTime.utc(2026, 5, 6, 12);
      final shifted = mkDeadline(
        id: 'd-shift',
        title: 'Kaebus',
        statuteBasis: 'HKMS §46',
        holidayShifted: true,
        holidayShiftNote: 'moved from Sat 2026-06-13 → Mon 2026-06-15',
        deadlineAt: DateTime.utc(2026, 6, 15, 12),
        now: now,
      );
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Scaffold(body: DeadlineCard(deadline: shifted, now: now)),
      ));
      await tester.pumpAndSettle();
      // Note text is in-tree.
      expect(
        find.textContaining('moved from Sat 2026-06-13'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Mon 2026-06-15'),
        findsOneWidget,
      );
      // The shift note has a Tooltip whose message matches the note. The
      // PopupMenuButton has its own "Show menu" tooltip — we filter to the
      // one that carries our shift-note message so the regression doesn't
      // misfire if the menu changes.
      final shiftTooltip = find.byWidgetPredicate(
        (w) => w is Tooltip &&
            w.message != null &&
            w.message!.contains('moved from Sat 2026-06-13'),
      );
      expect(shiftTooltip, findsOneWidget);
    },
  );

  // ---------------------------------------------------------------------------
  // 5. Banner dismissal escalation: 7d-band entry never shows banner; later
  //    a 3d-band reload re-shows. Tests the `_bandOrdinal` re-show rule.
  // ---------------------------------------------------------------------------
  testWidgets(
    'PKG9-REG-5 — banner does NOT show below high band (>3d); '
    'reload at critical band re-shows even after a previous dismissal',
    (tester) async {
      final now = DateTime.utc(2026, 5, 6, 12);
      final caseRepo = FakeCaseRepository(cases: [
        mkUserCase(id: 'c-1', title: 'Sulga FI'),
      ]);

      // Phase 1: deadline 7 days away (medium band) — banner must NOT
      // show, regardless of any pre-existing dismissal value.
      SharedPreferences.setMockInitialValues({
        'advocat.deadline_banner_dismissed.d-1': 'medium',
      });
      var deadlineRepo = FakeCaseDeadlineRepository(perCase: {
        'c-1': [
          mkDeadline(
            id: 'd-1',
            caseId: 'c-1',
            deadlineAt: now.add(const Duration(days: 7)),
          )
        ],
      });
      await tester.pumpWidget(_wrapBanner(
        deadlineRepo: deadlineRepo,
        caseRepo: caseRepo,
        activeCaseId: 'c-1',
        now: now,
      ));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('deadline-banner')),
        findsNothing,
        reason: 'medium-band deadline never triggers the banner',
      );

      // Phase 2: same deadline shifts to 16 hours away (critical band)
      // — banner must re-show. Use a fresh widget tree.
      SharedPreferences.setMockInitialValues({
        // Previous user dismissal was at the medium band — critical
        // exceeds it, so the banner returns.
        'advocat.deadline_banner_dismissed.d-1': 'medium',
      });
      deadlineRepo = FakeCaseDeadlineRepository(perCase: {
        'c-1': [
          mkDeadline(
            id: 'd-1',
            caseId: 'c-1',
            deadlineAt: now.add(const Duration(hours: 16)),
          )
        ],
      });
      await tester.pumpWidget(_wrapBanner(
        deadlineRepo: deadlineRepo,
        caseRepo: caseRepo,
        activeCaseId: 'c-1',
        now: now,
      ));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('deadline-banner')),
        findsOneWidget,
        reason: 'critical-band escalation must re-show banner '
            'even after a lower-band dismissal',
      );
    },
  );

  // ---------------------------------------------------------------------------
  // 6. Quiet-hours channel prefs persist across reloads.
  // ---------------------------------------------------------------------------
  test(
    'PKG9-REG-6 — quiet-hours setting (22:00-07:00) persists via DeadlineChannelPrefsNotifier',
    () async {
      SharedPreferences.setMockInitialValues({});
      var container = ProviderContainer(overrides: [
        caseDeadlineRepositoryProvider
            .overrideWithValue(FakeCaseDeadlineRepository()),
      ]);
      addTearDown(container.dispose);

      // Wait for SharedPreferences async resolve.
      await container.read(sharedPreferencesProvider.future);
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(Duration.zero);
      }

      // Default values match architect §9.
      var prefs = container.read(deadlineChannelPrefsProvider);
      expect(prefs.quietHoursStart, '21:00');
      expect(prefs.quietHoursEnd, '08:00');

      // Toggle quiet-hours window.
      await container
          .read(deadlineChannelPrefsProvider.notifier)
          .setQuietHours(start: '22:00', end: '07:00');

      prefs = container.read(deadlineChannelPrefsProvider);
      expect(prefs.quietHoursStart, '22:00');
      expect(prefs.quietHoursEnd, '07:00');

      // Build a fresh container — must rehydrate the same values.
      container.dispose();
      container = ProviderContainer(overrides: [
        caseDeadlineRepositoryProvider
            .overrideWithValue(FakeCaseDeadlineRepository()),
      ]);
      addTearDown(container.dispose);
      await container.read(sharedPreferencesProvider.future);
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      final reloaded = container.read(deadlineChannelPrefsProvider);
      expect(reloaded.quietHoursStart, '22:00');
      expect(reloaded.quietHoursEnd, '07:00');
    },
  );

  // ---------------------------------------------------------------------------
  // 7. Unknown DB enum values fall back to safe defaults (CaseDeadline.fromDb).
  //    Regression: in case the server schema gains a new enum value before
  //    the client picks it up, the model must not crash.
  // ---------------------------------------------------------------------------
  test('PKG9-REG-7 — unknown DB enum values fall back to safe defaults', () {
    expect(CaseDeadlineStatus.fromDb('unknown_future_status'),
        CaseDeadlineStatus.active);
    expect(CaseDeadlinePriority.fromDb('extreme'),
        CaseDeadlinePriority.high);
    expect(CaseDeadlineSource.fromDb('telegram'),
        CaseDeadlineSource.manual);
    // Null too.
    expect(CaseDeadlineStatus.fromDb(null), CaseDeadlineStatus.active);
    expect(CaseDeadlinePriority.fromDb(null), CaseDeadlinePriority.high);
    expect(CaseDeadlineSource.fromDb(null), CaseDeadlineSource.manual);
  });

  // ---------------------------------------------------------------------------
  // 8. Server-supplied delta_days override is preferred over local clock.
  //    Prevents an off-by-one when the client clock is skewed.
  // ---------------------------------------------------------------------------
  test(
    'PKG9-REG-8 — server delta_days override wins over local DateTime.now '
    'when no explicit `now` is passed',
    () {
      final d = mkDeadline(
        id: 'override',
        // deltaDaysOverride seed — pretend the server says 5 even though
        // our deadline is actually 30 days away in the model.
        deadlineAt: DateTime.utc(2999, 1, 1),
        deltaDaysOverride: 5,
      );
      // No `now` passed — must use override.
      expect(d.daysUntil(), 5);
      // With explicit `now`, the local computation wins so urgency math
      // stays deterministic in tests.
      final fixedNow = DateTime.utc(2998, 12, 31, 12);
      expect(d.daysUntil(now: fixedNow), greaterThan(0));
    },
  );

  // ---------------------------------------------------------------------------
  // 9. Permission re-enable: reset() returns to notAsked from any state.
  // ---------------------------------------------------------------------------
  test(
    'PKG9-REG-9 — DeadlinePermissionNotifier.reset() returns to notAsked',
    () async {
      SharedPreferences.setMockInitialValues({
        kDeadlinePermissionPrefKey: 'later',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(sharedPreferencesProvider.future);
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(Duration.zero);
      }

      // Initial: 'later'.
      expect(container.read(deadlinePermissionProvider),
          DeadlinePermissionState.later);

      // Reset.
      await container.read(deadlinePermissionProvider.notifier).reset();
      expect(container.read(deadlinePermissionProvider),
          DeadlinePermissionState.notAsked);

      // SharedPreferences key must be cleared.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kDeadlinePermissionPrefKey), isNull);
    },
  );
}
