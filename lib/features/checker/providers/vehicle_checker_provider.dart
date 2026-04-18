import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';

// ---------------------------------------------------------------------------
// Vehicle Checker Provider — State management for vehicle checks
//
// P0-2: no more hard-coded 908FBT demo. The notifier now talks to the
// Supabase `check-vehicle` Edge Function. For non-Estonian countries the
// function returns a redirect URL + language instead of fabricating data.
// ---------------------------------------------------------------------------

/// Represents the input mode for vehicle lookup.
enum VehicleInputMode { licensePlate, vin }

/// AI assessment level for the vehicle.
enum VehicleAssessment { safeToBuy, someConcerns, doNotBuy }

/// A single mileage history entry (reserved for future paid-data sources).
class MileageRecord {
  const MileageRecord({
    required this.date,
    required this.mileageKm,
    required this.source,
  });

  final DateTime date;
  final int mileageKm;
  final String source;
}

/// Typed wrapper around the `check-vehicle` Edge Function response. Use
/// [VehicleCheckResult.fromApi] instead of constructing directly.
class VehicleCheckResult {
  const VehicleCheckResult({
    required this.plate,
    required this.country,
    required this.found,
    this.make,
    this.model,
    this.year,
    this.firstRegistration,
    this.fuelType,
    this.techInspectionValid,
    this.insuranceValid,
    this.insurer,
    required this.sourceUrl,
    required this.sourceName,
    required this.language,
    required this.isPaidSource,
    this.message,
    this.inspectionPortal,
    this.insurancePortal,
  });

  final String plate;
  final String country;
  final bool found;
  final String? make;
  final String? model;
  final int? year;
  final DateTime? firstRegistration;
  final String? fuelType;
  final bool? techInspectionValid;
  final bool? insuranceValid;
  final String? insurer;
  final String sourceUrl;
  final String sourceName;
  final String language;
  final bool isPaidSource;
  final String? message;
  final String? inspectionPortal;
  final String? insurancePortal;

  static VehicleCheckResult fromApi(
    Map<String, dynamic> api, {
    required String plate,
    required String country,
  }) {
    final found = api['found'] == true;
    DateTime? firstReg;
    final rawReg = api['firstRegistration'] as String?;
    if (rawReg != null && rawReg.isNotEmpty) {
      firstReg = DateTime.tryParse(rawReg);
    }
    final yearRaw = api['year'];
    final yearVal = yearRaw is int
        ? yearRaw
        : (yearRaw is String ? int.tryParse(yearRaw) : null);

    return VehicleCheckResult(
      plate: (api['plate'] as String?) ?? plate,
      country: (api['country'] as String?) ?? country,
      found: found,
      make: api['make'] as String?,
      model: api['model'] as String?,
      year: yearVal,
      firstRegistration: firstReg,
      fuelType: api['fuelType'] as String?,
      techInspectionValid: api['techInspectionValid'] as bool?,
      insuranceValid: api['insuranceValid'] as bool?,
      insurer: api['insurer'] as String?,
      sourceUrl: (api['sourceUrl'] as String?) ?? '',
      sourceName: (api['sourceName'] as String?) ?? '',
      language: (api['language'] as String?) ?? 'en',
      isPaidSource: (api['isPaidSource'] as bool?) ?? false,
      message: api['message'] as String?,
      inspectionPortal: api['inspectionPortal'] as String?,
      insurancePortal: api['insurancePortal'] as String?,
    );
  }
}

/// Legacy rich report model, still used by the UI card. Built from
/// [VehicleCheckResult] — fields we cannot verify (mileage history,
/// accidents, stolen status, owner count) are left empty / default.
class VehicleReport {
  const VehicleReport({
    required this.plate,
    required this.vin,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.mileageKm,
    required this.mileageHistory,
    required this.mileageFraudSuspected,
    required this.accidentCount,
    required this.insuranceActive,
    required this.insuranceExpiry,
    required this.inspectionValid,
    required this.inspectionExpiry,
    required this.ownerCount,
    required this.isStolen,
    required this.assessment,
    required this.aiSummary,
    this.sourceUrl,
    this.isPaidSource = false,
    this.isFromRegistry = false,
  });

  final String plate;
  final String vin;
  final String make;
  final String model;
  final int year;
  final String color;
  final int mileageKm;
  final List<MileageRecord> mileageHistory;
  final bool mileageFraudSuspected;
  final int accidentCount;
  final bool insuranceActive;
  final DateTime? insuranceExpiry;
  final bool inspectionValid;
  final DateTime? inspectionExpiry;
  final int ownerCount;
  final bool isStolen;
  final VehicleAssessment assessment;
  final String aiSummary;

  final String? sourceUrl;
  final bool isPaidSource;
  final bool isFromRegistry;

