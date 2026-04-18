// =============================================================================
// Real Edge-Function integration tests for CompanyCheckerNotifier — P0-1
// =============================================================================
//
// Covers the production path where [CompanyCheckerNotifier] talks to the
// Supabase `check-company` Edge Function instead of returning hardcoded
// TechFlow/BadCorp mocks. The real Edge Function is exercised by the
// Supabase test suite; here we inject a fake [CompanyCheckClient] that
// returns fixture payloads captured from ariregister.rik.ee.
//
// Scenarios:
//   1. Real Estonian company found (happy path, detailed data)
//   2. Autocomplete-only response (no `detailed` block)
//   3. Company not found (404 from registry)
//   4. Registry returns bankrupt status → RiskLevel.high
//   5. Liquidated company → RiskLevel.high
//   6. Recently registered (< 1 year) → RiskLevel.medium
//   7. Network error (exception thrown by client)
//   8. Null response (SupabaseService.callEdgeFunction returned null)
//   9. Cyrillic / Russian company name input
//  10. Numeric registry code as query
//  11. Empty query guard
//  12. Partial name with whitespace
//  13. CompanyReport.fromApi — malformed payload returns null
//  14. CompanyReport.fromApi — unknown status string

import 'package:flutter_test/flutter_test.dart';
import 'package:advocat/features/checker/providers/company_checker_provider.dart';

class _FakeClient implements CompanyCheckClient {
  _FakeClient(this._response, {this.throwError = false});

  final Map<String, dynamic>? _response;
  final bool throwError;

  String? lastName;
  String? lastCountry;
  int callCount = 0;

  @override
  Future<Map<String, dynamic>?> checkCompany({
    required String companyName,
    required String country,
  }) async {
    callCount += 1;
    lastName = companyName;
    lastCountry = country;
    if (throwError) throw Exception('Network down');
    return _response;
  }
}

/// Fixture modeled on an actual ariregister.rik.ee response for an
/// active Estonian OÜ (Bolt Technology OÜ), trimmed to what our
/// Edge Function emits.
Map<String, dynamic> _activeEstonianCompanyFixture() => {
      'found': true,
      'country': 'Estonia',
      'companies': [
        {
          'name': 'Bolt Technology OÜ',
          'registry_code': '12417834',
          'status': 'R',
          'address': 'Vana-Lõuna tn 15, 10134 Tallinn',
          'type': '5',
          'url': 'https://ariregister.rik.ee/est/company/12417834',
          'historical_names': <String>[],
        },
      ],
      'detailed': {
        'name': 'Bolt Technology OÜ',
        'registry_code': '12417834',
        'status': 'Registered',
        'registered': '19.08.2013',
        'legal_form': 'Osaühing (OÜ)',
        'capital': '31 222 517 €',
        'address': 'Vana-Lõuna tn 15, 10134 Tallinn',
        'activities': [
          '62019 — Other software development',
          '46499 — Wholesale of other household goods',
        ],
        'board_members': ['Markus Villig', 'Martin Villig'],
        'fiscal_year': '01.01.2024 - 31.12.2024',
        'profit': '12 450 000',
        'revenue': '1 800 000 000',
        'employees': '5200',
        'historical_names': <String>[],
      },
      'source': 'ariregister.rik.ee',
      'check_url': 'https://ariregister.rik.ee/est/company/12417834',
    };

Map<String, dynamic> _bankruptFixture() => {
      'found': true,
      'country': 'Estonia',
      'companies': [
        {
          'name': 'Pankrot OÜ',
          'registry_code': '10000001',
          'status': 'K',
          'address': 'Tallinn',
          'type': '5',
          'url': '',
          'historical_names': <String>[],
        },
      ],
      'detailed': {
        'name': 'Pankrot OÜ',
        'registry_code': '10000001',
        'status': 'Bankruptcy',
        'registered': '01.01.2010',
        'legal_form': 'Osaühing (OÜ)',
        'capital': '2500 €',
        'address': 'Tallinn',
        'activities': <String>[],
        'board_members': <String>[],
        'fiscal_year': '',
        'profit': '-50 000',
        'revenue': '',
        'employees': '',
        'historical_names': <String>[],
      },
      'source': 'ariregister.rik.ee',
      'check_url': 'https://ariregister.rik.ee/est/company/10000001',
    };

Map<String, dynamic> _liquidatedFixture() => {
      'found': true,
      'country': 'Estonia',
      'companies': [
        {
          'name': 'Old Inactive OÜ',
          'registry_code': '11111111',
          'status': 'L',
          'address': 'Tartu',
          'type': '5',
          'url': '',
          'historical_names': <String>[],
        },
      ],
      'detailed': {
        'name': 'Old Inactive OÜ',
        'registry_code': '11111111',
        'status': 'Liquidated',
        'registered': '01.01.2005',
        'legal_form': 'Osaühing (OÜ)',
        'capital': null,
        'address': 'Tartu',
        'activities': <String>[],
        'board_members': <String>[],
        'fiscal_year': '',
        'profit': null,
        'revenue': null,
        'employees': null,
        'historical_names': <String>[],
      },
      'source': 'ariregister.rik.ee',
      'check_url': 'https://ariregister.rik.ee/est/company/11111111',
    };

