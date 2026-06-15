import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';

// ---------------------------------------------------------------------------
// Cost & Risk Estimator — state management (Feature #6)
//
// Talks to the `estimate-case` Edge Function. The output is intentionally a
// set of RANGES + a coarse 3-state strength signal — never a single number or
// a "% chance of winning". The disclaimer is enforced in the UI, and the
// model output is already clamped server-side; this layer only maps the JSON
// into typed Dart models and keeps the input form state.
// ---------------------------------------------------------------------------

/// Coarse strength traffic-light. Mirrors the server enum. NOT a probability.
enum CaseStrength { worthPursuing, contested, weak }

CaseStrength _strengthFromApi(String? raw) {
  switch (raw) {
    case 'worth_pursuing':
      return CaseStrength.worthPursuing;
    case 'weak':
      return CaseStrength.weak;
    case 'contested':
    default:
      return CaseStrength.contested;
  }
}

/// A low/high band (cost in EUR or duration in months).
class EstimateBand {
  const EstimateBand({required this.low, required this.high});

  final int low;
  final int high;

  static EstimateBand fromApi(dynamic v) {
    if (v is Map) {
      return EstimateBand(
        low: _asInt(v['low']),
        high: _asInt(v['high']),
      );
    }
    return const EstimateBand(low: 0, high: 0);
  }

  bool get isZero => low == 0 && high == 0;
}

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.round();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

List<String> _stringList(dynamic v) {
  if (v is List) {
    return v
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
  }
  return const [];
}

/// Typed estimate result returned by the edge function.
class CaseEstimate {
  const CaseEstimate({
    required this.courtFee,
    required this.lawyerFee,
    required this.total,
    required this.durationMonths,
    required this.strength,
    required this.factorsFor,
    required this.factorsAgainst,
    required this.recommendation,
    required this.nextStep,
    this.estimateId,
  });

  final EstimateBand courtFee;
  final EstimateBand lawyerFee;
  final EstimateBand total;
  final EstimateBand durationMonths;
  final CaseStrength strength;
  final List<String> factorsFor;
  final List<String> factorsAgainst;
  final String recommendation;
  final String nextStep;
  final String? estimateId;

  static CaseEstimate fromApi(Map<String, dynamic> api) {
    final est = (api['estimate'] is Map)
        ? Map<String, dynamic>.from(api['estimate'] as Map)
        : api;
    return CaseEstimate(
      courtFee: EstimateBand.fromApi(est['courtFee']),
      lawyerFee: EstimateBand.fromApi(est['lawyerFee']),
      total: EstimateBand.fromApi(est['total']),
      durationMonths: EstimateBand.fromApi(est['durationMonths']),
      strength: _strengthFromApi(est['strength'] as String?),
      factorsFor: _stringList(est['factorsFor']),
      factorsAgainst: _stringList(est['factorsAgainst']),
      recommendation: (est['recommendation'] as String?)?.trim() ?? '',
      nextStep: (est['nextStep'] as String?)?.trim() ?? '',
      estimateId: api['estimate_id'] as String?,
    );
  }
}

/// Input + result state for the estimator screen.
class CostEstimatorState {
  const CostEstimatorState({
    this.caseType = '',
    this.jurisdiction = 'EE',
    this.disputeAmount = '',
    this.description = '',
    this.b2bMode = false,
    this.isLoading = false,
    this.estimate,
    this.errorMessage,
  });

  final String caseType;
  final String jurisdiction;
  final String disputeAmount;
  final String description;
  final bool b2bMode;
  final bool isLoading;
  final CaseEstimate? estimate;
  final String? errorMessage;

  bool get canSubmit => caseType.trim().isNotEmpty && !isLoading;

