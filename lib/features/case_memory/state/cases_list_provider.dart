// =====================================================================
// casesListProvider — async list of UserCase rows for the "Мои дела"
// screen. Refreshable from pull-to-refresh.
// =====================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/case_repository.dart';
import '../models/user_case.dart';

/// Family of providers keyed by [CaseListFilter]. The list screen
/// usually watches `casesListProvider(CaseListFilter.active)`.
final casesListProvider =
    FutureProvider.family<List<UserCase>, CaseListFilter>((ref, filter) async {
  final repo = ref.watch(caseRepositoryProvider);
  return repo.listCases(filter: filter);
});

/// Single-case lookup. Used by the detail screen.
final caseByIdProvider =
    FutureProvider.family<UserCase?, String>((ref, id) async {
  final repo = ref.watch(caseRepositoryProvider);
  return repo.getCase(id);
});

/// Documents for a given case. Pkg 1.D scope = read-only list. Pkg 2
/// will add upload/parse + invalidate this provider on change.
final caseDocumentsProvider =
    FutureProvider.family<List<dynamic>, String>((ref, caseId) async {
  final repo = ref.watch(caseRepositoryProvider);
  return repo.listDocuments(caseId);
});
