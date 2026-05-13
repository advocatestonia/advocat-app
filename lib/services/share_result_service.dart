// share_result_service.dart
// ---------------------------------------------------------------------------
// Thin client for the `share-result` Supabase edge function. Used by the
// chat result + Contract Review screens to turn a powerful AI output into a
// public, anonymised marketing preview at https://advocat.ee/s/<slug>.
//
// Two implementations live side-by-side here:
//
//   * `ShareResultService` — calls Supabase via `functions.invoke` for the
//     real round-trip. In demo mode (no Supabase credentials) we
//     short-circuit with a synthetic success so the UI flow can be
//     exercised in local builds without burning a backend call.
//
//   * `ShareResultPayload` (pure, static) — builds the request payload so
//     widget tests can lock in the client-side contract without
//     instantiating Supabase.
//
// The edge function performs the actual two-stage redaction (regex + Haiku)
// and stores the row in public.shared_results. The client receives back
// `{share_url, slug, preview}` and is responsible for opening the native
// share sheet via share_plus.
// ---------------------------------------------------------------------------

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Riverpod provider — stateless wrapper around `functions.invoke`.
final shareResultServiceProvider = Provider<ShareResultService>((ref) {
  return ShareResultService(ref.read(supabaseServiceProvider));
});

/// Wire-format source kinds. Must match the CHECK constraint on
/// public.shared_results.source_type and the VALID_SOURCES set in the
/// edge function.
enum ShareSourceType { contractReview, legalAdvice, deadlineAnalysis }

extension ShareSourceTypeWire on ShareSourceType {
  String get wireValue => switch (this) {
        ShareSourceType.contractReview => 'contract_review',
        ShareSourceType.legalAdvice => 'legal_advice',
        ShareSourceType.deadlineAnalysis => 'deadline_analysis',
      };
}

/// Snapshot of a single share. Returned by [ShareResultService.createShare].
class ShareResult {
  const ShareResult({
    required this.slug,
    required this.shareUrl,
    required this.title,
    required this.insightSummary,
  });

  final String slug;
  final String shareUrl;
  final String title;
  final String insightSummary;
}

/// Either an ok result or a typed failure code. Never throws on validation
/// or HTTP errors — only unrecoverable network failures surface as
/// `errorReason='network'`.
class ShareSubmitResult {
  const ShareSubmitResult.ok(this.share)
      : success = true,
        errorReason = null,
        errorMessage = null;

  const ShareSubmitResult.error(this.errorReason, this.errorMessage)
      : success = false,
        share = null;

  final bool success;
  final ShareResult? share;
  final String? errorReason;
  final String? errorMessage;
}

/// Pure helpers — no Supabase, safe to import from any unit test.
class ShareResultPayload {
  ShareResultPayload._();

  /// Strict UUID regex — matches the same shape the edge function accepts.
  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  static bool isValidSourceId(String? id) {
    if (id == null || id.isEmpty) return false;
    return _uuidRegex.hasMatch(id);
  }

  /// Build the JSON payload sent to the edge function. Throws
  /// [ArgumentError] for invalid input so the UI surfaces validation
  /// failures before a round-trip.
  static Map<String, dynamic> buildPayload({
    required ShareSourceType sourceType,
    required String sourceId,
  }) {
    if (!isValidSourceId(sourceId)) {
      throw ArgumentError('sourceId must be a UUID, got: $sourceId');
    }
    return <String, dynamic>{
      'source_type': sourceType.wireValue,
      'source_id': sourceId,
    };
  }
}

/// Live client. Demo mode (Supabase not initialised) short-circuits with a
/// synthetic success so widget tests + local dev builds can exercise the
/// happy-path flow without a backend.
class ShareResultService {
  ShareResultService(this._supabase);

  final SupabaseService _supabase;

  static const String _functionName = 'share-result';

  /// Submit a share request. Returns a typed [ShareSubmitResult].
  Future<ShareSubmitResult> createShare({
    required ShareSourceType sourceType,
    required String sourceId,
  }) async {
    if (!ShareResultPayload.isValidSourceId(sourceId)) {
      return const ShareSubmitResult.error('invalid_source_id', null);
    }

    if (_supabase.isDemo) {
      // Demo / offline build: return a synthetic share so the UI flow can
      // be exercised end-to-end.
      return const ShareSubmitResult.ok(
        ShareResult(
          slug: 'demoslug',
          shareUrl: 'https://advocat.ee/s/demoslug',
          title: 'Demo share',
          insightSummary:
              'This is a demo share — your real shares will look like this.',
        ),
      );
    }

    final payload = ShareResultPayload.buildPayload(
      sourceType: sourceType,
      sourceId: sourceId,
    );

    try {
      final res = await Supabase.instance.client.functions.invoke(
        _functionName,
        body: payload,
      );
      if (res.status >= 200 && res.status < 300) {
        final data = res.data;
        if (data is Map &&
            data['slug'] is String &&
            data['share_url'] is String) {
          final preview = (data['preview'] is Map)
              ? (data['preview'] as Map).cast<String, dynamic>()
              : <String, dynamic>{};
          return ShareSubmitResult.ok(
            ShareResult(
              slug: data['slug'] as String,
              shareUrl: data['share_url'] as String,
              title: (preview['title'] as String?) ?? 'Advocat — AI legal analysis',
              insightSummary: (preview['insight_summary'] as String?) ?? '',
            ),
          );
        }
        return const ShareSubmitResult.error('malformed_response', null);
      }
      final data = res.data;
      String? reason;
      String? errorMessage;
      if (data is Map) {
        reason = (data['reason'] as String?) ?? (data['error'] as String?);
        errorMessage = data['error'] as String?;
      }
      return ShareSubmitResult.error(
        reason ?? 'server_${res.status}',
        errorMessage,
      );
    } on FunctionException catch (e) {
      final body = e.details;
      String? reason;
      String? errorMessage;
      if (body is Map) {
        reason = (body['reason'] as String?) ?? (body['error'] as String?);
        errorMessage = body['error'] as String?;
      }
      return ShareSubmitResult.error(
        reason ?? 'server_${e.status}',
        errorMessage,
      );
    } catch (e) {
      // Total network failure (offline, DNS, etc.).
      return ShareSubmitResult.error('network', e.toString());
    }
  }

  /// Visible for tests — direct override of the Supabase wire-call helper.
  @visibleForTesting
  static const String wireFunctionName = _functionName;
}
