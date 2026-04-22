// =============================================================================
// Estonian legal base coverage — Consilium 17.04.2026
// =============================================================================
//
// Locks in the knowledge base that Advocat claims in
// `Obsidian Vault/Advocat/Эстонская правовая база.md`:
//
//   10 acts: PKS, KarS, TLS, VÕS, VMS, HMS, HKMS, PärS, VõrdKS, TarKS
//   Emergency numbers: 112, 116 006, 116 111, 1247, 620 0100
//   Portals: juristaitab.ee, alimendid.ee, etoimik.rik.ee,
//            komisjon.ttja.ee, iseteenindus.notar.ee, parimine.notar.ee,
//            maasikas.emta.ee, etaotlus.politsei.ee
//   Key amounts / deadlines that MUST stay current:
//     - Min. alimony 2026: €318.62
//     - Min. wage 2026: €886
//     - Vaie (HMS §75): 30 days
//     - Deportation appeal: 10 days
//     - Court action (HKMS §46): 30 days
//     - Renounce inheritance (PärS §119): 3 months
//
// A drift here = drift from investor deck. Breaks are INTENTIONAL signals.

import 'package:flutter_test/flutter_test.dart';
import 'package:advocat/services/estonian_legal_database.dart';

void main() {
  group('Estonian legal acts — 10 codes must be present', () {
    test('PKS family law section exists with alimony + divorce anchors', () {
      const t = EstonianLegalDatabase.familyLaw;
      expect(t, contains('PKS'));
      expect(t, contains('PEREKONNASEADUS'));
      expect(t, contains('§ 100'));
      expect(t.toLowerCase(), contains('alimony'));
      expect(t, contains('318.62'),
          reason: 'April 2026 minimum alimony amount must be in database');
      expect(t.toLowerCase(), contains('divorce'));
    });

    test('KarS criminal law with key offences', () {
      const t = EstonianLegalDatabase.criminalLaw;
      expect(t, contains('KARISTUSSEADUSTIK'));
      expect(t, contains('KarS'));
      expect(t, contains('§ 120')); // threats
      expect(t, contains('§ 121')); // assault
      expect(t, contains('§ 157')); // stalking
      expect(t, contains('§ 199')); // theft
      expect(t, contains('§ 209')); // fraud
      expect(t, contains('116 006'),
          reason: 'Victim support 24/7 line missing from criminal section');
    });

    test('TLS employment law: notice periods + €886 min wage', () {
      const t = EstonianLegalDatabase.employmentLaw;
      expect(t, contains('TÖÖLEPINGU SEADUS'));
      expect(t, contains('TLS'));
      expect(t, contains('15 days')); // <1y notice
      expect(t, contains('30 days'));
      expect(t, contains('60 days'));
      expect(t, contains('90 days'));
      expect(t, contains('886'),
          reason: 'Minimum wage 2026 €886/month must be encoded');
    });

    test('VÕS rental law section covers deposit cap + 3mo notice', () {
      const t = EstonianLegalDatabase.rentalLaw;
      expect(t, contains('VÕS'));
      expect(t, contains('§ 311'));
      expect(t, contains('§ 308'));
      expect(t, contains('3 months'));
    });

    test('VMS immigration: 10-day deportation appeal deadline', () {
      const t = EstonianLegalDatabase.immigrationLaw;
      expect(t, contains('VÄLISMAALASTE SEADUS'));
      expect(t, contains('VMS'));
      expect(t.toLowerCase(), contains('deportation'));
      expect(t, contains('10 DAYS'),
          reason: 'Deportation appeal window (Sulga case!) must be explicit');
    });

    test('HMS administrative procedure: vaie 30 days + §40/§56/§75', () {
      const t = EstonianLegalDatabase.administrativeLaw;
      expect(t, contains('HALDUSMENETLUSE SEADUS'));
      expect(t, contains('HMS'));
      expect(t, contains('§ 40'));
      expect(t, contains('§ 56'));
      expect(t, contains('§ 75'));
      expect(t.toLowerCase(), contains('vaie'));
    });

    test('HKMS referenced for 30-day court action', () {
      const t = EstonianLegalDatabase.administrativeLaw +
          EstonianLegalDatabase.deadlines +
          EstonianLegalDatabase.immigrationLaw;
      expect(t, contains('HKMS'));
      expect(t, contains('§ 46'));
    });

    test('PärS inheritance: 3 months renounce window', () {
      const t = EstonianLegalDatabase.inheritanceLaw;
      expect(t, contains('PÄRIMISSEADUS'));
      expect(t, contains('PärS'));
      expect(t, contains('§ 119'));
      expect(t, contains('3 MONTHS'));
      expect(t.toLowerCase(), contains('no inheritance tax'));
    });

    test('VõrdKS equal treatment: 1-year deadline + burden of proof', () {
      const t = EstonianLegalDatabase.discriminationLaw;
      expect(t, contains('VÕRDSE KOHTLEMISE SEADUS'));
      expect(t, contains('VõrdKS'));
      expect(t, contains('§ 25'));
      expect(t, contains('§ 8'));
    });

    test('Consumer protection (TarKS scope) covers 14-day withdrawal', () {
      const t = EstonianLegalDatabase.consumerLaw;
      expect(t.toLowerCase(), contains('warranty'));
      expect(t, contains('14-day'));
      expect(t, contains('2 years'));
      expect(t, contains('667 2000'));
    });
  });

  group('Estonian emergency numbers', () {
    test('all 5 critical phone lines present', () {
      const t = EstonianLegalDatabase.contacts;
      for (final num in ['112', '116 006', '116 111', '1247', '620 0100']) {
        expect(t, contains(num), reason: 'Emergency number $num missing');
      }
    });
  });

  group('Estonian self-service portals', () {
    test('all 8 official portals referenced', () {
      const t = EstonianLegalDatabase.portals;
      const required = [
        'etoimik.rik.ee',
        'etaotlus.politsei.ee',
        'maasikas.emta.ee',
        'iseteenindus.notar.ee',
        'parimine.notar.ee',
        'komisjon.ttja.ee',
        'juristaitab.ee',
        'alimendid.ee',
      ];
      for (final p in required) {
        expect(t, contains(p), reason: 'Portal $p missing');
      }
    });
  });

  group('Critical deadlines summary', () {
    test('deadlines block cites 30-day vaie and 10-day deportation', () {
      const t = EstonianLegalDatabase.deadlines;
      expect(t.toLowerCase(), contains('vaie'));
      expect(t, contains('30 days'));
      expect(t, contains('10 days'));
      expect(t, contains('3 months'));
      expect(t.toLowerCase(), contains('inheritance'));
    });
  });
}
