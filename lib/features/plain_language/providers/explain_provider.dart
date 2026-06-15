// =============================================================================
// explain_provider.dart — Riverpod state for the Plain-Language Explainer.
// =============================================================================
//
// Holds the screen's transient state: the chosen level, the in-flight flag, the
// latest result, and any error (including the quota-exceeded case the UI turns
// into an upgrade prompt). Stateless across navigations — one explanation at a
// time, no history caching here (history is read straight from the RPC by the
// "Saved" tab if/when added).
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/explain_result.dart';
import '../services/explain_service.dart';

/// Phase of the explainer screen.
enum ExplainPhase { idle, loading, success, error, quotaExceeded }

class ExplainState {
  const ExplainState({
    this.phase = ExplainPhase.idle,
    this.level = ExplainLevel.friend,
    this.result,
    this.quota,
    this.errorMessage,
  });

  final ExplainPhase phase;
  final ExplainLevel level;
  final ExplainResult? result;

  /// Set when [phase] == quotaExceeded so the UI can show used/limit.
  final ExplainQuota? quota;
  final String? errorMessage;

  bool get isLoading => phase == ExplainPhase.loading;

  ExplainState copyWith({
    ExplainPhase? phase,
    ExplainLevel? level,
    ExplainResult? result,
    ExplainQuota? quota,
    String? errorMessage,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return ExplainState(
      phase: phase ?? this.phase,
      level: level ?? this.level,
      result: clearResult ? null : (result ?? this.result),
      quota: quota ?? this.quota,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ExplainNotifier extends StateNotifier<ExplainState> {
  ExplainNotifier(this._service) : super(const ExplainState());

  final ExplainService _service;

  void setLevel(ExplainLevel level) {
    state = state.copyWith(level: level);
  }

  /// Resets back to the input state (e.g. "explain another document").
  void reset() {
    state = ExplainState(level: state.level);
  }

  Future<void> explain({
    required String sourceText,
    String? language,
    String? caseId,
    String? sourceDocumentId,
  }) async {
    if (state.isLoading) return;
    state = state.copyWith(
      phase: ExplainPhase.loading,
      clearResult: true,
      clearError: true,
    );
    try {
      final result = await _service.explain(
        sourceText: sourceText,
        level: state.level,
        language: language,
        caseId: caseId,
        sourceDocumentId: sourceDocumentId,
      );
      state = state.copyWith(phase: ExplainPhase.success, result: result);
    } on ExplainQuotaExceeded catch (e) {
      state = state.copyWith(
        phase: ExplainPhase.quotaExceeded,
        quota: e.quota,
      );
    } catch (e) {
      state = state.copyWith(
        phase: ExplainPhase.error,
        errorMessage: e.toString(),
      );
    }
  }
}

final explainServiceProvider = Provider<ExplainService>(
  (ref) => ExplainService(),
);

final explainProvider =
    StateNotifierProvider.autoDispose<ExplainNotifier, ExplainState>(
  (ref) => ExplainNotifier(ref.watch(explainServiceProvider)),
);
