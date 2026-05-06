// Tests for the Pkg 9 Riverpod providers + permission notifier.

import 'package:advocat/features/case_memory/data/case_deadline_repository.dart';
import 'package:advocat/features/case_memory/state/active_case_provider.dart';
import 'package:advocat/features/case_memory/state/case_deadline_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/case_deadline_repository_fake.dart';

ProviderContainer _container({
  required FakeCaseDeadlineRepository repo,
}) {
  final c = ProviderContainer(
    overrides: [
      caseDeadlineRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

/// Await the SharedPreferences future so the StateNotifierProvider has
/// the real notifier (not the stub) before we read from it.
Future<void> _settle(ProviderContainer c) async {
  await c.read(sharedPreferencesProvider.future);
  for (var i = 0; i < 30; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('globalDeadlinesProvider', () {
    test('returns the repo rows', () async {
      final repo = FakeCaseDeadlineRepository(
        active: [mkDeadline(id: 'a'), mkDeadline(id: 'b')],
      );
      final c = _container(repo: repo);
      final rows = await c.read(globalDeadlinesProvider.future);
      expect(rows.map((r) => r.id), ['a', 'b']);
    });
  });

  group('deadlinesProvider(caseId)', () {
    test('returns the per-case rows', () async {
      final repo = FakeCaseDeadlineRepository(
        perCase: {
          'c-1': [mkDeadline(id: 'x'), mkDeadline(id: 'y')],
          'c-2': [mkDeadline(id: 'z')],
        },
      );
      final c = _container(repo: repo);
      final rows = await c.read(deadlinesProvider('c-1').future);
      expect(rows.map((r) => r.id), ['x', 'y']);
    });
  });

  group('DeadlineMutations', () {
    test('markComplete invalidates per-case + global providers', () async {
      final repo = FakeCaseDeadlineRepository(
        active: [mkDeadline(id: 'a')],
        perCase: {'c-1': [mkDeadline(id: 'a')]},
      );
      final c = _container(repo: repo);
      // Read both so providers cache initial values.
      await c.read(globalDeadlinesProvider.future);
      await c.read(deadlinesProvider('c-1').future);

      await c.read(deadlineMutationsProvider).markComplete(
            deadlineId: 'a',
            caseId: 'c-1',
          );
      expect(repo.lastMarkedComplete, 'a');

      // Both providers should reflect the new (empty) active state.
      final fresh = await c.read(globalDeadlinesProvider.future);
      expect(fresh, isEmpty);
    });

    test('archive removes from active list', () async {
      final repo = FakeCaseDeadlineRepository(
        active: [mkDeadline(id: 'arch')],
      );
      final c = _container(repo: repo);
      await c.read(globalDeadlinesProvider.future);
      await c
          .read(deadlineMutationsProvider)
          .archive(deadlineId: 'arch', caseId: 'c-1');
      expect(repo.lastArchivedId, 'arch');
    });
  });

  group('DeadlinePermissionNotifier', () {
    test('initial state is notAsked when prefs are empty', () async {
      SharedPreferences.setMockInitialValues({});
      final c = _container(repo: FakeCaseDeadlineRepository());
      await _settle(c);
      final state = c.read(deadlinePermissionProvider);
      expect(state, DeadlinePermissionState.notAsked);
    });

    test('markAllowed persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final c = _container(repo: FakeCaseDeadlineRepository());
      await _settle(c);
      await c
          .read(deadlinePermissionProvider.notifier)
          .markAllowed();
      expect(c.read(deadlinePermissionProvider),
          DeadlinePermissionState.allowed);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kDeadlinePermissionPrefKey), 'allowed');
    });

    test('markLater persists', () async {
      SharedPreferences.setMockInitialValues({});
      final c = _container(repo: FakeCaseDeadlineRepository());
      await _settle(c);
      await c.read(deadlinePermissionProvider.notifier).markLater();
      expect(c.read(deadlinePermissionProvider),
          DeadlinePermissionState.later);
    });

    test('rehydrates persisted "later" choice on rebuild', () async {
      SharedPreferences.setMockInitialValues({
        kDeadlinePermissionPrefKey: 'later',
      });
      final c = _container(repo: FakeCaseDeadlineRepository());
      await _settle(c);
      expect(c.read(deadlinePermissionProvider),
          DeadlinePermissionState.later);
    });
  });

  group('DeadlineChannelPrefsNotifier', () {
    test('default prefs: push/email/in-app on, quiet 21:00–08:00', () async {
      SharedPreferences.setMockInitialValues({});
      final c = _container(repo: FakeCaseDeadlineRepository());
      await _settle(c);
      final prefs = c.read(deadlineChannelPrefsProvider);
      expect(prefs.push, isTrue);
      expect(prefs.email, isTrue);
      expect(prefs.inApp, isTrue);
      expect(prefs.criticalBypassQuietHours, isTrue);
      expect(prefs.quietHoursStart, '21:00');
      expect(prefs.quietHoursEnd, '08:00');
    });

    test('setPush persists', () async {
      SharedPreferences.setMockInitialValues({});
      final c = _container(repo: FakeCaseDeadlineRepository());
      await _settle(c);
      await c
          .read(deadlineChannelPrefsProvider.notifier)
          .setPush(false);
      expect(c.read(deadlineChannelPrefsProvider).push, isFalse);
    });
  });

  group('criticalActiveCaseDeadlineProvider', () {
    test('returns null when no active case', () async {
      final repo = FakeCaseDeadlineRepository();
      final c = _container(repo: repo);
      final v = await c.read(criticalActiveCaseDeadlineProvider.future);
      expect(v, isNull);
    });
  });
}
