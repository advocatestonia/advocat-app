@Tags(['fast'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/email_service.dart';

/// Tests for [EmailService] — DTO parsing, exception structure.
///
/// Network-dependent methods (getOAuthUrl, completeOAuth, syncEmails,
/// isConnected, disconnect) require a backend and are tested via
/// integration tests. Here we focus on the data models and exception class.
void main() {
  group('EmailSyncResult', () {
    test('fromJson parses all fields', () {
      final json = {
        'new_emails': 5,
        'updated_emails': 3,
        'extracted_deadlines': 2,
        'synced_at': '2026-04-15T10:30:00Z',
      };
      final result = EmailSyncResult.fromJson(json);
      expect(result.newEmails, 5);
      expect(result.updatedEmails, 3);
      expect(result.extractedDeadlines, 2);
      expect(result.syncedAt.year, 2026);
      expect(result.syncedAt.month, 4);
      expect(result.syncedAt.day, 15);
    });

    test('fromJson uses defaults for missing numeric fields', () {
      final json = {
        'synced_at': '2026-01-01T00:00:00Z',
      };
      final result = EmailSyncResult.fromJson(json);
      expect(result.newEmails, 0);
      expect(result.updatedEmails, 0);
      expect(result.extractedDeadlines, 0);
    });

    test('fromJson throws on missing synced_at', () {
      final json = <String, dynamic>{
        'new_emails': 1,
      };
      expect(
        () => EmailSyncResult.fromJson(json),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('EmailServiceException', () {
    test('toString includes message', () {
      const e = EmailServiceException('Connection failed');
      expect(e.toString(), 'EmailServiceException: Connection failed');
    });

    test('stores message and optional cause', () {
      const e = EmailServiceException('Error');
      expect(e.message, 'Error');
      expect(e.cause, isNull);
    });
  });

  group('EmailService construction', () {
    test('can be instantiated without errors', () {
      final service = EmailService();
      expect(service, isNotNull);
    });

    test('setAuthToken does not throw', () {
      final service = EmailService();
      service.setAuthToken('test-bearer-token');
      // No exception
    });
  });
}
