// lib/features/lawyer_verification/data/lawyer_verification_service.dart
// -----------------------------------------------------------------------------
// Thin wrapper around the `verify-lawyer` Supabase edge function and the
// `profiles` table for the read-back status query.
//
// Three operations:
//   * submit(application)  → POST /verify-lawyer
//                            Returns LawyerVerificationOutcome.
//   * fetchStatus()        → SELECT lawyer_* FROM profiles WHERE id = me
//                            Drives the Settings panel.
//   * isProgramEnabled     → cached snapshot of feature flag.
//
// Demo mode: if no Supabase client is reachable (e.g. running in the web
// preview without auth), submit() returns Approved for tester@advocat.ee
// and Rejected('demo_no_match') otherwise so the screens render cleanly.
// -----------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lawyer_verification_state.dart';

/// Riverpod handle. Singleton — the service holds no per-screen state.
final lawyerVerificationServiceProvider =
    Provider<LawyerVerificationService>((ref) {
  return LawyerVerificationService();
});

class LawyerVerificationService {
  LawyerVerificationService({SupabaseClient? client}) : _client = client;
  final SupabaseClient? _client;

  static const String _functionName = 'verify-lawyer';

  SupabaseClient? get _safeClient {
    if (_client != null) return _client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get _isDemo => _safeClient == null;

  /// Submit a verification application. The Edge Function does all the
  /// work; this method only translates the JSON response into a typed
  /// [LawyerVerificationOutcome].
  Future<LawyerVerificationOutcome> submit(
    LawyerVerificationApplication application,
  ) async {
    if (!application.isComplete) {
      return const LawyerVerificationRejected(reasonCode: 'incomplete_form');
    }

    if (_isDemo) {
      // Deterministic demo behaviour for offline review:
      //   * email starts with "tester@" → approved
      //   * email starts with "queue@"  → queued
      //   * anything else               → rejected
      final email = application.email.toLowerCase();
      if (email.startsWith('tester@')) {
        return LawyerVerificationApproved(verifiedAt: DateTime.now().toUtc());
      }
      if (email.startsWith('queue@')) {
        return const LawyerVerificationQueued();
      }
      return const LawyerVerificationRejected(reasonCode: 'demo_no_match');
    }

    final client = _safeClient!;
    final res = await client.functions.invoke(
      _functionName,
      body: application.toJson(),
    );
    final status = res.status;
    final data = res.data;

    if (status >= 200 && status < 300 && data is Map) {
      final outcomeStatus = data['status']?.toString();
      if (outcomeStatus == 'auto_approved' ||
          outcomeStatus == 'manually_approved') {
        final verifiedRaw = data['verified_at']?.toString();
        final verifiedAt = verifiedRaw != null
            ? (DateTime.tryParse(verifiedRaw) ?? DateTime.now().toUtc())
            : DateTime.now().toUtc();
        return LawyerVerificationApproved(verifiedAt: verifiedAt);
      }
      if (outcomeStatus == 'pending') {
        return const LawyerVerificationQueued();
      }
    }

    // Error path. Reason key is what the UI localises.
    final reason = (data is Map ? data['reason']?.toString() : null) ??
        'unknown_error';
    final message = (data is Map ? data['error']?.toString() : null);
    return LawyerVerificationRejected(
      reasonCode: reason,
      statusCode: status,
      message: message,
    );
  }

  /// Read the current user's verification status from `profiles`. Returns
  /// [LawyerVerificationStatus.none] for unauthenticated sessions.
  Future<LawyerVerificationStatus> fetchStatus() async {
    if (_isDemo) {
      return LawyerVerificationStatus.none;
    }
    final client = _safeClient!;
    final user = client.auth.currentUser;
    if (user == null) return LawyerVerificationStatus.none;

    final row = await client
        .from('profiles')
        .select(
          'lawyer_verified_at, lawyer_verification_status, '
          'lawyer_bar_country, lawyer_bar_id',
        )
        .eq('id', user.id)
        .maybeSingle();

    if (row == null) return LawyerVerificationStatus.none;
    final verifiedRaw = row['lawyer_verified_at'] as String?;
    final verifiedAt = verifiedRaw != null && verifiedRaw.isNotEmpty
        ? DateTime.tryParse(verifiedRaw)
        : null;
    return LawyerVerificationStatus(
      lifecycle: LawyerVerificationLifecycle.parse(
        row['lawyer_verification_status'] as String?,
      ),
      verifiedAt: verifiedAt,
      barCountry: LawyerBarCountry.tryParse(
        row['lawyer_bar_country'] as String?,
      ),
      barId: row['lawyer_bar_id'] as String?,
    );
  }
}
