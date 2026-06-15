// ---------------------------------------------------------------------------
// Document-Collection Checklist (Feature #4) — Riverpod state.
//
// Family-keyed on DocProblemType so each problem type has independent state.
// Toggling a requirement (or linking a file) applies an optimistic local
// update, then persists via the service; on failure it rolls back and
// re-reads. Mirrors the checklists provider's optimistic pattern.
// ---------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/doc_requirement.dart';
import '../services/doc_collection_service.dart';

/// Async document-requirement set for one problem type, keyed by the enum.
final docRequirementsProvider = AsyncNotifierProvider.family<
    DocRequirementsNotifier, DocRequirementSet, DocProblemType>(
  DocRequirementsNotifier.new,
);

class DocRequirementsNotifier
    extends FamilyAsyncNotifier<DocRequirementSet, DocProblemType> {
  DocCollectionService get _service =>
      ref.read(docCollectionServiceProvider);

  DocProblemType get _problemType => arg;

  @override
  Future<DocRequirementSet> build(DocProblemType problemType) async {
    return _service.getRequirements(problemType);
  }

  /// Optimistically toggle [requirementId]'s collected flag, then persist.
  /// Rolls back on failure.
  Future<void> toggle(String requirementId, bool collected) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final optimistic = current.withCollected(requirementId, collected);
    state = AsyncData(optimistic);

    final linked = optimistic.items
        .firstWhere((i) => i.requirementId == requirementId)
        .documentId;

    final ok = await _safePersist(
      requirementId: requirementId,
      collected: collected,
      documentId: linked,
    );
    if (!ok) state = AsyncData(current);
  }

  /// Link an uploaded document to [requirementId] (also marks it collected),
  /// or clear the link when [documentId] is null. Optimistic + rollback.
  Future<void> linkDocument(String requirementId, String? documentId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final optimistic =
        current.withLinkedDocument(requirementId, documentId);
    state = AsyncData(optimistic);

    final row = optimistic.items
        .firstWhere((i) => i.requirementId == requirementId);

    final ok = await _safePersist(
      requirementId: requirementId,
      collected: row.collected,
      documentId: documentId,
    );
    if (!ok) state = AsyncData(current);
  }

  Future<bool> _safePersist({
    required String requirementId,
    required bool collected,
    String? documentId,
  }) async {
    final ok = await _service.toggleRequirement(
      problemType: _problemType,
      requirementId: requirementId,
      collected: collected,
      documentId: documentId,
    );
    if (!ok) ref.invalidateSelf();
    return ok;
  }

  /// Force a re-read from the server (pull-to-refresh).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _service.getRequirements(_problemType),
    );
  }
}
