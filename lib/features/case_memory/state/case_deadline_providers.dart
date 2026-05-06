// =====================================================================
// Pkg 9 — Deadline Radar Riverpod state.
//
// Three providers + one permission-flow notifier:
//   * deadlinesProvider(caseId)    FutureProvider.family — per-case
//   * globalDeadlinesProvider      FutureProvider — top-N across cases
//   * deadlineMutationsProvider    Notifier — mark/snooze/archive/create
//   * deadlinePermissionProvider   StateNotifier — inline ask flow
//
// Pattern matches lib/features/case_memory/state/active_case_provider.dart
// (manual flutter_riverpod, NOT @riverpod codegen — repo-wide convention).
//
// Auto-invalidation:
//   - Any mutation in [DeadlineMutations] invalidates BOTH the per-case
//     family AND the global radar (cascade is intentional; snoozing a
//     critical deadline should immediately demote it from the radar).
//   - Foreground transitions and case-auto-patch listeners are wired up
//     in the call sites (architect §8) — they `ref.invalidate()` the
//     same providers.
// =====================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/case_deadline_repository.dart';
import '../models/case_deadline.dart';
import 'active_case_provider.dart';

// ─── Read providers ─────────────────────────────────────────────────────

/// Per-case deadlines (any status). Wraps `case_deadlines_for`.
final deadlinesProvider =
    FutureProvider.family<List<CaseDeadline>, String>((ref, caseId) async {
  return ref.watch(caseDeadlineRepositoryProvider).listForCase(caseId);
});

/// Top-10 active deadlines across all of the caller's active cases.
/// Wraps `active_deadlines`. Sorted server-side by `deadline_at asc`.
final globalDeadlinesProvider =
    FutureProvider<List<CaseDeadline>>((ref) async {
  return ref
      .watch(caseDeadlineRepositoryProvider)
      .listActiveAcrossCases(limit: 10);
});

/// Convenience: the most-critical (by `delta_days`) Pkg 9 deadline for
/// the currently-active case, if any. Used by the chat banner.
final criticalActiveCaseDeadlineProvider =
    FutureProvider<CaseDeadline?>((ref) async {
  final caseId = ref.watch(activeCaseProvider).activeCaseId;
  if (caseId == null) return null;
  final list = await ref.watch(deadlinesProvider(caseId).future);
  // Filter to active rows ≤ 3 days away.
  final threshold = DateTime.now().add(const Duration(days: 3));
  final hits = list.where((d) =>
      d.status == CaseDeadlineStatus.active &&
      !d.deadlineAt.isAfter(threshold));
  if (hits.isEmpty) return null;
  // Earliest deadline_at = most urgent.
  final sorted = hits.toList()
    ..sort((a, b) => a.deadlineAt.compareTo(b.deadlineAt));
  return sorted.first;
});

// ─── Mutations ───────────────────────────────────────────────────────────

/// Methods on this notifier touch the server through the repo and then
/// invalidate the affected read providers.
class DeadlineMutations {
  DeadlineMutations(this._ref);

  final Ref _ref;

  CaseDeadlineRepository get _repo =>
      _ref.read(caseDeadlineRepositoryProvider);

  void _invalidateAll(String caseId) {
    _ref.invalidate(deadlinesProvider(caseId));
    _ref.invalidate(globalDeadlinesProvider);
    _ref.invalidate(criticalActiveCaseDeadlineProvider);
  }

  Future<void> markComplete({
    required String deadlineId,
    required String caseId,
    String? note,
  }) async {
    await _repo.markComplete(deadlineId, note: note);
    _invalidateAll(caseId);
  }

  Future<CaseDeadline> snooze({
    required String deadlineId,
    required String caseId,
    required DateTime newDeadlineAt,
  }) async {
    final res = await _repo.snooze(deadlineId, newDeadlineAt);
    _invalidateAll(caseId);
    return res;
  }

  Future<void> archive({
    required String deadlineId,
    required String caseId,
  }) async {
    await _repo.archive(deadlineId);
    _invalidateAll(caseId);
  }

  Future<CaseDeadline> createManual({
    required String caseId,
    required String title,
    required DateTime deadlineAt,
    String? description,
    String? statuteBasis,
    String? anchorKey,
    DateTime? serviceDate,
    CaseDeadlinePriority priority = CaseDeadlinePriority.high,
  }) async {
    final res = await _repo.createManual(
      caseId: caseId,
      title: title,
      deadlineAt: deadlineAt,
      description: description,
      statuteBasis: statuteBasis,
      anchorKey: anchorKey,
      serviceDate: serviceDate,
      priority: priority,
    );
    _invalidateAll(caseId);
    return res;
  }

