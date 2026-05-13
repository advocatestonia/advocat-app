import 'dart:async';

import 'package:dio/dio.dart';

import '../config/app_config.dart';

// ---------------------------------------------------------------------------
// LawSearchClient — thin client for the `law-search` Supabase Edge Function
// ---------------------------------------------------------------------------
//
// P0-3 (Advocat legal-brain rebuild, 2026-05-05). The client posts a query +
// language to a vector-search endpoint and returns a list of [LawChunk]s,
// each carrying the act name, paragraph, body text, similarity score, and
// (optional) source URL.
//
// Design notes:
//   • No retries. The edge function is idempotent and we want hard upper
//     bound on the chat-turn latency budget. Three back-to-back 3 s timeouts
//     would be far worse than a single fast no-op.
//   • Soft-fail: every error path (network, timeout, 4xx, 5xx, malformed
//     body) collapses to `<empty list>`. The caller (claude_service.dart)
//     uses an empty list as a no-op signal so the chat continues without
//     RAG injection. NEVER let a search failure break a chat turn.
//   • Endpoint & auth come from [AppConfig]; in local dev with no Supabase
//     URL/key the client still returns an empty list quietly.
//   • Until P0-2 deploys the function this whole path is dormant and
//     `search()` simply returns [] after a single failed POST. That's
//     intentional — it's the graceful-fallback contract.
// ---------------------------------------------------------------------------

/// One paragraph chunk returned from the `law-search` endpoint.
class LawChunk {
  /// Native short name of the act (e.g. "KarS", "HMS", "Rikoslaki").
  final String actName;

  /// Paragraph identifier inside the act (e.g. "§ 121", "§ 26 lg 3").
  final String paragraph;

  /// Body text of the chunk — verbatim, possibly translated to user language
  /// at server side. The chat layer is required to cite this verbatim and
  /// MUST NOT paraphrase the § number.
  final String body;

  /// Cosine similarity score in `[0.0, 1.0]`. Used by the chunk-budgeting
  /// path to drop the lowest-similarity chunks first when the system prompt
  /// is approaching the 200 KB cap.
  final double similarity;

  /// Optional canonical source URL (Riigi Teataja, Finlex, EUR-Lex).
  final String? sourceUrl;

  /// `law_chunks.id` — deterministic id of the row, e.g. `"tls-§88-1"`.
  /// Pkg 2 (Citations API): the chat client passes this through to
  /// claude-proxy in `rag_context.chunks[*].id` so the grounding verifier
  /// can resolve `[[ref:tls:88]]` markers to a concrete chunk row.
  final String? id;

  /// `law_chunks.act_slug` — lowercase short slug used inside the marker
  /// syntax (`[[ref:tls:88]]`). Optional for back-compat with callers that
  /// haven't been wired through the `act_slug` field yet (e.g. legacy
  /// tests). When null, the marker directive is omitted from
  /// formatLawContext for that chunk and the verifier cannot match it.
  final String? actSlug;

  /// `law_chunks.jurisdiction` — EE / FI / EU / RU / DE. Pkg 2: passed
  /// through to the verifier so EU markers resolve via CELEX-id.
  final String? jurisdiction;

  /// `law_chunks.in_force` — false flips the verifier status to
  /// `historical`. Defaults to `true` in fromJson for back-compat with
  /// today's law-search response (which only emits `in_force = true`
  /// rows via the partial unique index in 20260507_06).
  final bool? inForce;

  const LawChunk({
    required this.actName,
    required this.paragraph,
    required this.body,
    required this.similarity,
    this.sourceUrl,
    this.id,
    this.actSlug,
    this.jurisdiction,
    this.inForce,
  });

  /// Approximate byte cost in the system prompt. Used by the budget-trim
  /// path so we don't have to render every chunk to measure the cost.
  /// Conservative: header + body + URL + formatting overhead.
  int approximateBytes() {
    final urlLen = sourceUrl?.length ?? 0;
    final slugLen = actSlug?.length ?? 0;
    return actName.length + paragraph.length + body.length + urlLen + slugLen + 64;
  }

  factory LawChunk.fromJson(Map<String, dynamic> json) {
    final sim = json['similarity'];
    final score = sim is num ? sim.toDouble() : 0.0;
    final url = json['source_url'];
    final id = json['id'];
    final slug = json['act_slug'];
    final jur = json['jurisdiction'];
    final inForceRaw = json['in_force'];
    return LawChunk(
      actName: (json['act_name'] as String?) ?? '',
      paragraph: (json['paragraph'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      similarity: score.clamp(0.0, 1.0),
      sourceUrl: url is String && url.isNotEmpty ? url : null,
      id: id is String && id.isNotEmpty ? id : null,
      actSlug: slug is String && slug.isNotEmpty ? slug : null,
      jurisdiction: jur is String && jur.isNotEmpty ? jur : null,
      inForce: inForceRaw is bool ? inForceRaw : null,
    );
  }

  /// Serialise back to the JSON shape claude-proxy expects in
  /// `rag_context.chunks` (Pkg 2). Mirror of `fromJson`. We leave the
  /// `body` whole — the verifier truncates to ≤400 chars on its end.
  Map<String, dynamic> toRagContextJson() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      if (actSlug != null) 'act_slug': actSlug,
      'act_name': actName,
      'paragraph': _markerParagraph(),
      'body': body,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (jurisdiction != null) 'jurisdiction': jurisdiction,
      if (inForce != null) 'in_force': inForce,
    };
  }

