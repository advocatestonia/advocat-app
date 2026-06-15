// Unit tests for RenewableDocument pure logic (Renewal Radar, Feature #5).
// -----------------------------------------------------------------------------
// No widgets, no Supabase — just the date math, urgency banding, and JSON
// mapping that drive the Renewal Radar UI.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';
import 'package:advocat/features/renewals/models/renewable_document.dart';

void main() {
  // Reference "now": 2026-06-15 midday.
  final now = DateTime(2026, 6, 15, 12);

  RenewableDocument doc({
    String expires = '2026-12-31',
    RenewableDocType type = RenewableDocType.residencePermit,
    List<String> sent = const [],
    bool enabled = true,
  }) {
    return RenewableDocument(
      id: 'x',
      docType: type,
      label: 'Test permit',
      expiresOn: DateTime.parse(expires),
      remindersSent: sent,
      notificationsEnabled: enabled,
    );
  }

  group('daysUntilExpiry', () {
    test('future date counts whole days', () {
      expect(doc(expires: '2026-06-25').daysUntilExpiry(now), 10);
    });

    test('today is zero', () {
      expect(doc(expires: '2026-06-15').daysUntilExpiry(now), 0);
    });

    test('past is negative', () {
      expect(doc(expires: '2026-06-10').daysUntilExpiry(now), -5);
    });

    test('time-of-day on the reference does not shift the boundary', () {
      final early = DateTime(2026, 6, 15, 0, 1);
      final late = DateTime(2026, 6, 15, 23, 59);
      expect(doc(expires: '2026-06-22').daysUntilExpiry(early), 7);
      expect(doc(expires: '2026-06-22').daysUntilExpiry(late), 7);
    });
  });

  group('urgency bands align to 90/30/7 windows', () {
    test('expired', () {
      expect(doc(expires: '2026-06-14').urgency(now), RenewalUrgency.expired);
    });
    test('critical (<=7)', () {
      expect(doc(expires: '2026-06-20').urgency(now), RenewalUrgency.critical);
    });
    test('soon (<=30)', () {
      expect(doc(expires: '2026-07-10').urgency(now), RenewalUrgency.soon);
    });
    test('upcoming (<=90)', () {
      expect(doc(expires: '2026-09-10').urgency(now), RenewalUrgency.upcoming);
    });
    test('distant (>90)', () {
      expect(doc(expires: '2026-12-31').urgency(now), RenewalUrgency.distant);
    });
  });

  group('renewal guide gating', () {
    test('residence/work/visa have a guide', () {
      expect(RenewableDocType.residencePermit.hasRenewalGuide, isTrue);
      expect(RenewableDocType.workPermit.hasRenewalGuide, isTrue);
      expect(RenewableDocType.visa.hasRenewalGuide, isTrue);
    });
    test('passport/insurance/etc do not', () {
      expect(RenewableDocType.passport.hasRenewalGuide, isFalse);
      expect(RenewableDocType.insurance.hasRenewalGuide, isFalse);
      expect(RenewableDocType.other.hasRenewalGuide, isFalse);
    });
  });

  group('wire enum mapping', () {
    test('round-trips known values', () {
      for (final t in RenewableDocType.values) {
        expect(RenewableDocType.fromWire(t.wire), t);
      }
    });
    test('unknown wire falls back to other', () {
      expect(RenewableDocType.fromWire('nonsense'), RenewableDocType.other);
      expect(RenewableDocType.fromWire(null), RenewableDocType.other);
    });
  });

  group('fromJson / toInsert', () {
    test('parses a full row', () {
      final d = RenewableDocument.fromJson({
        'id': 'abc',
        'doc_type': 'passport',
        'label': 'EU passport',
        'doc_number': 'P1234',
        'jurisdiction': 'EE',
        'expires_on': '2027-01-15',
        'reminders_sent': ['90', '30'],
        'notifications_enabled': false,
        'notes': 'renew at police',
        'created_at': '2026-06-01T10:00:00Z',
      });
      expect(d.docType, RenewableDocType.passport);
      expect(d.label, 'EU passport');
      expect(d.docNumber, 'P1234');
      expect(d.jurisdiction, 'EE');
      expect(d.expiresOn, DateTime.parse('2027-01-15'));
      expect(d.remindersSent, ['90', '30']);
      expect(d.notificationsEnabled, isFalse);
    });

    test('toInsert emits date-only expiry and omits empty optionals', () {
      final d = doc(expires: '2026-12-31');
      final payload = d.toInsert();
      expect(payload['expires_on'], '2026-12-31');
      expect(payload.containsKey('doc_number'), isFalse);
      expect(payload['doc_type'], 'residence_permit');
      expect(payload['notifications_enabled'], isTrue);
    });

    test('dateOnly pads single-digit month/day', () {
      expect(RenewableDocument.dateOnly(DateTime(2026, 1, 5)), '2026-01-05');
    });
  });
}
