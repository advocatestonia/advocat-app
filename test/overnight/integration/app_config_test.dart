// Overnight isolated test suite — DOES NOT modify production code.
// Tests for AppConfig static contract and derived getters.
import 'package:flutter_test/flutter_test.dart';
import 'package:advocat/config/app_config.dart';

void main() {
  group('AppConfig static contract', () {
    test('exposes non-empty appName', () {
      expect(AppConfig.appName, isNotEmpty);
    });

    test('appVersion is semver-like', () {
      expect(AppConfig.appVersion, matches(RegExp(r'^\d+\.\d+\.\d+$')));
    });

    test('maxDocumentSizeBytes is 20 MB', () {
      expect(AppConfig.maxDocumentSizeBytes, 20 * 1024 * 1024);
    });

    test('supportedDocumentTypes contains PDF and common images', () {
      expect(AppConfig.supportedDocumentTypes, contains('application/pdf'));
      expect(AppConfig.supportedDocumentTypes, contains('image/jpeg'));
      expect(AppConfig.supportedDocumentTypes, contains('image/png'));
    });

    test('aiRequestThrottleMs is a positive integer', () {
      expect(AppConfig.aiRequestThrottleMs, greaterThan(0));
    });

    test('useSupabaseProxy is false unless both URL and anon key are set', () {
      // In test env, anon key is not set, so proxy must be false.
      if (AppConfig.supabaseAnonKey.isEmpty) {
        expect(AppConfig.useSupabaseProxy, isFalse);
      } else {
        expect(AppConfig.useSupabaseProxy,
            AppConfig.supabaseUrl.isNotEmpty && AppConfig.supabaseAnonKey.isNotEmpty);
      }
    });

    test('useRealAI returns a boolean derived from configured keys', () {
      // Should not throw; value may be true or false depending on env.
      expect(AppConfig.useRealAI, isA<bool>());
    });

    test('stripeMerchantId has a sensible default', () {
      expect(AppConfig.stripeMerchantId, isNotEmpty);
    });
  });
}
