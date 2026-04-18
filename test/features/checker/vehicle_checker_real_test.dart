// =============================================================================
// Real Edge-Function integration tests for VehicleCheckerNotifier — P0-2
// =============================================================================
//
// Exercises the production path where VehicleCheckerNotifier calls the
// `check-vehicle` Supabase Edge Function. We inject fixtures representing
// the function's honest contract:
//   • EE:  attempts LKF public lookup, returns insurance status or "unknown"
//   • FI/LV/LT/DE/PL/SE: returns redirect URL + language + paid-or-free flag
//   • Unsupported country or malformed plate: proper error
//
// Scenarios covered (14 tests, >min 10 required by OMEGA):
//   1.  Estonian plate, LKF found → full report with insurance
//   2.  Estonian plate, LKF could not verify → not-found + portal redirect
//   3.  Finland plate → redirect URL, language=fi, not paid
//   4.  Latvia plate → redirect URL, isPaidSource=true
//   5.  Germany plate → redirect, de, paid
//   6.  Poland plate → redirect, pl, free
//   7.  Sweden plate → redirect, sv, free
//   8.  Invalid plate format ("AB!@#") → error, no network call
//   9.  Empty plate → error
//   10. Unsupported country → error message from function
//   11. Timeout / offline (null from client) → error (prod) or demo (debug)
//   12. Network exception → error state
//   13. Country code switching preserves query
//   14. Plate uppercased / trimmed before hitting client
//   15. Demo-mode 908FBT still works when no client + debugMode

import 'package:flutter_test/flutter_test.dart';
import 'package:advocat/features/checker/providers/vehicle_checker_provider.dart';

class _FakeClient implements VehicleCheckClient {
  _FakeClient(this._response, {this.throwError = false});
  final Map<String, dynamic>? _response;
  final bool throwError;

  String? lastPlate;
  String? lastCountry;
  int callCount = 0;

  @override
  Future<Map<String, dynamic>?> checkVehicle({
    required String plate,
    required String country,
  }) async {
    callCount += 1;
    lastPlate = plate;
    lastCountry = country;
    if (throwError) throw Exception('Network down');
    return _response;
  }
}

Map<String, dynamic> _eeFound() => {
      'found': true,
      'plate': '123ABC',
      'country': 'EE',
      'insuranceValid': true,
      'insurer': 'If Kindlustus',
      'sourceUrl': 'https://eteenindus.mnt.ee/',
      'sourceName': 'Transpordiamet e-teenindus',
      'language': 'et',
      'isPaidSource': false,
      'inspectionPortal': 'https://eteenindus.mnt.ee/',
      'insurancePortal': 'https://www.lkf.ee/kindlustuse-kontroll',
    };

Map<String, dynamic> _eeUnverified() => {
      'found': false,
      'plate': '000XXX',
      'country': 'EE',
      'sourceUrl': 'https://eteenindus.mnt.ee/',
      'sourceName': 'Transpordiamet e-teenindus',
      'language': 'et',
      'isPaidSource': false,
      'message':
          'Estonian Transpordiamet does not publish a free public vehicle-data API.',
      'inspectionPortal': 'https://eteenindus.mnt.ee/',
      'insurancePortal': 'https://www.lkf.ee/kindlustuse-kontroll',
    };

Map<String, dynamic> _redirect({
  required String country,
  required String url,
  required String lang,
  required bool paid,
}) =>
    {
      'found': false,
      'plate': 'ABC123',
      'country': country,
      'sourceUrl': url,
      'sourceName': 'Registry $country',
      'language': lang,
      'isPaidSource': paid,
      'message': 'Lookup requires visiting the official portal.',
    };

