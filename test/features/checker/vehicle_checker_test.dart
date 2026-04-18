// =============================================================================
// Vehicle checker tests — Consilium 17.04.2026
// =============================================================================
//
// Validates state machine + 7-country registry guide behaviour of
// [VehicleCheckerNotifier]. Covers:
//   • state transitions (idle → loading → results / error)
//   • 7 supported countries (EE, FI, LV, LT, SE, DE, PL) from
//     [kSupportedCountries]
//   • demo plate "908FBT" happy path + unknown plate error path
//   • VIN input mode + country switching + clearResults()
//   • report payload invariants for VW Golf demo data
//
// NOTE: The checker itself currently returns mock data (TODO in provider).
//       These tests validate the CURRENT behaviour and act as a regression
//       lock before wiring a real transpordiamet.ee / traficom.fi API.

import 'package:flutter_test/flutter_test.dart';
import 'package:advocat/features/checker/providers/vehicle_checker_provider.dart';

void main() {
  group('VehicleCheckerState defaults', () {
    test('initial state is licensePlate input + EE', () {
      const s = VehicleCheckerState();
      expect(s.inputMode, VehicleInputMode.licensePlate);
      expect(s.countryCode, 'EE');
      expect(s.query, '');
      expect(s.isLoading, isFalse);
      expect(s.report, isNull);
      expect(s.errorMessage, isNull);
    });

    test('copyWith preserves unchanged fields', () {
      const s = VehicleCheckerState(
        countryCode: 'FI',
        query: 'ABC123',
        isLoading: true,
      );
      final copy = s.copyWith();
      expect(copy.countryCode, 'FI');
      expect(copy.query, 'ABC123');
      expect(copy.isLoading, isTrue);
    });

    test('copyWith(clearReport: true) removes report', () {
      final s = VehicleCheckerState(
        report: VehicleReport(
          plate: 'X',
          vin: 'Y',
          make: 'VW',
          model: 'Golf',
          year: 2020,
          color: 'Black',
          mileageKm: 10000,
          mileageHistory: const [],
          mileageFraudSuspected: false,
          accidentCount: 0,
          insuranceActive: true,
          insuranceExpiry: null,
          inspectionValid: true,
          inspectionExpiry: null,
          ownerCount: 1,
          isStolen: false,
          assessment: VehicleAssessment.safeToBuy,
          aiSummary: '',
        ),
      );
      final cleared = s.copyWith(clearReport: true);
      expect(cleared.report, isNull);
    });
  });

  group('kSupportedCountries', () {
    test('contains 7+ required countries for Advocat roadmap', () {
      // Roadmap guarantees these seven — tests MUST lock them in.
      const required = ['EE', 'FI', 'LV', 'LT', 'SE', 'DE', 'PL'];
      for (final code in required) {
        expect(kSupportedCountries.containsKey(code), isTrue,
            reason: 'Country $code missing from kSupportedCountries');
      }
    });

    test('all country names non-empty', () {
      for (final entry in kSupportedCountries.entries) {
        expect(entry.value, isNotEmpty,
            reason: '${entry.key} has empty name');
      }
    });

    test('Estonia is present and spelled correctly', () {
      expect(kSupportedCountries['EE'], 'Estonia');
    });

    test('codes are two uppercase letters', () {
      for (final code in kSupportedCountries.keys) {
        expect(code.length, 2);
        expect(code, code.toUpperCase());
      }
    });
  });

  group('VehicleCheckerNotifier — setters', () {
    late VehicleCheckerNotifier n;
    setUp(() => n = VehicleCheckerNotifier(debugMode: true));
    tearDown(() => n.dispose());

    test('setInputMode switches mode and clears prior results', () {
      n.setQuery('908FBT');
      n.setInputMode(VehicleInputMode.vin);
      expect(n.state.inputMode, VehicleInputMode.vin);
      expect(n.state.report, isNull);
      expect(n.state.errorMessage, isNull);
    });

    test('setCountryCode updates country', () {
      n.setCountryCode('PL');
      expect(n.state.countryCode, 'PL');
    });

    test('setQuery uppercases only on lookup, not on input', () {
      n.setQuery('908fbt');
      // Raw query stays as typed — normalization happens inside checkVehicle().
      expect(n.state.query, '908fbt');
    });
  });

  group('VehicleCheckerNotifier — checkVehicle()', () {
    late VehicleCheckerNotifier n;
    setUp(() => n = VehicleCheckerNotifier(debugMode: true));
    tearDown(() => n.dispose());

    test('empty query sets errorMessage, does not load', () async {
      await n.checkVehicle();
      expect(n.state.isLoading, isFalse);
      expect(n.state.errorMessage, isNotNull);
      expect(n.state.errorMessage!.toLowerCase(), contains('plate'));
    });

    test('demo plate 908FBT returns full VW Golf report', () async {
      n.setQuery('908FBT');
      await n.checkVehicle();
      expect(n.state.isLoading, isFalse);
      expect(n.state.report, isNotNull);
      final r = n.state.report!;
      expect(r.make, 'Volkswagen');
      expect(r.model, 'Golf');
      expect(r.year, 2018);
      expect(r.assessment, VehicleAssessment.safeToBuy);
      expect(r.mileageHistory.length, greaterThanOrEqualTo(6),
          reason: 'Golf demo must expose at least 6 mileage points');
      expect(r.isStolen, isFalse);
      expect(r.accidentCount, 0);
    });

    test('demo VIN WVWZZZ3CZWE123456 returns same VW Golf', () async {
      n.setQuery('WVWZZZ3CZWE123456');
      n.setInputMode(VehicleInputMode.vin);
      await n.checkVehicle();
      expect(n.state.report, isNotNull);
      expect(n.state.report!.make, 'Volkswagen');
    });

    test('unknown plate returns errorMessage and no report', () async {
      n.setQuery('ZZZ999');
      await n.checkVehicle();
      expect(n.state.isLoading, isFalse);
      expect(n.state.report, isNull);
      expect(n.state.errorMessage, isNotNull);
      expect(n.state.errorMessage!.toLowerCase(), contains('not found'));
    });

    test('lowercase/whitespace query normalized to uppercase', () async {
      n.setQuery('  908fbt  ');
      await n.checkVehicle();
      expect(n.state.report, isNotNull,
          reason: 'Query should be trimmed+uppercased before lookup');
    });

    test('mileage history is chronologically ordered', () async {
      n.setQuery('908FBT');
      await n.checkVehicle();
      final hist = n.state.report!.mileageHistory;
      for (var i = 1; i < hist.length; i++) {
        expect(hist[i].date.isAfter(hist[i - 1].date), isTrue,
            reason: 'Mileage record at index $i is out of order');
        expect(hist[i].mileageKm, greaterThanOrEqualTo(hist[i - 1].mileageKm),
            reason: 'Mileage decreased between records — fraud-like data');
      }
    });

    test('clearResults wipes report + error + query', () async {
      n.setQuery('908FBT');
      await n.checkVehicle();
      n.clearResults();
      expect(n.state.report, isNull);
      expect(n.state.errorMessage, isNull);
      expect(n.state.query, '');
    });
  });

  group('VehicleCheckerNotifier — cross-country behaviour', () {
    test('country change preserves query', () {
      final n = VehicleCheckerNotifier();
      n.setQuery('ABC123');
      n.setCountryCode('DE');
      expect(n.state.query, 'ABC123');
      expect(n.state.countryCode, 'DE');
      n.dispose();
    });

    test('all 7 primary countries accepted without crash', () async {
      for (final code in ['EE', 'FI', 'LV', 'LT', 'SE', 'DE', 'PL']) {
        final n = VehicleCheckerNotifier(debugMode: true);
        n.setCountryCode(code);
        n.setQuery('XX999');
        await n.checkVehicle();
        // Unknown plate in any country => error message, no crash.
        expect(n.state.errorMessage, isNotNull,
            reason: '$code did not produce an error for unknown plate');
        n.dispose();
      }
    });
  });
}
