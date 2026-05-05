// =====================================================================
// ActiveCaseNotifier — holds the user's currently-active case.
//
// Pkg 1.B's claude-proxy injection reads currentActiveCaseId() to fold
// the case + 10 most recent docs into the system prompt. The chat
// composer reads activeCase to render the "📁 Дело: <title>" badge.
//
// Persistence: only the case id is saved to SharedPreferences. On app
// startup we rehydrate by id via the repo. We keep the case object
// itself live in memory; the next reload picks up any auto-patches
// applied by Pkg 1.C.
//
// Concurrency note: setActiveCase() is synchronous in terms of the
// in-memory value — the SharedPreferences write happens fire-and-forget.
// Tests can `await ref.read(activeCaseSettledProvider.future)` to wait
// for persistence to complete.
// =====================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/case_repository.dart';
import '../models/user_case.dart';

/// SharedPreferences key for the persisted active case id. Versioned
/// so we can change the schema later without crashing on a stale string.
const kActiveCaseIdPrefKey = 'advocat.active_case_id.v1';

/// Provider for [SharedPreferences]. Tests override with an in-memory
/// instance via `SharedPreferences.setMockInitialValues({})`.
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

/// The active case state. `null` means "no case selected" (general
/// chat mode).
class ActiveCaseState {
  const ActiveCaseState({this.activeCase});

  final UserCase? activeCase;

  String? get activeCaseId => activeCase?.id;

  ActiveCaseState copyWith({Object? activeCase = _sentinel}) {
    return ActiveCaseState(
      activeCase: identical(activeCase, _sentinel)
          ? this.activeCase
          : activeCase as UserCase?,
    );
  }

  static const _sentinel = Object();
}

class ActiveCaseNotifier extends StateNotifier<ActiveCaseState> {
  ActiveCaseNotifier(this._ref) : super(const ActiveCaseState()) {
    // Fire-and-forget rehydrate — we don't block the UI; the chat
    // composer simply renders without a badge until the case loads.
    _rehydrate();
  }

  final Ref _ref;

  CaseRepository get _repo => _ref.read(caseRepositoryProvider);

  Future<void> _rehydrate() async {
    try {
      final prefs = await _ref.read(sharedPreferencesProvider.future);
      final savedId = prefs.getString(kActiveCaseIdPrefKey);
      if (savedId == null || savedId.isEmpty) return;
      final c = await _repo.getCase(savedId);
      if (c == null) {
        // Case was deleted server-side — clear stale id.
        await prefs.remove(kActiveCaseIdPrefKey);
        return;
      }
      // Don't overwrite an explicit selection that happened while we
      // were loading.
      if (state.activeCase == null) {
        state = ActiveCaseState(activeCase: c);
      }
    } catch (_) {
      // Best-effort. If rehydrate fails (no auth, network), we leave
      // the chip clear and let the user re-select.
    }
  }

  /// Selects [c] as the active case. Persists the id.
  Future<void> setActiveCase(UserCase? c) async {
    state = ActiveCaseState(activeCase: c);
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    if (c == null) {
      await prefs.remove(kActiveCaseIdPrefKey);
    } else {
      await prefs.setString(kActiveCaseIdPrefKey, c.id);
    }
  }

  /// Convenience for "x" button on the badge.
  Future<void> clearActiveCase() => setActiveCase(null);

  /// Pkg 1.B reads this synchronously when building the chat request
  /// payload. Returns null if no case is selected.
  String? currentActiveCaseId() => state.activeCaseId;
}

/// The single source of truth for the active case across the app.
final activeCaseProvider =
    StateNotifierProvider<ActiveCaseNotifier, ActiveCaseState>((ref) {
  return ActiveCaseNotifier(ref);
});
