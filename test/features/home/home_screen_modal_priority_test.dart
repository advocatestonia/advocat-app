// =============================================================================
// Regression guard for HomeScreen bootstrap modal priority queue.
// =============================================================================
//
// On 2026-05-27 the design audit flagged that HomeScreen.initState fired six
// modal triggers in parallel (welcome + B2B + referral + GDPR + checkout +
// onboarding bootstrap). Cold-start could stack 3+ modal surfaces within
// ~2s — a textbook cognitive-load failure.
//
// The refactor introduces:
//
//   * `lib/features/home/bootstrap/home_bootstrap.dart` — pure cool-down
//     decision functions + priority enum.
//   * `HomeScreen._runBootstrapQueue` — serial async runner that awaits
//     each modal dismissal before the next.
//
// We unit-test the policy module rather than pumping the full HomeScreen
// because the screen requires Supabase + Riverpod + GoRouter scaffolding
// that is unrelated to the priority order itself. The shape of the test
// matches `home_quick_actions_layout_test.dart` (source-string assertions
// for the integration site, behavioural assertions for the pure module).
//
// If a future refactor moves these gates or shuffles the order, update
// the tests deliberately — they exist to make accidental drift loud.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:advocat/features/home/bootstrap/home_bootstrap.dart';
import 'package:advocat/features/referral/referral_nudge.dart';

void main() {
  group('BootstrapModal priority order', () {
    test('priority list opens with gdpr and ends with referral', () {
      // The order is a contract: GDPR must be index 0 (legal blocking),
      // referral must be last (opportunistic). Anything in between can
      // be reshuffled but the bookends are load-bearing.
      expect(kBootstrapPriorityOrder.first, BootstrapModal.gdpr);
      expect(kBootstrapPriorityOrder.last, BootstrapModal.referral);
    });

    test('pendingCheckout comes before welcome (paying user > onboarding)',
        () {
      // Rationale: a user who just paid should not see the welcome modal
      // before their checkout return is processed — that would feel like
      // their payment was ignored.
      final checkoutIdx =
          kBootstrapPriorityOrder.indexOf(BootstrapModal.pendingCheckout);
      final welcomeIdx =
          kBootstrapPriorityOrder.indexOf(BootstrapModal.welcome);
      expect(checkoutIdx, lessThan(welcomeIdx));
    });

    test('b2b comes after welcome (onboarding > opportunistic upsell)', () {
      // Rationale: brand-new users get the standard welcome first; the
      // B2B nudge is a second-session-or-later trigger by design.
      final welcomeIdx =
          kBootstrapPriorityOrder.indexOf(BootstrapModal.welcome);
      final b2bIdx = kBootstrapPriorityOrder.indexOf(BootstrapModal.b2b);
      expect(welcomeIdx, lessThan(b2bIdx));
    });
  });

  group('shouldShowGdprConsentForMajorVersion', () {
    setUp(() {
      // Each test gets a clean SharedPreferences sandbox.
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('returns true when no version has been recorded', () async {
      final prefs = await SharedPreferences.getInstance();
      final should = await shouldShowGdprConsentForMajorVersion(
        currentMajorVersion: '1',
        prefs: prefs,
      );
      expect(should, isTrue,
          reason: 'first-run user must be prompted for consent');
    });

    test('returns false after acceptance for the same major version',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await markGdprAcceptedForMajorVersion(
        currentMajorVersion: '1',
        prefs: prefs,
      );
      final should = await shouldShowGdprConsentForMajorVersion(
        currentMajorVersion: '1',
        prefs: prefs,
      );
      expect(should, isFalse,
          reason: 'do not re-prompt within the same major version');
    });

    test('returns true when major version bumps (ToS rev)', () async {
      final prefs = await SharedPreferences.getInstance();
      await markGdprAcceptedForMajorVersion(
        currentMajorVersion: '1',
        prefs: prefs,
      );
      final should = await shouldShowGdprConsentForMajorVersion(
        currentMajorVersion: '2',
        prefs: prefs,
      );
      expect(should, isTrue,
          reason: 're-prompt when terms change in a new major version');
    });
  });

  group('shouldShowB2bModal cool-down', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('allows showing when no prior impression exists', () async {
      final prefs = await SharedPreferences.getInstance();
      final should = await shouldShowB2bModal(prefs: prefs);
      expect(should, isTrue);
    });

    test('blocks within 7-day window', () async {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.utc(2026, 5, 27, 12);
      // Last shown 6 days ago — still in the cool-down window.
      await markB2bModalShown(
        now: now.subtract(const Duration(days: 6)),
        prefs: prefs,
      );
      final should = await shouldShowB2bModal(now: now, prefs: prefs);
      expect(should, isFalse,
          reason: '6-day-old impression must still suppress the modal');
    });

    test('allows again after 7 days have elapsed', () async {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.utc(2026, 5, 27, 12);
      await markB2bModalShown(
        now: now.subtract(const Duration(days: 8)),
        prefs: prefs,
      );
      final should = await shouldShowB2bModal(now: now, prefs: prefs);
      expect(should, isTrue,
          reason: '8-day-old impression is outside the cool-down');
    });
  });

  group('withinReferralCooldown 14-day window', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('allows when never shown and not referral-seen', () async {
      final prefs = await SharedPreferences.getInstance();
      final should = await withinReferralCooldown(prefs: prefs);
      expect(should, isTrue);
    });

    test('blocks when user opened /referral (referral_seen=true)', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kReferralSeenPrefKey, true);
      final should = await withinReferralCooldown(prefs: prefs);
      expect(should, isFalse);
    });

    test('blocks within 14 days of the last snackbar nudge', () async {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.utc(2026, 5, 27, 12);
      await markReferralNudgeShown(
        now: now.subtract(const Duration(days: 10)),
        prefs: prefs,
      );
      final should = await withinReferralCooldown(now: now, prefs: prefs);
      expect(should, isFalse);
    });
  });

  group('HomeScreen source — bootstrap queue is serial', () {
    // Source-string check (same style as `home_quick_actions_layout_test`).
    // The point is to make accidental "revert to parallel fire-and-forget"
    // refactors loud at test-time, before they ship.
    late String source;

    setUpAll(() {
      source =
          File('lib/features/home/screens/home_screen.dart').readAsStringSync();
    });

    test('initState routes modals through _runBootstrapQueue (not parallel)',
        () {
      // The serial runner is mandatory — its absence means a future agent
      // reverted to chained fire-and-forget calls.
      expect(source.contains('_runBootstrapQueue'), isTrue,
          reason: 'serial bootstrap runner method must exist');
      expect(source.contains('await _checkGdprConsent()'), isTrue,
          reason: 'GDPR must be awaited (blocking)');
      expect(source.contains('await _checkPendingCheckout()'), isTrue,
          reason: 'checkout must be awaited (sequential)');
    });

    test('referral nudge is no longer fire-and-forget from initState', () {
      // Find the initState body.
      final initIdx = source.indexOf('void initState()');
      expect(initIdx, greaterThan(0));
      // Grab the next ~60 lines — the body is short.
      final initBody = source.substring(
        initIdx,
        (initIdx + 3000).clamp(0, source.length),
      );
      // The OLD code called `_maybeShowReferralNudge();` directly inside
      // initState. After the refactor that call is removed; the method
      // body still exists for future re-enablement but is gated behind
      // `// ignore: unused_element`.
      expect(initBody.contains('_maybeShowReferralNudge()'), isFalse,
          reason:
              'referral nudge must NOT be triggered from home cold-start');
    });
  });
}
