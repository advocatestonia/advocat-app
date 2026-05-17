// lib/features/lawyer_partnership/data/lawyer_partnership_service.dart
// -----------------------------------------------------------------------------
// Thin wrapper around the `lawyer-booking` Supabase edge function and the
// `partner_lawyers` / `lawyer_bookings` tables.
//
// Five operations:
//   * createBooking(request)      → POST {op:'create', ...}
//   * fetchBookings()             → SELECT * FROM lawyer_bookings WHERE user_id = me
//   * fetchPartnerBookings()      → SELECT * FROM lawyer_bookings WHERE lawyer_id = me
//   * fetchActivePartners()       → SELECT * FROM partner_lawyers (active filter)
//   * fetchQuota()                → SELECT lawyer_bookings_quota_used + tier
//   * submitOutcome(booking_id, summary)  ← partner lawyer
//   * submitRating(booking_id, rating, feedback?)
//   * cancelBooking(booking_id)
//
// Demo mode: if no Supabase client is reachable (e.g. running in the web
// preview without auth), every method returns reasonable placeholder data
// so screens still render. Mirrors the pattern in
// lawyer_verification_service.dart.
// -----------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lawyer_partnership_state.dart';

/// Riverpod handle. Singleton — the service holds no per-screen state.
final lawyerPartnershipServiceProvider =
    Provider<LawyerPartnershipService>((ref) {
  return LawyerPartnershipService();
});

class LawyerPartnershipService {
  LawyerPartnershipService({SupabaseClient? client}) : _client = client;
  final SupabaseClient? _client;

  static const String _functionName = 'lawyer-booking';
  static const String _bookingsTable = 'lawyer_bookings';
  static const String _partnersTable = 'partner_lawyers';

