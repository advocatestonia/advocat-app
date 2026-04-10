import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/case_model.dart';
import '../../../models/correspondence.dart';
import '../../../services/demo_data.dart';
import '../../../services/supabase_service.dart';

// ---------------------------------------------------------------------------
// Cases Providers — CRUD with optimistic updates and error handling
// ---------------------------------------------------------------------------

/// All cases for the current user.
final casesProvider =
    AsyncNotifierProvider<CasesNotifier, List<LegalCase>>(CasesNotifier.new);

class CasesNotifier extends AsyncNotifier<List<LegalCase>> {
  SupabaseService get _supabase => ref.read(supabaseServiceProvider);

  @override
  Future<List<LegalCase>> build() async {
    return _supabase.getCases();
  }

  /// Converts a [CaseType] enum value to the snake_case string
  /// that the Supabase `cases.type` column expects.
  static String _caseTypeToDbString(CaseType type) {
    switch (type) {
      case CaseType.deportation:
        return 'deportation';
      case CaseType.asylum:
        return 'asylum';
      case CaseType.residencePermit:
        return 'residence_permit';
      case CaseType.familyReunification:
        return 'family_reunification';
      case CaseType.citizenship:
        return 'citizenship';
      case CaseType.workPermit:
        return 'work_permit';
      case CaseType.laborDispute:
        return 'labor_dispute';
      case CaseType.tenantRights:
        return 'tenant_rights';
      case CaseType.debtCollection:
        return 'debt_collection';
      case CaseType.discrimination:
        return 'discrimination';
      case CaseType.policeMisconduct:
        return 'police_misconduct';
      case CaseType.socialBenefits:
        return 'social_benefits';
      case CaseType.domesticViolence:
        return 'domestic_violence';
      case CaseType.consumerProtection:
        return 'consumer_protection';
      case CaseType.inheritance:
        return 'inheritance';
      case CaseType.other:
        return 'other';
    }
  }

  /// Optimistically adds a case, then syncs with the server.
  Future<LegalCase> createCase({
    required String title,
    required CaseType type,
    String? description,
    String? migriReferenceNumber,
    String? country,
  }) async {
    // Convert CaseType enum to snake_case string matching DB schema
    final typeStr = _caseTypeToDbString(type);
    final result = await _supabase.createCase({
      'title': title,
      'type': typeStr,
      if (description != null) 'description': description,
      if (migriReferenceNumber != null)
        'migri_reference_number': migriReferenceNumber,
      if (country != null) 'country': country,
    });

    // Optimistic update — add to the top of the list
    state = state.whenData((cases) => [result, ...cases]);
    return result;
  }

  /// Update an existing case. Optimistically applies changes.
  Future<void> updateCase(String id, Map<String, dynamic> updates) async {
    await _supabase.updateCase(id, updates);

    // Refresh from server to get the canonical state
    ref.invalidateSelf();
    ref.invalidate(caseByIdProvider(id));
  }

  /// Archive a case (set status to closed). Optimistic removal from active list.
  Future<void> archiveCase(String id) async {
    // Optimistic: mark as closed immediately
    state = state.whenData((cases) {
      return cases.map((c) {
        if (c.id == id) {
          return c.copyWith(status: CaseStatus.closed);
        }
        return c;
      }).toList();
    });

    try {
      await _supabase.updateCase(id, {'status': 'closed'});
    } catch (e) {
      // Rollback on failure
      ref.invalidateSelf();
      rethrow;
    }
  }

  /// Delete a case. Optimistic removal.
  Future<void> deleteCase(String id) async {
    final previousState = state;

    // Optimistic: remove immediately
    state = state.whenData(
      (cases) => cases.where((c) => c.id != id).toList(),
    );

    try {
      await _supabase.updateCase(id, {'status': 'closed'});
    } catch (e) {
      // Rollback on failure
      state = previousState;
      rethrow;
    }
  }
}

/// A single case by ID.
final caseByIdProvider =
    FutureProvider.family<LegalCase, String>((ref, id) async {
  final isDemo = ref.watch(isDemoModeProvider);
  if (isDemo) {
    return DemoData.cases.firstWhere(
      (c) => c.id == id,
      orElse: () => DemoData.cases.first,
    );
  }
  return ref.watch(supabaseServiceProvider).getCaseById(id);
});

/// Correspondence for a specific case.
final caseCorrespondenceProvider =
    FutureProvider.family<List<Correspondence>, String>((ref, caseId) async {
  return ref.watch(supabaseServiceProvider).getCorrespondence(caseId);
});

/// Controller for creating and updating cases.
/// Kept for backward compatibility with screens that use it.
final caseControllerProvider =
    StateNotifierProvider<CaseController, AsyncValue<void>>((ref) {
  return CaseController(ref);
});

class CaseController extends StateNotifier<AsyncValue<void>> {
  CaseController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  CasesNotifier get _notifier => _ref.read(casesProvider.notifier);

  Future<LegalCase> createCase({
    required String title,
    required CaseType type,
    String? description,
    String? migriReferenceNumber,
    String? country,
  }) async {
    state = const AsyncLoading();
    try {
      final result = await _notifier.createCase(
        title: title,
        type: type,
        description: description,
        migriReferenceNumber: migriReferenceNumber,
        country: country,
      );
      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> updateCase(String id, Map<String, dynamic> updates) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _notifier.updateCase(id, updates);
    });
  }

  Future<void> archiveCase(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _notifier.archiveCase(id);
    });
  }

  Future<void> deleteCase(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _notifier.deleteCase(id);
    });
  }
}
