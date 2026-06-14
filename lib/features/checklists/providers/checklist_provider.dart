// ---------------------------------------------------------------------------
// Case Checklist Provider — DB-backed Riverpod state for the per-case
// "Action Plan" roadmap.
//
// Sources rows from the `get_case_checklist` RPC via SupabaseService and
// is family-keyed on caseId so each case has independent state. Toggling
// an item applies an optimistic local update, then persists via
// `toggle_checklist_item`; on failure it rolls back and re-reads.
// ---------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';
import '../models/checklist_item.dart';

/// Async checklist for a single case, keyed by caseId.
final caseChecklistProvider = AsyncNotifierProvider.family<CaseChecklistNotifier,
    CaseChecklist, String>(CaseChecklistNotifier.new);

class CaseChecklistNotifier
    extends FamilyAsyncNotifier<CaseChecklist, String> {
  SupabaseService get _supabase => ref.read(supabaseServiceProvider);

  String get _caseId => arg;

  @override
  Future<CaseChecklist> build(String caseId) async {
    final raw = await _supabase.getCaseChecklist(caseId);
    return CaseChecklist.fromRpc(raw);
  }

  /// Optimistically toggle [itemId] to [done], then persist. Rolls back
  /// and refreshes from the server on failure.
  Future<void> toggle(String itemId, bool done) async {
    final current = state.valueOrNull;
    if (current == null) return;

    // Optimistic local flip.
    final optimistic = current.withToggled(itemId, done);
    state = AsyncData(optimistic);

    try {
      final ok = await _supabase.toggleChecklistItem(
        caseId: _caseId,
        itemId: itemId,
        done: done,
      );
      if (!ok) {
        // Server rejected (e.g. ownership) — restore prior state.
        state = AsyncData(current);
      }
    } catch (_) {
      // Network / RPC error — restore and re-read canonical state.
      state = AsyncData(current);
      ref.invalidateSelf();
    }
  }

  /// Force a re-read from the server (pull-to-refresh).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final raw = await _supabase.getCaseChecklist(_caseId);
      return CaseChecklist.fromRpc(raw);
    });
  }
}
