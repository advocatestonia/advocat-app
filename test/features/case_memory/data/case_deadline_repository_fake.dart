// In-memory CaseDeadlineRepository fake. Used by all Pkg 9 tests:
//   * widget tests override the provider with a FakeCaseDeadlineRepository
//     that returns canned rows;
//   * mutation tests assert on the spy fields.

import 'package:advocat/features/case_memory/data/case_deadline_repository.dart';
import 'package:advocat/features/case_memory/models/case_deadline.dart';
import 'package:advocat/features/case_memory/models/user_case.dart';

/// In-memory fake. Each `list*` call returns the configured fixtures
/// for the matching method. Mutations are recorded for assertion.
class FakeCaseDeadlineRepository implements CaseDeadlineRepository {
  FakeCaseDeadlineRepository({
    List<CaseDeadline> active = const [],
    Map<String, List<CaseDeadline>>? perCase,
  })  : activeRows = List.of(active),
        perCaseRows = {...?perCase};

  /// Active rows returned by `listActiveAcrossCases`.
  List<CaseDeadline> activeRows;

  /// Per-case rows returned by `listForCase`.
  final Map<String, List<CaseDeadline>> perCaseRows;

  // Spies.
  String? lastMarkedComplete;
  String? lastSnoozedId;
  DateTime? lastSnoozedAt;
  String? lastArchivedId;
  Map<String, dynamic>? lastCreate;
  Map<String, dynamic>? lastEdit;

  // Failure injection.
  Exception? raiseOnListActive;
  Exception? raiseOnListForCase;
  Exception? raiseOnMutate;

  @override
  Future<List<CaseDeadline>> listActiveAcrossCases({int limit = 10}) async {
    if (raiseOnListActive != null) throw raiseOnListActive!;
    return List<CaseDeadline>.of(activeRows.take(limit));
  }

  @override
  Future<List<CaseDeadline>> listForCase(String caseId) async {
    if (raiseOnListForCase != null) throw raiseOnListForCase!;
    return List<CaseDeadline>.of(perCaseRows[caseId] ?? const []);
  }

  @override
  Future<void> markComplete(String deadlineId, {String? note}) async {
    if (raiseOnMutate != null) throw raiseOnMutate!;
    lastMarkedComplete = deadlineId;
    // Update fixture so the next list call reflects the change.
    activeRows = activeRows
        .where((d) => d.id != deadlineId)
        .toList(growable: false);
    perCaseRows.forEach((k, v) {
      perCaseRows[k] = v
          .map((d) => d.id == deadlineId
              ? d.copyWith(
                  status: CaseDeadlineStatus.completed,
                  completedAt: DateTime.now(),
                  completedNote: note,
                )
              : d)
          .toList(growable: false);
    });
  }

  @override
  Future<CaseDeadline> snooze(
      String deadlineId, DateTime newDeadlineAt) async {
    if (raiseOnMutate != null) throw raiseOnMutate!;
    lastSnoozedId = deadlineId;
    lastSnoozedAt = newDeadlineAt;
    final all = perCaseRows.values.expand((e) => e);
    return all.firstWhere(
      (d) => d.id == deadlineId,
      orElse: () => throw StateError('not in fake'),
    );
  }

  @override
  Future<void> archive(String deadlineId) async {
    if (raiseOnMutate != null) throw raiseOnMutate!;
    lastArchivedId = deadlineId;
    activeRows = activeRows
        .where((d) => d.id != deadlineId)
        .toList(growable: false);
  }

  @override
  Future<CaseDeadline> createManual({
    required String caseId,
    required String title,
    required DateTime deadlineAt,
    String? description,
    String? statuteBasis,
    String? anchorKey,
    DateTime? serviceDate,
    CaseDeadlinePriority priority = CaseDeadlinePriority.high,
  }) async {
    if (raiseOnMutate != null) throw raiseOnMutate!;
    lastCreate = {
      'case_id': caseId,
      'title': title,
      'deadline_at': deadlineAt,
      'priority': priority.dbValue,
      'anchor_key': anchorKey,
    };
    final created = CaseDeadline(
      id: 'fake-new-${DateTime.now().microsecondsSinceEpoch}',
      caseId: caseId,
      title: title,
      deadlineAt: deadlineAt,
      status: CaseDeadlineStatus.active,
      priority: priority,
      source: CaseDeadlineSource.manual,
      holidayShifted: false,
      anchorKey: anchorKey,
      statuteBasis: statuteBasis,
      description: description,
      serviceDate: serviceDate,
    );
    perCaseRows.putIfAbsent(caseId, () => []).add(created);
    return created;
  }

  @override
  Future<CaseDeadline> editManual({
    required String id,
    String? title,
    DateTime? deadlineAt,
    String? description,
    String? statuteBasis,
    CaseDeadlinePriority? priority,
  }) async {
    if (raiseOnMutate != null) throw raiseOnMutate!;
    lastEdit = {
      'id': id,
      'title': title,
      'deadline_at': deadlineAt,
      'priority': priority?.dbValue,
    };
    final all = perCaseRows.values.expand((e) => e);
    final existing = all.firstWhere(
      (d) => d.id == id,
      orElse: () => throw StateError('not in fake'),
    );
    return existing;
  }
}

/// Convenience constructor for a UserCase fixture, matching the
/// pattern in active_case_provider_test.dart.
UserCase mkUserCase({String id = 'c-1', String title = 'Test'}) {
  final now = DateTime.utc(2026, 5, 5, 12);
  return UserCase(
    id: id,
    userId: 'user-1',
    title: title,
    jurisdiction: 'EE',
    caseType: 'civil',
    createdAt: now,
    updatedAt: now,
  );
}

/// Convenience constructor for a CaseDeadline fixture used widely by
/// tests. Defaults match a generic FI kaebetähtaeg 5 days out.
CaseDeadline mkDeadline({
  String id = 'd-1',
  String caseId = 'c-1',
  String? caseTitle,
  String title = 'Appeal Migri decision',
  DateTime? deadlineAt,
  CaseDeadlineStatus status = CaseDeadlineStatus.active,
  CaseDeadlinePriority priority = CaseDeadlinePriority.high,
  CaseDeadlineSource source = CaseDeadlineSource.pdf,
  String? statuteBasis = 'HOL §164',
  String? anchorKey = 'fi_hol_2019_808_khoa',
  bool holidayShifted = false,
  String? holidayShiftNote,
  int? deltaDaysOverride,
  DateTime? now,
}) {
  final clock = now ?? DateTime.utc(2026, 5, 6, 12);
  final at = deadlineAt ?? clock.add(const Duration(days: 5));
  return CaseDeadline(
    id: id,
    caseId: caseId,
    caseTitle: caseTitle,
    title: title,
    deadlineAt: at,
    status: status,
    priority: priority,
    source: source,
    statuteBasis: statuteBasis,
    anchorKey: anchorKey,
    holidayShifted: holidayShifted,
    holidayShiftNote: holidayShiftNote,
    deltaDaysOverride: deltaDaysOverride,
  );
}
