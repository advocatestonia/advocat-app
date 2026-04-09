import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

enum RiskLevel { low, medium, high }

enum CompanyStatus { active, liquidated, bankrupt, unknown }

enum TaxDebtLevel { none, minor, significant }

class CompanyReport {
  const CompanyReport({
    required this.companyName,
    required this.registrationNumber,
    required this.status,
    required this.country,
    required this.address,
    required this.foundingDate,
    required this.taxDebtLevel,
    required this.hasCourtCases,
    required this.courtCasesCount,
    required this.riskLevel,
    required this.aiSummary,
  });

  final String companyName;
  final String registrationNumber;
  final CompanyStatus status;
  final String country;
  final String address;
  final DateTime foundingDate;
  final TaxDebtLevel taxDebtLevel;
  final bool hasCourtCases;
  final int courtCasesCount;
  final RiskLevel riskLevel;
  final String aiSummary;
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum CheckerStatus { idle, loading, results, error }

class CompanyCheckerState {
  const CompanyCheckerState({
    this.status = CheckerStatus.idle,
    this.report,
    this.errorMessage,
    this.query = '',
    this.selectedCountry = 'EE',
  });

  final CheckerStatus status;
  final CompanyReport? report;
  final String? errorMessage;
  final String query;
  final String selectedCountry;

  CompanyCheckerState copyWith({
    CheckerStatus? status,
    CompanyReport? report,
    String? errorMessage,
    String? query,
    String? selectedCountry,
  }) {
    return CompanyCheckerState(
      status: status ?? this.status,
      report: report ?? this.report,
      errorMessage: errorMessage ?? this.errorMessage,
      query: query ?? this.query,
      selectedCountry: selectedCountry ?? this.selectedCountry,
    );
  }
}

// ---------------------------------------------------------------------------
// Country list
// ---------------------------------------------------------------------------

class CheckerCountry {
  const CheckerCountry({required this.code, required this.name, required this.flag});
  final String code;
  final String name;
  final String flag;
}

const checkerCountries = [
  CheckerCountry(code: 'EE', name: 'Estonia', flag: '🇪🇪'),
  CheckerCountry(code: 'FI', name: 'Finland', flag: '🇫🇮'),
  CheckerCountry(code: 'LV', name: 'Latvia', flag: '🇱🇻'),
  CheckerCountry(code: 'LT', name: 'Lithuania', flag: '🇱🇹'),
  CheckerCountry(code: 'DE', name: 'Germany', flag: '🇩🇪'),
  CheckerCountry(code: 'SE', name: 'Sweden', flag: '🇸🇪'),
  CheckerCountry(code: 'PL', name: 'Poland', flag: '🇵🇱'),
  CheckerCountry(code: 'FR', name: 'France', flag: '🇫🇷'),
  CheckerCountry(code: 'IT', name: 'Italy', flag: '🇮🇹'),
  CheckerCountry(code: 'ES', name: 'Spain', flag: '🇪🇸'),
];

// ---------------------------------------------------------------------------
// StateNotifier
// ---------------------------------------------------------------------------

class CompanyCheckerNotifier extends StateNotifier<CompanyCheckerState> {
  CompanyCheckerNotifier() : super(const CompanyCheckerState());

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void setCountry(String countryCode) {
    state = state.copyWith(selectedCountry: countryCode);
  }

  void reset() {
    state = const CompanyCheckerState();
  }

  Future<void> checkCompany() async {
    if (state.query.trim().isEmpty) {
      state = state.copyWith(
        status: CheckerStatus.error,
        errorMessage: 'Please enter a company name or registration number',
      );
      return;
    }

    state = state.copyWith(status: CheckerStatus.loading, errorMessage: null);

    // Simulate network delay for demo
    await Future<void>.delayed(const Duration(milliseconds: 1800));

    // TODO: Replace with real API call
    // For demo: return mock data
    final report = _getMockReport(state.query, state.selectedCountry);
    state = state.copyWith(status: CheckerStatus.results, report: report);
  }

  CompanyReport _getMockReport(String query, String country) {
    final lowerQuery = query.toLowerCase();

    // Provide different mock results based on query
    if (lowerQuery.contains('bad') || lowerQuery.contains('risk')) {
      return CompanyReport(
        companyName: 'Bad Corp International O\u00DC',
        registrationNumber: '98765432',
        status: CompanyStatus.active,
        country: country,
        address: 'Narva mnt 1, 10117 Tallinn',
        foundingDate: DateTime(2019, 3, 15),
        taxDebtLevel: TaxDebtLevel.significant,
        hasCourtCases: true,
        courtCasesCount: 4,
        riskLevel: RiskLevel.high,
        aiSummary:
            'This company has significant tax debt and multiple pending court cases. '
            'The company has changed directors 3 times in the past year. '
            'We strongly recommend avoiding business dealings with this entity.',
      );
    }

    if (lowerQuery.contains('caution') || lowerQuery.contains('medium')) {
      return CompanyReport(
        companyName: 'Nordic Trade Solutions O\u00DC',
        registrationNumber: '55443321',
        status: CompanyStatus.active,
        country: country,
        address: 'Tartu mnt 52, 10115 Tallinn',
        foundingDate: DateTime(2021, 7, 1),
        taxDebtLevel: TaxDebtLevel.minor,
        hasCourtCases: true,
        courtCasesCount: 1,
        riskLevel: RiskLevel.medium,
        aiSummary:
            'This company has minor tax payment delays and one resolved court case from 2023. '
            'The company is relatively new (founded 2021). '
            'Proceed with caution and request upfront payment or guarantees.',
      );
    }

    // Default: safe company
    return CompanyReport(
      companyName: 'TechFlow Estonia O\u00DC',
      registrationNumber: '12345678',
      status: CompanyStatus.active,
      country: country,
      address: 'P\u00e4rnu mnt 25, 10141 Tallinn',
      foundingDate: DateTime(2015, 6, 12),
      taxDebtLevel: TaxDebtLevel.none,
      hasCourtCases: false,
      courtCasesCount: 0,
      riskLevel: RiskLevel.low,
      aiSummary:
          'This company has been operating since 2015 with a clean financial record. '
          'No tax debts or court cases found. '
          'The company appears reliable and safe to work with.',
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final companyCheckerProvider =
    StateNotifierProvider<CompanyCheckerNotifier, CompanyCheckerState>(
  (ref) => CompanyCheckerNotifier(),
);