  Future<CaseDeadline> editManual({
    required String id,
    required String caseId,
    String? title,
    DateTime? deadlineAt,
    String? description,
    String? statuteBasis,
    CaseDeadlinePriority? priority,
  }) async {
    final res = await _repo.editManual(
      id: id,
      title: title,
      deadlineAt: deadlineAt,
      description: description,
      statuteBasis: statuteBasis,
      priority: priority,
    );
    _invalidateAll(caseId);
    return res;
  }
}

final deadlineMutationsProvider =
    Provider<DeadlineMutations>((ref) => DeadlineMutations(ref));

// ─── Permission flow ─────────────────────────────────────────────────────

/// Three-state model for the deadline notification permission ask
/// (architect §9). We don't try to reflect the actual OS permission —
/// we only track whether the user has been given the inline soft-ask
/// and what they chose. The actual FCM permission is requested via
/// [NotificationService.requestPermission] when the user picks `allow`.
enum DeadlinePermissionState {
  /// Never asked. Show the soft-ask card.
  notAsked,

  /// User tapped "Allow" — we've kicked off `requestPermission`.
  allowed,

  /// User tapped "Later" / dismissed. Don't re-ask this session;
  /// settings screen still has a manual toggle.
  later,
}

/// SharedPrefs key. Versioned so we can re-prompt later if the soft-ask
/// copy or threshold semantics change.
const kDeadlinePermissionPrefKey = 'advocat.deadline_permission.v1';

class DeadlinePermissionNotifier
    extends StateNotifier<DeadlinePermissionState> {
  DeadlinePermissionNotifier(this._prefs)
      : super(_loadInitial(_prefs));

  final SharedPreferences _prefs;

  static DeadlinePermissionState _loadInitial(SharedPreferences prefs) {
    final raw = prefs.getString(kDeadlinePermissionPrefKey);
    return DeadlinePermissionState.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => DeadlinePermissionState.notAsked,
    );
  }

  Future<void> markAllowed() async {
    state = DeadlinePermissionState.allowed;
    await _prefs.setString(
      kDeadlinePermissionPrefKey,
      DeadlinePermissionState.allowed.name,
    );
  }

  Future<void> markLater() async {
    state = DeadlinePermissionState.later;
    await _prefs.setString(
      kDeadlinePermissionPrefKey,
      DeadlinePermissionState.later.name,
    );
  }

  /// Reset for "Re-enable" button on settings.
  Future<void> reset() async {
    state = DeadlinePermissionState.notAsked;
    await _prefs.remove(kDeadlinePermissionPrefKey);
  }
}

/// Provider — depends on [sharedPreferencesProvider]. While the
/// SharedPreferences future is loading, treat the state as `notAsked`
/// so the UI doesn't briefly flash the soft-ask before the persisted
/// "Later" choice loads.
final deadlinePermissionProvider = StateNotifierProvider<
    DeadlinePermissionNotifier, DeadlinePermissionState>((ref) {
  // Block synchronously on the prefs future. If it's still pending,
  // the StateNotifierProvider rebuilds when prefs resolves. This means
  // the very first frame after first-launch may render the radar
  // without the soft-ask card; acceptable trade-off.
  final prefsAsync = ref.watch(sharedPreferencesProvider);
  return prefsAsync.when(
    data: (prefs) => DeadlinePermissionNotifier(prefs),
    loading: () => _StubNotifier(),
    error: (_, __) => _StubNotifier(),
  );
});

/// Read-only stub used while SharedPreferences is loading or errored.
/// All mutations are no-ops; the UI just shows the soft-ask card on
/// the next rebuild when the real notifier replaces this one.
class _StubNotifier extends DeadlinePermissionNotifier {
  _StubNotifier() : super(_StubPrefs());
  @override
  Future<void> markAllowed() async {}
  @override
  Future<void> markLater() async {}
  @override
  Future<void> reset() async {}
}

/// Empty SharedPreferences-shaped object for the stub. We never call
/// methods on it — the stub overrides every public method.
class _StubPrefs implements SharedPreferences {
  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

// ─── Channel toggles (settings screen) ───────────────────────────────────

/// Per-channel toggles — push / email / in-app. Persisted via
/// SharedPreferences; defaults: push=true, email=true (critical only
/// — the cron job enforces that), in_app=true.
class DeadlineChannelPrefs {
  const DeadlineChannelPrefs({
    this.push = true,
    this.email = true,
    this.inApp = true,
    this.criticalBypassQuietHours = true,
    this.quietHoursStart = '21:00',
    this.quietHoursEnd = '08:00',
  });

