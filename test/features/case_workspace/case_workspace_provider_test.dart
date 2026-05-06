// Phase 2 Pkg 4 — case_workspace_provider tests.

import 'package:advocat/features/case_memory/data/case_deadline_repository.dart';
import 'package:advocat/features/case_memory/models/case_deadline.dart';
import 'package:advocat/features/case_memory/state/active_case_provider.dart'
    show sharedPreferencesProvider;
import 'package:advocat/features/case_memory/state/case_deadline_providers.dart';
import 'package:advocat/features/case_workspace/providers/case_workspace_provider.dart';
import 'package:advocat/features/inbox/models/inbox_severity.dart';
import 'package:advocat/features/inbox/models/inbox_thread.dart';
import 'package:advocat/features/inbox/providers/inbox_provider.dart';
import 'package:advocat/services/assistant_tools.dart';
import 'package:advocat/services/supabase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeDeadlineRepo implements CaseDeadlineRepository {
  _FakeDeadlineRepo(this._list);
  final List<CaseDeadline> _list;
  @override
  Future<List<CaseDeadline>> listForCase(String caseId) async => _list;
  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

CaseDeadline _dl({
  required String id,
  required DateTime at,
  CaseDeadlineStatus status = CaseDeadlineStatus.active,
}) {
  final now = DateTime.utc(2026, 5, 6, 12);
  return CaseDeadline(
    id: id,
    caseId: 'c-1',
    title: 'D-$id',
    deadlineAt: at,
    status: status,
    priority: CaseDeadlinePriority.high,
    source: CaseDeadlineSource.manual,
    holidayShifted: false,
    anchorKey: 'manual',
    createdAt: now,
    updatedAt: now,
  );
}

class _SeededInboxNotifier extends InboxNotifier {
  _SeededInboxNotifier(super.tools, List<InboxThread> seed) {
    state = InboxState(
      threads: seed,
      severityFilter: null,
      isLoading: false,
      errorMessage: null,
    );
  }
  @override
  Future<void> refresh() async {/* no-op */}
}

InboxThread _t({
  required String id,
  required String? caseId,
  InboxSeverity severity = InboxSeverity.critical,
  DateTime? seenAt,
}) {
  return InboxThread(
    threadId: id,
    triageId: 'r-$id',
    subject: 'S-$id',
    senderEmail: 'a@b.c',
    severity: severity,
    userBrief: 'b',
    lastMessageAt: DateTime.now().toUtc(),
    hasDraft: true,
    sendRecommendation: 'hold_for_user_review',
    userAction: null,
    seenByUserAt: seenAt,
    caseId: caseId,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('WorkspaceTab.fromQuery', () {
    test('round-trips canonical names', () {
      for (final t in WorkspaceTab.values) {
        expect(WorkspaceTab.fromQuery(t.name), t);
      }
    });
    test('falls back to overview', () {
      expect(WorkspaceTab.fromQuery(null), WorkspaceTab.overview);
      expect(WorkspaceTab.fromQuery('zzz'), WorkspaceTab.overview);
    });
  });

  group('caseWorkspaceFlagProvider', () {
    test('defaults to true when prefs are empty', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // Resolve prefs.
      // Force prefs to resolve so the provider returns the real value.
      // ignore: unused_local_variable
      final _ = container.read(workspaceLastTabProvider('warmup').notifier);
      expect(container.read(caseWorkspaceFlagProvider), isTrue);
    });

    test('reads false when prefs say so', () async {
      SharedPreferences.setMockInitialValues({
        kCaseWorkspaceFlagPrefKey: false,
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // Force prefs to resolve.
      // ignore: unused_local_variable
      final _ = container.read(workspaceLastTabProvider('warmup').notifier);
      // Allow microtasks to settle the AsyncValue.
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(container.read(caseWorkspaceFlagProvider), isFalse);
    });
  });

  group('workspaceLastTabProvider', () {
    test('persists and rehydrates the tab', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // Resolve the prefs FutureProvider first — until it's `.data`,
      // workspaceLastTabProvider is the stub notifier.
      await container.read(sharedPreferencesProvider.future);
      // Read the notifier — by now the real one exists.
      final notifier =
          container.read(workspaceLastTabProvider('c-1').notifier);
      await notifier.setTab(WorkspaceTab.deadlines);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('advocat.workspace.last_tab.c-1'),
          WorkspaceTab.deadlines.name);

      // Rehydrate via a fresh container.
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);
      await container2.read(sharedPreferencesProvider.future);
      expect(container2.read(workspaceLastTabProvider('c-1')),
          WorkspaceTab.deadlines);
    });
  });

  group('workspaceDeadlineBadgeProvider', () {
    test('counts active deadlines within 7 days', () async {
      final now = DateTime.now();
      final repo = _FakeDeadlineRepo([
        _dl(id: 'a', at: now.add(const Duration(days: 2))),
        _dl(id: 'b', at: now.add(const Duration(days: 6))),
        _dl(id: 'c', at: now.add(const Duration(days: 30))),
        _dl(
          id: 'd',
          at: now.add(const Duration(days: 1)),
          status: CaseDeadlineStatus.archived,
        ),
      ]);
      final container = ProviderContainer(overrides: [
        caseDeadlineRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);
      // Resolve the FutureProvider before reading the derived badge.
      // ignore: unused_local_variable
      final _ = await container.read(deadlinesProvider('c-1').future);
      final count =
          container.read(workspaceDeadlineBadgeProvider('c-1'));
      expect(count, 2);
    });
  });

  group('workspaceInboxBadgeProvider', () {
    test('counts unseen CRITICAL threads scoped to case', () async {
      final container = ProviderContainer(overrides: [
        inboxProvider.overrideWith(
          (ref) => _SeededInboxNotifier(
            ref.read(assistantToolsProvider),
            [
              _t(id: '1', caseId: 'c-1', severity: InboxSeverity.critical),
              _t(id: '2', caseId: 'c-1', severity: InboxSeverity.high),
              _t(
                id: '3',
                caseId: 'c-1',
                severity: InboxSeverity.critical,
                seenAt: DateTime.now().toUtc(),
              ),
              _t(id: '4', caseId: 'OTHER', severity: InboxSeverity.critical),
            ],
          ),
        ),
        assistantToolsProvider.overrideWithValue(
          AssistantTools(supabaseService: SupabaseService()),
        ),
      ]);
      addTearDown(container.dispose);
      final count = container.read(workspaceInboxBadgeProvider('c-1'));
      expect(count, 1);
    });
  });

  group('WorkspaceDraftsNotifier', () {
    test('add / markResolved / clearForCase update state', () {
      final n = WorkspaceDraftsNotifier();
      expect(n.state, isEmpty);

      n.add(WorkspaceDraft(
        id: 'd1',
        caseId: 'c-1',
        title: 'Letter',
        body: 'Body',
        createdAt: DateTime.utc(2026, 5, 6),
      ));
      expect(n.state.length, 1);
      expect(n.state.first.pending, isTrue);

      n.markResolved('d1');
      expect(n.state.first.pending, isFalse);

      n.clearForCase('c-1');
      expect(n.state, isEmpty);
    });
  });
}

