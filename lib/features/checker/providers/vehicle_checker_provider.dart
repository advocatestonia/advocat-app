import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Vehicle Checker Provider — State management for vehicle checks
// ---------------------------------------------------------------------------

/// Represents the input mode for vehicle lookup.
enum VehicleInputMode { licensePlate, vin }

/// AI assessment level for the vehicle.
enum VehicleAssessment { safeToBuy, someConcerns, doNotBuy }

/// A single mileage history entry.
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

/// Full vehicle report returned after a check.
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
  });

  final VehicleInputMode inputMode;
  final String countryCode;
  final String query;
  final bool isLoading;
  final VehicleReport? report;
  final String? errorMessage;

  VehicleCheckerState copyWith({
    VehicleInputMode? inputMode,
    String? countryCode,
    String? query,
    bool? isLoading,
    VehicleReport? report,
    String? errorMessage,
    bool clearReport = false,
    bool clearError = false,
  }) {
    return VehicleCheckerState(
      inputMode: inputMode ?? this.inputMode,
      countryCode: countryCode ?? this.countryCode,
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      report: clearReport ? null : (report ?? this.report),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// StateNotifier managing vehicle check flow.
class VehicleCheckerNotifier extends StateNotifier<VehicleCheckerState> {
  VehicleCheckerNotifier() : super(const VehicleCheckerState());

  void setInputMode(VehicleInputMode mode) {
    state = state.copyWith(
      inputMode: mode,
      clearReport: true,
      clearError: true,
    );
  }

  void setCountryCode(String code) {
    state = state.copyWith(countryCode: code);
  }

  void setQuery(String value) {
    state = state.copyWith(query: value);
  }

  /// Perform the vehicle check. Uses mock data for demo.
  Future<void> checkVehicle() async {
    final q = state.query.trim().toUpperCase();
    if (q.isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter a plate or VIN');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true, clearReport: true);

    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 1800));

    // Demo data for Estonian plate 908FBT
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
              source: 'Service record',
            ),
            MileageRecord(
              date: DateTime(2020, 3, 20),
              mileageKm: 31200,
              source: 'Technical inspection',
            ),
            MileageRecord(
              date: DateTime(2021, 4, 10),
              mileageKm: 48700,
              source: 'Service record',
            ),
            MileageRecord(
              date: DateTime(2022, 5, 5),
              mileageKm: 62300,
              source: 'Technical inspection',
            ),
            MileageRecord(
              date: DateTime(2023, 8, 22),
              mileageKm: 78100,
              source: 'Service record',
            ),
            MileageRecord(
              date: DateTime(2024, 6, 1),
              mileageKm: 87000,
              source: 'Technical inspection',
            ),
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
          aiSummary:
              'Vehicle appears to be in good condition. Mileage history is '
              'consistent with no signs of tampering. No accidents reported. '
              'Insurance and technical inspection are both current. Two previous '
              'owners is typical for a 2018 model. No red flags detected.',
        ),
      );
    } else {
      // For any other query, show not-found error in demo mode
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'Vehicle not found. In demo mode, try plate "908FBT".',
      );
    }
  }

  void clearResults() {
    state = state.copyWith(clearReport: true, clearError: true, query: '');
  }
}

/// Provider for the vehicle checker state.
final vehicleCheckerProvider =
    StateNotifierProvider<VehicleCheckerNotifier, VehicleCheckerState>(
  (_) => VehicleCheckerNotifier(),
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
