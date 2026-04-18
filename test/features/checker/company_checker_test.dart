import 'package:flutter_test/flutter_test.dart';
import 'package:advocat/features/checker/providers/company_checker_provider.dart';

void main() {
  group('CompanyCheckerState', () {
    test('initial state has idle status', () {
      const state = CompanyCheckerState();
      expect(state.status, CheckerStatus.idle);
    });

    test('initial state has no report', () {
      const state = CompanyCheckerState();
      expect(state.report, isNull);
    });

    test('initial state has no error message', () {
      const state = CompanyCheckerState();
      expect(state.errorMessage, isNull);
    });

    test('initial state has empty query', () {
      const state = CompanyCheckerState();
      expect(state.query, isEmpty);
    });

    test('initial state defaults to EE country', () {
      const state = CompanyCheckerState();
      expect(state.selectedCountry, 'EE');
    });

    test('copyWith preserves values when no arguments given', () {
      const state = CompanyCheckerState(
        status: CheckerStatus.loading,
        query: 'test',
        selectedCountry: 'FI',
      );
      final copied = state.copyWith();
      expect(copied.status, CheckerStatus.loading);
      expect(copied.query, 'test');
      expect(copied.selectedCountry, 'FI');
    });

    test('copyWith overrides specified fields', () {
      const state = CompanyCheckerState();
      final updated = state.copyWith(
        query: 'My Company',
        selectedCountry: 'DE',
      );
      expect(updated.query, 'My Company');
      expect(updated.selectedCountry, 'DE');
      expect(updated.status, CheckerStatus.idle); // unchanged
    });
  });

  group('CompanyCheckerNotifier', () {
    late CompanyCheckerNotifier notifier;

    setUp(() {
      // Legacy keyword-based mock mode — kept for regression coverage
      // of the demo fallback. Production uses the real Edge Function
      // (see company_checker_real_test.dart).
      notifier = CompanyCheckerNotifier(debugMode: true);
    });

    test('initial state is idle', () {
      expect(notifier.state.status, CheckerStatus.idle);
    });

    group('setQuery()', () {
      test('updates query string', () {
        notifier.setQuery('TechFlow');
        expect(notifier.state.query, 'TechFlow');
      });

      test('does not change status', () {
        notifier.setQuery('TechFlow');
        expect(notifier.state.status, CheckerStatus.idle);
      });
    });

    group('setCountry()', () {
      test('updates selected country', () {
        notifier.setCountry('FI');
        expect(notifier.state.selectedCountry, 'FI');
      });

      test('does not change query', () {
        notifier.setQuery('some query');
        notifier.setCountry('DE');
        expect(notifier.state.query, 'some query');
      });
    });

    group('reset()', () {
      test('resets to default state', () {
        notifier.setQuery('test');
        notifier.setCountry('FR');
        notifier.reset();

        expect(notifier.state.status, CheckerStatus.idle);
        expect(notifier.state.query, isEmpty);
        expect(notifier.state.selectedCountry, 'EE');
        expect(notifier.state.report, isNull);
        expect(notifier.state.errorMessage, isNull);
      });
    });

    group('checkCompany()', () {
      test('sets error when query is empty', () async {
        notifier.setQuery('');
        await notifier.checkCompany();

        expect(notifier.state.status, CheckerStatus.error);
        expect(notifier.state.errorMessage, isNotNull);
        expect(notifier.state.errorMessage, contains('enter'));
      });

      test('sets error when query is whitespace only', () async {
        notifier.setQuery('   ');
        await notifier.checkCompany();

        expect(notifier.state.status, CheckerStatus.error);
      });

      test('transitions through loading to results', () async {
        notifier.setQuery('TechFlow');

        // Capture loading state
        bool wasLoading = false;
        notifier.addListener((state) {
          if (state.status == CheckerStatus.loading) {
            wasLoading = true;
          }
        });

        await notifier.checkCompany();

        expect(wasLoading, isTrue);
        expect(notifier.state.status, CheckerStatus.results);
        expect(notifier.state.report, isNotNull);
      });

      test('returns safe company for generic query', () async {
        notifier.setQuery('TechFlow');
        await notifier.checkCompany();

        final report = notifier.state.report!;
        expect(report.riskLevel, RiskLevel.low);
        expect(report.taxDebtLevel, TaxDebtLevel.none);
        expect(report.hasCourtCases, isFalse);
        expect(report.courtCasesCount, 0);
      });

      test('returns high risk for queries containing "bad"', () async {
        notifier.setQuery('bad company');
        await notifier.checkCompany();

        final report = notifier.state.report!;
        expect(report.riskLevel, RiskLevel.high);
        expect(report.taxDebtLevel, TaxDebtLevel.significant);
        expect(report.hasCourtCases, isTrue);
        expect(report.courtCasesCount, greaterThan(0));
      });

      test('returns high risk for queries containing "risk"', () async {
        notifier.setQuery('risky business');
        await notifier.checkCompany();

        final report = notifier.state.report!;
        expect(report.riskLevel, RiskLevel.high);
      });

      test('returns medium risk for queries containing "caution"', () async {
        notifier.setQuery('caution trade');
        await notifier.checkCompany();

        final report = notifier.state.report!;
        expect(report.riskLevel, RiskLevel.medium);
        expect(report.taxDebtLevel, TaxDebtLevel.minor);
      });

      test('returns medium risk for queries containing "medium"', () async {
        notifier.setQuery('medium corp');
        await notifier.checkCompany();

        final report = notifier.state.report!;
        expect(report.riskLevel, RiskLevel.medium);
      });

      test('uses selected country in report', () async {
        notifier.setQuery('TechFlow');
        notifier.setCountry('FI');
        await notifier.checkCompany();

        expect(notifier.state.report!.country, 'FI');
      });

      test('clears error on new check', () async {
        // First trigger an error
        notifier.setQuery('');
        await notifier.checkCompany();
        expect(notifier.state.errorMessage, isNotNull);

        // Then do a valid check
        notifier.setQuery('TechFlow');
        // The loading state should clear the error
        bool errorCleared = false;
        notifier.addListener((state) {
          if (state.status == CheckerStatus.loading &&
              state.errorMessage == null) {
            errorCleared = true;
          }
        });
        await notifier.checkCompany();
        expect(errorCleared, isTrue);
      });
    });
  });

  group('CompanyReport model', () {
    test('can construct a CompanyReport', () {
      final report = CompanyReport(
        companyName: 'Test OUe',
        registrationNumber: '12345678',
        status: CompanyStatus.active,
        country: 'EE',
        address: 'Test street 1',
        foundingDate: DateTime(2020, 1, 1),
        taxDebtLevel: TaxDebtLevel.none,
        hasCourtCases: false,
        courtCasesCount: 0,
        riskLevel: RiskLevel.low,
        aiSummary: 'Safe company',
      );

      expect(report.companyName, 'Test OUe');
      expect(report.registrationNumber, '12345678');
      expect(report.status, CompanyStatus.active);
      expect(report.country, 'EE');
      expect(report.riskLevel, RiskLevel.low);
    });
  });

  group('CompanyStatus enum', () {
    test('has all expected values', () {
      expect(CompanyStatus.values, hasLength(4));
      expect(CompanyStatus.values, contains(CompanyStatus.active));
      expect(CompanyStatus.values, contains(CompanyStatus.liquidated));
      expect(CompanyStatus.values, contains(CompanyStatus.bankrupt));
      expect(CompanyStatus.values, contains(CompanyStatus.unknown));
    });
  });

  group('RiskLevel enum', () {
    test('has low, medium, high', () {
      expect(RiskLevel.values, hasLength(3));
      expect(RiskLevel.values, contains(RiskLevel.low));
      expect(RiskLevel.values, contains(RiskLevel.medium));
      expect(RiskLevel.values, contains(RiskLevel.high));
    });
  });

  group('TaxDebtLevel enum', () {
    test('has none, minor, significant', () {
      expect(TaxDebtLevel.values, hasLength(3));
      expect(TaxDebtLevel.values, contains(TaxDebtLevel.none));
      expect(TaxDebtLevel.values, contains(TaxDebtLevel.minor));
      expect(TaxDebtLevel.values, contains(TaxDebtLevel.significant));
    });
  });

  group('CheckerStatus enum', () {
    test('has idle, loading, results, error', () {
      expect(CheckerStatus.values, hasLength(4));
      expect(CheckerStatus.values, contains(CheckerStatus.idle));
      expect(CheckerStatus.values, contains(CheckerStatus.loading));
      expect(CheckerStatus.values, contains(CheckerStatus.results));
      expect(CheckerStatus.values, contains(CheckerStatus.error));
    });
  });

  group('Supported countries', () {
    test('has 10 countries', () {
      expect(checkerCountries, hasLength(10));
    });

    test('includes Estonia (EE)', () {
      expect(
        checkerCountries.any((c) => c.code == 'EE'),
        isTrue,
      );
    });

    test('includes Finland (FI)', () {
      expect(
        checkerCountries.any((c) => c.code == 'FI'),
        isTrue,
      );
    });

    test('includes all expected country codes', () {
      final codes = checkerCountries.map((c) => c.code).toSet();
      expect(codes, containsAll(['EE', 'FI', 'LV', 'LT', 'DE', 'SE', 'PL', 'FR', 'IT', 'ES']));
    });

    test('each country has a non-empty name', () {
      for (final country in checkerCountries) {
        expect(country.name, isNotEmpty,
            reason: 'Country ${country.code} has empty name');
      }
    });

    test('each country has a non-empty flag', () {
      for (final country in checkerCountries) {
        expect(country.flag, isNotEmpty,
            reason: 'Country ${country.code} has empty flag');
      }
    });

    test('each country has a 2-letter code', () {
      for (final country in checkerCountries) {
        expect(country.code.length, 2,
            reason: 'Country code "${country.code}" is not 2 letters');
      }
    });

    test('Estonia is the first country in the list', () {
      expect(checkerCountries.first.code, 'EE');
    });
  });

  group('CheckerCountry model', () {
    test('can construct with required fields', () {
      const country = CheckerCountry(
        code: 'EE',
        name: 'Estonia',
        flag: 'flag',
      );
      expect(country.code, 'EE');
      expect(country.name, 'Estonia');
      expect(country.flag, 'flag');
    });
  });
}
