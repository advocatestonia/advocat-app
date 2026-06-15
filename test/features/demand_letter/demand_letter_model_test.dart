@Tags(['fast'])
library;

// Unit tests for the Demand-Letter Generator models (Feature #2).
// -----------------------------------------------------------------------------
// Pure parsing + serialization + helper logic — no Flutter widgets, no Supabase.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/demand_letter/models/demand_letter.dart';

void main() {
  group('DemandClaimType', () {
    test('round-trips wire values', () {
      for (final t in DemandClaimType.values) {
        expect(DemandClaimType.fromWire(t.wire), t);
      }
    });

    test('falls back to genericClaim for unknown wire', () {
      expect(DemandClaimType.fromWire('nope'), DemandClaimType.genericClaim);
      expect(DemandClaimType.fromWire(null), DemandClaimType.genericClaim);
    });

    test('requiresAmount is false only for fine disputes', () {
      expect(DemandClaimType.fineDispute.requiresAmount, isFalse);
      expect(DemandClaimType.depositReturn.requiresAmount, isTrue);
      expect(DemandClaimType.unpaidWage.requiresAmount, isTrue);
      expect(DemandClaimType.genericClaim.requiresAmount, isTrue);
    });
  });

  group('DemandParty.toJson', () {
    test('omits a blank address', () {
      expect(
        const DemandParty(name: 'Jane').toJson(),
        <String, dynamic>{'name': 'Jane'},
      );
    });

    test('includes a non-empty address', () {
      expect(
        const DemandParty(name: 'Jane', address: 'Tallinn').toJson(),
        <String, dynamic>{'name': 'Jane', 'address': 'Tallinn'},
      );
    });
  });

  group('DemandLetterRequest.toJson', () {
    test('serializes the full request and omits empty optionals', () {
      final req = DemandLetterRequest(
        claimType: DemandClaimType.depositReturn,
        jurisdiction: 'EE',
        lang: 'et',
        recipient: const DemandParty(name: 'Landlord OÜ'),
        basis: 'tagatisraha tagastamata',
        deadline: '2026-07-01',
        amount: '850.00',
        currency: 'EUR',
      );
      final json = req.toJson();
      expect(json['claim_type'], 'deposit_return');
      expect(json['jurisdiction'], 'EE');
      expect(json['lang'], 'et');
      expect(json['amount'], '850.00');
      expect(json['currency'], 'EUR');
      expect((json['recipient'] as Map)['name'], 'Landlord OÜ');
      // No sender / reference / case_id / letter_id supplied → keys absent.
      expect(json.containsKey('sender'), isFalse);
      expect(json.containsKey('reference'), isFalse);
      expect(json.containsKey('case_id'), isFalse);
      expect(json.containsKey('letter_id'), isFalse);
    });

    test('omits a blank amount but keeps currency', () {
      final req = DemandLetterRequest(
        claimType: DemandClaimType.fineDispute,
        jurisdiction: 'FI',
        lang: 'fi',
        recipient: const DemandParty(name: 'Poliisi'),
        basis: 'sakon oikaisu',
        deadline: '2026-07-01',
        amount: '',
      );
      final json = req.toJson();
      expect(json.containsKey('amount'), isFalse);
      expect(json['currency'], 'EUR');
    });

    test('includes letter_id when updating an existing draft', () {
      final req = DemandLetterRequest(
        claimType: DemandClaimType.genericClaim,
        jurisdiction: 'EE',
        lang: 'en',
        recipient: const DemandParty(name: 'X'),
        basis: 'b',
        deadline: 'd',
        amount: '10',
        letterId: 'abc-123',
      );
      expect(req.toJson()['letter_id'], 'abc-123');
    });
  });

  group('DemandLetterResult.fromJson', () {
    test('parses markdown, subject and norms', () {
      final r = DemandLetterResult.fromJson(<String, dynamic>{
        'letter_id': 'id-1',
        'markdown': '# Letter',
        'subject': 'Nõudekiri',
        'norms': <dynamic>[
          <String, dynamic>{
            'label': 'VÕS § 308',
            'slug': 'ee-vos',
            'article': '308',
            'note': 'tagatisraha',
          },
        ],
      });
      expect(r.letterId, 'id-1');
      expect(r.markdown, '# Letter');
      expect(r.subject, 'Nõudekiri');
      expect(r.norms, hasLength(1));
      expect(r.norms.first.label, 'VÕS § 308');
    });

    test('tolerates missing norms and fields', () {
      final r = DemandLetterResult.fromJson(<String, dynamic>{});
      expect(r.letterId, '');
      expect(r.markdown, '');
      expect(r.norms, isEmpty);
    });
  });
}
