// =====================================================================
// Tests for [CaseAutoPatchService] — Pkg 1.C client.
//
// We test the service via a fake [SupabaseService] that overrides
// callEdgeFunction. This keeps the suite hermetic — no network, no
// Supabase emulator. Provider invalidation is exercised through a
// real ProviderContainer with overrides.
// =====================================================================

@Tags(['fast'])
library;

import 'dart:async';

import 'package:advocat/features/case_memory/data/case_repository.dart';
import 'package:advocat/features/case_memory/models/case_document.dart';
import 'package:advocat/features/case_memory/models/user_case.dart';
import 'package:advocat/features/case_memory/services/case_auto_patch_service.dart';
import 'package:advocat/features/case_memory/state/cases_list_provider.dart';
import 'package:advocat/services/supabase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _validUuid = '550e8400-e29b-41d4-a716-446655440000';

// =====================================================================
// Fakes
// =====================================================================

class _FakeSupabaseService implements SupabaseService {
  _FakeSupabaseService({
    this.demo = false,
    this.response,
    this.throwsOnCall = false,
  });

  bool demo;
  Map<String, dynamic>? response;
  bool throwsOnCall;

  // Spy
  String? lastFunctionName;
  Map<String, dynamic>? lastBody;
  int callCount = 0;

  @override
  bool get isDemo => demo;

  @override
  Future<Map<String, dynamic>?> callEdgeFunction(
    String functionName, {
    Map<String, dynamic>? body,
  }) async {
    callCount++;
    lastFunctionName = functionName;
    lastBody = body;
    if (throwsOnCall) throw StateError('boom');
    return response;
  }

  // ── Everything else is unused by CaseAutoPatchService — throw to make
  //    accidental coupling loud during refactors.
  @override
  dynamic noSuchMethod(Invocation i) {
    throw UnimplementedError(
      '_FakeSupabaseService.${i.memberName.toString()} not stubbed',
    );
  }
}

class _FakeCaseRepository implements CaseRepository {
  _FakeCaseRepository(this.cases);

  List<UserCase> cases;
  int listCallCount = 0;
  int getCallCount = 0;

  @override
  Future<List<UserCase>> listCases({CaseListFilter filter = CaseListFilter.active}) async {
    listCallCount++;
    return cases;
  }

  @override
  Future<UserCase?> getCase(String id) async {
    getCallCount++;
    return cases.cast<UserCase?>().firstWhere(
      (c) => c?.id == id,
      orElse: () => null,
    );
  }

  @override
  Future<UserCase> createCase({
    required String title,
    required String jurisdiction,
    String? caseType,
    String language = 'ru',
  }) async => throw UnimplementedError();

  @override
  Future<UserCase> updateCase(UserCase updated) async => throw UnimplementedError();

  @override
  Future<void> archiveCase(String id) async => throw UnimplementedError();

  @override
  Future<void> closeCase(String id) async => throw UnimplementedError();

  @override
  Future<List<CaseDocument>> listDocuments(String caseId) async => const [];
}

UserCase _stubCase(String id) => UserCase(
      id: id,
      userId: 'user-1',
      title: 'Test',
      jurisdiction: 'EE',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );

// =====================================================================
// Tests
// =====================================================================

