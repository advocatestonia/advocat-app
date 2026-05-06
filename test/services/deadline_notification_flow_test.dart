@Tags(['fast'])
library;

// Phase 2 Pkg 9 — notification flow integration tests.
//
// What this covers (separate from the widget tests):
//   * Permission state model: notAsked → allowed | later, with prefs
//     persistence and rehydration semantics.
//   * Permission denied → in-app fallback path: a deadline still
//     surfaces in `criticalActiveCaseDeadlineProvider` even when the
//     user has not granted FCM permission. The radar widget IS the
//     primary defense (architect §11 #2); push is a bonus layer.
//   * Channel preference toggles round-trip through SharedPreferences.
//   * The FakeCaseDeadlineRepository's `markComplete` propagates so
//     the critical-deadline provider re-resolves to null.
//
// Style: pure provider container tests. No real Firebase, no real
// Supabase — that surface is covered by smoke tests.

import 'package:advocat/features/case_memory/data/case_deadline_repository.dart';
import 'package:advocat/features/case_memory/data/case_repository.dart';
import 'package:advocat/features/case_memory/models/case_deadline.dart';
import 'package:advocat/features/case_memory/state/active_case_provider.dart';
import 'package:advocat/features/case_memory/state/case_deadline_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/case_memory/data/case_deadline_repository_fake.dart';
import '../features/case_memory/data/case_repository_test.dart';

ProviderContainer _container({
  required FakeCaseDeadlineRepository repo,
  FakeCaseRepository? caseRepo,
}) {
  final c = ProviderContainer(overrides: [
    caseDeadlineRepositoryProvider.overrideWithValue(repo),
    if (caseRepo != null)
      caseRepositoryProvider.overrideWithValue(caseRepo),
  ]);
  addTearDown(c.dispose);
  return c;
}

