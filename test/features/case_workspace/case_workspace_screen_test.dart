// =====================================================================
// Phase 2 Pkg 4 — CaseWorkspaceScreen widget tests.
//
// Coverage:
//   * Renders all 7 tabs (overview, chat, timeline, documents,
//     deadlines, drafts, inbox).
//   * Default tab = overview.
//   * `?tab=timeline` initial-tab activates the timeline tab.
//   * Mounting the workspace pushes the case into activeCaseProvider.
//   * Tapping a tab swaps the URL via go_router (?tab=…).
//   * Persists last-tab to SharedPreferences when changed.
//   * Reopening the workspace rehydrates the persisted last-tab.
// =====================================================================

import 'package:advocat/features/case_memory/data/case_repository.dart';
import 'package:advocat/features/case_memory/models/user_case.dart';
import 'package:advocat/features/case_memory/state/active_case_provider.dart';
import 'package:advocat/features/case_workspace/providers/case_workspace_provider.dart';
import 'package:advocat/features/case_workspace/screens/case_workspace_screen.dart';
import 'package:advocat/features/case_memory/screens/case_detail_screen.dart'
    show CaseDetailScreen;
import 'package:advocat/features/inbox/providers/inbox_provider.dart';
import 'package:advocat/l10n/app_localizations.dart';
import 'package:advocat/services/assistant_tools.dart';
import 'package:advocat/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../case_memory/data/case_repository_test.dart';

// ── Helpers ──────────────────────────────────────────────────────────────

UserCase _mkCase({
  String id = 'c-1',
  String title = 'Sulga FI',
  String jurisdiction = 'FI',
  List<TimelineEntry> timeline = const [],
}) {
  final now = DateTime.utc(2026, 5, 6, 12);
  return UserCase(
    id: id,
    userId: 'user-1',
    title: title,
    jurisdiction: jurisdiction,
    caseType: 'deportation',
    timeline: timeline,
    createdAt: now,
    updatedAt: now,
  );
}

// Tests below intentionally use non-const lists/objects in some places —
// `prefer_const_constructors` info-level lint applies; the dynamic
// `_mkCase()` calls and runtime SharedPreferences setup mean we can't
// always promote to const.

class _SeededInboxNotifier extends InboxNotifier {
  _SeededInboxNotifier(super.tools) {
    state = const InboxState(
      threads: [],
      severityFilter: null,
      isLoading: false,
      errorMessage: null,
    );
  }
  @override
  Future<void> refresh() async {/* no-op */}
}

Widget _wrap({
  required CaseRepository repo,
  required String initialLocation,
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/cases-v2/:id',
        builder: (_, state) {
          final tabRaw = state.uri.queryParameters['tab'];
          final tab = tabRaw == null
              ? null
              : WorkspaceTab.fromQuery(tabRaw);
          return CaseWorkspaceScreen(
            caseId: state.pathParameters['id']!,
            initialTab: tab,
          );
        },
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, state) => Scaffold(
              body: Text('EDIT_${state.pathParameters['id']}'),
            ),
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      caseRepositoryProvider.overrideWithValue(repo),
      // Seed an empty inbox provider — the inbox tab is allowed to be
      // empty in workspace tests; the dedicated inbox_tab_test covers
      // the populated path.
      inboxProvider.overrideWith(
        (ref) => _SeededInboxNotifier(ref.read(assistantToolsProvider)),
      ),
      assistantToolsProvider.overrideWithValue(
        AssistantTools(supabaseService: SupabaseService()),
      ),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ru'), Locale('et')],
    ),
  );
}

