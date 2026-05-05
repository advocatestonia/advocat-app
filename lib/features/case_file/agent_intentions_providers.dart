// agent_intentions_providers.dart — Riverpod state for the
// "Pending follow-ups" section on the Case File screen.
// -----------------------------------------------------------------------------
// Ref: lib/services/supabase_service.dart#listAgentIntentions/cancelAgentIntention
//      lib/features/case_file/widgets/pending_intentions_section.dart
//      supabase/migrations/20260505_agent_intentions.sql
//
// Read-only list + cancel action. Kept out of case_file_service.dart on
// purpose — that file just shipped, owner asked us not to touch it.
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/supabase_service.dart';

/// Plain-data row exposed to the UI. Mirrors the agent_intentions table
/// minus the columns the UI does not render.
@immutable
class AgentIntentionEntry {
  final String id;
  final String? caseId;
  final String intentType;
  final String? targetId;
  final DateTime nextCheckAt;
  final String summary;
  final String locale;

  const AgentIntentionEntry({
    required this.id,
    required this.caseId,
    required this.intentType,
    required this.targetId,
    required this.nextCheckAt,
    required this.summary,
    required this.locale,
  });

  static AgentIntentionEntry fromRow(Map<String, dynamic> row) {
    final ctx = (row['conversation_context'] as Map?)?.cast<String, dynamic>();
    final summary = (ctx?['summary'] as String? ?? '').trim();
    final locale = (ctx?['locale'] as String? ?? 'en').trim();
    return AgentIntentionEntry(
      id: row['id'] as String,
      caseId: row['case_id'] as String?,
      intentType: row['intent_type'] as String? ?? 'follow_up_question',
      targetId: row['target_id'] as String?,
      nextCheckAt: DateTime.parse(row['next_check_at'] as String).toUtc(),
      summary: summary,
      locale: locale,
    );
  }
}

@immutable
class AgentIntentionsState {
  final List<AgentIntentionEntry> items;
  final bool loading;
  final String? error;

  const AgentIntentionsState({
    this.items = const [],
    this.loading = false,
    this.error,
  });

  bool get isEmpty => items.isEmpty && !loading && error == null;

  AgentIntentionsState copyWith({
    List<AgentIntentionEntry>? items,
    bool? loading,
    String? error,
  }) =>
      AgentIntentionsState(
        items: items ?? this.items,
        loading: loading ?? this.loading,
        error: error,
      );
}

class AgentIntentionsNotifier extends StateNotifier<AgentIntentionsState> {
  AgentIntentionsNotifier(this._supabase) : super(const AgentIntentionsState());

  final SupabaseService _supabase;
  String? _caseId;

  Future<void> bind({String? caseId}) async {
    _caseId = caseId;
    await refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final rows = await _supabase.listAgentIntentions(caseId: _caseId);
      final items = rows
          .map((r) => AgentIntentionEntry.fromRow(r))
          .toList(growable: false);
      state = AgentIntentionsState(items: items, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  /// Cancel an intention (sets completed=true) and refresh.
  Future<void> cancel(String id) async {
    await _supabase.cancelAgentIntention(id);
    await refresh();
  }
}

final agentIntentionsProvider = StateNotifierProvider.autoDispose<
    AgentIntentionsNotifier, AgentIntentionsState>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  final notifier = AgentIntentionsNotifier(supabase);
  notifier.refresh();
  return notifier;
});