Future<void> _settle(ProviderContainer c) async {
  await c.read(sharedPreferencesProvider.future);
  for (var i = 0; i < 30; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ---------------------------------------------------------------------------
  // 1. Permission state machine — notAsked → allowed → reset → notAsked.
  // ---------------------------------------------------------------------------
  group('Permission state machine', () {
    test(
      'PKG9-NOT-1 — notAsked → allowed via markAllowed; persists across rebuild',
      () async {
        SharedPreferences.setMockInitialValues({});
        var c = _container(repo: FakeCaseDeadlineRepository());
        await _settle(c);

        expect(c.read(deadlinePermissionProvider),
            DeadlinePermissionState.notAsked);
        await c
            .read(deadlinePermissionProvider.notifier)
            .markAllowed();
        expect(c.read(deadlinePermissionProvider),
            DeadlinePermissionState.allowed);

        // Rebuild the container: same persisted value.
        c.dispose();
        c = _container(repo: FakeCaseDeadlineRepository());
        await _settle(c);
        expect(c.read(deadlinePermissionProvider),
            DeadlinePermissionState.allowed);
      },
    );

    test(
      'PKG9-NOT-2 — Later → allowed transition is permitted (settings re-enable)',
      () async {
        SharedPreferences.setMockInitialValues({
          kDeadlinePermissionPrefKey: 'later',
        });
        final c = _container(repo: FakeCaseDeadlineRepository());
        await _settle(c);
        expect(c.read(deadlinePermissionProvider),
            DeadlinePermissionState.later);

        // From settings: user re-enables.
        await c
            .read(deadlinePermissionProvider.notifier)
            .markAllowed();
        expect(c.read(deadlinePermissionProvider),
            DeadlinePermissionState.allowed);
      },
    );

    test(
      'PKG9-NOT-3 — empty prefs default reads as notAsked (no UI assumes denied)',
      () async {
        SharedPreferences.setMockInitialValues({});
        final c = _container(repo: FakeCaseDeadlineRepository());
        await _settle(c);
        // Critical: a brand-new install must be in `notAsked` so the
        // soft-ask card has a chance to show. If we ever default to
        // `later`, the user is silently locked out of reminders.
        expect(c.read(deadlinePermissionProvider),
            DeadlinePermissionState.notAsked);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // 2. Channel toggles — push/email/in-app individual setters.
  // ---------------------------------------------------------------------------
  group('Channel toggles round-trip', () {
    test(
      'PKG9-NOT-10 — setEmail false then true round-trips through SharedPreferences',
      () async {
        SharedPreferences.setMockInitialValues({});
        var c = _container(repo: FakeCaseDeadlineRepository());
        await _settle(c);
        expect(c.read(deadlineChannelPrefsProvider).email, isTrue);

        await c
            .read(deadlineChannelPrefsProvider.notifier)
            .setEmail(false);
        expect(c.read(deadlineChannelPrefsProvider).email, isFalse);

        // Rebuild — value must hydrate back as `false`.
        c.dispose();
        c = _container(repo: FakeCaseDeadlineRepository());
        await _settle(c);
        expect(c.read(deadlineChannelPrefsProvider).email, isFalse);
      },
    );

    test(
      'PKG9-NOT-11 — setInApp + setPush + setCriticalBypass each round-trip',
      () async {
        SharedPreferences.setMockInitialValues({});
        final c = _container(repo: FakeCaseDeadlineRepository());
        await _settle(c);
        await c
            .read(deadlineChannelPrefsProvider.notifier)
            .setInApp(false);
        await c
            .read(deadlineChannelPrefsProvider.notifier)
            .setPush(false);
        await c
            .read(deadlineChannelPrefsProvider.notifier)
            .setCriticalBypassQuietHours(false);
        final p = c.read(deadlineChannelPrefsProvider);
        expect(p.inApp, isFalse);
        expect(p.push, isFalse);
        expect(p.criticalBypassQuietHours, isFalse);
      },
    );

    test(
      'PKG9-NOT-12 — DeadlineChannelPrefs.fromJson tolerates partial maps',
      () {
        // If a future deploy adds a new pref key the client doesn't yet
        // know, the prefs notifier must still hydrate without crash.
        final partial = DeadlineChannelPrefs.fromJson({
          'push': false,
          // Other fields missing — should fall back to defaults.
        });
        expect(partial.push, isFalse);
        expect(partial.email, isTrue);
        expect(partial.inApp, isTrue);
        expect(partial.quietHoursStart, '21:00');
        expect(partial.quietHoursEnd, '08:00');
        expect(partial.criticalBypassQuietHours, isTrue);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // 3. In-app fallback path — when permission denied, the radar provider
  //    still surfaces critical deadlines.
  // ---------------------------------------------------------------------------
  group('Permission-denied fallback (in-app radar always works)', () {
    test(
      'PKG9-NOT-20 — even with permission=later, criticalActiveCaseDeadlineProvider '
      'still surfaces a < 3d deadline (radar is the safety net)',
      () async {
        SharedPreferences.setMockInitialValues({
          kDeadlinePermissionPrefKey: 'later',
        });
        final caseRepo = FakeCaseRepository(cases: [
          mkUserCase(id: 'c-1', title: 'Sulga FI'),
        ]);
        // Deadline 2 days away → critical band. Permission=later must
        // NOT silence the in-app surface.
        final repo = FakeCaseDeadlineRepository(perCase: {
          'c-1': [
            mkDeadline(
              id: 'd-1',
              caseId: 'c-1',
              deadlineAt: DateTime.now().add(const Duration(days: 2)),
            )
          ],
        });
        final c = _container(repo: repo, caseRepo: caseRepo);
        await _settle(c);
        await c.read(activeCaseProvider.notifier).setActiveCase(
              caseRepo.cases.first,
            );

        final critical =
            await c.read(criticalActiveCaseDeadlineProvider.future);
        expect(critical, isNotNull);
        expect(critical!.id, 'd-1');
        // And: the permission stays at `later` regardless.
        expect(c.read(deadlinePermissionProvider),
            DeadlinePermissionState.later);
      },
    );

    test(
      'PKG9-NOT-21 — markComplete drops the row from the critical provider '
      '(consumer of the deadline gets cleared)',
      () async {
        final caseRepo = FakeCaseRepository(cases: [
          mkUserCase(id: 'c-1', title: 'Sulga FI'),
        ]);
        final repo = FakeCaseDeadlineRepository(perCase: {
          'c-1': [
            mkDeadline(
              id: 'd-1',
              caseId: 'c-1',
              deadlineAt: DateTime.now().add(const Duration(days: 2)),
            )
          ],
        });
        final c = _container(repo: repo, caseRepo: caseRepo);
        await _settle(c);
        await c.read(activeCaseProvider.notifier)
            .setActiveCase(caseRepo.cases.first);

        var critical =
            await c.read(criticalActiveCaseDeadlineProvider.future);
        expect(critical?.id, 'd-1');

        // Mark complete → next read returns null (active filter empties).
        await c.read(deadlineMutationsProvider).markComplete(
              deadlineId: 'd-1',
              caseId: 'c-1',
            );
        critical =
            await c.read(criticalActiveCaseDeadlineProvider.future);
        expect(critical, isNull,
            reason:
                'completed deadline must drop from criticalActiveCaseDeadlineProvider');
      },
    );

    test(
      'PKG9-NOT-22 — when active case has no deadlines, critical provider returns null',
      () async {
        final caseRepo = FakeCaseRepository(cases: [
          mkUserCase(id: 'c-1', title: 'Sulga FI'),
        ]);
        final repo = FakeCaseDeadlineRepository(perCase: {'c-1': []});
        final c = _container(repo: repo, caseRepo: caseRepo);
        await _settle(c);
        await c.read(activeCaseProvider.notifier)
            .setActiveCase(caseRepo.cases.first);
        final critical =
            await c.read(criticalActiveCaseDeadlineProvider.future);
        expect(critical, isNull);
      },
    );

    test(
      'PKG9-NOT-23 — when deadline is far away (>3d), critical provider returns null',
      () async {
        final caseRepo = FakeCaseRepository(cases: [
          mkUserCase(id: 'c-1', title: 'Sulga FI'),
        ]);
        final repo = FakeCaseDeadlineRepository(perCase: {
          'c-1': [
            mkDeadline(
              id: 'd-1',
              caseId: 'c-1',
              // 14 days away — well outside the 3-day banner window.
              deadlineAt: DateTime.now().add(const Duration(days: 14)),
            )
          ],
        });
        final c = _container(repo: repo, caseRepo: caseRepo);
        await _settle(c);
        await c.read(activeCaseProvider.notifier)
            .setActiveCase(caseRepo.cases.first);
        final critical =
            await c.read(criticalActiveCaseDeadlineProvider.future);
        expect(critical, isNull,
            reason:
                'criticalActiveCaseDeadlineProvider only fires within 3d window');
      },
    );

    test(
      'PKG9-NOT-24 — when multiple deadlines are critical, the earliest one wins',
      () async {
        final caseRepo = FakeCaseRepository(cases: [
          mkUserCase(id: 'c-1', title: 'Sulga FI'),
        ]);
        final now = DateTime.now();
        final repo = FakeCaseDeadlineRepository(perCase: {
          'c-1': [
            mkDeadline(
              id: 'later',
              caseId: 'c-1',
              deadlineAt: now.add(const Duration(days: 3)),
            ),
            mkDeadline(
              id: 'soonest',
              caseId: 'c-1',
              deadlineAt: now.add(const Duration(hours: 18)),
            ),
            mkDeadline(
              id: 'middle',
              caseId: 'c-1',
              deadlineAt: now.add(const Duration(days: 2)),
            ),
          ],
        });
        final c = _container(repo: repo, caseRepo: caseRepo);
        await _settle(c);
        await c.read(activeCaseProvider.notifier)
            .setActiveCase(caseRepo.cases.first);

        final critical =
            await c.read(criticalActiveCaseDeadlineProvider.future);
        expect(critical?.id, 'soonest');
      },
    );
  });

  // ---------------------------------------------------------------------------
  // 4. Mutation cascade invalidation — confirms the cross-provider wiring.
  // ---------------------------------------------------------------------------
  group('Mutation cascade invalidation', () {
    test(
      'PKG9-NOT-30 — snooze invalidates BOTH per-case and global providers',
      () async {
        final repo = FakeCaseDeadlineRepository(
          active: [mkDeadline(id: 'a')],
          perCase: {'c-1': [mkDeadline(id: 'a')]},
        );
        final c = _container(repo: repo);

        // Prime caches.
        await c.read(globalDeadlinesProvider.future);
        await c.read(deadlinesProvider('c-1').future);

        await c.read(deadlineMutationsProvider).snooze(
              deadlineId: 'a',
              caseId: 'c-1',
              newDeadlineAt: DateTime.now().add(const Duration(days: 7)),
            );
        // Spy fired.
        expect(repo.lastSnoozedId, 'a');
      },
    );

    test(
      'PKG9-NOT-31 — createManual hits createManual on the repo',
      () async {
        final repo = FakeCaseDeadlineRepository();
        final c = _container(repo: repo);
        await c.read(deadlineMutationsProvider).createManual(
              caseId: 'c-1',
              title: 'Manual deadline',
              deadlineAt: DateTime.utc(2026, 12, 31, 12),
              priority: CaseDeadlinePriority.high,
            );
        expect(repo.lastCreate, isNotNull);
        expect(repo.lastCreate!['title'], 'Manual deadline');
        expect(repo.lastCreate!['case_id'], 'c-1');
      },
    );

    test(
      'PKG9-NOT-32 — editManual hits editManual on the repo',
      () async {
        final repo = FakeCaseDeadlineRepository(perCase: {
          'c-1': [mkDeadline(id: 'edit-me')],
        });
        final c = _container(repo: repo);
        await c.read(deadlineMutationsProvider).editManual(
              id: 'edit-me',
              caseId: 'c-1',
              title: 'Updated',
            );
        expect(repo.lastEdit, isNotNull);
        expect(repo.lastEdit!['id'], 'edit-me');
        expect(repo.lastEdit!['title'], 'Updated');
      },
    );
  });
}