  SupabaseClient? get _safeClient {
    if (_client != null) return _client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get _isDemo => _safeClient == null;

  // ─── create ──────────────────────────────────────────────────────────────

  Future<BookingOutcome> createBooking(BookingRequest request) async {
    if (!request.isComplete) {
      return const BookingRejected(reasonCode: 'incomplete_form');
    }
    if (_isDemo) {
      return BookingCreated(
        booking: LawyerBooking.fromJson({
          'id': 'demo-${DateTime.now().millisecondsSinceEpoch}',
          'user_id': 'demo-user',
          'topic': request.topic == BookingTopic.other
              ? request.freeFormTopic
              : request.topic?.token,
          'language': request.language,
          'duration_minutes': 15,
          'status': 'requested',
          'quota_quarter': _nowQuarter(),
          'created_at': DateTime.now().toUtc().toIso8601String(),
        }),
        quotaRemaining: 0,
      );
    }

    final client = _safeClient!;
    final res = await client.functions.invoke(
      _functionName,
      body: request.toJson(),
    );
    final status = res.status;
    final data = res.data;
    if (status >= 200 && status < 300 && data is Map) {
      final bookingMap = data['booking'];
      if (bookingMap is Map) {
        return BookingCreated(
          booking:
              LawyerBooking.fromJson(Map<String, dynamic>.from(bookingMap)),
          quotaRemaining: (data['quota_remaining'] as num?)?.toInt() ?? 0,
        );
      }
    }
    final reason = (data is Map ? data['reason']?.toString() : null) ??
        'unknown_error';
    final message = (data is Map ? data['error']?.toString() : null);
    return BookingRejected(
      reasonCode: reason,
      statusCode: status,
      message: message,
    );
  }

  // ─── user bookings ───────────────────────────────────────────────────────

  Future<List<LawyerBooking>> fetchBookings() async {
    if (_isDemo) return const [];
    final client = _safeClient!;
    final user = client.auth.currentUser;
    if (user == null) return const [];
    final rows = await client
        .from(_bookingsTable)
        .select('*')
        .eq('user_id', user.id)
        .order('scheduled_at', ascending: false)
        .limit(50);
    return _parseList(rows);
  }

  // ─── partner-side bookings (their dashboard) ─────────────────────────────

  Future<List<LawyerBooking>> fetchPartnerBookings() async {
    if (_isDemo) return const [];
    final client = _safeClient!;
    final user = client.auth.currentUser;
    if (user == null) return const [];
    final rows = await client
        .from(_bookingsTable)
        .select('*')
        .eq('lawyer_id', user.id)
        .order('scheduled_at', ascending: true)
        .limit(100);
    return _parseList(rows);
  }

  List<LawyerBooking> _parseList(dynamic rows) {
    if (rows is! List) return const [];
    return rows
        .whereType<Map>()
        .map((m) => LawyerBooking.fromJson(Map<String, dynamic>.from(m)))
        .toList(growable: false);
  }

  // ─── partner directory ───────────────────────────────────────────────────

  Future<List<PartnerLawyerProfile>> fetchActivePartners({
    String? country,
    String? specialty,
    String? language,
  }) async {
    if (_isDemo) return const [];
    final client = _safeClient!;
    var query = client
        .from(_partnersTable)
        .select('lawyer_id, public_blurb, country, specialties, '
            'languages, avg_rating, bookings_completed')
        .eq('active', true)
        .isFilter('paused_at', null)
        .isFilter('ended_at', null);
    if (country != null && country.isNotEmpty) {
      query = query.eq('country', country);
    }
    final rows = await query
        .order('avg_rating', ascending: false, nullsFirst: false)
        .limit(50);
    // PostgREST always returns a List for `.select()`; the explicit check
    // would have been a no-op (`rows is! List` is statically false).
    final all = (rows as List)
        .whereType<Map>()
        .map((m) =>
            PartnerLawyerProfile.fromJson(Map<String, dynamic>.from(m)))
        .toList(growable: false);
    Iterable<PartnerLawyerProfile> filtered = all;
    if (specialty != null && specialty.isNotEmpty) {
      final s = specialty.toLowerCase();
      filtered = filtered.where(
        (p) => p.specialties.any((x) => x.toLowerCase().contains(s)),
      );
    }
    if (language != null && language.isNotEmpty) {
      filtered = filtered.where((p) => p.languages.contains(language));
    }
    return filtered.toList(growable: false);
  }

  // ─── quota ───────────────────────────────────────────────────────────────

  /// Fetch the current user's quota state. Reads `profiles.subscription_tier`
  /// for the cap and the RPC `lawyer_bookings_quota_used` for the count.
  Future<BookingQuota> fetchQuota() async {
    if (_isDemo) {
      return BookingQuota(
        quotaTotal: 1,
        quotaUsed: 0,
        quarter: _nowQuarter(),
      );
    }
    final client = _safeClient!;
    final user = client.auth.currentUser;
    if (user == null) {
      return BookingQuota(
        quotaTotal: 0,
        quotaUsed: 0,
        quarter: _nowQuarter(),
      );
    }

    final profile = await client
        .from('profiles')
        .select('subscription_tier, is_pro')
        .eq('id', user.id)
        .maybeSingle();
    final tier = (profile?['subscription_tier'] as String?) ??
        ((profile?['is_pro'] == true) ? 'pro' : 'free');
    final quotaTotal = _quotaForTier(tier);

    final used = await client.rpc(
      'lawyer_bookings_quota_used',
      params: {'p_user': user.id},
    );
    final usedInt = used is num ? used.toInt() : int.tryParse('$used') ?? 0;
    return BookingQuota(
      quotaTotal: quotaTotal,
      quotaUsed: usedInt,
      quarter: _nowQuarter(),
    );
  }

  static int _quotaForTier(String tier) {
    switch (tier) {
      case 'pro':
        return 1;
      case 'premium':
        return 2;
      case 'free':
      case 'premium_lawyer':
      default:
        return 0;
    }
  }

  // ─── partner: submit outcome ─────────────────────────────────────────────

  Future<bool> submitOutcome({
    required String bookingId,
    required String outcomeSummary,
  }) async {
    if (_isDemo) return true;
    final client = _safeClient!;
    final res = await client.functions.invoke(
      _functionName,
      body: <String, dynamic>{
        'op': 'outcome',
        'booking_id': bookingId,
        'outcome_summary': outcomeSummary,
      },
    );
    return res.status >= 200 && res.status < 300;
  }

  // ─── user: submit rating ─────────────────────────────────────────────────

  Future<bool> submitRating({
    required String bookingId,
    required int rating,
    String? feedback,
  }) async {
    if (_isDemo) return true;
    final client = _safeClient!;
    final res = await client.functions.invoke(
      _functionName,
      body: <String, dynamic>{
        'op': 'rate',
        'booking_id': bookingId,
        'user_rating': rating,
        if (feedback != null && feedback.trim().isNotEmpty)
          'user_feedback': feedback.trim(),
      },
    );
    return res.status >= 200 && res.status < 300;
  }

  // ─── cancel ──────────────────────────────────────────────────────────────

  Future<bool> cancelBooking(String bookingId) async {
    if (_isDemo) return true;
    final client = _safeClient!;
    final res = await client.functions.invoke(
      _functionName,
      body: <String, dynamic>{
        'op': 'cancel',
        'booking_id': bookingId,
      },
    );
    return res.status >= 200 && res.status < 300;
  }

  static String _nowQuarter() {
    final n = DateTime.now().toUtc();
    final q = ((n.month - 1) ~/ 3) + 1;
    return '${n.year}-Q$q';
  }
}
