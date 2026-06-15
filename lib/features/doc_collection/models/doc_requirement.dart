// ---------------------------------------------------------------------------
// Document-Collection Checklist (Feature #4) — domain models.
//
// A materialised list of DOCUMENTS to collect before contacting an
// authority / court / lawyer, keyed by a user-pickable problem type
// (residence permit, tenancy, dismissal, inheritance, divorce). Distinct
// from the checklists feature (which is an ordered ACTION plan).
//
// Source: RPC `get_doc_requirements(p_problem_type, p_jurisdiction)`
// (migration 20260619000000_doc_requirements.sql) returning a jsonb array of
//   { requirement_id, sort_order, title, where_to_get, why_needed,
//     optional, collected, document_id }
// joining `doc_requirement_templates` with the caller's
// `doc_collection_progress`.
//
// Pure data + derived progress; no LLM, no cron. The optional AI top-up
// (extra suggested documents) is a separate, ephemeral concern rendered
// by the screen and not modelled here.
// ---------------------------------------------------------------------------

import 'package:flutter/foundation.dart';

/// The fixed set of problem types the picker offers. The string values are
/// the `problem_type` keys seeded in `doc_requirement_templates` and sent to
/// the `doc-requirements` edge function / RPC.
enum DocProblemType {
  residencePermit('residence_permit'),
  tenantRights('tenant_rights'),
  dismissal('dismissal'),
  inheritance('inheritance'),
  divorce('divorce');

  const DocProblemType(this.key);

  /// DB key (e.g. `residence_permit`).
  final String key;

  static DocProblemType? fromKey(String? key) {
    if (key == null) return null;
    for (final t in DocProblemType.values) {
      if (t.key == key) return t;
    }
    return null;
  }
}

/// One required document in the collection list.
@immutable
class DocRequirement {
  const DocRequirement({
    required this.requirementId,
    required this.sortOrder,
    required this.title,
    this.whereToGet,
    this.whyNeeded,
    this.optional = false,
    required this.collected,
    this.documentId,
  });

  /// `doc_requirement_templates.id` — stable id used to toggle progress.
  final String requirementId;

  /// 1-based ordering within the list.
  final int sortOrder;

  /// WHAT to collect.
  final String title;

  /// WHERE to get it.
  final String? whereToGet;

  /// WHY it is needed.
  final String? whyNeeded;

  /// Soft hint that the document is optional / situational.
  final bool optional;

  /// Whether the user has marked this requirement collected.
  final bool collected;

  /// Optionally links an uploaded `documents.id` that satisfies this row.
  final String? documentId;

  /// True when the user has attached a file from their vault/documents.
  bool get hasLinkedDocument =>
      documentId != null && documentId!.isNotEmpty;

  factory DocRequirement.fromJson(Map<String, dynamic> json) {
    return DocRequirement(
      requirementId: (json['requirement_id'] as String?) ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      title: (json['title'] as String?) ?? '',
      whereToGet: json['where_to_get'] as String?,
      whyNeeded: json['why_needed'] as String?,
      optional: json['optional'] == true,
      collected: json['collected'] == true,
      documentId: json['document_id'] as String?,
    );
  }

  DocRequirement copyWith({
    bool? collected,
    String? documentId,
    bool clearDocument = false,
  }) {
    return DocRequirement(
      requirementId: requirementId,
      sortOrder: sortOrder,
      title: title,
      whereToGet: whereToGet,
      whyNeeded: whyNeeded,
      optional: optional,
      collected: collected ?? this.collected,
      documentId: clearDocument ? null : (documentId ?? this.documentId),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DocRequirement &&
      other.requirementId == requirementId &&
      other.collected == collected &&
      other.documentId == documentId &&
      other.sortOrder == sortOrder;

  @override
  int get hashCode =>
      Object.hash(requirementId, collected, documentId, sortOrder);
}

/// An AI-suggested EXTRA document for a non-standard situation. Ephemeral —
/// never persisted; rendered under the same disclaimer as the base list.
@immutable
class DocSuggestion {
  const DocSuggestion({
    required this.title,
    this.whereToGet,
    this.whyNeeded,
  });

  final String title;
  final String? whereToGet;
  final String? whyNeeded;

  factory DocSuggestion.fromJson(Map<String, dynamic> json) {
    return DocSuggestion(
      title: (json['title'] as String?) ?? '',
      whereToGet: json['where_to_get'] as String?,
      whyNeeded: json['why_needed'] as String?,
    );
  }
}

/// Immutable snapshot of a problem type's document list plus derived
/// collection progress.
@immutable
class DocRequirementSet {
  const DocRequirementSet({required this.items});

  final List<DocRequirement> items;

  static const empty = DocRequirementSet(items: []);

  bool get isEmpty => items.isEmpty;

  int get total => items.length;

  int get collected => items.where((i) => i.collected).length;

  /// Progress in [0.0, 1.0]. 0 when empty (avoids a 0/0 NaN in the bar).
  double get progress => total == 0 ? 0 : collected / total;

  /// True when every required document is collected.
  bool get allCollected => total > 0 && collected == total;

  factory DocRequirementSet.fromRpc(dynamic rpcResult) {
    if (rpcResult is! List) return DocRequirementSet.empty;
    final items = rpcResult
        .whereType<Map<String, dynamic>>()
        .map(DocRequirement.fromJson)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return DocRequirementSet(items: items);
  }

  /// Returns a copy with [requirementId] toggled collected/uncollected.
  DocRequirementSet withCollected(String requirementId, bool collected) {
    return DocRequirementSet(
      items: items
          .map((i) => i.requirementId == requirementId
              ? i.copyWith(collected: collected)
              : i)
          .toList(),
    );
  }

  /// Returns a copy with [requirementId]'s linked document set or cleared.
  /// Passing a non-null [documentId] also marks the row collected (attaching
  /// a file is implicit proof of collection); clearing leaves `collected`.
  DocRequirementSet withLinkedDocument(
    String requirementId,
    String? documentId,
  ) {
    return DocRequirementSet(
      items: items.map((i) {
        if (i.requirementId != requirementId) return i;
        if (documentId == null || documentId.isEmpty) {
          return i.copyWith(clearDocument: true);
        }
        return i.copyWith(documentId: documentId, collected: true);
      }).toList(),
    );
  }

  /// A plain-text export of the list ("[x] Title — where / why"), suitable
  /// for the "export list" share action. No PII beyond the user's own text.
  String toPlainText() {
    final buf = StringBuffer();
    for (final i in items) {
      final box = i.collected ? '[x]' : '[ ]';
      buf.writeln('$box ${i.title}${i.optional ? ' (optional)' : ''}');
      if (i.whereToGet != null && i.whereToGet!.isNotEmpty) {
        buf.writeln('    Where: ${i.whereToGet}');
      }
      if (i.whyNeeded != null && i.whyNeeded!.isNotEmpty) {
        buf.writeln('    Why: ${i.whyNeeded}');
      }
    }
    return buf.toString().trimRight();
  }
}
