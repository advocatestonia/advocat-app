import 'package:advocat/features/case_memory/data/case_repository.dart';
import 'package:advocat/features/case_memory/models/user_case.dart';
import 'package:advocat/features/case_memory/state/active_case_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/case_repository_test.dart';

UserCase _mkCase({String id = 'c-1', String title = 'Test'}) {
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

ProviderContainer _makeContainer({required CaseRepository repo}) {
  final container = ProviderContainer(
    overrides: [
      caseRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Drains the microtask queue until the SharedPreferences write
/// (kicked off by setActiveCase) has flushed. We use a small bounded
/// loop so a hung future fails the test instead of hanging forever.
Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('ActiveCaseNotifier — initial state', () {
    test('starts with no active case', () async {
      final container = _makeContainer(repo: FakeCaseRepository());
      final state = container.read(activeCaseProvider);
      expect(state.activeCase, isNull);
      expect(state.activeCaseId, isNull);
    });
  });

  group('ActiveCaseNotifier — setActiveCase', () {
    test('updates state synchronously', () async {
      final container = _makeContainer(repo: FakeCaseRepository());
      final notifier = container.read(activeCaseProvider.notifier);
      final c = _mkCase(id: 'sulga-fi', title: 'Sulga FI');
      await notifier.setActiveCase(c);

      final state = container.read(activeCaseProvider);
      expect(state.activeCase, equals(c));
      expect(state.activeCaseId, 'sulga-fi');
      expect(notifier.currentActiveCaseId(), 'sulga-fi');
    });

    test('persists case id to SharedPreferences', () async {
      final container = _makeContainer(repo: FakeCaseRepository());
      final notifier = container.read(activeCaseProvider.notifier);
      await notifier.setActiveCase(_mkCase(id: 'persisted'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kActiveCaseIdPrefKey), 'persisted');
    });

    test('setting null removes persisted id', () async {
      // Seed prefs with a stale id first.
      SharedPreferences.setMockInitialValues({
        kActiveCaseIdPrefKey: 'old-id',
      });
      final container = _makeContainer(repo: FakeCaseRepository());
      final notifier = container.read(activeCaseProvider.notifier);

      await notifier.setActiveCase(null);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kActiveCaseIdPrefKey), isNull);
    });

    test('clearActiveCase is equivalent to setActiveCase(null)', () async {
      final container = _makeContainer(repo: FakeCaseRepository());
      final notifier = container.read(activeCaseProvider.notifier);
      await notifier.setActiveCase(_mkCase());
      await notifier.clearActiveCase();
      expect(container.read(activeCaseProvider).activeCase, isNull);
      expect(notifier.currentActiveCaseId(), isNull);
    });
  });

  group('ActiveCaseNotifier — rehydrate on startup', () {
    test('loads persisted case via repo.getCase', () async {
      final c = _mkCase(id: 'persisted-1', title: 'Restored');
      SharedPreferences.setMockInitialValues({
        kActiveCaseIdPrefKey: 'persisted-1',
      });
      final repo = FakeCaseRepository(cases: [c]);
      final container = _makeContainer(repo: repo);

      // Reading the provider triggers construction and rehydrate.
      container.read(activeCaseProvider);
      await _settle();

      expect(container.read(activeCaseProvider).activeCase?.id, 'persisted-1');
      expect(repo.lastGetId, 'persisted-1');
    });

    test('clears stale id when repo cannot find the case', () async {
      SharedPreferences.setMockInitialValues({
        kActiveCaseIdPrefKey: 'ghost',
      });
      // Empty repo: getCase('ghost') will throw, repo treats as missing.
      // We need a repo that returns null instead of throwing for clean
      // rehydrate semantics — adapt the fake to match.
      final repo = _NullOnMissingRepo();
      final container = _makeContainer(repo: repo);

      container.read(activeCaseProvider);
      await _settle();

      expect(container.read(activeCaseProvider).activeCase, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kActiveCaseIdPrefKey), isNull,
          reason: 'stale id should be removed');
    });

    test('does nothing when no persisted id', () async {
      final container = _makeContainer(repo: FakeCaseRepository());
      container.read(activeCaseProvider);
      await _settle();
      expect(container.read(activeCaseProvider).activeCase, isNull);
    });
  });
}

/// Variant of FakeCaseRepository whose getCase returns null instead of
/// throwing when the id is unknown — that's the contract real
/// SupabaseCaseRepository follows.
class _NullOnMissingRepo extends FakeCaseRepository {
  @override
  Future<UserCase?> getCase(String id) async {
    lastGetId = id;
    final found = cases.where((c) => c.id == id);
    return found.isEmpty ? null : found.first;
  }
}