Map<String, dynamic> _recentStartupFixture() {
      final now = DateTime.now();
      final recent = DateTime(now.year, now.month, now.day - 60); // 60 days ago
      final dd = recent.day.toString().padLeft(2, '0');
      final mm = recent.month.toString().padLeft(2, '0');
      final yyyy = recent.year.toString();
      return {
        'found': true,
        'country': 'Estonia',
        'companies': [
          {
            'name': 'New Startup OÜ',
            'registry_code': '16999999',
            'status': 'R',
            'address': 'Tallinn',
            'type': '5',
            'url': '',
            'historical_names': <String>[],
          },
        ],
        'detailed': {
          'name': 'New Startup OÜ',
          'registry_code': '16999999',
          'status': 'Registered',
          'registered': '$dd.$mm.$yyyy',
          'legal_form': 'Osaühing (OÜ)',
          'capital': '2500 €',
          'address': 'Tallinn',
          'activities': <String>[],
          'board_members': ['Jane Founder'],
          'fiscal_year': '',
          'profit': null,
          'revenue': null,
          'employees': null,
          'historical_names': <String>[],
        },
        'source': 'ariregister.rik.ee',
        'check_url': 'https://ariregister.rik.ee/est/company/16999999',
      };
    }

Map<String, dynamic> _notFoundFixture(String query) => {
      'found': false,
      'country': 'Estonia',
      'message': 'Company "$query" not found in Estonian registry',
      'check_url':
          'https://ariregister.rik.ee/est/company?search_query=${Uri.encodeComponent(query)}',
    };

Map<String, dynamic> _autocompleteOnlyFixture() => {
      'found': true,
      'country': 'Estonia',
      'companies': [
        {
          'name': 'Test OÜ',
          'registry_code': '12345678',
          'status': 'R',
          'address': 'Tallinn',
          'type': '5',
          'url': '',
          'historical_names': <String>[],
        },
      ],
      // `detailed` intentionally missing to simulate scraper fallback
      'source': 'ariregister.rik.ee',
      'check_url': 'https://ariregister.rik.ee/est/company/12345678',
    };

