// =====================================================================
// CaseDeadlineRepository — Pkg 9 Supabase wrapper.
//
// Surfaces the three RPCs from migration 20260507_10_case_deadlines.sql:
//   * active_deadlines(p_limit)        → top-N across user's active cases
//   * case_deadlines_for(p_case_id)    → full per-case list
//   * mark_deadline_complete(id, note) → owner-only completion
//
// And direct table mutations for snooze / archive / create / edit
// (RLS enforces ownership). Tests inject a [FakeCaseDeadlineRepository]
// to avoid hitting Supabase.
// =====================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/case_deadline.dart';

/// Riverpod provider — overridden in tests.
final caseDeadlineRepositoryProvider =
    Provider<CaseDeadlineRepository>((ref) {
  return SupabaseCaseDeadlineRepository(Supabase.instance.client);
});

abstract class CaseDeadlineRepository {
  /// Top-N deadlines across all of the caller's active cases.
  /// Wraps the `active_deadlines(p_limit)` RPC.
  Future<List<CaseDeadline>> listActiveAcrossCases({int limit = 10});

  /// Full deadline list for a single case (any status). Wraps
  /// `case_deadlines_for(p_case_id)`.
  Future<List<CaseDeadline>> listForCase(String caseId);

  /// Mark a deadline complete via the `mark_deadline_complete` RPC.
  /// `note` is optional free-text the user adds at completion.
  Future<void> markComplete(String deadlineId, {String? note});

  /// Snooze a deadline by moving its `deadline_at` forward. Status
  /// stays `active`. Snoozing is a direct UPDATE — RLS enforces
  /// ownership.
  Future<CaseDeadline> snooze(String deadlineId, DateTime newDeadlineAt);

  /// Archive a deadline (status → 'archived'). Direct UPDATE under RLS.
  Future<void> archive(String deadlineId);

  /// Create a manual deadline. Returns the new row.
  Future<CaseDeadline> createManual({
    required String caseId,
    required String title,
    required DateTime deadlineAt,
    String? description,
    String? statuteBasis,
    String? anchorKey,
    DateTime? serviceDate,
    CaseDeadlinePriority priority = CaseDeadlinePriority.high,
  });

  /// Edit a manual deadline. `id` selects the row; the other fields
  /// overwrite. Returns the updated row.
  Future<CaseDeadline> editManual({
    required String id,
    String? title,
    DateTime? deadlineAt,
    String? description,
    String? statuteBasis,
    CaseDeadlinePriority? priority,
  });
}

class SupabaseCaseDeadlineRepository implements CaseDeadlineRepository {
  SupabaseCaseDeadlineRepository(this._client);

  final SupabaseClient _client;
  static const _table = 'case_deadlines';

  @override
  Future<List<CaseDeadline>> listActiveAcrossCases({int limit = 10}) async {
    final rows = await _client.rpc(
      'active_deadlines',
      params: {'p_limit': limit},
    );
    return _asList(rows)
        .map((r) => CaseDeadline.fromActiveRow(Map<String, dynamic>.from(r)))
        .toList(growable: false);
  }

  @override
  Future<List<CaseDeadline>> listForCase(String caseId) async {
    final rows = await _client.rpc(
      'case_deadlines_for',
      params: {'p_case_id': caseId},
    );
    return _asList(rows)
        .map((r) => CaseDeadline.fromCaseRow(Map<String, dynamic>.from(r)))
        .toList(growable: false);
  }

  @override
  Future<void> markComplete(String deadlineId, {String? note}) async {
    await _client.rpc(
      'mark_deadline_complete',
      params: {
        'p_deadline_id': deadlineId,
        'p_note': note,
      },
    );
  }

  @override
  Future<CaseDeadline> snooze(
      String deadlineId, DateTime newDeadlineAt) async {
    final row = await _client
        .from(_table)
        .update({
          'deadline_at': newDeadlineAt.toUtc().toIso8601String(),
        })
        .eq('id', deadlineId)
        .select()
        .single();
    return CaseDeadline.fromCaseRow(Map<String, dynamic>.from(row));
  }

  @override
  Future<void> archive(String deadlineId) async {
    await _client
        .from(_table)
        .update({'status': 'archived'}).eq('id', deadlineId);
  }

  @override
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
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('createManual: no authenticated user');
    }
    final payload = <String, dynamic>{
      'user_id': userId,
      'case_id': caseId,
      'title': title,
      'deadline_at': deadlineAt.toUtc().toIso8601String(),
      'source': 'manual',
      'priority': priority.dbValue,
      if (description != null) 'description': description,
      if (statuteBasis != null) 'statute_basis': statuteBasis,
      if (anchorKey != null) 'anchor_key': anchorKey,
      if (serviceDate != null)
        'service_date':
            serviceDate.toUtc().toIso8601String().split('T').first,
    };
    final row = await _client.from(_table).insert(payload).select().single();
    return CaseDeadline.fromCaseRow(Map<String, dynamic>.from(row));
  }

  @override
  Future<CaseDeadline> editManual({
    required String id,
    String? title,
    DateTime? deadlineAt,
    String? description,
    String? statuteBasis,
    CaseDeadlinePriority? priority,
  }) async {
    final patch = <String, dynamic>{
      if (title != null) 'title': title,
      if (deadlineAt != null)
        'deadline_at': deadlineAt.toUtc().toIso8601String(),
      if (description != null) 'description': description,
      if (statuteBasis != null) 'statute_basis': statuteBasis,
      if (priority != null) 'priority': priority.dbValue,
    };
    if (patch.isEmpty) {
      // Nothing to change — read-back to keep return type non-null.
      final row =
          await _client.from(_table).select().eq('id', id).single();
      return CaseDeadline.fromCaseRow(Map<String, dynamic>.from(row));
    }
    final row = await _client
        .from(_table)
        .update(patch)
        .eq('id', id)
        .select()
        .single();
    return CaseDeadline.fromCaseRow(Map<String, dynamic>.from(row));
  }

  Iterable<Map> _asList(Object? raw) {
    if (raw == null) return const Iterable.empty();
    if (raw is List) {
      return raw.cast<Map>();
    }
    return const Iterable.empty();
  }
}
