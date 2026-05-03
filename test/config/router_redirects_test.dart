@Tags(['fast'])
library;

// =============================================================================
// Regression guard for 404-recovery redirects (Fix #3 from QA report
// 2026-05-03).
// =============================================================================
//
// The QA pass found that bare /profile, /chat, /documents and /case/<id>
// dead-ended on a "Page not found:" screen with no recovery affordance.
// Owner approved redirecting them to:
//   /profile      → /settings  (profile lives inside settings)
//   /chat         → /home      (chat needs a caseId; bare path is invalid)
//   /documents    → /home      (TODO: dedicated documents listing screen)
//   /case/<id>    → /home      (TODO: alias to /cases/<id>)
//
// We boot a tiny GoRouter that mirrors the redirect rules and assert the
// resolved location for each entry path. We also do a light source-grep
// regression check on `lib/config/router.dart` so accidental deletion of
// any of these GoRoutes is loud.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:advocat/config/router.dart';

GoRouter _buildRedirectOnlyRouter() {
  // Mirror the production redirect rules (only) so we can resolve paths
  // without booting Riverpod, Supabase, or any feature screens.
  return GoRouter(
    initialLocation: '/profile',
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const Scaffold(body: Text('home')),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, __) => const Scaffold(body: Text('settings')),
      ),
      GoRoute(
        path: '/profile',
        redirect: (_, __) => AppRoutes.settings,
      ),
      GoRoute(
        path: '/chat',
        redirect: (_, __) => AppRoutes.home,
      ),
      GoRoute(
        path: '/documents',
        redirect: (_, __) => AppRoutes.home,
      ),
      GoRoute(
        path: '/case/:id',
        redirect: (_, __) => AppRoutes.home,
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Text('Page not found: ${state.matchedLocation}'),
    ),
  );
}

Future<String> _resolveLocation(WidgetTester tester, String path) async {
  final router = _buildRedirectOnlyRouter();
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  router.go(path);
  await tester.pumpAndSettle();
  // ignore: deprecated_member_use
  return router.routerDelegate.currentConfiguration.fullPath;
}

void main() {
  group('404-recovery redirects (QA report 2026-05-03)', () {
    testWidgets('/profile redirects to /settings', (tester) async {
      final loc = await _resolveLocation(tester, '/profile');
      expect(loc, AppRoutes.settings);
    });

    testWidgets('/chat (no caseId) redirects to /home', (tester) async {
      final loc = await _resolveLocation(tester, '/chat');
      expect(loc, AppRoutes.home);
    });

    testWidgets('/documents redirects to /home', (tester) async {
      final loc = await _resolveLocation(tester, '/documents');
      expect(loc, AppRoutes.home);
    });

    testWidgets('/case/<id> redirects to /home', (tester) async {
      final loc = await _resolveLocation(tester, '/case/test-case-123');
      expect(loc, AppRoutes.home);
    });
  });

  // ---------------------------------------------------------------------------
  // Source-grep regression: make accidental deletion of redirect routes loud.
  // Same lightweight style as test/features/home/home_quick_actions_layout_test.
  // ---------------------------------------------------------------------------
  group('lib/config/router.dart contains the redirect routes', () {
    late String source;

    setUpAll(() {
      source = File('lib/config/router.dart').readAsStringSync();
    });

    test('declares /profile redirect to AppRoutes.settings', () {
      // The route block declares path: '/profile' and a redirect that
      // returns AppRoutes.settings. Look for both substrings within a
      // small window of each other.
      final profileIdx = source.indexOf("path: '/profile'");
      expect(profileIdx, greaterThan(0),
          reason: '/profile redirect route must exist');
      final block = source.substring(
        profileIdx,
        (profileIdx + 200).clamp(0, source.length),
      );
      expect(block, contains('AppRoutes.settings'),
          reason: '/profile must redirect to AppRoutes.settings');
    });

    test('declares /chat redirect to AppRoutes.home', () {
      final chatIdx = source.indexOf("path: '/chat'");
      expect(chatIdx, greaterThan(0),
          reason: '/chat redirect route must exist');
      final block = source.substring(
        chatIdx,
        (chatIdx + 200).clamp(0, source.length),
      );
      expect(block, contains('AppRoutes.home'),
          reason: '/chat must redirect to AppRoutes.home');
    });

    test('declares /documents redirect to AppRoutes.home', () {
      final docsIdx = source.indexOf("path: '/documents'");
      expect(docsIdx, greaterThan(0),
          reason: '/documents redirect route must exist');
      final block = source.substring(
        docsIdx,
        (docsIdx + 200).clamp(0, source.length),
      );
      expect(block, contains('AppRoutes.home'),
          reason: '/documents must redirect to AppRoutes.home');
    });

    test('declares /case/:id redirect to AppRoutes.home', () {
      final caseIdx = source.indexOf("path: '/case/:id'");
      expect(caseIdx, greaterThan(0),
          reason: '/case/:id redirect route must exist');
      final block = source.substring(
        caseIdx,
        (caseIdx + 200).clamp(0, source.length),
      );
      expect(block, contains('AppRoutes.home'),
          reason: '/case/:id must redirect to AppRoutes.home');
    });
  });
}
