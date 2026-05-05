// case_file_providers.dart — Riverpod state for the Case File screen.
// -----------------------------------------------------------------------------
// Loads the three persisted lists (events / parties / deadlines) for the
// signed-in user and exposes them to the UI.  Pull-to-refresh re-fetches.
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/case_file.dart';
import '../../services/case_file_service.dart';

/// Snapshot exposed to the UI.
@immutable
class CaseFileState {
  final List<CaseEvent> events;
  final List<CaseParty> parties;
  final List<CaseDeadline> deadlines;
  final bool loading;
  final String? error;

  const CaseFileState({
    this.events = const [],
    this.parties = const [],
    this.deadlines = const [],
    this.loading = false,
    this.error,
  });

  bool get isEmpty =>
      events.isEmpty && parties.isEmpty && deadlines.isEmpty && !loading;

  /// Active (uncompleted) deadlines, sorted by date ascending.  Computed for
  /// the countdown widget.
  List<CaseDeadline> activeDeadlines() {
    final out = deadlines.where((d) => !d.completed).toList();
    out.sort((a, b) => a.date.compareTo(b.date));
    return out;
  }

  /// The single most-urgent upcoming deadline, or null when none exists.
  CaseDeadline? mostUrgentDeadline(DateTime today) {
    final active = activeDeadlines();
    final upcoming = active.where((d) => !d.date.isBefore(_dateOnly(today)));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  CaseFileState copyWith({
    List<CaseEvent>? events,
    List<CaseParty>? parties,
    List<CaseDeadline>? deadlines,
    bool? loading,
    String? error,
  }) =>
      CaseFileState(
        events: events ?? this.events,
        parties: parties ?? this.parties,
        deadlines: deadlines ?? this.deadlines,
        loading: loading ?? this.loading,
        error: error,
      );
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class CaseFileNotifier extends StateNotifier<CaseFileState> {
  CaseFileNotifier(this._service) : super(const CaseFileState());

  final CaseFileService _service;
  String? _caseId;

  /// Pin the notifier to a specific case (or `null` for the cross-case
  /// view) and trigger a refresh.
  Future<void> bind({String? caseId}) async {
    _caseId = caseId;
    await refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final results = await Future.wait([
        _service.listEvents(caseId: _caseId),
        _service.listParties(caseId: _caseId),
        _service.listDeadlines(caseId: _caseId),
      ]);
      state = CaseFileState(
        events: results[0] as List<CaseEvent>,
        parties: results[1] as List<CaseParty>,
        deadlines: results[2] as List<CaseDeadline>,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> markDeadlineCompleted(String deadlineId) async {
    await _service.markDeadlineCompleted(deadlineId, completed: true);
    await refresh();
  }

  Future<void> deleteEvent(String id) async {
    await _service.deleteEvent(id);
    await refresh();
  }

  Future<void> deleteParty(String id) async {
    await _service.deleteParty(id);
    await refresh();
  }

  Future<void> deleteDeadline(String id) async {
    await _service.deleteDeadline(id);
    await refresh();
  }
}

final caseFileProvider =
    StateNotifierProvider.autoDispose<CaseFileNotifier, CaseFileState>((ref) {
  final svc = ref.watch(caseFileServiceProvider);
  final notifier = CaseFileNotifier(svc);
  // Kick off the first load immediately. Tests can override this provider
  // with a fake notifier to bypass.
  notifier.refresh();
  return notifier;
});
