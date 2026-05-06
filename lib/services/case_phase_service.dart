// =====================================================================
// CasePhaseService — Phase 2 Pkg 5
// =====================================================================
// Manual-override path for the case conversation state machine. Calls
// the `set_case_phase` Postgres RPC (security invoker → RLS-bound)
// so the user can only transition cases they own.
// =====================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/case_memory/models/case_phase.dart';

class CasePhaseTransition {
  const CasePhaseTransition({
    required this.changed,
    this.from,
    this.to,
    this.reason,
    this.phaseEnteredAt,
  });

  final bool changed;
  final CasePhase? from;
  final CasePhase? to;
  final String? reason;
  final DateTime? phaseEnteredAt;

  factory CasePhaseTransition.fromRpc(Map<String, dynamic> json) {
    final changed = json['changed'] == true;
    if (!changed) {
      return CasePhaseTransition(
        changed: false,
        reason: json['reason'] as String?,
      );
    }
    return CasePhaseTransition(
      changed: true,
      from: CasePhase.fromDb(json['from'] as String?),
      to: CasePhase.fromDb(json['to'] as String?),
      phaseEnteredAt: json['phase_entered_at'] is String
          ? DateTime.tryParse(json['phase_entered_at'] as String)
          : null,
    );
  }
}

class CasePhaseException implements Exception {
  const CasePhaseException(this.message, {this.cause});
  final String message;
  final Object? cause;

  @override
  String toString() => 'CasePhaseException: $message'
      '${cause != null ? ' (cause: $cause)' : ''}';
}

abstract class CasePhaseService {
  Future<CasePhaseTransition> setPhase(
    String caseId,
    CasePhase phase, {
    Map<String, dynamic>? metadata,
  });
}

typedef CasePhaseRpcFn = Future<Map<String, dynamic>?> Function(
  String fnName,
  Map<String, dynamic> params,
);

class CasePhaseServiceImpl implements CasePhaseService {
  CasePhaseServiceImpl({required CasePhaseRpcFn rpc}) : _rpc = rpc;

  final CasePhaseRpcFn _rpc;

  @override
  Future<CasePhaseTransition> setPhase(
    String caseId,
    CasePhase phase, {
    Map<String, dynamic>? metadata,
  }) async {
    final params = <String, dynamic>{
      'p_case_id': caseId,
      'p_phase': phase.dbValue,
      'p_metadata': metadata ?? <String, dynamic>{},
    };

    final Map<String, dynamic>? response;
    try {
      response = await _rpc('set_case_phase', params);
    } catch (e) {
      throw CasePhaseException('set_case_phase RPC threw', cause: e);
    }
    if (response == null) {
      throw const CasePhaseException('set_case_phase returned null');
    }
    return CasePhaseTransition.fromRpc(response);
  }
}

Future<Map<String, dynamic>?> _supabaseRpc(
  String fnName,
  Map<String, dynamic> params,
) async {
  final response = await Supabase.instance.client.rpc(fnName, params: params);
  if (response is Map<String, dynamic>) return response;
  if (response is Map) {
    return response.map((k, v) => MapEntry(k.toString(), v));
  }
  return null;
}

final casePhaseServiceProvider = Provider<CasePhaseService>((ref) {
  return CasePhaseServiceImpl(rpc: _supabaseRpc);
});