void main() {
  group('CompanyCheckerNotifier — real Edge Function path', () {
    test('1. active Estonian company produces low-risk report with all fields',
        () async {
      final client = _FakeClient(_activeEstonianCompanyFixture());
      final n = CompanyCheckerNotifier(client: client);

      n.setQuery('Bolt Technology');
      n.setCountry('EE');
      await n.checkCompany();

      expect(client.callCount, 1);
      expect(client.lastName, 'Bolt Technology');
      expect(client.lastCountry, 'EE');
      expect(n.state.status, CheckerStatus.results);

      final r = n.state.report!;
      expect(r.companyName, 'Bolt Technology OÜ');
      expect(r.registrationNumber, '12417834');
      expect(r.status, CompanyStatus.active);
      expect(r.country, 'EE');
      expect(r.address, contains('Tallinn'));
      expect(r.foundingDate.year, 2013);
      expect(r.riskLevel, RiskLevel.low);
      expect(r.isFromRegistry, isTrue);
      expect(r.legalForm, contains('Osaühing'));
      expect(r.capital, contains('€'));
      expect(r.managementBoard, containsAll(['Markus Villig', 'Martin Villig']));
      expect(r.emtakActivities, isNotEmpty);
      expect(r.turnover, contains('1 800 000 000'));
      expect(r.employees, '5200');
      expect(r.aiSummary, contains('Bolt Technology'));
      expect(r.aiSummary, contains('active'));
      expect(r.checkUrl, startsWith('https://ariregister.rik.ee'));
    });

    test('2. autocomplete-only payload still produces a usable report',
        () async {
      final client = _FakeClient(_autocompleteOnlyFixture());
      final n = CompanyCheckerNotifier(client: client);

      n.setQuery('Test');
      await n.checkCompany();

      expect(n.state.status, CheckerStatus.results);
      final r = n.state.report!;
      expect(r.companyName, 'Test OÜ');
      expect(r.registrationNumber, '12345678');
      expect(r.status, CompanyStatus.active);
      expect(r.managementBoard, isEmpty);
      expect(r.isFromRegistry, isTrue);
    });

    test('3. not-found returns error with check_url in message', () async {
      final client = _FakeClient(_notFoundFixture('NonExistent'));
      final n = CompanyCheckerNotifier(client: client);

      n.setQuery('NonExistent');
      await n.checkCompany();

      expect(n.state.status, CheckerStatus.error);
      expect(n.state.errorMessage, contains('not found'));
      expect(n.state.errorMessage, contains('ariregister.rik.ee'));
    });

    test('4. bankrupt company → RiskLevel.high', () async {
      final client = _FakeClient(_bankruptFixture());
      final n = CompanyCheckerNotifier(client: client);

      n.setQuery('Pankrot');
      await n.checkCompany();

      final r = n.state.report!;
      expect(r.status, CompanyStatus.bankrupt);
      expect(r.riskLevel, RiskLevel.high);
      expect(r.aiSummary.toLowerCase(), contains('bankrupt'));
    });

    test('5. liquidated company → RiskLevel.high', () async {
      final client = _FakeClient(_liquidatedFixture());
      final n = CompanyCheckerNotifier(client: client);

      n.setQuery('Old Inactive');
      await n.checkCompany();

      final r = n.state.report!;
      expect(r.status, CompanyStatus.liquidated);
      expect(r.riskLevel, RiskLevel.high);
    });

    test('6. recent registration (<1 year) → RiskLevel.medium', () async {
      final client = _FakeClient(_recentStartupFixture());
      final n = CompanyCheckerNotifier(client: client);

      n.setQuery('New Startup');
      await n.checkCompany();

      final r = n.state.report!;
      expect(r.status, CompanyStatus.active);
      expect(r.riskLevel, RiskLevel.medium,
          reason: 'A company <1 year old with small capital must flag medium risk');
    });

    test('7. network exception → error state, report not produced', () async {
      final client = _FakeClient(null, throwError: true);
      final n = CompanyCheckerNotifier(client: client);

      n.setQuery('Any Company');
      await n.checkCompany();

      expect(n.state.status, CheckerStatus.error);
      expect(n.state.errorMessage!.toLowerCase(), contains('network'));
      expect(n.state.report, isNull);
    });

    test('8. null response (demo/offline) → error in prod, mock in debug',
        () async {
      final prod = CompanyCheckerNotifier(client: _FakeClient(null));
      prod.setQuery('Anything');
      await prod.checkCompany();
      expect(prod.state.status, CheckerStatus.error);
      expect(prod.state.errorMessage!.toLowerCase(), contains('offline'));

      final debug = CompanyCheckerNotifier(
        client: _FakeClient(null),
        debugMode: true,
      );
      debug.setQuery('Anything');
      await debug.checkCompany();
      expect(debug.state.status, CheckerStatus.results,
          reason: 'debugMode: true should fall back to legacy demo');
    });

    test('9. cyrillic input (Russian) is passed through unchanged', () async {
      final client = _FakeClient(_notFoundFixture('Сбербанк'));
      final n = CompanyCheckerNotifier(client: client);

      n.setQuery('Сбербанк');
      await n.checkCompany();

      expect(client.lastName, 'Сбербанк');
      expect(n.state.status, CheckerStatus.error);
    });

    test('10. numeric registry code as query', () async {
      final client = _FakeClient(_activeEstonianCompanyFixture());
      final n = CompanyCheckerNotifier(client: client);

      n.setQuery('12417834');
      await n.checkCompany();

      expect(client.lastName, '12417834');
      expect(n.state.status, CheckerStatus.results);
    });

    test('11. empty query → error, does not call the Edge Function',
        () async {
      final client = _FakeClient(_activeEstonianCompanyFixture());
      final n = CompanyCheckerNotifier(client: client);

      n.setQuery('   ');
      await n.checkCompany();

      expect(client.callCount, 0);
      expect(n.state.status, CheckerStatus.error);
      expect(n.state.errorMessage, contains('enter'));
    });

    test('12. partial name with whitespace is trimmed before request',
        () async {
      final client = _FakeClient(_activeEstonianCompanyFixture());
      final n = CompanyCheckerNotifier(client: client);

      n.setQuery('  Bolt  ');
      await n.checkCompany();

      expect(client.lastName, 'Bolt',
          reason: 'Notifier must trim() the query before calling the client');
    });
  });

  group('CompanyReport.fromApi — pure mapping', () {
    test('13. malformed payload (found:false) returns null', () {
      final r = CompanyReport.fromApi(
        {'found': false, 'country': 'Estonia'},
        fallbackCountry: 'EE',
      );
      expect(r, isNull);
    });

    test('14. unknown status string defaults to CompanyStatus.unknown', () {
      final r = CompanyReport.fromApi({
        'found': true,
        'companies': [
          {'name': 'Weird Inc', 'registry_code': '1', 'status': ''},
        ],
        'detailed': {
          'name': 'Weird Inc',
          'registry_code': '1',
          'status': 'Mystery-state',
          'registered': '',
          'legal_form': '',
          'capital': null,
          'address': '',
          'activities': <String>[],
          'board_members': <String>[],
        },
        'source': 'ariregister.rik.ee',
        'check_url': '',
      }, fallbackCountry: 'EE');
      expect(r, isNotNull);
      expect(r!.status, CompanyStatus.unknown);
    });
  });
}