  CostEstimatorState copyWith({
    String? caseType,
    String? jurisdiction,
    String? disputeAmount,
    String? description,
    bool? b2bMode,
    bool? isLoading,
    CaseEstimate? estimate,
    String? errorMessage,
    bool clearEstimate = false,
    bool clearError = false,
  }) {
    return CostEstimatorState(
      caseType: caseType ?? this.caseType,
      jurisdiction: jurisdiction ?? this.jurisdiction,
      disputeAmount: disputeAmount ?? this.disputeAmount,
      description: description ?? this.description,
      b2bMode: b2bMode ?? this.b2bMode,
      isLoading: isLoading ?? this.isLoading,
      estimate: clearEstimate ? null : (estimate ?? this.estimate),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ---------------------------------------------------------------------------
// Edge Function client abstraction (for tests)
// ---------------------------------------------------------------------------

abstract class CostEstimatorClient {
  Future<Map<String, dynamic>?> estimate({
    required String caseType,
    required String jurisdiction,
    int? disputeAmountEur,
    required String description,
    required bool b2bMode,
  });
}

class SupabaseCostEstimatorClient implements CostEstimatorClient {
  SupabaseCostEstimatorClient(this._service);
  final SupabaseService _service;

  @override
  Future<Map<String, dynamic>?> estimate({
    required String caseType,
    required String jurisdiction,
    int? disputeAmountEur,
    required String description,
    required bool b2bMode,
  }) {
    return _service.callEdgeFunction(
      'estimate-case',
      body: {
        'case_type': caseType,
        'jurisdiction': jurisdiction,
        if (disputeAmountEur != null) 'dispute_amount_eur': disputeAmountEur,
        if (description.isNotEmpty) 'description': description,
        'b2b_mode': b2bMode,
      },
    );
  }
}

/// Parse a free-text amount field ("€12,500", "12 500", "") into an int EUR,
/// or null when no usable number is present. Pure — unit-tested.
int? parseDisputeAmount(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'[^\d.]'), '');
  if (cleaned.isEmpty) return null;
  final value = double.tryParse(cleaned);
  if (value == null || value < 0) return null;
  return value.round();
}

class CostEstimatorNotifier extends StateNotifier<CostEstimatorState> {
  CostEstimatorNotifier({CostEstimatorClient? client})
      : _client = client,
        super(const CostEstimatorState());

  final CostEstimatorClient? _client;

  void setCaseType(String v) => state = state.copyWith(caseType: v);
  void setJurisdiction(String v) => state = state.copyWith(jurisdiction: v);
  void setDisputeAmount(String v) => state = state.copyWith(disputeAmount: v);
  void setDescription(String v) => state = state.copyWith(description: v);
  void setB2bMode(bool v) => state = state.copyWith(b2bMode: v);

  void reset() {
    state = state.copyWith(clearEstimate: true, clearError: true);
  }

  Future<void> submit() async {
    final caseType = state.caseType.trim();
    if (caseType.isEmpty) {
      state = state.copyWith(errorMessage: 'Please describe the type of case.');
      return;
    }
    if (_client == null) {
      state = state.copyWith(
        errorMessage: 'Estimator unavailable in offline/demo mode.',
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearEstimate: true,
    );

    Map<String, dynamic>? api;
    try {
      api = await _client.estimate(
        caseType: caseType,
        jurisdiction: state.jurisdiction,
        disputeAmountEur: parseDisputeAmount(state.disputeAmount),
        description: state.description.trim(),
        b2bMode: state.b2bMode,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Network error while generating estimate.',
      );
      return;
    }

    if (api == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Estimator unavailable. Please sign in and retry.',
      );
      return;
    }
    if (api['error'] != null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: api['error'].toString(),
      );
      return;
    }

    state = state.copyWith(
      isLoading: false,
      estimate: CaseEstimate.fromApi(api),
    );
  }
}

final costEstimatorProvider =
    StateNotifierProvider<CostEstimatorNotifier, CostEstimatorState>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return CostEstimatorNotifier(
    client: SupabaseCostEstimatorClient(supabase),
  );
});

/// Jurisdictions offered by the estimator. EE/FI are the primary markets; the
/// rest are EU markets the corpus supports.
const kEstimatorJurisdictions = <String, String>{
  'EE': 'Estonia',
  'FI': 'Finland',
  'LV': 'Latvia',
  'LT': 'Lithuania',
  'SE': 'Sweden',
  'PL': 'Poland',
  'DE': 'Germany',
  'FR': 'France',
};