  final bool push;
  final bool email;
  final bool inApp;
  final bool criticalBypassQuietHours;
  final String quietHoursStart;
  final String quietHoursEnd;

  DeadlineChannelPrefs copyWith({
    bool? push,
    bool? email,
    bool? inApp,
    bool? criticalBypassQuietHours,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) {
    return DeadlineChannelPrefs(
      push: push ?? this.push,
      email: email ?? this.email,
      inApp: inApp ?? this.inApp,
      criticalBypassQuietHours:
          criticalBypassQuietHours ?? this.criticalBypassQuietHours,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }

  Map<String, Object> toJson() => {
        'push': push,
        'email': email,
        'in_app': inApp,
        'critical_bypass_quiet_hours': criticalBypassQuietHours,
        'quiet_hours_start': quietHoursStart,
        'quiet_hours_end': quietHoursEnd,
      };

  factory DeadlineChannelPrefs.fromJson(Map<String, Object?> json) {
    return DeadlineChannelPrefs(
      push: (json['push'] as bool?) ?? true,
      email: (json['email'] as bool?) ?? true,
      inApp: (json['in_app'] as bool?) ?? true,
      criticalBypassQuietHours:
          (json['critical_bypass_quiet_hours'] as bool?) ?? true,
      quietHoursStart: (json['quiet_hours_start'] as String?) ?? '21:00',
      quietHoursEnd: (json['quiet_hours_end'] as String?) ?? '08:00',
    );
  }
}

const kDeadlineChannelPrefsKey = 'advocat.deadline_channel_prefs.v1';

class DeadlineChannelPrefsNotifier
    extends StateNotifier<DeadlineChannelPrefs> {
  DeadlineChannelPrefsNotifier(this._prefs)
      : super(_load(_prefs));

  final SharedPreferences _prefs;

  static DeadlineChannelPrefs _load(SharedPreferences prefs) {
    final raw = prefs.getStringList(kDeadlineChannelPrefsKey);
    if (raw == null) return const DeadlineChannelPrefs();
    final map = <String, Object?>{};
    for (final entry in raw) {
      final i = entry.indexOf('=');
      if (i <= 0) continue;
      final k = entry.substring(0, i);
      final v = entry.substring(i + 1);
      if (v == 'true') {
        map[k] = true;
      } else if (v == 'false') {
        map[k] = false;
      } else {
        map[k] = v;
      }
    }
    return DeadlineChannelPrefs.fromJson(map);
  }

  Future<void> _persist() async {
    final json = state.toJson();
    final lines = json.entries
        .map((e) => '${e.key}=${e.value}')
        .toList(growable: false);
    await _prefs.setStringList(kDeadlineChannelPrefsKey, lines);
  }

  Future<void> setPush(bool v) async {
    state = state.copyWith(push: v);
    await _persist();
  }

  Future<void> setEmail(bool v) async {
    state = state.copyWith(email: v);
    await _persist();
  }

  Future<void> setInApp(bool v) async {
    state = state.copyWith(inApp: v);
    await _persist();
  }

  Future<void> setCriticalBypassQuietHours(bool v) async {
    state = state.copyWith(criticalBypassQuietHours: v);
    await _persist();
  }

  Future<void> setQuietHours(
      {required String start, required String end}) async {
    state = state.copyWith(quietHoursStart: start, quietHoursEnd: end);
    await _persist();
  }
}

final deadlineChannelPrefsProvider = StateNotifierProvider<
    DeadlineChannelPrefsNotifier, DeadlineChannelPrefs>((ref) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);
  return prefsAsync.when(
    data: (prefs) => DeadlineChannelPrefsNotifier(prefs),
    loading: () => _StubChannelNotifier(),
    error: (_, __) => _StubChannelNotifier(),
  );
});

class _StubChannelNotifier extends DeadlineChannelPrefsNotifier {
  _StubChannelNotifier() : super(_StubPrefs());
  @override
  Future<void> setPush(bool v) async {}
  @override
  Future<void> setEmail(bool v) async {}
  @override
  Future<void> setInApp(bool v) async {}
  @override
  Future<void> setCriticalBypassQuietHours(bool v) async {}
  @override
  Future<void> setQuietHours(
      {required String start, required String end}) async {}
}
