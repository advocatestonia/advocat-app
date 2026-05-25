// =============================================================================
// b2b_service.dart
// =============================================================================
//
// Thin wrapper around the two Supabase round-trips that back the silent-
// signal B2B detection flow. Owned by the client; the actual signal
// computation + table columns live on the backend (parallel agent).
//
// Two operations:
//
//   1. [fetchB2BModalPending]  — reads `profiles.b2b_modal_pending` for
//      the current authed user. Fire-and-forget; returns false on any
//      transport or parse failure so we never block the home-screen render
//      on a B2B network call.
//
//   2. [markB2BModalShown]     — calls the `mark_b2b_modal_shown(uuid)`
//      Postgres RPC, which the backend uses to set
//      `b2b_modal_shown_at = now()` and flip the pending flag to false.
//      Also fire-and-forget; if the RPC errors, we still treat the modal
//      as locally-shown for this session.
//
// Demo mode (no Supabase creds) short-circuits both calls with
// (false, success) so unit + widget tests can run without a backend.
//
// The B2B inquiry form submission reuses the existing `support-ticket`
// edge function with `category='b2b_inquiry'` + a structured payload —
// no extra edge fn needed, no separate retry logic, no separate ticketing
// surface for the founders.
// =============================================================================

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_service.dart';

final b2bServiceProvider = Provider<B2BService>((ref) {
  return B2BService(ref.read(supabaseServiceProvider));
});

/// Result of [B2BService.submitInquiry]. Mirrors the SupportSubmitResult
/// pattern: never throws on the happy/error path; only unreachable network
/// surfaces as `errorReason='network'`.
class B2BInquiryResult {
  const B2BInquiryResult.ok(this.ticketId)
      : success = true,
        errorReason = null;

  const B2BInquiryResult.error(this.errorReason)
      : success = false,
        ticketId = null;

  final bool success;
  final String? ticketId;
  final String? errorReason;
}

class B2BService {
  B2BService(this._supabase);

  final SupabaseService _supabase;

  static const String _profilesTable = 'profiles';
  static const String _pendingColumn = 'b2b_modal_pending';
  static const String _markShownRpc = 'mark_b2b_modal_shown';
  static const String _supportFunction = 'support-ticket';

  /// Reads `profiles.b2b_modal_pending` for the current user. Returns
  /// `false` on any failure (missing profile row, RLS deny, network
  /// timeout, demo mode). Never throws — the caller is expected to use
  /// this in a fire-and-forget startup check.
  Future<bool> fetchB2BModalPending() async {
    if (_supabase.isDemo) return false;

    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return false;

      final row = await Supabase.instance.client
          .from(_profilesTable)
          .select(_pendingColumn)
          .eq('id', uid)
          .maybeSingle();

      if (row == null) return false;
      final value = row[_pendingColumn];
      // Supabase returns booleans as bool, but RPC return shapes have
      // historically been inconsistent — accept "true"/"t"/1 as truthy
      // so a column-type drift doesn't silently disable the feature.
      if (value is bool) return value;
      if (value is String) {
        return value.toLowerCase() == 'true' || value == 't' || value == '1';
      }
      if (value is num) return value != 0;
      return false;
    } catch (e) {
      if (kDebugMode) {
        // Surface in dev so a missing column shows up immediately, but
        // never crash the home-screen render path.
        // ignore: avoid_print
        print('[B2BService] fetchB2BModalPending failed: $e');
      }
      return false;
    }
  }

  /// Calls the `mark_b2b_modal_shown` RPC. Pass through the current user
  /// id so the RPC can do its own auth check (defense-in-depth — RLS on
  /// profiles already restricts the update). Fire-and-forget: errors are
  /// logged in debug builds but otherwise swallowed.
  Future<void> markB2BModalShown() async {
    if (_supabase.isDemo) return;

    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;
      await Supabase.instance.client.rpc(
        _markShownRpc,
        params: {'p_user_id': uid},
      );
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[B2BService] markB2BModalShown failed: $e');
      }
      // Swallow — the worst case is the user sees the modal again on a
      // future session; far better than crashing on a transient network
      // blip.
    }
  }

  /// Submits a B2B inquiry via the existing `support-ticket` edge fn with
  /// a dedicated `category='b2b_inquiry'` flag. The full structured payload
  /// (firm_name / team_size / practices / pain) is included so the
  /// founders can triage without a second round-trip.
  ///
  /// Returns an [B2BInquiryResult] — never throws.
  Future<B2BInquiryResult> submitInquiry({
    required String name,
    required String email,
    required String firmName,
    required String teamSize,
    required List<String> practices,
    required String biggestPainToday,
    String? language,
    String? appVersion,
  }) async {
    // Build a single human-readable message body so the Telegram ping
    // the support-ticket fn produces is legible without parsing JSON.
    final messageLines = <String>[
      'B2B inquiry from $name <$email>',
      'Firm: $firmName',
      'Team size: $teamSize',
      'Practices: ${practices.join(", ")}',
      '',
      'Biggest pain today:',
      biggestPainToday,
    ];
    final message = messageLines.join('\n');

    final payload = <String, dynamic>{
      'category': 'b2b_inquiry',
      'message': message,
      'contact_channel': 'in_app',
      'email': email,
      '_hp': '',
      // Structured B2B fields — backend agent's support-ticket handler
      // extension reads these to populate a dedicated b2b_inquiries view.
      'b2b': <String, dynamic>{
        'name': name,
        'email': email,
        'firm_name': firmName,
        'team_size': teamSize,
        'practices': practices,
        'biggest_pain_today': biggestPainToday,
      },
      if (language != null && language.isNotEmpty) 'language': language,
      if (appVersion != null && appVersion.isNotEmpty) 'app_version': appVersion,
    };

    if (_supabase.isDemo) {
      return const B2BInquiryResult.ok(
          'demo-00000000-0000-0000-0000-000000000000');
    }

    try {
      final res = await Supabase.instance.client.functions.invoke(
        _supportFunction,
        body: payload,
      );
      if (res.status >= 200 && res.status < 300) {
        final data = res.data;
        if (data is Map && data['ticket_id'] is String) {
          return B2BInquiryResult.ok(data['ticket_id'] as String);
        }
        return const B2BInquiryResult.ok('');
      }
      return B2BInquiryResult.error('server_${res.status}');
    } on FunctionException catch (e) {
      return B2BInquiryResult.error('server_${e.status}');
    } catch (e) {
      return const B2BInquiryResult.error('network');
    }
  }
}
