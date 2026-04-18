import 'package:advocat/features/cases/providers/cases_provider.dart';
import 'package:advocat/models/case_model.dart';
import 'package:advocat/services/supabase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_helpers.dart';

// ---------------------------------------------------------------------------
// Fake SupabaseService — controllable stub for provider tests
// ---------------------------------------------------------------------------

class FakeSupabaseService extends SupabaseService {
  List<LegalCase> casesToReturn = [];
  LegalCase? caseByIdToReturn;
  LegalCase? createdCaseToReturn;
  Exception? getCasesError;
  Exception? createCaseError;
  Exception? updateCaseError;
  Map<String, dynamic>? lastCreateCaseData;
  String? lastUpdateId;
  Map<String, dynamic>? lastUpdateData;

  @override
  Future<List<LegalCase>> getCases() async {
    if (getCasesError != null) throw getCasesError!;
    return casesToReturn;
  }

  @override
  Future<LegalCase> getCaseById(String id) async {
    if (caseByIdToReturn != null) return caseByIdToReturn!;
    return casesToReturn.firstWhere(
      (c) => c.id == id,
      orElse: () => throw Exception('Case not found'),
    );
  }

  @override
  Future<LegalCase> createCase(Map<String, dynamic> caseData) async {
    lastCreateCaseData = caseData;
    if (createCaseError != null) throw createCaseError!;
    return createdCaseToReturn ?? makeCase(id: 'new-case-001');
  }

