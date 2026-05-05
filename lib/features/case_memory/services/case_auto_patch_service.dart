// =====================================================================
// CaseAutoPatchService — Pkg 1.C of Case Memory rebuild.
//
// Fire-and-forget client for the `case-auto-patch` Edge Function. Called
// from AIService AFTER each chat reply on a case-aware turn so the
// background Haiku call can extract a JSON patch (new dates, contacts,
// case numbers, open_questions, next_actions, summary) and merge it into
// `user_cases`.
//
// Hard guarantees:
//   * NEVER throws — chat already shipped, we cannot disrupt the UI.
//   * NEVER awaits anything the caller cares about.
//   * NEVER mutates `user_cases` directly — the Edge Function owns the
//     write (RLS pre-check + service-role merge).
//   * On success, invalidates the Riverpod providers that back the
//     "Мои дела" detail / list screens so the next render reflects the
//     patched state.
// =====================================================================

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';
import '../state/cases_list_provider.dart';

/// Riverpod DI. The service holds a [Ref] so it can invalidate
/// `caseByIdProvider(caseId)` and `casesListProvider` after a successful
/// patch — that is the only state-management touchpoint of Pkg 1.C.
final caseAutoPatchServiceProvider = Provider<CaseAutoPatchService>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return CaseAutoPatchService(supabase: supabase, ref: ref);
});

/// Outcome of a [CaseAutoPatchService.patchCase] call. Returned for
/// observability — the AIService caller ignores it (fire-and-forget).
enum CaseAutoPatchOutcome {
  /// Edge Function returned `{patched: true, fields_changed: [...]}`.
  patched,

  /// Edge Function returned `{patched: false, reason: ...}` — Haiku produced
  /// no new facts, or a non-fatal upstream issue (invalid_json,
  /// haiku_unavailable, write_failed, no_changes, load_failed).
  noChange,

  /// 401 / 403 — caller is not authenticated or the case_id is not owned.
  /// Logged but never rethrown.
  forbidden,

  /// Network error / 5xx / timeout. Logged, never rethrown.
  error,

  /// Demo mode — Edge Functions are not reachable. No-op.
  demoSkip,

  /// Caller passed a non-UUID case id; we never POST in this case.
  invalidInput,
}

class CaseAutoPatchService {
  CaseAutoPatchService({required SupabaseService supabase, required Ref ref})
      : _supabase = supabase,
        _ref = ref;

  /// Sub-class hook for tests — see [_FakeService] in the test suite. Real
  /// callers always go through the public [patchCase] entry point.
  @visibleForTesting
  CaseAutoPatchService.forTest({required SupabaseService supabase, Ref? ref})
      : _supabase = supabase,
        _ref = ref;

  final SupabaseService _supabase;
  final Ref? _ref;

  static const String _endpoint = 'case-auto-patch';

  /// UUID v4 (mixed case). Strict — synthetic ids like `general` fail.
  static final RegExp _uuidRe = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Trim cap matching the Edge Function's MAX_INPUT_CHARS (8 KB per side).
  /// Defensive — prevents pathological prompts and saves bandwidth.
  static const int maxInputChars = 8000;

  /// Fire-and-forget patch call. The caller MUST wrap this in `unawaited`
  /// (from `dart:async`) so the chat reply path never blocks on the
  /// network round-trip.
  ///
  /// Returns a [CaseAutoPatchOutcome] purely for observability — the
  /// production caller in `ai_service.dart` ignores the future entirely.
  Future<CaseAutoPatchOutcome> patchCase({
    required String caseId,
    required String userMessage,
    required String aiReply,
  }) async {
    if (caseId.isEmpty || !_uuidRe.hasMatch(caseId)) {
      return CaseAutoPatchOutcome.invalidInput;
    }
    if (userMessage.isEmpty && aiReply.isEmpty) {
      return CaseAutoPatchOutcome.invalidInput;
    }
    if (_supabase.isDemo) return CaseAutoPatchOutcome.demoSkip;

    final body = <String, dynamic>{
      'case_id': caseId,
      'user_msg': _trim(userMessage),
      'ai_reply': _trim(aiReply),
    };

    Map<String, dynamic>? response;
    try {
      response = await _supabase.callEdgeFunction(_endpoint, body: body);
    } catch (_) {
      // The shared helper already swallows most exceptions and surfaces
      // them as `{error: ...}` maps; this catch is the belt-and-braces
      // guard against e.g. JsonEncodingError on weird payloads.
      return CaseAutoPatchOutcome.error;
    }

    if (response == null) {
      // null only when callEdgeFunction couldn't decode any JSON. Treat
      // as transient.
      return CaseAutoPatchOutcome.error;
    }

    // Auth / ownership errors flow back as `{error: '...'}` strings from
    // the shared helper. Detect them defensively.
    final err = response['error'];
    if (err is String) {
      // Heuristic: 401/403 messages from `requireUserWithRateLimit` carry
      // "Unauthorized" / "Invalid session" / "Forbidden". Anything else is
      // a generic transport error.
      final lc = err.toLowerCase();
      if (lc.contains('unauthorized') ||
          lc.contains('invalid session') ||
          lc.contains('forbidden')) {
        return CaseAutoPatchOutcome.forbidden;
      }
      return CaseAutoPatchOutcome.error;
    }

    final patched = response['patched'];
    if (patched == true) {
      _invalidateProviders(caseId);
      return CaseAutoPatchOutcome.patched;
    }
    return CaseAutoPatchOutcome.noChange;
  }

  String _trim(String s) =>
      s.length > maxInputChars ? s.substring(0, maxInputChars) : s;

  /// Invalidate the providers that back the case-detail and case-list
  /// screens. Best-effort — when [_ref] is null (test override) this is
  /// a no-op so unit tests can run without a `ProviderContainer`.
  void _invalidateProviders(String caseId) {
    final ref = _ref;
    if (ref == null) return;
    try {
      ref.invalidate(caseByIdProvider(caseId));
      ref.invalidate(casesListProvider);
    } catch (_) {
      // Disposed scope or test container — never bubble.
    }
  }
}