  /// Build the UI report from an API result. Unverified fields are marked
  /// as "unknown" via defaults — the UI must show them as such rather than
  /// pretending they are real.
  factory VehicleReport.fromResult(VehicleCheckResult r) {
    final assessment = r.insuranceValid == false
        ? VehicleAssessment.someConcerns
        : VehicleAssessment.safeToBuy;
    final summary = StringBuffer();
    summary.write('Plate ${r.plate} in ${r.country}. ');
    if (r.insuranceValid == true) {
      summary.write('Insurance: valid${r.insurer != null ? " (${r.insurer})" : ""}. ');
    } else if (r.insuranceValid == false) {
      summary.write('Insurance: NOT valid — flag for buyer. ');
    } else {
      summary.write('Insurance status: unknown (requires portal login). ');
    }
    if (r.isPaidSource) {
      summary.write('Full vehicle history is available via a paid lookup at ${r.sourceName}.');
    } else {
      summary.write('Verify further at ${r.sourceName} (${r.sourceUrl}).');
    }

    return VehicleReport(
      plate: r.plate,
      vin: '',
      make: r.make ?? '',
      model: r.model ?? '',
      year: r.year ?? 0,
      color: '',
      mileageKm: 0,
      mileageHistory: const [],
      mileageFraudSuspected: false,
      accidentCount: 0,
      insuranceActive: r.insuranceValid ?? false,
      insuranceExpiry: null,
      inspectionValid: r.techInspectionValid ?? false,
      inspectionExpiry: null,
      ownerCount: 0,
      isStolen: false,
      assessment: assessment,
      aiSummary: summary.toString(),
      sourceUrl: r.sourceUrl,
      isPaidSource: r.isPaidSource,
      isFromRegistry: r.found,
    );
  }
}

/// State for the vehicle checker screen.
class VehicleCheckerState {
  const VehicleCheckerState({
    this.inputMode = VehicleInputMode.licensePlate,
    this.countryCode = 'EE',
    this.query = '',
    this.isLoading = false,
    this.report,
    this.errorMessage,
    this.redirectUrl,
    this.redirectLanguage,
    this.redirectIsPaid,
  });

  final VehicleInputMode inputMode;
  final String countryCode;
  final String query;
  final bool isLoading;
  final VehicleReport? report;
  final String? errorMessage;

  /// When a country has no free API (e.g. Germany, Latvia), the notifier
  /// sets this URL so the UI can show a "Open ${country} registry" button.
  final String? redirectUrl;
  final String? redirectLanguage;
  final bool? redirectIsPaid;

  VehicleCheckerState copyWith({
    VehicleInputMode? inputMode,
    String? countryCode,
    String? query,
    bool? isLoading,
    VehicleReport? report,
    String? errorMessage,
    String? redirectUrl,
    String? redirectLanguage,
    bool? redirectIsPaid,
    bool clearReport = false,
    bool clearError = false,
    bool clearRedirect = false,
  }) {
    return VehicleCheckerState(
      inputMode: inputMode ?? this.inputMode,
      countryCode: countryCode ?? this.countryCode,
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      report: clearReport ? null : (report ?? this.report),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      redirectUrl: clearRedirect ? null : (redirectUrl ?? this.redirectUrl),
      redirectLanguage: clearRedirect ? null : (redirectLanguage ?? this.redirectLanguage),
      redirectIsPaid: clearRedirect ? null : (redirectIsPaid ?? this.redirectIsPaid),
    );
  }
}

// ---------------------------------------------------------------------------
// Edge Function client abstraction (for tests)
// ---------------------------------------------------------------------------

abstract class VehicleCheckClient {
  Future<Map<String, dynamic>?> checkVehicle({
    required String plate,
    required String country,
  });
}

class SupabaseVehicleCheckClient implements VehicleCheckClient {
  SupabaseVehicleCheckClient(this._service);
  final SupabaseService _service;

  @override
  Future<Map<String, dynamic>?> checkVehicle({
    required String plate,
    required String country,
  }) {
    return _service.callEdgeFunction(
      'check-vehicle',
      body: {'plate_number': plate, 'country': country},
    );
  }
}

/// Plate format validation — mirrors the Edge Function logic so that
/// obviously-invalid input never reaches the network.
bool isPlateFormatValid(String plate) {
  final s = plate.trim();
  if (s.length < 3 || s.length > 12) return false;
  return RegExp(r'^[A-Za-zÅÄÖÕÜа-яА-Я0-9\-\s]+$').hasMatch(s);
}

/// VIN format validation — 17 chars, alphanumeric, no I/O/Q.
bool isVinFormatValid(String vin) {
  final s = vin.trim().toUpperCase();
  if (s.length != 17) return false;
  return RegExp(r'^[A-HJ-NPR-Z0-9]{17}$').hasMatch(s);
}

/// StateNotifier managing vehicle check flow.
class VehicleCheckerNotifier extends StateNotifier<VehicleCheckerState> {
  VehicleCheckerNotifier({
    VehicleCheckClient? client,
    this.debugMode = false,
  })  : _client = client,
        super(const VehicleCheckerState());

  final VehicleCheckClient? _client;

  /// Legacy demo mode — when true and no client is injected, returns the
  /// hard-coded VW Golf for plate 908FBT. **Must be false in production.**
  final bool debugMode;

