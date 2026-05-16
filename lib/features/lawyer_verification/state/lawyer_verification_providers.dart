// lib/features/lawyer_verification/state/lawyer_verification_providers.dart
// -----------------------------------------------------------------------------
// Riverpod providers backing the lawyer verification feature.
//
//   lawyerVerificationStatusProvider — AsyncValue<LawyerVerificationStatus>.
//                                      Auto-disposed when the screen leaves.
//   lawyerVerificationFormProvider    — StateNotifier holding the in-progress
//                                      form payload.
//   lawyerVerificationSubmitProvider  — async submission state for the form
//                                      (idle / submitting / done).
//
// All three are isolated; the screen wires them together.
// -----------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/lawyer_verification_service.dart';
import '../models/lawyer_verification_state.dart';

/// Read the current user's verification state from `profiles`. The form
/// screen reads this on mount to display the "already verified" banner
/// instead of the form when applicable.
final lawyerVerificationStatusProvider =
    FutureProvider.autoDispose<LawyerVerificationStatus>((ref) async {
  return ref.read(lawyerVerificationServiceProvider).fetchStatus();
});

/// In-progress form data. Survives field-level rebuilds without each
/// TextField needing its own StateProvider.
final lawyerVerificationFormProvider = StateNotifierProvider.autoDispose<
    LawyerVerificationFormController, LawyerVerificationApplication>((ref) {
  return LawyerVerificationFormController();
});

class LawyerVerificationFormController
    extends StateNotifier<LawyerVerificationApplication> {
  LawyerVerificationFormController()
      : super(const LawyerVerificationApplication());

  void setCountry(LawyerBarCountry? c) => state = state.copyWith(country: c);
  void setBarId(String v) => state = state.copyWith(barId: v);
  void setFullName(String v) => state = state.copyWith(fullName: v);
  void setEmail(String v) => state = state.copyWith(email: v);
  void setPracticeUrl(String v) => state = state.copyWith(practiceUrl: v);
}

/// Status of the in-flight submission. The screen watches this to swap
/// between the form, the spinner, and the result card.
sealed class LawyerSubmitState {
  const LawyerSubmitState();
}

final class LawyerSubmitIdle extends LawyerSubmitState {
  const LawyerSubmitIdle();
}

final class LawyerSubmitInFlight extends LawyerSubmitState {
  const LawyerSubmitInFlight();
}

final class LawyerSubmitDone extends LawyerSubmitState {
  const LawyerSubmitDone(this.outcome);
  final LawyerVerificationOutcome outcome;
}

final lawyerVerificationSubmitProvider =
    StateNotifierProvider.autoDispose<LawyerSubmitController, LawyerSubmitState>(
        (ref) {
  return LawyerSubmitController(ref);
});

class LawyerSubmitController extends StateNotifier<LawyerSubmitState> {
  LawyerSubmitController(this._ref) : super(const LawyerSubmitIdle());
  final Ref _ref;

  Future<void> submit() async {
    if (state is LawyerSubmitInFlight) return; // dedupe rapid taps
    final application = _ref.read(lawyerVerificationFormProvider);
    state = const LawyerSubmitInFlight();
    final outcome =
        await _ref.read(lawyerVerificationServiceProvider).submit(application);
    state = LawyerSubmitDone(outcome);
    // Invalidate status so the Settings panel reflects the new state next
    // time it is read.
    _ref.invalidate(lawyerVerificationStatusProvider);
  }

  void reset() {
    state = const LawyerSubmitIdle();
  }
}
