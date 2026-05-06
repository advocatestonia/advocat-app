// =====================================================================
// Phase 2 Pkg 4 — Case Workspace Riverpod state.
//
// Owns:
//   * WorkspaceTab enum (canonical 7-tab order)
//   * caseWorkspaceFlagProvider          — feature flag (rollback safety)
//   * workspaceLastTabProvider           — per-case last-used tab
//   * workspaceTabSelectionProvider      — current selection (autoDispose)
//   * workspaceInboxBadgeProvider        — count of unseen CRITICAL
//   * workspaceDeadlineBadgeProvider     — count of active <=7d
//   * workspaceDraftsBadgeProvider       — count of pending drafts
//
// All read-paths are derived from the existing Pkg 1 / Pkg 9 / Email D6
// data sources. We deliberately don't introduce any new server queries
// — Pkg 4 is a UX shell, not a data layer.
//
// Pattern matches lib/features/case_memory/state/active_case_provider.dart
// (manual flutter_riverpod, NOT @riverpod codegen — repo convention).
// =====================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../case_memory/models/case_deadline.dart';
import '../../case_memory/state/active_case_provider.dart'
    show sharedPreferencesProvider;
import '../../case_memory/state/case_deadline_providers.dart';
import '../../inbox/models/inbox_severity.dart';
import '../../inbox/providers/inbox_provider.dart';

// ─── Tab enum ───────────────────────────────────────────────────────────

/// Canonical tab order for the case workspace. Persisted to
/// SharedPreferences via [WorkspaceTab.name] so re-ordering the enum
/// without bumping the persistence key would break rehydration — keep
/// `name` stable.
enum WorkspaceTab {
  overview,
  chat,
  timeline,
  documents,
  deadlines,
  drafts,
  inbox;

  /// Parse the `?tab=` query param. Unknown / null falls back to
  /// [WorkspaceTab.overview] — never throw, the URL is user-supplied.
  static WorkspaceTab fromQuery(String? raw) {
    if (raw == null || raw.isEmpty) return WorkspaceTab.overview;
    for (final t in WorkspaceTab.values) {
      if (t.name == raw) return t;
    }
    return WorkspaceTab.overview;
  }
}

// ─── Feature flag ───────────────────────────────────────────────────────

/// SharedPreferences key for the rollback flag. Default is `true` —
/// the workspace ships enabled. Settings exposes a toggle to flip it
/// back to the legacy detail screen for one release; the toggle is
/// removed in the next release.
const kCaseWorkspaceFlagPrefKey = 'advocat.case_workspace.enabled';

/// True when the new workspace UI is active. Reads SharedPreferences
/// synchronously through the AsyncValue resolution — while prefs are
/// loading we default to `true` (workspace enabled). The router swap
/// also reads this provider; on mismatch the router returns the legacy
/// CaseDetailScreen.
final caseWorkspaceFlagProvider = Provider<bool>((ref) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);
  return prefsAsync.maybeWhen(
    data: (prefs) => prefs.getBool(kCaseWorkspaceFlagPrefKey) ?? true,
    orElse: () => true,
  );
});

// ─── Last-tab persistence ───────────────────────────────────────────────

/// Per-case last-used tab. Persisted under
/// `advocat.workspace.last_tab.<caseId>` so reopening a case lands on
/// the tab the user was last on (Slack-style continuity).
String _lastTabPrefKey(String caseId) =>
    'advocat.workspace.last_tab.$caseId';

class WorkspaceLastTabNotifier extends StateNotifier<WorkspaceTab> {
  WorkspaceLastTabNotifier(this._prefs, this.caseId)
      : super(_loadInitial(_prefs, caseId));

  final SharedPreferences _prefs;
  final String caseId;

  static WorkspaceTab _loadInitial(SharedPreferences prefs, String caseId) {
    final raw = prefs.getString(_lastTabPrefKey(caseId));
    return WorkspaceTab.fromQuery(raw);
  }

  Future<void> setTab(WorkspaceTab tab) async {
    state = tab;
    await _prefs.setString(_lastTabPrefKey(caseId), tab.name);
  }
}

/// Per-case last-tab notifier. Family keyed on caseId. Backed by
/// SharedPreferences; depends on [sharedPreferencesProvider].
final workspaceLastTabProvider =
    StateNotifierProvider.family<WorkspaceLastTabNotifier, WorkspaceTab, String>(
  (ref, caseId) {
    final prefsAsync = ref.watch(sharedPreferencesProvider);
    return prefsAsync.when(
      data: (prefs) => WorkspaceLastTabNotifier(prefs, caseId),
      loading: () => _StubLastTabNotifier(caseId),
      error: (_, __) => _StubLastTabNotifier(caseId),
    );
  },
);

