/// Smart Case Follow-ups (Feature #2) — Riverpod providers + service.
///
/// Thin wrapper over the `case-followups` edge function (CRUD + Haiku
/// suggest). The edge function enforces JWT auth + RLS ownership, so this
/// layer carries no authz logic of its own.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/supabase_service.dart';
import 'case_followup_model.dart';

/// Service that brokers calls to the `case-followups` edge function.
class CaseFollowupsService {
  CaseFollowupsService(this._supabase);

  final SupabaseService _supabase;
  static const String _fn = 'case-followups';

  /// Ordered list for one case (open first, then done; dismissed hidden).
  Future<List<CaseFollowup>> list(String caseId) async {
    final res = await _supabase.callEdgeFunction(
      _fn,
      body: {'action': 'list', 'case_id': caseId},
    );
    if (res == null || res['error'] != null) return const [];
    final items = res['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(CaseFollowup.fromJson)
        .toList(growable: false);
  }

  /// Ask Haiku for 3-5 soft next-steps based on the recent transcript.
  /// Returns an empty list on any backend hiccup (best-effort feature).
  Future<List<FollowupSuggestion>> suggest({
    required String caseId,
    required String transcript,
  }) async {
    final res = await _supabase.callEdgeFunction(
      _fn,
      body: {
        'action': 'suggest',
        'case_id': caseId,
        'transcript': transcript,
      },
    );
    if (res == null || res['error'] != null) return const [];
    final s = res['suggestions'];
    if (s is! List) return const [];
    return s
        .whereType<Map<String, dynamic>>()
        .map(FollowupSuggestion.fromJson)
        .toList(growable: false);
  }

  /// Persist a new follow-up. Returns the created row, or null on failure.
  Future<CaseFollowup?> create({
    required String caseId,
    required String title,
    String? detail,
    DateTime? dueAt,
    FollowupSource source = FollowupSource.manual,
  }) async {
    final res = await _supabase.callEdgeFunction(
      _fn,
      body: {
        'action': 'create',
        'case_id': caseId,
        'title': title,
        if (detail != null && detail.isNotEmpty) 'detail': detail,
        if (dueAt != null) 'due_at': dueAt.toUtc().toIso8601String(),
        'source': _sourceToJson(source),
      },
    );
    if (res == null || res['error'] != null) return null;
    final item = res['item'];
    if (item is Map<String, dynamic>) return CaseFollowup.fromJson(item);
    return null;
  }

  Future<bool> complete(String followupId) =>
      _mutate('complete', {'followup_id': followupId});

  Future<bool> dismiss(String followupId) =>
      _mutate('dismiss', {'followup_id': followupId});

  Future<bool> snooze(String followupId, DateTime newDueAt) => _mutate('snooze', {
        'followup_id': followupId,
        'new_due_at': newDueAt.toUtc().toIso8601String(),
      });

  Future<bool> _mutate(String action, Map<String, dynamic> extra) async {
    final res = await _supabase.callEdgeFunction(
      _fn,
      body: {'action': action, ...extra},
    );
    if (res == null || res['error'] != null) return false;
    return res['changed'] == true;
  }

  static String _sourceToJson(FollowupSource s) {
    switch (s) {
      case FollowupSource.ai:
        return 'ai';
      case FollowupSource.suggested:
        return 'suggested';
      case FollowupSource.manual:
        return 'manual';
    }
  }
}

final caseFollowupsServiceProvider = Provider<CaseFollowupsService>((ref) {
  return CaseFollowupsService(ref.watch(supabaseServiceProvider));
});

/// Follow-ups for a specific case (the "Next steps" widget binds to this).
final caseFollowupsProvider =
    FutureProvider.family<List<CaseFollowup>, String>((ref, caseId) async {
  return ref.watch(caseFollowupsServiceProvider).list(caseId);
});
