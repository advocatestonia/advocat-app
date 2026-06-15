// =============================================================================
// explain_service.dart — thin client for the explain-plain edge function.
// =============================================================================
//
// One method: explain(). Posts the source text + chosen level to the
// `explain-plain` edge function and maps the response into ExplainResult.
//
// Error mapping:
//   * HTTP 402 / { error: "quota_exceeded" } → throws ExplainQuotaExceeded so
//     the screen can show the upgrade path.
//   * Anything else non-200 → StateError with the server message.
//
// The Supabase Functions client attaches the user's JWT automatically; the
// edge function rejects anonymous callers, so a logged-out user can never
// reach it (the screen is also behind the authed shell route).
// =============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/explain_result.dart';

class ExplainService {
  ExplainService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Requests a plain-language explanation of [sourceText].
  ///
  /// [language] omitted → the server auto-detects from the text (17 locales).
  /// Throws [ExplainQuotaExceeded] on 402, [StateError] on other failures.
  Future<ExplainResult> explain({
    required String sourceText,
    required ExplainLevel level,
    String? language,
    String? caseId,
    String? sourceDocumentId,
  }) async {
    final FunctionResponse res;
    try {
      res = await _client.functions.invoke(
        'explain-plain',
        body: <String, dynamic>{
          'source_text': sourceText,
          'level': level.wire,
          if (language != null && language.isNotEmpty) 'language': language,
          if (caseId != null && caseId.isNotEmpty) 'case_id': caseId,
          if (sourceDocumentId != null && sourceDocumentId.isNotEmpty)
            'source_document_id': sourceDocumentId,
        },
      );
    } on FunctionException catch (e) {
      // The supabase-flutter client throws FunctionException for non-2xx; the
      // JSON error body lives in `details`. Detect the quota case there.
      final details = e.details;
      if (e.status == 402 ||
          (details is Map && details['error'] == 'quota_exceeded')) {
        throw ExplainQuotaExceeded(_quotaFromDetails(details));
      }
      throw StateError(_messageFromDetails(details, e.status));
    }

    final data = res.data;
    if (data is! Map) {
      throw StateError('explain-plain returned unexpected payload: $data');
    }
    final map = data.cast<String, dynamic>();
    // A 200 body may still carry a quota_exceeded marker if the client did not
    // surface the status — handle defensively.
    if (map['error'] == 'quota_exceeded') {
      throw ExplainQuotaExceeded(
        ExplainQuota.fromJson(
          (map['quota'] as Map?)?.cast<String, dynamic>() ??
              const <String, dynamic>{},
        ),
      );
    }
    return ExplainResult.fromJson(map);
  }

  ExplainQuota _quotaFromDetails(Object? details) {
    if (details is Map && details['quota'] is Map) {
      return ExplainQuota.fromJson(
        (details['quota'] as Map).cast<String, dynamic>(),
      );
    }
    return const ExplainQuota(used: null, limit: null, tier: 'free');
  }

  String _messageFromDetails(Object? details, int status) {
    if (details is Map && details['error'] is String) {
      return details['error'] as String;
    }
    return 'explain-plain failed ($status)';
  }
}
