// drafting/models/draft_model.dart — Pkg 7 Drafting Studio MVP.
// -----------------------------------------------------------------------------
// Plain data models for the drafting feature. No dependency on Supabase here
// so they can be constructed in tests without a backend stub.
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart' show immutable;

/// Where a draft came from. Mirrors the CHECK constraint in
/// `migration 20260514130000_drafting_studio.sql` (extended 2026-05-27 by
/// `20260527080200_drafts_vault_link.sql` to add `vault_note` and
/// `vault_import` for the Drafting × Vault integration).
enum DraftSourceType {
  blank,
  contractReviewReply,
  letter,
  appeal,
  memo,
  // ─── Drafting × Vault bridge ───
  /// Created from the Vault "Create Note" CTA. On first save we also call
  /// `DraftService.saveToVault` so the note lives in the encrypted vault.
  vaultNote,
  /// Created from "Edit in Studio" on an existing Vault doc — the body was
  /// imported from a `.md` / `.txt` Vault file. The Vault copy is tracked via
  /// the draft's `vault_copy_id` so subsequent saves overwrite the same row.
  vaultImport;

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
      case DraftSourceType.vaultNote:
        return 'vault_note';
      case DraftSourceType.vaultImport:
        return 'vault_import';
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
      case 'vault_note':
        return DraftSourceType.vaultNote;
      case 'vault_import':
        return DraftSourceType.vaultImport;
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
    this.vaultCopyId,
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

  /// Link to the Vault document created by `DraftService.saveToVault`.
  /// NULL when the draft has never been filed to the Vault.
  final String? vaultCopyId;

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
    String? vaultCopyId,
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
      vaultCopyId: vaultCopyId ?? this.vaultCopyId,
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
        if (vaultCopyId != null) 'vault_copy_id': vaultCopyId,
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
      vaultCopyId: json['vault_copy_id'] as String?,
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

/// A historical snapshot of a draft's `content_markdown`. Stored in
/// `draft_versions` and capped to 10 rows per draft by an after-insert trigger.
@immutable
class DraftVersion {
  const DraftVersion({
    required this.id,
    required this.draftId,
    required this.contentSnapshot,
    required this.isAiRevision,
    required this.createdAt,
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final String draftId;
  final String contentSnapshot;
  final bool isAiRevision;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  /// Cheap preview snippet used by the version-history list. Returns at
  /// most [maxChars] of the plaintext-stripped snapshot, single-spaced.
  String previewSnippet({int maxChars = 100}) {
    final plain = markdownToPlaintext(contentSnapshot)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (plain.isEmpty) return '';
    if (plain.length <= maxChars) return plain;
    return '${plain.substring(0, maxChars)}…';
  }

  factory DraftVersion.fromJson(Map<String, dynamic> json) {
    return DraftVersion(
      id: json['id'] as String,
      draftId: json['draft_id'] as String,
      contentSnapshot: (json['content_snapshot'] as String?) ?? '',
      isAiRevision: (json['ai_revision'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      metadata:
          ((json['metadata'] as Map?)?.cast<String, dynamic>()) ??
              const <String, dynamic>{},
    );
  }
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
    final raw = (json['changes_made'] as List?) ?? const <dynamic>[];
    return AiRevision(
      revisedText: (json['revised_text'] as String?) ?? '',
      explanation: (json['explanation'] as String?) ?? '',
      // Keep only string entries; reject null / int / empty so the dialog
      // doesn't render misleading bullets.
      changesMade: raw
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toList(growable: false),
    );
  }
}
