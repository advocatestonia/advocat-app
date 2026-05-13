// drafting/models/draft_model.dart — Pkg 7 Drafting Studio MVP.
// -----------------------------------------------------------------------------
// Plain data models for the drafting feature. No dependency on Supabase here
// so they can be constructed in tests without a backend stub.
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart' show immutable;

/// Where a draft came from. Mirrors the CHECK constraint in
/// `migration 20260514130000_drafting_studio.sql`.
enum DraftSourceType {
  blank,
  contractReviewReply,
  letter,
  appeal,
  memo;

  /// Postgres wire value (snake_case).
  String get wire {
    switch (this) {
      case DraftSourceType.blank:
        return 'blank';
      case DraftSourceType.contractReviewReply:
        return 'contract_review_reply';
      case DraftSourceType.letter:
        return 'letter';
      case DraftSourceType.appeal:
        return 'appeal';
      case DraftSourceType.memo:
        return 'memo';
    }
  }

  static DraftSourceType fromWire(String? raw) {
    switch (raw) {
      case 'contract_review_reply':
        return DraftSourceType.contractReviewReply;
      case 'letter':
        return DraftSourceType.letter;
      case 'appeal':
        return DraftSourceType.appeal;
      case 'memo':
        return DraftSourceType.memo;
      case 'blank':
      default:
        return DraftSourceType.blank;
    }
  }
}

/// Lifecycle status of a draft. Mirrors the CHECK constraint in the migration.
enum DraftStatus {
  draft,
  finalized,
  sent,
  archived;

  String get wire {
    switch (this) {
      case DraftStatus.draft:
        return 'draft';
      case DraftStatus.finalized:
        return 'finalized';
      case DraftStatus.sent:
        return 'sent';
      case DraftStatus.archived:
        return 'archived';
    }
  }

  static DraftStatus fromWire(String? raw) {
    switch (raw) {
      case 'finalized':
        return DraftStatus.finalized;
      case 'sent':
        return DraftStatus.sent;
      case 'archived':
        return DraftStatus.archived;
      case 'draft':
      default:
        return DraftStatus.draft;
    }
  }
}

/// A single drafting-studio document.
@immutable
class Draft {
  const Draft({
    required this.id,
    required this.userId,
    this.caseId,
    this.sourceType = DraftSourceType.blank,
    this.sourceId,
    this.title,
    this.contentMarkdown = '',
    this.contentPlaintext = '',
    this.language,
    this.jurisdiction,
    this.status = DraftStatus.draft,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final String userId;
  final String? caseId;
  final DraftSourceType sourceType;
  final String? sourceId;
  final String? title;
  final String contentMarkdown;
  final String contentPlaintext;
  final String? language;
  final String? jurisdiction;
  final DraftStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  /// True iff the draft has no body text. Drives the "Empty state" CTA on
  /// the editor screen.
  bool get isEmpty => contentMarkdown.trim().isEmpty;

  /// Display label for the drafts list. Falls back to a translated "Untitled"
  /// at the call-site (we keep this getter localisation-free).
  String displayTitle({String untitledFallback = 'Untitled'}) {
    final t = title?.trim();
    if (t == null || t.isEmpty) return untitledFallback;
    return t;
  }

  Draft copyWith({
    String? id,
    String? userId,
    String? caseId,
    DraftSourceType? sourceType,
    String? sourceId,
    String? title,
    String? contentMarkdown,
    String? contentPlaintext,
    String? language,
    String? jurisdiction,
    DraftStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Draft(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      caseId: caseId ?? this.caseId,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      title: title ?? this.title,
      contentMarkdown: contentMarkdown ?? this.contentMarkdown,
      contentPlaintext: contentPlaintext ?? this.contentPlaintext,
      language: language ?? this.language,
      jurisdiction: jurisdiction ?? this.jurisdiction,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'user_id': userId,
        'case_id': caseId,
        'source_type': sourceType.wire,
        'source_id': sourceId,
        'title': title,
        'content_markdown': contentMarkdown,
        'content_plaintext': contentPlaintext,
        'language': language,
        'jurisdiction': jurisdiction,
        'status': status.wire,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'metadata': metadata,
      };

  factory Draft.fromJson(Map<String, dynamic> json) {
    return Draft(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      caseId: json['case_id'] as String?,
      sourceType: DraftSourceType.fromWire(json['source_type'] as String?),
      sourceId: json['source_id'] as String?,
      title: json['title'] as String?,
      contentMarkdown: (json['content_markdown'] as String?) ?? '',
      contentPlaintext: (json['content_plaintext'] as String?) ?? '',
      language: json['language'] as String?,
      jurisdiction: json['jurisdiction'] as String?,
      status: DraftStatus.fromWire(json['status'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      metadata:
          ((json['metadata'] as Map?)?.cast<String, dynamic>()) ??
              const <String, dynamic>{},
    );
  }
}

/// Pure helper to derive plaintext from markdown (strips common syntax).
/// Kept top-level so widget tests can verify behaviour without spinning up
/// any database / editor state.
String markdownToPlaintext(String md) {
  if (md.isEmpty) return '';
  var out = md;
  // Strip ATX headings markers.
  out = out.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');
  // Strip bold / italic markers without nuking the inner text.
  out = out.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => m.group(1) ?? '');
  out = out.replaceAllMapped(RegExp(r'__(.+?)__'), (m) => m.group(1) ?? '');
  out = out.replaceAllMapped(RegExp(r'\*(.+?)\*'), (m) => m.group(1) ?? '');
  out = out.replaceAllMapped(RegExp(r'_(.+?)_'), (m) => m.group(1) ?? '');
  // Bullet / number list markers.
  out = out.replaceAll(RegExp(r'^\s*[-*]\s+', multiLine: true), '');
  out = out.replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '');
  // Inline code.
  out = out.replaceAllMapped(RegExp(r'`(.+?)`'), (m) => m.group(1) ?? '');
  // Links — keep the visible text, drop URL.
  out = out.replaceAllMapped(
    RegExp(r'\[([^\]]+)\]\([^)]+\)'),
    (m) => m.group(1) ?? '',
  );
  return out.trim();
}

/// Result of an AI revision call. Plain data so the dialog can render
/// without holding a service reference.
@immutable
class AiRevision {
  const AiRevision({
    required this.revisedText,
    required this.explanation,
    required this.changesMade,
  });

  final String revisedText;
  final String explanation;
  final List<String> changesMade;

  factory AiRevision.fromJson(Map<String, dynamic> json) {
    return AiRevision(
      revisedText: (json['revised_text'] as String?) ?? '',
      explanation: (json['explanation'] as String?) ?? '',
      changesMade: ((json['changes_made'] as List?) ?? const [])
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList(growable: false),
    );
  }
}
