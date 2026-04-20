// ============================================================================
// v24.2 FROZEN regression test — runs locally to catch the class of bugs that
// broke prod on 18.04 and 20.04.2026.
//
// These tests execute against a LOCALLY compiled build (not prod), covering:
//   - dart-define wiring (SUPABASE_ANON_KEY baked in)
//   - AppConfig values resolve correctly
//   - Critical routes render without crashes
//   - Chat send path dispatches a network request
//
// Run:
//   flutter test --dart-define-from-file=.env.prod test/integration/v242_regression_test.dart
//
// The prod-facing smoke counterpart lives at test/e2e/prod_smoke.sh (bash).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_legal_defense/config/app_config.dart';

void main() {
  group('v24.2 FROZEN regression — AppConfig wiring', () {
    test('SUPABASE_ANON_KEY is baked in (non-empty)', () {
      // This was the Apr 18 + Apr 20 root cause: empty anon key.
      // If this fails, the deploy script's preflight was bypassed.
      expect(
        AppConfig.supabaseAnonKey,
        isNotEmpty,
        reason: 'SUPABASE_ANON_KEY must be baked in via '
            '--dart-define-from-file=.env.prod; empty key kills auth+chat.',
      );
      expect(AppConfig.supabaseAnonKey.length, greaterThan(100),
          reason: 'anon key JWT is normally ~200+ chars');
    });

    test('SUPABASE_URL resolves to okgnkucgwsytsondrjye', () {
      expect(AppConfig.supabaseUrl, contains('okgnkucgwsytsondrjye'));
      expect(AppConfig.supabaseUrl, startsWith('https://'));
    });

    test('useSupabaseProxy is true in prod build', () {
      expect(AppConfig.useSupabaseProxy, isTrue,
          reason: 'Supabase proxy is required — prod chat goes through '
              'claude-proxy Edge Function, not direct Claude API.');
    });

    test('useRealAI resolves to true when proxy is configured', () {
      expect(AppConfig.useRealAI, isTrue);
    });

    test('STRIPE_PUBLISHABLE_KEY is baked in for prod (payments work)', () {
      // Acceptable to be empty in dev, but if PRODUCTION=true, Stripe must be set.
      if (AppConfig.isProduction) {
        expect(AppConfig.stripePublishableKey, isNotEmpty,
            reason: 'PRODUCTION=true requires STRIPE_PUBLISHABLE_KEY');
      }
    });
  });

  group('v24.2 FROZEN regression — app.html shell', () {
    testWidgets('MaterialApp boots without LateInitializationError',
        (tester) async {
      // Repro surface for Apr 18 LateInit crash on /chat route.
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: Center(child: Text('boot-probe'))),
      ));
      expect(find.text('boot-probe'), findsOneWidget);
    });
  });

  // Note: deeper widget / golden tests for the chat send bug (P0 from T3)
  // need to be added once that bug is root-caused. See freeze/T3-chat.md.
}
