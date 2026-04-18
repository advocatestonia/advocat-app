import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

enum RiskLevel { low, medium, high }

enum CompanyStatus { active, liquidated, bankrupt, unknown }

enum TaxDebtLevel { none, minor, significant }

/// Typed representation of a company check result as returned by the
/// Supabase `check-company` Edge Function plus derived UI fields.
///
/// The Edge Function returns a free-form map shaped like:
/// `{found, country, companies[], detailed{...}, source, check_url}`.
/// This class is the canonical UI-facing shape; use [CompanyReport.fromApi]
/// to build it safely from the raw payload.
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
    this.legalForm,
    this.capital,
    this.managementBoard = const [],
    this.emtakActivities = const [],
    this.turnover,
    this.profit,
    this.employees,
    this.sourceUrl,
    this.checkUrl,
    this.isFromRegistry = false,
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

  // ── Extended fields from the Estonian registry ─────────────────────────
  final String? legalForm;
  final String? capital;
  final List<String> managementBoard;
  final List<String> emtakActivities;
  final String? turnover;
  final String? profit;
  final String? employees;
  final String? sourceUrl;
  final String? checkUrl;

  /// `true` when the data in this report came from a real registry lookup,
  /// `false` for demo/fallback responses.
  final bool isFromRegistry;

  /// Build a [CompanyReport] from the raw `check-company` Edge Function
  /// response. Returns `null` when the function reports the company was
  /// not found.
  ///
  /// The registry currently returns machine-readable data only for
  /// Estonia; for other countries the function returns `{found: false}`
  /// together with a `check_url`.
  static CompanyReport? fromApi(
    Map<String, dynamic> api, {
    required String fallbackCountry,
  }) {
    final found = api['found'] == true;
    if (!found) return null;

    final detailed = api['detailed'] as Map<String, dynamic>?;
    final companies = (api['companies'] as List?) ?? const [];
    final first =
        companies.isNotEmpty ? companies.first as Map<String, dynamic> : null;

    // ── Basic identity ───────────────────────────────────────────────
    final name = (detailed?['name'] ??
            first?['name'] ??
            '')
        .toString();
    final regCode = (detailed?['registry_code'] ??
            first?['registry_code'] ??
            '')
        .toString();
    final address = (detailed?['address'] ??
            first?['address'] ??
            '')
        .toString();
    final statusText = (detailed?['status'] ??
            first?['status'] ??
            '')
        .toString();
    final legalForm = (detailed?['legal_form'] ?? '').toString();

    // ── Management ──────────────────────────────────────────────────
    final managementRaw = (detailed?['board_members'] as List?) ?? const [];
    final management = managementRaw.map((e) => e.toString()).toList();

    // ── Activities (EMTAK) ──────────────────────────────────────────
    final activitiesRaw = (detailed?['activities'] as List?) ?? const [];
    final activities = activitiesRaw.map((e) => e.toString()).toList();

    // ── Founding date ───────────────────────────────────────────────
    final registered = (detailed?['registered'] ?? '').toString();
    final founding = _parseDate(registered);

    // ── Status mapping ──────────────────────────────────────────────
    final companyStatus = _mapStatus(statusText);

    // ── Risk derivation ─────────────────────────────────────────────
    final risk = _deriveRisk(
      status: companyStatus,
      foundingDate: founding,
      capital: detailed?['capital']?.toString(),
      profit: detailed?['profit']?.toString(),
    );

    // ── AI summary (deterministic text built from registry facts) ───
    final summary = _buildSummary(
      name: name,
      regCode: regCode,
      status: companyStatus,
      founding: founding,
      legalForm: legalForm,
      capital: detailed?['capital']?.toString(),
      management: management,
      risk: risk,
    );

    return CompanyReport(
      companyName: name,
      registrationNumber: regCode,
      status: companyStatus,
      country: fallbackCountry,
      address: address,
      foundingDate: founding,
      taxDebtLevel: TaxDebtLevel.none, // registry does not expose this
      hasCourtCases: false, // registry does not expose this
      courtCasesCount: 0,
      riskLevel: risk,
      aiSummary: summary,
      legalForm: legalForm.isEmpty ? null : legalForm,
      capital: detailed?['capital']?.toString(),
      managementBoard: management,
      emtakActivities: activities,
      turnover: detailed?['revenue']?.toString(),
      profit: detailed?['profit']?.toString(),
      employees: detailed?['employees']?.toString(),
      sourceUrl: (api['source'] ?? '').toString(),
      checkUrl: (api['check_url'] ?? '').toString(),
      isFromRegistry: true,
    );
  }

  static DateTime _parseDate(String s) {
    // Accept "dd.mm.yyyy" or "yyyy-mm-dd" or "yyyy".
    if (s.isEmpty) return DateTime(1970, 1, 1);
    final dot = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$');
    final dotMatch = dot.firstMatch(s);
    if (dotMatch != null) {
      return DateTime(
        int.parse(dotMatch.group(3)!),
        int.parse(dotMatch.group(2)!),
        int.parse(dotMatch.group(1)!),
      );
    }
    final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})');
    final isoMatch = iso.firstMatch(s);
    if (isoMatch != null) {
      return DateTime(
        int.parse(isoMatch.group(1)!),
        int.parse(isoMatch.group(2)!),
        int.parse(isoMatch.group(3)!),
      );
    }
    final yearOnly = RegExp(r'^(\d{4})$');
    final yearMatch = yearOnly.firstMatch(s);
    if (yearMatch != null) {
      return DateTime(int.parse(yearMatch.group(1)!), 1, 1);
    }
    return DateTime(1970, 1, 1);
  }

  static CompanyStatus _mapStatus(String s) {
    final low = s.toLowerCase();
    if (low.contains('regist') || low.contains('active') || low == 'r') {
      return CompanyStatus.active;
    }
    if (low.contains('liquid') || low == 'l') return CompanyStatus.liquidated;
    if (low.contains('bankrupt') || low == 'k') return CompanyStatus.bankrupt;
    return CompanyStatus.unknown;
  }

  static RiskLevel _deriveRisk({
    required CompanyStatus status,
    required DateTime foundingDate,
    String? capital,
    String? profit,
  }) {
    // Terminal states are always high risk.
    if (status == CompanyStatus.bankrupt) return RiskLevel.high;
    if (status == CompanyStatus.liquidated) return RiskLevel.high;

    // Recently registered (< 1 year) → medium risk.
    final age = DateTime.now().difference(foundingDate).inDays;
    final recent = foundingDate.year > 1970 && age < 365;

    // Negative profit (minus sign present) → medium risk.
    final negativeProfit = profit != null && profit.trim().startsWith('-');

    // Very small capital (< 2500€) hints at shell company.
    final smallCapital = capital != null &&
        RegExp(r'^\s*[0-2][\d\s\u00a0]*€').hasMatch(capital);

    if (recent || negativeProfit || smallCapital) return RiskLevel.medium;
    return RiskLevel.low;
  }

  static String _buildSummary({
    required String name,
    required String regCode,
    required CompanyStatus status,
    required DateTime founding,
    required String legalForm,
    String? capital,
    required List<String> management,
    required RiskLevel risk,
  }) {
    final buf = StringBuffer();
    buf.write(name.isNotEmpty ? name : 'The company');
    if (regCode.isNotEmpty) buf.write(' (reg. $regCode)');
    buf.write(' is listed in the Estonian e-Business Register');
    if (founding.year > 1970) {
      buf.write(' with founding date ${founding.year}');
    }
    buf.write('. ');
    switch (status) {
      case CompanyStatus.active:
        buf.write('Status: active. ');
        break;
      case CompanyStatus.liquidated:
        buf.write('Status: liquidated — the company is no longer operating. ');
        break;
      case CompanyStatus.bankrupt:
        buf.write('Status: bankruptcy proceedings — strongly avoid. ');
        break;
      case CompanyStatus.unknown:
        buf.write('Status: unknown. ');
        break;
    }
    if (legalForm.isNotEmpty) buf.write('Legal form: $legalForm. ');
    if (capital != null && capital.isNotEmpty) {
      buf.write('Share capital: $capital. ');
    }
    if (management.isNotEmpty) {
      buf.write(
          'Management: ${management.take(3).join(', ')}${management.length > 3 ? '…' : ''}. ');
    }
    switch (risk) {
      case RiskLevel.low:
        buf.write(
            'No obvious red flags found in registry data. Always verify latest filings at the source.');
        break;
      case RiskLevel.medium:
        buf.write(
            'Some caution indicators were detected (recent registration, small capital, or negative profit). Verify before entering a contract.');
        break;
      case RiskLevel.high:
        buf.write(
            'High-risk indicator detected. We recommend avoiding new business with this entity until status changes.');
        break;
    }
    return buf.toString();
  }
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
    bool clearErrorMessage = false,
    String? query,
    String? selectedCountry,
  }) {
    return CompanyCheckerState(
      status: status ?? this.status,
      report: report ?? this.report,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
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
// Edge Function client abstraction (for test injection)
// ---------------------------------------------------------------------------

/// Minimal interface used by the notifier to call the `check-company`
/// Edge Function. Wrapping [SupabaseService.callEdgeFunction] behind an
/// interface lets us inject deterministic fixtures in unit tests without
/// spinning up a real Supabase client.
abstract class CompanyCheckClient {
  Future<Map<String, dynamic>?> checkCompany({
    required String companyName,
    required String country,
  });
}

/// Production adapter — delegates to [SupabaseService.callEdgeFunction].
class SupabaseCompanyCheckClient implements CompanyCheckClient {
  SupabaseCompanyCheckClient(this._service);
  final SupabaseService _service;

  @override
  Future<Map<String, dynamic>?> checkCompany({
    required String companyName,
    required String country,
  }) {
    return _service.callEdgeFunction(
      'check-company',
      body: {'company_name': companyName, 'country': country},
    );
  }
}

// ---------------------------------------------------------------------------
// StateNotifier
// ---------------------------------------------------------------------------

class CompanyCheckerNotifier extends StateNotifier<CompanyCheckerState> {
  CompanyCheckerNotifier({
    CompanyCheckClient? client,
    this.debugMode = false,
  })  : _client = client,
        super(const CompanyCheckerState());

  final CompanyCheckClient? _client;

  /// When `true`, empty responses fall back to a deterministic demo report
  /// (used by local dev / old keyword tests). Must remain `false` in
  /// production builds — production responses come exclusively from the
  /// `check-company` Edge Function.
  final bool debugMode;

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
    final trimmed = state.query.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(
        status: CheckerStatus.error,
        errorMessage: 'Please enter a company name or registration number',
      );
      return;
    }

    state = state.copyWith(status: CheckerStatus.loading, clearErrorMessage: true);

    // ── Real Edge Function path ──────────────────────────────────────
    if (_client != null) {
      Map<String, dynamic>? api;
      try {
        api = await _client.checkCompany(
          companyName: trimmed,
          country: state.selectedCountry,
        );
      } catch (e) {
        state = state.copyWith(
          status: CheckerStatus.error,
          errorMessage: 'Network error while querying registry. Please try again.',
        );
        return;
      }

      if (api == null) {
        // Not-authenticated / demo mode → fall through to optional demo.
        if (debugMode) {
          final report = _getMockReport(trimmed, state.selectedCountry);
          state = state.copyWith(status: CheckerStatus.results, report: report);
          return;
        }
        state = state.copyWith(
          status: CheckerStatus.error,
          errorMessage:
              'Registry lookup is not available in offline/demo mode. Please sign in and retry.',
        );
        return;
      }

      final found = api['found'] == true;
      if (!found) {
        final countryName = (api['country'] as String?) ?? state.selectedCountry;
        final checkUrl = (api['check_url'] as String?) ?? '';
        state = state.copyWith(
          status: CheckerStatus.error,
          errorMessage: checkUrl.isNotEmpty
              ? 'Company "$trimmed" not found in $countryName registry. Verify at: $checkUrl'
              : 'Company "$trimmed" not found in $countryName registry.',
        );
        return;
      }

      final report = CompanyReport.fromApi(
        api,
        fallbackCountry: state.selectedCountry,
      );
      if (report == null) {
        state = state.copyWith(
          status: CheckerStatus.error,
          errorMessage: 'Registry returned an unexpected response shape.',
        );
        return;
      }
      state = state.copyWith(status: CheckerStatus.results, report: report);
      return;
    }

    // ── No client injected → legacy demo path (debug only) ──────────
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    final report = _getMockReport(trimmed, state.selectedCountry);
    state = state.copyWith(status: CheckerStatus.results, report: report);
  }

  /// Legacy demo report — **debug-only**. Kept solely so the keyword-based
  /// smoke tests (bad/risk/caution) that exist in `company_checker_test.dart`
  /// still pass without a Supabase client.
  CompanyReport _getMockReport(String query, String country) {
    final lowerQuery = query.toLowerCase();

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

/// Production provider — uses Supabase Edge Function.
final companyCheckerProvider =
    StateNotifierProvider<CompanyCheckerNotifier, CompanyCheckerState>(
  (ref) {
    final supabase = ref.watch(supabaseServiceProvider);
    return CompanyCheckerNotifier(
      client: SupabaseCompanyCheckClient(supabase),
    );
  },
);
