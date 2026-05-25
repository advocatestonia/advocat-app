@Tags(['fast'])
library;

// Unit tests for [B2BDetectionController].
//
// We don't touch Supabase here — instead we hand the controller a fake
// [B2BService] that pretends `b2b_modal_pending` is true / false, and a
// fake modal runner + navigator that just record calls.
//
// What's covered (per brief):
//   * pending=true triggers the modal exactly once per session
//   * pending=false skips (and does NOT call markB2BModalShown)
//   * already-triggered second call no-ops
//   * dismiss path: markB2BModalShown called, no navigation
//   * learnMore path: markB2BModalShown called, navigates to /for-firms

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/b2b/providers/b2b_detection_provider.dart';
import 'package:advocat/features/b2b/services/b2b_service.dart';
import 'package:advocat/features/b2b/widgets/b2b_lead_modal.dart';

/// Stand-in for [B2BService]. Records calls so each test can assert
/// exactly what the controller did or didn't do.
class _FakeB2BService implements B2BService {
  _FakeB2BService({this.pending = false});

  bool pending;
  int fetchCallCount = 0;
  int markShownCallCount = 0;

  @override
  Future<bool> fetchB2BModalPending() async {
    fetchCallCount++;
    return pending;
  }

  @override
  Future<void> markB2BModalShown() async {
    markShownCallCount++;
  }

  // Unused in these tests but required by the interface.
  @override
  Future<B2BInquiryResult> submitInquiry({
    required String name,
    required String email,
    required String firmName,
    required String teamSize,
    required List<String> practices,
    required String biggestPainToday,
    String? language,
    String? appVersion,
  }) async {
    return const B2BInquiryResult.ok('test');
  }

  // No-op satisfies any noSuchMethod fall-through from added interface
  // members in future refactors.
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// Minimal BuildContext placeholder. The controller never reads context
/// state in these tests — both the modal runner and navigator stubs
/// accept any BuildContext.
class _DummyContext implements BuildContext {
  @override
  bool get mounted => true;

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  group('B2BDetectionController.maybeTrigger', () {
    test('pending=true: shows modal, marks shown, returns user action',
        () async {
      final svc = _FakeB2BService(pending: true);
      final modalCalls = <String>[];
      final navCalls = <String>[];

      final controller = B2BDetectionController(
        svc,
        modalRunner: (_, locale) async {
          modalCalls.add(locale);
          return B2BAction.dismiss;
        },
        navigator: (_, route) => navCalls.add(route),
      );

      final result = await controller.maybeTrigger(
        _DummyContext(),
        locale: 'en',
      );

      expect(result, B2BAction.dismiss);
      expect(modalCalls, ['en']);
      expect(svc.fetchCallCount, 1);
      expect(svc.markShownCallCount, 1,
          reason: 'dismiss must still mark the modal as shown');
      expect(navCalls, isEmpty,
          reason: 'dismiss must not navigate anywhere');
    });

    test('pending=false: no modal, no mark shown', () async {
      final svc = _FakeB2BService(pending: false);
      final modalCalls = <String>[];
      final navCalls = <String>[];

      final controller = B2BDetectionController(
        svc,
        modalRunner: (_, locale) async {
          modalCalls.add(locale);
          return B2BAction.dismiss;
        },
        navigator: (_, route) => navCalls.add(route),
      );

      final result = await controller.maybeTrigger(
        _DummyContext(),
        locale: 'en',
      );

      expect(result, isNull);
      expect(modalCalls, isEmpty);
      expect(svc.fetchCallCount, 1);
      expect(svc.markShownCallCount, 0,
          reason: 'pending=false must NOT call markB2BModalShown');
      expect(navCalls, isEmpty);
    });

    test('learnMore path: marks shown AND navigates to /for-firms',
        () async {
      final svc = _FakeB2BService(pending: true);
      final modalCalls = <String>[];
      final navCalls = <String>[];

      final controller = B2BDetectionController(
        svc,
        modalRunner: (_, locale) async {
          modalCalls.add(locale);
          return B2BAction.learnMore;
        },
        navigator: (_, route) => navCalls.add(route),
      );

      final result = await controller.maybeTrigger(
        _DummyContext(),
        locale: 'et',
      );

      expect(result, B2BAction.learnMore);
      expect(modalCalls, ['et']);
      expect(svc.markShownCallCount, 1);
      expect(navCalls, [kForFirmsRoute]);
      expect(kForFirmsRoute, '/for-firms');
    });

    test('triggeredThisSession gate: second call no-ops even if pending=true',
        () async {
      final svc = _FakeB2BService(pending: true);
      int modalRuns = 0;

      final controller = B2BDetectionController(
        svc,
        modalRunner: (_, __) async {
          modalRuns++;
          return B2BAction.dismiss;
        },
        navigator: (_, __) {},
      );

      await controller.maybeTrigger(_DummyContext(), locale: 'en');
      // Second call should NOT fetch again or open the modal.
      final second = await controller.maybeTrigger(
        _DummyContext(),
        locale: 'en',
      );

      expect(second, isNull);
      expect(modalRuns, 1);
      expect(svc.fetchCallCount, 1,
          reason: 'session gate must short-circuit before fetching');
    });

    test('pending=false STILL sets triggeredThisSession (no re-fetch)',
        () async {
      final svc = _FakeB2BService(pending: false);
      final controller = B2BDetectionController(
        svc,
        modalRunner: (_, __) async => B2BAction.dismiss,
        navigator: (_, __) {},
      );

      await controller.maybeTrigger(_DummyContext(), locale: 'en');
      await controller.maybeTrigger(_DummyContext(), locale: 'en');

      // Second call should short-circuit on the session gate, NOT
      // round-trip again.
      expect(svc.fetchCallCount, 1);
    });
  });
}
