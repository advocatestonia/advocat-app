@Tags(['fast'])
library;

// Tests for [SupportService] — pure unit coverage for the payload shaping
// + validation logic. The Supabase round-trip is exercised by the canary
// smoke script against a deployed function.
//
// These tests run in fast mode (no network, no Supabase) so they fit
// inside the pre-commit budget.

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/support_service.dart';

void main() {
  group('SupportServiceMeta.buildPayload', () {
    test('always includes honeypot field (default empty)', () {
      final payload = SupportServiceMeta.buildPayload(
        category: SupportCategory.bug,
        message: 'something is broken',
        contactChannel: SupportContactChannel.inApp,
      );
      expect(payload.containsKey('_hp'), isTrue);
      expect(payload['_hp'], '');
    });

    test('forwards an explicit honeypot value', () {
      final payload = SupportServiceMeta.buildPayload(
        category: SupportCategory.bug,
        message: 'something is broken',
        contactChannel: SupportContactChannel.inApp,
        honeypot: 'bot-was-here',
      );
      expect(payload['_hp'], 'bot-was-here');
    });

    test('serialises category to wire slug', () {
      for (final c in SupportCategory.values) {
        final payload = SupportServiceMeta.buildPayload(
          category: c,
          message: 'something is broken',
          contactChannel: SupportContactChannel.inApp,
        );
        expect(payload['category'], c.wireValue);
      }
    });

    test('serialises contact channel to wire slug', () {
      final payload = SupportServiceMeta.buildPayload(
        category: SupportCategory.bug,
        message: 'something is broken',
        contactChannel: SupportContactChannel.whatsapp,
      );
      expect(payload['contact_channel'], 'whatsapp');
    });

    test('trims surrounding whitespace from message', () {
      final payload = SupportServiceMeta.buildPayload(
        category: SupportCategory.bug,
        message: '   help me debug this   ',
        contactChannel: SupportContactChannel.inApp,
      );
      expect(payload['message'], 'help me debug this');
    });

    test('drops empty email field rather than sending blank string', () {
      final payload = SupportServiceMeta.buildPayload(
        category: SupportCategory.bug,
        message: 'something is broken',
        contactChannel: SupportContactChannel.inApp,
        email: '   ',
      );
      expect(payload.containsKey('email'), isFalse);
    });

    test('includes email when provided', () {
      final payload = SupportServiceMeta.buildPayload(
        category: SupportCategory.bug,
        message: 'something is broken',
        contactChannel: SupportContactChannel.inApp,
        email: 'me@example.com',
      );
      expect(payload['email'], 'me@example.com');
    });

    test('includes metadata when provided', () {
      final payload = SupportServiceMeta.buildPayload(
        category: SupportCategory.bug,
        message: 'something is broken',
        contactChannel: SupportContactChannel.inApp,
        pageUrl: 'https://advocat.ee/app.html',
        language: 'et',
        appVersion: '1.2.3+build.42',
      );
      expect(payload['page_url'], 'https://advocat.ee/app.html');
      expect(payload['language'], 'et');
      expect(payload['app_version'], '1.2.3+build.42');
    });

    test('omits page_url / language / app_version when blank', () {
      final payload = SupportServiceMeta.buildPayload(
        category: SupportCategory.bug,
        message: 'something is broken',
        contactChannel: SupportContactChannel.inApp,
        pageUrl: '',
        language: '',
        appVersion: '',
      );
      expect(payload.containsKey('page_url'), isFalse);
      expect(payload.containsKey('language'), isFalse);
      expect(payload.containsKey('app_version'), isFalse);
    });
  });

  group('SupportServiceMeta.validateMessage', () {
    test('rejects message under 10 chars (after trim)', () {
      expect(SupportServiceMeta.validateMessage('hi'), 'too_short');
      expect(SupportServiceMeta.validateMessage('  short  '), 'too_short');
    });

    test('accepts message at exactly 10 chars', () {
      expect(SupportServiceMeta.validateMessage('1234567890'), isNull);
    });

    test('accepts long but in-range message', () {
      expect(
        SupportServiceMeta.validateMessage('a' * 1500),
        isNull,
      );
    });

    test('rejects message over 2000 chars', () {
      expect(SupportServiceMeta.validateMessage('a' * 2001), 'too_long');
    });

    test('accepts message at exactly 2000 chars', () {
      expect(SupportServiceMeta.validateMessage('a' * 2000), isNull);
    });
  });

  group('SupportCategoryWire', () {
    test('every enum value maps to a non-empty wire slug', () {
      for (final c in SupportCategory.values) {
        expect(c.wireValue, isNotEmpty);
      }
    });

    test('wire slugs match the edge function CHECK constraint set', () {
      const allowed = {'bug', 'payment', 'question', 'feature', 'other'};
      for (final c in SupportCategory.values) {
        expect(allowed, contains(c.wireValue));
      }
    });
  });

  group('SupportContactChannelWire', () {
    test('wire slugs match the edge function CHECK constraint set', () {
      const allowed = {'in_app', 'whatsapp', 'email'};
      for (final ch in SupportContactChannel.values) {
        expect(allowed, contains(ch.wireValue));
      }
    });
  });

  group('SupportSubmitResult', () {
    test('ok constructor sets success=true and stores ticket id', () {
      const r = SupportSubmitResult.ok('abc-123');
      expect(r.success, isTrue);
      expect(r.ticketId, 'abc-123');
      expect(r.errorReason, isNull);
    });

    test('error constructor sets success=false and stores reason', () {
      const r = SupportSubmitResult.error('rate_limited', 'Slow down');
      expect(r.success, isFalse);
      expect(r.errorReason, 'rate_limited');
      expect(r.errorMessage, 'Slow down');
      expect(r.ticketId, isNull);
    });
  });
}
