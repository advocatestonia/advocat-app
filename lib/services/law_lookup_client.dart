import 'dart:async';

import 'package:dio/dio.dart';

import '../config/app_config.dart';

// ---------------------------------------------------------------------------
// LawLookupClient — thin client for the `law-lookup` Supabase Edge Function
// ---------------------------------------------------------------------------
//
// Phase 2 Pkg 1+2 (Advocat legal-brain rebuild). Mirror of [LawSearchClient]
// but for EXACT statute lookups: the user names a specific § ("what does
// KarS § 121 say verbatim?") and we hit the `lookup_statute(act_slug,
// paragraph, jurisdiction)` RPC directly — no embedding, no semantic
// search, no LLM round-trip.
//
// Design notes (same constraints as law_search_client.dart):
//   • No retries. The lookup is idempotent and we want a hard upper bound
//     on the chat-turn latency budget.
//   • Soft-fail: every error path (network, timeout, 4xx, 5xx, malformed
//     body, missing config) collapses to `null`. The caller treats null
//     as "not in our bundled corpus" and asks the model to fall back.
//   • Endpoint & auth come from [AppConfig]; in local dev with no Supabase
//     URL/key the client returns null quietly.
// ---------------------------------------------------------------------------

/// One statute lookup result returned from the `law-lookup` endpoint.
///
/// Modelled separately from [LawChunk] because lookup carries
/// `versionDate` (statutes are versioned) and never carries `similarity`
/// (this is exact match, not semantic).
class StatuteLookup {
  /// Stable corpus id (e.g. `"tls-§88-0"`).
  final String id;

  /// Lower-case slug of the act (e.g. `"kars"`, `"hms"`).
  final String actSlug;

  /// Native short name (e.g. `"KarS"`, `"HMS"`, `"Rikoslaki"`).
  final String actName;

  /// Paragraph identifier (e.g. `"121"`, `"40 lg 3"`).
  final String paragraph;

  /// Optional human-readable section title.
  final String? title;

  /// Verbatim body text — must be cited exactly, never paraphrased.
  final String body;

  /// Optional canonical source URL (Riigi Teataja, Finlex, EUR-Lex).
  final String? sourceUrl;

  /// Effective version date of this statute revision (ISO-8601 string),
  /// or null if the corpus row didn't carry it.
  final String? versionDate;

  /// One of `EE`, `FI`, `EU` (matches the migration's check constraint).
  final String jurisdiction;

  const StatuteLookup({
    required this.id,
    required this.actSlug,
    required this.actName,
    required this.paragraph,
    required this.body,
    required this.jurisdiction,
    this.title,
    this.sourceUrl,
    this.versionDate,
  });

  factory StatuteLookup.fromJson(Map<String, dynamic> json) {
    final url = json['source_url'];
    final ttl = json['title'];
    final ver = json['version_date'];
    return StatuteLookup(
      id: (json['id'] as String?) ?? '',
      actSlug: (json['act_slug'] as String?) ?? '',
      actName: (json['act_name'] as String?) ?? '',
      paragraph: (json['paragraph'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      jurisdiction: (json['jurisdiction'] as String?) ?? 'EE',
      title: ttl is String && ttl.isNotEmpty ? ttl : null,
      sourceUrl: url is String && url.isNotEmpty ? url : null,
      versionDate: ver is String && ver.isNotEmpty ? ver : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'act_slug': actSlug,
        'act_name': actName,
        'paragraph': paragraph,
        if (title != null) 'title': title,
        'body': body,
        if (sourceUrl != null) 'source_url': sourceUrl,
        if (versionDate != null) 'version_date': versionDate,
        'jurisdiction': jurisdiction,
      };
}

/// Static client. Same shape as [LawSearchClient] for consistency and to
/// keep test patterns aligned (Dio injection, no instance state).
abstract final class LawLookupClient {
  /// Default per-call timeout. The chat path budgets 3 s for tool round-
  /// trips and falls back to null on timeout.
  static const Duration defaultTimeout = Duration(seconds: 3);

  /// Allowed jurisdiction codes (matches the edge function whitelist).
  static const Set<String> supportedJurisdictions = {'EE', 'FI', 'EU'};

  /// Look up an exact statute paragraph.
  ///
  /// Returns `null` on any error (network, timeout, non-200, malformed
  /// body, missing config, statute not in corpus). Callers MUST treat
  /// null as "not in our corpus, fall back to web_search or admit
  /// ignorance" and continue the chat turn unchanged.
  ///
  /// [dio] — optional injected Dio for tests. Production calls leave it
  /// null.
  static Future<StatuteLookup?> lookup({
    required String act,
    required String paragraph,
    String jurisdiction = 'EE',
    Duration timeout = defaultTimeout,
    Dio? dio,
  }) async {
    final actT = act.trim();
    final paraT = paragraph.trim();
    final jurT = jurisdiction.trim().toUpperCase();

    // Local validation — never POST when we know the call will 400.
    if (actT.isEmpty || paraT.isEmpty) return null;
    if (!supportedJurisdictions.contains(jurT)) return null;
    if (AppConfig.supabaseUrl.isEmpty || AppConfig.supabaseAnonKey.isEmpty) {
      return null;
    }

    final client = dio ??
        Dio(BaseOptions(
          baseUrl: '${AppConfig.supabaseUrl}/functions/v1',
          connectTimeout: timeout,
          receiveTimeout: timeout,
          sendTimeout: timeout,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          },
        ));

    try {
      final resp = await client
          .post<dynamic>(
            '/law-lookup',
            data: <String, dynamic>{
              'act': actT,
              'paragraph': paraT,
              'jurisdiction': jurT,
            },
          )
          .timeout(timeout);
      return parseResponse(resp.data);
    } on TimeoutException {
      return null;
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Pure parser, exposed so tests can pin the wire-format contract
  /// without instantiating Dio. Edge function returns `{statute: {...}}`
  /// or `{statute: null}`. We accept both that and a bare statute object
  /// for tolerance.
  static StatuteLookup? parseResponse(Object? data) {
    if (data == null) return null;
    Map<String, dynamic>? statuteJson;
    if (data is Map<String, dynamic>) {
      final candidate = data['statute'];
      if (candidate == null) {
        // {statute: null} — explicit "not found" wire shape.
        if (data.containsKey('statute')) return null;
        // Bare object — fall back to treating data itself as the statute.
        statuteJson = data;
      } else if (candidate is Map<String, dynamic>) {
        statuteJson = candidate;
      } else if (candidate is Map) {
        statuteJson = Map<String, dynamic>.from(candidate);
      }
    } else if (data is Map) {
      // Untyped map (e.g. Map<dynamic,dynamic> from JSON decode). Coerce.
      final m = Map<String, dynamic>.from(data);
      return parseResponse(m);
    }
    if (statuteJson == null) return null;
    // Minimum viable row must have a body.
    final body = statuteJson['body'];
    if (body is! String || body.isEmpty) return null;
    return StatuteLookup.fromJson(statuteJson);
  }
}
