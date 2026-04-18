import 'package:flutter_test/flutter_test.dart';
import 'package:advocat/config/app_config.dart';

void main() {
  group('AppConfig', () {
    group('Default values', () {
      test('supabaseUrl has a default value', () {
        expect(AppConfig.supabaseUrl, isNotEmpty);
        expect(
          AppConfig.supabaseUrl,
          'https://okgnkucgwsytsondrjye.supabase.co',
        );
      });

      test('supabaseAnonKey defaults to empty string', () {
        expect(AppConfig.supabaseAnonKey, isEmpty);
      });

      test('stripePublishableKey defaults to empty string', () {
        expect(AppConfig.stripePublishableKey, isEmpty);
      });

      test('stripeMerchantId has a default value', () {
        expect(AppConfig.stripeMerchantId, 'merchant.com.ailegaldefense');
      });

      test('aiApiBaseUrl defaults to empty string', () {
        expect(AppConfig.aiApiBaseUrl, isEmpty);
      });

      test('aiApiKey defaults to empty string', () {
        expect(AppConfig.aiApiKey, isEmpty);
      });

      test('claudeApiKey defaults to empty string', () {
        expect(AppConfig.claudeApiKey, isEmpty);
      });

      test('emailApiBaseUrl defaults to empty string', () {
        expect(AppConfig.emailApiBaseUrl, isEmpty);
      });

      test('appName is AI Legal Defense', () {
        expect(AppConfig.appName, 'AI Legal Defense');
      });

      test('appVersion is 1.0.0', () {
        expect(AppConfig.appVersion, '1.0.0');
      });

      test('isProduction defaults to false', () {
        expect(AppConfig.isProduction, isFalse);
      });
    });

    group('useRealAI computed property', () {
      // Note: Since _aiModeRaw is a compile-time constant set to 'auto',
      // and in test environment both claudeApiKey and supabaseAnonKey are empty,
      // useRealAI should be false when no keys are provided.
      test(
        'returns false when no API keys are configured (auto mode)',
        () {
          // In default test environment with no dart-define overrides:
          // _aiModeRaw = 'auto', claudeApiKey = '', supabaseAnonKey = ''
          // useRealAI = useSupabaseProxy || claudeApiKey.isNotEmpty
          //           = false || false = false
          expect(AppConfig.useRealAI, isFalse);
        },
      );
    });

    group('useSupabaseProxy computed property', () {
      test(
        'returns false when supabaseAnonKey is empty (default)',
        () {
          // supabaseUrl is not empty (has default), but anonKey is empty
          expect(AppConfig.useSupabaseProxy, isFalse);
        },
      );
    });

    group('Constants', () {
      test('aiRequestThrottleMs is 1000 ms', () {
        expect(AppConfig.aiRequestThrottleMs, 1000);
      });

      test('maxDocumentSizeBytes is 20 MB', () {
        expect(AppConfig.maxDocumentSizeBytes, 20 * 1024 * 1024);
        expect(AppConfig.maxDocumentSizeBytes, 20971520);
      });

      test('supportedDocumentTypes contains 4 MIME types', () {
        expect(AppConfig.supportedDocumentTypes, hasLength(4));
      });

      test('supportedDocumentTypes includes application/pdf', () {
        expect(
          AppConfig.supportedDocumentTypes,
          contains('application/pdf'),
        );
      });

      test('supportedDocumentTypes includes image/jpeg', () {
        expect(
          AppConfig.supportedDocumentTypes,
          contains('image/jpeg'),
        );
      });

      test('supportedDocumentTypes includes image/png', () {
        expect(
          AppConfig.supportedDocumentTypes,
          contains('image/png'),
        );
      });

      test('supportedDocumentTypes includes image/heic', () {
        expect(
          AppConfig.supportedDocumentTypes,
          contains('image/heic'),
        );
      });

      test('supportedDocumentTypes is in expected order', () {
        expect(AppConfig.supportedDocumentTypes, [
          'application/pdf',
          'image/jpeg',
          'image/png',
          'image/heic',
        ]);
      });
    });
  });
}
