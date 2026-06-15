// =============================================================================
// explain_result.dart — typed model for the Plain-Language Explainer response.
// =============================================================================
//
// Mirrors the JSON shape returned by supabase/functions/explain-plain/index.ts:
//   {
//     explain_request_id: string | null,
//     explanation: { tldr, paragraphs, glossary, next_steps },
//     language: string,
//     level: "friend" | "with_terms",
//     quota: { used: int | null, limit: int | null, tier: string }
//   }
//
// Parsing is defensive: any malformed sub-entry is dropped rather than thrown,
// so a single bad row from the model never breaks the whole screen.
// =============================================================================

/// The mode the user picked for the explanation.
enum ExplainLevel {
  /// "Как другу" — A2/B1 readability, no jargon.
  friend,

  /// "С юр-терминами" — plain but keeps key legal terms + glossary.
  withTerms;

  String get wire => this == ExplainLevel.friend ? 'friend' : 'with_terms';

  static ExplainLevel fromWire(String? v) =>
      v == 'with_terms' ? ExplainLevel.withTerms : ExplainLevel.friend;
}

/// One contentious legal term explained plainly, with an optional corpus ref.
class ExplainGlossaryEntry {
  const ExplainGlossaryEntry({
    required this.term,
    required this.plain,
    this.ref,
  });

  final String term;
  final String plain;

  /// Optional corpus slug (e.g. "fi-ulkomaalaislaki:148") for a deep link.
  final String? ref;

  static ExplainGlossaryEntry? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final term = (raw['term'] as String?)?.trim() ?? '';
    final plain = (raw['plain'] as String?)?.trim() ?? '';
    if (term.isEmpty || plain.isEmpty) return null;
    final ref = (raw['ref'] as String?)?.trim();
    return ExplainGlossaryEntry(
      term: term,
      plain: plain,
      ref: (ref == null || ref.isEmpty) ? null : ref,
    );
  }
}

/// One explained section of the source document.
class ExplainParagraph {
  const ExplainParagraph({required this.heading, required this.plain});

  final String heading;
  final String plain;

  static ExplainParagraph? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final plain = (raw['plain'] as String?)?.trim() ?? '';
    if (plain.isEmpty) return null;
    final heading = (raw['heading'] as String?)?.trim() ?? '';
    return ExplainParagraph(heading: heading, plain: plain);
  }
}

/// The structured explanation body.
class ExplainBody {
  const ExplainBody({
    required this.tldr,
    required this.paragraphs,
    required this.glossary,
    required this.nextSteps,
  });

  final List<String> tldr;
  final List<ExplainParagraph> paragraphs;
  final List<ExplainGlossaryEntry> glossary;
  final List<String> nextSteps;

  bool get isEmpty =>
      tldr.isEmpty &&
      paragraphs.isEmpty &&
      glossary.isEmpty &&
      nextSteps.isEmpty;

  static List<String> _stringList(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
  }

  factory ExplainBody.fromJson(Map<String, dynamic> json) {
    final paragraphs = <ExplainParagraph>[];
    final rawParas = json['paragraphs'];
    if (rawParas is List) {
      for (final p in rawParas) {
        final parsed = ExplainParagraph.tryParse(p);
        if (parsed != null) paragraphs.add(parsed);
      }
    }
    final glossary = <ExplainGlossaryEntry>[];
    final rawGloss = json['glossary'];
    if (rawGloss is List) {
      for (final g in rawGloss) {
        final parsed = ExplainGlossaryEntry.tryParse(g);
        if (parsed != null) glossary.add(parsed);
      }
    }
    return ExplainBody(
      tldr: _stringList(json['tldr']),
      paragraphs: paragraphs,
      glossary: glossary,
      nextSteps: _stringList(json['next_steps']),
    );
  }
}

/// Quota state echoed back by the endpoint. `used`/`limit` are null for Pro.
class ExplainQuota {
  const ExplainQuota({this.used, this.limit, required this.tier});

  final int? used;
  final int? limit;
  final String tier;

  bool get isPro => tier != 'free';

  factory ExplainQuota.fromJson(Map<String, dynamic> json) => ExplainQuota(
        used: json['used'] as int?,
        limit: json['limit'] as int?,
        tier: (json['tier'] as String?) ?? 'free',
      );
}

/// The full successful response.
class ExplainResult {
  const ExplainResult({
    required this.id,
    required this.body,
    required this.language,
    required this.level,
    required this.quota,
  });

  final String? id;
  final ExplainBody body;
  final String language;
  final ExplainLevel level;
  final ExplainQuota quota;

  factory ExplainResult.fromJson(Map<String, dynamic> json) => ExplainResult(
        id: json['explain_request_id'] as String?,
        body: ExplainBody.fromJson(
          (json['explanation'] as Map?)?.cast<String, dynamic>() ??
              const <String, dynamic>{},
        ),
        language: (json['language'] as String?) ?? 'en',
        level: ExplainLevel.fromWire(json['level'] as String?),
        quota: ExplainQuota.fromJson(
          (json['quota'] as Map?)?.cast<String, dynamic>() ??
              const <String, dynamic>{},
        ),
      );
}

/// Thrown when a free user is over their monthly cap (HTTP 402).
class ExplainQuotaExceeded implements Exception {
  const ExplainQuotaExceeded(this.quota);
  final ExplainQuota quota;
}
