// legal_templates/services/legal_template_service.dart — Feature #5.
// -----------------------------------------------------------------------------
// Thin layer over the `legal_templates` table (read-only) and the
// `template-fill` edge function. The service deliberately does NOT touch the
// drafting tables itself — once a template is filled it hands the markdown back
// so the caller can persist it via the existing `DraftService.createDraft`,
// reusing the established PDF/DOCX export pipeline.
//
// IO is behind an interface so widget tests can inject a fake.
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/legal_template.dart';

/// Provider for the default Supabase-backed implementation.
final legalTemplateServiceProvider = Provider<LegalTemplateService>((ref) {
  return SupabaseLegalTemplateService();
});

/// Public surface used by the gallery + fill screens.
abstract class LegalTemplateService {
  /// Lists templates, optionally filtered by [jurisdiction] ('FI'/'EE') and/or
  /// [category]. Ordered by (jurisdiction, sort_order).
  Future<List<LegalTemplate>> listTemplates({
    String? jurisdiction,
    String? category,
  });

  /// Calls the `template-fill` edge function and returns the filled markdown.
  ///
  /// [templateId] may be a uuid or a slug. [caseId] is optional; when supplied
  /// the server auto-fills case_number / migri_ref from a case the user owns.
  /// [fields] supplies values for the template's required (manual) tokens.
  Future<FilledTemplate> fillTemplate({
    required String templateId,
    String? caseId,
    Map<String, String> fields = const <String, String>{},
  });
}

/// Production implementation backed by Supabase.
class SupabaseLegalTemplateService implements LegalTemplateService {
  SupabaseLegalTemplateService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<LegalTemplate>> listTemplates({
    String? jurisdiction,
    String? category,
  }) async {
    var query = _client.from('legal_templates').select(
          'id, slug, category, jurisdiction, locale, title, description, '
          'required_fields, auto_fields, is_sample, sort_order',
        );
    if (jurisdiction != null && jurisdiction.isNotEmpty) {
      query = query.eq('jurisdiction', jurisdiction);
    }
    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }
    final rows = await query
        .order('jurisdiction', ascending: true)
        .order('sort_order', ascending: true);
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(LegalTemplate.fromJson)
        .toList(growable: false);
  }

  @override
  Future<FilledTemplate> fillTemplate({
    required String templateId,
    String? caseId,
    Map<String, String> fields = const <String, String>{},
  }) async {
    final res = await _client.functions.invoke(
      'template-fill',
      body: <String, dynamic>{
        'template_id': templateId,
        if (caseId != null && caseId.isNotEmpty) 'case_id': caseId,
        if (fields.isNotEmpty) 'fields': fields,
      },
    );
    final data = res.data;
    if (data is! Map) {
      throw StateError('template-fill returned unexpected payload: $data');
    }
    return FilledTemplate.fromJson(data.cast<String, dynamic>());
  }
}

/// Returns the current user id, or null when signed out / Supabase not ready.
/// Test-only override hook so widget tests don't need to boot Supabase.
@visibleForTesting
String? Function()? debugLegalTemplateUserIdAccessor;

String? currentLegalTemplateUserId() {
  final override = debugLegalTemplateUserIdAccessor;
  if (override != null) return override();
  try {
    return Supabase.instance.client.auth.currentUser?.id;
  } catch (_) {
    return null;
  }
}