  /// Strip the leading "§" / whitespace so the value is the marker-friendly
  /// form ("88") rather than the human-readable form ("§ 88"). Used both
  /// by the rag_context payload and by formatLawContext when it shows the
  /// `paragraph: …` annotation.
  String _markerParagraph() {
    var p = paragraph.trim();
    if (p.startsWith('§')) {
      p = p.substring(1).trim();
    }
    return p;
  }

  /// Public accessor for the marker-friendly paragraph form. Exposed so
  /// callers (system prompt builder, claude_service) don't have to repeat
  /// the same § strip everywhere.
  String get markerParagraph => _markerParagraph();
}

/// Static client. No instance state — every call constructs its own Dio so
/// tests can inject without a singleton dependency.
abstract final class LawSearchClient {
  /// Default similarity threshold. Chunks below this are dropped server-side.
  static const double defaultSimilarityThreshold = 0.60;

  /// Default chunk count per query. P0-3 spec: 8.
  static const int defaultMatchCount = 8;

  /// Default per-call timeout. The chat path budgets 3 s for RAG and falls
  /// back to no-op on timeout — never block the user past that.
  static const Duration defaultTimeout = Duration(seconds: 3);

  /// Search for relevant law paragraphs.
  ///
  /// Returns an empty list on any error (network, timeout, non-200, malformed
  /// body, missing config). Callers MUST treat empty as "no RAG, skip
  /// injection" and continue the chat turn unchanged.
  ///
  /// [queryJurisdiction] — optional ISO 3166-1 alpha-2 code (EE, FI, EU, ...)
  /// to scope retrieval to one jurisdiction. When null, the RPC's default
  /// is used (search every jurisdiction). EU directives are always
  /// included regardless of the value (the RPC does `lc.lang like 'eu_%'`
  /// unconditionally). Added 2026-05-11 for the Finnish corpus.
  ///
  /// [dio] — optional injected Dio for tests. Production calls leave it null.
  static Future<List<LawChunk>> search({
    required String query,
    required String lang,
    int matchCount = defaultMatchCount,
    double similarityThreshold = defaultSimilarityThreshold,
    Duration timeout = defaultTimeout,
    String? queryJurisdiction,
    Dio? dio,
  }) async {
    // Empty query / no Supabase config — degrade silently.
    if (query.trim().isEmpty) return const [];
    if (AppConfig.supabaseUrl.isEmpty || AppConfig.supabaseAnonKey.isEmpty) {
      return const [];
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
      final body = <String, dynamic>{
        'query': query,
        'lang': lang,
        'match_count': matchCount,
        'similarity_threshold': similarityThreshold,
      };
      // Only include the jurisdiction key when set so back-compat with
      // the edge function's current shape is preserved. The edge fn
      // ignores unknown keys, but omission keeps the wire-format diff
      // minimal until the server-side validator is taught about it.
      if (queryJurisdiction != null && queryJurisdiction.isNotEmpty) {
        body['query_jurisdiction'] = queryJurisdiction.toUpperCase();
      }
      final resp = await client
          .post<dynamic>(
            '/law-search',
            data: body,
          )
          .timeout(timeout);
      return _parseResponse(resp.data);
    } on TimeoutException {
      return const [];
    } on DioException {
      // 4xx, 5xx, network errors — graceful no-op.
      return const [];
    } catch (_) {
      // Anything else (JSON shape, type errors) — graceful no-op.
      return const [];
    }
  }

  /// Pure parser, exposed so tests can pin the wire-format contract without
  /// instantiating Dio. Accepts either a top-level list or an object with a
  /// `chunks` key — the edge function's exact shape is owned by P0-2 so we
  /// stay tolerant.
  static List<LawChunk> parseResponse(Object? data) => _parseResponse(data);

  static List<LawChunk> _parseResponse(Object? data) {
    if (data == null) return const [];
    List<dynamic>? raw;
    if (data is List) {
      raw = data;
    } else if (data is Map<String, dynamic>) {
      final candidate = data['chunks'] ?? data['results'] ?? data['data'];
      if (candidate is List) raw = candidate;
    }
    if (raw == null) return const [];
    final out = <LawChunk>[];
    for (final entry in raw) {
      if (entry is Map<String, dynamic>) {
        out.add(LawChunk.fromJson(entry));
      } else if (entry is Map) {
        out.add(LawChunk.fromJson(Map<String, dynamic>.from(entry)));
      }
    }
    return out;
  }
}
