// lib/features/lawyer_partnership/state/lawyer_partnership_providers.dart
// -----------------------------------------------------------------------------
// Riverpod providers backing the lawyer-partnership feature (Day2-E).
//
//   bookingQuotaProvider             — AsyncValue<BookingQuota>.
//                                      Cached per-screen; refreshed on
//                                      booking submit / cancel.
//
//   userBookingsProvider             — AsyncValue<List<LawyerBooking>> for
//                                      the user's "my bookings" history.
//
//   partnerBookingsProvider          — AsyncValue<List<LawyerBooking>> for
//                                      the partner lawyer dashboard.
//
//   activePartnersProvider           — AsyncValue<List<PartnerLawyerProfile>>
//                                      for the booking screen's directory.
//                                      Family-parameterised by country.
//
//   bookingFormProvider              — StateNotifier holding the in-progress
//                                      form payload.
//
//   bookingSubmitProvider            — async submission state.
//
//   bookingOutcomeFormProvider       — StateNotifier for the partner-lawyer
//                                      "fill outcome" form.
//
// All providers are auto-disposed where the screen lifecycle allows.
// -----------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/lawyer_partnership_service.dart';
import '../models/lawyer_partnership_state.dart';

// ─── Quota ──────────────────────────────────────────────────────────────────

final bookingQuotaProvider =
    FutureProvider.autoDispose<BookingQuota>((ref) async {
  return ref.read(lawyerPartnershipServiceProvider).fetchQuota();
});

// ─── User bookings list ─────────────────────────────────────────────────────

final userBookingsProvider =
    FutureProvider.autoDispose<List<LawyerBooking>>((ref) async {
  return ref.read(lawyerPartnershipServiceProvider).fetchBookings();
});

// ─── Partner-lawyer bookings list ───────────────────────────────────────────

final partnerBookingsProvider =
    FutureProvider.autoDispose<List<LawyerBooking>>((ref) async {
  return ref.read(lawyerPartnershipServiceProvider).fetchPartnerBookings();
});

// ─── Active partner directory ───────────────────────────────────────────────

class PartnerDirectoryQuery {
  const PartnerDirectoryQuery({this.country, this.specialty, this.language});
  final String? country;
  final String? specialty;
  final String? language;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PartnerDirectoryQuery &&
          other.country == country &&
          other.specialty == specialty &&
          other.language == language);

  @override
  int get hashCode => Object.hash(country, specialty, language);
}

final activePartnersProvider = FutureProvider.autoDispose
    .family<List<PartnerLawyerProfile>, PartnerDirectoryQuery>(
        (ref, query) async {
  return ref.read(lawyerPartnershipServiceProvider).fetchActivePartners(
        country: query.country,
        specialty: query.specialty,
        language: query.language,
      );
});

// ─── Booking form controller ────────────────────────────────────────────────

final bookingFormProvider =
    StateNotifierProvider.autoDispose<BookingFormController, BookingRequest>(
        (ref) {
  return BookingFormController();
});

class BookingFormController extends StateNotifier<BookingRequest> {
  BookingFormController() : super(const BookingRequest());

  void setTopic(BookingTopic? t) => state = state.copyWith(topic: t);
  void setFreeFormTopic(String v) => state = state.copyWith(freeFormTopic: v);
  void setLanguage(String v) => state = state.copyWith(language: v);
  void setLawyerId(String? v) => state = state.copyWith(lawyerId: v);
  void setCaseId(String? v) => state = state.copyWith(caseId: v);
  void setScheduledAt(DateTime? v) => state = state.copyWith(scheduledAt: v);
  void setTimePreference(String v) => state = state.copyWith(timePreference: v);
  void setUserBrief(String v) => state = state.copyWith(userBrief: v);
  void reset() => state = const BookingRequest();
}

// ─── Booking submit lifecycle ───────────────────────────────────────────────

sealed class BookingSubmitState {
  const BookingSubmitState();
}

final class BookingSubmitIdle extends BookingSubmitState {
  const BookingSubmitIdle();
}

final class BookingSubmitInFlight extends BookingSubmitState {
  const BookingSubmitInFlight();
}

final class BookingSubmitDone extends BookingSubmitState {
  const BookingSubmitDone(this.outcome);
  final BookingOutcome outcome;
}

final bookingSubmitProvider = StateNotifierProvider.autoDispose<
    BookingSubmitController, BookingSubmitState>((ref) {
  return BookingSubmitController(ref);
});

class BookingSubmitController extends StateNotifier<BookingSubmitState> {
  BookingSubmitController(this._ref) : super(const BookingSubmitIdle());
  final Ref _ref;

  Future<void> submit() async {
    if (state is BookingSubmitInFlight) return; // dedupe rapid taps
    final request = _ref.read(bookingFormProvider);
    state = const BookingSubmitInFlight();
    final outcome =
        await _ref.read(lawyerPartnershipServiceProvider).createBooking(
              request,
            );
    state = BookingSubmitDone(outcome);
    // Invalidate cached lists so any screen showing them refreshes.
    _ref.invalidate(bookingQuotaProvider);
    _ref.invalidate(userBookingsProvider);
  }

  void reset() {
    state = const BookingSubmitIdle();
  }
}

// ─── Partner outcome form ───────────────────────────────────────────────────

class OutcomeFormState {
  const OutcomeFormState({
    this.bookingId,
    this.summary = '',
    this.submitting = false,
    this.error,
  });

  final String? bookingId;
  final String summary;
  final bool submitting;
  final String? error;

  bool get canSubmit =>
      bookingId != null && summary.trim().length >= 10 && !submitting;

  OutcomeFormState copyWith({
    String? bookingId,
    String? summary,
    bool? submitting,
    Object? error = _sentinel,
  }) {
    return OutcomeFormState(
      bookingId: bookingId ?? this.bookingId,
      summary: summary ?? this.summary,
      submitting: submitting ?? this.submitting,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }

  static const _sentinel = Object();
}

final outcomeFormProvider = StateNotifierProvider.autoDispose<
    OutcomeFormController, OutcomeFormState>((ref) {
  return OutcomeFormController(ref);
});

class OutcomeFormController extends StateNotifier<OutcomeFormState> {
  OutcomeFormController(this._ref) : super(const OutcomeFormState());
  final Ref _ref;

  void bind(String bookingId) =>
      state = state.copyWith(bookingId: bookingId, summary: '');

  void setSummary(String v) => state = state.copyWith(summary: v);

  Future<bool> submit() async {
    if (!state.canSubmit) return false;
    state = state.copyWith(submitting: true, error: null);
    final ok =
        await _ref.read(lawyerPartnershipServiceProvider).submitOutcome(
              bookingId: state.bookingId!,
              outcomeSummary: state.summary.trim(),
            );
    if (ok) {
      state = const OutcomeFormState();
      _ref.invalidate(partnerBookingsProvider);
      return true;
    }
    state = state.copyWith(submitting: false, error: 'submit_failed');
    return false;
  }
}
