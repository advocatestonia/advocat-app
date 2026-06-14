// case_dossier_service.dart
// ---------------------------------------------------------------------------
// Thin client for the `case-dossier-export` Supabase edge function. Given a
// case id + a set of section toggles, it asks the backend to assemble a single
// PDF/HTML dossier (facts + chronology + deadlines + documents + AI summary)
// and returns a downloadable signed URL.
//
// The backend does ALL the work (aggregation, markdown assembly, render,
// storage, signed URL, case_documents row). This client only:
//   * builds the request payload (pure — `DossierExportPayload`), and
//   * invokes the function + maps the response (`CaseDossierService`).
//
// In demo mode (no Supabase) we short-circuit with a synthetic success so the
// preview flow can be exercised in local builds without a backend call.
// ---------------------------------------------------------------------------

import 'package:flutter/foundation.dart' show immutable, visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/supabase_service.dart';

/// Which whole sections to include in the dossier. The case header (facts) is
/// always included and is not toggleable.
@immutable
class DossierSectionToggles {
  const DossierSectionToggles({
    this.timeline = true,
    this.deadlines = true,
    this.documents = true,
    this.aiSummary = true,
  });

  final bool timeline;
  final bool deadlines;
  final bool documents;
  final bool aiSummary;

  DossierSectionToggles copyWith({
    bool? timeline,
    bool? deadlines,
    bool? documents,
    bool? aiSummary,
  }) {
    return DossierSectionToggles(
      timeline: timeline ?? this.timeline,
      deadlines: deadlines ?? this.deadlines,
      documents: documents ?? this.documents,
      aiSummary: aiSummary ?? this.aiSummary,
    );
  }

  Map<String, dynamic> toJson() => {
        'timeline': timeline,
        'deadlines': deadlines,
        'documents': documents,
        'aiSummary': aiSummary,
      };
}

/// Pure payload builder — kept separate from the service so widget tests can
/// lock in the client-side contract without instantiating Supabase.
@immutable
class DossierExportPayload {
  const DossierExportPayload._();

  static Map<String, dynamic> build({
    required String caseId,
    required DossierSectionToggles sections,
    String? locale,
  }) {
    final body = <String, dynamic>{
      'case_id': caseId,
      'sections': sections.toJson(),
    };
    if (locale != null && locale.trim().isNotEmpty) {
      body['locale'] = locale.trim();
    }
    return body;
  }
}

/// Result of a dossier export. On success [downloadUrl] is a time-limited
/// signed URL the UI hands to the OS / browser.
@immutable
class DossierExportResult {
  const DossierExportResult({
    required this.ok,
    this.downloadUrl,
    this.filename,
    this.errorCode,
  });

  final bool ok;
  final String? downloadUrl;
  final String? filename;
  final String? errorCode;

  factory DossierExportResult.success(String url, String? filename) =>
      DossierExportResult(ok: true, downloadUrl: url, filename: filename);

  factory DossierExportResult.failure(String code) =>
      DossierExportResult(ok: false, errorCode: code);
}

const String _functionName = 'case-dossier-export';

/// Riverpod provider — stateless wrapper around the edge function.
final caseDossierServiceProvider = Provider<CaseDossierService>((ref) {
  return CaseDossierService(ref.read(supabaseServiceProvider));
});

class CaseDossierService {
  CaseDossierService(this._supabase);

  final SupabaseService _supabase;

  /// Visible for tests — lets a fake [SupabaseService] be injected.
  @visibleForTesting
  CaseDossierService.forTest(this._supabase);

  Future<DossierExportResult> export({
    required String caseId,
    required DossierSectionToggles sections,
    String? locale,
  }) async {
    if (_supabase.isDemo) {
      return DossierExportResult.success(
        'https://advocat.ee/demo/dossier.pdf',
        'case_dossier.pdf',
      );
    }

    final payload = DossierExportPayload.build(
      caseId: caseId,
      sections: sections,
      locale: locale,
    );

    final Map<String, dynamic>? data = await _supabase.callEdgeFunction(
      _functionName,
      body: payload,
    );

    if (data == null) {
      return DossierExportResult.failure('no_response');
    }
    final err = data['error'];
    if (err is String && err.isNotEmpty) {
      return DossierExportResult.failure(err);
    }
    final url = data['download_url'];
    if (url is String && url.isNotEmpty) {
      final filename = data['filename'];
      return DossierExportResult.success(
        url,
        filename is String ? filename : null,
      );
    }
    return DossierExportResult.failure('malformed_response');
  }
}