  void setInputMode(VehicleInputMode mode) {
    state = state.copyWith(
      inputMode: mode,
      clearReport: true,
      clearError: true,
      clearRedirect: true,
    );
  }

  void setCountryCode(String code) {
    state = state.copyWith(countryCode: code);
  }

  void setQuery(String value) {
    state = state.copyWith(query: value);
  }

  Future<void> checkVehicle() async {
    final raw = state.query.trim().toUpperCase();
    if (raw.isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter a plate or VIN');
      return;
    }
    final looksLikeVin = state.inputMode == VehicleInputMode.vin || raw.length == 17;
    final validShape = looksLikeVin
        ? isVinFormatValid(raw)
        : isPlateFormatValid(raw);
    if (!validShape) {
      state = state.copyWith(
        errorMessage: looksLikeVin ? 'Invalid VIN format' : 'Invalid plate format',
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearReport: true,
      clearRedirect: true,
    );

    // ── Real Edge Function path ─────────────────────────────────────
    if (_client != null) {
      Map<String, dynamic>? api;
      try {
        api = await _client.checkVehicle(plate: raw, country: state.countryCode);
      } catch (e) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Network error while querying vehicle registry.',
        );
        return;
      }

      if (api == null) {
        if (debugMode) {
          _applyLegacyDemo(raw);
          return;
        }
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              'Vehicle lookup unavailable in offline/demo mode. Please sign in and retry.',
        );
        return;
      }

      // Function-level error (400/500).
      if (api['error'] != null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: api['error'].toString(),
        );
        return;
      }

      final result = VehicleCheckResult.fromApi(
        api,
        plate: raw,
        country: state.countryCode,
      );

      if (!result.found) {
        // Either a country without a free API, or the plate wasn't in the
        // registry. Surface the redirect URL so the UI can open the source.
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.message ??
              'Vehicle not found. Verify at ${result.sourceName}.',
          redirectUrl: result.sourceUrl,
          redirectLanguage: result.language,
          redirectIsPaid: result.isPaidSource,
        );
        return;
      }

      state = state.copyWith(
        isLoading: false,
        report: VehicleReport.fromResult(result),
        redirectUrl: result.sourceUrl,
        redirectLanguage: result.language,
        redirectIsPaid: result.isPaidSource,
      );
      return;
    }

    // ── No client injected → legacy demo path ────────────────────────
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    _applyLegacyDemo(raw);
  }

  void _applyLegacyDemo(String q) {
    if (q == '908FBT' || q == 'WVWZZZ3CZWE123456') {
      state = state.copyWith(
        isLoading: false,
        report: VehicleReport(
          plate: '908FBT',
          vin: 'WVWZZZ3CZWE123456',
          make: 'Volkswagen',
          model: 'Golf',
          year: 2018,
          color: 'Silver',
          mileageKm: 87000,
          mileageHistory: [
            MileageRecord(
                date: DateTime(2019, 6, 15),
                mileageKm: 12400,
                source: 'Service record'),
            MileageRecord(
                date: DateTime(2020, 3, 20),
                mileageKm: 31200,
                source: 'Technical inspection'),
            MileageRecord(
                date: DateTime(2021, 4, 10),
                mileageKm: 48700,
                source: 'Service record'),
            MileageRecord(
                date: DateTime(2022, 5, 5),
                mileageKm: 62300,
                source: 'Technical inspection'),
            MileageRecord(
                date: DateTime(2023, 8, 22),
                mileageKm: 78100,
                source: 'Service record'),
            MileageRecord(
                date: DateTime(2024, 6, 1),
                mileageKm: 87000,
                source: 'Technical inspection'),
          ],
          mileageFraudSuspected: false,
          accidentCount: 0,
          insuranceActive: true,
          insuranceExpiry: DateTime(2026, 12, 31),
          inspectionValid: true,
          inspectionExpiry: DateTime(2026, 8, 15),
          ownerCount: 2,
          isStolen: false,
          assessment: VehicleAssessment.safeToBuy,
          aiSummary: 'Demo-only data. Production uses check-vehicle Edge Function.',
        ),
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Vehicle not found. In demo mode, try plate "908FBT".',
      );
    }
  }

  void clearResults() {
    state = state.copyWith(
      clearReport: true,
      clearError: true,
      clearRedirect: true,
      query: '',
    );
  }
}

/// Provider for the vehicle checker state.
final vehicleCheckerProvider =
    StateNotifierProvider<VehicleCheckerNotifier, VehicleCheckerState>(
  (ref) {
    final supabase = ref.watch(supabaseServiceProvider);
    return VehicleCheckerNotifier(
      client: SupabaseVehicleCheckClient(supabase),
    );
  },
);

/// Supported countries for license plate lookup.
const kSupportedCountries = <String, String>{
  'EE': 'Estonia',
  'FI': 'Finland',
  'LV': 'Latvia',
  'LT': 'Lithuania',
  'SE': 'Sweden',
  'DE': 'Germany',
  'PL': 'Poland',
  'FR': 'France',
  'IT': 'Italy',
  'ES': 'Spain',
};
