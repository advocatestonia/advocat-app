// legal_templates/models/legal_template.dart — Feature #5.
// -----------------------------------------------------------------------------
// Plain data models for the Legal Template Library. No Supabase dependency so
// they can be constructed in tests. Mirrors the `legal_templates` table from
// migration 20260601100000_legal_templates.sql.
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart' show immutable;

/// A single curated fill-in form (kantelu, valitus, kaebus …).
@immutable
class LegalTemplate {
  const LegalTemplate({
    required this.id,
    required this.slug,
    required this.category,
    required this.jurisdiction,
    required this.locale,
    required this.title,
    required this.description,
    this.bodyMarkdown = '',
    this.requiredFields = const <String>[],
    this.autoFields = const <String>[],
    this.isSample = true,
    this.sortOrder = 100,
  });

  final String id;
  final String slug;

  /// Broad grouping: complaint · appeal · application · claim · request.
  final String category;

  /// ISO-3166 alpha-2 ('FI' / 'EE').
  final String jurisdiction;

  /// Body locale ('fi' / 'et' / 'en' / 'ru').
  final String locale;

  final String title;
  final String description;

  /// Form body with `{{placeholder}}` tokens. Empty in gallery responses
  /// (we don't ship the full body to the list) — the edge fn reads it server
  /// side. Kept here for completeness / preview if ever selected.
  final String bodyMarkdown;

  /// Tokens the user must supply manually.
  final List<String> requiredFields;

  /// Tokens the edge fn fills from case/profile (documentation only).
  final List<String> autoFields;

  /// True for curated sample forms — UI marks them "sample / образец".
  final bool isSample;

  final int sortOrder;

  factory LegalTemplate.fromJson(Map<String, dynamic> json) {
    List<String> strList(dynamic raw) {
      if (raw is List) {
        return raw.whereType<String>().toList(growable: false);
      }
      return const <String>[];
    }

    return LegalTemplate(
      id: json['id'] as String,
      slug: json['slug'] as String,
      category: (json['category'] as String?) ?? 'request',
      jurisdiction: (json['jurisdiction'] as String?) ?? 'FI',
      locale: (json['locale'] as String?) ?? 'fi',
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      bodyMarkdown: (json['body_markdown'] as String?) ?? '',
      requiredFields: strList(json['required_fields']),
      autoFields: strList(json['auto_fields']),
      isSample: (json['is_sample'] as bool?) ?? true,
      sortOrder: (json['sort_order'] as int?) ?? 100,
    );
  }
}

/// Result of a successful `template-fill` edge-function call.
@immutable
class FilledTemplate {
  const FilledTemplate({
    required this.filled,
    required this.title,
    required this.slug,
    required this.jurisdiction,
    required this.locale,
    this.tokens = const <String>[],
    this.resolved = const <String>[],
    this.unresolved = const <String>[],
    this.requiredFields = const <String>[],
  });

  /// The substituted markdown ready to drop into a draft.
  final String filled;
  final String title;
  final String slug;
  final String jurisdiction;
  final String locale;

  final List<String> tokens;
  final List<String> resolved;

  /// Tokens still missing after the fill (rendered as a visible marker in
  /// [filled]). The UI can warn the user to complete them in the editor.
  final List<String> unresolved;

  final List<String> requiredFields;

  factory FilledTemplate.fromJson(Map<String, dynamic> json) {
    List<String> strList(dynamic raw) {
      if (raw is List) {
        return raw.whereType<String>().toList(growable: false);
      }
      return const <String>[];
    }

    return FilledTemplate(
      filled: (json['filled'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      slug: (json['slug'] as String?) ?? '',
      jurisdiction: (json['jurisdiction'] as String?) ?? '',
      locale: (json['locale'] as String?) ?? '',
      tokens: strList(json['tokens']),
      resolved: strList(json['resolved']),
      unresolved: strList(json['unresolved']),
      requiredFields: strList(json['required_fields']),
    );
  }
}

/// Pure helper: turns a snake_case token into a human label fallback
/// ("case_number" → "Case number"). Used when no localized label exists.
String humanizeToken(String token) {
  if (token.isEmpty) return token;
  final words = token.split('_').where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return token;
  final first = words.first;
  final capFirst = first[0].toUpperCase() + first.substring(1);
  return <String>[capFirst, ...words.skip(1)].join(' ');
}