class _StubLastTabNotifier extends WorkspaceLastTabNotifier {
  _StubLastTabNotifier(String caseId) : super(_StubPrefs(), caseId);
  @override
  Future<void> setTab(WorkspaceTab tab) async {
    state = tab; // best-effort in-memory only
  }
}

class _StubPrefs implements SharedPreferences {
  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

// ─── Current selection (autoDispose) ────────────────────────────────────

/// Currently-active tab for the workspace. AutoDispose — a fresh
/// workspace push starts from the resolved-from-URL or last-tab value;
/// leaving the workspace drops the state.
final workspaceTabSelectionProvider =
    StateProvider.autoDispose.family<WorkspaceTab, String>(
  (ref, caseId) => WorkspaceTab.overview,
);

// ─── Tab badges ─────────────────────────────────────────────────────────

/// Inbox badge: count of CRITICAL threads scoped to [caseId] that the
/// user has not yet seen. Reads the existing inboxProvider state — no
/// new round-trip.
///
/// The Email D6 InboxThread model exposes `severity` and
/// `seenByUserAt`, but **not** `caseId` directly (the wire shape
/// includes `case_id` in the assistant tool payload — see
/// `lib/features/inbox/models/inbox_thread.dart`). Pkg 4 reads
/// `caseId` from the underlying assistant-tool snapshot via
/// [inboxProvider]; if a future schema removes it, badge falls back
/// to 0 silently.
final workspaceInboxBadgeProvider =
    Provider.family<int, String>((ref, caseId) {
  final state = ref.watch(inboxProvider);
  return state.threads.where((t) {
    if (t.severity != InboxSeverity.critical) return false;
    if (t.seenByUserAt != null) return false;
    final tid = t.caseId;
    return tid != null && tid == caseId;
  }).length;
});

/// Deadlines badge: count of active deadlines within 7 days. Reads
/// the existing per-case deadlinesProvider; loading/error → 0.
final workspaceDeadlineBadgeProvider =
    Provider.family<int, String>((ref, caseId) {
  final asyncList = ref.watch(deadlinesProvider(caseId));
  return asyncList.maybeWhen(
    data: (list) {
      final cutoff = DateTime.now().add(const Duration(days: 7));
      return list
          .where((d) =>
              d.status == CaseDeadlineStatus.active &&
              !d.deadlineAt.isAfter(cutoff))
          .length;
    },
    orElse: () => 0,
  );
});

/// Drafts badge: count of pending drafts associated with the case.
///
/// Until Pkg 7 ships the `case_drafts` table, drafts are ephemeral
/// (chat tool result history). Pkg 4 surfaces them via
/// [workspaceCaseDraftsProvider] — an in-memory list seeded by the
/// drafts_tab.dart consumer. Until any draft is pushed, this returns
/// 0 (empty state).
final workspaceDraftsBadgeProvider =
    Provider.family<int, String>((ref, caseId) {
  final list = ref.watch(workspaceCaseDraftsProvider(caseId));
  return list.where((d) => d.pending).length;
});

// ─── Drafts placeholder store ───────────────────────────────────────────

/// Lightweight in-memory draft model. Pkg 7 replaces this with a
/// `case_drafts` table; Pkg 4's drafts_tab.dart treats this as the
/// source of truth so the upgrade is a one-file swap.
class WorkspaceDraft {
  const WorkspaceDraft({
    required this.id,
    required this.caseId,
    required this.title,
    required this.body,
    required this.createdAt,
    this.pending = true,
  });

  final String id;
  final String caseId;
  final String title;
  final String body;
  final DateTime createdAt;

  /// True until the user explicitly accepts/sends/archives. The badge
  /// counts only pending drafts.
  final bool pending;

  WorkspaceDraft copyWith({bool? pending}) => WorkspaceDraft(
        id: id,
        caseId: caseId,
        title: title,
        body: body,
        createdAt: createdAt,
        pending: pending ?? this.pending,
      );
}

class WorkspaceDraftsNotifier extends StateNotifier<List<WorkspaceDraft>> {
  WorkspaceDraftsNotifier() : super(const <WorkspaceDraft>[]);

  void add(WorkspaceDraft d) {
    state = [d, ...state];
  }

  void markResolved(String id) {
    state = [
      for (final d in state)
        if (d.id == id) d.copyWith(pending: false) else d,
    ];
  }

  void clearForCase(String caseId) {
    state = state.where((d) => d.caseId != caseId).toList(growable: false);
  }
}

/// Per-case drafts store. Family keyed by caseId — each case has its
/// own list. Tests inject seeds via override.
final workspaceCaseDraftsProvider = StateNotifierProvider.family<
    WorkspaceDraftsNotifier, List<WorkspaceDraft>, String>(
  (ref, caseId) => WorkspaceDraftsNotifier(),
);