void main() {
  group('CaseAutoPatchService.patchCase — input validation', () {
    test('rejects empty caseId without POST', () async {
      final supa = _FakeSupabaseService();
      final svc = CaseAutoPatchService.forTest(supabase: supa);
      final out = await svc.patchCase(
        caseId: '',
        userMessage: 'u',
        aiReply: 'a',
      );
      expect(out, CaseAutoPatchOutcome.invalidInput);
      expect(supa.callCount, 0);
    });

    test("rejects synthetic 'general' id without POST", () async {
      final supa = _FakeSupabaseService();
      final svc = CaseAutoPatchService.forTest(supabase: supa);
      final out = await svc.patchCase(
        caseId: 'general',
        userMessage: 'u',
        aiReply: 'a',
      );
      expect(out, CaseAutoPatchOutcome.invalidInput);
      expect(supa.callCount, 0);
    });

    test('rejects when both messages are empty', () async {
      final supa = _FakeSupabaseService();
      final svc = CaseAutoPatchService.forTest(supabase: supa);
      final out = await svc.patchCase(
        caseId: _validUuid,
        userMessage: '',
        aiReply: '',
      );
      expect(out, CaseAutoPatchOutcome.invalidInput);
      expect(supa.callCount, 0);
    });

    test('demo mode skips without POST', () async {
      final supa = _FakeSupabaseService(demo: true);
      final svc = CaseAutoPatchService.forTest(supabase: supa);
      final out = await svc.patchCase(
        caseId: _validUuid,
        userMessage: 'u',
        aiReply: 'a',
      );
      expect(out, CaseAutoPatchOutcome.demoSkip);
      expect(supa.callCount, 0);
    });
  });

  group('CaseAutoPatchService.patchCase — POST shape', () {
    test('posts {case_id, user_msg, ai_reply} to case-auto-patch', () async {
      final supa = _FakeSupabaseService(
        response: {'patched': false, 'reason': 'no_changes'},
      );
      final svc = CaseAutoPatchService.forTest(supabase: supa);
      await svc.patchCase(
        caseId: _validUuid,
        userMessage: 'When is the deadline?',
        aiReply: '30 days from notification per HMS § 26.',
      );
      expect(supa.lastFunctionName, 'case-auto-patch');
      expect(supa.lastBody?['case_id'], _validUuid);
      expect(supa.lastBody?['user_msg'], 'When is the deadline?');
      expect(supa.lastBody?['ai_reply'],
          '30 days from notification per HMS § 26.');
    });

    test('trims oversize messages to 8 KB cap', () async {
      final long = 'a' * (CaseAutoPatchService.maxInputChars + 100);
      final supa = _FakeSupabaseService(
        response: {'patched': false, 'reason': 'no_changes'},
      );
      final svc = CaseAutoPatchService.forTest(supabase: supa);
      await svc.patchCase(
        caseId: _validUuid,
        userMessage: long,
        aiReply: long,
      );
      expect(
        (supa.lastBody?['user_msg'] as String).length,
        CaseAutoPatchService.maxInputChars,
      );
      expect(
        (supa.lastBody?['ai_reply'] as String).length,
        CaseAutoPatchService.maxInputChars,
      );
    });
  });

  group('CaseAutoPatchService.patchCase — outcome mapping', () {
    test('returns patched on {patched: true}', () async {
      final supa = _FakeSupabaseService(
        response: {'patched': true, 'fields_changed': ['summary']},
      );
      final svc = CaseAutoPatchService.forTest(supabase: supa);
      final out = await svc.patchCase(
        caseId: _validUuid,
        userMessage: 'u',
        aiReply: 'a',
      );
      expect(out, CaseAutoPatchOutcome.patched);
    });

    test('returns noChange on {patched: false}', () async {
      final supa = _FakeSupabaseService(
        response: {'patched': false, 'reason': 'no_changes'},
      );
      final svc = CaseAutoPatchService.forTest(supabase: supa);
      final out = await svc.patchCase(
        caseId: _validUuid,
        userMessage: 'u',
        aiReply: 'a',
      );
      expect(out, CaseAutoPatchOutcome.noChange);
    });

    test('returns noChange on {patched: false, reason: invalid_json}', () async {
      final supa = _FakeSupabaseService(
        response: {'patched': false, 'reason': 'invalid_json'},
      );
      final svc = CaseAutoPatchService.forTest(supabase: supa);
      final out = await svc.patchCase(
        caseId: _validUuid,
        userMessage: 'u',
        aiReply: 'a',
      );
      expect(out, CaseAutoPatchOutcome.noChange);
    });

    test('returns forbidden on 403-style error message', () async {
      final supa = _FakeSupabaseService(
        response: {'error': 'Forbidden: case not owned by caller'},
      );
      final svc = CaseAutoPatchService.forTest(supabase: supa);
      final out = await svc.patchCase(
        caseId: _validUuid,
        userMessage: 'u',
        aiReply: 'a',
      );
      expect(out, CaseAutoPatchOutcome.forbidden);
    });

    test('returns forbidden on 401-style error message', () async {
      final supa = _FakeSupabaseService(
        response: {'error': 'Unauthorized'},
      );
      final svc = CaseAutoPatchService.forTest(supabase: supa);
      final out = await svc.patchCase(
        caseId: _validUuid,
        userMessage: 'u',
        aiReply: 'a',
      );
      expect(out, CaseAutoPatchOutcome.forbidden);
    });

    test('returns error on generic network error string', () async {
      final supa = _FakeSupabaseService(
        response: {'error': 'Edge function timeout'},
      );
      final svc = CaseAutoPatchService.forTest(supabase: supa);
      final out = await svc.patchCase(
        caseId: _validUuid,
        userMessage: 'u',
        aiReply: 'a',
      );
      expect(out, CaseAutoPatchOutcome.error);
    });

    test('returns error on null response (no JSON decodable)', () async {
      final supa = _FakeSupabaseService(response: null);
      final svc = CaseAutoPatchService.forTest(supabase: supa);
      final out = await svc.patchCase(
        caseId: _validUuid,
        userMessage: 'u',
        aiReply: 'a',
      );
      expect(out, CaseAutoPatchOutcome.error);
    });

    test('NEVER throws when callEdgeFunction throws', () async {
      final supa = _FakeSupabaseService(throwsOnCall: true);
      final svc = CaseAutoPatchService.forTest(supabase: supa);
      // The whole point: caller's `unawaited(...)` must never see an
      // exception bubble up.
      final out = await svc.patchCase(
        caseId: _validUuid,
        userMessage: 'u',
        aiReply: 'a',
      );
      expect(out, CaseAutoPatchOutcome.error);
    });
  });

  group('CaseAutoPatchService.patchCase — provider invalidation', () {
    test('invalidates caseByIdProvider + casesListProvider on patched=true',
        () async {
      final repo = _FakeCaseRepository([_stubCase(_validUuid)]);
      final supa = _FakeSupabaseService(
        response: {'patched': true, 'fields_changed': ['summary']},
      );

      final container = ProviderContainer(overrides: [
        caseRepositoryProvider.overrideWithValue(repo),
        supabaseServiceProvider.overrideWithValue(supa),
      ]);
      addTearDown(container.dispose);

      // Prime the providers — ensure they have run once.
      await container.read(caseByIdProvider(_validUuid).future);
      await container.read(casesListProvider(CaseListFilter.active).future);
      final beforeGetCount = repo.getCallCount;
      final beforeListCount = repo.listCallCount;

      // Sanity: priming actually hit the repo once each.
      expect(beforeGetCount, 1);
      expect(beforeListCount, 1);

      final svc = container.read(caseAutoPatchServiceProvider);
      final out = await svc.patchCase(
        caseId: _validUuid,
        userMessage: 'u',
        aiReply: 'a',
      );
      expect(out, CaseAutoPatchOutcome.patched);

      // Re-read — invalidation should have cleared cached results, so
      // the repo gets called again.
      await container.read(caseByIdProvider(_validUuid).future);
      await container.read(casesListProvider(CaseListFilter.active).future);
      expect(repo.getCallCount, beforeGetCount + 1,
          reason: 'caseByIdProvider should have been invalidated');
      expect(repo.listCallCount, beforeListCount + 1,
          reason: 'casesListProvider should have been invalidated');
    });

    test('does NOT invalidate when patched=false', () async {
      final repo = _FakeCaseRepository([_stubCase(_validUuid)]);
      final supa = _FakeSupabaseService(
        response: {'patched': false, 'reason': 'no_changes'},
      );

      final container = ProviderContainer(overrides: [
        caseRepositoryProvider.overrideWithValue(repo),
        supabaseServiceProvider.overrideWithValue(supa),
      ]);
      addTearDown(container.dispose);

      await container.read(caseByIdProvider(_validUuid).future);
      await container.read(casesListProvider(CaseListFilter.active).future);
      final beforeGetCount = repo.getCallCount;
      final beforeListCount = repo.listCallCount;

      final svc = container.read(caseAutoPatchServiceProvider);
      await svc.patchCase(
        caseId: _validUuid,
        userMessage: 'u',
        aiReply: 'a',
      );

      // Re-read — should still be cached.
      await container.read(caseByIdProvider(_validUuid).future);
      await container.read(casesListProvider(CaseListFilter.active).future);
      expect(repo.getCallCount, beforeGetCount,
          reason: 'should NOT have invalidated caseByIdProvider on no_change');
      expect(repo.listCallCount, beforeListCount,
          reason: 'should NOT have invalidated casesListProvider on no_change');
    });
  });
}