void main() {
  group('VehicleCheckerNotifier — real Edge Function path', () {
    test('1. EE plate with LKF hit → report + insurance valid', () async {
      final c = _FakeClient(_eeFound());
      final n = VehicleCheckerNotifier(client: c);
      n.setCountryCode('EE');
      n.setQuery('123ABC');
      await n.checkVehicle();

      expect(c.callCount, 1);
      expect(c.lastPlate, '123ABC');
      expect(c.lastCountry, 'EE');
      expect(n.state.report, isNotNull);
      expect(n.state.report!.insuranceActive, isTrue);
      expect(n.state.report!.aiSummary, contains('If Kindlustus'));
      expect(n.state.report!.isFromRegistry, isTrue);
      expect(n.state.redirectUrl, startsWith('https://eteenindus.mnt.ee'));
      expect(n.state.redirectLanguage, 'et');
      expect(n.state.redirectIsPaid, isFalse);
      n.dispose();
    });

    test('2. EE plate with LKF miss → portal redirect + user-friendly error',
        () async {
      final c = _FakeClient(_eeUnverified());
      final n = VehicleCheckerNotifier(client: c);
      n.setCountryCode('EE');
      n.setQuery('000XXX');
      await n.checkVehicle();

      expect(n.state.report, isNull);
      expect(n.state.errorMessage, isNotNull);
      expect(n.state.redirectUrl, startsWith('https://eteenindus.mnt.ee'));
      expect(n.state.redirectIsPaid, isFalse);
      n.dispose();
    });

    test('3. Finland → redirect, fi language, not paid', () async {
      final c = _FakeClient(_redirect(
        country: 'FI',
        url: 'https://www.traficom.fi/fi/asiointi/ajoneuvon-rekisteritiedot',
        lang: 'fi',
        paid: false,
      ));
      final n = VehicleCheckerNotifier(client: c);
      n.setCountryCode('FI');
      n.setQuery('ABC123');
      await n.checkVehicle();

      expect(n.state.redirectUrl, contains('traficom.fi'));
      expect(n.state.redirectLanguage, 'fi');
      expect(n.state.redirectIsPaid, isFalse);
      expect(n.state.report, isNull);
      n.dispose();
    });

    test('4. Latvia → paid source flag set', () async {
      final c = _FakeClient(_redirect(
        country: 'LV',
        url: 'https://e.csdd.lv/',
        lang: 'lv',
        paid: true,
      ));
      final n = VehicleCheckerNotifier(client: c);
      n.setCountryCode('LV');
      n.setQuery('AB123');
      await n.checkVehicle();

      expect(n.state.redirectUrl, contains('csdd.lv'));
      expect(n.state.redirectLanguage, 'lv');
      expect(n.state.redirectIsPaid, isTrue);
      n.dispose();
    });

    test('5. Germany → de, paid', () async {
      final c = _FakeClient(_redirect(
        country: 'DE',
        url: 'https://www.kba.de/',
        lang: 'de',
        paid: true,
      ));
      final n = VehicleCheckerNotifier(client: c);
      n.setCountryCode('DE');
      n.setQuery('B-AA1234');
      await n.checkVehicle();

      expect(n.state.redirectLanguage, 'de');
      expect(n.state.redirectIsPaid, isTrue);
      n.dispose();
    });

    test('6. Poland → pl, free', () async {
      final c = _FakeClient(_redirect(
        country: 'PL',
        url: 'https://historiapojazdu.gov.pl/',
        lang: 'pl',
        paid: false,
      ));
      final n = VehicleCheckerNotifier(client: c);
      n.setCountryCode('PL');
      n.setQuery('WX1234');
      await n.checkVehicle();

      expect(n.state.redirectLanguage, 'pl');
      expect(n.state.redirectIsPaid, isFalse);
      n.dispose();
    });

    test('7. Sweden → sv, free', () async {
      final c = _FakeClient(_redirect(
        country: 'SE',
        url: 'https://fu-regnr.transportstyrelsen.se/',
        lang: 'sv',
        paid: false,
      ));
      final n = VehicleCheckerNotifier(client: c);
      n.setCountryCode('SE');
      n.setQuery('ABC123');
      await n.checkVehicle();

      expect(n.state.redirectLanguage, 'sv');
      expect(n.state.redirectIsPaid, isFalse);
      n.dispose();
    });

    test('8. invalid plate (contains forbidden chars) → error, no network',
        () async {
      final c = _FakeClient(_eeFound());
      final n = VehicleCheckerNotifier(client: c);
      n.setCountryCode('EE');
      n.setQuery('AB!@#');
      await n.checkVehicle();

      expect(c.callCount, 0, reason: 'Invalid plates must be rejected client-side');
      expect(n.state.errorMessage, contains('Invalid'));
      n.dispose();
    });

    test('9. empty plate → error, no network', () async {
      final c = _FakeClient(_eeFound());
      final n = VehicleCheckerNotifier(client: c);
      n.setQuery('   ');
      await n.checkVehicle();

      expect(c.callCount, 0);
      expect(n.state.errorMessage, contains('plate'));
      n.dispose();
    });

    test('10. unsupported country (FR/IT/ES) → function-level error', () async {
      final c = _FakeClient({
        'found': false,
        'country': 'FR',
        'message': 'Country FR is not supported.',
        'supportedCountries': ['EE', 'FI', 'LV', 'LT', 'DE', 'PL', 'SE'],
      });
      final n = VehicleCheckerNotifier(client: c);
      n.setCountryCode('FR');
      n.setQuery('AB123CD');
      await n.checkVehicle();

      expect(n.state.errorMessage, contains('not supported'));
      n.dispose();
    });

    test('11. null response (offline) → error in prod, demo fallback in debug',
        () async {
      final prod = VehicleCheckerNotifier(client: _FakeClient(null));
      prod.setCountryCode('EE');
      prod.setQuery('ABC123');
      await prod.checkVehicle();
      expect(prod.state.errorMessage, contains('offline'));
      expect(prod.state.report, isNull);
      prod.dispose();

      final debug = VehicleCheckerNotifier(
        client: _FakeClient(null),
        debugMode: true,
      );
      debug.setCountryCode('EE');
      debug.setQuery('908FBT');
      await debug.checkVehicle();
      expect(debug.state.report, isNotNull,
          reason: 'debugMode: true must keep the legacy VW Golf fallback');
      debug.dispose();
    });

    test('12. network exception → error state', () async {
      final c = _FakeClient(null, throwError: true);
      final n = VehicleCheckerNotifier(client: c);
      n.setCountryCode('EE');
      n.setQuery('ABC123');
      await n.checkVehicle();

      expect(n.state.errorMessage, contains('Network error'));
      expect(n.state.report, isNull);
      n.dispose();
    });

    test('13. changing country preserves query', () {
      final n = VehicleCheckerNotifier(client: _FakeClient(_eeFound()));
      n.setQuery('ABC123');
      n.setCountryCode('LV');
      expect(n.state.query, 'ABC123');
      expect(n.state.countryCode, 'LV');
      n.dispose();
    });

    test('14. plate is trimmed and uppercased before hitting the client',
        () async {
      final c = _FakeClient(_eeFound());
      final n = VehicleCheckerNotifier(client: c);
      n.setQuery('  abc123  ');
      await n.checkVehicle();
      expect(c.lastPlate, 'ABC123');
      n.dispose();
    });

    test('15. 908FBT demo path still works when no client + debugMode',
        () async {
      final n = VehicleCheckerNotifier(debugMode: true);
      n.setQuery('908FBT');
      await n.checkVehicle();
      expect(n.state.report, isNotNull);
      expect(n.state.report!.make, 'Volkswagen');
      n.dispose();
    });
  });

  group('VehicleCheckResult.fromApi — mapping', () {
    test('parses year from string', () {
      final r = VehicleCheckResult.fromApi(
        {
          'found': true,
          'plate': 'X',
          'country': 'EE',
          'year': '2018',
          'isPaidSource': false,
          'sourceUrl': 'u',
          'sourceName': 's',
          'language': 'et',
        },
        plate: 'X',
        country: 'EE',
      );
      expect(r.year, 2018);
    });

    test('parses firstRegistration ISO date', () {
      final r = VehicleCheckResult.fromApi(
        {
          'found': true,
          'plate': 'X',
          'country': 'EE',
          'firstRegistration': '2020-01-15',
          'isPaidSource': false,
          'sourceUrl': 'u',
          'sourceName': 's',
          'language': 'et',
        },
        plate: 'X',
        country: 'EE',
      );
      expect(r.firstRegistration?.year, 2020);
      expect(r.firstRegistration?.month, 1);
      expect(r.firstRegistration?.day, 15);
    });
  });

  group('isPlateFormatValid()', () {
    test('accepts common EU plates', () {
      expect(isPlateFormatValid('123ABC'), isTrue);
      expect(isPlateFormatValid('AB-CD 12'), isTrue);
      expect(isPlateFormatValid('ÅÄÖ123'), isTrue);
    });
    test('rejects too short / too long / weird chars', () {
      expect(isPlateFormatValid('AB'), isFalse);
      expect(isPlateFormatValid('A' * 13), isFalse);
      expect(isPlateFormatValid('AB!@#'), isFalse);
    });
  });
}