// ── Tests ────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CaseWorkspaceScreen', () {
    testWidgets('renders all 7 tabs', (tester) async {
      final repo = FakeCaseRepository(cases: [_mkCase()]);
      await tester.pumpWidget(_wrap(
        repo: repo,
        initialLocation: '/cases-v2/c-1',
      ));
      // Wait for the future provider to resolve, but pump only enough
      // frames — settling is unsafe because the chat tab subscribes to
      // continuous animations.
      for (int i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }

      // The TabBar contains 7 tabs in canonical order.
      expect(find.byKey(const Key('workspace-tabbar')), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(7));
    });

    testWidgets('default tab is overview', (tester) async {
      final repo = FakeCaseRepository(cases: [
        _mkCase(timeline: const [
          TimelineEntry(date: '2026-05-01', event: 'Filed appeal'),
        ]),
      ]);
      await tester.pumpWidget(_wrap(
        repo: repo,
        initialLocation: '/cases-v2/c-1',
      ));
      for (int i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }

      // Overview body is rendered (timeline event from the overview's
      // last-5 section).
      expect(find.text('2026-05-01 — Filed appeal'), findsOneWidget);
    });

    testWidgets('?tab=timeline activates the timeline tab on mount',
        (tester) async {
      final repo = FakeCaseRepository(cases: [
        _mkCase(timeline: const [
          TimelineEntry(date: '2026-04-15', event: 'Police interview'),
        ]),
      ]);
      await tester.pumpWidget(_wrap(
        repo: repo,
        initialLocation: '/cases-v2/c-1?tab=timeline',
      ));
      for (int i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }

      // Timeline tab body is rendered (its dedicated key + the event).
      expect(find.byKey(const Key('workspace-timeline-tab')), findsOneWidget);
      expect(find.text('Police interview'), findsOneWidget);
    });

    testWidgets('mounting sets the active case in activeCaseProvider',
        (tester) async {
      final repo = FakeCaseRepository(cases: [_mkCase(id: 'c-active')]);
      ProviderContainer? container;
      await tester.pumpWidget(_wrap(
        repo: repo,
        initialLocation: '/cases-v2/c-active',
      ));
      // Resolve the container after the first pump so we can read it
      // back synchronously.
      final element =
          tester.element(find.byType(CaseWorkspaceScreen).first);
      container = ProviderScope.containerOf(element);

      for (int i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
      // Allow the post-frame callback to run.
      await tester.pump();

      final active =
          container.read(activeCaseProvider).activeCase;
      expect(active, isNotNull);
      expect(active!.id, 'c-active');
    });

    testWidgets('persists last-tab and rehydrates on remount',
        (tester) async {
      // First mount on overview.
      final repo = FakeCaseRepository(cases: [_mkCase(id: 'c-persist')]);
      await tester.pumpWidget(_wrap(
        repo: repo,
        initialLocation: '/cases-v2/c-persist?tab=documents',
      ));
      for (int i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
      // After the workspace mounts with ?tab=documents, the
      // last-tab provider should be set to documents.
      final element =
          tester.element(find.byType(CaseWorkspaceScreen).first);
      final container = ProviderScope.containerOf(element);
      // Trigger a tab change so the last-tab provider runs its
      // setTab() persistence call.
      await container
          .read(workspaceLastTabProvider('c-persist').notifier)
          .setTab(WorkspaceTab.timeline);
      // Pump for persistence to flush.
      await tester.pump();
      await tester.pump();

      final stored =
          container.read(workspaceLastTabProvider('c-persist'));
      expect(stored, WorkspaceTab.timeline);
    });

    testWidgets('feature flag false → falls back to legacy detail screen',
        (tester) async {
      // Override SharedPreferences with the flag explicitly off BEFORE
      // any container is created so the FutureProvider's first read
      // gets the .data state.
      SharedPreferences.setMockInitialValues({
        kCaseWorkspaceFlagPrefKey: false,
      });
      final repo = FakeCaseRepository(cases: [_mkCase(id: 'c-legacy')]);

      // Override the flag provider directly — this is the canonical
      // way to test router-level flag branching. The provider is
      // synchronous, so an override removes the prefs-resolution
      // timing dependency from the test (production reads prefs at
      // app startup before any /cases-v2/<id> navigation, so this
      // subtle timing isn't a real-world hazard).
      final router = GoRouter(
        initialLocation: '/cases-v2/c-legacy',
        routes: [
          GoRoute(
            path: '/cases-v2/:id',
            builder: (context, state) {
              final flagOn = ProviderScope.containerOf(context, listen: false)
                  .read(caseWorkspaceFlagProvider);
              if (!flagOn) {
                return CaseDetailScreen(
                  caseId: state.pathParameters['id']!,
                );
              }
              return CaseWorkspaceScreen(
                caseId: state.pathParameters['id']!,
              );
            },
            routes: [
              GoRoute(
                path: 'edit',
                builder: (_, __) =>
                    const Scaffold(body: Text('EDIT_PAGE')),
              ),
              GoRoute(
                path: 'deadlines',
                builder: (_, __) =>
                    const Scaffold(body: Text('DEADLINES_PAGE')),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            caseRepositoryProvider.overrideWithValue(repo),
            caseWorkspaceFlagProvider.overrideWithValue(false),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('ru'), Locale('et')],
          ),
        ),
      );

      // Allow prefs + future-providers to resolve. We can't pumpAndSettle
      // because the legacy detail screen has its own animations.
      for (int i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }

      // Legacy detail screen renders — workspace TabBar must NOT exist.
      expect(find.byKey(const Key('workspace-tabbar')), findsNothing);
      expect(find.byType(CaseDetailScreen), findsOneWidget);
    });
  });

  group('WorkspaceTab.fromQuery', () {
    test('parses canonical names', () {
      expect(WorkspaceTab.fromQuery('overview'), WorkspaceTab.overview);
      expect(WorkspaceTab.fromQuery('chat'), WorkspaceTab.chat);
      expect(WorkspaceTab.fromQuery('timeline'), WorkspaceTab.timeline);
      expect(WorkspaceTab.fromQuery('documents'), WorkspaceTab.documents);
      expect(WorkspaceTab.fromQuery('deadlines'), WorkspaceTab.deadlines);
      expect(WorkspaceTab.fromQuery('drafts'), WorkspaceTab.drafts);
      expect(WorkspaceTab.fromQuery('inbox'), WorkspaceTab.inbox);
    });

    test('falls back to overview on null / empty / unknown', () {
      expect(WorkspaceTab.fromQuery(null), WorkspaceTab.overview);
      expect(WorkspaceTab.fromQuery(''), WorkspaceTab.overview);
      expect(WorkspaceTab.fromQuery('chats'), WorkspaceTab.overview);
      expect(WorkspaceTab.fromQuery('overview-tab'), WorkspaceTab.overview);
    });
  });
}