  @override
  Future<void> updateCase(String id, Map<String, dynamic> updates) async {
    lastUpdateId = id;
    lastUpdateData = updates;
    if (updateCaseError != null) throw updateCaseError!;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a [ProviderContainer] with the [SupabaseService] overridden by
/// the given [fakeService].
ProviderContainer makeContainer(FakeSupabaseService fakeService) {
  final container = ProviderContainer(
    overrides: [
      supabaseServiceProvider.overrideWithValue(fakeService),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Waits for the [casesProvider] to leave the loading state.
/// Uses a [Completer] driven by a listener so we get a true signal
/// rather than guessing how many microtasks to pump.
Future<void> waitForProvider(ProviderContainer container) async {
  // Read the provider to trigger its build if it hasn't started yet.
  container.read(casesProvider);

  // Pump microtasks until the provider resolves.
  // We use a simple loop with a short timer to let Riverpod's internal
  // scheduling proceed.
  var attempts = 0;
  while (container.read(casesProvider).isLoading && attempts < 50) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    attempts++;
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ── CasesNotifier — build / loading / data states ────────────────────

  group('CasesNotifier — build', () {
    test('starts in loading state', () {
      final fake = FakeSupabaseService();
      final container = makeContainer(fake);

      // Before any microtask runs the provider should be loading.
      final state = container.read(casesProvider);
      expect(state, isA<AsyncLoading<List<LegalCase>>>());
    });

    test('loads empty list when service returns no cases', () async {
      final fake = FakeSupabaseService()..casesToReturn = [];
      final container = makeContainer(fake);

      await waitForProvider(container);

      final state = container.read(casesProvider);
      expect(state.value, isEmpty);
    });

    test('loads cases from service', () async {
      final cases = [
        makeCase(id: 'c-1', title: 'Case One'),
        makeCase(id: 'c-2', title: 'Case Two'),
      ];
      final fake = FakeSupabaseService()..casesToReturn = cases;
      final container = makeContainer(fake);

      await waitForProvider(container);

      final state = container.read(casesProvider);
      expect(state.value, hasLength(2));
      expect(state.value!.first.id, 'c-1');
      expect(state.value!.last.id, 'c-2');
    });

    test('enters error state when getCases throws', () async {
      final fake = FakeSupabaseService()
        ..getCasesError = Exception('Network error');
      final container = makeContainer(fake);

      await waitForProvider(container);

      final state = container.read(casesProvider);
      expect(state.hasError, isTrue);
      expect(state.error.toString(), contains('Network error'));
    });
  });

  // ── CasesNotifier — createCase ───────────────────────────────────────

  group('CasesNotifier — createCase', () {
    test('returns the created case', () async {
      final newCase = makeCase(id: 'created-1', title: 'New Deportation');
      final fake = FakeSupabaseService()
        ..casesToReturn = []
        ..createdCaseToReturn = newCase;
      final container = makeContainer(fake);
      await waitForProvider(container);

      final notifier = container.read(casesProvider.notifier);
      final result = await notifier.createCase(
        title: 'New Deportation',
        type: CaseType.deportation,
      );

      expect(result.id, 'created-1');
      expect(result.title, 'New Deportation');
    });

    test('sends correct snake_case type to service', () async {
      final fake = FakeSupabaseService()
        ..casesToReturn = []
        ..createdCaseToReturn = makeCase();
      final container = makeContainer(fake);
      await waitForProvider(container);

      final notifier = container.read(casesProvider.notifier);
      await notifier.createCase(
        title: 'Test',
        type: CaseType.familyReunification,
      );

      expect(fake.lastCreateCaseData!['type'], 'family_reunification');
    });

    test('sends optional fields when provided', () async {
      final fake = FakeSupabaseService()
        ..casesToReturn = []
        ..createdCaseToReturn = makeCase();
      final container = makeContainer(fake);
      await waitForProvider(container);

      final notifier = container.read(casesProvider.notifier);
      await notifier.createCase(
        title: 'Full Case',
        type: CaseType.asylum,
        description: 'Seeking asylum',
        migriReferenceNumber: 'MR-999',
        country: 'Estonia',
      );

      final data = fake.lastCreateCaseData!;
      expect(data['title'], 'Full Case');
      expect(data['type'], 'asylum');
      expect(data['description'], 'Seeking asylum');
      expect(data['migri_reference_number'], 'MR-999');
      expect(data['country'], 'Estonia');
    });

    test('omits optional fields when null', () async {
      final fake = FakeSupabaseService()
        ..casesToReturn = []
        ..createdCaseToReturn = makeCase();
      final container = makeContainer(fake);
      await waitForProvider(container);

      final notifier = container.read(casesProvider.notifier);
      await notifier.createCase(title: 'Minimal', type: CaseType.other);

      final data = fake.lastCreateCaseData!;
      expect(data.containsKey('description'), isFalse);
      expect(data.containsKey('migri_reference_number'), isFalse);
      expect(data.containsKey('country'), isFalse);
    });

    test('optimistically prepends created case to state', () async {
      final existing = [makeCase(id: 'old-1')];
      final newCase = makeCase(id: 'new-1', title: 'Brand New');
      final fake = FakeSupabaseService()
        ..casesToReturn = existing
        ..createdCaseToReturn = newCase;
      final container = makeContainer(fake);
      await waitForProvider(container);

      final notifier = container.read(casesProvider.notifier);
      await notifier.createCase(title: 'Brand New', type: CaseType.asylum);

      final state = container.read(casesProvider);
      expect(state.value, hasLength(2));
      expect(state.value!.first.id, 'new-1',
          reason: 'new case should be at the top');
      expect(state.value!.last.id, 'old-1');
    });

    test('rethrows when service throws', () async {
      final fake = FakeSupabaseService()
        ..casesToReturn = []
        ..createCaseError = Exception('Insert failed');
      final container = makeContainer(fake);
      await waitForProvider(container);

      final notifier = container.read(casesProvider.notifier);
      expect(
        () => notifier.createCase(title: 'Fail', type: CaseType.other),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── CasesNotifier — _caseTypeToDbString mapping ──────────────────────

  group('CasesNotifier — type mapping', () {
    test('all CaseType values map to correct snake_case strings', () async {
      final expectedMappings = {
        CaseType.deportation: 'deportation',
        CaseType.asylum: 'asylum',
        CaseType.residencePermit: 'residence_permit',
        CaseType.familyReunification: 'family_reunification',
        CaseType.citizenship: 'citizenship',
        CaseType.workPermit: 'work_permit',
        CaseType.laborDispute: 'labor_dispute',
        CaseType.tenantRights: 'tenant_rights',
        CaseType.debtCollection: 'debt_collection',
        CaseType.discrimination: 'discrimination',
        CaseType.policeMisconduct: 'police_misconduct',
        CaseType.socialBenefits: 'social_benefits',
        CaseType.domesticViolence: 'domestic_violence',
        CaseType.consumerProtection: 'consumer_protection',
        CaseType.inheritance: 'inheritance',
        CaseType.other: 'other',
      };

      for (final entry in expectedMappings.entries) {
        final fake = FakeSupabaseService()
          ..casesToReturn = []
          ..createdCaseToReturn = makeCase();
        final container = makeContainer(fake);
        await waitForProvider(container);

        final notifier = container.read(casesProvider.notifier);
        await notifier.createCase(title: 'T', type: entry.key);

        expect(fake.lastCreateCaseData!['type'], entry.value,
            reason: '${entry.key.name} should map to ${entry.value}');
      }
    });
  });

  // ── CasesNotifier — updateCase ───────────────────────────────────────

  group('CasesNotifier — updateCase', () {
    test('delegates to service with correct id and updates', () async {
      final fake = FakeSupabaseService()
        ..casesToReturn = [makeCase(id: 'c-1')];
      final container = makeContainer(fake);
      await waitForProvider(container);

      final notifier = container.read(casesProvider.notifier);
      await notifier.updateCase('c-1', {'title': 'Updated'});

      expect(fake.lastUpdateId, 'c-1');
      expect(fake.lastUpdateData!['title'], 'Updated');
    });

    test('rethrows when service throws', () async {
      final fake = FakeSupabaseService()
        ..casesToReturn = [makeCase(id: 'c-1')]
        ..updateCaseError = Exception('Update failed');
      final container = makeContainer(fake);
      await waitForProvider(container);

      final notifier = container.read(casesProvider.notifier);
      expect(
        () => notifier.updateCase('c-1', {'title': 'Nope'}),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── CasesNotifier — archiveCase ──────────────────────────────────────

  group('CasesNotifier — archiveCase', () {
    test('optimistically sets status to closed', () async {
      final cases = [
        makeCase(id: 'c-1', status: CaseStatus.active),
        makeCase(id: 'c-2', status: CaseStatus.active),
      ];
      final fake = FakeSupabaseService()..casesToReturn = cases;
      final container = makeContainer(fake);
      await waitForProvider(container);

      final notifier = container.read(casesProvider.notifier);
      await notifier.archiveCase('c-1');

      final state = container.read(casesProvider);
      final archived = state.value!.firstWhere((c) => c.id == 'c-1');
      expect(archived.status, CaseStatus.closed);
    });

    test('does not change other cases', () async {
      final cases = [
        makeCase(id: 'c-1', status: CaseStatus.active),
        makeCase(id: 'c-2', status: CaseStatus.inCourt),
      ];
      final fake = FakeSupabaseService()..casesToReturn = cases;
      final container = makeContainer(fake);
      await waitForProvider(container);

      final notifier = container.read(casesProvider.notifier);
      await notifier.archiveCase('c-1');

      final state = container.read(casesProvider);
      final other = state.value!.firstWhere((c) => c.id == 'c-2');
      expect(other.status, CaseStatus.inCourt);
    });

    test('sends status=closed to service', () async {
      final fake = FakeSupabaseService()
        ..casesToReturn = [makeCase(id: 'c-1')];
      final container = makeContainer(fake);
      await waitForProvider(container);

      final notifier = container.read(casesProvider.notifier);
      await notifier.archiveCase('c-1');

      expect(fake.lastUpdateId, 'c-1');
      expect(fake.lastUpdateData!['status'], 'closed');
    });

    test('rethrows on service failure', () async {
      final fake = FakeSupabaseService()
        ..casesToReturn = [makeCase(id: 'c-1')]
        ..updateCaseError = Exception('Archive failed');
      final container = makeContainer(fake);
      await waitForProvider(container);

      final notifier = container.read(casesProvider.notifier);
      expect(
        () => notifier.archiveCase('c-1'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── CasesNotifier — deleteCase ───────────────────────────────────────

  group('CasesNotifier — deleteCase', () {
    test('optimistically removes case from state', () async {
      final cases = [
        makeCase(id: 'c-1', title: 'First'),
        makeCase(id: 'c-2', title: 'Second'),
      ];
      final fake = FakeSupabaseService()..casesToReturn = cases;
      final container = makeContainer(fake);
      await waitForProvider(container);

      final notifier = container.read(casesProvider.notifier);
      await notifier.deleteCase('c-1');

      final state = container.read(casesProvider);
      expect(state.value, hasLength(1));
      expect(state.value!.first.id, 'c-2');
    });

    test('calls service with status=closed', () async {
      final fake = FakeSupabaseService()
        ..casesToReturn = [makeCase(id: 'c-1')];
      final container = makeContainer(fake);
      await waitForProvider(container);

      final notifier = container.read(casesProvider.notifier);
      await notifier.deleteCase('c-1');

      expect(fake.lastUpdateId, 'c-1');
      expect(fake.lastUpdateData!['status'], 'closed');
    });

    test('rolls back on service failure', () async {
      final cases = [
        makeCase(id: 'c-1', title: 'Keep Me'),
        makeCase(id: 'c-2', title: 'Second'),
      ];
      final fake = FakeSupabaseService()
        ..casesToReturn = cases
        ..updateCaseError = Exception('Delete failed');
      final container = makeContainer(fake);
      await waitForProvider(container);

      final notifier = container.read(casesProvider.notifier);

      // The delete should throw...
      expect(
        () => notifier.deleteCase('c-1'),
        throwsA(isA<Exception>()),
      );

      // ... and after the error the state should be rolled back.
      await Future<void>.delayed(Duration.zero);
      final state = container.read(casesProvider);
      expect(state.value, hasLength(2),
          reason: 'rollback should restore original list');
    });

    test('deleting non-existent id leaves state unchanged', () async {
      final cases = [makeCase(id: 'c-1')];
      final fake = FakeSupabaseService()..casesToReturn = cases;
      final container = makeContainer(fake);
      await waitForProvider(container);

      final notifier = container.read(casesProvider.notifier);
      await notifier.deleteCase('non-existent');

      final state = container.read(casesProvider);
      expect(state.value, hasLength(1));
    });

    test('deleting last case results in empty list', () async {
      final fake = FakeSupabaseService()
        ..casesToReturn = [makeCase(id: 'c-1')];
      final container = makeContainer(fake);
      await waitForProvider(container);

      final notifier = container.read(casesProvider.notifier);
      await notifier.deleteCase('c-1');

      final state = container.read(casesProvider);
      expect(state.value, isEmpty);
    });
  });

  // ── CaseController — state transitions ───────────────────────────────

  group('CaseController — createCase', () {
    test('transitions loading → data on success', () async {
      final newCase = makeCase(id: 'ctrl-1');
      final fake = FakeSupabaseService()
        ..casesToReturn = []
        ..createdCaseToReturn = newCase;
      final container = makeContainer(fake);
      await waitForProvider(container);

      final controller = container.read(caseControllerProvider.notifier);
      final result = await controller.createCase(
        title: 'Ctrl Case',
        type: CaseType.citizenship,
      );

      expect(result.id, 'ctrl-1');
      final controllerState = container.read(caseControllerProvider);
      expect(controllerState, isA<AsyncData<void>>());
    });

    test('transitions to error on failure', () async {
      final fake = FakeSupabaseService()
        ..casesToReturn = []
        ..createCaseError = Exception('Controller fail');
      final container = makeContainer(fake);
      await waitForProvider(container);

      final controller = container.read(caseControllerProvider.notifier);

      expect(
        () => controller.createCase(title: 'Fail', type: CaseType.other),
        throwsA(isA<Exception>()),
      );

      await Future<void>.delayed(Duration.zero);
      final controllerState = container.read(caseControllerProvider);
      expect(controllerState, isA<AsyncError<void>>());
    });
  });

  group('CaseController — updateCase', () {
    test('transitions loading → data on success', () async {
      final fake = FakeSupabaseService()
        ..casesToReturn = [makeCase(id: 'c-1')];
      final container = makeContainer(fake);
      await waitForProvider(container);

      final controller = container.read(caseControllerProvider.notifier);
      await controller.updateCase('c-1', {'title': 'Updated via ctrl'});

      final controllerState = container.read(caseControllerProvider);
      expect(controllerState, isA<AsyncData<void>>());
    });

    test('transitions to error on failure', () async {
      final fake = FakeSupabaseService()
        ..casesToReturn = [makeCase(id: 'c-1')]
        ..updateCaseError = Exception('Update via ctrl fail');
      final container = makeContainer(fake);
      await waitForProvider(container);

      final controller = container.read(caseControllerProvider.notifier);
      await controller.updateCase('c-1', {'title': 'Nope'});

      final controllerState = container.read(caseControllerProvider);
      expect(controllerState, isA<AsyncError<void>>());
    });
  });

  group('CaseController — archiveCase', () {
    test('transitions loading → data on success', () async {
      final fake = FakeSupabaseService()
        ..casesToReturn = [makeCase(id: 'c-1')];
      final container = makeContainer(fake);
      await waitForProvider(container);

      final controller = container.read(caseControllerProvider.notifier);
      await controller.archiveCase('c-1');

      final controllerState = container.read(caseControllerProvider);
      expect(controllerState, isA<AsyncData<void>>());
    });

    test('transitions to error on failure', () async {
      final fake = FakeSupabaseService()
        ..casesToReturn = [makeCase(id: 'c-1')]
        ..updateCaseError = Exception('Archive via ctrl fail');
      final container = makeContainer(fake);
      await waitForProvider(container);

      final controller = container.read(caseControllerProvider.notifier);
      await controller.archiveCase('c-1');

      final controllerState = container.read(caseControllerProvider);
      expect(controllerState, isA<AsyncError<void>>());
    });
  });

  group('CaseController — deleteCase', () {
    test('transitions loading → data on success', () async {
      final fake = FakeSupabaseService()
        ..casesToReturn = [makeCase(id: 'c-1')];
      final container = makeContainer(fake);
      await waitForProvider(container);

      final controller = container.read(caseControllerProvider.notifier);
      await controller.deleteCase('c-1');

      final controllerState = container.read(caseControllerProvider);
      expect(controllerState, isA<AsyncData<void>>());
    });

    test('transitions to error on failure', () async {
      final fake = FakeSupabaseService()
        ..casesToReturn = [makeCase(id: 'c-1')]
        ..updateCaseError = Exception('Delete via ctrl fail');
      final container = makeContainer(fake);
      await waitForProvider(container);

      final controller = container.read(caseControllerProvider.notifier);
      await controller.deleteCase('c-1');

      final controllerState = container.read(caseControllerProvider);
      expect(controllerState, isA<AsyncError<void>>());
    });
  });

  // ── Edge cases ───────────────────────────────────────────────────────

  group('Edge cases', () {
    test('creating multiple cases appends each at the top', () async {
      final fake = FakeSupabaseService()..casesToReturn = [];
      final container = makeContainer(fake);
      await waitForProvider(container);

      final notifier = container.read(casesProvider.notifier);

      fake.createdCaseToReturn = makeCase(id: 'a');
      await notifier.createCase(title: 'A', type: CaseType.asylum);

      fake.createdCaseToReturn = makeCase(id: 'b');
      await notifier.createCase(title: 'B', type: CaseType.other);

      final state = container.read(casesProvider);
      expect(state.value, hasLength(2));
      expect(state.value!.first.id, 'b',
          reason: 'most recent should be first');
    });

    test('archive then delete same case does not throw', () async {
      final fake = FakeSupabaseService()
        ..casesToReturn = [makeCase(id: 'c-1', status: CaseStatus.active)];
      final container = makeContainer(fake);
      await waitForProvider(container);

      final notifier = container.read(casesProvider.notifier);
      await notifier.archiveCase('c-1');
      await notifier.deleteCase('c-1');

      final state = container.read(casesProvider);
      expect(state.value, isEmpty);
    });

    test('empty title is passed through to service', () async {
      final fake = FakeSupabaseService()
        ..casesToReturn = []
        ..createdCaseToReturn = makeCase(title: '');
      final container = makeContainer(fake);
      await waitForProvider(container);

      final notifier = container.read(casesProvider.notifier);
      await notifier.createCase(title: '', type: CaseType.other);

      expect(fake.lastCreateCaseData!['title'], '');
    });

    test('very long title is passed through to service', () async {
      final longTitle = 'A' * 1000;
      final fake = FakeSupabaseService()
        ..casesToReturn = []
        ..createdCaseToReturn = makeCase(title: longTitle);
      final container = makeContainer(fake);
      await waitForProvider(container);

      final notifier = container.read(casesProvider.notifier);
      await notifier.createCase(title: longTitle, type: CaseType.other);

      expect(fake.lastCreateCaseData!['title'], longTitle);
    });

    test('large list of cases loads without error', () async {
      final manyCases = List.generate(
        500,
        (i) => makeCase(id: 'case-$i', title: 'Case $i'),
      );
      final fake = FakeSupabaseService()..casesToReturn = manyCases;
      final container = makeContainer(fake);
      await waitForProvider(container);

      final state = container.read(casesProvider);
      expect(state.value, hasLength(500));
    });
  });
}
