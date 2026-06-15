// demand_letter/services/demand_letter_service.dart — Feature #2.
// -----------------------------------------------------------------------------
// Thin layer over the `demand-letter` edge function (compose + persist) and the
// existing `pdf-generator` function (export). The service does NOT auto-send;
// e-mail hand-off is a separate, explicit user action in the UI.
//
// IO is behind an interface so widget tests can inject a fake.
// -----------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/demand_letter.dart';

/// Provider for the default Supabase-backed implementation.
final demandLetterServiceProvider = Provider<DemandLetterService>((ref) {
  return SupabaseDemandLetterService();
});

/// A generated, downloadable export of a demand letter.
class DemandLetterExport {
  const DemandLetterExport({required this.downloadUrl, required this.filename});

  final String downloadUrl;
  final String filename;
}

/// Public surface used by the wizard + preview screens.
abstract class DemandLetterService {
  /// Composes the letter and persists it. Returns the markdown + saved id.
  Future<DemandLetterResult> generate(DemandLetterRequest request);

  /// Renders [markdown] to a print-ready document via the existing
  /// `pdf-generator` function and returns the signed download URL.
  Future<DemandLetterExport> exportPdf({
    required String title,
    required String markdown,
    required String locale,
    String? caseId,
  });
}

/// Production implementation backed by Supabase.
class SupabaseDemandLetterService implements DemandLetterService {
  SupabaseDemandLetterService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<DemandLetterResult> generate(DemandLetterRequest request) async {
    final res = await _client.functions.invoke(
      'demand-letter',
      body: request.toJson(),
    );
    final data = res.data;
    if (data is! Map) {
      throw StateError('demand-letter returned unexpected payload: $data');
    }
    return DemandLetterResult.fromJson(data.cast<String, dynamic>());
  }

  @override
  Future<DemandLetterExport> exportPdf({
    required String title,
    required String markdown,
    required String locale,
    String? caseId,
  }) async {
    final res = await _client.functions.invoke(
      'pdf-generator',
      body: <String, dynamic>{
        'title': title,
        'body_markdown': markdown,
        'doc_type': 'letter',
        'locale': locale,
        if (caseId != null && caseId.isNotEmpty) 'case_id': caseId,
      },
    );
    final data = res.data;
    if (data is! Map || data['download_url'] == null) {
      throw StateError('pdf-generator returned no download_url: $data');
    }
    final map = data.cast<String, dynamic>();
    return DemandLetterExport(
      downloadUrl: map['download_url'] as String,
      filename: (map['filename'] as String?) ?? '$title.html',
    );
  }
}
