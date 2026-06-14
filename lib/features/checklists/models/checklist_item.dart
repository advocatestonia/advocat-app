// ---------------------------------------------------------------------------
// Checklist Item — one ordered step in a case-type roadmap.
//
// Source: RPC `get_case_checklist(p_case_id)` (migration
// 20260601100000_case_checklists.sql) which returns a jsonb array of
//   { item_id, step_order, title, description, deadline_days, done }
// joining `checklist_templates` with the caller's `checklist_progress`.
//
// This is a static, type-keyed roadmap — distinct from the dynamic
// AI-generated follow-up tasks. No LLM, no cron; pure read model.
// ---------------------------------------------------------------------------

import 'package:flutter/foundation.dart';

@immutable
class ChecklistItem {
  const ChecklistItem({
    required this.itemId,
    required this.stepOrder,
    required this.title,
    this.description,
    this.deadlineDays,
    required this.done,
  });

  /// `checklist_templates.id` — stable id used to toggle progress.
  final String itemId;

  /// 1-based ordering within the roadmap.
  final int stepOrder;

  final String title;
  final String? description;

  /// Optional statutory deadline hint in days (e.g. 30 = "30 days to
  /// appeal"). Null when the step has no associated clock.
  final int? deadlineDays;

  /// Whether the user has checked this step off for this case.
  final bool done;

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      itemId: json['item_id'] as String,
      stepOrder: (json['step_order'] as num?)?.toInt() ?? 0,
      title: (json['title'] as String?) ?? '',
      description: json['description'] as String?,
      deadlineDays: (json['deadline_days'] as num?)?.toInt(),
      done: json['done'] == true,
    );
  }

  ChecklistItem copyWith({bool? done}) {
    return ChecklistItem(
      itemId: itemId,
      stepOrder: stepOrder,
      title: title,
      description: description,
      deadlineDays: deadlineDays,
      done: done ?? this.done,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ChecklistItem &&
      other.itemId == itemId &&
      other.done == done &&
      other.stepOrder == stepOrder;

  @override
  int get hashCode => Object.hash(itemId, done, stepOrder);
}

/// Immutable snapshot of a case's checklist plus derived progress.
@immutable
class CaseChecklist {
  const CaseChecklist({required this.items});

  final List<ChecklistItem> items;

  static const empty = CaseChecklist(items: []);

  bool get isEmpty => items.isEmpty;

  int get total => items.length;

  int get completed => items.where((i) => i.done).length;

  /// Progress in [0.0, 1.0]. Returns 0 when there are no items (avoids
  /// a 0/0 NaN in the progress bar).
  double get progress => total == 0 ? 0 : completed / total;

  /// True when every step is checked off.
  bool get allDone => total > 0 && completed == total;

  factory CaseChecklist.fromRpc(dynamic rpcResult) {
    if (rpcResult is! List) return CaseChecklist.empty;
    final items = rpcResult
        .whereType<Map<String, dynamic>>()
        .map(ChecklistItem.fromJson)
        .toList()
      ..sort((a, b) => a.stepOrder.compareTo(b.stepOrder));
    return CaseChecklist(items: items);
  }

  CaseChecklist withToggled(String itemId, bool done) {
    return CaseChecklist(
      items: items
          .map((i) => i.itemId == itemId ? i.copyWith(done: done) : i)
          .toList(),
    );
  }
}
